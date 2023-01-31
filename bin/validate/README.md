# Validaton

We provide validation of each defined Atomic Red Team test in the form of a [JSON Schema](https://json-schema.org/). This schema defines the structure and format of an Atomic test.

We use this schema to validate the format of Atomics using a [GitHub Action](.../.github/workflows/validate-schema.yml) which runs on every push to the repository. If an Atomic fails validation, it is not allowed to be merged into the main branch.


## Validation Requirements

TODO

## Tooling & Usage

TODO

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

