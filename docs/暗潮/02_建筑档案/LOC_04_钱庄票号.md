# 钱庄票号 · `loc_04`

> 借贷、汇兑、行情。金钱≥10 可办事；≥50 解锁高阶（R006）。

---

## 1. 一句话

银钱进出的正规口子；Demo 功能偏薄，服务跳槽线启动资金与生活压力。

---

## 2. 开放时段

早 / 中 / 下午

---

## 3. 热区

| 热区 id | 区域 | 挂行动 | 金钱戏 |
|---|---|---|---|
| `hz_bank_counter` | 柜面 | `act_11` | 短借 / 汇兑 / 打听 / 高阶往来 |
| `hz_bank_ledger` | 内账房（背景） | — | 叙事用；E015 黑账对照「正规 vs 账外」 |

### 3.1 柜面菜单（`act_11`）

| 选项 | 门槛 | 消耗/收入 | 戏剧 |
|---|---|---|---|
| 短借 `loan` | `stat_money >= 10` | +15，日末息 | 应急饮鸩止渴；`flag_bank_loan_active` |
| 汇兑 `remit` | `stat_money >= 20` | -5 | 办体面、汇银回乡；E002/E008 聘礼压力出口 |
| 打听 `market` | `stat_money >= 10` | -2 | 票号风向，补 ACT_03 茶楼线 |
| 高阶 `tier2` | `flag_bank_tier2` | — | R006 解锁；跳槽线「像样商人」门面 |

### 3.2 金钱档位与台词

| 区间 | 柜员态度 | loc_key |
|---|---|---|
| `< 20` 拮据 | 零碎客，利钱照算 | `dialog.act_11.outro.tight` |
| `10–49` 周转 | 常规汇兑，仍当过客 | `dialog.act_11.outro.mid` |
| `>= 50` 活钱厚 | 记进簿子，能周转的人 | `dialog.act_11.outro.well` + R006 |

对话入口：[`DIALOG_ACT_POOL`](../../11_对话档案/DIALOG_ACT_POOL.md) · `dialog_act_11_*`

---

## 4. 服务定义样例

票号层建议优先固化四项 `def_finance_service`：

```yaml
svc_bank_loan_short:
  service_type: loan
  require: [{ key: stat_money, op: ">=", value: 10 }]
  principal: 15
  interest_per_day: 1
  due_in_days: 3

svc_bank_rollover:
  service_type: rollover
  require: [{ flag: flag_bank_loan_active, value: true }]
  extra_interest: 1
  extend_days: 2

svc_bank_remit_home:
  service_type: remit
  require: [{ key: stat_money, op: ">=", value: 20 }]
  cost: 5

svc_bank_market_info:
  service_type: info
  require: [{ key: stat_money, op: ">=", value: 10 }]
  cost: 2
```

### 4.1 票号的四种判断

| 服务 | 看什么 | 作用 |
|---|---|---|
| 短借 | 你是不是走投无路但还像个人 | 给活路，也给利息 |
| 展期 | 你还值不值得继续拖 | 给时间，但伤信用 |
| 汇兑 | 你有没有体面需求 | 办婚事、回乡、做门面 |
| 行情 | 你是不是愿用正规口子买消息 | 低风险、低暴利、稳 |

对照文档：[`../../04_数值定义/金融系统_示例数据表.md`](../../04_数值定义/金融系统_示例数据表.md)

---

## 5. 主线 / 随机事件挂接

无固定主线；`R006` 钱庄邀约（`stat_money >= 50` → `flag_bank_tier2` → 票号信用升级）。
