# Validaton

We provide validation of each defined Atomic Red Team test in the form of a [JSON Schema](https://json-schema.org/). This schema defines the structure and format of an Atomic test.

- [Validaton](#validaton)
  - [Validation Requirements](#validation-requirements)
    - [atomic\_tests](#atomic_tests)
    - [input\_arguments](#input_arguments)
    - [dependencies](#dependencies)
    - [dependency\_executor\_name](#dependency_executor_name)
    - [executor](#executor)
  - [Tooling \& Usage](#tooling--usage)
  - [Error Messages (Ruby Version)](#error-messages-ruby-version)
  - [Error Messages (Python version)](#error-messages-python-version)

We use this schema to validate the format of Atomics using a [GitHub Action](.../.github/workflows/validate-schema.yml) which runs on every push to the repository. If an Atomic fails validation, it is not allowed to be merged into the main branch.

```
📦atomics
 ┣ 📂T1234
 ┃ ┣ 📂T1234.md
 ┃ ┗ 📂T1234.yaml       <-- This is where all the atomic tests live
 ┃ ┣ 📂src
 ┃ ┃ ┣ 📜payload1.sct   <-- A paload file needed by one of the T1234 atomics (human readable)
 ┃ ┃ ┣ 📜payload2.dll   <-- Another payload file needed by one of the T1234 atomics (binary)
 ```
In general, a set of atomic tests for a technique should never depend on payloads or supporting files from other atomic directories. We want to keep things nice and close. Use git symlinks if you really need to share files between techniques.

Atomic tests should be fully automated whenever possible, requiring no continued interaction. Include any needed options to execute the commands seamlessly, for example SysInternal's -accepteula option or any -q or -quiet modes.

## Validation Requirements

To explain the requirements around validation, we have broken down each main component.

Each yaml specification requires the following main level entities:

* attack_techniques - A Mitre ATT&CK Technique or Sub-Technique ID with a capital T.
* display_name      - Name of the technique or sub-technique as defined by ATT&CK.
* atomic_tests      - One or more Atomic tests for a technique / sub-technique.

### atomic_tests

Each `atomic_test` object must have the following fields defined:

|Property Name|Description|Data Type|Accepted Values|
|-------------|-----------|---------|---------------|
|name         |The name of the test.|String|Any|
|description  |A description about the test|String|Any|
|supported_platforms|One or more supported operating system platforms for this test. This is a list of supported_platforms and each must be unique.|List[String]|windows, macos, linux, office-365, azure-ad, google-workspace, saas, iaas, containers, iaas:gcp, iaas:azure, iaas:aws|

### input_arguments

Each defined test can supply one or more `input_arguments`. Please note that input arguments are not required and only optional. If you do provide a `input_argument` then each must be unique and contain a unique named property as well as sub-properties.

If your argument requires a String or null value you can use the following properties.

|Property Name|Description|Data Type|Accepted Values|
|-------------|-----------|---------|---------------|
|{unique_name}|A unique name for the input argument that will be referenced in commands|String|`^[a-zA-Z0-9_-]+$`|
|description  |A description about the the input argument property|String|Any|
|type         |The data type of the value for this property|String|Path, Url, String (please note the capitalization)|
|default      |The default value for the argument|String or Null|Any|

If your argument requires a integer or float you can use the following properties.

|Property Name|Description|Data Type|Accepted Values|
|-------------|-----------|---------|---------------|
|{unique_name}|A unique name for the input argument that will be referenced in commands|String|`^[a-zA-Z0-9_-]+$`|
|description  |A description about the the input argument property|String|Any|
|type         |The data type of the value for this property|String|Integer, Float (please note the capitalization)|
|default      |The default value for the argument|Number or Null|Any|

### dependencies

A list of dependies that must be met to successfully run this atomic. This is optional but if provided you must provide the following values for that dependency.

> You can supply more than 1 dependency. The `dependencies` property takes a list of dependencies.

|Property Name|Description|Data Type|Accepted Values|
|-------------|-----------|---------|---------------|
|description  |A description about the the input argument property|String|Any|
|prereq_command|Commands to check if prerequisites for running this test are met. For the "command_prompt" executor, if any command returns a non-zero exit code, the pre-requisites are not met. For the "powershell" executor, all commands are run as a script block and the script block must return 0 for success.|String|Any|
|get_prereq_command|Commands to meet this prerequisite or a message describing how to meet this prereq|String|Any|


### dependency_executor_name

The executor for the prereq commands, defaults to the same executor used by the attack commands. This field is optional but must be one of the following values:

* command_prompt
* powershell
* sh
* bash
* manual

### executor

The `executor` propery contains a list of unique executors for each environment that the test belongs to or has defined definitions for.

Each defined `executor` can define the following properties.

|Property Name|Description|Data Type|Accepted Values|
|-------------|-----------|---------|---------------|
|name         |The name of the executor to use to execute this command sequence.|String|command_prompt, sh, bash, powershell, aws, az, gcloud, kubectl|
|command      |The command string to execute.|String|Any|

Each executor can also have the following fields, but these are only specified when needed.

|Property Name|Description|Data Type|Accepted Values|
|-------------|-----------|---------|---------------|
|elevation_required|indicates whether command must be run with admin privileges.|Bool|true or false|
|cleanup_command      |The command string to execute to cleanup the system after executing the command above.|String|Any|

You can also specify the executor type of `manual`. The manual executor requires another field called `steps` which is a list of manual steps that the user must take to perform an action.

## Tooling & Usage

There are two main entrypoints to validate atomics. You can do so manually by cloning the repository and running the [validate.rb](validate.rb).

```ruby
ruby ./bin/validate/validate.rb
```

Additionally, the validation script will run on each push to the repository using the provided GitHub Action.

## Error Messages (Ruby Version)

TODO

## Error Messages (Python version)

A typical error message when validation fails looks like the following:

```bash
{'description': 'Daily scheduled task execution time', 'type': 'string', 'default': '07:45'} is not valid under any of the given schemas

Failed validating 'anyOf' in schema['properties']['atomic_tests']['items']['properties']['input_arguments']['patternProperties']['^[a-zA-Z0-9]*$']:
    {'anyOf': [{'properties': {'default': {'type': ['string', 'null']},
                               'description': {'type': 'string'},
                               'type': {'enum': ['Path', 'Url', 'String'],
                                        'type': 'string'}},
                'type': 'object'},
               {'properties': {'default': {'type': ['number', 'null']},
                               'description': {'type': 'string'},
                               'type': {'enum': ['Integer', 'Float'],
                                        'type': 'string'}},
                'required': ['description', 'type', 'default'],
                'type': 'object'}],
     'type': 'object'}

On instance['atomic_tests'][6]['input_arguments']['time']:
    {'default': '07:45',
     'description': 'Daily scheduled task execution time',
     'type': 'string'}
```

With this error, it may be unclear exactly why the validation failed. That is why we have formatted the output to parse this error to make it more readable. For example, the parsed version is 

```bash
Error occurred with ./atomics/T1053.005/T1053.005.yaml.
Each of the following are why it failed:

        'string' is not one of ['Path', 'Url', 'String']

The JSON Path is $.atomic_tests[6].input_arguments.time
```

