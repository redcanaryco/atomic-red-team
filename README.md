<p><img src="https://redcanary.com/wp-content/uploads/Atomic-Red-Team-Logo.png" width="150px" /></p>

# Atomic Red Team
[![CircleCI](https://circleci.com/gh/redcanaryco/atomic-red-team.svg?style=svg)](https://circleci.com/gh/redcanaryco/atomic-red-team)

Atomic Red Team allows every security team to test their controls by executing simple
"atomic tests" that exercise the same techniques used by adversaries (all mapped to
[MITRE ATT&CK](https://attack.mitre.org)).

## Philosophy

Atomic Red Team is a library of simple tests that every security team can execute to test their controls. Tests are
focused, have few dependencies, and are defined in a structured format that can be used by automation frameworks.

Three key beliefs made up the Atomic Red Team charter:
- **Teams need to be able to test everything from specific technical controls to outcomes.**
  Our security teams do not want to operate with a “hopes and prayers” attitude toward detection. We need to know
  what our controls and program can detect, and what it cannot. We don’t have to detect every adversary, but we
  do believe in knowing our blind spots.

- **We should be able to run a test in less than five minutes.**
  Most security tests and automation tools take a tremendous amount of time to install, configure, and execute.
  We coined the term "atomic tests" because we felt there was a simple way to decompose tests so most could be
  run in a few minutes.

  The best test is the one you actually run.

- **We need to keep learning how adversaries are operating.**
  Most security teams don’t have the benefit of seeing a wide variety of adversary types and techniques crossing
  their desk every day. Even we at Red Canary only come across a fraction of the possible techniques being used,
  which makes the community working together essential to making us all better.

## Getting Started

Learn all about this project, executing atomic tests, and contributing over of [the Wiki](https://github.com/redcanaryco/atomic-red-team/wiki).