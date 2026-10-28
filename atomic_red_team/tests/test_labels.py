import json

import pytest

from atomic_red_team.labels import GithubAPI


@pytest.mark.parametrize(
    "patch, starts, expected",
    [
        ("@@ -10,3 +10,3 @@\n context\n-old\n+new\n context", [4, 20], [1]),
        ("@@ -10,3 +30,3 @@\n context\n-old\n+new\n context", [4, 20], [2]),
        ("@@ -10 +10 @@\n-old\n+new", [4, 20], [1]),
        ("@@ -1000,3 +1000,3 @@\n context\n-old\n+new\n context", [4, 1000], [2]),
        ("@@ -20 +20 @@\n-- name: old\n+- name: new", [4, 20], [2]),
        ("@@ -10,3 +10,3 @@\n context\n-old\n+new\n context", [4], [1]),
        ("@@ -100,3 +100,3 @@\n context\n-old\n+new\n context", [4], [1]),
        ("@@ -10,91 +10,91 @@" + "\n context" * 90 + "\n-old\n+new", [4], [1]),
        (
            "@@ -10 +10 @@\n-old\n+new\n@@ -100 +100 @@\n-old\n+new",
            [4, 20],
            [1, 2],
        ),
        (None, [4, 20], [1, 2]),
    ],
)
def test_changed_tests_use_new_file_line_numbers(monkeypatch, patch, starts, expected):
    api = GithubAPI("unused-test-token")
    file = {
        "filename": "atomics/T1003/T1003.yaml",
        "status": "modified",
        "raw_url": "https://example.invalid/T1003.yaml",
    }
    if patch is not None:
        file["patch"] = patch
    atomics = [
        {"__line__": start, "supported_platforms": ["linux"]} for start in starts
    ]
    monkeypatch.setattr(api, "get_files_for_pr", lambda pr: [file])
    monkeypatch.setattr(api, "get_atomic_with_lines", lambda url: {"atomic_tests": atomics})

    changed = api.get_tests_changed("123")

    assert [test.test_number for test in changed] == expected
    assert all(test.technique == "T1003" for test in changed)


def test_labels_and_maintainers_follow_changed_platform(monkeypatch, tmp_path):
    api = GithubAPI("unused-test-token")
    monkeypatch.chdir(tmp_path)
    monkeypatch.setattr(
        api,
        "get_files_for_pr",
        lambda pr: [{
            "filename": "atomics/T1003/T1003.yaml",
            "status": "modified",
            "raw_url": "https://example.invalid/T1003.yaml",
            "patch": "@@ -10,3 +30,3 @@\n context\n-old\n+new\n context",
        }],
    )
    monkeypatch.setattr(
        api,
        "get_atomic_with_lines",
        lambda url: {"atomic_tests": [
            {"__line__": 4, "supported_platforms": ["windows"]},
            {"__line__": 20, "supported_platforms": ["linux"]},
        ]},
    )

    api.save_labels_and_maintainers("123")

    labels = json.loads((tmp_path / "pr" / "labels.json").read_text())
    changed = json.loads((tmp_path / "pr" / "changedfiles.json").read_text())
    assert labels["labels"] == ["linux"]
    assert labels["maintainers"] == api.maintainers["linux"]
    assert changed == [{"name": "T1003", "test_number": 2}]
