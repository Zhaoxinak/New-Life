# 对话 · E011 洋行第二次考察

> 入口：`dialog_e011_start` · 事件 [`../07_事件档案/主线/E011_洋行第二次考察.md`](../07_事件档案/主线/E011_洋行第二次考察.md)  
> 选项 B → [`item_bradley_spy_note`](../12_信物与把柄/ITEM_洋人暗查记录.md)

---

## 节点图

```
dialog_e011_start
  → dialog_e011_bradley
  → dialog_e011_qian
  → dialog_e011_bradley_2
  → dialog_e011_spy
  → dialog_e011_choice
       ├─ A (intel≥20) → outro_a
       ├─ B → outro_b
       └─ C → outro_c
```

---

## Nodes

### `dialog_e011_start`

```yaml
dialog_id: dialog_e011_start
event_id: E011
speaker: narrator
loc_key: dialog.e011.start
text_zh: |
  白瑞德再次到访钱记商行。这次他带了一个随从，拿着一本册子，仔细记录商行的进出货情况。
  他提出要看看钱记的仓储能力和物流渠道——语气客气，但要求具体。
tags: [mainline, foreign]
next: dialog_e011_bradley
```

### `dialog_e011_bradley`

```yaml
dialog_id: dialog_e011_bradley
speaker: char_bradley
loc_key: dialog.e011.bradley
text_zh: |
  钱东家，上次聊得投机。我们洋行做事讲究实在——若要长期合作，得看看贵行的仓储条件、运输路线，也好放心。
next: dialog_e011_qian
```

### `dialog_e011_qian`

```yaml
dialog_id: dialog_e011_qian
speaker: char_qian_demao
loc_key: dialog.e011.qian
text_zh: |
  白先生，这些都是行里的机密……
next: dialog_e011_bradley_2
```

### `dialog_e011_bradley_2`

```yaml
dialog_id: dialog_e011_bradley_2
speaker: char_bradley
loc_key: dialog.e011.bradley_2
text_zh: |
  自然。朋友之间，先看后谈，不必勉强。
next: dialog_e011_spy
```

### `dialog_e011_spy`

```yaml
dialog_id: dialog_e011_spy
speaker: narrator
loc_key: dialog.e011.spy
text_zh: |
  钱德茂犹豫片刻，让账房带白先生去看前仓。
  林瑞生在旁倒水时注意到——白瑞德的随从趁机在抄写门口的货单挂牌。
next: dialog_e011_choice
```

### `dialog_e011_choice`

```yaml
dialog_id: dialog_e011_choice
event_id: E011
speaker: narrator
loc_key: dialog.e011.choice_prompt
text_zh: |
  （你怎么做？）
tags: [mainline, choice]
choices:
  - id: A
    loc_key: dialog.e011.choice.a
    text_zh: 借故接近白瑞德，展示对物流渠道的熟悉
    require:
      - { key: stat_intel, op: ">=", value: 20 }
    effects:
      - { op: add, key: stat_intel, value: 5 }
      - { op: add, meter: impression_bradley, value: 15 }
      - { op: add, edge: {from: char_bradley, to: char_lin_ruisheng}, key: score, value: 12 }
      - { op: add, key: stat_trust_firm, value: -5 }
      - { op: add, edge: {from: char_qian_demao, to: char_lin_ruisheng}, key: score, value: -5 }
      - { op: add, edge: {from: char_qian_demao, to: char_lin_ruisheng}, key: suspicion, value: 1 }
    next: dialog_e011_outro_a
  - id: B
    loc_key: dialog.e011.choice.b
    text_zh: 默默服务，暗中记下随从的举动
    effects:
      - { op: add, key: stat_intel, value: 8 }
      - { op: set_flag, key: flag_saw_bradley_spy, value: true }
      - { op: grant_item, id: item_bradley_spy_note }
    next: dialog_e011_outro_b
  - id: C
    loc_key: dialog.e011.choice.c
    text_zh: 找借口阻止随从抄写货单
    effects:
      - { op: add, key: stat_trust_firm, value: 10 }
      - { op: add, edge: {from: char_qian_demao, to: char_lin_ruisheng}, key: score, value: 8 }
      - { op: add, edge: {from: char_qian_demao, to: char_lin_ruisheng}, key: suspicion, value: -1 }
      - { op: add, meter: impression_bradley, value: -5 }
      - { op: add, edge: {from: char_bradley, to: char_lin_ruisheng}, key: score, value: -5 }
    next: dialog_e011_outro_c
```

### Outros

```yaml
dialog_id: dialog_e011_outro_a
speaker: narrator
loc_key: dialog.e011.outro.a
text_zh: |
  白瑞德对你的渠道见识点了点头。钱东家的眼神却冷了下来。
next: null

dialog_id: dialog_e011_outro_b
speaker: narrator
loc_key: dialog.e011.outro.b
text_zh: |
  你把随从抄挂牌的细节记在心里。洋人在暗中摸钱记的物流——这条，日后用得上。
next: null

dialog_id: dialog_e011_outro_c
speaker: narrator
loc_key: dialog.e011.outro.c
text_zh: |
  「瑞生办事稳。」钱德茂难得夸一句。白先生的笑意淡了淡。
next: null
```
