# 鸦片样品 · `item_opium_sample`

| 项 | 内容 |
|---|---|
| `id` | `item_opium_sample` |
| 显示名 loc | `item.opium_sample.name` |
| 类型 | `sample` |
| 获取 | E015 选项 A（取样放回暗箱） |
| 失去 | 交出/销毁/被搜 |
| 风险 | 被搜出 → 嫌疑极高；要挟力度高于「仅推断」 |

## 用途

| 场景 | 效果摘要 |
|---|---|
| 搭配 `clue_opium_secret` | 完整证据链 |
| 要挟/举报伏笔 | Demo 可不消耗，正式版分支用 |

```yaml
# E015A 建议追加
- { op: unlock_clue, id: clue_opium_secret }
- { op: grant_item, id: item_opium_sample }
```

E015B 只有 `clue_opium_infer`，**无**本 item（要挟减半）。
