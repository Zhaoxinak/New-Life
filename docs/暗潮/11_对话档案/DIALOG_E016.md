# 对话 · E016 挑拨父子

> 入口：`dialog_e016_start` · 事件 [`../07_事件档案/主线/E016_挑拨父子.md`](../07_事件档案/主线/E016_挑拨父子.md)  
> 同事件内两招可选其一（枕边风需 `pursuit≥40`）。

---

## 节点图

```
dialog_e016_start
  → dialog_e016_choice
       ├─ A 传话三万两 → dialog_e016_a_* → outro_a
       └─ B 枕边风 (pursuit≥40) → dialog_e016_b_* → outro_b
```

---

## Nodes

```yaml
dialog_id: dialog_e016_start
event_id: E016
speaker: narrator
loc_key: dialog.e016.start
text_zh: |
  林瑞生开始利用收集到的情报，在钱氏父子之间制造裂痕。你知道：这不是闹脾气，是在给“层 5：暗线入口”拆门。
require:
  - { key: stat_intel, op: ">=", value: 35 }
  - { meter: father_son, op: "<=", value: 45 }
tags: [mainline]
next: dialog_e016_choice

dialog_id: dialog_e016_choice
event_id: E016
speaker: narrator
loc_key: dialog.e016.choice_prompt
text_zh: |
  （你下手的方式？）
tags: [mainline, choice]
choices:
  - id: A
    loc_key: dialog.e016.choice.a
    text_zh: 向钱子安「无意」提起往北京汇的三万两
    next: dialog_e016_a_lin
  - id: B
    loc_key: dialog.e016.choice.b
    text_zh: 让柳如烟吹枕边风（需 pursuit≥40）
    require:
      - { meter: pursuit, op: ">=", value: 40 }
    next: dialog_e016_b_liu
```

### 分支 A · 三万两

```yaml
dialog_id: dialog_e016_a_lin
speaker: char_lin_ruisheng
loc_key: dialog.e016.a.lin
text_zh: |
  少爷，今天账房来了一笔汇款单子。东家往北京汇了三万两。
next: dialog_e016_a_zian

dialog_id: dialog_e016_a_zian
speaker: char_qian_zian
loc_key: dialog.e016.a.zian
text_zh: |
  三万两？他给我一个月的月例才多少？二十两！
next: dialog_e016_a_lin2

dialog_id: dialog_e016_a_lin2
speaker: char_lin_ruisheng
loc_key: dialog.e016.a.lin2
text_zh: |
  少爷，这话我不该说的。可您是东家独子，这商行迟早……
next: dialog_e016_a_zian2

dialog_id: dialog_e016_a_zian2
speaker: char_qian_zian
loc_key: dialog.e016.a.zian2
text_zh: |
  他钱德茂嘴上说让我历练，实际上把我扔在天津，自己把银子往北京搬！
effects:
  - { op: add, meter: father_son, value: -15 }
  - { op: add, edge: {from: char_qian_zian, to: char_qian_demao}, key: score, value: -10 }
next: dialog_e016_outro_a

dialog_id: dialog_e016_outro_a
speaker: narrator
loc_key: dialog.e016.outro.a
text_zh: |
  少爷拍桌的声音，隔着木门都能听见。父子之间，又裂开一道口子——足够你伸手进暗处一寸。
next: null
```

### 分支 B · 枕边风

```yaml
dialog_id: dialog_e016_b_liu
speaker: char_liu_ruyan
loc_key: dialog.e016.b.liu
text_zh: |
  少爷，我听厂里姐妹说……东家最近好像不打算让您管账上的事。
next: dialog_e016_b_zian

dialog_id: dialog_e016_b_zian
speaker: char_qian_zian
loc_key: dialog.e016.b.zian
text_zh: |
  他连账都不让我碰？
next: dialog_e016_b_liu2

dialog_id: dialog_e016_b_liu2
speaker: char_liu_ruyan
loc_key: dialog.e016.b.liu2
text_zh: |
  我……我也是听人说的。
effects:
  - { op: add, meter: father_son, value: -20 }
  - { op: add, edge: {from: char_qian_zian, to: char_liu_ruyan}, key: suspicion, value: 1 }
  - { op: add, meter: liu_source_risk, value: 10 }
next: dialog_e016_outro_b

dialog_id: dialog_e016_outro_b
speaker: narrator
loc_key: dialog.e016.outro.b
text_zh: |
  裂痕更深了。可钱子安不是傻子——他开始打量消息从哪儿来。暗线入口就在眼前，也就更危险。
next: null
```
