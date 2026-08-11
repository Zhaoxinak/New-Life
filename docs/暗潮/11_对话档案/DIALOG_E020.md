# 对话 · E020 升任外场

> 入口：`dialog_e020_start` · 事件 [`../07_事件档案/主线/E020_升任外场.md`](../07_事件档案/主线/E020_升任外场.md)  
> 演出合同：升职四拍（见 [`表现层边界.md`](../00_总纲/表现层边界.md)）
> 主结算见事件文件；本文件只负责仪式演出。

```
dialog_e020_start → dialog_e020_announce → dialog_e020_title → dialog_e020_crowd → dialog_e020_pay → dialog_e020_window → END
```

```yaml
dialog_id: dialog_e020_start
event_id: E020
speaker: narrator
loc_key: dialog.e020.start
text_zh: |
  前堂的人被叫齐了。算盘声停了一拍。
tags: [mainline, rank_up]
next: dialog_e020_announce

dialog_id: dialog_e020_announce
speaker: char_qian_demao
loc_key: dialog.e020.announce
text_zh: |
  瑞生入行三年，差事稳。从今天起，外场跑差归他先盯着。货单出门、街面上的应答，有事找他。
next: dialog_e020_title

dialog_id: dialog_e020_title
speaker: narrator
loc_key: dialog.e020.title
text_zh: |
  有人低声试了一句：「林外场。」
  像一句玩笑，又像一道门槛——跨过去，称呼就不一样了。
next: dialog_e020_crowd

dialog_id: dialog_e020_crowd
speaker: narrator
loc_key: dialog.e020.crowd
text_zh: |
  王胖子冲你挤眼。原先爱看热闹的几个伙计，目光往别处躲。
  钱子安靠在柱边，笑了笑，笑意不到眼底。
next: dialog_e020_pay

dialog_id: dialog_e020_pay
speaker: char_qian_demao
loc_key: dialog.e020.pay
text_zh: |
  月例按外场规矩加一成。先办好眼前的，别急着跟我谈跑街。
next: dialog_e020_window

dialog_id: dialog_e020_window
speaker: narrator
loc_key: dialog.e020.window
text_zh: |
  散场时你手里多了一点沉甸甸的活钱。更沉的是位子——往后谁再拿你当随意使唤的学徒，得先掂量掂量。
  有些旧账，也到了可以翻开看一眼的时候。
next: null
```
