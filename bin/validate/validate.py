"""Validates atomics based on JSON Schema."""
import glob
import os.path
import sys
import yaml
from jsonschema import validate
from jsonschema.exceptions import ValidationError

is_exception = False
with open(f"{os.path.dirname(os.path.abspath(__file__))}/atomic-red-team.schema.yaml", "r") as f:
    schema = yaml.safe_load(f)

    for item in glob.glob("./atomics/T*/T*.yaml"):
        with open(item, 'r') as file:
            data = yaml.safe_load(file)
        try:
            validate(
                instance=data,
                schema=schema
            )
        except ValidationError as ve:
            print(f"Error occurred with {item}")
            print("Each of the following are why it failed:")
            if (context := ve.context) and len(context) > 0:
                print(f"\n\t{context[0].message}\n")
            else:
                print(f"\n\t{ve}\n")
            print(f"The JSON Path is {ve.json_path}")
            is_exception = True
        except Exception as e:
            print(f"Error occurred with {item}")
            print("Each of the following are why it failed:")
            print(f"\n\t{e}\n")
            is_exception = True

if is_exception:
    sys.exit(1)