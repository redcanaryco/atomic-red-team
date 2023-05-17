import fnmatch
import re
import sys
from dataclasses import dataclass

import click
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
        mapping['__line__'] = node.start_mark.line + 1
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
        "iaas:azure": "cloud"
    }

    maintainers = {
        "windows": ["clr2of8", "MHaggis"],
        "linux": ["josehelps", "cyberbuff"],
        "macos": ["josehelps", "cyberbuff"],
        "containers": ["patel-bhavin"],
        "iaas:gcp": ["patel-bhavin"],
        "iaas:aws": ["patel-bhavin"],
        "iaas:azure": ["patel-bhavin"],
        "azure-ad": ["patel-bhavin"]
    }

    def __init__(self, token):
        self.token = token

    @property
    def headers(self):
        return {
            "Authorization": f"Bearer {self.token}",
            "X-GitHub-Api-Version": "2022-11-28",
            "Accept": "application/vnd.github+json"
        }

    def get_atomic_with_lines(self, file_url: str):
        """Get Aromic Technique along with line number for each of the atomics."""
        r = requests.get(file_url, headers=self.headers)
        assert r.status_code == 200
        return yaml.load(r.text, Loader=SafeLineLoader)

    def get_files_for_pr(self, pr):
        """Get new and modified files in the `atomics` directory changed in a PR."""
        response = requests.get(f"https://api.github.com/repos/redcanaryco/atomic-red-team/pulls/{pr}/files",
                                headers=self.headers, timeout=15)
        print(response.status_code, response.reason)
        assert response.status_code == 200
        files = response.json()
        return filter(
            lambda x: x["status"] in ["added", "modified"] and fnmatch.fnmatch(x["filename"], "atomics/T*/T*.yaml"),
            files)

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
                tests += [ChangedAtomic(technique=technique, test_number=index + 1, data=t)
                          for index, t in enumerate(data["atomic_tests"])]
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
                    count += 1
                for index, t in enumerate(data["atomic_tests"]):
                    if t["__line__"] in changed_lines:
                        tests.append(ChangedAtomic(technique=technique, test_number=index + 1,
                                                   data=t))

        return tests

    def assign_label(self, pr, labels):
        url = f"https://api.github.com/repos/redcanaryco/atomic-red-team/issues/{pr}/labels"
        data = {
            "labels": labels
        }
        response = requests.put(url, json=data,
                                headers=self.headers, timeout=15)
        print(response.status_code, response.reason, response.text)
        assert response.status_code == 200

    def assign_maintainer(self, pr, maintainers):
        url = f"https://api.github.com/repos/redcanaryco/atomic-red-team/issues/{pr}/assignees"
        data = {
            "assignees": maintainers
        }
        response = requests.post(url, json=data,
                                 headers=self.headers, timeout=15)
        assert response.status_code == 201

    def assign_labels_and_maintainers(self, pr):
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
        self.assign_label(pr, labels)
        self.assign_maintainer(pr, maintainers)


@click.command()
@click.option("--token", "-t", "token", required=True,
              help="Github Token to be used",
              )
@click.option("--pull-request", "-pr", "pr", required=True,
              help="Current pull request number")
def process(token, pr):
    """ Processes the changed files and assign labels and maintainers to the PR"""
    api = GithubAPI(token)
    api.assign_labels_and_maintainers(pr)


if __name__ == "__main__":
    process()
