# 对话 · 朝账诸人建言（共用池）

> 服务例行朝账 ④ 段；剧情朝账 M001–M003 可 override 部分条目。  
> 规则：[`../17_朝账系统/诸人建言.md`](../17_朝账系统/诸人建言.md)  
> 生成：`game/tools/gen_p19_meeting_council_content.py`

---

## 入口 / 路由

| 节点 | 用途 |
|---|---|
| `dialog_council_zhou_pick` | 周管事口径抽选（cycle_mod） |
| `dialog_council_after_zhou` | → 王口径 |
| `dialog_council_after_wang` | → 子安 / 仇人 / 玩家 / 定调 |
| `dialog_council_after_zian` | → 仇人 / 玩家 |
| `dialog_council_after_rival` | → 玩家 / 定调 |
| `dialog_meeting_council_player_pick` | 玩家：建言 / 附议(decide) / 不言 |
| `dialog_meeting_council_endorse` | 附议上一发言者 |
| `dialog_m000_council_listen*` | 旁听碎片（含仇人/少爷/简席快过） |

条件扩展：`council_has`、`cycle_mod`（见 ConditionEval）。

---

## 周管事 · 发言变体

| dialog_id | stance | 一句 |
|---|---|---|
| `dialog_council_zhou_order` | bright_steady | 按章、货单、别省东家的脸 |
| `dialog_council_zhou_manifest` | bright_steady | 货单墨色新旧不一，先对清楚 |
| `dialog_council_zhou_yard` | look_away | 后院少问，明面先稳住 |
| `dialog_council_zhou_pass` | — | 目光一扫，没开口 |

---

## 王胖子 · 发言变体

| dialog_id | stance |
|---|---|
| `dialog_council_wang_front` | bright_steady · 人手紧 |
| `dialog_council_wang_street` | watch_jufeng · 聚丰压价 |
| `dialog_council_wang_hands` | bright_steady · 该出力还得出 |
| `dialog_council_wang_pass` | 沉默喝茶 |

---

## 钱子安

| dialog_id | stance |
|---|---|
| `dialog_council_zian_show` | son_first · 摆排场 |
| `dialog_council_zian_boast` | son_first · 洋人/面子自夸 |
| `dialog_council_zian_pass` | 哼一声不说 |

---

## 仇人踩线（满席 / 序位紧逼）

入队：`MeetingSystem.pick_meeting_rival()` → `council_queue`。

| 角色 | dialog_id | 效果 |
|---|---|---|
| 孙六 | `dialog_council_sun_step` / `sun_flatter` | 当面踩玩家勤快假象；己序位+、玩家− |
| 赵外场 | `dialog_council_zhao_step` / `zhao_sneer` | 外场嘴皮 vs 算账；序位对撞 |

旁听碎片：`dialog_m000_council_listen_rival` / `_listen_zian`。

---

## 玩家 · 建言选项

同前：稳明面 / 盯聚丰 / 少问后院 / 直报货单（要胆）。  
`decide` 可附议：见 `dialog_meeting_council_endorse`（`endorse_last_council`）。  
简席：`council_brief` 时压缩周/王变体与旁听时长。

---

## 东家反应

`dialog_meeting_council_demao_nod` / `demao_cut` → `dialog_meeting_council_next` → ⑤ 定调。
