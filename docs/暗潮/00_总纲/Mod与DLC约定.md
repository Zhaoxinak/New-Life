# Mod / DLC 约定（设计）

> 内容可扩，引擎只做解释器。详细表见 [`数据库架构.md`](数据库架构.md)。

---

## 1. 能改 / 不能改

| 能（内容包） | 不能 |
|---|---|
| 新增/覆盖 `def_*` 行 | 改 effect 白名单未登记的 op |
| 新 char/event/loc/dialog/clue/item | 改存档 schema 无迁移 |
| 覆盖 loc 文案 | 直接写玩家机器上的存档逻辑 |
| 附加 tick 规则（登记后） | 复用已有主键改指别的实体 |

---

## 2. 包结构（建议）

```
mods/<mod_id>/
  modinfo.yaml          # id, name, version, depend[], load_order
  def/                  # 同主包表结构
  loc/
```

- `load_order`：数字越大越后覆盖  
- 依赖：缺少 `depend` 则拒绝加载  

---

## 3. ID 纪律

- 新内容用自己的前缀命名空间：`char_modxxx_*` 或约定 `modid.char_*`  
- **禁止**静默占用原版 `E014` 等 ID 改剧情（覆盖须在 modinfo 声明 `overrides: [E014]`）  

---

## 4. Demo 范围

正式 Mod 管线可后置；设计期先保证：**原版全用稳定 ID + 白名单 effect**，为 Mod 留同构接口。

---

## 5. 版本

| 版本 | 内容 |
|---|---|
| **v0.1** | 能改边界、包结构草案 |
