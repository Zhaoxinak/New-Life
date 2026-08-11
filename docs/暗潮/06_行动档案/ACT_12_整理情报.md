# 整理情报 · `act_12`

| 项 | 内容 |
|---|---|
| id | `act_12` |
| 地点 | `loc_06` |
| 时段 | late_night |
| 前置 | 无 |
| 对话入口 | [`DIALOG_ACT_POOL`](../11_对话档案/DIALOG_ACT_POOL.md) · `dialog_act_12_outro_default` |

## 金钱戏

| 项 | 内容 |
|---|---|
| 类型 | 门路钱（变现前置） |
| 对谁 | 林瑞生——把情报换成价码 |
| 戏剧 | 整理本身不扣钱，但推论解锁后，情报可以卖、可以换、可以要挟——E015/E017 的“黑账钱”从这里长出来。 |
| 拿不到 | 线索堆着用不上；竞品/洋人线缺可交付的成果 |

```yaml
effects:
  - { op: add_range, key: stat_intel, min: 2, max: 4 }
  - { op: maybe_unlock_inference: true }
note: 与 08_线索档案、E015 变现分支衔接
```
