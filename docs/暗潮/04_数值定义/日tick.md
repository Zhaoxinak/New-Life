# 日 tick · 时间流动自动改数

> P 社 `on_action` 对应物。档案定义规则；运行时每日/每时段套用。

---

## 1. 日末结算 `on_day_end`

```yaml
on_day_end:
  - { op: add, key: stat_money, value: -1, reason: "生活费" }
  # 若当日执行过「商行干活」类达标差事，另计打工收入（或并入行动 effect，勿双算）
  - id: marriage_fund_pressure
    if:
      all:
        - { flag: flag_need_marriage_fund, value: true }
        - { stat_money: { lt: 30 } }
    then: { op: set_flag, key: flag_need_marriage_fund, value: true }
    note: "婚事资金压力持续存在；低于三十两时默认仍未缓解"
  - id: money_pressure_broke
    if: { stat_money: { lt: 10 } }
    then: { op: set_flag, key: flag_money_broke, value: true }
    note: "断炊档；UI 可挂拮据台词，部分情面行动效果打折（实现时表）"
  - id: money_pressure_tight
    if: { stat_money: { gte: 10, lt: 20 } }
    then: { op: set_flag, key: flag_money_tight, value: true }
    note: "拮据档；见 06_行动档案 各 ACT 阈值台词"
  - id: bank_loan_interest
    if: { flag: flag_bank_loan_active }
    then: { op: add, key: stat_money, value: -1, reason: "票号息" }
    note: "ACT_11 短借还款；还清后清 flag"
  - id: neglect_liu
    if: { not_acted: act_06, days: 1 }  # 当日未陪伴
    then: { op: add_edge, from: char_liu_ruyan, to: char_lin_ruisheng, key: score, value: -8 }
    note: "冷落→如烟对你交情分下降；可调为仅连续冷落才触发"
```

可选（实现时二选一，避免与行动重复）：

```yaml
# 方案 A：打工收入只在 act_01 effect
# 方案 B：日末若 flag_worked_today → money +3
```

婚事资金压力口径：

- `flag_need_marriage_fund` 一般由 `E002` / `E008` 抬起
- 当 `stat_money >= 30` 且发生明确“办体面/备婚事”行为时，可清除此旗
- `ACT_11.remit`、`ACT_06`、`ACT_08`、日末婚事提示可共同读取此旗

---

## 2. 时段进入 `on_slot_enter`

```yaml
on_slot_enter:
  late_night:
    - { op: set_temp, key: risk_tier, value: high }
```

---

## 3. 行动后通用 `on_action_after`

```yaml
on_action_after:
  - if: { slot: late_night, action_tag: covert }
    then: { op: add_range, key: stat_suspicion, min: 5, max: 15 }
```

（若各行动已自带嫌疑 effect，则此处不再叠乘——**实现只留一处权威**。）

---

## 4. 关系自然漂移（可选低频）

| 边 | 条件 | tick |
|---|---|---|
| `rel_liu_zian_intimacy` / pursuit | 已开启「受礼传消息」旗标 | 每 N 日 +小额（伴随情报事件） |
| `eval`（白→钱） | 无 | 默认不漂；仅事件改 |

---

## 5. 扫描顺序（建议）

```
时段行动 effect
  → on_action_after
  → 关系阈值扫描（见 05_关系档案/关系触发逻辑.md）
  → 若触发派生事件则再 apply
  → 日末：on_day_end
```
