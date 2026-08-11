# 对话 · E001 开场与老板考校

> 入口：`dialog_e001_start` · 事件 [`../07_事件档案/主线/E001_开场与老板考校.md`](../07_事件档案/主线/E001_开场与老板考校.md)  
> 含场景 1-1 开场旁白 + 1-2 老板考校（无分支选项）。

---

## 节点图

```
dialog_e001_start          # 开场旁白
  → dialog_e001_exam_q1
  → dialog_e001_exam_a1
  → dialog_e001_exam_q2
  → dialog_e001_exam_a2
  → dialog_e001_exam_praise
  → dialog_e001_exam_hedge
  → dialog_e001_exam_ack
  → dialog_e001_exam_close  # effects → END
```

---

## Nodes

### `dialog_e001_start`

```yaml
dialog_id: dialog_e001_start
event_id: E001
speaker: narrator
loc_key: dialog.e001.start
text_zh: |
  光绪十六年，天津。

  紫竹林洋行的汽笛声日日不断，码头上的苦力弯腰扛起一包又一包的洋货。租界里是另一重天地——洋楼、花园、马车，和华界的破巷子隔着一道墙，像隔着一辈子。

  天津卫的买卖人，有句老话——"冰炭不同炉，清浊不同器"。可在这座通商口岸，清浊早就搅在一处了。码头上扛的、账本上写的，未必是招牌上的那一行字。

  你叫林瑞生，钱记商行的学徒。三年了，起早贪黑，就等着满师那天，当上跑街，娶了如烟，安安稳稳过日子。

  可这天底下，从来就没有"安稳"二字。
tags: [mainline, opening]
next: dialog_e001_exam_q1
```

### 考校链

```yaml
dialog_id: dialog_e001_exam_q1
speaker: char_qian_demao
loc_key: dialog.e001.exam.q1
text_zh: |
  这批南洋柚木，到岸价多少？
next: dialog_e001_exam_a1

dialog_id: dialog_e001_exam_a1
speaker: char_lin_ruisheng
loc_key: dialog.e001.exam.a1
text_zh: |
  回东家，到岸价每方三两七。
next: dialog_e001_exam_q2

dialog_id: dialog_e001_exam_q2
speaker: char_qian_demao
loc_key: dialog.e001.exam.q2
text_zh: |
  市价呢？
next: dialog_e001_exam_a2

dialog_id: dialog_e001_exam_a2
speaker: char_lin_ruisheng
loc_key: dialog.e001.exam.a2
text_zh: |
  眼下天津行价四两二。不过聚丰行刚放了一批货，估摸三日内会跌到四两。
next: dialog_e001_exam_praise

dialog_id: dialog_e001_exam_praise
speaker: char_qian_demao
loc_key: dialog.e001.exam.praise
text_zh: |
  不错。账上的数目你记得比我还清楚。
next: dialog_e001_exam_hedge

dialog_id: dialog_e001_exam_hedge
speaker: char_qian_demao
loc_key: dialog.e001.exam.hedge
text_zh: |
  满师的事，我考虑考虑。跑街这位置，不是光记数字就行的。得懂人情，知进退。
next: dialog_e001_exam_ack

dialog_id: dialog_e001_exam_ack
speaker: char_lin_ruisheng
loc_key: dialog.e001.exam.ack
text_zh: |
  是，东家。
next: dialog_e001_exam_close

dialog_id: dialog_e001_exam_close
speaker: char_qian_demao
loc_key: dialog.e001.exam.close
text_zh: |
  年轻人，路要一步一步走。
effects:
  - { op: add, edge: {from: char_qian_demao, to: char_lin_ruisheng}, key: score, value: 8 }
  - { op: add, key: stat_trust_firm, value: 5 }
next: null
```
