# 对话 · 日常行动口风池

> **挂接**：各 `act_*` 执行完 effect 后，按条件播 `outro` 节点（可重复、无分支）。  
> 数值已在行动 `effects` 中结算；此处只负责表现层 `loc_key`。  
> 规范：[`../00_总纲/对话规范.md`](../00_总纲/对话规范.md)

---

## 挂接方式（实现参考）

```yaml
on_action_complete:
  act_01:
    goto_dialog_by_condition:
      - require: [{ key: stat_money, op: "<", value: 20 }]
        id: dialog_act_01_outro_tight
      - require: [{ key: stat_money, op: ">=", value: 50 }]
        id: dialog_act_01_outro_well
      - default: dialog_act_01_outro_default
  act_11:
    goto_dialog: dialog_act_11_menu   # 菜单型；选项再跳子节点
```

---

## act_01 · 商行干活

```yaml
dialog_id: dialog_act_01_outro_default
speaker: narrator
loc_key: dialog.act_01.outro.default
text_zh: |
  前堂忙到日头偏西，周管事记了一笔：「今日勤快。」月例外的碎银落进荷包。你知道这钱不是运气，是东家愿意让你先活下去。
tags: [action, act_01]
next: null

dialog_id: dialog_act_01_outro_tight
speaker: narrator
loc_key: dialog.act_01.outro.tight
require: [{ key: stat_money, op: "<", value: 20 }]
text_zh: |
  今日又挣得二三两，够吃几天。你掂了掂荷包，聘礼仍像天边的数。可至少，月例还没断。
tags: [action, act_01, money_tight]
next: null

dialog_id: dialog_act_01_outro_well
speaker: narrator
loc_key: dialog.act_01.outro.well
require: [{ key: stat_money, op: ">=", value: 50 }]
text_zh: |
  活还是那些活，银子却不像以前那样掐着花。周管事扫你一眼：勤快仍比阔气要紧。你听懂了——你离能经手账的那一步，近了一点。
tags: [action, act_01, money_well]
next: null
```

---

## act_02 · 整理货单

```yaml
dialog_id: dialog_act_02_outro_default
speaker: narrator
loc_key: dialog.act_02.outro.default
text_zh: |
  货单上的斤两、箱数、价码对了一遍又一遍。有几个数对不上，你在心里画了个问号。你不急着赌钱，只先记住“怎么报账才不露怯”。
tags: [action, act_02]
next: null
```

---

## act_03 · 茶楼打听

```yaml
dialog_id: dialog_act_03_outro_default
speaker: narrator
loc_key: dialog.act_03.outro.default
text_zh: |
  一壶茶见底，街面上的闲话筛过一遍，有用的几句记在心上。
tags: [action, act_03]
next: null

dialog_id: dialog_act_03_outro_tight
speaker: narrator
loc_key: dialog.act_03.outro.tight
require: [{ key: stat_money, op: "<", value: 20 }]
text_zh: |
  茶钱摸出来，心都在疼。这消息最好值当，不然明日只能喝西北风。
tags: [action, act_03, money_tight]
next: null

dialog_id: dialog_act_03_outro_well
speaker: narrator
loc_key: dialog.act_03.outro.well
require: [{ key: stat_money, op: ">=", value: 50 }]
text_zh: |
  赏钱给得爽快，跑堂凑近低语：近来票号、洋行、钱记，都有动静。
tags: [action, act_03, money_well]
next: null
```

---

## act_04 · 请师兄喝酒

```yaml
dialog_id: dialog_act_04_outro_default
speaker: narrator
loc_key: dialog.act_04.outro.default
text_zh: |
  三两大酒钱，换来师兄几段后院门缝里听来的风声。酒尽人散，交情又厚一分。
tags: [action, act_04]
next: null

dialog_id: dialog_act_04_outro_tight
speaker: narrator
loc_key: dialog.act_04.outro.tight
require: [{ key: stat_money, op: "<", value: 20 }]
text_zh: |
  这顿酒几乎掏空了兜里的活钱。王胖子拍肩：「兄弟，我记着你这份心。」
tags: [action, act_04, money_tight]
next: null

dialog_id: dialog_act_04_outro_well
speaker: narrator
loc_key: dialog.act_04.outro.well
require: [{ key: stat_money, op: ">=", value: 50 }]
text_zh: |
  酒钱算不了什么。师兄压低嗓子：「货栈那边别问太细——有人问，推给我。」
tags: [action, act_04, money_well]
next: null
```

