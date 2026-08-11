# 对话 · E020B 聚丰报价

> 入口：`dialog_e020b_start` · 事件 [`../07_事件档案/主线/E020B_聚丰报价.md`](../07_事件档案/主线/E020B_聚丰报价.md)  
> 升职四拍换皮：估价仪式（非钱记前堂）
> 主结算见事件文件；本文件只负责估价仪式演出。

```
dialog_e020b_start → quote → title → crowd → money → window → END
```

```yaml
dialog_id: dialog_e020b_start
event_id: E020B
speaker: narrator
loc_key: dialog.e020b.start
text_zh: |
  茶楼隔间里，赵鸿运把盖碗一推。外面是天津街市的嘈杂，隔门却清静得像在过秤。
tags: [mainline, rank_up, route_b]
next: dialog_e020b_quote

dialog_id: dialog_e020b_quote
speaker: char_zhao_hongyun
loc_key: dialog.e020b.quote
text_zh: |
  林兄弟，我把话说明白。钱记那点月例，养不住你这种人。
  聚丰这边，位子我可以留——跑街的缺，我心里有数。你先把货情、客户口径理一理；理得清，启动的银子和位子，一块给。
next: dialog_e020b_title

dialog_id: dialog_e020b_title
speaker: narrator
loc_key: dialog.e020b.title
text_zh: |
  他不叫你学徒，也不叫你「瑞生」敷衍。他叫的是价码：可投的人。
  这一声，比钱记前堂的「林外场」更冷，也更真——冷在利害，真在你突然被标成资产。
next: dialog_e020b_crowd

dialog_id: dialog_e020b_crowd
speaker: narrator
loc_key: dialog.e020b.crowd
text_zh: |
  隔间外有跑堂经过，眼神往里溜了一下。过不了两日，街市会有人咬耳朵：聚丰在谈钱记那小子。
  闲话比公文快。钱记有人听见了，只会把你看得更紧——或更怕。
next: dialog_e020b_money

dialog_id: dialog_e020b_money
speaker: char_zhao_hongyun
loc_key: dialog.e020b.money
text_zh: |
  先拿一点定金。不是赏你，是订你。订了，就别两边空口吊着。
next: dialog_e020b_window

dialog_id: dialog_e020b_window
speaker: narrator
loc_key: dialog.e020b.window
text_zh: |
  银子入袖，分量不惊人，却把「被报价」变成了摸得着的东西。
  你在钱记或许仍得低头做事；可街面上，你已经不是随便使唤的学徒了。
  有些旧账——尤其那些当众笑你的嘴——也到了可以在市井里讨还的时候。
next: null
```
