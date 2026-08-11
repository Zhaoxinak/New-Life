# 对话 · R001 茶楼消息

> 入口：`dialog_r001_start` · 事件 [`../07_事件档案/随机/R001_茶楼消息.md`](../07_事件档案/随机/R001_茶楼消息.md)

```
dialog_r001_start → dialog_r001_pay → END
```

```yaml
dialog_id: dialog_r001_start
event_id: R001
speaker: narrator
loc_key: dialog.r001.start
text_zh: |
  茶楼角落里，一个跑码头的消息通拍了拍桌子：「林师兄，喝茶？有点新鲜的。」
require:
  - { loc: loc_03 }
  - { slot: evening }
  - { key: stat_money, op: ">=", value: 5 }
tags: [random]
next: dialog_r001_pay

dialog_id: dialog_r001_pay
speaker: narrator
loc_key: dialog.r001.pay
text_zh: |
  五两银子换来几句半真半假的街谈巷议。平日五两够你和如烟省吃俭用好几天，如今却只换来几句门道。
  你挑着听，心里记下几处能对上号的，也记下了：这世上消息跟银子一样，越急越贵。
effects:
  - { op: add, key: stat_money, value: -5 }
  - { op: add_range, key: stat_intel, min: 3, max: 8 }
next: null
```
