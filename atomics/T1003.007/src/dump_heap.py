#!/usr/bin/env python
'''Dump a process's heap space to disk
Usage:
    python dump_proc.py <PID> <filepath>
'''
import argparse
import platform
parser = argparse.ArgumentParser(description='Dump a process\'s heap space to disk')
parser.add_argument('pid', type=int, help='ID of process to dump')
parser.add_argument('filepath', help='A filepath to save output to')
args = parser.parse_args()
process_id = args.pid
output_file = args.filepath
if platform.system() == "Linux":
  with open("/proc/{}/maps".format(process_id), "r") as maps_file:
      # example: 5566db1a6000-5566db4f0000 rw-p 00000000 00:00 0    [heap]
      heap_line = next(filter(lambda line: "[heap]" in line, maps_file))
      heap_range = heap_line.split(' ')[0]
      mem_start = int(heap_range.split('-')[0], 16)
      mem_stop = int(heap_range.split('-')[1], 16)
      mem_size = mem_stop - mem_start
elif platform.system() == "FreeBSD":
  import subprocess
  procstat_output = subprocess.check_output(["procstat", "-v", str(process_id)], universal_newlines=True)
  heap_line = None
  for line in procstat_output.splitlines():
      if "rw-" in line and "sw" in line:
          heap_line = line
          break
  if not heap_line:
      for line in procstat_output.splitlines():
          if "rw-" in line and not (".so" in line or "/lib/" in line):
              heap_line = line
              break
  columns = heap_line.split()
  mem_start = int(columns[1], 16)
  mem_stop = int(columns[2], 16)
  mem_size = mem_stop - mem_start
with open("/proc/{}/mem".format(process_id), "rb") as mem_file:
    mem_file.seek(mem_start, 0)
    heap_mem = mem_file.read(mem_size)
with open(output_file, "wb") as ofile:
    ofile.write(heap_mem)
