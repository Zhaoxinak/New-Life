# 庆系手书 · `item_qing_letter`

| 项 | 内容 |
|---|---|
| `id` | `item_qing_letter` |
| 显示名 loc | `item.qing_letter.name` |
| 类型 | `token` |
| 获取 | E014 选项 A（护送银票交周管事后） |
| 失去 | 交出亮给白瑞德（E017A，可保留「已出示」旗标）；被搜出则极危 |
| 风险 | 持有本身嫌疑不高；滥用名头被庆系识破则灾难 |

## 用途

| 场景 | 效果摘要 |
|---|---|
| E017A 亮手书 | `impression_bradley` +25；白→林 score↑；`flag_ending_c_ready` |
| 对话/狐假虎威 | 证明「有京中通道」 |

## effects_on_use（E017A 时由事件写，不必物品自带）

```yaml
# 参考：事件施加，物品仅作 require
require:
  - { item: item_qing_letter, owned: true }
```

## 备注

Demo 可用「管事留下的片言只语/回条」演出，不必真有一封红头公文。
