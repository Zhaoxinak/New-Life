# 对话 · E022C 清算子安（借势）

> 入口：`dialog_e022c_start` · [`E022C_清算子安_借势.md`](../07_事件档案/主线/E022C_清算子安_借势.md)
> 分支结算以事件文件为准；本文件只保留借势清算演出与选择文本。

```
dialog_e022c_start → flash → setup → choice → outro
```

```yaml
dialog_id: dialog_e022c_start
event_id: E022C
speaker: narrator
loc_key: dialog.e022c.start
text_zh: |
  洋行的门、庆系的手书、钱记的前堂，原本不该落在一条线上。
  可你今天偏要借那条线，去勒住钱子安的气。
tags: [mainline, reckoning, route_c]
next: dialog_e022c_flash

dialog_id: dialog_e022c_flash
speaker: narrator
loc_key: dialog.grudge.zian_fiancee.flash
text_zh: |
  （闪回）赤金镯子压得如烟指尖发白。钱家的礼，像是拿势和活路一并压在她身上。
next: dialog_e022c_setup

dialog_id: dialog_e022c_setup
speaker: narrator
loc_key: dialog.e022c.setup
text_zh: |
  钱子安以为自己还占着少爷的位子。可你今日背后，不只是一间前堂。
  看客分不清你到底借了谁的势，只看得出：你比从前更不好惹。
next: dialog_e022c_choice

dialog_id: dialog_e022c_choice
speaker: narrator
loc_key: dialog.e022c.choice
text_zh: |
  （这桩婚事债，你怎么用「势」来收？）
tags: [choice]
choices:
  - id: A
    loc_key: dialog.e022c.choice.a
    text_zh: 惩罚——借外头的势压场，让子安当众失语
    next: dialog_e022c_punish
  - id: B
    loc_key: dialog.e022c.choice.b
    text_zh: 宽恕——亮势收刀，把婚事拿回来就够
    next: dialog_e022c_forgive

dialog_id: dialog_e022c_punish
speaker: narrator
loc_key: dialog.e022c.punish
text_zh: |
  你没有把洋人的名字说满，只让前堂听懂半句。半句就够了。钱子安的火一下矮了，像被什么看不见的手按住。
  这胜仗脏，却真。婚事的主动权，也就在这脏里被你硬生生夺了回来。
next: null

dialog_id: dialog_e022c_forgive
speaker: narrator
loc_key: dialog.e022c.forgive
text_zh: |
  你让所有人都看见自己有本事把场面掀翻，却只拿回该拿的那一份。
  钱子安保住了面皮，丢掉的却是心气。旁人也会明白：你如今能借势，却未必滥用势。
next: null
```
