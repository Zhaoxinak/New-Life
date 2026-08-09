# -*- coding: utf-8 -*-
"""Do NOT overwrite the painted harbor map.

The live art is game/art/world/harbor_outdoor.png (pixel harbor from
harbor_outdoor_wide). Procedural generation was rejected — keep the painted asset.
"""
print(
    "Refusing to overwrite painted harbor_outdoor.png.\n"
    "Source of truth: game/art/world/harbor_outdoor.png\n"
    "(backup copies live under Cursor assets/harbor_outdoor_wide.png)"
)
raise SystemExit(1)
