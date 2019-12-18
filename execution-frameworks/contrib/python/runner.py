"""
ART Attack Runner
Version: 1.0
Author: Olivier Lemelin

Script that was built in order to automate the execution of ART.
"""

import os
import os.path
import fnmatch
import platform
import re
import subprocess
import sys
import hashlib
import json
import argparse

import yaml
import unidecode

# pylint: disable=line-too-long, invalid-name

TECHNIQUE_DIRECTORY_PATTERN = 'T*'
ATOMICS_DIR_RELATIVE_PATH = os.path.join("..", "..", "..", "atomics")
HASH_DB_RELATIVE_PATH = "techniques_hash.db"
COMMAND_TIMEOUT = 20

##########################################
# Filesystem & Helpers
##########################################

def get_platform():
    """Gets the current platform."""

    # We need to handle the platform a bit differently in certain cases.
    # Otherwise, we simply return the value that's given here.
    plat = platform.system().lower()

    if plat == "darwin":
        # 'macos' is the term that is being used within the .yaml files.
        plat = "macos"

    return plat


def get_self_path():
    """Gets the full path to this script's directory."""
    return os.path.dirname(os.path.abspath(__file__))


def get_yaml_file_from_dir(path_to_dir):
    """Returns path of the first file that matches "*.yaml" in a directory."""

    for entry in os.listdir(path_to_dir):
        if fnmatch.fnmatch(entry, '*.yaml'):
            # Found the file!
            return os.path.join(path_to_dir, entry)

    print("No YAML file describing the technique in {}!".format(path_to_dir))
    return None


def load_technique(path_to_dir):
    """Loads the YAML content of a technique from its directory. (T*)"""

    # Get path to YAML file.
    file_entry = get_yaml_file_from_dir(path_to_dir)

    # Load and parses its content.
    with open(file_entry, 'r', encoding="utf-8") as f:
        return yaml.load(unidecode.unidecode(f.read()))


def load_techniques():
    """Loads multiple techniques from the 'atomics' directory."""

    # Get path to atomics directory.
    atomics_path = os.path.join(get_self_path(),
                                ATOMICS_DIR_RELATIVE_PATH)
    normalized_atomics_path = os.path.normpath(atomics_path)

    print("Loading techniques from {}...".format(normalized_atomics_path))

    # Create a dict to accept the techniques that will be loaded.
    techniques = {}

    # For each tech directory in the main directory.
    for atomic_entry in os.listdir(normalized_atomics_path):

        # Make sure that it matches the current pattern.
        if fnmatch.fnmatch(atomic_entry, TECHNIQUE_DIRECTORY_PATTERN):
            print("Loading Technique {}...".format(atomic_entry))

            # Get path to tech dir.
            path_to_dir = os.path.join(normalized_atomics_path, atomic_entry)

            # Load, parse and add to dict.
            tech = load_technique(path_to_dir)
            techniques[atomic_entry] = tech

            # Add path to technique's directory.
            techniques[atomic_entry]["path"] = path_to_dir

    return techniques


##########################################
# Executors
##########################################

def is_valid_executor(exe, self_platform):
    """Validates that the executor can be run on the current platform."""
    if self_platform not in exe["supported_platforms"]:
        return False

    # The "manual" executors need to be run by hand, normally.
    # This script should not be running them.
    if exe["executor"]["name"] == "manual":
        return False

    return True


def get_valid_executors(tech):
    """From a loaded technique, get all executors appropriate for the current platform."""
    return list(filter(lambda x: is_valid_executor(x, get_platform()), tech['atomic_tests']))


def get_executors(tech):
    """From a loaded technique, get all executors."""
    return tech['atomic_tests']


def print_input_arguments(executor):
    """Prints out the input arguments of an executor in a human-readable manner."""
    if "input_arguments" in executor:
        for name, values in executor["input_arguments"].items():
            print("{name}: {description} (default: {default})".format(name=name,
                                                                      description=values["description"],
                                                                      default=values["default"]))


