# 对话 · E018 阶段性结局

> 入口：`dialog_e018_start` · 事件 [`../07_事件档案/主线/E018_阶段性结局.md`](../07_事件档案/主线/E018_阶段性结局.md)  
> 判定见 [`../10_路线与结局/阶段性结局.md`](../10_路线与结局/阶段性结局.md)。  
> **引擎**：失败优先（含中途开除/清除/反水旗）→ 再匹配 A/B/C。

---

## 节点图

```
dialog_e018_start
  → next_by_condition
       ├─ fail_purged / fail_fired / fail_liu / fail_stats → 分支失败文案
       ├─ A 隐忍
       ├─ B 跳槽
       └─ C 洋人（硬门：flag_ending_c_ready）
```

---

## Nodes

### `dialog_e018_start`

```yaml
dialog_id: dialog_e018_start
event_id: E018
speaker: narrator
loc_key: dialog.e018.start
text_zh: |
  光绪十六年的秋天，到了结账的日子。
tags: [mainline, ending]
next_by_condition:
  # —— 失败优先（中途终局旗）——
  - id: fail_purged
    require: [{ flag: flag_purged, value: true }]
    next: dialog_e018_fail_purged
  - id: fail_fired
    require: [{ flag: flag_fired, value: true }]
    next: dialog_e018_fail_fired
  - id: fail_liu
    require_any:
      - { flag: flag_liu_betrayed, value: true }
      - all:
          - { edge: {from: char_liu_ruyan, to: char_lin_ruisheng}, key: score, op: "<=", value: -20 }
          - { meter: pursuit, op: ">=", value: 60 }
    next: dialog_e018_fail_liu
  - id: fail_stats
    require_any:
      - { key: stat_suspicion, op: ">=", value: 100 }
      - { key: stat_trust_firm, op: "<=", value: 0 }
    next: dialog_e018_fail_stats
  # —— 成功结局 ——
  - id: ending_a
    require:
      - { meter: father_son, op: "<=", value: 30 }
      - { key: stat_trust_firm, op: ">=", value: 50 }
      - { key: stat_intel, op: ">=", value: 40 }
      - { flag: route_endure_failed, value: false }
    next: dialog_e018_a
  - id: ending_b
    require:
      - { key: stat_network, op: ">=", value: 40 }
      - { key: stat_intel, op: ">=", value: 30 }
      - { edge: {from: char_zhao_hongyun, to: char_lin_ruisheng}, key: score, op: ">=", value: 40 }
    next: dialog_e018_b
  - id: ending_c
    require:
      - { flag: flag_ending_c_ready, value: true }
      - { flag: route_foreign_closed, value: false }
      - { meter: impression_qing, op: ">=", value: 30 }
      - { meter: impression_bradley, op: ">=", value: 30 }
      - { key: stat_intel, op: ">=", value: 35 }
      - { key: stat_support_mid, op: ">=", value: 40 }
    next: dialog_e018_c
  - id: fallback_fail
    next: dialog_e018_fail_stats
```

---

### 结局 A · 隐忍

```yaml
dialog_id: dialog_e018_a
speaker: narrator
loc_key: dialog.e018.a.narr
text_zh: |
  钱德茂发现账目有出入，怀疑钱子安私吞了一笔货款。钱子安暴怒，当众和父亲吵了一架，摔门而去。商行人心惶惶，两个老伙计私下说要走。

  钱德茂不得不重新倚重林瑞生。
next: dialog_e018_a_qian

dialog_id: dialog_e018_a_qian
speaker: char_qian_demao
loc_key: dialog.e018.a.qian
text_zh: |
  瑞生啊，子安不争气。跑街的位置，明天就给你。后堂的事你也多看着。月例提上去，外头的应酬账也归你经手。
next: dialog_e018_a_close

dialog_id: dialog_e018_a_close
speaker: narrator
loc_key: dialog.e018.a.close
text_zh: |
  林瑞生低着头应了。他能进后堂了——更多账目、更多秘密。
  这不只是个位置。月例更厚，街面上的体面更足，婚事也终于像能往前挪一挪。

  光绪十六年的秋天，林瑞生当上了钱记商行的跑街。他走进了后堂，看到了那些他不该看到的东西。

  可他还没想到：从天津到京城的那条线，不会让一个跑街的小子轻易翻身。

  暗潮，才刚刚涌动。
# 若持有 item_opium_sample，表现层可追加一句「口袋里那块膏状物发烫」；无样品则不提。
effects:
  - { op: set_flag, key: flag_ending_a, value: true }
next: null
```

---

### 结局 B · 跳槽

