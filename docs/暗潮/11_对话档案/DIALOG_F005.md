# 对话 · F005 钱德茂清除

> 入口：`dialog_f005_start` · 事件 [`../07_事件档案/失败/F005_钱德茂清除.md`](../07_事件档案/失败/F005_钱德茂清除.md)  
> 播完即 `end_run`。

```
dialog_f005_start → watch → frame → out → END_RUN
```

```yaml
dialog_id: dialog_f005_start
event_id: F005
speaker: narrator
loc_key: dialog.f005.start
text_zh: |
  东家的疑心已经压不住了。先是盯梢，再是栽赃，最后是一纸「送客」。
require:
  - { edge: {from: char_qian_demao, to: char_lin_ruisheng}, key: suspicion, op: ">=", value: 3 }
tags: [failure, ending]
next: dialog_f005_watch

dialog_id: dialog_f005_watch
speaker: narrator
loc_key: dialog.f005.watch
text_zh: |
  有人夜夜跟在你身后。货栈小屋的门缝外，有新脚印。
next: dialog_f005_frame

dialog_id: dialog_f005_frame
speaker: narrator
loc_key: dialog.f005.frame
text_zh: |
  第二天，账房「丢」了一笔银子。证据齐得像早写好的戏——你的名字写在最上面。
next: dialog_f005_out

dialog_id: dialog_f005_out
speaker: char_qian_demao
loc_key: dialog.f005.out
text_zh: |
  天津卫容不下你了。滚。
effects:
  - { op: set_flag, key: flag_purged, value: true }
  - { op: set_flag, key: flag_ending_fail, value: true }
  - { op: add, edge: {from: char_qian_demao, to: char_lin_ruisheng}, key: score, value: -50 }
  - { op: end_run, reason: purged }
next: null
```