---

## act_05 · 拉拢伙计

```yaml
dialog_id: dialog_act_05_outro_default
speaker: narrator
loc_key: dialog.act_05.outro.default
text_zh: |
  散碎银子、一包烟、替人顶半个时辰——后院有人冲你点了点头。
tags: [action, act_05]
next: null

dialog_id: dialog_act_05_outro_tight
speaker: narrator
loc_key: dialog.act_05.outro.tight
require: [{ key: stat_money, op: "<", value: 20 }]
text_zh: |
  只够请一个人吃碗面。谁拿了好处心里都记着，也都知道你并不宽裕。
tags: [action, act_05, money_tight]
next: null

dialog_id: dialog_act_05_outro_well
speaker: narrator
loc_key: dialog.act_05.outro.well
require: [{ key: stat_money, op: ">=", value: 50 }]
text_zh: |
  赏钱给得大方，后院几个人交换眼神：「林兄弟，有事言语。」
tags: [action, act_05, money_well]
next: null
```

---

## act_06 · 陪伴如烟

```yaml
dialog_id: dialog_act_06_outro_default
speaker: narrator
loc_key: dialog.act_06.outro.default
text_zh: |
  货栈小屋里茶烟袅袅，你们说了些无关紧要的闲话。嫌疑像薄雾，散了一些。
tags: [action, act_06]
next: null

dialog_id: dialog_act_06_outro_tight
speaker: narrator
loc_key: dialog.act_06.outro.tight
require: [{ key: stat_money, op: "<", value: 20 }]
text_zh: |
  只陪坐说说话。柳如烟倒茶：「你也不容易，别为我乱花钱。」
tags: [action, act_06, money_tight]
next: null

dialog_id: dialog_act_06_outro_marriage_pressure
speaker: narrator
loc_key: dialog.act_06.outro.marriage_pressure
require: [{ flag: flag_need_marriage_fund, value: true }]
text_zh: |
  说到婚期，两人都安静了一瞬。不是没情分，是聘礼、铺盖、酒席钱还没着落。
tags: [action, act_06, marriage_pressure]
next: null

dialog_id: dialog_act_06_outro_gift
speaker: narrator
loc_key: dialog.act_06.outro.gift
require:
  - { key: stat_money, op: ">=", value: 30 }
  - { flag: flag_liu_gift_today, value: false }
text_zh: |
  捎了一包点心，如烟推辞半晌才收：「你心里有我，就够了。」
effects:
  - { op: add, key: stat_money, value: -3 }
  - { op: add, edge: {from: char_liu_ruyan, to: char_lin_ruisheng}, key: score, value: 3 }
  - { op: set_flag, key: flag_liu_gift_today, value: true }
tags: [action, act_06, optional_gift]
next: null
```

---

## act_07 · 街市结交

```yaml
dialog_id: dialog_act_07_outro_default
speaker: narrator
loc_key: dialog.act_07.outro.default
text_zh: |
  街市上又多了几张认得你的脸。门路钱不在银子多少，在“愿意替你递话”的份量上。
tags: [action, act_07]
next: null

dialog_id: dialog_act_07_outro_tight
speaker: narrator
loc_key: dialog.act_07.outro.tight
require: [{ key: stat_money, op: "<", value: 20 }]
text_zh: |
  只能请一碗茶，话却说得足：「兄弟，日后有事找林瑞生。」你穷归穷，街面却记住了你。
tags: [action, act_07, money_tight]
next: null

dialog_id: dialog_act_07_outro_well
speaker: narrator
loc_key: dialog.act_07.outro.well
require: [{ key: stat_money, op: ">=", value: 50 }]
text_zh: |
  小小人情做足了，街市上有人点头：「钱记那个跑腿的，会办事。」你在他们眼里，算是能走通的那一类人。
tags: [action, act_07, money_well]
next: null
```

