# 事件档案索引

## 主线 E

| ID | 文件 | Day | 时段 |
|---|---|---|---|
| E001 | [E001_开场与老板考校.md](主线/E001_开场与老板考校.md) | 1 | morning |
| E002 | [E002_未婚妻来访.md](主线/E002_未婚妻来访.md) | 2 | evening |
| E003 | [E003_货单异常.md](主线/E003_货单异常.md) | 3 | afternoon |
| E004 | [E004_少爷驾到.md](主线/E004_少爷驾到.md) | 4 | morning |
| E005 | [E005_暮色初见.md](主线/E005_暮色初见.md) | 4 | evening |
| E006 | [E006_升职搁置.md](主线/E006_升职搁置.md) | 5 | morning |
| E007 | [E007_洋行第一次考察.md](主线/E007_洋行第一次考察.md) | 5 | afternoon |
| E008 | [E008_纳妾风波.md](主线/E008_纳妾风波.md) | 6 | evening |
| E009 | [E009_复仇抉择.md](主线/E009_复仇抉择.md) | 7 | late_night |
| E010 | [E010_深夜可疑货物.md](主线/E010_深夜可疑货物.md) | 10 | late_night |
| E011 | [E011_洋行第二次考察.md](主线/E011_洋行第二次考察.md) | 12 | afternoon |
| E012 | [E012_利用柳如烟.md](主线/E012_利用柳如烟.md) | 12 | evening |
| E013 | [E013_账房密账.md](主线/E013_账房密账.md) | 15 | late_night |
| E014 | [E014_钱子安的鲁莽.md](主线/E014_钱子安的鲁莽.md) | 16 | afternoon |
| E015 | [E015_真相大白.md](主线/E015_真相大白.md) | 19 | late_night |
| E016 | [E016_挑拨父子.md](主线/E016_挑拨父子.md) | 20 | afternoon |
| E017 | [E017_向洋人递刀.md](主线/E017_向洋人递刀.md) | 20-22 | evening |
| E018 | [E018_阶段性结局.md](主线/E018_阶段性结局.md) | 30 | morning |
| E010b | [E010b_深夜可疑货物_推迟.md](主线/E010b_深夜可疑货物_推迟.md) | 13 | late_night（条件） |

## 随机 R

见 [`随机/`](随机/)：R001–R009

| ID | 地点 | 时段 | 关键 require |
|---|---|---|---|
| R001 | `loc_03` | evening | money≥5 |
| R002 | `loc_02` | noon–evening | 王→林 相善+ score≥40 |
| R003 | `loc_01` | morning–afternoon | 子安→林 仇隙/不睦 |
| R004 | `loc_06` | evening | 柳→林 相善+ pursuit≥30 |
| R005 | `loc_03` | noon–evening | network≥20 |
| R006 | `loc_04` | morning, noon | money≥50 |
| R007 | `loc_02` | noon–late_night | 钱→林 疑心≥2 |
| R008 | `loc_02` | noon, afternoon | trust_firm≥40 |
| R009 | `loc_03` | afternoon, evening | impression_bradley≥20 + route_foreign |
| R009 会谈 | `loc_05` | morning–afternoon | `flag_bradley_invite` / E018C |

## 失败 F

见 [`失败/`](失败/)：F001–F005

## 写法

每个事件文件含：触发 · 摘要 · 选项 effect YAML · **对话入口**。  
演出对白以 [`../11_对话档案/`](../11_对话档案/README.md) 为准；总源 V3 仅对照。

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
```

禁止再写「好感度+N」或 `attitude.favor`；一律用 `edge.score` / `meter.*`。
