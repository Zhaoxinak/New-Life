# 对话 · R005 聚丰行接触

> 入口：`dialog_r005_start` · 事件 [`../07_事件档案/随机/R005_聚丰行接触.md`](../07_事件档案/随机/R005_聚丰行接触.md)

```
dialog_r005_start → dialog_r005_zhao → dialog_r005_outro → END
```

```yaml
dialog_id: dialog_r005_start
event_id: R005
speaker: narrator
loc_key: dialog.r005.start
text_zh: |
  茶楼雅座里，有人斟了杯热茶推过来——聚丰行的赵鸿运。
require:
  - { loc: loc_03 }
  - { key: stat_network, op: ">=", value: 20 }
tags: [random, defect]
next: dialog_r005_zhao

dialog_id: dialog_r005_zhao
speaker: char_zhao_hongyun
loc_key: dialog.r005.zhao
text_zh: |
  林兄弟，听说钱记近来不太平。有本事的人，不必吊死在一棵树上。哪天想换个地方做事，来找我。
  只要你手里真有货情、有人路，位子和月钱都好谈；空着手，我这儿连热茶都不白续。
next: dialog_r005_outro

dialog_id: dialog_r005_outro
speaker: narrator
loc_key: dialog.r005.outro
text_zh: |
  他留下一张名片便起身。跳槽的门缝，从这一刻起，微微开了。
  赵鸿运不是在交朋友，是在先给你报一个价。
effects:
  - { op: add, edge: {from: char_zhao_hongyun, to: char_lin_ruisheng}, key: score, value: 10 }
  - { op: set_flag, key: flag_zhao_contacted, value: true }
next: null
```
