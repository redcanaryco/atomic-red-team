from hypothesis import given, strategies as st, settings, HealthCheck
from hypothesis.provisional import urls
from pydantic import AnyUrl
from pydantic.networks import IPvAnyAddress

from atomic_red_team.models import (
    Technique,
    Atomic,
    StringArg,
    IntArg,
    FloatArg,
    UrlArg,
    ManualExecutor,
    Platform,
    CommandExecutor,
    ExecutorType,
)

executor_strategy = st.sampled_from(["powershell", "bash", "sh", "command_prompt"])

st.register_type_strategy(IPvAnyAddress, st.ip_addresses())
st.register_type_strategy(AnyUrl, urls())

alphanumeric_underscore_strategy = st.text(
    alphabet=st.sampled_from(
        "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789_"
    ),
    min_size=4,
)
input_args_types = [
    st.builds(
        StringArg,
        description=st.text(),
        default=st.text(),
        type=st.sampled_from(["string", "path", "String", "Path"]),
    ),
    st.builds(
        IntArg,
        description=st.text(),
        default=st.integers(),
        type=st.sampled_from(["integer", "Integer"]),
    ),
    st.builds(
        FloatArg,
        description=st.text(),
        default=st.floats(),
        type=st.sampled_from(["float", "Float"]),
    ),
    st.builds(
        UrlArg,
        description=st.text(),
        default=st.one_of(urls(), st.ip_addresses()),
        type=st.sampled_from(["url", "Url"]),
    ),
]

platforms_strategy = st.lists(st.sampled_from(list(Platform.__args__)), min_size=1)
input_arguments_strategy = st.dictionaries(
    keys=alphanumeric_underscore_strategy, values=st.one_of(*input_args_types)
)

atomics_strategy = dict(
    input_arguments=input_arguments_strategy,
    name=alphanumeric_underscore_strategy,
    description=st.text(min_size=5),
    supported_platforms=platforms_strategy,
)


def atomic_manual_executor_builder():
    def build_atomic(input_arguments, **kwargs):
        formatted_args = " ".join(
            [f"echo #{key}=#{{{key}}}" for key in input_arguments.keys()]
        )
        return Atomic(
            **kwargs,
            executor=ManualExecutor(
                name="manual", steps=f"{formatted_args} Custom steps here..."
            ),
            input_arguments=input_arguments,
        )

    return st.builds(build_atomic, **atomics_strategy)


def atomic_command_executor_builder():
    def build_atomic(input_arguments, executor_name, **kwargs):
        formatted_args = " ".join(
            [f"echo #{key}=#{{{key}}}" for key in input_arguments.keys()]
        )
        return Atomic(
            executor=CommandExecutor(
                name=executor_name,
                command=f"{formatted_args} Custom steps here...",
            ),
            input_arguments=input_arguments,
            **kwargs,
        )

    return st.builds(build_atomic, executor_name=executor_strategy, **atomics_strategy)


@given(
    st.builds(
        Technique,
        attack_technique=st.integers(min_value=1000, max_value=9999).map(
            lambda x: f"T{x}"
        ),
        atomic_tests=st.lists(
            st.one_of(
                atomic_manual_executor_builder(), atomic_command_executor_builder()
            ),
            min_size=1,
        ),
    )
)
@settings(max_examples=500, suppress_health_check=[HealthCheck.too_slow])
def test_property(instance):
    assert isinstance(instance, Technique)
    assert len(instance.attack_technique) > 4
    assert len(instance.display_name) >= 5
    for test in instance.atomic_tests:
        assert isinstance(test, Atomic)
        assert test.executor.name in ExecutorType.__args__
