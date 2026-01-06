# T1546.018 - Event Triggered Execution: Python Startup Hooks
# Overview
Adversaries may establish persistence or execute arbitrary code by abusing Python's path configuration (.pth) files. When the Python interpreter starts, it processes .pth files in the site-packages directory. If a line in a .pth file begins with an import statement, Python executes that line as code.

These tests demonstrate the technique by creating a localized virtual environment and dropping a .pth file that triggers a subprocess (like a calculator or terminal message) the moment the interpreter is initialized.

# Supported Platforms
Windows (PowerShell)

Linux (Bash)

macOS (Bash)

# Atomic Tests

# Test 1: Python Startup Hook Execution via .pth (Windows)
GUID: 7d8a6f3c-2b1d-4b59-9e3a-8c4a9c9b1f12

Description: Creates a virtual environment and injects a hook to launch calc.exe.

Prerequisites: Python 3 must be installed and in the system PATH.

# Test 2: Python Startup Hook Execution via .pth (Linux)
GUID: 3f0d6e5a-6a4f-4a0f-b9a7-1c1f7e3f8d21

Description: Creates a virtual environment and injects a hook that prints a success message to the terminal via os.system. This is optimized for headless/server environments.

Prerequisites: Python 3 and the venv module.

# Test 3: Python Startup Hook Execution via .pth (macOS)
GUID: 9c2b8e14-4a9f-4b1a-b7e2-6c9f0e5c4b33

Description: Creates a virtual environment and injects a hook to launch Calculator.app.

Prerequisites: Python 3 (standard or Homebrew).

Execution Instructions
Automatic Execution (Invoke-AtomicRedTeam)
Run the test for your specific platform:

PowerShell

# Run the macOS test
Invoke-AtomicTest T1546.018 -TestNumbers 3

# Run the Linux test
Invoke-AtomicTest T1546.018 -TestNumbers 2

# Run the Windows test
Invoke-AtomicTest T1546.018 -TestNumbers 1

# Cleanup after testing
Invoke-AtomicTest T1546.018 -TestNumbers [1 or 2 or 3] -Cleanup

# Manual Testing on Windows (No Framework)
If you want to test the technique manually to see exactly how it behaves without using Invoke-AtomicTest, follow these steps in a PowerShell terminal:

# Setup the Environment:
# Create a temporary virtual environment
python -m venv $env:TEMP\atc_venv

# Identify the site-packages directory
$SitePackages = & "$env:TEMP\atc_venv\Scripts\python.exe" -c "import site; print(site.getsitepackages()[1])"

# Inject the Hook:
# Create a .pth file that imports subprocess to launch an app
'import subprocess; subprocess.Popen(["calc.exe"])' | Out-File -Encoding ASCII "$SitePackages\hook.pth"

# Trigger Execution: Simply starting the Python interpreter inside that environment will trigger the hook.
& "$env:TEMP\atc_venv\Scripts\python.exe" -c "print('Python is running')"

# Manual Execution (CLI)
You can manually replicate the macOS/Linux behavior to see how the injection works:

Bash

# 1. Setup a dummy environment
python3 -m venv /tmp/test_env
SP_DIR=$(/tmp/test_env/bin/python -c "import site; print(site.getsitepackages()[0])")

# 2. Drop the malicious hook
echo "import os; os.system('echo \"Exploit Triggered\"')" > "$SP_DIR/test.pth"

# 3. Trigger the hook by simply starting Python
/tmp/test_env/bin/python -c "exit()"

# Detection and Observation
# Process Tree Observation
During execution, monitor your process tree. You will notice the Python interpreter spawning a child process immediately upon startup, even if no script was explicitly called.

# File System Monitoring
Monitor for the creation of .pth files in any site-packages or dist-packages directory.

# Indicator: Files containing lines starting with import .

# YARA: Use a rule that scans for the import keyword followed by subprocess or os within .pth files.

# References

https://attack.mitre.org/techniques/T1546/018/
https://docs.python.org/3/library/site.html
https://dfir.ch/posts/publish_python_pth_extension/