def print_executor(executor):
    """Prints an executor in a human-readable manner."""

    print("\n-----------------------------------------------------------")
    print("Name: " + executor["name"].strip())
    print("Description: " + executor["description"].strip())
    print("Platforms: " + ", ".join(map(lambda x: x.strip(), executor["supported_platforms"])))
    print("\nArguments:")
    print_input_arguments(executor)
    print("\nLauncher: " + executor["executor"]["name"])
    print("Command: " + executor["executor"]["command"] + "\n")


def executor_get_input_arguments(input_arguments):
    """Gets the input arguments from the user, displaying a prompt and converting them."""

    # Empty dict to hold on the parameters.
    parameters = {}
    for name, values in input_arguments.items():

        # If answer, use that.
        answer = input_string("Please provide a parameter for '{name}' (blank for default)".format(name=name))

        # If no answer, use the default.
        if not answer:
            answer = values["default"]

        # Cast parameter to string
        parameters[name] = str(answer)

    return parameters


def print_non_interactive_command_line(technique_name, executor_number, parameters):
    """Prints the comand line to use in order to launch the technique non-interactively."""
    print("In order to run this non-interactively:")
    print("    Python:")
    print("    techniques = runner.AtomicRunner()")
    print("    techniques.execute(\"{name}\", position={pos}, parameters={params})".format(name=technique_name, pos=executor_number, params=parameters))
    print("    Shell Script:")
    print("    python3 runner.py run {name} {pos} --args '{params}' \n".format(name=technique_name, pos=executor_number, params=json.dumps(parameters)))


def interactive_apply_executor(executor, path, technique_name, executor_number):
    """Interactively run a given executor."""

    # Prints information about the executor.
    print_executor(executor)

    # Request if we still want to run this.
    if not yes_or_no("Do you want to run this? "):
        print("Cancelled.")
        return

    # If so, get the input parameters.
    if "input_arguments" in executor:
        parameters = executor_get_input_arguments(executor["input_arguments"])
    else:
        parameters = {}

    # Prints the Command line to enter for non-interactive execution.
    print_non_interactive_command_line(technique_name, executor_number, parameters)

    launcher = convert_launcher(executor["executor"]["name"])
    command = executor["executor"]["command"]
    built_command = build_command(launcher, command, parameters)

    # begin execution with the above parameters.
    execute_command(launcher, built_command, path)


def get_default_parameters(args):
    """Build a default parameters dictionary from the content of the YAML file."""
    return {name: values["default"] for name, values in args.items()}


def set_parameters(executor_input_arguments, given_arguments):
    """Sets the default parameters if no value was given."""

    # Default parameters as decribed in the executor.
    default_parameters = get_default_parameters(executor_input_arguments)

    # Merging default parameters with the given parameters, giving precedence
    # to the given params.
    final_parameters = {**default_parameters, **given_arguments}

    # Cast parameters to string
    for name, value in final_parameters.items():
        final_parameters[name] = str(value)

    return final_parameters


def apply_executor(executor, path, parameters):
    """Non-interactively run a given executor."""

    args = executor["input_arguments"] if "input_arguments" in executor else {}
    final_parameters = set_parameters(args, parameters)

    launcher = convert_launcher(executor["executor"]["name"])
    command = executor["executor"]["command"]
    built_command = build_command(launcher, command, final_parameters)

    # begin execution with the above parameters.
    execute_command(launcher, built_command, path)


##########################################
# Text Input
##########################################

def yes_or_no(question):
    """Asks a yes or no question, and captures input.  Blank input is interpreted as Y."""
    reply = str(input(question+' (Y/n): ')).capitalize().strip()

    if reply == "": #pylint: disable=no-else-return
        return True
    elif reply[0] == 'Y':
        return True
    elif reply[0] == 'N':
        return False

    return yes_or_no("Please enter Y or N.")


def input_string(message):
    """Asks a question and captures the string output."""
    return str(input(message + ': ')).strip()


def parse_number_input(user_input):
    """Converts a string of space-separated numbers to an array of numbers."""
    lst_str = user_input.strip().split(' ')
    return list(map(int, lst_str))


