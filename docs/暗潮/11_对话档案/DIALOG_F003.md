# 对话 · F003 被开除

> 入口：`dialog_f003_start` · 事件 [`../07_事件档案/失败/F003_被开除.md`](../07_事件档案/失败/F003_被开除.md)  
> 播完即 `end_run`（失败终局）。

```
dialog_f003_start → dialog_f003_qian → dialog_f003_outro → END_RUN
```

```yaml
dialog_id: dialog_f003_start
event_id: F003
speaker: narrator
loc_key: dialog.f003.start
text_zh: |
  钱德茂把你的铺盖卷扔到前堂门外。伙计们低头让路，没人敢接你的目光。
require:
  - { key: stat_suspicion, op: ">=", value: 70 }
tags: [failure, ending]
next: dialog_f003_qian

dialog_id: dialog_f003_qian
speaker: char_qian_demao
loc_key: dialog.f003.qian
text_zh: |
  钱记商行，容不下你这种人。走吧。天津卫大得很——别让我再看见你在附近转。
next: dialog_f003_outro

dialog_id: dialog_f003_outro
speaker: narrator
loc_key: dialog.f003.outro
text_zh: |
  隐忍线断了。朱红大门在身后合上，合得很死。
  你兜里那点散碎银子，撑不了几天；从今往后，吃饭、住店、抬头见人，都得另算。
effects:
  - { op: set_flag, key: flag_fired, value: true }
  - { op: set_flag, key: route_endure_failed, value: true }
  - { op: set_flag, key: flag_ending_fail, value: true }
  - { op: add, edge: {from: char_qian_demao, to: char_lin_ruisheng}, key: score, value: -40 }
  - { op: end_run, reason: fired }
next: null
```
