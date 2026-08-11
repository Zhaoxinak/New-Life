# 对话 · R006 钱庄邀约

> 入口：`dialog_r006_start` · 事件 [`../07_事件档案/随机/R006_钱庄邀约.md`](../07_事件档案/随机/R006_钱庄邀约.md)

```
dialog_r006_start → dialog_r006_clerk → END
```

```yaml
dialog_id: dialog_r006_start
event_id: R006
speaker: narrator
loc_key: dialog.r006.start
text_zh: |
  钱庄掌柜派人送来一张帖子，请你「有空过来一叙」。
require:
  - { loc: loc_04 }
  - { key: stat_money, op: ">=", value: 50 }
tags: [random]
next: dialog_r006_clerk

dialog_id: dialog_r006_clerk
speaker: narrator
loc_key: dialog.r006.clerk
text_zh: |
  「林爷手头宽裕了，票号这边有些高阶往来，可以谈。」对方笑得客气，门也开得更大。
  五十两不算巨富，却已够让钱庄把你从“跑腿小子”看成“能周转的人”。
effects:
  - { op: set_flag, key: flag_bank_tier2, value: true }
next: null
```
