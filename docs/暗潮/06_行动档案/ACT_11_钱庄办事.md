# 钱庄办事 · `act_11`

| 项 | 内容 |
|---|---|
| id | `act_11` |
| 地点 | `loc_04` |
| 时段 | morning, noon |
| 前置 | stat_money >= 10 |
| 对话入口 | [`DIALOG_ACT_POOL`](../11_对话档案/DIALOG_ACT_POOL.md) · `dialog_act_11_*` |

## 金钱戏

| 项 | 内容 |
|---|---|
| 类型 | 生存钱 + 门路钱 |
| 对谁 | 林瑞生 ↔ 票号柜面 |
| 戏剧 | 十两是“进得了门”；五十两才是“能周转的人”（见 R006、`flag_bank_tier2`）。跳槽线需要周转本钱；隐忍线需要不丢脸；拮据时借贷是饮鸩止渴。 |
| 拿不到 | 急用时只能硬扛；竞品资助、办喜事、打点都缺正规口子 |

### 阈值台词（表现层）

| 条件 | 反馈 |
|---|---|
| `stat_money < 20` | 柜员打量你：“零碎客，借可以，利钱照算。” |
| `10 <= stat_money < 50` | 「票号肯办常规汇兑、小借小还；柜员语气客气，仍把你当过客。」 |
| `stat_money >= 50` | 「自从身子里有了五十两活钱，票号把你记进簿子：‘林掌柜，照旧？’」 |

```yaml
effects:
  - op: menu
    options:
      loan:
        label: 短借
        require: stat_money >= 10
        effects:
          - { op: add, key: stat_money, value: 15 }
          - { op: add, key: stat_suspicion, value: 3 }
          - { op: set_flag, key: flag_bank_loan_active, value: true }
        note: 借十五两应急；日末额外扣息（实现时表，建议 +1/日直至还清）
      remit:
        label: 汇兑 / 办体面
        require: stat_money >= 20
        cost: { op: add, key: stat_money, value: -5 }
        effects:
          - { op: add, key: stat_credit_bank, value: 3 }
          - { op: add, key: meter.impression_qing, value: 2 }
          - { op: clear_flag, key: flag_need_marriage_fund }
        note: 汇银回乡或备体面开销；E002/E008 聘礼压力的叙事出口，也是婚事资金链的首个“缓解口”
      market:
        label: 打听行情
        require: stat_money >= 10
        cost: { op: add, key: stat_money, value: -2 }
        effects:
          - { op: add_range, key: stat_intel, min: 1, max: 3 }
        note: 票号风向、洋货价、钱记上下游；与 ACT_03 茶楼线互补
      tier2_services:
        label: 高阶往来
        require: flag_bank_tier2 == true
        effects:
          - { op: add_range, key: stat_network, min: 2, max: 4 }
        note: R006 解锁后可选；跳槽线“像样商人”的门面
note: 具体数值与还款规则实现时再表；高阶见 R006、`loc_04`
```

## 金融服务样例

与 [`../04_数值定义/金融系统_示例数据表.md`](../04_数值定义/金融系统_示例数据表.md) 对应，`act_11` 建议优先挂这四项 `service_id`：

| 菜单项 | `service_id` | 金融意义 |
|---|---|---|
| 短借 `loan` | `svc_bank_loan_short` | 现金救急；立刻起息 |
| 展期 `rollover` | `svc_bank_rollover` | 拖时间；伤票号信用 |
| 汇兑 `remit` | `svc_bank_remit_home` | 办体面、婚事、回乡钱；可缓解 `flag_need_marriage_fund` |
| 行情 `market` | `svc_bank_market_info` | 正规金融口子的消息 |

### 债务实例样板

```yaml
run_debt:
  debt_bank_short_001:
    service_id: svc_bank_loan_short
    creditor: org_bank
    principal: 15
    remaining: 15
    interest_per_day: 1
    due_day: 18
    collateral: none
    status: active
```

### 实现备注

- `loan` 开债：+`stat_money`，+`stat_suspicion`，设 `flag_bank_loan_active`
- `rollover` 不加本金，只延天数、加额外成本，并压 `stat_credit_bank`
- `remit` 主要处理婚事/体面支出，不建议给直接收益；建议 +`stat_credit_bank` 并清 `flag_need_marriage_fund`
- `market` 属于“花钱买正规消息”，与街市茶楼互补，不互替
