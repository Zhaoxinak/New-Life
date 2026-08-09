# 混合时钟 + 地图升档（落地口径）

> 对应计划：小镇地图 + 混合时钟（1B 地图 / 2C 时间）  
> Pack：core **0.9.17** · schema 6；本文件只锁**运行口径**，不改主线 CSV 权威。

## 日钟

| 项 | 值 |
|---|---|
| 可活动窗 | 06:00–22:00 |
| `morning` | 06:00–11:59 |
| `afternoon` | 12:00–17:59 |
| `evening` | 18:00–21:59 |
| 宵禁 | ≥22:00 → 次日 06:00（`day_ended` + 时段早上） |
| 夜前提示 | 21:30 `tip_night_home` |

## 地图开关

- [`WorldHost.USE_TOWN_MAP`](game/world/WorldHost.gd) = `true` → [`TownOutdoor`](game/world/TownOutdoor.gd)（AI Town `town.png` + `place_bridge` 门洞）
- `false` → 旧港湾图

## Town 人物 / 路径 / 无 LLM 智能（对齐 demo_ai_town）

| 层 | 实现 | 不做 |
|---|---|---|
| 寻路 | [`TownOutdoorPathfinder`](game/world/town/nav/TownOutdoorPathfinder.gd) + `outdoor_navigation_grid.json` | 不搬完整 `TownWorldRuntime` |
| 人物 | [`TownOutdoorNpc`](game/world/TownOutdoorNpc.gd) + [`TownWhitebodyRig`](game/world/town/TownWhitebodyRig.gd)（complete-set 表） | 玩家暂留 [`Player.gd`](game/world/Player.gd) |
| 智能 | [`NpcBrain`](game/systems/NpcBrain.gd) + [`NpcPerception`](game/systems/NpcPerception.gd) + `goal_pressure` | **不接** LLM `AgentSystem` / Prompt / Provider |

- 任务光路：`find_walk_path` 真折线（失败时 L 弯回退）
- 家门口：`npc_homes.town_place_id` / `TownOutdoor.NPC_HOME_PLACE`
- 感知半径：320（与 AI Town `perceptionRange` 一致）

## 流速（`ClockSystem`）

| 模式 | 游戏分 / 现实秒 |
|---|---:|
| 站立 `idle` | 0 |
| 走动 `walk` | 0.4 |
| 忙碌 `busy` | 12.0 |

对话 / 事件 / 结局 / 小游戏打开时：**暂停走动耗时**；已开始的忙碌仍继续。

## 行动耗时

- 优先列 `duration_minutes`（可选）
- 否则：`time_cost<=0` → 0；`time_cost` → `×120` 游戏分
- 忙碌期间 `GameFlow.clock_busy` 挡操作；结束后再结算结果文案 / 任务推进

## 联动

- **天气**：跨时段仍 `WeatherSystem.apply_for_current`；变天 tip `tip_weather_change`
- **任务**：`QuestGuide` 忽略忙碌中途的 `action_resolved`；完成以 busy 结束为准；`hint_location_id` / `hint_npc_id` 驱动找人提示与路径高亮
- **事项**：玩家须到 `place_id`（室内或门口）才结算；逾时未到 → `matter.miss`
- **提示**：`tip_clock_*` / `tip_night_home` / `tip_time_waste` / `tip_matter_*`

## 存档

- 新增 `minute_of_day`；旧档按 `period` 默认钟点回填（早 08:00 / 午 14:00 / 晚 19:00）
