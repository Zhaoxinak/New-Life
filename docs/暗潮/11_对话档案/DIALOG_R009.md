# 对话 · R009 洋行邀约

> 入口：`dialog_r009_start` · 事件 [`../07_事件档案/随机/R009_洋行邀约.md`](../07_事件档案/随机/R009_洋行邀约.md)

```
dialog_r009_start → dialog_r009_bradley → dialog_r009_outro → END
```

```yaml
dialog_id: dialog_r009_start
event_id: R009
speaker: narrator
loc_key: dialog.r009.start
text_zh: |
  一张烫金名片递到你手里——宝顺洋行，白瑞德请你「得空坐坐」。这是层 1：名片开门，先让你被记住。
require:
  - { loc: loc_03 }
  - { meter: impression_bradley, op: ">=", value: 20 }
  - { flag: route_foreign, value: true }
  - { flag: route_foreign_closed, value: false }
tags: [random, foreign]
next: dialog_r009_bradley

dialog_id: dialog_r009_bradley
speaker: char_bradley
loc_key: dialog.r009.bradley
text_zh: |
  林朋友，茶楼说话不方便。宝顺洋行随时欢迎——只谈生意，不谈闲话。先进门，价码才有资格谈。
next: dialog_r009_outro

dialog_id: dialog_r009_outro
speaker: narrator
loc_key: dialog.r009.outro
text_zh: |
  他拱手离去。洋行的门，对你开了一道缝——从此你不是路边客，而是“可能的门路”。
effects:
  - { op: add, edge: {from: char_bradley, to: char_lin_ruisheng}, key: score, value: 5 }
  - { op: set_flag, key: flag_bradley_invite, value: true }
next: null
```
