# 对话 · F001 被敲打

> 入口：`dialog_f001_start` · 事件 [`../07_事件档案/失败/F001_被敲打.md`](../07_事件档案/失败/F001_被敲打.md)

```
dialog_f001_start → dialog_f001_qian → dialog_f001_outro → END
```

```yaml
dialog_id: dialog_f001_start
event_id: F001
speaker: narrator
loc_key: dialog.f001.start
text_zh: |
  钱德茂把你叫进账房，把门关上。桌上的茶凉了，他却不急着喝。
require:
  - { key: stat_suspicion, op: ">=", value: 30 }
tags: [failure]
next: dialog_f001_qian

dialog_id: dialog_f001_qian
speaker: char_qian_demao
loc_key: dialog.f001.qian
text_zh: |
  瑞生，我待你不薄。有些事，看见了当没看见。听见了当没听见。再不安分，这商行容不下你。
next: dialog_f001_outro

dialog_id: dialog_f001_outro
speaker: narrator
loc_key: dialog.f001.outro
text_zh: |
  他挥了挥手让你出去。警告已经落下，下一次就不会只是谈话。
effects:
  - { op: add, edge: {from: char_qian_demao, to: char_lin_ruisheng}, key: score, value: -5 }
next: null
```
