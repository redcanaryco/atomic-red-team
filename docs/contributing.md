---
layout: default
---

# Contributing to Atomic Red Team
*NOTE: We have sweet stickers for people who contribute; if you’re interested send a message to 
gear@redcanary.com with your mailing address*

- [Atomic Philosophy](#atomic-philosophy)
- [How to contribute](#how-to-contribute)
- [Atomic Test structure](#atomic-test-structure)
- [Generating Atomic docs yourself (optional)](#generating-atomic-docs-yourself-optional)

## Atomic Philosophy
Atomic Red Team welcomes all types of contributions as long as it is mapped to 
[MITRE ATT&CK](https://attack.mitre.org/wiki/Main_Page). A few guidelines:

- Tests are made to be "easy". If your Atomic Test is complicated and requires multiple external utilities/packages/Kali,
  we may ask that you simplify it.

- TEST YOUR ATOMIC TEST! Be sure to run it from a few OSes/platforms before submitting a pull request to ensure 
  everything is working correctly.

- If sourcing from another tool/product (ex. generated command), be sure to cite it in the test's description.

## How to contribute
### Fork
[Fork the atomic-red-team repository in Github](https://github.com/redcanaryco/atomic-red-team/fork), then checkout 
the repository and make a branch for your new test:
```bash
git clone git@github.com/YOUR_GITHUB_ACCOUNT/atomic-red-team
cd atomic-red-team

git checkout -b t1234-something-describing-your-test
```

### Add Atomic Test
Pick the technique you want to add a test for (ie, T1234) and run the generator. This makes 
a new test for the technique with a bunch of TODOs you'll fill in and opens up your editor
so you can get to work.

```bash
bin/new-atomic.rb T1234
```

> Don't have Ruby? Use the Atomic Test template [here]({{ site.github.repository_url }}/blob/master/atomic_red_team/atomic_test_template.yaml) as a starting point for your new test.

Fill in the TODOs with the information for your test. See the [Atomic Test structure](#atomic-test-structure) section below.

### Validate
Validate that your Atomic Test is up to spec!

```bash
bin/validate-atomics.rb
```

> Don't have Ruby? The automated build system will validate the techniques on your branch as soon as you commit to your branch and push to your fork.

### Push it
Submit a Pull Request once your test is complete and everything validates.
```bash
git add atomics/T1234
git commit -m "Add test for T1234 that does XYZ"
git push -u origin $(git branch |grep '*'|cut -f2 -d' ')
```

Go to github.com/YOUR_GITHUB_ACCOUNT/atomic-red-team and follow the 
instructions to create a new Pull Request.

## Atomic Test structure
This spec describes the format of Atomic Red Team atomic tests that are defined in YAML format. 

The Atomic YAML schema is specified in the [Atomic Red Team YAML Spec]({{
site.github.repository_url }}/blob/master/atomic_red_team/spec.yaml). See that
file for complete details about what each field means and a list of possible values.

The source of truth for a test is the YAML file - the associated human readable Markdown file is automatically 
generated via `bin/generate-atomic-docs.rb` and `atomic_red_team/atomic_doc_template.md.erb`.

The directory structure is:
- Tests reside in the `atomics` directory
- One directory per ATT&CK technique, named as `T1234`
- All the atomic tests for a technique in a file named `T1234.yaml` inside that directory
- Any payloads, supporting materials, etc for the atomic tests also live in that directory

For example:

```
atomic_red_team/
atomic_red_team/atomics
atomic_red_team/atomics/T1234
atomic_red_team/atomics/T1234/T1234.yaml   <-- where all the atomic tests for a technique live
atomic_red_team/atomics/T1234/payload1.sct <-- payload file needed by one of the T1234 atomics
```

In general, a set of atomic tests for a technique should never depend on payloads
or supporting files from other atomic directories. We want to keep things nice and close.
Use git symlinks if you really need to share files between techniques.

## Generating Atomic docs yourself (optional)
If you want to see what the pretty Markdown version of your Atomic Test is going to look like, 
you can generate the Atomic Docs yourself:

```
bin/generate-atomic-docs.rb
```

The CircleCI build will automatically generate docs and commit them to master when your pull request is merged.
