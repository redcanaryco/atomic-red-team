import csv
import os
from typing import get_args, List

from atomic_red_team.sources import AtomicRedTeam, Platform, Atomic, flatten, AttackAPI

all_platforms: List[Platform] = list(get_args(Platform))
atomic_red_team = AtomicRedTeam()
attack_api = AttackAPI()

tactics = [
    "reconnaissance",
    'initial-access',
    'execution',
    'persistence',
    'privilege-escalation',
    'defense-evasion',
    'credential-access',
    'discovery',
    'lateral-movement',
    'collection',
    'exfiltration',
    'command-and-control',
    'impact'
]
TACTIC_ORDER = {k: v for v, k in enumerate(tactics)}


def get_technique_name(technique_id: str) -> str:
    return list(filter(lambda x: x.attack_technique == technique_id, atomic_red_team.atomic_techniques))[0].display_name


def get_rows_from_atomic(atomic: Atomic) -> List[List[str]]:
    technique_number, test_number = atomic.test_number.split("-")
    tactics = attack_api.get_tactics_for_technique(technique_number)
    return [[
        t,
        technique_number,
        get_technique_name(technique_number),
        test_number,
        atomic.name,
        atomic.auto_generated_guid,
        atomic.executor.name
    ] for t in tactics]


def create_index_csv(file_path: str, atomics: List[Atomic]) -> None:
    with open(file_path, 'w', newline='') as file:
        writer = csv.writer(file, lineterminator=os.linesep)
        writer.writerow(
            ["Tactic", "Technique #", "Technique Name", "Test #", "Test Name", "Test GUID", "Executor Name"])
        writer.writerows(sorted(flatten([get_rows_from_atomic(a) for a in atomics]), key=lambda x: TACTIC_ORDER[x[0]]))


index_path = f"{atomic_red_team.atomics_path}/Indexes"
csv_index = f"{index_path}/Indexes-CSV"
create_index_csv(f"{csv_index}/index.csv", atomic_red_team.atomics)

for platform in all_platforms:
    atomics = atomic_red_team.get_atomics_by_platform(platform)
    file_path = f"{csv_index}/{platform.replace(':', '-')}-index.csv"
    create_index_csv(file_path, atomics)