---

## act_08 · 休息整理

```yaml
dialog_id: dialog_act_08_outro_default
speaker: narrator
loc_key: dialog.act_08.outro.default
text_zh: |
  闭门不出，把纷乱理一理。明日精神些，再出门碰运气。
tags: [action, act_08]
next: null

dialog_id: dialog_act_08_outro_tight
speaker: narrator
loc_key: dialog.act_08.outro.tight
require: [{ key: stat_money, op: "<", value: 20 }]
text_zh: |
  在货栈小屋数了数剩银，明日还得找活路。
tags: [action, act_08, money_tight]
next: null

dialog_id: dialog_act_08_outro_marriage_pressure
speaker: narrator
loc_key: dialog.act_08.outro.marriage_pressure
require: [{ flag: flag_need_marriage_fund, value: true }]
text_zh: |
  今夜省下一点心意钱，婚期也就又往后推了一步。你知道这不是没良心，是没活钱。
tags: [action, act_08, marriage_pressure]
next: null

dialog_id: dialog_act_08_outro_suspicion
speaker: narrator
loc_key: dialog.act_08.outro.suspicion
require: [{ key: stat_suspicion, op: ">=", value: 2 }]
text_zh: |
  风头紧，不如歇一日。穷一点，总比被抓现行强。
tags: [action, act_08, high_suspicion]
next: null
```

---

## act_09 · 暗中观察

```yaml
dialog_id: dialog_act_09_outro_default
speaker: narrator
loc_key: dialog.act_09.outro.default
text_zh: |
  深夜后院，你贴墙听了一阵。心跳快，耳朵更灵——记下几笔，也记下这份险。
tags: [action, act_09]
next: null
```

---

## act_10 · 接触竞品

```yaml
dialog_id: dialog_act_10_outro_default
speaker: narrator
loc_key: dialog.act_10.outro.default
text_zh: |
  赵鸿运话里带刺也带笑，聚丰行的门缝似乎开了一条缝——像在当场估价你值不值得投。
tags: [action, act_10]
next: null

dialog_id: dialog_act_10_outro_tight
speaker: char_zhao_hongyun
loc_key: dialog.act_10.outro.tight
require: [{ key: stat_money, op: "<", value: 20 }]
text_zh: |
  有心跳槽，得先像能周转的人。穷鬼我请不起——至少还不够被报价的那一档。
tags: [action, act_10, money_tight]
next: null

dialog_id: dialog_act_10_outro_well
speaker: char_zhao_hongyun
loc_key: dialog.act_10.outro.well
require: [{ key: stat_money, op: ">=", value: 50 }]
text_zh: |
  林掌柜手头活泛，聚丰行缺会算账的人。——话里没银子，眼里有数。赵鸿运的笑，是把你记进了投位子的意思。
tags: [action, act_10, money_well]
next: null
```

---

## act_11 · 钱庄办事

