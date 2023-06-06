import fnmatch
import glob
import os
from os import DirEntry
import yaml
import sys
from jsonschema import validate, ValidationError
from collections import defaultdict


class BaseError(Exception):
    def __init__(self, path):
        self.path = path


class InvalidPath(BaseError):
    def __str__(self):
        return f"Invalid path. `src` and `bin` are the only two directories supported."


class InvalidFileName(BaseError):
    def __str__(self):
        return f"Invalid filename. Rename file from .yml to .yaml"


class UnusedArgument(BaseError):
    def __init__(self, path, argument, test_number):
        super().__init__(path)
        self.argument = argument
        self.test_number = test_number

    def __str__(self):
        return f"Unused Input Argument {self.argument} for test number {self.test_number}"


class Validator:
    errors = defaultdict(list)

    def __init__(self):
        with open(f"{os.path.dirname(os.path.abspath(__file__))}/atomic-red-team.schema.yaml", "r") as f:
            self.schema = yaml.safe_load(f)

    def validate(self, obj: DirEntry):
        if obj.is_file():
            if fnmatch.fnmatch(obj.name, "*.y*ml"):
                self.validate_file(obj)
        if obj.is_dir():
            self.validate_directory(obj)

    def validate_file(self, file: DirEntry):
        """Performs file validation"""
        self.validate_yaml_extension(file)
        self.validate_input_args(file)
        self.validate_json_schema(file)

    def validate_input_args(self, file: DirEntry):
        """Validates whether the defined input args are used."""
        with open(file.path, "r") as f:
            atomic = yaml.safe_load(f)
            for index, t in enumerate(atomic["atomic_tests"]):
                if args := t.get("input_arguments"):
                    for k in list(args.keys()):
                        variable = f"#{{{k}}}"
                        executor = t.get("executor", {})
                        deps = t.get("dependencies", [])

                        if executor:
                            commands = [executor.get("command"), executor.get("cleanup_command"), executor.get("steps")]
                        if deps:
                            commands += [d.get("get_prereq_command") for d in deps]
                            commands += [d.get("prereq_command") for d in deps]
                        commands = filter(lambda x: x is not None, commands)

                        if not any([variable in c for c in commands]):
                            self.errors[file.path].append(UnusedArgument(file.path, k, index + 1))

    def validate_yaml_extension(self, file: DirEntry):
        """Validates the yaml extension"""
        if fnmatch.fnmatch(file.path, "*.yml"):
            self.errors[file.path].append(InvalidFileName(file.path))

    def validate_json_schema(self, file: DirEntry):
        """Validates the yaml file against the schema."""
        with open(file.path, "r") as f:
            atomic = yaml.safe_load(f)
            try:
                validate(
                    instance=atomic,
                    schema=self.schema
                )
            except Exception as e:
                self.errors[file.path].append(e)

    def validate_directory(self, directory: DirEntry):
        """Performs directory validation"""
        self.validate_directory_path(directory)

    def validate_directory_path(self, directory: DirEntry):
        """Validated whether the directory is a allowed directory name (`src` or `bin`) """
        if directory.name not in ["src", "bin"]:
            self.errors[directory.path].append(InvalidPath(directory.path))

    def print_errors(self):
        """Output errors in a human friendly way."""
        for i, errors in self.errors.items():
            print(f"Error occurred with {i}.")
            print("Each of the following are why it failed:")
            for error in errors:
                if isinstance(error, BaseError):
                    print(f"\n\t{error}\n")
                elif isinstance(error, ValidationError):
                    if "auto_generated_guid" in error.json_path:
                        print(f"\n\tGUIDs are auto generated. You can remove {error.json_path}\n")
                    else:
                        if (context := error.context) and len(context) > 0:
                            print("\n\tIt failed because of one of the following reasons:")
                            messages = '\n\t\t'.join([c.message for c in context])
                            print(f"\n\t\t{messages}")
                        else:
                            print(f"\n\t{error}\n")
                        print(f"\nThe JSON Path is {error.json_path}\n")
                else:
                    print(f"\n\t{error}\n")


validator = Validator()

for folder in glob.glob('./atomics/T*'):
    for item in os.scandir(folder):
        validator.validate(item)

if len(validator.errors) > 0:
    print("Validation Failed")
    validator.print_errors()
    sys.exit(1)
else:
    print("Validation Successful")
