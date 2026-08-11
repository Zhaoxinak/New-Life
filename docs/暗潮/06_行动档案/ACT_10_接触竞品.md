# ACT_10 · 接触竞品 · `act_10`

| 项 | 内容 |
|---|---|
| id | `act_10` |
| 地点 | `loc_03` |
| 时段 | afternoon, evening |
| 前置 | 人脉≥10 |
| 对话入口 | [`DIALOG_ACT_POOL`](../11_对话档案/DIALOG_ACT_POOL.md) · `dialog_act_10_outro_*` |

## 金钱戏

| 项 | 内容 |
|---|---|
| 类型 | 黑账钱（前置） |
| 对谁 | 林瑞生 ↔ 赵鸿运 / 聚丰行 |
| 戏剧 | 赵鸿运先看的不是你的人，是你“像不像值得投”。Demo 里竞品资助是跳槽线的甜头，但钱记会记仇——没钱有胆也接不住后续的价码。这里也是 `stat_credit_market` 的第一块垫脚石。 |
| 拿不到 | 赵鸿运 edge 涨不动；R005 聚丰行接触缺铺垫 |

### 阈值台词（表现层）

| 条件 | 反馈 |
|---|---|
| `stat_money < 20` | 赵鸿运打量你：“有心跳槽，得先像能周转的人；穷鬼我请不起。” |
| `stat_money >= 50` | 「赵鸿运递茶：‘林掌柜手头活泛，聚丰行缺会算账的人。’——话里没银子，眼里有数。」 |

### B 线收益层级（跳槽线口径）

- `act_10` 对应**层 2：被报价资格 / 市场授信的前置**。它不直接给你启动资金，但让赵鸿运“愿意把你记进投位名单”
- 对应财感：主要加 `stat_credit_market`（后续 R005 的报价会更顺）

```yaml
effects:
  - { op: add_range, key: stat_network, min: 3, max: 5 }
  - { op: add, key: stat_credit_market, value: 5 }
  - { op: add_range, edge: {from: char_zhao_hongyun, to: char_lin_ruisheng}, key: score, min: 3, max: 5 }
  - { op: add, edge: {from: char_lin_ruisheng, to: char_zhao_hongyun}, key: score, value: 2 }
note: `stat_credit_market` 代表街市与竞品眼里“值不值得继续往来”；后续 R005 / 跳槽线可联动此值
```
