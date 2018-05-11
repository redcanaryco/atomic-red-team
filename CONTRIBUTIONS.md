# How to contribute to Atomic Red Team

## Atomic Philosophy
Atomic Red Team welcomes all types of contributions as long as it is mapped to [MITRE ATT&CK](https://attack.mitre.org/wiki/Main_Page).

- Tests are made to be "easy". If your Atomic test is complicated and requires multiple external utilities/packages/Kali, we may dismiss it.

- TEST YOUR Atomic Test! Be sure to run it from a few OS platforms before submitting a pull to ensure everything is working correctly.

- If sourcing from another tool/product (ex. generated command), be sure to cite it in the test's description.

## How to contribute
Pick the technique you want to add a test for and run the generator:

```
bin/new-atomic.rb T1234
```

This makes a new test for the technique with a bunch of TBDs you'll fill in and opens up your editor
so you can get to work.

Fill in the TBDs with the information for your test. Read the [Atomic Red Team YAML Spec](atomic-red-team/spec.yaml)
for complete details about what each field means and a list of possible values.

Validate that your Atomic Test is up to code!

```
bin/validate-atomics.rb
```

Submit a pull request once your test is complete and everything validates.

## Generating Atomic docs yourself (optional)
If you want to see what the pretty Markdown version of your Atomic Test is going to look like, 
you can generate the Atomic Docs yourself:

```
bin/generate-atomic-docs.rb
```