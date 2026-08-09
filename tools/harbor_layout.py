# -*- coding: utf-8 -*-
"""Reference coords for painted harbor_outdoor.png (door / spawn / hub stops).

Keep in sync with game/world/HarborOutdoor.gd LAYOUT + TRANSIT_STOPS.
"""
from __future__ import annotations

MAP_W = 1536
MAP_H = 1024
MAP_SCALE = 2.55

# door = facade threshold on cobbles · spawn = clear path exit · stop = hub only
MAINS = {
    "company": {
        "body": (0.08, 0.06, 0.18, 0.20),
        "door": (0.170, 0.220),
        "spawn": (0.195, 0.300),
        "facing": "south",
    },
    "home": {
        "body": (0.42, 0.05, 0.16, 0.20),
        "door": (0.505, 0.235),
        "spawn": (0.520, 0.300),
        "facing": "south",
        "stop": (0.500, 0.355),
    },
    "rival": {
        "body": (0.78, 0.06, 0.16, 0.18),
        "door": (0.870, 0.195),
        "spawn": (0.820, 0.230),
        "facing": "south",
    },
    "tea_house": {
        "body": (0.04, 0.30, 0.14, 0.14),
        "door": (0.130, 0.365),
        "spawn": (0.200, 0.395),
        "facing": "east",
    },
    "plaza": {
        "body": (0.05, 0.48, 0.18, 0.16),
        "door": (0.195, 0.560),
        "spawn": (0.220, 0.600),
        "facing": "east",
        "stop": (0.255, 0.595),
    },
    "garage": {
        "body": (0.04, 0.68, 0.16, 0.14),
        "door": (0.155, 0.755),
        "spawn": (0.220, 0.770),
        "facing": "east",
    },
    "exchange": {
        "body": (0.72, 0.40, 0.22, 0.20),
        "door": (0.785, 0.500),
        "spawn": (0.700, 0.505),
        "facing": "west",
        "stop": (0.620, 0.505),
    },
    "dock": {
        "body": (0.42, 0.68, 0.20, 0.20),
        "door": (0.520, 0.720),
        "spawn": (0.520, 0.660),
        "facing": "north",
        "stop": (0.520, 0.585),
    },
}

TRANSIT_STOPS = ["home", "plaza", "exchange", "dock"]
