# 对话 · 朝账诸人建言（共用池）

> 服务例行朝账 ④ 段；剧情朝账 M001–M003 可 override 部分条目。  
> 规则：[`../17_朝账系统/诸人建言.md`](../17_朝账系统/诸人建言.md)

---

## 入口

| 节点 | 用途 |
|---|---|
| `dialog_meeting_council_turn` | 系统：轮到 `char_*`，判 speak / pass |
| `dialog_meeting_council_player_pick` | 玩家建言话题分支 |
| `dialog_meeting_council_player_pass` | 玩家「不言」 |
| `dialog_meeting_council_endorse` | 玩家附议 |

---

## 周管事 · `char_zhou_guanshi`

### 发言

```yaml
dialog_id: dialog_council_zhou_order
speaker: char_zhou_guanshi
loc_key: council.zhou.order
text_zh: |
  后院账房这几日按章走，货单别拖拉。谁要省事，最后省的是东家的脸。
stance: bright_steady
effects:
  - { op: record_council_speech, char: char_zhou_guanshi, spoke: true, topic_key: council.zhou.order, stance: bright_steady }
  - { op: add_policy_draft, key: bright_steady, value: 2 }
```

### 沉默

```yaml
dialog_id: dialog_council_zhou_pass
speaker: narrator
loc_key: council.zhou.pass
text_zh: |
  周管事目光一扫，没开口。
effects:
  - { op: record_council_speech, char: char_zhou_guanshi, spoke: false, mode: pass }
```

---

## 王胖子 · `char_wang_pangzi`

### 发言

```yaml
dialog_id: dialog_council_wang_front
speaker: char_wang_pangzi
loc_key: council.wang.front_busy
text_zh: |
  前堂这几日货来货往，人手紧。要再减人，怕误了客。
stance: bright_steady
effects:
  - { op: record_council_speech, char: char_wang_pangzi, spoke: true, stance: bright_steady }
  - { op: add_policy_draft, key: bright_steady, value: 1 }
```

### 沉默

```yaml
dialog_id: dialog_council_wang_pass
speaker: narrator
text_zh: |
  王胖子低头喝茶，没接话。
effects:
  - { op: record_council_speech, char: char_wang_pangzi, spoke: false, mode: pass }
```

---

## 钱子安 · `char_qian_zian`（`flag_zian_arrived`）

### 发言

```yaml
dialog_id: dialog_council_zian_show
speaker: char_qian_zian
loc_key: council.zian.show
text_zh: |
  我看街面上要摆排场，别老抠那几两银子。钱记的脸面，不能比聚丰矮一截。
stance: son_first
effects:
  - { op: record_council_speech, char: char_qian_zian, spoke: true, stance: son_first }
  - { op: add_policy_draft, key: son_first, value: 2 }
  - { op: add, meter: father_son, value: -5 }
```

### 沉默

```yaml
dialog_id: dialog_council_zian_pass
speaker: narrator
text_zh: |
  少爷钱子安哼了一声，竟也没再往下说。
effects:
  - { op: record_council_speech, char: char_qian_zian, spoke: false, mode: pass }
```

---

## 玩家 · 建言选项

### `dialog_meeting_council_player_pick`

```yaml
choices:
  - id: steady
    label: 稳明面，紧货单
    next: dialog_council_player_steady
  - id: market
    label: 盯聚丰压价
    next: dialog_council_player_market
  - id: look_away
    label: 少问后院
    next: dialog_council_player_look_away
  - id: risk
    label: 直报货单不对（要胆）
    require: [{ key: stat_intel, op: ">=", value: 15 }]
    next: dialog_council_player_risk
```

### `dialog_council_player_steady`

```yaml
speaker: char_lin_ruisheng
text_zh: |
  回东家，孙辈以为：明面货单先理清楚，比急着扩门面稳当。
effects:
  - { op: record_council_speech, char: char_lin_ruisheng, spoke: true, stance: bright_steady, mode: speak }
  - { op: add_policy_draft, key: bright_steady, value: 2 }
  - { op: add, key: stat_trust_firm, value: 2 }
next: dialog_meeting_council_demao_nod
```

### `dialog_meeting_council_player_pass`

```yaml
speaker: char_lin_ruisheng
text_zh: |
  ……你退后半步，没接话。
effects:
  - { op: record_council_speech, char: char_lin_ruisheng, spoke: false, mode: pass }
next: dialog_meeting_council_next
```

---

## 东家反应（④ 段末，进 ⑤ 前）

```yaml
dialog_id: dialog_meeting_council_demao_nod
speaker: char_qian_demao
text_zh: |
  嗯。
next: dialog_meeting_council_next

dialog_id: dialog_meeting_council_demao_cut
speaker: char_qian_demao
text_zh: |
  够了。这话到此为止。
next: dialog_meeting_council_next
```

`dialog_meeting_council_next` 由系统推进 queue 中下一位或进入 ⑤ 定调。
