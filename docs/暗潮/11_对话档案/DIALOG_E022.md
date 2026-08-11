# 对话 · E022 清算子安

> 入口：`dialog_e022_start` · 事件 [`../07_事件档案/主线/E022_清算子安.md`](../07_事件档案/主线/E022_清算子安.md)  
> 主债：`grudge_zian_fiancee`；可并兑 `grudge_zian_slight`
> 分支结算以事件文件为准；本文件只保留清算演出与选择文本。

```
dialog_e022_start → flash → setup → choice (A罚/B恕) → outro
```

```yaml
dialog_id: dialog_e022_start
event_id: E022
speaker: narrator
loc_key: dialog.e022.start
text_zh: |
  父子为着账和脸面闹得前堂人人侧目。你知道——有些话，今天说，才够分量。
tags: [mainline, reckoning]
next: dialog_e022_flash

dialog_id: dialog_e022_flash
speaker: narrator
loc_key: dialog.grudge.zian_fiancee.flash
text_zh: |
  （闪回）赤金镯子摊在桌上。如烟眼圈红着：钱家的势力……我们惹不起。
next: dialog_e022_setup

dialog_id: dialog_e022_setup
speaker: narrator
loc_key: dialog.e022.setup
text_zh: |
  钱德茂在，钱子安在，伙计们装忙。你站在外场的位子上，第一次觉得自己的声音能压过少爷的笑。
next: dialog_e022_choice

dialog_id: dialog_e022_choice
speaker: narrator
loc_key: dialog.e022.choice
text_zh: |
  （婚事这桩债，你怎么收？）
tags: [choice]
choices:
  - id: A
    loc_key: dialog.e022.choice.a
    text_zh: 惩罚——当众钉死定亲，让子安丢脸
    next: dialog_e022_punish
  - id: B
    loc_key: dialog.e022.choice.b
    text_zh: 宽恕——放过他，但钉死如烟是我的人
    next: dialog_e022_forgive

dialog_id: dialog_e022_punish
speaker: char_lin_ruisheng
loc_key: dialog.e022.punish.lin
text_zh: |
  东家明鉴：如烟与我定亲三年。金镯的事，请少爷收回。商行的规矩，不该坏在内宅。
next: dialog_e022_punish_crowd

dialog_id: dialog_e022_punish_crowd
speaker: narrator
loc_key: dialog.e022.punish.crowd
text_zh: |
  前堂静得能听见算盘珠子。钱德茂眉头一跳。钱子安想笑，笑不出来——他看见伙计们的眼神已经站到你这边。
  婚事主动权，这一刻从钱家礼单上，回到了你嘴里。
next: null

dialog_id: dialog_e022_forgive
speaker: char_lin_ruisheng
loc_key: dialog.e022.forgive.lin
text_zh: |
  少爷看上的人，是我的定亲。这事，我记着。今日我不多说——只请东家一句：商行不夺人姻缘。
next: dialog_e022_forgive_crowd

dialog_id: dialog_e022_forgive_crowd
speaker: narrator
loc_key: dialog.e022.forgive.crowd
text_zh: |
  你本可以把少爷撕开。你没有。你只把话说死，把刀收回鞘里。
  钱德茂看你的眼神复杂；子安的恨意更深——可看客敬的是「能收住」的人。
next: null
```
