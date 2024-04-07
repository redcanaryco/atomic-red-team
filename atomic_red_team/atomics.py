import csv
import glob
from collections import defaultdict
from functools import cache
from itertools import chain

from common import atomics_path, attack
from models import Technique, Index, Platform
from validator import yaml

ordered_tactics = [
    "reconnaissance",
    "initial-access",
    "execution",
    "persistence",
    "privilege-escalation",
    "defense-evasion",
    "credential-access",
    "discovery",
    "lateral-movement",
    "collection",
    "exfiltration",
    "command-and-control",
    "impact",
]
mitre_platforms_to_platforms = {
    "Windows": "windows",
    "Linux": "linux",
    "macOS": "macos",
    "Office 365": "office-365",
    "Azure AD": "azure-ad",
    "Google Workspace": "google-workspace",
    "SaaS": "saas",
    "IaaS": "iaas",
    "Containers": "containers"
}
platforms = list(Platform.__args__)
platforms.append("")


class Atomics:
    techniques = []

    def __init__(self):
        for file in glob.glob(f"{atomics_path}/T*/T*.yaml"):
            with open(file, "r") as f:
                atomic = yaml.load(f)
                self.techniques.append(Technique(**atomic))

    @cache
    def get_techniques(self):
        return attack.get_techniques(
            include_subtechniques=True, remove_revoked_deprecated=True
        )

    @cache
    def generate_attack_patterns_to_tactics(self) -> dict:
        attack_patterns_to_tactics = {}
        attack_patterns = self.get_techniques()

        for ap in attack_patterns:
            attack_id = ap.external_references[0].external_id
            kill_chain_phases = [p.phase_name for p in ap.kill_chain_phases]
            attack_patterns_to_tactics[attack_id] = list(
                set(kill_chain_phases) & set(ordered_tactics)
            )
        return attack_patterns_to_tactics

    def generate_platform_to_tactics_to_techniques(self) -> dict:
        platform_to_tactics_to_techniques = {}
        for p in platforms:
            platform_to_tactics_to_techniques[p] = defaultdict(list)
        attack_patterns = self.get_techniques()

        for ap in attack_patterns:
            attack_id = ap.external_references[0].external_id
            kill_chain_phases = list(
                set([p.phase_name for p in ap.kill_chain_phases]) & set(ordered_tactics)
            )
            for phase in kill_chain_phases:
                for platform in ap.x_mitre_platforms:
                    if platform not in mitre_platforms_to_platforms:
                        continue

                    platform_to_tactics_to_techniques[mitre_platforms_to_platforms[platform]][phase].append({
                        "id": attack_id,
                        "name": ap.name
                    })
        return platform_to_tactics_to_techniques

    def generate_index(self):
        index = {}
        attack_patterns_to_tactics = self.generate_attack_patterns_to_tactics()

        for platform in platforms:
            index[platform] = defaultdict(set)

        for technique in self.techniques:
            for atomic in technique.atomic_tests:
                for platform in atomic.supported_platforms:
                    for tactic in attack_patterns_to_tactics[
                        technique.attack_technique
                    ]:
                        index_model = Index(
                            **{
                                "tactic": tactic,
                                "platform": platform,
                                "attack_technique": technique.attack_technique,
                                "display_name": technique.display_name,
                                "test_number": atomic.test_number.split("-")[1],
                                "name": atomic.name,
                                "auto_generated_guid": str(atomic.auto_generated_guid),
                                "executor": atomic.executor.name,
                            }
                        )
                        index[platform][tactic].add(index_model)
                        index[""][tactic].add(index_model)
        return index

    def generate_csv_indices(self):
        generated_index = self.generate_index()

        for p in platforms:
            headers = [
                "Tactic",
                "Technique #",
                "Technique Name",
                "Test #",
                "Test Name",
                "Test GUID",
                "Executor Name",
            ]
            filename = f"{atomics_path}/Indexes/Indexes-CSV/"
            if p:
                filename += f'{p.replace(":", "-")}-index.csv'
            else:
                filename += "index.csv"

            rows = [generated_index[p][tactic] for tactic in ordered_tactics]
            rows = sorted(
                [r.to_csv() for r in list(chain.from_iterable(rows))],
                key=lambda x: (ordered_tactics.index(x[0]), x[1], x[3]),
            )
            if len(rows) > 0:
                with open(filename, mode="w", newline="") as file:
                    csv_writer = csv.writer(
                        file, delimiter=",", quotechar='"', quoting=csv.QUOTE_MINIMAL
                    )
                    csv_writer.writerow(headers)
                    csv_writer.writerows(rows)

    def generate_md_indices(self):
        generated_index = self.generate_platform_to_tactics_to_techniques()

        for p in generated_index.keys():
            filename = f"{atomics_path}/Indexes/Indexes-Markdown/"
            if p:
                filename += f'{p.replace(":", "-")}-index.md'
            else:
                filename += "index.md"

            with open(filename, mode="w") as file:
                for tactic in ordered_tactics:
                    ts = generated_index[p][tactic]
                    if len(ts) > 0:
                        file.write(f"# {tactic}\n")
                        for technique in sorted(ts, key=lambda x: x["id"]):
                            t = list(filter(lambda x: x.attack_technique == technique["id"], self.techniques))
                            if len(t) > 0 and any([p in atomic.supported_platforms for atomic in t[0].atomic_tests]):
                                display_name = t[0].display_name
                                file.write(
                                    f"- [{technique['id']} {display_name}](../../{technique['id']}/{technique['id']}.md)\n"
                                )
                                for test in t[0].atomic_tests:
                                    if p in test.supported_platforms:
                                        file.write(
                                            f"  - Atomic Test #{test.test_number.split('-')[1]}: {test.name} [{p}]\n"
                                        )
                            else:
                                file.write(
                                    f"- {technique['id']} {technique['name']} [CONTRIBUTE A TEST](https://github.com/redcanaryco/atomic-red-team/wiki/Contributing)\n"
                                )

                        file.write("\n")
