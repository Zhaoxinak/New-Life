# 暗中观察 · `act_09`

| 项 | 内容 |
|---|---|
| id | `act_09` |
| 地点 | `loc_02` |
| 时段 | late_night |
| 前置 | 无 |
| 对话入口 | [`DIALOG_ACT_POOL`](../11_对话档案/DIALOG_ACT_POOL.md) · `dialog_act_09_outro_default` |

## 金钱戏

| 项 | 内容 |
|---|---|
| 类型 | 黑账钱（风险） |
| 对谁 | 林瑞生——用前途换真相 |
| 戏剧 | 不花钱，但一旦被逮，丢差事、丢月例、丢体面——比花十两更疼。E010 深夜可疑货物的日常版。 |
| 拿不到 | 情报；若 suspicion 过高触发 F001/F002 |

```yaml
tags: [covert, high_risk]
effects:
  - { op: add_range, key: stat_intel, min: 2, max: 5 }
  - { op: add_range, key: stat_suspicion, min: 5, max: 10 }
note: 与 E010/E015 黑账钱戏同轴；穷时更输不起
```
