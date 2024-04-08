import csv
import glob
import json
from collections import defaultdict
from functools import lru_cache
from itertools import chain

from attack import MitreEnrichedTechnique
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
    "IaaS": "iaas",
    "Containers": "containers",
    "All": "",
}
platforms = list(Platform.__args__)
platforms.append("")
# We dont have any SaaS tests yet. So disabling indexing for SaaS
platforms.remove("saas")


class Atomics:
    techniques = []  # contains Atomic Red Team techniques
    attack_techniques = []  # contains MITRE ATT&CK techniques

    def __init__(self):
        for file in glob.glob(f"{atomics_path}/T*/T*.yaml"):
            with open(file, "r") as f:
                atomic = yaml.load(f)
                self.techniques.append(Technique(**atomic))

    @lru_cache(maxsize=None)
    def get_techniques(self):
        ts = {t.attack_technique: t for t in self.techniques}
        attack_patterns = attack.get_techniques(
            include_subtechniques=True, remove_revoked_deprecated=True
        )
        techniques = []
        for ap in attack_patterns:
            t = MitreEnrichedTechnique(**json.loads(ap.serialize()))
            t.technique = ts.get(t.attack_id)
            techniques.append(t)
        return techniques

    def generate_platform_to_tactics_to_techniques(self) -> dict:
        platform_to_tactics_to_techniques = {p: defaultdict(list) for p in platforms}

        for ap in self.get_techniques():
            for phase in ap.phases:
                platform_to_tactics_to_techniques[""][phase].append(ap)
                for platform in ap.platforms:
                    if platform not in mitre_platforms_to_platforms:
                        continue
                    art_platform = mitre_platforms_to_platforms[platform]
                    platform_to_tactics_to_techniques[art_platform][phase].append(ap)

        return platform_to_tactics_to_techniques

    def generate_index(self):
        attack_patterns_to_tactics = {
            t.attack_id: t.phases for t in self.get_techniques()
        }

        index = {platform: defaultdict(set) for platform in platforms}

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

    def generate_markdown_index(self):
        def fname(platform):
            f = f"{atomics_path}/Indexes/Indexes-Markdown/"
            if platform:
                f += f'{platform.replace(":", "-")}-index.md'
            else:
                f += "index.md"
            return f

        generated_index = self.generate_platform_to_tactics_to_techniques()
        art_platforms_to_mitre = dict(
            (v, k) for k, v in mitre_platforms_to_platforms.items()
        )

        for platform in mitre_platforms_to_platforms.values():
            filename = fname(platform)
            content = f"# {art_platforms_to_mitre[platform]} Atomic Tests by ATT&CK Tactic & Technique\n\n"
            for tactic in ordered_tactics:
                techniques = sorted(generated_index[platform][tactic], key=lambda x: x.attack_id)
                if len(techniques) > 0:
                    content += f"# {tactic}\n\n"
                    for technique in techniques:
                        if technique.technique and technique.includes_platform(platform):
                            attack_id = technique.attack_id
                            display_name = technique.technique.display_name
                            content += f"- [{attack_id} {display_name}](../../{attack_id}/{attack_id}.md)\n"

                            for test in technique.technique.atomic_tests:
                                test_platforms = None
                                if "iaas" in platform:
                                    test_platforms = ', '.join(
                                        list(filter(lambda x: "iaas" in x, test.supported_platforms)))
                                if platform == "":
                                    test_platforms = ', '.join(test.supported_platforms)
                                elif platform in test.supported_platforms:
                                    test_platforms = platform
                                if test_platforms:
                                    content += f"  - Atomic Test #{test.test_number.split('-')[1]}: {test.name} [{test_platforms}]\n"
                        else:
                            content += f"- {technique.attack_id} {technique.name} [CONTRIBUTE A TEST](https://github.com/redcanaryco/atomic-red-team/wiki/Contributing)\n"
                    content += "\n"
                with open(filename, mode="w") as file:
                    file.write(content)