##########################################
# Commands
##########################################

class ManualExecutorException(Exception):
    """Custom Exception that we trigger triggered when we encounter manual executors."""
    pass

def convert_launcher(launcher):
    """Takes the YAML launcher, and outputs an appropriate executable
    to run the command."""

    plat = get_platform()

    # Regular command prompt.
    if launcher == "command_prompt": #pylint: disable=no-else-return
        if plat == "windows": #pylint: disable=no-else-return
            # This is actually a 64bit CMD.EXE.  Do not change this to a 32bits CMD.EXE
            return "C:\\Windows\\System32\\cmd.exe"

        elif plat == "linux":
            # Good ol' Bourne Shell.
            return "/bin/sh"

        elif plat == "macos":
            # I assume /bin/sh is available on OSX.
            return "/bin/sh"

        else:
            # We hit a non-Linux, non-Windows OS.  Use sh.
            print("Warning: Unsupported platform {}! Using /bin/sh.".format(plat))
            return "/bin/sh"

    elif launcher == "powershell":
        return "C:\\Windows\\System32\\WindowsPowerShell\\v1.0\\powershell.exe"

    elif launcher == "sh":
        return "/bin/sh"

    elif launcher == "manual":
        # We cannot process manual execution with this script.  Raise an exception.
        raise ManualExecutorException()

    else:
        # This launcher is not known.  Returning it directly.
        print("Warning: Launcher '{}' has no specific case! Returning as is.")
        return launcher


def build_command(launcher, command, parameters): #pylint: disable=unused-argument
    """Builds the command line that will eventually be run."""

    # Using a closure! We use the replace to match found objects
    # and replace them with the corresponding passed parameter.
    def replacer(matchobj):
        if matchobj.group(1) in parameters:
            val = parameters[matchobj.group(1)]
        else:
            print("Warning: no match found while building the replacement string.")
            val = None

        return val

    # Fix string interpolation (from ruby to Python!) -- ${}
    command = re.sub(r"\$\{(.+?)\}", replacer, command)

    # Fix string interpolation (from ruby to Python!) -- #{}
    command = re.sub(r"\#\{(.+?)\}", replacer, command)

    return command


def execute_subprocess(launcher, command, cwd):
    p = subprocess.Popen(launcher, shell=False, stdin=subprocess.PIPE, stdout=subprocess.PIPE,
                         stderr=subprocess.STDOUT, env=os.environ, cwd=cwd)
    try:

        outs, errs = p.communicate(bytes(command, "utf-8") + b"\n", timeout=COMMAND_TIMEOUT)
        return outs, errs
    except subprocess.TimeoutExpired as e:

        # Display output if it exists.
        if e.output:
            print(e.output)
        if e.stdout:
            print(e.stdout)
        if e.stderr:
            print(e.stderr)
        print("Command timed out!")

        # Kill the process.
        p.kill()
        return "", ""


def print_process_output(outs, errs):
    def clean_output(s):
        # Remove Windows CLI garbage
        s = re.sub(r"Microsoft\ Windows\ \[version .+\]\r?\nCopyright.*(\r?\n)+[A-Z]\:.+?\>", "", s)
        return re.sub(r"(\r?\n)*[A-Z]\:.+?\>", "", s)

    # Output the appropriate outputs if they exist.
    if outs:
        print("Output: {}".format(clean_output(outs.decode("utf-8", "ignore"))), flush=True)
    else:
        print("(No output)")
    if errs:
        print("Errors: {}".format(clean_output(errs.decode("utf-8", "ignore"))), flush=True)

        
