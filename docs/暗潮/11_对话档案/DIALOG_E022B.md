# 对话 · E022B 清算子安（截胡）

> 入口：`dialog_e022b_start` · [`E022B_清算子安_截胡.md`](../07_事件档案/主线/E022B_清算子安_截胡.md)
> 分支结算以事件文件为准；本文件只保留街面清算演出与选择文本。

```
dialog_e022b_start → flash → setup → choice → outro
```

```yaml
dialog_id: dialog_e022b_start
event_id: E022B
speaker: narrator
loc_key: dialog.e022b.start
text_zh: |
  街面上的风先闻见了火药味。聚丰盯着钱记那单货，钱子安也在找能挽回脸面的机会。
  你知道：今天若把话挑明，丢的就不只是脸，还有买卖。
tags: [mainline, reckoning, route_b]
next: dialog_e022b_flash

dialog_id: dialog_e022b_flash
speaker: narrator
loc_key: dialog.grudge.zian_fiancee.flash
text_zh: |
  （闪回）赤金镯子压在桌上。如烟低声说：收了像认了，退了，他们一句话，厂里都未必还有我站脚的地方。
next: dialog_e022b_setup

dialog_id: dialog_e022b_setup
speaker: narrator
loc_key: dialog.e022b.setup
text_zh: |
  钱子安想拿这单生意压你一头。街面上的看客却更愿意看谁能把价、把人、把脸一起拿住。
  你站在路中间，第一次像个能决定单子往哪边走的人。
next: dialog_e022b_choice

dialog_id: dialog_e022b_choice
speaker: narrator
loc_key: dialog.e022b.choice
text_zh: |
  （婚事这桩债，你怎么在街面上收？）
tags: [choice]
choices:
  - id: A
    loc_key: dialog.e022b.choice.a
    text_zh: 惩罚——借着截胡，把子安的脸和话一起掀翻
    next: dialog_e022b_punish
  - id: B
    loc_key: dialog.e022b.choice.b
    text_zh: 宽恕——给他留一句场面话，但把婚事钉死
    next: dialog_e022b_forgive

dialog_id: dialog_e022b_punish
speaker: narrator
loc_key: dialog.e022b.punish
text_zh: |
  你把货价、婚事、少爷先前的荒唐话一并摊在街面上。看客先是愣，随即倒向能办成事的一边。
  钱子安想发作，嘴却快不过人群里的窃笑。今天丢的，不只是他的脸，还有这单买卖的话头。
next: null

dialog_id: dialog_e022b_forgive
speaker: narrator
loc_key: dialog.e022b.forgive
text_zh: |
  你把最狠的话咽回去，只留一句：买卖归买卖，姻缘归姻缘。少爷若懂规矩，彼此都省脸。
  你给了他台阶，却把如烟的名字牢牢按回自己这边。街面上的人会记住：你能截单，也能收刀。
next: null
```
