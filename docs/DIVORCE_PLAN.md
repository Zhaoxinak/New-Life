# 晚晴退婚／散伙线 — 验收清单

> 表内身份仍是未婚妻；剧情用退婚／散伙承担「离婚」重量。可选，不锁主线。

## 旗标

| 旗标 | 含义 |
|---|---|
| `divorced_su` | 已退婚 |
| `divorce_as_weapon` | 把退婚当离间刀 |
| `divorce_snooze` | 摊牌推迟一晚（跨日清晨清除） |
| `divorce_aftermath_done` | 余波已播 |

## 触发（非强制）

日 ≥ 6、未退婚、非 snooze 夜，且任一：

- `su_accepts_son_gifts`
- 晚晴 favor ≤ 40
- `resigned_hongyuan` / `joined_tongyang`
- `su_may_betray`

入口：

1. 晚间事件 `ev_divorce_ultimatum`
2. 客厅行动 `home_propose_divorce` → `dlg_home_divorce`

## 三选一

| 选项 | 记忆点 |
|---|---|
| 冷退 | `divorced_su`；favor/trust 大跌；少霆 intimacy↑；张力小涨 |
| 再忍 | `divorce_snooze`；可次日再谈 |
| 当刀 | `divorced_su` + `divorce_as_weapon`；张力↑↑；嫌疑↑ |

## 日常变味

- `home_guide_su`：退婚后锁定
- `dlg_su_talk` 变体：冷／礼；武器化带惧意
- 茶馆闲话：`chatter_divorce_rumor` / `chatter_divorce_weapon`
- 余波事件：`ev_divorce_aftermath`

## 主线软挂钩（正文附加段）

| 线 | 键 |
|---|---|
| D7 | `events.ev_day7_choice.body_divorced` |
| B 公开对立 | `body_divorced` +（武器化）`body_divorce_weapon` |
| A 截胡 | `events.ev_a_first_strike.body_divorced` |
| C 平仓 | `events.ev_c_first_short.body_divorced` |
| A 日常 | 陈掌柜 `var_chen_lobby_l02_divorced` |

## 验收

- [ ] 不退婚也能完整打工／通洋／主线
- [ ] 三选项台词与数值立刻不同
- [ ] 退婚后枕边风灰掉；客厅对话变冷
- [ ] `divorce_as_weapon` 后 B 公开对立点题
- [ ] 存读档旗标不丢
- [ ] HUD 在裂痕就绪时提示「今晚或许该回家谈清楚」