def execute_command(launcher, command, cwd):
    """Executes a command with the given launcher."""

    print("\n------------------------------------------------")

   # Replace instances of PathToAtomicsFolder
    atomics = os.path.join(cwd, "..")
    command = command.replace("$PathToAtomicsFolder", atomics)
    command = command.replace("PathToAtomicsFolder", atomics)

    # If launcher is powershell we execute all commands under a single process
    # powershell.exe -Command - (Tell powershell to read scripts from stdin)
    if "powershell" in launcher:
        outs, errs = execute_subprocess([launcher, '-Command', '-'], command, cwd)
        print_process_output(outs, errs)

    else:
        for comm in command.split("\n"):

            # We skip empty lines.  This is due to the split just above.
            if comm == "":
                continue

            # # We actually run the command itself.
            outs, errs = execute_subprocess(launcher, comm, cwd)
            print_process_output(outs, errs)
            
            continue


#########################################
# Hash database
#########################################

def load_hash_db():
    """Loads the hash database from a file, or create the empty file if it did not already exist."""
    hash_db_path = os.path.join(get_self_path(), HASH_DB_RELATIVE_PATH)
    try:
        with open(hash_db_path, 'r') as f:
            return json.load(f)
    except json.JSONDecodeError:
        print("Could not decode the JSON Hash DB!  Please fix the syntax of the file.")
        sys.exit(3)
    except IOError:
        print("File did not exist.  Created a new empty Hash DB.")
        empty_db = {}
        write_hash_db(hash_db_path, empty_db)
        return empty_db


def write_hash_db(hash_db_path, db):
    """Writes the hash DB dictionary to a file."""
    with open(hash_db_path, 'w') as f:
        json.dump(db, f, sort_keys=True, indent=4, separators=(',', ': '))


def check_hash_db(hash_db_path, executor_data, technique_name, executor_position):
    """Checks the hash DB for a hash, and verifies that it corresponds to the current executor data's
    hash.  Adds the hash to the current database if it does not already exist."""
    hash_db = load_hash_db()
    executor_position = str(executor_position)

    # Tries to load the technique section.
    if not technique_name in hash_db:
        print("Technique section '{}' did not exist.  Creating.".format(technique_name))
        # Create section
        hash_db[technique_name] = {}

    new_hash = hashlib.sha256(json.dumps(executor_data).encode()).hexdigest()

    # Tries to load the executor hash.
    if not executor_position in hash_db[technique_name]:
        print("Hash was not in DB.  Adding.")
        # Create the hash, since it does not exist.  Return OK.
        hash_db[technique_name][executor_position] = new_hash

        # Write DB to file.
        write_hash_db(hash_db_path, hash_db)
        return True

    old_hash = hash_db[technique_name][executor_position]

    # If a previous hash already exists, compare both hashes.
    return old_hash == new_hash

def clear_hash(hash_db_path, technique_to_clear, position_to_clear=-1):
    """Clears a hash from the DB, then saves the DB to a file."""
    hash_db = load_hash_db()

    if position_to_clear == -1:
        # We clear out the whole technique.
        del hash_db[technique_to_clear]
    else:
        # We clear the position.
        del hash_db[technique_to_clear][str(position_to_clear)]

    print("Hash cleared.")

    write_hash_db(hash_db_path, hash_db)

#########################################
# Atomic Runner and Main
#########################################

