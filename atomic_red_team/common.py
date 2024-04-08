from os.path import dirname, realpath

base_path = dirname(dirname(realpath(__file__)))
atomics_path = f"{base_path}/atomics"
used_guids_file = f"{atomics_path}/used_guids.txt"
