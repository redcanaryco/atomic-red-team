from typing import Optional

from mitreattack.navlayers.core import Link, Technique as NavTechnique
from pydantic import BaseModel, Field, AliasPath

from atomic_red_team.models import Technique


class MitreEnrichedTechnique(BaseModel):
    attack_id: str = Field(
        validation_alias=AliasPath("external_references", 0, "external_id")
    )
    name: str
    kill_chain_phases: list[dict] = Field(alias="kill_chain_phases")
    platforms: list[str] = Field(alias="x_mitre_platforms")
    is_subtechnique: bool = Field(alias="x_mitre_is_subtechnique")
    technique: Optional[Technique] = None

    @property
    def phases(self):
        return [phase["phase_name"] for phase in self.kill_chain_phases]

    def includes_platform(self, platform: str):
        return platform == "" or any(
            [
                any([platform in p for p in atomic.supported_platforms])
                for atomic in self.technique.atomic_tests
            ]
        )

    def to_nav_layer_technique(self):
        t = NavTechnique(tID=self.attack_id)
        t.tactic = ",".join(self.phases)
        t.enabled = True
        if self.technique:
            t.score = len(self.technique.atomic_tests)
        t.links = [
            Link(
                label="View Atomic",
                url=f"https://github.com/redcanaryco/atomic-red-team/blob/master/atomics/{self.attack_id}/{self.attack_id}.md",
            )
        ]
        return t