class AtomicRunner():
    """Class that allows the execution, interactive or not, of the various techniques that are part of ART."""

    def __init__(self):
        """Constructor.  Ensures that the techniques are loaded before we can run them."""
        # Loads techniques.
        self.techniques = load_techniques()


    def repl(self):
        """Presents a REPL to the user so that they may interactively run certain techniques."""
        print("Enter the name of the technique that you would like to execute (eg. T1033).  Type 'exit' to quit.")
        i = input("> ").strip()

        while True:
            if i == "exit":
                break
            else:
                if i in self.techniques:
                    self.interactive_execute(i)
                else:
                    print("Technique '{}' does not exist.".format(i))

            i = input("> ").strip()


    def execute(self, technique_name, position=0, parameters=None):
        """Runs a technique non-interactively."""

        parameters = parameters or {}

        print("================================================")
        print("Executing {}/{}\n".format(technique_name, position))

        # Gets the tech.
        tech = self.techniques[technique_name]

        # Gets Executors.
        executors = get_executors(tech)

        try:
            # Get executor at given position.
            executor = executors[position]
        except IndexError:
            print("Out of bounds: this executor is not part of that technique's list!")
            return False

        # Make sure that it is compatible.
        if not is_valid_executor(executor, get_platform()):
            print("Warning: This executor is not compatible with the current platform!")
            return False

        # Check that hash matches previous executor hash or that this is a new hash.
        if not check_hash_db(HASH_DB_RELATIVE_PATH, executor, technique_name, position):
            print("Warning: new executor fingerprint does not match the old one! Skipping this execution.")
            print("To re-enable this test, review this specific executor, test your payload, and clear out this executor's hash from the database.")
            print("Run this: python runner.py clearhash {} {}.".format(technique_name, position))
            return False

        # Launch execution.
        try:
            apply_executor(executor, tech["path"], parameters)
        except ManualExecutorException:
            print("Cannot launch a technique with a manual executor. Aborting.")
            return False

        return True


    def interactive_execute(self, technique_name):
        """Interactively execute a single technique."""

        # Gets the tech.
        tech = self.techniques[technique_name]

        # Gets the compatible executors for this current platform.
        executors = get_valid_executors(tech)

        # If there are none.
        if not executors:
            print("No valid executors for this platform/technique combination!")
            return

        # Display technique info
        print("\n===========================================================")
        print("{} - {}".format(tech["display_name"], tech["attack_technique"]))

        # Get number of executors.
        nb_executors = len(executors)
        if nb_executors > 1:

            # Displays all executors with the index (for the number choice).
            for idx, executor in enumerate(executors):
                # Make it better!
                print("{}. ".format(idx))
                print_executor(executor)

            # Display prompt, and get input as number list.
            while True:
                user_input = input("Please choose your executors: (space-separated list of numbers): ")
                try:
                    numbers = parse_number_input(user_input)
                    for i in numbers:
                        # Interactively apply all chosen executors.
                        interactive_apply_executor(executors[i], tech["path"], tech["attack_technique"], i)
                    break
                except Exception as e: #pylint: disable=broad-except
                    print("Could not parse the input. make sure this is a space-separated list of integers.")
                    print(e)
        else:
            # We only have one executor in this case.
            interactive_apply_executor(executors[0], tech["path"], tech["attack_technique"], 0)


def interactive(args): #pylint: disable=unused-argument
    """Launch the runner in interactive mode."""
    runner = AtomicRunner()
    runner.repl()


def run(args):
    """Launch the runner in non-interactive mode."""
    runner = AtomicRunner()
    runner.execute(args.technique, args.position, json.loads(args.args))


def clear(args):
    """Clears a stale hash from the Hash DB."""
    clear_hash(HASH_DB_RELATIVE_PATH, args.technique, args.position)


def main():
    """Main function, called every time this script is launched rather than imported."""
    parser = argparse.ArgumentParser(description="Allows the automation of tests in the Atomic Red Team repository.")
    subparsers = parser.add_subparsers()

    parser_int = subparsers.add_parser('interactive', help='Runs the techniques interactively.')
    parser_int.set_defaults(func=interactive)

    parser_run = subparsers.add_parser('run', help="Ponctually runs a single technique / executor pair.")
    parser_run.add_argument('technique', type=str, help="Technique to run.")
    parser_run.add_argument('position', type=int, help="Position of the executor in technique to run.")
    parser_run.add_argument('--args', type=str, default="{}", help="JSON string representing a dictionary of arguments (eg. '{ \"arg1\": \"val1\", \"arg2\": \"val2\" }' )")
    parser_run.set_defaults(func=run)

    parser_clear = subparsers.add_parser('clearhash', help="Clears a hash from the database, allowing the technique to be run once again.")
    parser_clear.add_argument('technique', type=str, help="Technique to run.")
    parser_clear.add_argument('--position', '-p', type=int, default=-1, help="Position of the executor in technique to run.")
    parser_clear.set_defaults(func=clear)

    try:
        args = parser.parse_args()
        args.func(args)
    except AttributeError:
        parser.print_help()


if __name__ == "__main__":
    main()
