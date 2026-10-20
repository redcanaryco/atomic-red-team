import re
import uuid
from typing import List

from ruamel.yaml import YAML

from atomic_red_team.common import used_guids_file

yaml = YAML(typ="safe")


def get_unique_guid(guids: List[str]):
    # This function should return a unique GUID that's not in the used_guids_file.
    guid = str(uuid.uuid4())
    if guid not in guids:
        with open(used_guids_file, "a") as f:  # append mode
            f.write(f"{guid}\n")
        return guid
    else:
        return get_unique_guid(guids)


def generate_guids_for_yaml(path, get_guid):
    with open(path, "r") as file:
        og_text = file.read()

    # Add the "auto_generated_guid:" element after the "- name:" element if it isn't already there
    text = re.sub(
        r"(?i)(^([ \t]*-[ \t]*)name:.*$(?!\s*auto_generated_guid))",
        lambda m: f"{m.group(1)}\n{m.group(2).replace('-', ' ')}auto_generated_guid:",
        og_text,
        flags=re.MULTILINE,
    )

    # Fill the "auto_generated_guid:" element in if it doesn't contain a guid
    text = re.sub(
        r"(?i)^([ \t]*auto_generated_guid:)(?!([ \t]*[a-f0-9]{8}-[a-f0-9]{4}-4[a-f0-9]{3}-[89aAbB][a-f0-9]{3}-[a-f0-9]{12})).*$",
        lambda m: f"{m.group(1)} {get_guid()}",
        text,
        flags=re.MULTILINE,
    )
    if text != og_text:
        with open(path, "wb") as file:
            # using wb mode instead of w. If not, the end of line characters are auto-converted to OS specific ones.
            file.write(text.encode())
