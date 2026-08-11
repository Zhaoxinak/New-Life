# 对话 · E021C 轻清算（借势）

> 入口：`dialog_e021c_start` · [`E021C_轻清算_借势.md`](../07_事件档案/主线/E021C_轻清算_借势.md)
> 分支结算以事件文件为准；本文件只保留借势路由、分支选择和演出文本。

```yaml
dialog_id: dialog_e021c_start
event_id: E021C
speaker: narrator
loc_key: dialog.e021c.start
text_zh: |
  从洋行台阶下来的人，靴底还带着另一边的尘。前堂若再有闲话，你可以选择——借那股势，轻轻压回去。
tags: [mainline, reckoning, route_c]
next_by_condition:
  - id: onlooker
    require: [{ grudge: grudge_onlooker, status: open }]
    next: dialog_e021c_flash_onlooker
  - id: slight
    require: [{ grudge: grudge_zian_slight, status: open }]
    next: dialog_e021c_flash_slight
  - id: none
    next: dialog_e021c_skip

dialog_id: dialog_e021c_skip
speaker: narrator
loc_key: dialog.e021c.skip
text_zh: |
  势在袖里，你按住不用。
next: null

dialog_id: dialog_e021c_flash_onlooker
speaker: narrator
loc_key: dialog.grudge.onlooker.flash
text_zh: |
  （闪回）他们笑你跟靴。
next: dialog_e021c_onlooker_choice

dialog_id: dialog_e021c_onlooker_choice
speaker: narrator
loc_key: dialog.e021c.onlooker.choice
text_zh: |
  闲话又起。有人瞥见你袖里那点「洋行的气味」，嗓门矮了。
tags: [choice]
choices:
  - id: A
    text_zh: 惩罚——点破靠山，让他们当众塌脸
    loc_key: dialog.e021c.onlooker.a
    next: dialog_e021c_onlooker_punish
  - id: B
    text_zh: 宽恕——亮势又收，收为耳目
    loc_key: dialog.e021c.onlooker.b
    next: dialog_e021c_onlooker_forgive

dialog_id: dialog_e021c_onlooker_punish
speaker: narrator
loc_key: dialog.e021c.onlooker.punish
text_zh: |
  你不必报洋人的名。只需一句「有些路，不是你们配打听的」。笑声死在喉咙里。
  怕，比敬来得快；嫌疑，也会跟着长一点。
next: null

dialog_id: dialog_e021c_onlooker_forgive
speaker: narrator
loc_key: dialog.e021c.onlooker.forgive
text_zh: |
  你让他们看见刀，又把刀收回鞘。留下一句：嘴严，有你们的好处。
  他们懂——这不是慈悲，是收编。
next: null

dialog_id: dialog_e021c_flash_slight
speaker: narrator
loc_key: dialog.grudge.zian_slight.flash
text_zh: |
  （闪回）目光滑开。
next: dialog_e021c_slight_choice

dialog_id: dialog_e021c_slight_choice
speaker: narrator
loc_key: dialog.e021c.slight.choice
text_zh: |
  钱子安又要当众拿你垫话。你站得很稳——像背后有一扇他推不开的门。
tags: [choice]
choices:
  - id: A
    text_zh: 惩罚——借势顶回去，让他当场失语
    loc_key: dialog.e021c.slight.a
    next: dialog_e021c_slight_punish
  - id: B
    text_zh: 宽恕——压住场面，给他留脸
    loc_key: dialog.e021c.slight.b
    next: dialog_e021c_slight_forgive

dialog_id: dialog_e021c_slight_punish
speaker: narrator
loc_key: dialog.e021c.slight.punish
text_zh: |
  「少爷若有事，不妨托人去洋行那边问一声。」你把话说得极轻，他却像被烫到。
  看客倒抽凉气。这胜仗脏一点，也爽一点。
next: null

dialog_id: dialog_e021c_slight_forgive
speaker: narrator
loc_key: dialog.e021c.slight.forgive
text_zh: |
  你止住自己更脏的半句，只道：今日不争这个。
  他保住了脸，却知道脸是你恩准留下的。
next: null
```
