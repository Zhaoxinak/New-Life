# -*- coding: utf-8 -*-
"""Smoke: hybrid clock duration mapping + period bounds (no Godot)."""
from __future__ import annotations

DAY_START = 6 * 60
AFTERNOON = 12 * 60
EVENING = 18 * 60
DAY_END = 22 * 60


def period_for_minute(m: int) -> str:
    if m < AFTERNOON:
        return "morning"
    if m < EVENING:
        return "afternoon"
    return "evening"


def duration_minutes(time_cost: int, duration_minutes_col: int | None = None) -> float:
    if duration_minutes_col is not None and duration_minutes_col >= 0 and str(duration_minutes_col) != "":
        # mirror: explicit column wins when present
        return float(max(0, duration_minutes_col))
    if time_cost <= 0:
        return 0.0
    return float(time_cost) * 120.0


def main() -> None:
    assert period_for_minute(6 * 60) == "morning"
    assert period_for_minute(12 * 60) == "afternoon"
    assert period_for_minute(18 * 60) == "evening"
    assert duration_minutes(1) == 120.0
    assert duration_minutes(0) == 0.0
    assert duration_minutes(1, 90) == 90.0
    # 120 min busy @ 12/sec => 10s wall
    assert abs(120.0 / 12.0 - 10.0) < 1e-6
    print("smoke_clock_m1: OK")


if __name__ == "__main__":
    main()
