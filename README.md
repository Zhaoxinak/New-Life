# 码头风云：复仇之路（Demo）

近代港口 · 开放式策略 RPG Demo。对标《行会 2》多路径 + 权谋复仇。

## 文档

| 文件 | 内容 |
|---|---|
| [docs/DATA.md](docs/DATA.md) | 数据架构 / i18n / Mod / 流水线 |
| [docs/PLAN.md](docs/PLAN.md) | 开发计划与验收 |
| [docs/EXPORT.md](docs/EXPORT.md) | 运行 / 导出 / QA |
| [码头风云企划书.docx](码头风云企划书.docx) | 原始企划 |

## 技术

- 引擎：**Godot 4.7.1** + GDScript  
- 数据：`docs/tables/packs/core/`（schema **6** · **0.9.1**）  
- 文案：`packs/core/l10n/`（`zh_CN` / `en`）

## 目录

```
docs/tables/packs/core/        # 权威玩法数据
docs/tables/packs/_examples/   # Mod 示例（默认不加载）
game/                          # Godot 4.7.1 工程
tools/smoke_*.py               # 无引擎冒烟
tools/copy_packs_for_export.ps1
```

## 运行

1. 安装 **Godot 4.7.1**
2. 打开 `game/project.godot`
3. 运行（F5）：标题 → 新游戏 → 开场事件 → 地点/热区/行动  
4. QA：`F3` 调试面板

导出步骤见 [docs/EXPORT.md](docs/EXPORT.md)。

改数值 → `effects.csv`　改文案 → `l10n/*.csv`　不要写死在脚本里。
