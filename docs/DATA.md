# 数据说明（SCHEMA 6 · core 0.9.1）

权威目录：`docs/tables/packs/core/`

---

## 原则

1. **逻辑在 CSV，文案在 l10n**  
2. **UI 布局不进玩法表**  
3. **加内容 = 加行 / 加 Pack**；同 id 后覆盖前  
4. `_examples/` 默认不加载  

---

## 改什么打开什么

| 目的 | 文件 |
|---|---|
| 调数值 | `effects.csv`、热区 `suspicion_mult` |
| 成功率 | `checks.csv`、`check_mods.csv`（**双方角色数据**） |
| 文案 | `l10n/*.csv` |
| 对白 / 变体 / 锁 | `dialogues*`、`conditions` |
| 金融 | `stock_*` |
| 解锁 | `unlock_schedule` + `conditions` |

---

## 行动流水线

```
选行动 → conditions → 对话/选项
  → action 固定代价（如贿赂扣款）
  → check_id？双方数据算成功率 → 成功/失败 effects
       成功才执行 stock_rule_id
  → 文案 / 闲聊 → 嫌疑 → 时段 → thresholds/events
```

---

## 检定（双方角色）

`checks.target_npc_id` = 主要对手（可空）。

```
chance = clamp(base + Σ contrib, chance_min, chance_max)
```

`check_mods.mod_kind`：

| kind | 含义 | contrib |
|---|---|---|
| `relation_scale` | 关系值 `source:target:key` | `clamp((v−ref)×scale, min_mod, max_mod)` |
| `stat_scale` | 玩家属性 | 同上 |
| `flag_flat` | 旗标为 1 | 直接加 `scale`（可为负） |

**设计要点：**

- 对 **少霆**（假消息）：看少霆对你的 favor/trust/suspicion + 你的 intel + 父子互信/矛盾  
- 对 **鸿业/公司**（偷听、偷单、收买、看账、栽赃、假传闻）：看鸿业对你的 trust/suspicion/favor + 你的 trust/intel/suspicion  
- 对 **陈掌柜**（私货）：看陈对你的 favor/trust/suspicion + 码头人脉  
- **码头闲聊**：主要看你的 `network_base`，公司风声作减成  

晚晴谈心等**不检定**，只走对白分支。

---

## 三线结局 / 金融

同 0.9：A/B/C 需 `ready + show`；假传闻仅成功才跑 `rule_rumor_fake`。

---

## 规模

检定 **10** · 双方修正约 **79** · Pack **0.9.1**
