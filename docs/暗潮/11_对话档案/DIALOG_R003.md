# 对话 · R003 钱子安发难

> 入口：`dialog_r003_start` · 事件 [`../07_事件档案/随机/R003_钱子安发难.md`](../07_事件档案/随机/R003_钱子安发难.md)

```
dialog_r003_start → dialog_r003_zian → dialog_r003_outro → END
```

```yaml
dialog_id: dialog_r003_start
event_id: R003
speaker: narrator
loc_key: dialog.r003.start
text_zh: |
  前堂正忙着，钱子安忽然提高嗓门，指名道姓冲你来。
require:
  - { loc: loc_01 }
  - { edge: {from: char_qian_zian, to: char_lin_ruisheng}, tier_in: [仇隙, 不睦] }
tags: [random]
next: dialog_r003_zian

dialog_id: dialog_r003_zian
speaker: char_qian_zian
loc_key: dialog.r003.zian
text_zh: |
  林瑞生！这几天你跟在我后头转什么？眼里还有没有少爷？当着众人说清楚！
next: dialog_r003_outro

dialog_id: dialog_r003_outro
speaker: narrator
loc_key: dialog.r003.outro
text_zh: |
  你越解释，围观的眼神越怪。少爷甩袖子走了，闲话却留了下来。
effects:
  - { op: add, key: stat_suspicion, value: 10 }
  - { op: add, key: stat_trust_firm, value: -5 }
  - { op: add, edge: {from: char_qian_zian, to: char_lin_ruisheng}, key: score, value: -5 }
  - { op: unlock_grudge, id: grudge_zian_slight }
  - { op: set_flag, key: flag_zian_slight_worsened, value: true }
next: null
```
