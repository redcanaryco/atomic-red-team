from typing import Optional

from pydantic import BaseModel
from pydantic import Field, AliasPath

from models import Technique


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
        return (
                platform == "" or
                any(
                    [
                        any([platform in p for p in atomic.supported_platforms])
                        for atomic in self.technique.atomic_tests
                    ]
                )
        )
