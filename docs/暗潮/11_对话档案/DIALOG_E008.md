# 对话 · E008 纳妾风波

> 入口：`dialog_e008_start` · 事件 [`../07_事件档案/主线/E008_纳妾风波.md`](../07_事件档案/主线/E008_纳妾风波.md)

---

## 节点图

```
dialog_e008_start
  → dialog_e008_lin_ask
  → dialog_e008_liu_show
  → dialog_e008_lin_shock
  → dialog_e008_liu_explain
  → dialog_e008_lin_rage
  → dialog_e008_liu_fear
  → dialog_e008_choice
       ├─ A → outro_a
       ├─ B → outro_b
       └─ C → outro_c
```

---

## Nodes

```yaml
dialog_id: dialog_e008_start
event_id: E008
speaker: narrator
loc_key: dialog.e008.start
text_zh: |
  柳如烟眼圈红着，进门就坐下，不说话。
tags: [mainline]
next: dialog_e008_lin_ask

dialog_id: dialog_e008_lin_ask
speaker: char_lin_ruisheng
loc_key: dialog.e008.lin_ask
text_zh: |
  怎么了？
next: dialog_e008_liu_show

dialog_id: dialog_e008_liu_show
speaker: narrator
loc_key: dialog.e008.liu_show
text_zh: |
  她从袖子里掏出一个红绸包，打开——一对赤金镯子。赤金压手，怕是她半年工钱都换不来。
next: dialog_e008_lin_shock

dialog_id: dialog_e008_lin_shock
speaker: char_lin_ruisheng
loc_key: dialog.e008.lin_shock
text_zh: |
  这哪来的？
next: dialog_e008_liu_explain

dialog_id: dialog_e008_liu_explain
speaker: char_liu_ruyan
loc_key: dialog.e008.liu_explain
text_zh: |
  钱家……派人送来的。说是少爷的心意。问……问我们愿不愿意。那婆子还说，少爷若开口，往后我娘家那边的日子也能照应。
next: dialog_e008_lin_rage

dialog_id: dialog_e008_lin_rage
speaker: char_lin_ruisheng
loc_key: dialog.e008.lin_rage
text_zh: |
  他这是什么意思？纳妾？你是我的人，他拿对镯子就想……
next: dialog_e008_liu_fear

dialog_id: dialog_e008_liu_fear
speaker: char_liu_ruyan
loc_key: dialog.e008.liu_fear
text_zh: |
  瑞生，我害怕。可你别说出去，钱家的势力……我们惹不起。这镯子我退也不是，不退也不是……
  收了，像是认了；退了，他们一句话，厂里都未必还有我站脚的地方。
next: dialog_e008_choice

dialog_id: dialog_e008_choice
event_id: E008
speaker: narrator
loc_key: dialog.e008.choice_prompt
text_zh: |
  （你怎么做？）
tags: [mainline, choice]
choices:
  - id: A
    loc_key: dialog.e008.choice.a
    text_zh: 找老板理论
    effects:
      - { op: add, key: stat_trust_firm, value: -20 }
      - { op: add, key: stat_suspicion, value: 10 }
      - { op: add, edge: {from: char_qian_demao, to: char_lin_ruisheng}, key: score, value: -15 }
      - { op: add, edge: {from: char_qian_demao, to: char_lin_ruisheng}, key: suspicion, value: 1 }
      - { op: set_flag, key: flag_need_marriage_fund, value: true }
      - { op: set_flag, key: flag_marked_restless, value: true }
      - { op: unlock_grudge, id: grudge_zian_fiancee }
    next: dialog_e008_outro_a
  - id: B
    loc_key: dialog.e008.choice.b
    text_zh: 隐忍不发
    effects:
      - { op: add, key: stat_intel, value: 5 }
      - { op: add, edge: {from: char_liu_ruyan, to: char_lin_ruisheng}, key: score, value: 5 }
      - { op: set_flag, key: flag_need_marriage_fund, value: true }
      - { op: set_flag, key: flag_endure_preview, value: true }
      - { op: unlock_grudge, id: grudge_zian_fiancee }
    next: dialog_e008_outro_b
  - id: C
    loc_key: dialog.e008.choice.c
    text_zh: 去找赵鸿运打听
    effects:
      - { op: add, key: stat_network, value: 5 }
      - { op: add, key: stat_intel, value: 10 }
      - { op: add, key: stat_credit_market, value: 5 }
      - { op: set_flag, key: flag_need_marriage_fund, value: true }
      - { op: add, edge: {from: char_zhao_hongyun, to: char_lin_ruisheng}, key: score, value: 5 }
      - { op: unlock_grudge, id: grudge_zian_fiancee }
    next: dialog_e008_outro_c
```

### Outros

```yaml
dialog_id: dialog_e008_outro_a
speaker: narrator
loc_key: dialog.e008.outro.a
text_zh: |
  钱德茂嘴上安抚，眼神却冷。你被暗中标成了「不安分」。
next: null

dialog_id: dialog_e008_outro_b
speaker: narrator
loc_key: dialog.e008.outro.b
text_zh: |
  你按住怒火。眼下争这一对镯子，争不过钱家的银子和势力；得争那条更大的钱路。
  如烟更愧疚，也更黏着你——这条路，才刚起头。
next: null

dialog_id: dialog_e008_outro_c
speaker: narrator
loc_key: dialog.e008.outro.c
text_zh: |
  赵鸿运听完，笑眯眯地说：有意思。可空口无凭，你得先拿出点值钱的东西来。
next: null
```
