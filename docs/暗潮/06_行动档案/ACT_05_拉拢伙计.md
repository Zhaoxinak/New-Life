# 拉拢伙计 · `act_05`

| 项 | 内容 |
|---|---|
| id | `act_05` |
| 地点 | `loc_02` |
| 时段 | noon, afternoon |
| 前置 | 无 |
| 对话入口 | [`DIALOG_ACT_POOL`](../11_对话档案/DIALOG_ACT_POOL.md) · `dialog_act_05_outro_*` |

## 金钱戏

| 项 | 内容 |
|---|---|
| 类型 | 情面钱 + 黑账钱（轻度） |
| 对谁 | 林瑞生 → 中层/下层伙计 |
| 戏剧 | 散碎银子、一包烟、替人顶半个时辰的班——买的是“出事了有人帮你圆”。洋人线 Day16 拦截前，中层/下层支持须均≥40；这钱不能省。 |
| 拿不到 | `stat_support_mid` / `stat_support_low` 涨不动；E014 钱子安发难时无人帮腔 |

### 阈值台词（表现层）

| 条件 | 反馈 |
|---|---|
| `stat_money < 20` | 「只够请一个人吃碗面；谁拿了好处，心里都记着，但也都知道你并不宽裕。」 |
| `stat_money >= 50` | 「赏钱给得大方，后院几个人交换眼神：‘林兄弟，有事言语。’」 |

```yaml
effects_branch:
  mid: { op: add, key: stat_support_mid, value: 3 }
  low: { op: add, key: stat_support_low, value: 2 }
cost:
  - { op: add_range, key: stat_money, min: -3, max: -1 }
note: 洋人线 Day16 拦截前需中层/下层均≥40；钱德茂视此为“收买”，嫌疑间接上升（实现时可选）
```
