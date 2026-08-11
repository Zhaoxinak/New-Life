# 对话 · R007 被监视

> 入口：`dialog_r007_start` · 事件 [`../07_事件档案/随机/R007_被监视.md`](../07_事件档案/随机/R007_被监视.md)

```
dialog_r007_start → dialog_r007_feel → END
```

```yaml
dialog_id: dialog_r007_start
event_id: R007
speaker: narrator
loc_key: dialog.r007.start
text_zh: |
  你走到哪儿，背后总像跟了双眼睛。伙计的目光躲闪，拐角处有人假装整理货单。
require:
  - { loc: loc_02 }
  - { edge: {from: char_qian_demao, to: char_lin_ruisheng}, key: suspicion, op: ">=", value: 2  # 高 }
tags: [random, pressure]
next: dialog_r007_feel

dialog_id: dialog_r007_feel
speaker: narrator
loc_key: dialog.r007.feel
text_zh: |
  东家疑心重了。今日再动歪心思，失手的可能大得多。
effects:
  - { op: set_temp, key: plot_success_mod, value: -0.30 }
next: null
```
