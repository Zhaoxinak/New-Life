# 洋人暗查记录 · `item_bradley_spy_note`

| 项 | 内容 |
|---|---|
| `id` | `item_bradley_spy_note` |
| 显示名 loc | `item.bradley_spy_note.name` |
| 类型 | `leverage` |
| 获取 | E011 选项 B（暗记随从抄货单）→ 同时 `flag_saw_bradley_spy` |
| 失去 | 交给白瑞德/赵鸿运后可保留记忆旗标 |
| 风险 | 低；主要是情报价值 |

## 用途

| 场景 | 效果摘要 |
|---|---|
| E017 递刀铺垫 | 证明洋人已在摸钱记物流 |
| 卖竞品 | 人脉/银钱（可后补行动） |

```yaml
# E011B 建议追加
- { op: set_flag, key: flag_saw_bradley_spy, value: true }
- { op: grant_item, id: item_bradley_spy_note }
```
