# 对话 · E004 少爷驾到

> 入口：`dialog_e004_start` · 事件 [`../07_事件档案/主线/E004_少爷驾到.md`](../07_事件档案/主线/E004_少爷驾到.md)

```
dialog_e004_start → dialog_e004_zian → dialog_e004_crowd → dialog_e004_outro
```

```yaml
dialog_id: dialog_e004_start
event_id: E004
speaker: char_qian_demao
loc_key: dialog.e004.start
text_zh: |
  子安从北京来了。往后他在商行帮衬，你们多照顾。
tags: [mainline]
next: dialog_e004_zian

dialog_id: dialog_e004_zian
speaker: char_qian_zian
loc_key: dialog.e004.zian
text_zh: |
  各位师兄多关照。我就是来天津看看的，别的也不懂。
next: dialog_e004_crowd

dialog_id: dialog_e004_crowd
speaker: narrator
loc_key: dialog.e004.crowd
text_zh: |
  伙计们齐声应「是」。有人偷看少爷的靴尖，有人低头理货单。王胖子在你身后轻轻咂舌——北京来的少爷，做派跟跑码头的不一样。
next: dialog_e004_outro

dialog_id: dialog_e004_outro
speaker: narrator
loc_key: dialog.e004.outro
text_zh: |
  钱子安的目光扫过商行，在你脸上停了半息，又滑开，很快失去兴趣。午饭时分，他独自去了街上的茶楼。
effects:
  - { op: set_flag, key: flag_zian_arrived, value: true }
next: null
```
