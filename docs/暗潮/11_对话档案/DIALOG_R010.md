# 对话 · R010 看客起哄

> 入口：`dialog_r010_start` · 事件 [`../07_事件档案/随机/R010_看客起哄.md`](../07_事件档案/随机/R010_看客起哄.md)

```
dialog_r010_start → dialog_r010_crowd → dialog_r010_outro → END
```

```yaml
dialog_id: dialog_r010_start
event_id: R010
speaker: narrator
loc_key: dialog.r010.start
text_zh: |
  你刚被少爷差去跑腿，回来时前堂有人故意抬高嗓门。
require:
  - { loc: loc_01 }
  - { flag: flag_zian_arrived, value: true }
tags: [random]
next: dialog_r010_crowd

dialog_id: dialog_r010_crowd
speaker: narrator
loc_key: dialog.r010.crowd
text_zh: |
  「哟，林师兄，这回跟得可紧——少爷靴尖都亮了。」
  几个人笑。笑声不大，刚好够你听见，也刚好够装成无心。
next: dialog_r010_outro

dialog_id: dialog_r010_outro
speaker: narrator
loc_key: dialog.r010.outro
text_zh: |
  你没接话。那笑却进了账——不是银钱账，是人账。
effects:
  - { op: unlock_grudge, id: grudge_onlooker }
  - { op: add, key: stat_suspicion, value: 3 }
  - { op: add, edge: {from: char_lin_ruisheng, to: char_zhou_guanshi}, key: score, value: -5 }
next: null
```
