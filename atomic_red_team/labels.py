import fnmatch
import json
import os
import re
from dataclasses import dataclass

import requests
import yaml
from yaml.loader import SafeLoader


def get_technique_from_filename(filename):
    """Returns technique(Txxx.xxx) from the filename specified"""
    return re.findall(r"T[.\d]{4,8}", filename)[0]


@dataclass
class ChangedAtomic:
    """Returns atomic technique with test number which can be later used to run atomics in CI/CD pipelines."""

    technique: str
    test_number: int
    data: dict


class SafeLineLoader(SafeLoader):
    def construct_mapping(self, node, deep=False):
        """Add line number to each block of the atomic test."""
        mapping = super(SafeLineLoader, self).construct_mapping(node, deep=deep)
        # Add 1 so line numbering starts at 1
        mapping["__line__"] = node.start_mark.line + 1
        return mapping


class GithubAPI:
    labels = {
        "windows": "windows",
        "macos": "macOS",
        "linux": "linux",
        "azure-ad": "ADFS",
        "containers": "containers",
        "iaas:gcp": "cloud",
        "iaas:aws": "cloud",
        "iaas:azure": "cloud",
        "office-365": "cloud",
        "google-workspace": "cloud",
    }

    maintainers = {
        "windows": ["clr2of8", "MHaggis"],
        "linux": ["josehelps", "cyberbuff"],
        "macos": ["josehelps", "cyberbuff"],
        "containers": ["patel-bhavin"],
        "iaas:gcp": ["patel-bhavin"],
        "iaas:aws": ["patel-bhavin"],
        "iaas:azure": ["patel-bhavin"],
        "azure-ad": ["patel-bhavin"],
        "google-workspace": ["patel-bhavin"],
        "office-365": ["patel-bhavin"],
    }

    def __init__(self, token):
        self.token = token

    @property
    def headers(self):
        return {
            "Authorization": f"Bearer {self.token}",
            "X-GitHub-Api-Version": "2022-11-28",
            "Accept": "application/vnd.github+json",
        }

    def get_atomic_with_lines(self, file_url: str):
        """Get Atomic Technique along with line number for each of the atomics."""
        r = requests.get(file_url, headers=self.headers)
        assert r.status_code == 200
        return yaml.load(r.text, Loader=SafeLineLoader)

    def get_files_for_pr(self, pr):
        """Get new and modified files in the `atomics` directory changed in a PR."""
        response = requests.get(
            f"https://api.github.com/repos/{os.getenv('GITHUB_REPOSITORY')}/pulls/{pr}/files",
            headers=self.headers,
            timeout=15,
        )
        assert response.status_code == 200
        files = response.json()
        return filter(
            lambda x: x["status"] in ["added", "modified"]
            and fnmatch.fnmatch(x["filename"], "atomics/T*/T*.yaml"),
            files,
        )

    def get_tests_changed(self, pr: str):
        """Get all the tests changed in a PR"""
        tests = []
        start = 0
        files = self.get_files_for_pr(pr)
        for file in files:
            data = self.get_atomic_with_lines(file["raw_url"])
            technique = get_technique_from_filename(file["filename"])
            if file["status"] == "added":
                # New file; run the entire technique; Invoke-AtomicTest Txxxx
                tests += [
                    ChangedAtomic(technique=technique, test_number=index + 1, data=t)
                    for index, t in enumerate(data["atomic_tests"])
                ]
            else:
                changed_lines = []
                count = 0
                for line in file["patch"].split("\n"):
                    if line.startswith("@@"):
                        x, y = re.findall(r"\d{1,3},\d{1,3}", line)
                        start = int(x.split(",")[0])
                        count = -1
                    elif line.startswith("+"):  # only take count of added lines
                        changed_lines.append(start + count)
                    elif line.startswith("-"):
                        count -= 1
                    count += 1
                atomics = data["atomic_tests"]
                for index, t in enumerate(atomics):
                    curr_atomic_start = atomics[index]["__line__"]
                    if index + 1 < len(atomics):
                        curr_atomic_end = atomics[index + 1]["__line__"]
                    else:
                        curr_atomic_end = start + 60
                    changes_in_current_atomic = [
                        i
                        for i in changed_lines
                        if i > curr_atomic_start and i < curr_atomic_end
                    ]
                    if len(changes_in_current_atomic) > 0:
                        tests.append(
                            ChangedAtomic(
                                technique=technique, test_number=index + 1, data=t
                            )
                        )

        return tests

    def save_labels_and_maintainers(self, pr):
        """Saves labels and maintainers into `pr/labels.json` which would be later used by a workflow run."""
        tests = self.get_tests_changed(pr)
        platforms = set()
        for t in tests:
            platforms.update(t.data["supported_platforms"])
        labels = []
        maintainers = []
        for p in platforms:
            if p in self.labels:
                labels.append(self.labels[p])
            if p in self.maintainers:
                maintainers += self.maintainers[p]
        os.mkdir("pr")

        with open("pr/changedfiles.json", "w") as f:
            x = [{"name": t.technique, "test_number": t.test_number} for t in tests]
            f.write(json.dumps(x))

        with open("pr/labels.json", "w") as f:
            j = {"pr": pr, "labels": labels, "maintainers": maintainers}
            f.write(json.dumps(j))
