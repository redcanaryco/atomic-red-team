from os.path import dirname, realpath

from mitreattack.stix20 import MitreAttackData

base_path = dirname(dirname(realpath(__file__)))
atomics_path = f"{base_path}/atomics"
used_guids_file = f"{atomics_path}/used_guids.txt"
stix_filepath = f"{base_path}/atomic_red_team/enterprise-attack.json"

attack = MitreAttackData(stix_filepath)
