# 对话 · E007 洋行第一次考察

> 入口：`dialog_e007_start` · 事件 [`../07_事件档案/主线/E007_洋行第一次考察.md`](../07_事件档案/主线/E007_洋行第一次考察.md)  
> 无论选项，均建立认知：「洋人正在考察钱家」（路线 C 前置）。

---

## 节点图

```
dialog_e007_start
  → dialog_e007_bradley_greet
  → dialog_e007_qian_reply
  → dialog_e007_observe
  → dialog_e007_choice
       ├─ A → dialog_e007_outro_a → END
       ├─ B → dialog_e007_outro_b → END
       └─ C → check intel≥10
              ├─ pass → dialog_e007_outro_c_ok → END
              └─ fail → dialog_e007_outro_c_fail → END
```

---

## Nodes

### `dialog_e007_start`

```yaml
dialog_id: dialog_e007_start
event_id: E007
speaker: narrator
loc_key: dialog.e007.start
text_zh: |
  一辆漆黑的洋式马车停在钱记商行门前。下来一个穿中式长衫的洋人，操着一口流利官话，自称宝顺洋行的「白先生」。
tags: [mainline, foreign]
next: dialog_e007_bradley_greet
```

### `dialog_e007_bradley_greet`

```yaml
dialog_id: dialog_e007_bradley_greet
speaker: char_bradley
loc_key: dialog.e007.bradley_greet
text_zh: |
  钱东家，久仰。宝顺洋行新开了古董行当，听说钱记在天津商界交游广阔，特来讨教。
next: dialog_e007_qian_reply
```

### `dialog_e007_qian_reply`

```yaml
dialog_id: dialog_e007_qian_reply
speaker: char_qian_demao
loc_key: dialog.e007.qian_reply
text_zh: |
  白先生客气。请里面坐。
next: dialog_e007_observe
```

### `dialog_e007_observe`

```yaml
dialog_id: dialog_e007_observe
speaker: narrator
loc_key: dialog.e007.observe
text_zh: |
  白瑞德坐下后，话题从瓷器聊到字画，从字画聊到青铜器，对中国文物的知识面令钱德茂都有些意外。
  但林瑞生在旁倒茶时注意到——白瑞德的目光一直在扫商行的陈设、伙计的做派、货单的堆放方式。

  他不是来聊古董的。他在评估钱记商行的实力。
next: dialog_e007_choice
```

### `dialog_e007_choice`

```yaml
dialog_id: dialog_e007_choice
event_id: E007
speaker: narrator
loc_key: dialog.e007.choice_prompt
text_zh: |
  （你怎么做？）
tags: [mainline, choice]
choices:
  - id: A
    loc_key: dialog.e007.choice.a
    text_zh: 主动搭话，展示对文物的了解
    effects:
      - { op: add, key: stat_intel, value: 5 }
      - { op: add, meter: impression_bradley, value: 10 }
      - { op: add, edge: {from: char_bradley, to: char_lin_ruisheng}, key: score, value: 10 }
      - { op: add, key: stat_trust_firm, value: -5 }
      - { op: add, edge: {from: char_qian_demao, to: char_lin_ruisheng}, key: suspicion, value: 1 }
      - { op: add, edge: {from: char_qian_demao, to: char_lin_ruisheng}, key: score, value: -5 }
      - { op: set_flag, key: flag_know_bradley_scouting, value: true }
    next: dialog_e007_outro_a
  - id: B
    loc_key: dialog.e007.choice.b
    text_zh: 默默倒茶，不动声色
    effects:
      - { op: add, key: stat_intel, value: 3 }
      - { op: set_flag, key: flag_know_bradley_scouting, value: true }
    next: dialog_e007_outro_b
  - id: C
    loc_key: dialog.e007.choice.c
    text_zh: 找借口接近，偷听后续谈话
    check:
      require: { key: stat_intel, op: ">=", value: 10 }
      on_pass:
        effects:
          - { op: add, key: stat_intel, value: 8 }
          - { op: set_flag, key: flag_know_bradley_scouting, value: true }
          - { op: set_flag, key: flag_heard_bradley_needs_comprador, value: true }
        next: dialog_e007_outro_c_ok
      on_fail:
        effects:
          - { op: add, key: stat_suspicion, value: 10 }
          - { op: set_flag, key: flag_know_bradley_scouting, value: true }
        next: dialog_e007_outro_c_fail
```

### Outros

```yaml
dialog_id: dialog_e007_outro_a
speaker: narrator
loc_key: dialog.e007.outro.a
text_zh: |
  白瑞德多看了你一眼。钱德茂的笑容淡了一分——学徒不该这么抢话。
next: null

dialog_id: dialog_e007_outro_b
speaker: narrator
loc_key: dialog.e007.outro.b
text_zh: |
  白先生没注意你。你却把他对物流、人脉、官场背景的打量，一一记在心里。
next: null

dialog_id: dialog_e007_outro_c_ok
speaker: narrator
loc_key: dialog.e007.outro.c_ok
text_zh: |
  你听清了：他要找「有官场背景的本地人」长期合作古董收购，对钱记的评估尚未定论。
next: null

dialog_id: dialog_e007_outro_c_fail
speaker: narrator
loc_key: dialog.e007.outro.c_fail
text_zh: |
  「瑞生，茶凉了。」钱德茂的声音不重，你却背上发凉。
next: null
```
