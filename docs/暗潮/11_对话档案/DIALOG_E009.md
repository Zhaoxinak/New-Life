# 对话 · E009 抉择时刻

> 入口：`dialog_e009_start` · 事件 [`../07_事件档案/主线/E009_复仇抉择.md`](../07_事件档案/主线/E009_复仇抉择.md)  
> 文案暂内嵌 `text_zh`；实现期抽到 `def_loc_string`。

---

## 节点图

```
dialog_e009_start
  → dialog_e009_monologue
  → dialog_e009_choice
       ├─ A → dialog_e009_outro_a → END
       ├─ B → dialog_e009_outro_b → END
       └─ C → dialog_e009_outro_c → END
```

---

## Nodes

### `dialog_e009_start`

```yaml
dialog_id: dialog_e009_start
event_id: E009
speaker: narrator
loc_key: dialog.e009.start
text_zh: |
  林瑞生独自坐在小屋里。窗外是天津华界的夜色，远处租界的灯火亮着。
tags: [mainline]
next: dialog_e009_monologue
```

### `dialog_e009_monologue`

```yaml
dialog_id: dialog_e009_monologue
event_id: E009
speaker: narrator
loc_key: dialog.e009.monologue
text_zh: |
  升职没了，未婚妻被人盯上了，东家嘴上说「迟早是你的」，手上却让你去伺候他儿子。
  三天前那个洋人白瑞德来商行考察——他看到东家堆着笑脸招待洋人，心里不是滋味。

  你认了三年师父、起了三年早、扛了三年活，到头来一场空。

  不。不会再空下去了。
tags: [mainline]
next: dialog_e009_choice
```

### `dialog_e009_choice`

```yaml
dialog_id: dialog_e009_choice
event_id: E009
speaker: narrator
loc_key: dialog.e009.choice_prompt
text_zh: |
  灯油快尽了。你把三条路在心里摊开——没有一条干净，但总得选一个下手处。
  （日后仍可混搭；眼下先定方向。）
tags: [mainline, choice]
choices:
  - id: A
    loc_key: dialog.e009.choice.a
    text_zh: 先忍着。留在钱记，把刀子藏进袖子里
    effects:
      - { op: set_flag, key: route_endure, value: true }
      - { op: add, key: stat_trust_firm, value: 5 }
      - { op: add, key: stat_intel, value: 5 }
    next: dialog_e009_outro_a
  - id: B
    loc_key: dialog.e009.choice.b
    text_zh: 另寻东家。聚丰若肯开门，钱记就不是唯一的天
    effects:
      - { op: set_flag, key: route_defect, value: true }
      - { op: add, key: stat_network, value: 10 }
      - { op: add, key: stat_trust_firm, value: -5 }
    next: dialog_e009_outro_b
  - id: C
    loc_key: dialog.e009.choice.c
    text_zh: 借洋人之势。要渠道、要官场——他们缺，你有
    effects:
      - { op: set_flag, key: route_foreign, value: true }
      - { op: add, key: stat_intel, value: 10 }
    next: dialog_e009_outro_c
```

### `dialog_e009_outro_a`

```yaml
dialog_id: dialog_e009_outro_a
speaker: narrator
loc_key: dialog.e009.outro.a
text_zh: |
  你决定留在钱记。表面更勤快，暗中留意每一张货单、每一句闲话。
  如烟……也许不得不卷进来。这笔账，你先记着。
next: null
```

### `dialog_e009_outro_b`

```yaml
dialog_id: dialog_e009_outro_b
speaker: narrator
loc_key: dialog.e009.outro.b
text_zh: |
  聚丰行的赵鸿运一直想挖钱记的墙脚。你手里若有够分量的货情，他会开门——也会开价。
next: null
```

### `dialog_e009_outro_c`

```yaml
dialog_id: dialog_e009_outro_c
speaker: narrator
loc_key: dialog.e009.outro.c
text_zh: |
  洋人要渠道，要官场背景。你要权势。
  白瑞德那天在商行的目光还在眼前。这条路走深了，就不再是「复仇」那么简单——你清楚。
next: null
```
