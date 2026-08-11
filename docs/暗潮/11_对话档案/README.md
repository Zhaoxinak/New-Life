# 11 · 对话档案

> 规范：[`../00_总纲/对话规范.md`](../00_总纲/对话规范.md)  
> **已迁出的事件以本目录为准**；总源 V3 仅作对照。

## 主线 E001–E018

| 文件 | 入口 | 事件 |
|---|---|---|
| [DIALOG_E001.md](DIALOG_E001.md) | `dialog_e001_start` | 开场与老板考校 |
| [DIALOG_E002.md](DIALOG_E002.md) | `dialog_e002_start` | 未婚妻来访 |
| [DIALOG_E003.md](DIALOG_E003.md) | `dialog_e003_start` | 货单异常 |
| [DIALOG_E004.md](DIALOG_E004.md) | `dialog_e004_start` | 少爷驾到 |
| [DIALOG_E005.md](DIALOG_E005.md) | `dialog_e005_start` | 暮色初见 |
| [DIALOG_E006.md](DIALOG_E006.md) | `dialog_e006_start` | 升职搁置 |
| [DIALOG_E007.md](DIALOG_E007.md) | `dialog_e007_start` | 第一次考察 |
| [DIALOG_E008.md](DIALOG_E008.md) | `dialog_e008_start` | 纳妾风波 |
| [DIALOG_E009.md](DIALOG_E009.md) | `dialog_e009_start` | 抉择时刻 |
| [DIALOG_E010.md](DIALOG_E010.md) | `dialog_e010_start` | 深夜可疑货物 |
| [DIALOG_E010b.md](DIALOG_E010b.md) | `dialog_e010b_start` | 深夜可疑货物（推迟重入） |
| [DIALOG_E011.md](DIALOG_E011.md) | `dialog_e011_start` | 第二次考察 |
| [DIALOG_E012.md](DIALOG_E012.md) | `dialog_e012_start` | 利用柳如烟 |
| [DIALOG_E013.md](DIALOG_E013.md) | `dialog_e013_start` | 账房密账 |
| [DIALOG_E014.md](DIALOG_E014.md) | `dialog_e014_start` | 钱子安的鲁莽 |
| [DIALOG_E015.md](DIALOG_E015.md) | `dialog_e015_start` | 真相大白 |
| [DIALOG_E016.md](DIALOG_E016.md) | `dialog_e016_start` | 挑拨父子 |
| [DIALOG_E017.md](DIALOG_E017.md) | `dialog_e017_start` | 向洋人递刀 |
| [DIALOG_E018.md](DIALOG_E018.md) | `dialog_e018_start` | 阶段性结局 |

## 随机 R001–R009

| 文件 | 入口 | 事件 |
|---|---|---|
| [DIALOG_R001.md](DIALOG_R001.md) | `dialog_r001_start` | 茶楼消息 |
| [DIALOG_R002.md](DIALOG_R002.md) | `dialog_r002_start` | 师兄报信 |
| [DIALOG_R003.md](DIALOG_R003.md) | `dialog_r003_start` | 钱子安发难 |
| [DIALOG_R004.md](DIALOG_R004.md) | `dialog_r004_start` | 柳如烟哭诉 |
| [DIALOG_R005.md](DIALOG_R005.md) | `dialog_r005_start` | 聚丰行接触 |
| [DIALOG_R006.md](DIALOG_R006.md) | `dialog_r006_start` | 钱庄邀约 |
| [DIALOG_R007.md](DIALOG_R007.md) | `dialog_r007_start` | 被监视 |
| [DIALOG_R008.md](DIALOG_R008.md) | `dialog_r008_start` | 伙计私语 |
| [DIALOG_R009.md](DIALOG_R009.md) | `dialog_r009_start` | 洋行邀约 |

## 失败 F001–F005

| 文件 | 入口 | 事件 |
|---|---|---|
| [DIALOG_F001.md](DIALOG_F001.md) | `dialog_f001_start` | 被敲打 |
| [DIALOG_F002.md](DIALOG_F002.md) | `dialog_f002_start` | 被降职 |
| [DIALOG_F003.md](DIALOG_F003.md) | `dialog_f003_start` | 被开除 |
| [DIALOG_F004.md](DIALOG_F004.md) | `dialog_f004_start` | 柳如烟反水 |
| [DIALOG_F005.md](DIALOG_F005.md) | `dialog_f005_start` | 钱德茂清除 |

## 日常行动口风池

| 文件 | 入口 | 说明 |
|---|---|---|
| [DIALOG_ACT_POOL.md](DIALOG_ACT_POOL.md) | `dialog_act_*_outro_*` | ACT_01–12 可重复 outro；`act_11` 含菜单 |

## 迁移优先级（剩余）

| 优先级 | 内容 | 说明 |
|---|---|---|
| — | 机器可读导出 | YAML/JSON schema（实现期） |

## 文件约定

- 主线：`DIALOG_E0XX.md` · 随机：`DIALOG_R0XX.md` · 失败：`DIALOG_F0XX.md`
- 节点含 `loc_key` + 设计期 `text_zh`
- 冲突时以对话文件 + effect 词汇表为准
- 检定 / 多结局 / 无分支规则见 [`../00_总纲/对话规范.md`](../00_总纲/对话规范.md)
