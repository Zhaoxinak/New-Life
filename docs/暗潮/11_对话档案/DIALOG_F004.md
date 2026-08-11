# 对话 · F004 柳如烟反水

> 入口：`dialog_f004_start` · 事件 [`../07_事件档案/失败/F004_柳如烟反水.md`](../07_事件档案/失败/F004_柳如烟反水.md)

```
dialog_f004_start → dialog_f004_overhear → dialog_f004_zian → dialog_f004_outro
```

```yaml
dialog_id: dialog_f004_start
event_id: F004
speaker: narrator
loc_key: dialog.f004.start
text_zh: |
  你绕过后院廊柱时，听见钱子安的笑声——旁边，是如烟压得很低的声音。
require:
  - { edge: {from: char_liu_ruyan, to: char_lin_ruisheng}, key: score, op: "<=", value: -20 }
  - { meter: pursuit, op: ">=", value: 60 }
tags: [failure]
next: dialog_f004_overhear

dialog_id: dialog_f004_overhear
speaker: narrator
loc_key: dialog.f004.overhear
text_zh: |
  「……是他让我接近您的。他说，打听账上的事……」半句话够了。枕边风翻了面，变成刀子。
next: dialog_f004_zian

dialog_id: dialog_f004_zian
speaker: char_qian_zian
loc_key: dialog.f004.zian
text_zh: |
  （似笑非笑，抬眼望向廊外）林瑞生啊……胆子不小。
next: dialog_f004_outro

dialog_id: dialog_f004_outro
speaker: narrator
loc_key: dialog.f004.outro
text_zh: |
  你退进阴影。商行里的空气变了——像有人把你的名字写进了黑册。
effects:
  - { op: add, key: stat_suspicion, value: 30 }
  - { op: add, edge: {from: char_qian_zian, to: char_lin_ruisheng}, key: score, value: -20 }
  - { op: add, edge: {from: char_liu_ruyan, to: char_lin_ruisheng}, key: score, value: -15 }
  - { op: set_flag, key: flag_liu_betrayed, value: true }
next: null
```
