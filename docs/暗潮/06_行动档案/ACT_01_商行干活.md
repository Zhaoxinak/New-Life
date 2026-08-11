# 商行干活 · `act_01`

| 项 | 内容 |
|---|---|
| id | `act_01` |
| 地点 | `loc_01` |
| 时段 | morning, noon |
| 前置 | 无 |
| 对话入口 | [`DIALOG_ACT_POOL`](../11_对话档案/DIALOG_ACT_POOL.md) · `dialog_act_01_outro_*` |

## 金钱戏

| 项 | 内容 |
|---|---|
| 类型 | 生存钱 |
| 对谁 | 林瑞生——最干净的活路 |
| 戏剧 | 前堂搬货、对账、跑腿，月例外的零碎进账。钱少时这是唯一不惹嫌疑的收入；钱够时仍值得做，因为商行信任比两银子更慢更难补。 |
| 拿不到 | 信任不涨、跑街无望；拮据时连“像样伙计”的体面都维持不住 |

### 阈值台词（表现层）

| 条件 | 反馈 |
|---|---|
| `stat_money < 20` | 「今日又挣得二三两，够吃几天；再省一点，聘礼仍像天边的数。」 |
| `stat_money >= 50` | 「活还是那些活，银子却不像以前那样掐着花——可东家眼里，勤快仍比阔气要紧。」 |

### A 线收益层级（隐忍线口径）

- `act_01` 的金钱戏是**层 1：月例保活层**（稳定补血的生存钱）
- 同时通过 `stat_trust_firm` 给你一点**层 4 前置**：让“替商行出面/先垫后报”更容易发生在后续事件里

```yaml
effects:
  - { op: add_range, key: stat_trust_firm, min: 2, max: 5 }
  - { op: add_range, key: stat_money, min: 2, max: 3 }
  - { op: set_flag, key: flag_worked_today, value: true }
note: 日末仍扣生活费 -1；打工是 Demo 最稳的 stat_money 来源
```
