# 对话 · E014 钱子安的鲁莽

> 入口：`dialog_e014_start` · 事件 [`../07_事件档案/主线/E014_钱子安的鲁莽.md`](../07_事件档案/主线/E014_钱子安的鲁莽.md)  
> 选项 A 成功后授予 [`../12_信物与把柄/ITEM_庆系手书.md`](../12_信物与把柄/ITEM_庆系手书.md)

---

## 节点图

```
dialog_e014_start
  → dialog_e014_overhear
  → dialog_e014_zian_1
  → dialog_e014_retainer
  → dialog_e014_zian_2
  → dialog_e014_realize
  → dialog_e014_choice
       ├─ A (require support) → dialog_e014_outro_a → END
       ├─ B → dialog_e014_outro_b → END
       └─ C → dialog_e014_outro_c → END
```

---

## Nodes

### `dialog_e014_start`

```yaml
dialog_id: dialog_e014_start
event_id: E014
speaker: narrator
loc_key: dialog.e014.start
text_zh: |
  林瑞生偶然听到钱子安在屋里发牢骚——他从账房偷看了父亲的密账，发现「每月往北京送三万两」，不知道背后的庆大人，以为父亲被人骗了或者在私吞家产。
require:
  - { key: stat_intel, op: ">=", value: 35 }
  - { clue: clue_special_goods, owned: true }
tags: [mainline]
next: dialog_e014_overhear
```

### `dialog_e014_overhear`

```yaml
dialog_id: dialog_e014_overhear
speaker: narrator
loc_key: dialog.e014.overhear
text_zh: |
  （隔墙，听得真切。）
next: dialog_e014_zian_1
```

### `dialog_e014_zian_1`

```yaml
dialog_id: dialog_e014_zian_1
speaker: char_qian_zian
loc_key: dialog.e014.zian_1
text_zh: |
  三万两！他一个月给我二十两月例，转头给北京送三万两！凭什么？他当我是傻子？
next: dialog_e014_retainer
```

### `dialog_e014_retainer`

```yaml
dialog_id: dialog_e014_retainer
speaker: narrator
loc_key: dialog.e014.retainer
text_zh: |
  【随从】少爷，要不……问问东家？
# 随从无独立 char；Demo 用旁白代
next: dialog_e014_zian_2
```

### `dialog_e014_zian_2`

```yaml
dialog_id: dialog_e014_zian_2
speaker: char_qian_zian
loc_key: dialog.e014.zian_2
text_zh: |
  问个屁！他问起来我就说不知道。下次那批货出门，我亲自去截——我看他怎么解释！
next: dialog_e014_realize
```

### `dialog_e014_realize`

```yaml
dialog_id: dialog_e014_realize
speaker: narrator
loc_key: dialog.e014.realize
text_zh: |
  林瑞生心头一震。结合账房里那本「特别货」密账、末页「庆大人·月奉」——少爷要截的，八成是送往京中的货与银票。
  若真截了：那边收不到东西，钱德茂未必保得住自己。

  三万两不是小账。那不是少爷多眼红了几锭银子，而是他第一次看清：家里真正的大钱，从来没准备分到他手上。

  至于货里究竟是什么，你心里有影，却还没亲眼钉死。眼下更要紧的是——这是一个天大的机会。
next: dialog_e014_choice
```

### `dialog_e014_choice`

```yaml
dialog_id: dialog_e014_choice
event_id: E014
speaker: narrator
loc_key: dialog.e014.choice_prompt
text_zh: |
  （你怎么做？）
tags: [mainline, choice]
choices:
  - id: A
    loc_key: dialog.e014.choice.a
    text_zh: 暗中阻止钱子安，自己接手护送银票（靠近账权经手层的门槛）
    require:
      - { key: stat_support_mid, op: ">=", value: 40 }
      - { key: stat_support_low, op: ">=", value: 40 }
    effects:
      - { op: add, key: stat_intel, value: 15 }
      - { op: add, key: stat_suspicion, value: 10 }
      - { op: add, meter: impression_qing, value: 30 }
      - { op: add, edge: {from: char_qing_daren, to: char_lin_ruisheng}, key: score, value: 25 }
      - { op: add, edge: {from: char_zhou_guanshi, to: char_lin_ruisheng}, key: score, value: 20 }
      - { op: grant_item, id: item_qing_letter }
    next: dialog_e014_outro_a
  - id: B
    loc_key: dialog.e014.choice.b
    text_zh: 直接告诉钱德茂，让他自己处理（站稳内部位置，嫌疑可控才有经手权）
    effects:
      - { op: add, key: stat_trust_firm, value: 10 }
      - { op: add, edge: {from: char_qian_demao, to: char_lin_ruisheng}, key: score, value: 8 }
      - { op: add, edge: {from: char_qian_demao, to: char_lin_ruisheng}, key: suspicion, value: 2 }
      - { op: add, meter: father_son, value: -25 }
      - { op: add, edge: {from: char_qian_demao, to: char_qian_zian}, key: score, value: -15 }
      - { op: add, edge: {from: char_qian_zian, to: char_qian_demao}, key: score, value: -10 }
    next: dialog_e014_outro_b
  - id: C
    loc_key: dialog.e014.choice.c
    text_zh: 放任不管（分利崩盘，反而让你退回更脆的位置）
    effects:
      - { op: add, meter: father_son, value: -40 }
      - { op: add, key: stat_intel, value: 5 }
      - { op: set_flag, key: route_foreign_closed, value: true }
    next: dialog_e014_outro_c
```

### `dialog_e014_outro_a`

```yaml
dialog_id: dialog_e014_outro_a
speaker: narrator
loc_key: dialog.e014.outro.a
text_zh: |
  银票交到周管事手上。他捻了捻封口，看了你一眼，没多问。
  回京复命时，会提起天津有个叫林瑞生的年轻人，办差妥帖。
  这趟差事没有现银落进你袖里，可比散碎赏钱值钱得多：你摸到了能换来大钱路的门槛，也更像“自己人”。
  （获得信物：庆系相关凭据 / item_qing_letter）
next: null
```

### `dialog_e014_outro_b`

```yaml
dialog_id: dialog_e014_outro_b
speaker: narrator
loc_key: dialog.e014.outro.b
text_zh: |
  钱德茂听完脸色铁青。他对儿子更不放心了——也对你多了一分疑心：
  你怎么知道得这么清楚？
  你明白：你拿到的不是银子，是可被允许经手的信任门缝。
next: null
```

### `dialog_e014_outro_c`

```yaml
dialog_id: dialog_e014_outro_c
speaker: narrator
loc_key: dialog.e014.outro.c
text_zh: |
  货被截了。钱家乱成一团。庆大人那边断了线——你那条狐假虎威的路，也断了。
next: null
```
