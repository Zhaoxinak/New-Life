# ACT_04 · 请师兄喝酒 · `act_04`

| 项 | 内容 |
|---|---|
| id | `act_04` |
| 地点 | `loc_03` |
| 时段 | evening |
| 前置 | 金钱≥3 |
| 对话入口 | [`DIALOG_ACT_POOL`](../11_对话档案/DIALOG_ACT_POOL.md) · `dialog_act_04_outro_*` |

## 金钱戏

| 项 | 内容 |
|---|---|
| 类型 | 情面钱 |
| 对谁 | 林瑞生 ↔ 王胖子 |
| 戏剧 | 三两大酒钱，买的是师兄嘴里的实话和后院门缝里的风声。王胖子不缺这顿酒，缺的是“你把我当自个儿人”的确认。 |
| 拿不到 | 交情涨得慢；E010 深夜可疑货物、后院动向等情报入口变窄 |

### 阈值台词（表现层）

| 条件 | 反馈 |
|---|---|
| `stat_money < 20` | 「这顿酒几乎掏空了兜里的活钱；师兄拍肩说‘兄弟，我记着你这份心’。」 |
| `stat_money >= 50` | 「酒钱算不了什么，师兄却低语：‘钱记近来货栈那边，别问太细——有人问，推给我。’」 |

```yaml
effects:
  - { op: add, key: stat_money, value: -3 }
  - { op: add, edge: {from: char_wang_pangzi, to: char_lin_ruisheng}, key: score, value: 5 }
  - { op: add, edge: {from: char_lin_ruisheng, to: char_wang_pangzi}, key: score, value: 3 }
  - { op: add_range, key: stat_intel, min: 1, max: 3 }
note: 王胖子档案 §2：好一口酒；情面比银子重要，但银子是开口的前提
```
