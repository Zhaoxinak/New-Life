# 对话 · E021B 轻清算（街市）

> 入口：`dialog_e021b_start` · [`E021B_轻清算_街市.md`](../07_事件档案/主线/E021B_轻清算_街市.md)
> 分支结算以事件文件为准；本文件只保留街市路由、分支选择和演出文本。

```
dialog_e021b_start → next_by_condition (onlooker|slight|skip)
```

```yaml
dialog_id: dialog_e021b_start
event_id: E021B
speaker: narrator
loc_key: dialog.e021b.start
text_zh: |
  茶楼外的风里，已经有人把「聚丰在谈他」五个字咬热了。
  旧账若要讨，市井比前堂更适合——围观的人多，丢脸也丢脸得响。
tags: [mainline, reckoning, route_b]
next_by_condition:
  - id: onlooker
    require: [{ grudge: grudge_onlooker, status: open }]
    next: dialog_e021b_flash_onlooker
  - id: slight
    require: [{ grudge: grudge_zian_slight, status: open }]
    next: dialog_e021b_flash_slight
  - id: none
    next: dialog_e021b_skip

dialog_id: dialog_e021b_skip
speaker: narrator
loc_key: dialog.e021b.skip
text_zh: |
  闲话有了，账目却还没到期。你把袖口放下。
next: null

dialog_id: dialog_e021b_flash_onlooker
speaker: narrator
loc_key: dialog.grudge.onlooker.flash
text_zh: |
  （闪回）他们笑你跟在少爷靴后跟。
next: dialog_e021b_onlooker_choice

dialog_id: dialog_e021b_onlooker_choice
speaker: narrator
loc_key: dialog.e021b.onlooker.choice
text_zh: |
  那几张熟脸又在茶桌边起哄。有人看见你，笑意僵了半拍——像忽然想起聚丰的名字。
tags: [choice]
choices:
  - id: A
    text_zh: 惩罚——当众揭他们势利，让闲话反过来咬人
    loc_key: dialog.e021b.onlooker.a
    next: dialog_e021b_onlooker_punish
  - id: B
    text_zh: 宽恕——点破又收手，收他们当耳目
    loc_key: dialog.e021b.onlooker.b
    next: dialog_e021b_onlooker_forgive

dialog_id: dialog_e021b_onlooker_punish
speaker: narrator
loc_key: dialog.e021b.onlooker.punish
text_zh: |
  你把话放在明处：笑人跟靴的时候，怎不想想自己会不会变成别人嘴里的笑话。
  茶桌一静。有人起身溜了。街市的敬，常常从怕开始。
next: null

dialog_id: dialog_e021b_onlooker_forgive
speaker: narrator
loc_key: dialog.e021b.onlooker.forgive
text_zh: |
  你本可以让他们在茶客面前抬不起头。你只淡淡道：嘴严点，往后有你们听的。
  他们诺诺。市井里，被放过的人比被踩的人更肯递话。
next: null

dialog_id: dialog_e021b_flash_slight
speaker: narrator
loc_key: dialog.grudge.zian_slight.flash
text_zh: |
  （闪回）他的目光滑开，像扫过一件不值钱的货。
next: dialog_e021b_slight_choice

dialog_id: dialog_e021b_slight_choice
speaker: narrator
loc_key: dialog.e021b.slight.choice
text_zh: |
  钱子安今日也在街市晃。有人起哄让他「管管」你——你站着，像已经不属于他管的人。
tags: [choice]
choices:
  - id: A
    text_zh: 惩罚——当众把客户口径说准，让他脸挂不住
    loc_key: dialog.e021b.slight.a
    next: dialog_e021b_slight_punish
  - id: B
    text_zh: 宽恕——压着他，给台阶下
    loc_key: dialog.e021b.slight.b
    next: dialog_e021b_slight_forgive

dialog_id: dialog_e021b_slight_punish
speaker: narrator
loc_key: dialog.e021b.slight.punish
text_zh: |
  你报出一串他答不上的数。看客的笑转向他。少爷耳根发青，丢下一句「有意思」走了。
next: null

dialog_id: dialog_e021b_slight_forgive
speaker: narrator
loc_key: dialog.e021b.slight.forgive
text_zh: |
  你止住伙计的起哄，替他把台阶铺好。他看你的眼神像恨，又像第一次承认你在市面上「值个价」。
next: null
```
