# 对话 · E020C 洋行门路

> 入口：`dialog_e020c_start` · 事件 [`../07_事件档案/主线/E020C_洋行门路.md`](../07_事件档案/主线/E020C_洋行门路.md)  
> 升职四拍换皮：门路确认（非月例任命）
> 主结算见事件文件；本文件只负责门路确认演出。

```
dialog_e020c_start → admit → title → crowd → gift → window → END
```

```yaml
dialog_id: dialog_e020c_start
event_id: E020C
speaker: narrator
loc_key: dialog.e020c.start
text_zh: |
  宝顺洋行会客室里，红茶烫着。窗外是租界的车马，与华界的喧闹隔着一道看不见的槛。
tags: [mainline, rank_up, route_c]
require:
  - { loc: loc_05 }
next: dialog_e020c_admit

dialog_id: dialog_e020c_admit
speaker: char_bradley
loc_key: dialog.e020c.admit
text_zh: |
  林朋友，我记住你了。天津的门路，我见过许多——大多只会笑，不会办事。
  你若还能再来，我们谈的就不是寒暄。名片之后，是资格。
next: dialog_e020c_title

dialog_id: dialog_e020c_title
speaker: narrator
loc_key: dialog.e020c.title
text_zh: |
  「林朋友」三个字，被他用洋腔钉在桌上。
  不是东家赐的职称，是另一套天——洋行开始把你写进可往来的人名里。
next: dialog_e020c_crowd

dialog_id: dialog_e020c_crowd
speaker: narrator
loc_key: dialog.e020c.crowd
text_zh: |
  出门时，买办房有人打量你的靴。华界那边若有人看见你从洋行台阶下来，闲话会先于你回到钱记：这人有洋人的路子。
next: dialog_e020c_gift

dialog_id: dialog_e020c_gift
speaker: char_bradley
loc_key: dialog.e020c.gift
text_zh: |
  一点车马。不成敬意——分成的事，等你真能把路走通再谈。
next: dialog_e020c_window

dialog_id: dialog_e020c_window
speaker: narrator
loc_key: dialog.e020c.window
text_zh: |
  银子薄，门路厚。你清楚：今日拿到的不是身家，是下一张椅子的入场券。
  回到前堂，有人再拿话刺你时——你可以选择借这股「势」轻轻压回去。旧账，未必非在钱记的屋檐下讨。
next: null
```
