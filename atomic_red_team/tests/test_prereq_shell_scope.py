"""Regression tests: executor commands must not rely on variables that are
only assigned in a dependency's ``prereq_command``.

``prereq_command`` runs in a separate shell invocation from the executor's
``command``/``cleanup_command`` (see https://github.com/redcanaryco/atomic-red-team/issues/3473),
so a variable assigned there is empty when the executor runs. Atomic tests
must either call the binary directly or assign the variable inside the
executor command itself (the pattern already used by e.g. T1486 test 3).
"""

import glob
import os
import re

import yaml

from atomic_red_team.common import atomics_path

# Assignment such as `which_gpg=`which gpg`` or `FOO=bar`, including `export FOO=`.
ASSIGN_RE = re.compile(r"(?:^|[\s;])(?:export\s+)?([A-Za-z_][A-Za-z0-9_]*)=")


def assigned_variables(text):
    return {m.group(1) for m in ASSIGN_RE.finditer(text or "")}


def used_variables(text):
    # `$foo` and `${foo}` forms.
    return set(re.findall(r"\$\{?([A-Za-z_][A-Za-z0-9_]*)", text or ""))


def cross_shell_variables(technique):
    """Yield (test_name, field, variable) for prereq-only vars used by an executor."""
    for test in technique.get("atomic_tests") or []:
        prereq_vars = set()
        for dependency in test.get("dependencies") or []:
            prereq_vars |= assigned_variables(dependency.get("prereq_command"))

        executor = test.get("executor") or {}
        for field in ("command", "cleanup_command"):
            command = executor.get(field)
            if not command:
                continue
            unassigned = prereq_vars - assigned_variables(command)
            for variable in sorted(unassigned & used_variables(command)):
                yield test.get("name"), field, variable


def test_executor_commands_do_not_depend_on_prereq_only_variables():
    """Every atomic's executor must be self-contained w.r.t. shell variables."""
    offenders = []
    for path in sorted(glob.glob(os.path.join(atomics_path, "T*", "T*.yaml"))):
        with open(path, encoding="utf-8") as handle:
            technique = yaml.safe_load(handle)
        if not technique:
            continue
        relpath = os.path.relpath(path, atomics_path)
        for test_name, field, variable in cross_shell_variables(technique):
            offenders.append(f"{relpath}: {test_name}: {field} uses ${variable}")

    assert not offenders, (
        "Variables assigned only in prereq_command are not visible to the "
        "executor (separate shell); assign them inside the executor command "
        "or call the binary directly:\n" + "\n".join(offenders)
    )
