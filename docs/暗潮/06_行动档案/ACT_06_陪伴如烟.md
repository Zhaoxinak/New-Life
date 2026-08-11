# ACT_06 · 陪伴如烟 · `act_06`

| 项 | 内容 |
|---|---|
| id | `act_06` |
| 地点 | `loc_06` |
| 时段 | evening |
| 前置 | 无 |
| 对话入口 | [`DIALOG_ACT_POOL`](../11_对话档案/DIALOG_ACT_POOL.md) · `dialog_act_06_outro_*` |

## 金钱戏

| 项 | 内容 |
|---|---|
| 类型 | 情面钱（可选） |
| 对谁 | 林瑞生 ↔ 柳如烟 |
| 戏剧 | 行动本身不扣钱，但“空着手去”和“带一点心意”差一截。金镯、退礼、敢不敢得罪钱家——如烟线的钱戏在事件里爆发，日常陪伴是铺垫；若已抬起 `flag_need_marriage_fund`，每次陪伴都在提醒“你心里有她，但钱还不够”。 |
| 拿不到 | 关系仍涨，但 E008/E012 关键抉择缺“你曾为她花过心”的叙事重量 |

### 阈值台词（表现层）

| 条件 | 反馈 |
|---|---|
| `stat_money < 20` | 「只陪坐说说话，如烟倒茶：‘你也不容易，别为我乱花钱。’」 |
| `stat_money >= 30` 且未触发 `flag_liu_gift_today` | 「捎了一包点心，如烟推辞半晌才收：‘你心里有我，就够了。’」 |

### 情面资产口径

- 点心、布头、小首饰这类小礼，默认不进 `run_item`
- 它们主要作用是把“你对如烟花过心思”写进 `run_edge.debt`
- 若 `flag_need_marriage_fund = true`，则这类花费天然带有“现在花在心意上，还是留作聘礼”的张力

```yaml
effects:
  - { op: add_range, edge: {from: char_liu_ruyan, to: char_lin_ruisheng}, key: score, min: 5, max: 10 }
  - { op: add, edge: {from: char_lin_ruisheng, to: char_liu_ruyan}, key: score, value: 3 }
  - { op: add, key: stat_suspicion, value: -3 }
  - { op: set_flag, key: flag_companied_liu_today, value: true }
optional_cost:
  - require: stat_money >= 3
  - { op: add, key: stat_money, value: -3 }
  - { op: add, edge: {from: char_liu_ruyan, to: char_lin_ruisheng}, key: score, value: 3 }
  - { op: set, edge: {from: char_liu_ruyan, to: char_lin_ruisheng}, key: debt, value: 收过你的小心意 }
note: `flag_need_marriage_fund` 为 true 时，此行动更偏“情面消费 vs 存聘礼”；可选花费实现时在 UI 给“带点心意”
```
