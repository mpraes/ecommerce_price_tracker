"""Smoke test so CI has at least one passing test.

Real tests live alongside the code they cover (see AGENTS.md).
This file guarantees `pytest` exits 0 even on a greenfield branch
where nothing has been implemented yet.
"""


def test_smoke() -> None:
    """Trivial assertion that the test harness is wired up."""
    assert 1 + 1 == 2
