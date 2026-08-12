# 事件档案索引

## 主线 E

| ID | 文件 | 建议日程 | 时段 |
|---|---|---|---|
| E001 | [E001_开场与老板考校.md](主线/E001_开场与老板考校.md) | 章一 D1 | morning → M001 |
| M001 | [M001_首次旁听朝账.md](朝账/M001_首次旁听朝账.md) | 章一 D1 | morning |
| E002 | [E002_未婚妻来访.md](主线/E002_未婚妻来访.md) | 章一 D2 | evening |
| E003 | [E003_货单异常.md](主线/E003_货单异常.md) | 章一 D3 | afternoon |
| E004 | [E004_少爷驾到.md](主线/E004_少爷驾到.md) | 章一 D8 · M002 内嵌 | morning |
| E005 | [E005_暮色初见.md](主线/E005_暮色初见.md) | 章一 D8 | evening |
| E006 | [E006_升职搁置.md](主线/E006_升职搁置.md) | 章一 D8 · M002 内嵌 | morning |
| M002 | [M002_满师朝账.md](朝账/M002_满师朝账.md) | 章一 D8 | morning |
| E007 | [E007_洋行第一次考察.md](主线/E007_洋行第一次考察.md) | 章一 D9 | afternoon |
| E008 | [E008_纳妾风波.md](主线/E008_纳妾风波.md) | 章一 D10 | evening |
| E009 | [E009_复仇抉择.md](主线/E009_复仇抉择.md) | 章一 D11 | late_night |
| E010 | [E010_深夜可疑货物.md](主线/E010_深夜可疑货物.md) | 章二 | late_night |
| E010b | [E010b_深夜可疑货物_推迟.md](主线/E010b_深夜可疑货物_推迟.md) | 章二 | late_night（条件） |
| E011 | [E011_洋行第二次考察.md](主线/E011_洋行第二次考察.md) | 章二 | afternoon |
| E012 | [E012_利用柳如烟.md](主线/E012_利用柳如烟.md) | 章二 | evening |
| E013 | [E013_账房密账.md](主线/E013_账房密账.md) | 章二 | late_night |
| E019 | [E019_密账一用.md](主线/E019_密账一用.md) | 章二 · E013 后 | afternoon |
| E020 | [E020_升任外场.md](主线/E020_升任外场.md) | 章二 D22 · M003 内嵌 | morning |
| M003 | [M003_升外场朝账.md](朝账/M003_升外场朝账.md) | 章二 D22 | morning |
| E020B | [E020B_聚丰报价.md](主线/E020B_聚丰报价.md) | 章二中后 · B线主爽 | afternoon |
| E020C | [E020C_洋行门路.md](主线/E020C_洋行门路.md) | 章二中后 · C线主爽 | afternoon |
| E021 | [E021_轻清算.md](主线/E021_轻清算.md) | 章二 · E020 后 | afternoon |
| E021B | [E021B_轻清算_街市.md](主线/E021B_轻清算_街市.md) | 章二 · E020B 后 | afternoon |
| E021C | [E021C_轻清算_借势.md](主线/E021C_轻清算_借势.md) | 章二 · E020C 后 | afternoon |
| E014 | [E014_钱子安的鲁莽.md](主线/E014_钱子安的鲁莽.md) | 章三 | afternoon |
| E015 | [E015_真相大白.md](主线/E015_真相大白.md) | 章三 | late_night |
| E016 | [E016_挑拨父子.md](主线/E016_挑拨父子.md) | 章三 | afternoon |
| E017 | [E017_向洋人递刀.md](主线/E017_向洋人递刀.md) | 章三 | evening |
| E022 | [E022_清算子安.md](主线/E022_清算子安.md) | 章三末 | afternoon |
| E022B | [E022B_清算子安_截胡.md](主线/E022B_清算子安_截胡.md) | 章三末 · B线主爽 | afternoon |
| E022C | [E022C_清算子安_借势.md](主线/E022C_清算子安_借势.md) | 章三末 · C线主爽 | afternoon |
| E018 | [E018_阶段性结局.md](主线/E018_阶段性结局.md) | 章终 | morning |

日期权威：[`../09_日程表/日历总表.md`](../09_日程表/日历总表.md)（开放日程，不锁 30 日）。

## 朝账 M

见 [`朝账/`](朝账/)：M001–M003。规则：[`../17_朝账系统/`](../17_朝账系统/README.md)。

## 随机 R

见 [`随机/`](随机/)：R001–R010

| ID | 地点 | 时段 | 关键 require |
|---|---|---|---|
| R001 | `loc_03` | evening | money≥5 |
| R002 | `loc_02` | noon–evening | 王→林 相善+ score≥40 |
| R003 | `loc_01` | morning–afternoon | 子安→林 仇隙/不睦；加深 `grudge_zian_slight` |
| R004 | `loc_06` | evening | 柳→林 相善+ pursuit≥30 |
| R005 | `loc_03` | noon–evening | network≥20 |
| R006 | `loc_04` | morning, noon | money≥50 |
| R007 | `loc_02` | noon–late_night | 钱→林 疑心≥2 |
| R008 | `loc_02` | noon, afternoon | trust_firm≥40 |
| R009 | `loc_03` | afternoon, evening | impression_bradley≥20 + route_foreign |
| R009 会谈 | `loc_05` | morning–afternoon | `flag_bradley_invite` / E018C |
| R010 | `loc_01` | morning–afternoon | 埋 `grudge_onlooker` |

## 失败 F

见 [`失败/`](失败/)：F001–F005

## 实现辅助

- [`事件互斥矩阵.md`](事件互斥矩阵.md)：章二/章三分轨主爽三选一规则

## 写法

每个事件文件含：触发 · 摘要 · 选项 effect YAML · **对话入口**。  
演出对白以 [`../11_对话档案/`](../11_对话档案/README.md) 为准。  
总源 V3 仅作历史对照：[`../_archive/暗潮_游戏设定与剧本_V3.md`](../_archive/暗潮_游戏设定与剧本_V3.md)。

升阶 / 清算事件须遵守：[`../13_职级档案/职级阶梯.md`](../13_职级档案/职级阶梯.md) · [`../14_清算与爽点档案/暗潮阶段爽点映射.md`](../14_清算与爽点档案/暗潮阶段爽点映射.md) · [`../05_关系档案/恩怨账与清算.md`](../05_关系档案/恩怨账与清算.md) · 升阶四件套检查表见 [`../10_路线与结局/阶段爽点与职级阶梯.md`](../10_路线与结局/阶段爽点与职级阶梯.md)。  
若要直接看职级推进链：[`../13_职级档案/暗潮职级推进映射.md`](../13_职级档案/暗潮职级推进映射.md)。

### Effect 交情约定（v0.2）

```yaml
# 改交情分（权威）→ 运行时重算五档
- { op: add, edge: {from: char_x, to: char_y}, key: score, value: 10 }

# 改修正
- { op: add, edge: {from: char_x, to: char_y}, key: suspicion, value: 1 }

# 改玩法计量（不替代交情）
- { op: add, meter: father_son, value: -25 }
- { op: add, meter: pursuit, value: 5 }
- { op: add, meter: impression_bradley, value: 10 }

# 职级 / 恩怨
- { op: set_rank, value: waichang }
- { op: unlock_grudge, id: grudge_zian_fiancee }
- { op: resolve_grudge, id: grudge_onlooker, mode: punish }
```

禁止再写「好感度+N」或 `attitude.favor`；一律用 `edge.score` / `meter.*`。
