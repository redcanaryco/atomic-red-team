"""Validates atomics based on JSON Schema."""
import glob
import json

import yaml
from jsonschema import validate
from jsonschema.exceptions import ValidationError


schema = json.load(open("./bin/validate/atomic-red-team.schema.json"))

for item in glob.glob("./atomics/T*/T*.yaml"):
    with open(item, 'r') as file:
        data = yaml.safe_load(file)
    try:
        response = validate(
            instance=data,
            schema=schema
        )
    except ValidationError as ve:
        print(f"Error occurred with {item}.")
        print("Each of the following are why it failed:")
        print(f"\n\t{ve.context[0].message}\n")
        print(f"The JSON Path is {ve.json_path}")
    except Exception as e:
        print(f"Error occurred with {item}.")
        print("Each of the following are why it failed:")
        print(f"\n\t{ve.context[0].message}\n")
        print(f"The JSON Path is {ve.json_path}")
