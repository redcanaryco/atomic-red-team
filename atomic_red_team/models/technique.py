import re
from typing import List

from pydantic import (
    BaseModel,
)
from snakemd import Element, Heading, MDList, Raw

from .atomic import Atomic


def get_technique_description(technique: str):
    return ""


class Technique(BaseModel):
    attack_technique: str
    display_name: str
    atomic_tests: List[Atomic]

    def model_post_init(self, __context) -> None:
        for index in range(len(self.atomic_tests)):
            self.atomic_tests[
                index
            ].test_number = f"{self.attack_technique}-{index + 1}"

    @property
    def title(self) -> Heading:
        return Heading(
            text=f"{self.attack_technique.upper()} - {self.display_name}", level=1
        )

    @property
    def mitre_url(self):
        url = self.attack_technique.upper().replace(".", "/")
        url = f"https://attack.mitre.org/techniques/{url}"
        return Heading(text=f"[Description from ATT&CK]({url})", level=2)

    @property
    def atomic_tests_toc(self):
        replace_all_special_chars = lambda x: re.sub(
            "[^A-Za-z0-9-]+", "", x.lower().replace(" ", "-")
        )
        items = [
            f"Atomic Test #{index + 1} - {test.name}"
            for index, test in enumerate(self.atomic_tests)
        ]
        items = [f"[{item}](#{replace_all_special_chars(item)})" for item in items]
        return MDList(items=items, ordered=False)

    @property
    def markdown(self) -> [Element]:
        elements = [
            self.title,
            self.mitre_url,
            Raw(
                f"<blockquote>{get_technique_description(self.attack_technique)}</blockquote>"
            ),
            Heading("Atomic Tests", level=2),
            self.atomic_tests_toc,
            Raw("<br/>"),
        ]
        for index, test in enumerate(self.atomic_tests):
            elements.append(
                Heading(f"Atomic Test #{index + 1} - {test.name}".strip(), level=2)
            )
            elements.extend(test.markdown)
        return elements
