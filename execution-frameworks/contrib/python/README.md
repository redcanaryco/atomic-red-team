Introduction
============

ART Attack Runner is a wrapper made to automate the attacks described in the [Atomic Red Team Git Repository](https://github.com/redcanaryco/atomic-red-team).  It allows running the various techniques via shell scripts (bash or powershell), via Python scripts or interactively.

Installing
==========

This script runs on Windows and Linux at the moment, and was tested against Python 3.6.  Python 2.7 is unsupported at the moment.

To install the script, pull the Git repo from [here](https://github.com/redcanaryco/atomic-red-team), move to the execution-frameworks/python directory and install the tool's dependencies:

```
pip install -r requirements.txt
```

This will pull in the external packages that are required to run.

Installing on Windows
---------------------

Here are some more extensive instructions to install this software on Windows.


- Ensure that Git is installed.  If it is not, get it from the [official site](https://git-scm.com/downloads). If you right-click within a folder, you should have a "Git Bash Here" option.
- Ensure Python 3 is installed (3.7 is known to work).  If it is not installed, get it [here](https://www.python.org/getit/). 
- Ensure pip (Python package manager) is installed.  It is normally installed when the python package is installed, so make sure that the step above has completed properly.
- Add "%USERPROFILE%\AppData\Local\Programs\Python\Python37" and "%USERPROFILE%\AppData\Local\Programs\Python\Python37\Scripts" to the PATH environment variable.  This adds pip and the python executable to the PATH, allowing them to be run more conveniently from the command line.
- Open a shell with the "Git Bash Here" contextual menu option. You should be able to run the "python" command successfully. "python -V" should indicate Python 3 rather than python 2.7.
- Upgrade pip to the latest version: "pip install --upgrade pip"
- Clone the ART Attack Runner Git repository on the Desktop directly.  Open Git Bash on the Desktop and type the following: "git clone https://github.com/redcanaryco/atomic-red-team".  - Move into the cloned repository, and run the installation commands: "pip install -r requirements.txt".  This will install the dependencies of the project.
- Try to run the script: "python runner.py interactive".  Try to run the technique of your choice.


Usage
=====

The tool may be used in three different ways: interactively, in Python scripts, or via shell scripts.

Interactive usage
-----------------

Run the tool like follows:

```
python runner.py interactive
```

You will be dropped in a REPL that will allow you to interact with the system.  Here is an example session:

    Enter the name of the technique that you would like to execute (eg. T1033).  Type 'exit' to quit.
    > T1033
    
    ===========================================================
    System Owner/User Discovery - T1033
    
    -----------------------------------------------------------
    Name: System Owner/User Discovery
    Description: Identify System owner or users on an endpoint
    Platforms: windows
    
    Arguments:
    computer_name: Name of remote computer (default: computer1)
    
    Launcher: command_prompt
    Command: cmd.exe /C whoami
    quser
    quser /SERVER:"${computer_name}"
    wmic useraccount get /ALL
    qwinsta.exe /server:${computer_name}
    qwinsta.exe
    for /F "tokens=1,2" %i in ('qwinsta /server:${computer_name} ^| findstr "Active Disc"') do @echo %i | find /v "#" | find /v "c
    onsole" || echo %j > usernames.txt
    @FOR /F %n in (computers.txt) DO @FOR /F "tokens=1,2" %i in ('qwinsta /server:%n ^| findstr "Active Disc"') do @echo %i | find
     /v "#" | find /v "console" || echo %j > usernames.txt
    
    
    Do you want to run this?  (Y/n): y
    Please provide a parameter for 'computer_name' (blank for default): MY_COMPUTER
    
    ------------------------------------------------
    
    Running: cmd.exe /C whoami
    Output: olivier.lemelin


In Python Scripts
-----------------

To use in a Python script, simply import the script as a package, create an `AtomicRunner` class instance, and use it as follows:

    # Import the runner (the script "runner.py")
    import runner
    def main():
    
        # Instantiate the AtomicRunner class instance.
        techniques = runner.AtomicRunner()
    
        # Execute the chosen technique the following way:
        # First parameter ("T1033"): Name of the technique to execute.
        # Second parameter (0): Position of the executor in the list.
        #     In order to find this number, launch an interactive execution. Just before actually launching
        #     the command, the system will display what line needs to be added to your script.
        #     If there is only one executor, you may omit this parameter.
        # Third parameter ({"computer_name": "DA2CTC"}): Arguments to pass to the executor.
        #     This is a dictionary of the arguments to pass to the executor.  Both the key and value are
        #     to be passed as strings.  You may also launch an interactive execution, and the script will
        #     tell you what needs to be entered to invoke this test.
        techniques.execute("T1033", position=0, parameters={"computer_name": "DA2CTC"})
    
    if __name__ == "__main__":
        main()

In Shell Scripts
----------------

To use in a shell script, a CLI interface has been produced.  YOu may use it the following way:

```
 python runner.py run T1033 0 --args '{"computer_name": "DA2CTC"}'
```

If you're unsure of how to use this, you may also launch an interactive execution, and just before actually launching the command, the system will report the line that needs to be added to your shell script in order to run it as desired.

Help!
=====

If you're ever unsure of the sytax to invoke the script, you may use the help function from the script:

`python runner.py -h`

`python runner.py interactive -h`

`python runner.py run -h`

Gotchas
-------

Here are a few things you might want to keep in mind as you go along:

- The script "moves" into the ART technique's directory before launching the command.  If your parameters include a Path, it will need to take this in consideration (or you may want to use fully qualified paths)


FAQ
---

Q. I am receiving the following error, what does this mean? : "Warning: new executor fingerprint does not match the old one! Skipping this execution"

A. Since executors are not associated to an ID, but only to a position in a YAML file, we need to make sure that we are running the right executor at any time.  As such, we take a hash of an executor before it is run, and if they're different, we spit out this error.  To fix this, simply do what the script asks you to do: Make sure that you are executing the right executor with the right parameters using the interactive mode, and run the clearhash function, which removes the hash from the database.  You should be good to go afterwards.
