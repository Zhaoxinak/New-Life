# 对话 · E002 未婚妻来访

> 入口：`dialog_e002_start` · 事件 [`../07_事件档案/主线/E002_未婚妻来访.md`](../07_事件档案/主线/E002_未婚妻来访.md)

---

## 节点图

```
dialog_e002_start
  → dialog_e002_lin_ask
  → dialog_e002_liu_busy
  → dialog_e002_lin_say
  → dialog_e002_liu_wedding
  → dialog_e002_lin_promise
  → dialog_e002_liu_bright
  → dialog_e002_lin_wait
  → dialog_e002_liu_ok   # effects → END
```

---

## Nodes

```yaml
dialog_id: dialog_e002_start
event_id: E002
speaker: char_liu_ruyan
loc_key: dialog.e002.start
text_zh: |
  瑞生，今天蒸了你爱吃的糖三角。
tags: [mainline]
next: dialog_e002_lin_ask

dialog_id: dialog_e002_lin_ask
speaker: char_lin_ruisheng
loc_key: dialog.e002.lin_ask
text_zh: |
  又跑这一趟。厂里不忙？
next: dialog_e002_liu_busy

dialog_id: dialog_e002_liu_busy
speaker: char_liu_ruyan
loc_key: dialog.e002.liu_busy
text_zh: |
  忙完了。我……我跟你说个事。
next: dialog_e002_lin_say

dialog_id: dialog_e002_lin_say
speaker: char_lin_ruisheng
loc_key: dialog.e002.lin_say
text_zh: |
  说。
next: dialog_e002_liu_wedding

dialog_id: dialog_e002_liu_wedding
speaker: char_liu_ruyan
loc_key: dialog.e002.liu_wedding
text_zh: |
  咱们……什么时候能办喜事？厂里的姐妹都问呢。娘前两天还说，聘礼可以慢慢凑，屋里的箱笼总得先备起来。
next: dialog_e002_lin_promise

dialog_id: dialog_e002_lin_promise
speaker: char_lin_ruisheng
loc_key: dialog.e002.lin_promise
text_zh: |
  快了。等东家给我满师，当了跑街，一个月多拿二两银子，再攒两三个月，把聘礼、铺盖、酒席钱凑得像样些，到时候就办。
next: dialog_e002_liu_bright

dialog_id: dialog_e002_liu_bright
speaker: char_liu_ruyan
loc_key: dialog.e002.liu_bright
text_zh: |
  真的？
next: dialog_e002_lin_wait

dialog_id: dialog_e002_lin_wait
speaker: char_lin_ruisheng
loc_key: dialog.e002.lin_wait
text_zh: |
  真的。再等等。我不想叫你空着手进门，连顿像样的席都摆不起。
next: dialog_e002_liu_ok

dialog_id: dialog_e002_liu_ok
speaker: char_liu_ruyan
loc_key: dialog.e002.liu_ok
text_zh: |
  好，我等你。慢一点没事，只要你别总叫我看着个空日子。
effects:
  - { op: add, edge: {from: char_liu_ruyan, to: char_lin_ruisheng}, key: score, value: 10 }
  - { op: set_flag, key: flag_need_marriage_fund, value: true }
next: null
```
