# 对话 · R008 伙计私语

> 入口：`dialog_r008_start` · 事件 [`../07_事件档案/随机/R008_伙计私语.md`](../07_事件档案/随机/R008_伙计私语.md)

```
dialog_r008_start → dialog_r008_gossip → END
```

```yaml
dialog_id: dialog_r008_start
event_id: R008
speaker: narrator
loc_key: dialog.r008.start
text_zh: |
  午后闲档，两个伙计在后院压着嗓子扯闲篇，见你走近，犹豫片刻还是把你拉进了话里。
require:
  - { loc: loc_02 }
  - { key: stat_trust_firm, op: ">=", value: 40 }
tags: [random]
next: dialog_r008_gossip

dialog_id: dialog_r008_gossip
speaker: narrator
loc_key: dialog.r008.gossip
text_zh: |
  东家的脾气、少爷的作派、夜里多出来的车——七嘴八舌里，总有一两句能拼进你的账。
effects:
  - { op: add_range, key: stat_intel, min: 2, max: 5 }
next: null
```
