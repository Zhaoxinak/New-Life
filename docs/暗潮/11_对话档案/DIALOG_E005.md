# 对话 · E005 暮色初见

> 入口：`dialog_e005_start` · 事件 [`../07_事件档案/主线/E005_暮色初见.md`](../07_事件档案/主线/E005_暮色初见.md)  
> 启用 `meter.pursuit`。

---

## 节点图

```
dialog_e005_start
  → dialog_e005_notice
  → dialog_e005_zian_ask
  → dialog_e005_retainer
  → dialog_e005_zian_hook  # effects → END
```

---

## Nodes

```yaml
dialog_id: dialog_e005_start
event_id: E005
speaker: narrator
loc_key: dialog.e005.start
text_zh: |
  黄昏时分，柳如烟下了纺纱厂的工，提着饭盒来商行门口等林瑞生一起回家。林瑞生正好忙完手头的活，两人并肩往华界走，暮色里拢着头发，低着头说话，笑得很小声。
tags: [mainline]
next: dialog_e005_notice

dialog_id: dialog_e005_notice
speaker: narrator
loc_key: dialog.e005.notice
text_zh: |
  钱子安从茶楼晃回来，恰好在街对面看见这一幕。他的脚步顿住了。
next: dialog_e005_zian_ask

dialog_id: dialog_e005_zian_ask
speaker: char_qian_zian
loc_key: dialog.e005.zian_ask
text_zh: |
  刚才跟林瑞生一块儿走的那丫头，谁？
next: dialog_e005_retainer

dialog_id: dialog_e005_retainer
speaker: narrator
loc_key: dialog.e005.retainer
text_zh: |
  「回少爷，纺纱厂的女工，好像叫柳如烟。听说跟林师兄定了亲的。」随从低声答。
next: dialog_e005_zian_hook

dialog_id: dialog_e005_zian_hook
speaker: char_qian_zian
loc_key: dialog.e005.zian_hook
text_zh: |
  定了亲？……打听打听，住哪儿。
effects:
  - { op: add, meter: pursuit, value: 5 }  # 初见即起意；非空 set 0
  - { op: set_flag, key: flag_zian_notices_liu, value: true }
  - { op: add, edge: {from: char_qian_zian, to: char_liu_ruyan}, key: score, value: 5 }
next: null
```