```yaml
dialog_id: dialog_act_11_menu
speaker: narrator
loc_key: dialog.act_11.menu
text_zh: |
  票号柜面算盘轻响。你要办哪一桩？
tags: [action, act_11]
choices:
  - id: loan
    loc_key: dialog.act_11.choice.loan
    require: [{ key: stat_money, op: ">=", value: 10 }]
    next: dialog_act_11_loan
  - id: remit
    loc_key: dialog.act_11.choice.remit
    require: [{ key: stat_money, op: ">=", value: 20 }]
    next: dialog_act_11_remit
  - id: market
    loc_key: dialog.act_11.choice.market
    require: [{ key: stat_money, op: ">=", value: 10 }]
    next: dialog_act_11_market
  - id: tier2
    loc_key: dialog.act_11.choice.tier2
    require: [{ flag: flag_bank_tier2, value: true }]
    next: dialog_act_11_tier2

dialog_id: dialog_act_11_loan
speaker: narrator
loc_key: dialog.act_11.loan
text_zh: |
  柜员拨算盘：「短借十五两，利钱照算，按期还。」银子入袋，心里却多了一桩账。
effects:
  - { op: add, key: stat_money, value: 15 }
  - { op: add, key: stat_suspicion, value: 3 }
  - { op: set_flag, key: flag_bank_loan_active, value: true }
next: null

dialog_id: dialog_act_11_remit
speaker: narrator
loc_key: dialog.act_11.remit
text_zh: |
  汇五两出去，票号盖了戳。体面这东西，有时比银子更急。
effects:
  - { op: add, key: stat_money, value: -5 }
  - { op: add, key: stat_credit_bank, value: 3 }
  - { op: add, meter: impression_qing, value: 2 }
  - { op: clear_flag, key: flag_need_marriage_fund }
next: null

dialog_id: dialog_act_11_market
speaker: narrator
loc_key: dialog.act_11.market
text_zh: |
  花两吊打听行情：洋货价、票号风向、钱记上下游，零碎拼成一张图。
effects:
  - { op: add, key: stat_money, value: -2 }
  - { op: add_range, key: stat_intel, min: 1, max: 3 }
next: null

dialog_id: dialog_act_11_tier2
speaker: narrator
loc_key: dialog.act_11.tier2
text_zh: |
  自从身子里有了五十两活钱，票号把你记进簿子：「林掌柜，照旧？」
effects:
  - { op: add_range, key: stat_network, min: 2, max: 4 }
next: null

dialog_id: dialog_act_11_outro_tight
speaker: narrator
loc_key: dialog.act_11.outro.tight
require: [{ key: stat_money, op: "<", value: 20 }]
text_zh: |
  柜员打量你：「零碎客，借可以，利钱照算。」
tags: [action, act_11, money_tight]
next: dialog_act_11_menu

dialog_id: dialog_act_11_outro_mid
speaker: narrator
loc_key: dialog.act_11.outro.mid
require:
  - { key: stat_money, op: ">=", value: 10 }
  - { key: stat_money, op: "<", value: 50 }
text_zh: |
  票号肯办常规汇兑、小借小还；柜员语气客气，仍把你当过客。
tags: [action, act_11]
next: dialog_act_11_menu

dialog_id: dialog_act_11_outro_well
speaker: narrator
loc_key: dialog.act_11.outro.well
require: [{ key: stat_money, op: ">=", value: 50 }]
text_zh: |
  票号把你当能周转的人，柜面语气也热络几分。
tags: [action, act_11, money_well]
next: dialog_act_11_menu
```

---

## act_12 · 整理情报

```yaml
dialog_id: dialog_act_12_outro_default
speaker: narrator
loc_key: dialog.act_12.outro.default
text_zh: |
  零碎线索摊在案上，拼出一条隐约的线。能不能卖钱、换路、要命，还得看下一步。
tags: [action, act_12]
next: null
```

---

## 日末拮据提示（可选）

```yaml
dialog_id: dialog_money_day_end_broke
speaker: narrator
loc_key: dialog.money.day_end.broke
require: [{ key: stat_money, op: "<", value: 10 }]
text_zh: |
  生活费又扣去一两。荷包里叮当响，是该想办法了。
tags: [system, money_broke]
next: null

dialog_id: dialog_money_day_end_tight
speaker: narrator
loc_key: dialog.money.day_end.tight
require:
  - { key: stat_money, op: ">=", value: 10 }
  - { key: stat_money, op: "<", value: 20 }
text_zh: |
  还能撑几日，但请客、送礼、打点都得掂量着来。
tags: [system, money_tight]
next: null

dialog_id: dialog_money_day_end_marriage_pressure
speaker: narrator
loc_key: dialog.money.day_end.marriage_pressure
require: [{ flag: flag_need_marriage_fund, value: true }]
text_zh: |
  婚事不是一句话就能成。聘礼、铺盖、酒席钱像一张单子，夜里不看也压在心上。
tags: [system, marriage_pressure]
next: null
```
