# 12 · 信物与把柄

> 定义表 `def_item`；持有状态在存档 `run_item`。  
> Effect：`grant_item` / `revoke_item`（见 [`../00_总纲/effect词汇表.md`](../00_总纲/effect词汇表.md)）。

**信物 ≠ 交情**：有把柄可逼事，但通常伴随交情下降。

---

## 1. 类型

| 类型 | 说明 |
|---|---|
| `token` | 信物/手书/凭据 |
| `leverage` | 把柄（可逼一次） |
| `sample` | 物证样品 |

### 情面资产（不默认进 `item`）

礼物、退礼、金镯、点心、席面承诺这类内容，优先视为**关系金融**，而不是硬物品：

- 欠心意 → 记 `run_edge.debt`
- 被礼压住 / 被礼拿捏 → 记 `run_edge.leverage`
- 真正拿在手里、可转交、可出示的东西，才进 `run_item`

例：

- `ACT_06` 的点心更像“欠心意 / 表过心”
- `E008` 的金镯更像“拿礼压人”
- `E012` 的受礼传消息，是把情面变成控制

---

## 2. Demo 条目

| id | 文件 | 类型 | 获取 |
|---|---|---|---|
| `item_qing_letter` | [ITEM_庆系手书.md](ITEM_庆系手书.md) | token | E014A |
| `item_special_ledger_copy` | [ITEM_特别货密账抄件.md](ITEM_特别货密账抄件.md) | leverage | E013B |
| `item_opium_sample` | [ITEM_鸦片样品.md](ITEM_鸦片样品.md) | sample | E015A |
| `item_bradley_spy_note` | [ITEM_洋人暗查记录.md](ITEM_洋人暗查记录.md) | leverage | E011B |

---

## 3. 专页字段

| 项 | 内容 |
|---|---|
| `id` | `item_*` |
| 显示名 loc | |
| 类型 | token / leverage / sample |
| 获取 / 失去 | |
| 用途表 | |
| 风险 | |

---

## 4. 版本

| 版本 | 内容 |
|---|---|
| v0.1 | 占坑表 |
| **v0.2** | 四条 Demo 专页 + 事件 grant_item 挂钩 |
