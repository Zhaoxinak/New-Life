# 对话 · M002 满师朝账

> 入口：`dialog_m002_start` · 事件 [`../07_事件档案/朝账/M002_满师朝账.md`](../07_事件档案/朝账/M002_满师朝账.md)  
> 内嵌：E004（①）、E006（③）。E 对白全文仍以 [`DIALOG_E004.md`](DIALOG_E004.md)、[`DIALOG_E006.md`](DIALOG_E006.md) 为准。

---

## 节点图

```
dialog_m002_start
  → dialog_m002_zhou_rollcall    # ① 朝账开门
  → dialog_e004_start            # E004 少爷驾到（堂内）
  → dialog_m002_report_zian      # ② 子安敷衍汇报
  → dialog_m002_player_named     # 门外被点名
  → dialog_e006_start            # E006 搁置满师（③）
  → dialog_m002_ladder_read      # ②末：学徒/跑街池序播报
  → dialog_m002_council_zian     # ④ 子安建言摆排场
  → dialog_m002_council_zhou_pass # ④ 周管事不语
  → dialog_m002_council_wang     # ④ 王胖子稳明面
  → dialog_m002_policy_son       # ⑤ 先安顿少爷
  → dialog_m002_task_humiliate   # ⑥ 羞辱性差事
  → dialog_m002_close
```

---

## Nodes（M002 独有）

### `dialog_m002_start`

```yaml
speaker: narrator
text_zh: |
  第七日一早，前堂比平日更早开了门。你照旧站在门帘外，手里是一壶续不满的热茶。
next: dialog_m002_zhou_rollcall
```

### `dialog_m002_player_named`

```yaml
speaker: char_qian_demao
text_zh: |
  门帘外那个——瑞生，满师三年，货价行情你答得上来。堂里的事，你听着。
next: dialog_e006_start
```

### `dialog_m002_ladder_read`

```yaml
speaker: char_zhou_guanshi
text_zh: |
  本周序：少爷钱子安第一，林瑞生第二。满师名册，东家已有话。
tags: [meeting, ladder]
effects:
  - { op: bias_ladder_npc, char: char_qian_zian, value: 12 }
  - { op: add_ladder_score, char: char_lin_ruisheng, value: -5 }
next: dialog_m002_council_zian
```

### `dialog_m002_council_zian`

```yaml
speaker: char_qian_zian
text_zh: |
  我看街面上要摆排场，别老抠那几两银子。钱记的脸面，不能比聚丰矮一截。
tags: [meeting, council]
effects:
  - { op: add_policy_draft, key: son_first, value: 3 }
next: dialog_m002_council_zhou_pass
```

### `dialog_m002_council_zhou_pass`

```yaml
speaker: narrator
text_zh: |
  周管事目光一扫，竟没开口。门帘外的人只听见茶碗轻轻一响。
next: dialog_m002_council_wang
```

### `dialog_m002_council_wang`

```yaml
speaker: char_wang_pangzi
text_zh: |
  前堂人手紧，货单先理清楚，比扩门面稳当。
effects:
  - { op: add_policy_draft, key: bright_steady, value: 1 }
next: dialog_m002_policy_son
```

### `dialog_m002_policy_son`

```yaml
speaker: char_qian_demao
text_zh: |
  排场的事，等子安先站稳了再说。这周，先把少爷那边安顿好。
next: dialog_m002_task_humiliate
```

### `dialog_m002_task_humiliate`

```yaml
speaker: char_qian_demao
text_zh: |
  瑞生，这周先把少爷那边招呼好。堂上的位子，等他能坐稳了再说。
next: dialog_m002_close
```

### `dialog_m002_close`

```yaml
speaker: narrator
text_zh: |
  满师的名册上，你的名字被轻轻搁到了「以后再说」。门帘外的人听得一清二楚。
next: null
```

---

## 实现备注

- `dialog_e004_*` / `dialog_e006_*` 的 `effects` 在 E006 关闭链末执行，M002 不重复写。  
- ⑤ 定调选 `son_first`（子安建言权重高），压过王胖子 `bright_steady`，体现东家偏心。
