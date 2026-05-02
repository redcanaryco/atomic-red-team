from atomic_red_team.new_atomic import create_or_append_atomic


def test_create_or_append_atomic_creates_new_technique_file(tmp_path):
    atomics_dir = tmp_path / "atomics"

    output_path = create_or_append_atomic("t1001", atomics_dir=atomics_dir)

    assert output_path == atomics_dir / "T1001" / "T1001.yaml"
    assert "attack_technique: T1001" in output_path.read_text()
    assert "atomic_tests:" in output_path.read_text()


def test_create_or_append_atomic_appends_atomic_test_to_existing_file(tmp_path):
    atomics_dir = tmp_path / "atomics"
    technique_dir = atomics_dir / "T1001"
    technique_dir.mkdir(parents=True)
    output_path = technique_dir / "T1001.yaml"
    output_path.write_text(
        "attack_technique: T1001\n"
        "display_name: Existing Technique\n"
        "atomic_tests:\n"
        "- name: Existing test\n"
    )

    create_or_append_atomic("T1001", atomics_dir=atomics_dir)

    output = output_path.read_text()
    assert "- name: Existing test" in output
    assert output.count("- name: TODO") == 1
    assert output.count("atomic_tests:") == 1
