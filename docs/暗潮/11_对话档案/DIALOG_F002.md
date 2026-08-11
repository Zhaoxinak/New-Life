# 对话 · F002 被降职

> 入口：`dialog_f002_start` · 事件 [`../07_事件档案/失败/F002_被降职.md`](../07_事件档案/失败/F002_被降职.md)

```
dialog_f002_start → dialog_f002_qian → dialog_f002_outro → END
```

```yaml
dialog_id: dialog_f002_start
event_id: F002
speaker: narrator
loc_key: dialog.f002.start
text_zh: |
  前堂众人面前，钱德茂当众点了你的名。
require:
  - { key: stat_suspicion, op: ">=", value: 50 }
  - { key: stat_trust_firm, op: "<=", value: 20 }
tags: [failure]
next: dialog_f002_qian

dialog_id: dialog_f002_qian
speaker: char_qian_demao
loc_key: dialog.f002.qian
text_zh: |
  从今天起，瑞生去做杂役。跑街、管货的事，先放下。月例减半——自己好好想想。
  能不能吃饱饭、还谈不谈得起婚事，就看你还长不长记性。
next: dialog_f002_outro

dialog_id: dialog_f002_outro
speaker: narrator
loc_key: dialog.f002.outro
text_zh: |
  伙计们低头不语。你站在原地，像被当众剥了一层皮。
  这不只是丢脸；从明天起，银钱就会一点点告诉你，什么叫往下掉。
effects:
  - { op: set_flag, key: flag_demoted, value: true }
  - { op: add, edge: {from: char_qian_demao, to: char_lin_ruisheng}, key: score, value: -10 }
next: null
```
