# 对话 · E013 账房密账

> 入口：`dialog_e013_start` · 事件 [`../07_事件档案/主线/E013_账房密账.md`](../07_事件档案/主线/E013_账房密账.md)  
> 选项 B → [`item_special_ledger_copy`](../12_信物与把柄/ITEM_特别货密账抄件.md)

---

## 节点图

```
dialog_e013_start
  → dialog_e013_ledger
  → dialog_e013_realize
  → dialog_e013_choice
       ├─ A (intel≥30) → outro_a
       ├─ B → outro_b
       └─ C → outro_c
```

---

## Nodes

```yaml
dialog_id: dialog_e013_start
event_id: E013
speaker: narrator
loc_key: dialog.e013.start
text_zh: |
  林瑞生趁夜潜入账房。在钱德茂的书桌暗格里，他找到一本封面无字的账册。
require:
  - { key: stat_intel, op: ">=", value: 25 }
  - { clue: clue_light_crate, owned: true }
tags: [mainline, opium_arc]
next: dialog_e013_ledger

dialog_id: dialog_e013_ledger
speaker: narrator
loc_key: dialog.e013.ledger
text_zh: |
  翻开账册，里面记的是「特别货」的进出。每箱「特别货」进价八十两，售价三百两——利润是木材的四十倍。账册上还有一列收货人代号，全是化名，但最后一页写着：「庆大人·三千两·月奉」。
next: dialog_e013_realize

dialog_id: dialog_e013_realize
speaker: narrator
loc_key: dialog.e013.realize
text_zh: |
  林瑞生不是傻子。八十两进、三百两出，利润四十倍——木材做不出这个数。而「庆大人」三个字，让他隐约触到了一条他不该碰的线。
next: dialog_e013_choice

dialog_id: dialog_e013_choice
event_id: E013
speaker: narrator
loc_key: dialog.e013.choice_prompt
text_zh: |
  （你怎么做？）
tags: [mainline, choice]
choices:
  - id: A
    loc_key: dialog.e013.choice.a
    text_zh: 把密账记在脑子里，原样放回（先把“经手资格”学会）
    require:
      - { key: stat_intel, op: ">=", value: 30 }
    effects:
      - { op: add, key: stat_intel, value: 15 }
      - { op: add, key: stat_suspicion, value: 5 }
      - { op: unlock_clue, id: clue_special_goods }
    next: dialog_e013_outro_a
  - id: B
    loc_key: dialog.e013.choice.b
    text_zh: 偷走密账（拿到账权的影子，暗线入口更近）
    effects:
      - { op: add, key: stat_intel, value: 20 }
      - { op: add, key: stat_suspicion, value: 25 }
      - { op: unlock_clue, id: clue_special_goods, quality: physical }
      - { op: grant_item, id: item_special_ledger_copy }
      - { op: set_flag, key: flag_ledger_stolen, value: true }
    next: dialog_e013_outro_b
  - id: C
    loc_key: dialog.e013.choice.c
    text_zh: 只记最后一页（庆大人那行），放回（有线索但经手未够）
    effects:
      - { op: add, key: stat_intel, value: 10 }
      - { op: unlock_clue, id: clue_special_goods, quality: partial }
    next: dialog_e013_outro_c
```

### Outros

```yaml
dialog_id: dialog_e013_outro_a
speaker: narrator
loc_key: dialog.e013.outro.a
text_zh: |
  数字进了脑子，账册回到暗格。你手里没有纸，却有了要挟的影子——你开始像账房里的人了。
next: null

dialog_id: dialog_e013_outro_b
speaker: narrator
loc_key: dialog.e013.outro.b
text_zh: |
  账册贴在怀里发烫。明天商行若搜查，你就是第一个被盯上的人。暗线账权的代价，也开始压到你身上。
next: null

dialog_id: dialog_e013_outro_c
speaker: narrator
loc_key: dialog.e013.outro.c
text_zh: |
  你只带走末页那一行。其余的数，留给以后——如果还有以后。你离“经手哪笔先走”还差一步。
next: null
```
