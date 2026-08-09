# 钱·权·女 玩法升档 — 验收清单

> pack `core` **0.9.12** · 薄切片：不造婚姻/新商店系统

## 金钱 — 买场面

| 行动 | 声望 |
|---|---|
| `home_upgrade_2` | `network_base` +2 |
| `home_upgrade_3` | `network_base` +3 |
| `home_upgrade_4` | `network_elite` +3 |

- Tip：`tip.home_upgrade` / `tip.money_ways` 串「赚钱 → 宅基/车行/茶馆」
- HUD：钱≥120 且 `home_tier<3` →「有钱了，去宅基撑场面」

## 权力 — 走廊碾压

| ID | 说明 |
|---|---|
| `ev_power_flex` | 下午；`claimed_promo_manager` **或** `claimed_promo_ty_supervisor`；`power_flex_done=0`；day≥10 |
| `ch_power_flex_accept` | 收下场面：声望/信任微涨 |
| `ch_power_flex_press` | 拿去压人：张力/嫌疑/情报；晚晴 favor↓ |
| `var_su_office_l01_promo` | 经理名分日常再撞 |

## 女人 — 三短弧

| 弧 | 旗标 | 点亮 | 节拍 |
|---|---|---|---|
| 求合 | `su_reconcile_path` | mend / comfort / soft talk | `ev_su_reconcile`（不消 `divorced_su`） |
| 利用 | `su_used_as_tool` | scheme / guide / afraid_use / 退婚当刀 | 变体 + `chatter_su_used_tool` |
| 放手 | `su_let_go` | 冷退 / betray push / 客厅「放手」 | `ev_su_let_go` |

变体优先级：利用(30) > 求合(22) > 放手(21) > 既有退婚。

主线软挂钩：

- `events.ev_b_public_clash.body_reconcile`
- `events.ev_day7_choice.body_let_go`
- 利用/当刀沿用 `body_divorce_weapon`

## 验收

- [ ] 宅基升级后声望立刻动；tip/HUD 能串「赚钱→撑场面」
- [ ] 晋升经理或通洋主管后下午能撞走廊碾压，两选项味道不同
- [ ] 求合/利用/放手可由现有对话或事件点亮，客厅台词变味
- [ ] 求合不抹掉 `divorced_su`；退婚线仍可选
- [ ] 存读档旗标不丢
