# 对话 · E006 升职搁置

> 入口：`dialog_e006_start` · 事件 [`../07_事件档案/主线/E006_升职搁置.md`](../07_事件档案/主线/E006_升职搁置.md)

---

## 节点图

```
dialog_e006_start
  → dialog_e006_narr
  → dialog_e006_zian
  → dialog_e006_lin
  → dialog_e006_aside
  → dialog_e006_qian_soft  # effects → END
```

---

## Nodes

```yaml
dialog_id: dialog_e006_start
event_id: E006
speaker: char_qian_demao
loc_key: dialog.e006.start
text_zh: |
  子安刚从北京来，对天津的买卖不熟。瑞生啊，跑街的事暂缓一缓，你先带子安到处走走，帮他认认门路。
tags: [mainline]
next: dialog_e006_narr

dialog_id: dialog_e006_narr
speaker: narrator
loc_key: dialog.e006.narr
text_zh: |
  满师的升职，被一句话搁置了——东家的意思很明白：先伺候好少爷，别的以后再说。
  跑街的位置不只是名头。月例、外出办事的油水、在街面上抬头说话的体面，都跟着一起往后挪了。
next: dialog_e006_zian

dialog_id: dialog_e006_zian
speaker: char_qian_zian
loc_key: dialog.e006.zian
text_zh: |
  林师兄，多关照啊。
next: dialog_e006_lin

dialog_id: dialog_e006_lin
speaker: char_lin_ruisheng
loc_key: dialog.e006.lin
text_zh: |
  少爷客气。
next: dialog_e006_aside

dialog_id: dialog_e006_aside
speaker: narrator
loc_key: dialog.e006.aside
text_zh: |
  散场后，钱德茂把林瑞生单独叫到一旁。
next: dialog_e006_qian_soft

dialog_id: dialog_e006_qian_soft
speaker: char_qian_demao
loc_key: dialog.e006.qian_soft
text_zh: |
  年轻人，要沉得住气。子安刚来天津，人生地不熟的，你多费心照应。跑街的位置，等子安安顿好了，迟早是你的。
  差事办稳了，月例、赏钱，都不会亏你。
effects:
  - { op: add, key: stat_trust_firm, value: -10 }
  - { op: add, edge: {from: char_lin_ruisheng, to: char_qian_demao}, key: score, value: -10 }
next: null
```
