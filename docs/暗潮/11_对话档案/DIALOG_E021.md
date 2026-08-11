# 对话 · E021 轻清算

> 入口：`dialog_e021_start` · 事件 [`../07_事件档案/主线/E021_轻清算.md`](../07_事件档案/主线/E021_轻清算.md)  
> 四拍：闪回 → 称呼 → 站位 → 看客 → 失态
> 分支结算以事件文件为准；本文件只保留目标路由、分支选择和演出文本。

```
dialog_e021_start
  → next_by_condition
       ├─ onlooker → choice_onlooker (A罚/B恕)
       └─ slight → choice_slight (A罚/B恕)
```

```yaml
dialog_id: dialog_e021_start
event_id: E021
speaker: narrator
loc_key: dialog.e021.start
text_zh: |
  外场的位子坐了几天，前堂的空气已经不一样了。
  有笔旧账，今天适合当众了结——或者当众按住。
tags: [mainline, reckoning]
next_by_condition:
  - id: onlooker
    require: [{ grudge: grudge_onlooker, status: open }]
    next: dialog_e021_flash_onlooker
  - id: slight
    require: [{ grudge: grudge_zian_slight, status: open }]
    next: dialog_e021_flash_slight
  - id: none
    next: dialog_e021_skip

dialog_id: dialog_e021_skip
speaker: narrator
loc_key: dialog.e021.skip
text_zh: |
  账本翻开，却没有到期的条目。你把袖口放下——不是时候。
next: null

# —— 看客线 ——
dialog_id: dialog_e021_flash_onlooker
speaker: narrator
loc_key: dialog.grudge.onlooker.flash
text_zh: |
  （闪回）那天他们跟着起哄，笑你像条跟在少爷脚后跟的狗。
next: dialog_e021_onlooker_setup

dialog_id: dialog_e021_onlooker_setup
speaker: narrator
loc_key: dialog.e021.onlooker.setup
text_zh: |
  那几个爱传闲话的人又聚在货箱边。你走过去时，有人下意识让出半步——有人还没习惯叫你「林外场」。
next: dialog_e021_onlooker_choice

dialog_id: dialog_e021_onlooker_choice
speaker: narrator
loc_key: dialog.e021.onlooker.choice
text_zh: |
  （你怎么做？）
tags: [choice]
choices:
  - id: A
    loc_key: dialog.e021.onlooker.a
    text_zh: 惩罚——当众斥回，调开闲差
    next: dialog_e021_onlooker_punish
  - id: B
    loc_key: dialog.e021.onlooker.b
    text_zh: 宽恕——压着他们，收为眼线
    next: dialog_e021_onlooker_forgive

dialog_id: dialog_e021_onlooker_punish
speaker: narrator
loc_key: dialog.e021.onlooker.punish
text_zh: |
  你把话摔在明处。笑声死了。有人脸红到耳根，被派去搬最沉的箱。
  下层伙计看你的眼神齐了——这回是怕，也是服。
next: null

dialog_id: dialog_e021_onlooker_forgive
speaker: narrator
loc_key: dialog.e021.onlooker.forgive
text_zh: |
  你本可以让他们当场丢脸。你只淡淡一句：过去的事，我记下了；以后嘴严点，有你们的好处。
  他们诺诺连声。怕比恨更听话。
next: null

# —— 子安轻线 ——
dialog_id: dialog_e021_flash_slight
speaker: narrator
loc_key: dialog.grudge.zian_slight.flash
text_zh: |
  （闪回）他的目光在你脸上停半息，又滑开，像扫过一件不值钱的货。
next: dialog_e021_slight_setup

dialog_id: dialog_e021_slight_setup
speaker: narrator
loc_key: dialog.e021.slight.setup
text_zh: |
  钱子安今日又在前堂指手画脚。你站在外场该站的位置上——比他想象的更靠中间。
next: dialog_e021_slight_choice

dialog_id: dialog_e021_slight_choice
speaker: narrator
loc_key: dialog.e021.slight.choice
text_zh: |
  （你怎么做？）
tags: [choice]
choices:
  - id: A
    loc_key: dialog.e021.slight.a
    text_zh: 惩罚——当众纠正差事口径
    next: dialog_e021_slight_punish
  - id: B
    loc_key: dialog.e021.slight.b
    text_zh: 宽恕——压着他，当众放过
    next: dialog_e021_slight_forgive

dialog_id: dialog_e021_slight_punish
speaker: narrator
loc_key: dialog.e021.slight.punish
text_zh: |
  你把货单数字报准，把他的胡话当场钉死。看客吸凉气。少爷耳根发青，甩袖走了。
next: null

dialog_id: dialog_e021_slight_forgive
speaker: narrator
loc_key: dialog.e021.slight.forgive
text_zh: |
  你本可以让他当众出丑。你只抬手止住伙计的笑，道：少爷初来，口径生疏，我改就是。
  他盯着你，像恨，又像第一次认真打量你。
next: null
```
