"""Validates atomics based on JSON Schema."""
import glob
import json

import yaml
from jsonschema import validate


schema = json.load(open("./bin/validate/atomic-red-team.schema.json"))

for item in glob.glob("./atomics/T*/T*.yaml"):
    with open(item, 'r') as file:
        data = yaml.safe_load(file)
    try:
        response = validate(
            instance=data,
            schema=schema
        )
    except Exception as e:
        print(item, e)
