# 对话 · E017 向洋人递刀

> 入口：`dialog_e017_start` · 事件 [`../07_事件档案/主线/E017_向洋人递刀.md`](../07_事件档案/主线/E017_向洋人递刀.md)  
> 选项 A 需 [`item_qing_letter`](../12_信物与把柄/ITEM_庆系手书.md)

---

## 节点图

```
dialog_e017_start
  → dialog_e017_lin_hint
  → dialog_e017_bradley_probe
  → dialog_e017_lin_hedge
  → dialog_e017_bradley_ask
  → dialog_e017_choice
       ├─ A (qing≥30 + item) → outro_a
       ├─ B → outro_b
       └─ C → outro_c
```

---

## Nodes

### `dialog_e017_start`

```yaml
dialog_id: dialog_e017_start
event_id: E017
speaker: narrator
loc_key: dialog.e017.start
text_zh: |
  林瑞生在茶楼「偶遇」白瑞德。两人寒暄后，林瑞生看似无意地提起——
require:
  - { meter: impression_qing, op: ">=", value: 30 }
  - { meter: impression_bradley, op: ">=", value: 10 }
  - { flag: route_foreign, value: true }
  - { flag: route_foreign_closed, value: false }
  - { loc: loc_03 }
tags: [mainline, foreign]
next: dialog_e017_lin_hint
```

### `dialog_e017_lin_hint`

```yaml
dialog_id: dialog_e017_lin_hint
speaker: char_lin_ruisheng
loc_key: dialog.e017.lin_hint
text_zh: |
  白先生，钱记商行最近不太平。少爷和东家闹得厉害，听说少爷还要截东家的货。
  这种事，外人不好说，可钱记若是内部不稳……跟宝顺洋行合作，怕是不保险。
next: dialog_e017_bradley_probe
```

### `dialog_e017_bradley_probe`

```yaml
dialog_id: dialog_e017_bradley_probe
speaker: char_bradley
loc_key: dialog.e017.bradley_probe
text_zh: |
  哦？截货？什么样的货？
next: dialog_e017_lin_hedge
```

### `dialog_e017_lin_hedge`

```yaml
dialog_id: dialog_e017_lin_hedge
speaker: char_lin_ruisheng
loc_key: dialog.e017.lin_hedge
text_zh: |
  这我就不清楚了。只是风声。白先生要跟钱东家合作，还是多看看为好。
next: dialog_e017_bradley_ask
```

### `dialog_e017_bradley_ask`

```yaml
dialog_id: dialog_e017_bradley_ask
speaker: narrator
loc_key: dialog.e017.bradley_ask_narr
text_zh: |
  白瑞德沉默片刻，然后笑了。
---
speaker: char_bradley
loc_key: dialog.e017.bradley_ask
text_zh: |
  林朋友，你倒是热心。不过——你跟我说这些，图什么？
next: dialog_e017_choice
```

### `dialog_e017_choice`

```yaml
dialog_id: dialog_e017_choice
event_id: E017
speaker: narrator
loc_key: dialog.e017.choice_prompt
text_zh: |
  （你怎么答？）
tags: [mainline, choice]
choices:
  - id: A
    loc_key: dialog.e017.choice.a
    text_zh: 直接摊牌，亮出庆大人管事的手书——把你抬到能签约的价码（层 3）
    require:
      - { meter: impression_qing, op: ">=", value: 30 }
      - { item: item_qing_letter, owned: true }
    effects:
      - { op: add, meter: impression_bradley, value: 25 }
      - { op: add, edge: {from: char_bradley, to: char_lin_ruisheng}, key: score, value: 20 }
      - { op: add, meter: eval, value: -10 }
      - { op: set_flag, key: flag_ending_c_ready, value: true }
    next: dialog_e017_outro_a
  - id: B
    loc_key: dialog.e017.choice.b
    text_zh: 暗示有更好的合作人选（自己），但不亮底牌——先试探，再等他们看见“能不能成”（层 2）
    effects:
      - { op: add, meter: impression_bradley, value: 15 }
      - { op: add, edge: {from: char_bradley, to: char_lin_ruisheng}, key: score, value: 10 }
    next: dialog_e017_outro_b
  - id: C
    loc_key: dialog.e017.choice.c
    text_zh: 不图什么，只是「好心提醒」（礼到心到，价码还没到手）（层 2）
    effects:
      - { op: add, meter: impression_bradley, value: 5 }
      - { op: add, edge: {from: char_bradley, to: char_lin_ruisheng}, key: score, value: 3 }
    next: dialog_e017_outro_c
```

### Outros

```yaml
dialog_id: dialog_e017_outro_a
speaker: char_lin_ruisheng
loc_key: dialog.e017.outro.a_line
text_zh: |
  白先生要找有官场背景的人。我恰好认识一些京中的朋友。
---
speaker: narrator
loc_key: dialog.e017.outro.a
text_zh: |
  白瑞德看过手书，态度明显转变。他表示有兴趣详谈，邀请你到宝顺洋行正式会谈（层 4 的门槛已亮起）。
next: null

dialog_id: dialog_e017_outro_b
speaker: narrator
loc_key: dialog.e017.outro.b
text_zh: |
  白瑞德领会了意思，却不急着拍板：「再办成一件让我看见的事——比如，让钱记的人自己乱一阵。然后，我们再谈价」（层 2→层 4 的过渡）。
next: null

dialog_id: dialog_e017_outro_c
speaker: narrator
loc_key: dialog.e017.outro.c
text_zh: |
  「好心。」白瑞德重复这两个字，像在品尝。他起身时只说：「林朋友，宝顺的门不常开。下次来，带点真东西」（把你推到“能开价”的那一天）（层 4 前置）。
next: null
```