```yaml
dialog_id: dialog_e018_b
speaker: narrator
loc_key: dialog.e018.b.narr
text_zh: |
  林瑞生带着钱记的客户名单和几份货情抄件，敲开了聚丰行的侧门。
next: dialog_e018_b_zhao

dialog_id: dialog_e018_b_zhao
speaker: char_zhao_hongyun
loc_key: dialog.e018.b.zhao
text_zh: |
  好。从今天起，你是聚丰的跑街，月薪五两。先办一件事——把钱记那批南洋木材的单子，截过来。你先前被报价的那份资格，今天算是兑现了第一笔钱。
next: dialog_e018_b_close

dialog_id: dialog_e018_b_close
speaker: narrator
loc_key: dialog.e018.b.close
text_zh: |
  第一步做成了。钱德茂勃然大怒，却查不到是谁走漏的消息。

  月薪五两，比在钱记当学徒像样得多；可这五两不是抬举，是价码。赵鸿运笑眯眯看着你，那眼神像在称一块肉——有用，但随时可换。

  暗潮换了岸，水一样深。
effects:
  - { op: set_flag, key: flag_ending_b, value: true }
next: null
```

---

### 结局 C · 洋人

```yaml
dialog_id: dialog_e018_c
speaker: narrator
loc_key: dialog.e018.c.narr
require:
  - { loc: loc_05 }
text_zh: |
  白瑞德邀请林瑞生到宝顺洋行天津分行正式会谈。茶是锡兰红茶，杯子是官窑青花。

  林瑞生没有先谈古董。他递上一封信——周管事手书，称「林瑞生办事妥帖，日后有事可托」。
next: dialog_e018_c_bradley

dialog_id: dialog_e018_c_bradley
speaker: char_bradley
loc_key: dialog.e018.c.bradley
text_zh: |
  林朋友，你这封信，比十箱古董都值钱。京中的路子，我在天津找了三年都没找到门。
next: dialog_e018_c_lin

dialog_id: dialog_e018_c_lin
speaker: char_lin_ruisheng
loc_key: dialog.e018.c.lin
text_zh: |
  白先生，钱记内部不稳，少爷莽撞——差点截了自家运往京里的货。宝顺要长期合作，得找靠得住的人。
next: dialog_e018_c_price

dialog_id: dialog_e018_c_price
speaker: char_bradley
loc_key: dialog.e018.c.price
text_zh: |
  那你开个价。第一笔分成从这里起（层 4），后续才谈抽头与佣金（层 5）。
next: dialog_e018_c_close

dialog_id: dialog_e018_c_close
speaker: narrator
loc_key: dialog.e018.c.close
text_zh: |
  从这一刻起，他不再是学徒，而是宝顺在天津的新代理人。钱德茂成了「旧人」。旧人挡路，要么让开，要么被让开。

  洋人的合作不是施舍——是交易。分成、抽头、佣金，会比跑街月例厚得多；这就是层 5：让你在长期流水里被“绑定、可替代但离不开”。
  代价是日后替他们辨青铜、找字画、通门路；还有南方一路运来的货。

  暗潮之下，没有干净的手。
effects:
  - { op: set_flag, key: flag_ending_c, value: true }
next: null
```

---

### 失败分支

```yaml
dialog_id: dialog_e018_fail_fired
speaker: narrator
loc_key: dialog.e018.fail.fired
text_zh: |
  钱记的朱红大门早已对你关上。你在华界租间破屋熬到秋末，手里的散碎银子一天薄过一天，打听消息的人越来越少。

  光绪十六年的天津，多了一个没人记得名字的流浪汉。
effects:
  - { op: set_flag, key: flag_ending_fail, value: true }
next: null

dialog_id: dialog_e018_fail_purged
speaker: narrator
loc_key: dialog.e018.fail.purged
text_zh: |
  栽赃、送客、离津。码头的汽笛响着，你上了南下的船，怀里那点盘缠薄得可怜，连回头看一眼的资格都没有。

  天津卫的雨，洗不掉一个被清除的人。
effects:
  - { op: set_flag, key: flag_ending_fail, value: true }
next: null

dialog_id: dialog_e018_fail_liu
speaker: narrator
loc_key: dialog.e018.fail.liu
text_zh: |
  枕边风翻了面。钱子安拿到了你的把柄，如烟进了钱家侧门。

  你站在纺纱厂门口，厂里的女工低头走过，没有人叫你的名字。办不起的婚事，到头来连个空日子都没剩下。
effects:
  - { op: set_flag, key: flag_ending_fail, value: true }
next: null

dialog_id: dialog_e018_fail_stats
speaker: narrator
loc_key: dialog.e018.fail.stats
text_zh: |
  嫌疑压垮了信任，或信任被你自己磨穿。钱德茂不必再找借口——你在商行已无立足之地，手里的银子也不够再撑几回体面。

  光绪十六年的秋天，暗潮没有托起你，只把你拍在岸上。
effects:
  - { op: set_flag, key: flag_ending_fail, value: true }
next: null
```
