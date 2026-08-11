# 对话 · E015 真相大白

> 入口：`dialog_e015_start` · 事件 [`../07_事件档案/主线/E015_真相大白.md`](../07_事件档案/主线/E015_真相大白.md)  
> 选项 A → [`item_opium_sample`](../12_信物与把柄/ITEM_鸦片样品.md)

---

## 节点图

```
dialog_e015_start
  → dialog_e015_open
  → dialog_e015_know
  → dialog_e015_legal
  → dialog_e015_smuggle
  → dialog_e015_puzzle
  → dialog_e015_weight
  → dialog_e015_choice
       ├─ A → outro_a
       ├─ B → outro_b
       └─ C → outro_c
```

---

## Nodes

```yaml
dialog_id: dialog_e015_start
event_id: E015
speaker: narrator
loc_key: dialog.e015.start
text_zh: |
  林瑞生找到机会，在库房深处一个上了锁的暗箱前停下。他从师兄王胖子那里套到了钥匙的位置。
require:
  - { key: stat_intel, op: ">=", value: 40 }
  - { clue: clue_special_goods, owned: true }
  - any:
      - { edge: {from: char_wang_pangzi, to: char_lin_ruisheng}, key: score, op: ">=", value: 40 }
      - { key: stat_network, op: ">=", value: 30 }
tags: [mainline, opium_arc]
next: dialog_e015_open

dialog_id: dialog_e015_open
speaker: narrator
loc_key: dialog.e015.open
text_zh: |
  打开暗箱，里面是油纸包裹的黑色膏状物——整整齐齐码了半箱。林瑞生见过烟馆门口那些鬼鬼祟祟的人，闻过那种甜腻的焦味。
next: dialog_e015_know

dialog_id: dialog_e015_know
speaker: narrator
loc_key: dialog.e015.know
text_zh: |
  他知道这是什么了。

  洋药。鸦片。
next: dialog_e015_legal

dialog_id: dialog_e015_legal
speaker: narrator
loc_key: dialog.e015.legal
text_zh: |
  但林瑞生在码头混了三年，他知道鸦片生意本身不违法——洋药完了税，凭单运销内地，正经买卖人做得，天津港的洋行天天走。钱记商行若是正大光明做鸦片买卖，也没什么了不起。
next: dialog_e015_smuggle

dialog_id: dialog_e015_smuggle
speaker: narrator
loc_key: dialog.e015.smuggle
text_zh: |
  可钱记商行不是正大光明的。木材货单上写的是「南洋木器」，海关报关单上没有这批货的名字。这些鸦片没有走过海关，没有交过一百一十两的税。它们从暗道入库，半夜卸货，东家亲自盯着。
next: dialog_e015_puzzle

dialog_id: dialog_e015_puzzle
speaker: narrator
loc_key: dialog.e015.puzzle
text_zh: |
  加上账房密账里记的「特别货」——进价八十两、售价三百两的暴利——和末页那个「庆大人·月奉」。

  林瑞生终于拼完了这幅拼图：钱记商行的鸦片走两条线。一条走海关、完税、有凭单——合法，但瞒着股东和伙计；另一条绕关走私、零税入货——纯违法，利润全送去北京。合法的那条给商行撑门面，违法的那条才是真正的暴利来源。
  一箱八十两，转手三百两。跑街月例多那二两、如烟一针一线攒的嫁妆、王胖子一年酒钱，在这半箱黑膏面前都像笑话。
next: dialog_e015_weight

dialog_id: dialog_e015_weight
speaker: narrator
loc_key: dialog.e015.weight
text_zh: |
  东家表面是个精明的木材商人，暗地里是个逃税走私犯，更深处还是京中高官的暗钱通道。

  那一刻，林瑞生心里的复仇，不再只是为了一个被抢走的未婚妻和一份被搁置的升职。他忽然明白：自己这些年低头苦熬，为的是几两月例；而钱家在夜里搬的，是能换掉一个人一辈子的银子。
  他手里捏着的东西，比他自己想象的要大得多。
next: dialog_e015_choice

dialog_id: dialog_e015_choice
event_id: E015
speaker: narrator
loc_key: dialog.e015.choice_prompt
text_zh: |
  （你怎么做？）
tags: [mainline, choice]
choices:
  - id: A
    loc_key: dialog.e015.choice.a
    text_zh: 拿一小块样品，放回暗箱
    effects:
      - { op: add, key: stat_intel, value: 30 }
      - { op: add, key: stat_suspicion, value: 10 }
      - { op: unlock_clue, id: clue_opium_secret }
      - { op: grant_item, id: item_opium_sample }
    next: dialog_e015_outro_a
  - id: B
    loc_key: dialog.e015.choice.b
    text_zh: 不动暗箱，靠已有信息推断
    effects:
      - { op: add, key: stat_intel, value: 15 }
      - { op: unlock_clue, id: clue_opium_infer }
    next: dialog_e015_outro_b
  - id: C
    loc_key: dialog.e015.choice.c
    text_zh: 拿走大量鸦片，转手卖钱
    effects:
      - { op: add, key: stat_money, value: 100 }
      - { op: add, key: stat_intel, value: 10 }
      - { op: add, key: stat_suspicion, value: 40 }
      - { op: unlock_clue, id: clue_opium_infer }
    next: dialog_e015_outro_c
```

### Outros

```yaml
dialog_id: dialog_e015_outro_a
speaker: narrator
loc_key: dialog.e015.outro.a
text_zh: |
  一小块膏体贴身藏好。货单、暗道、密账、实物——证据链齐了。
next: null

dialog_id: dialog_e015_outro_b
speaker: narrator
loc_key: dialog.e015.outro.b
text_zh: |
  你合上暗箱。脑子里的拼图已经够用；只是少一块实物，要挟时会软一分。
next: null

dialog_id: dialog_e015_outro_c
speaker: narrator
loc_key: dialog.e015.outro.c
text_zh: |
  银子烫手。你头一回真把这条黑钱路掰了一块塞进自己怀里。
  若是东家查库，你连退路都没有；若查不出，你往后再看那些月例和赏钱，只会更嫌它们寒酸。
next: null
```
