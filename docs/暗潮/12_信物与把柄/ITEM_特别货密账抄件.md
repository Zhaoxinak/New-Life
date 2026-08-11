# 特别货密账抄件 · `item_special_ledger_copy`

| 项 | 内容 |
|---|---|
| `id` | `item_special_ledger_copy` |
| 显示名 loc | `item.special_ledger_copy.name` |
| 类型 | `leverage` |
| 获取 | E013 选项 B（偷走密账）→ 实物；选项 A 仅为记忆（无线索物品，只靠 clue） |
| 失去 | 交还给钱德茂 / 被搜出 / 销毁 |
| 风险 | 持有期间商行搜查 → 嫌疑暴增；可 unlock `clue_special_goods` quality=physical |

## 用途

| 场景 | 效果摘要 |
|---|---|
| 要挟钱德茂 | 恐惧/交情博弈（正式版展开） |
| 卖给赵鸿运 | 跳槽线筹码 |
| 向海关/政敌 | 第五层鸦片弧伏笔 |

## 与线索关系

- `clue_special_goods` = 知道内容  
- 本 item = **拿得出手的抄件/原件**  
- E013A 只有 clue，无本 item  

```yaml
# E013B 建议追加
- { op: unlock_clue, id: clue_special_goods, quality: physical }
- { op: grant_item, id: item_special_ledger_copy }
- { op: set_flag, key: flag_ledger_stolen, value: true }
```
