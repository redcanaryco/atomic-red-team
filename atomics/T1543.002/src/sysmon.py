#!/usr/bin/env python3
import os
import subprocess
import sys

pglog_path = sys.argv[1] if len(sys.argv) > 1 else "/tmp/pglog"
pglog_dir = os.path.dirname(pglog_path)
if pglog_dir:
    os.makedirs(pglog_dir, exist_ok=True)

with open(pglog_path, "w") as f:
    f.write("#!/bin/sh\n")
os.chmod(pglog_path, 0o755)
subprocess.Popen([pglog_path], start_new_session=True)
