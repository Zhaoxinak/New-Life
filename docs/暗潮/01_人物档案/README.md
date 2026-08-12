# 人物档案索引

> **字段必须统一**：见 [`_模板.md`](_模板.md)。缺项用 `—` / `0` / `无` / `未知`，**不删行**。  
> 新角色：复制 `_模板.md` → 改名填表 → 本索引加一行 → 关系开局表补边。

## 怎么扩展

| 步骤 | 做啥 |
|---|---|
| 1 | 复制 `_模板.md` 为 `姓名.md` |
| 2 | 填 §1～§8，`id` 用 `char_蛇形` |
| 3 | 在 [`../05_关系档案/关系开局表.md`](../05_关系档案/关系开局表.md) 补双向边 |
| 4 | 有纽带则写入 [`../05_关系档案/社会纽带.md`](../05_关系档案/社会纽带.md) |
| 5 | 本索引卡司表加一行 |

## 卡司

| ID | 文件 | 一句话钩子 | Demo |
|---|---|---|---|
| `char_lin_ruisheng` | [林瑞生.md](林瑞生.md) | 玩家 · 学徒满师被搁置后复仇 | P0 |
| `char_qian_demao` | [钱德茂.md](钱德茂.md) | 东家 · 白手套 · 疑心可杀 | P0 |
| `char_qian_zian` | [钱子安.md](钱子安.md) | 纨绔独子 · 纳妾与截货 | P0 |
| `char_liu_ruyan` | [柳如烟.md](柳如烟.md) | 未婚妻 · 情感锚 / 情报 / 反水 | P0 |
| `char_zhao_hongyun` | [赵鸿运.md](赵鸿运.md) | 聚丰掌柜 · 跳槽反戈 | P0 |
| `char_wang_pangzi` | [王胖子.md](王胖子.md) | 师兄 · 低阶情报与钥匙 | P0 |
| `char_bradley` | [白瑞德.md](白瑞德.md) | 宝顺代表 · 洋人评估 | P0 |
| `char_qing_daren` | [庆大人.md](庆大人.md) | 幕后京官 · Demo 不出场 | P0 |
| `char_zhou_guanshi` | [周管事.md](周管事.md) | 庆系接引人 · 印象通道 | P1 |
| `char_apprentice_xiao_chen` | [小陈.md](小陈.md) | 学徒池 · 勤快劲敌 | P2 |
| `char_apprentice_xiao_liu` | [小刘.md](小刘.md) | 学徒池 · 偷懒对手 | P2 |
| `char_apprentice_a_fu` | [阿福.md](阿福.md) | 学徒池 · 陪跑 | P2 |
| `char_apprentice_sun_liu` | [孙六.md](孙六.md) | 学徒池 · 拍马蹿升 | P2 |
| `char_li_waichang` | [李外场.md](李外场.md) | 外场池 · 实干 | P2 |
| `char_zhao_waichang` | [赵外场.md](赵外场.md) | 外场池 · 媚上 | P2 |

## 关系字段（运行时 · 全员同一套）

权威：[`../05_关系档案/`](../05_关系档案/README.md)。

| 字段 | 含义 |
|---|---|
| `score` / `tier` | 交情分 → 五档 |
| `trust` / `suspicion` / `fear` | 修正 |
| `debt` / `leverage` | 债 / 把柄 |
| `bonds[]` | 社会纽带 |
| `meters{}` | 玩法计量 |
