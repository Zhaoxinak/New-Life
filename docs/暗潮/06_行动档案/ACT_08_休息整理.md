# 休息整理 · `act_08`

| 项 | 内容 |
|---|---|
| id | `act_08` |
| 地点 | `loc_06` |
| 时段 | evening, late_night |
| 前置 | 无 |
| 对话入口 | [`DIALOG_ACT_POOL`](../11_对话档案/DIALOG_ACT_POOL.md) · `dialog_act_08_outro_*` |

## 金钱戏

| 项 | 内容 |
|---|---|
| 类型 | 生存钱（反向） |
| 对谁 | 林瑞生——省钱换安全 |
| 戏剧 | 不出门、不请客、不打点，嫌疑下来，但银子也不进来。拮据时“休息”是无奈；宽裕时“休息”是策略。若 `flag_need_marriage_fund` 已抬起，这种“省着过”会更像把婚期往后拖。 |
| 拿不到 | 当日无收入；若连续休息且 `stat_money < 20`，叙事上“坐吃山空” |

### 阈值台词（表现层）

| 条件 | 反馈 |
|---|---|
| `stat_money < 20` | 「在货栈小屋数了数剩银，明日还得找活路。」 |
| `stat_suspicion >= 2` | 「闭门不出，让风头过去——穷一点，总比被抓现行强。」 |

```yaml
effects:
  - { op: add_range, key: stat_suspicion, min: -8, max: -5 }
  - { op: set_temp, key: next_slot_efficiency, value: 1.10 }
note: 日末仍扣生活费 -1；`flag_need_marriage_fund` 为 true 时，这类行动代表“省体面钱、拖婚事”
```
