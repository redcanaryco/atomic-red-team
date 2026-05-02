import json

from atomic_red_team.attack_api import Attack


def test_techniques_by_tactic_filters_platform_revoked_and_deprecated(tmp_path):
    attack_file = tmp_path / "enterprise-attack.json"
    attack_file.write_text(
        json.dumps(
            {
                "type": "bundle",
                "id": "bundle--11111111-1111-4111-8111-111111111111",
                "spec_version": "2.0",
                "objects": [
                    {
                        "type": "attack-pattern",
                        "id": "attack-pattern--11111111-1111-4111-8111-111111111111",
                        "created": "2024-01-01T00:00:00.000Z",
                        "modified": "2024-01-01T00:00:00.000Z",
                        "name": "Allowed Technique",
                        "external_references": [
                            {"source_name": "mitre-attack", "external_id": "T1001"}
                        ],
                        "x_mitre_platforms": ["Windows"],
                        "kill_chain_phases": [
                            {
                                "kill_chain_name": "mitre-attack",
                                "phase_name": "execution",
                            }
                        ],
                    },
                    {
                        "type": "attack-pattern",
                        "id": "attack-pattern--22222222-2222-4222-8222-222222222222",
                        "created": "2024-01-01T00:00:00.000Z",
                        "modified": "2024-01-01T00:00:00.000Z",
                        "name": "Wrong Platform",
                        "external_references": [
                            {"source_name": "mitre-attack", "external_id": "T1002"}
                        ],
                        "x_mitre_platforms": ["Linux"],
                        "kill_chain_phases": [
                            {
                                "kill_chain_name": "mitre-attack",
                                "phase_name": "execution",
                            }
                        ],
                    },
                    {
                        "type": "attack-pattern",
                        "id": "attack-pattern--33333333-3333-4333-8333-333333333333",
                        "created": "2024-01-01T00:00:00.000Z",
                        "modified": "2024-01-01T00:00:00.000Z",
                        "name": "Revoked Technique",
                        "external_references": [
                            {"source_name": "mitre-attack", "external_id": "T1003"}
                        ],
                        "x_mitre_platforms": ["Windows"],
                        "revoked": True,
                        "kill_chain_phases": [
                            {
                                "kill_chain_name": "mitre-attack",
                                "phase_name": "execution",
                            }
                        ],
                    },
                ],
            }
        )
    )

    attack = Attack(attack_file)

    assert attack.technique_info("t1001")["name"] == "Allowed Technique"
    assert attack.techniques_by_tactic("windows")["execution"] == [
        attack.technique_info("T1001")
    ]
