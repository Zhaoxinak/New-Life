# New-Life 体验提升改进计划

## 目标

把当前项目从“系统完整的 Demo”提升为“能让人记住、能让人愿意继续玩的展示版本”。

重点不是继续堆功能，而是先把以下 4 件事做强：

1. 开场反转
2. 中段背叛
3. 结局爆点
4. 不同建筑的情绪差异

---

## 优先级

### 第一优先级

1. 先做 3 个核心剧情节点：开场反转 / 中段背叛 / 结局爆点
2. 先确定一条主路线，保证它能在 10–15 分钟内完整体验
3. 先把关键选择后的反馈做强，让结果有“重量”
4. 先优化对话节奏，减少冗长和平铺

### 第二优先级

5. 再强化公司、码头、出租屋、商行、交易所的建筑气质
6. 再优化对话 UI 和状态提示
7. 最后再考虑扩展更多分支和复杂系统

---

## 第一周执行清单

### 1. 改开场剧情
- 目标：让玩家一开始就感觉“事情已经不对劲”
- 主要文件：
  - [docs/tables/packs/core/events.csv](docs/tables/packs/core/events.csv)
  - [docs/tables/packs/core/dialogue_lines.csv](docs/tables/packs/core/dialogue_lines.csv)
- 做法：把开场写成“看似顺利、实则危险”的内容

### 2. 增加一个中段背叛节点
- 目标：让玩家感受到“之前的选择，真的把关系推向了另一边”
- 主要文件：
  - [docs/tables/packs/core/events.csv](docs/tables/packs/core/events.csv)
  - [docs/tables/packs/core/dialogue_line_variants.csv](docs/tables/packs/core/dialogue_line_variants.csv)
- 做法：在中段触发一次关系翻转或立场反转

### 3. 收束结局
- 目标：让结局更像“命运落点”，而不是简单结论
- 主要文件：
  - [docs/tables/packs/core/endings.csv](docs/tables/packs/core/endings.csv)
  - [docs/tables/packs/core/events.csv](docs/tables/packs/core/events.csv)
- 做法：结局文案更短、更有压迫感，结局前增加最后一次关键选择

### 4. 让建筑有不同气质
- 目标：让公司、码头、出租屋等地点看起来不像是同一类空间
- 主要文件：
  - [docs/tables/packs/core/hotspots.csv](docs/tables/packs/core/hotspots.csv)
  - [docs/tables/packs/core/actions.csv](docs/tables/packs/core/actions.csv)
- 做法：
  - 公司：更压迫、更控制
  - 码头：更危险、更粗粝
  - 出租屋：更私密、更情绪化

### 5. 给关键选择加反馈
- 目标：让玩家在做选择后能立即感知“这一步有后果”
- 主要文件：
  - [game/systems/ActionPipeline.gd](game/systems/ActionPipeline.gd)
  - [game/ui/PlayChrome.gd](game/ui/PlayChrome.gd)
- 做法：反馈要包含人物反应、局势变化和情绪变化，而不只是数值变化

---

## 需要改的核心文件

- 剧情与事件：[docs/tables/packs/core/events.csv](docs/tables/packs/core/events.csv)
- 对话与选项：[docs/tables/packs/core/dialogue_lines.csv](docs/tables/packs/core/dialogue_lines.csv), [docs/tables/packs/core/dialogue_choices.csv](docs/tables/packs/core/dialogue_choices.csv)
- 结局：[docs/tables/packs/core/endings.csv](docs/tables/packs/core/endings.csv)
- 热点与动作：[docs/tables/packs/core/hotspots.csv](docs/tables/packs/core/hotspots.csv), [docs/tables/packs/core/actions.csv](docs/tables/packs/core/actions.csv)
- 反馈与 UI：[game/systems/ActionPipeline.gd](game/systems/ActionPipeline.gd), [game/ui/DialoguePanel.gd](game/ui/DialoguePanel.gd), [game/ui/PlayChrome.gd](game/ui/PlayChrome.gd)

---

## 完成标准

如果你能把上面 5 件事做完，项目就已经比现在更像一个“能拿去试玩、能让人记住”的 Demo 了。

你应该能明显感受到：
- 开场更有吸引力
- 中段有反转
- 结局更有重量
- 不同建筑的气质更鲜明
- 关键选择更有后果感

### 11.3 状态系统：从“数值表”升级成“关系与压迫感”

建议把核心状态做得更直观：

- 用更明显的颜色和符号区分“信任 / 疑心 / 压力 / 亲密 / 监视”。
- 关键状态变化时，增加短提示和情绪化文案，而不只是纯数字。

目标：

- 让玩家明显感觉到“局势正在变热、变冷、变危险”。

---

## 12. UI 层优化方案

### 12.1 入口与场景切换

相关逻辑已经体现在 [game/ui/LocationView.gd](game/ui/LocationView.gd)、[game/ui/SceneStage.gd](game/ui/SceneStage.gd) 与 [game/world/HarborOutdoor.gd](game/world/HarborOutdoor.gd)。

建议：

- 建筑进入时增加更明显的过渡动作，如淡入、色温变化、轻微视角偏移。
- 场景切换时主视觉不要太“硬切”，要有一种“世界正在变化”的感觉。
- 每个建筑都应该有属于自己的色调和视觉关键词。

目标：

- 玩家不只是“切换地点”，而是“进入不同的情境”。

---

### 12.2 HUD 与信息层

相关脚本在 [game/ui/HUD.gd](game/ui/HUD.gd) 与 [game/ui/PlayChrome.gd](game/ui/PlayChrome.gd)。

建议：

- 把状态条做成更有层次的“情绪仪表”，而不是单纯数字列表。
- 对紧张状态增加明显的颜色变化和轻提示。
- 关键时刻用更短、更强的提示文案，而不是长文本说明。

目标：

- 让玩家看到 UI 时，能立刻理解“此刻局势有何变化”。

---

### 12.3 对话与选择 UI

相关脚本在 [game/ui/DialoguePanel.gd](game/ui/DialoguePanel.gd)。

建议：

- 选择按钮不要都同样大小、同样样式，关键选项要更突出。
- 选项的文本尽量体现“立场和代价”，而不是只写“继续”。
- 对话文本可以增加短暂停顿、重音和节奏控制。

目标：

- 让选择不只是“点一下”，而是“下决定”。

---

## 13. 效果与演出优化方案

### 13.1 视觉效果

建议在关键节点加入：

- 轻微画面抖动
- 色调偏移或短暂黑白化
- 过场黑边、淡入淡出
- 强调人物动作或表情时的局部高亮

重点用于：

- 选择后果出现时
- 关系突然翻转时
- 结局前的最后一段剧情

---

### 13.2 音效与节奏

建议：

- 每个建筑都拥有一个明显的环境音风格。
- 关键剧情时增加短促、明确的音效反馈，不要完全依赖文本。
- 通过节奏控制让“紧张”和“安静”产生明显反差。

目标：

- 让玩家在听觉上也能感受到“这里不一样”。

---

### 13.3 演出节奏

建议把整个 Demo 的节奏改成“前半段铺垫，后半段爆发”。

可以这样设计：

- 前面以人物关系和小冲突为主。
- 中段逐步把局势推向更危险的方向。
- 最后用一段强烈的结局演出收束。

目标：

- 让玩家从“看内容”变成“被内容推着走”。

---

## 14. 建议的 Demo 展示顺序

如果是拿给朋友看，建议不要从完整流程开始，而是按下面顺序展示：

1. 先展示开场反转和人物关系建立。
2. 再展示一次关键选择后的反转。
3. 最后展示结局爆点。

这样更容易让人记住“这游戏的核心体验是什么”。

---

## 15. 最终建议

最重要的不是继续加功能，而是把现有内容做成“更有重量、更有冲击力、更有辨识度”的体验。

建议优先顺序是：

1. 先把 3 个高冲击剧情节点做出来。
2. 再把各建筑的空间感和情绪感做强。
3. 然后统一强化 UI、效果和演出节奏。

如果你现在要开始动手，最稳妥的路线是：

- 先做一条主路线，确保它能完整跑通；
- 再把开场、转折、结局这三段的演出做满；
- 最后才考虑扩展更多建筑、更多路线和更复杂的分支。

只要做到这三点，作品就会从“可玩”提升到“值得被记住”。

---

## 16. 真正可执行的开发任务清单

下面这份清单是按“你现在就能开始做”的方式整理的，适合直接拿去开发。

### 16.1 第一阶段：先把主路线做成能打动人的 Demo

#### 任务 1：确定 1 条主路线
- 目标：选出一条最适合展示的剧情路线，优先保证它能在 10–15 分钟内体验完。
- 重点：不要同时做太多分支，先把一条“强剧情、强反馈、强结局”的路线打出来。
- 推荐内容：
  - 开场：让玩家误以为自己在推进一个普通复仇计划。
  - 中段：让玩家发现自己被卷入更大的局势。
  - 结局：把前面的选择真正落到一个强烈的结果上。
- 相关文件：
  - [docs/tables/packs/core/dialogues.csv](docs/tables/packs/core/dialogues.csv)
  - [docs/tables/packs/core/dialogue_lines.csv](docs/tables/packs/core/dialogue_lines.csv)
  - [docs/tables/packs/core/dialogue_choices.csv](docs/tables/packs/core/dialogue_choices.csv)
  - [docs/tables/packs/core/events.csv](docs/tables/packs/core/events.csv)

#### 任务 2：补 3 个高冲击剧情节点
- 目标：完成开场反转、中段背叛、结局爆点这三个节点。
- 具体做法：
  - 开场反转：让玩家意识到自己已经被卷入更大的阴谋。
  - 中段背叛：设计一个人物关系瞬间翻转的节点。
  - 结局爆点：让结局不是简单好坏，而是有情绪重量和命运感。
- 相关文件：
  - [docs/tables/packs/core/events.csv](docs/tables/packs/core/events.csv)
  - [docs/tables/packs/core/dialogue_lines.csv](docs/tables/packs/core/dialogue_lines.csv)
  - [docs/tables/packs/core/effects.csv](docs/tables/packs/core/effects.csv)

#### 任务 3：把关键节点的选择后果做强
- 目标：让选择不只是数值变化，而是带来明确的情绪和局势差异。
- 具体做法：
  - 每个关键选择都对应一个强后果：信任变化、嫌疑变化、人物立场变化、事件触发。
  - 后果要让玩家感知到“我刚刚做了一个决定，局势真的变了”。
- 相关文件：
  - [docs/tables/packs/core/effects.csv](docs/tables/packs/core/effects.csv)
  - [docs/tables/packs/core/conditions.csv](docs/tables/packs/core/conditions.csv)

---

### 16.2 第二阶段：把建筑变成有情绪的空间

#### 任务 4：码头货场增强
- 目标：让码头从“功能区”变成“风险与情报交汇点”。
- 具体改动：
  - 货仓办公室：增加紧张、压迫、权力感。
  - 装卸货区：增加粗粝、身体感、现实感。
  - 港口公告栏：让它更像“信息传播点”。
- 相关文件：
  - [docs/tables/packs/core/hotspots.csv](docs/tables/packs/core/hotspots.csv)
  - [docs/tables/packs/core/actions.csv](docs/tables/packs/core/actions.csv)
  - [game/ui/LocationView.gd](game/ui/LocationView.gd)
  - [game/ui/SceneStage.gd](game/ui/SceneStage.gd)

#### 任务 5：宏远贸易公司增强
- 目标：让公司从“普通办公室”变成“权力机器”。
- 具体改动：
  - 老板办公室：强调压迫和命运感。
  - 财务室门口：增强“关键节点”的感觉。
  - 大办公区：把它做成“信息流动和人际流动”的空间。
- 相关文件：
  - [docs/tables/packs/core/hotspots.csv](docs/tables/packs/core/hotspots.csv)
  - [docs/tables/packs/core/actions.csv](docs/tables/packs/core/actions.csv)
  - [game/world/HarborOutdoor.gd](game/world/HarborOutdoor.gd)

#### 任务 6：出租屋增强
- 目标：让出租屋从“休整地点”变成“情绪与秘密的避风港”。
- 具体改动：
  - 客厅：用来承接亲密、压抑、犹豫的情绪。
  - 书桌：强调思考、记录、决定。
  - 床边：做成最脆弱的情绪空间。
- 相关文件：
  - [docs/tables/packs/core/hotspots.csv](docs/tables/packs/core/hotspots.csv)
  - [docs/tables/packs/core/dialogues.csv](docs/tables/packs/core/dialogues.csv)
  - [game/ui/DialoguePanel.gd](game/ui/DialoguePanel.gd)

#### 任务 7：通洋商行增强
- 目标：让商行变成“站队与背叛的门槛”。
- 具体改动：
  - 接待大堂：强调“进入就意味着决定”。
  - 洽谈室：强化谈判和立场选择。
  - 掌柜办公室：让进入它像一次真正的决策。
- 相关文件：
  - [docs/tables/packs/core/hotspots.csv](docs/tables/packs/core/hotspots.csv)
  - [docs/tables/packs/core/actions.csv](docs/tables/packs/core/actions.csv)

#### 任务 8：股票交易所增强
- 目标：让交易所从“金融地点”变成“高压博弈场”。
- 具体改动：
  - 交易大厅：加强节奏和压迫感。
  - 消息茶馆：强化谣言传播和信息风向。
  - 大户室：强化最终决策的重量。
- 相关文件：
  - [docs/tables/packs/core/hotspots.csv](docs/tables/packs/core/hotspots.csv)
  - [docs/tables/packs/core/actions.csv](docs/tables/packs/core/actions.csv)

---

### 16.3 第三阶段：把反馈和演出做成“有冲击力的体验”

#### 任务 9：增强行动反馈
- 目标：让玩家从“我做了一个行动”变成“我看见了后果”。
- 具体改动：
  - 每个关键动作增加简短的结果提示。
  - 结果提示要包含人物反应、局势变化、情绪变化，而不只是数值变化。
- 相关文件：
  - [game/systems/ActionPipeline.gd](game/systems/ActionPipeline.gd)
  - [game/ui/PlayChrome.gd](game/ui/PlayChrome.gd)
  - [game/ui/HUD.gd](game/ui/HUD.gd)

#### 任务 10：增强对话演出
- 目标：让对话更像“人物在对峙”，而不是“文本在推进”。
- 具体改动：
  - 关键对话增加停顿、重音和情绪表达。
  - 选择按钮要有不同的“重量”，重点选择更突出。
- 相关文件：
  - [game/ui/DialoguePanel.gd](game/ui/DialoguePanel.gd)
  - [docs/tables/packs/core/dialogue_choices.csv](docs/tables/packs/core/dialogue_choices.csv)

#### 任务 11：增加关键节点的视觉与音效演出
- 目标：让剧情节点有“看得见、听得见”的冲击力。
- 具体改动：
  - 关键选择后增加短暂的画面变化。
  - 关键剧情节点增加简短音效和节奏变化。
- 相关文件：
  - [game/ui/SceneStage.gd](game/ui/SceneStage.gd)
  - [game/ui/DialoguePanel.gd](game/ui/DialoguePanel.gd)
  - [game/world/HarborOutdoor.gd](game/world/HarborOutdoor.gd)

---

### 16.4 第四阶段：把 UI 做成“能辅助剧情”的层

#### 任务 12：优化 HUD 与状态提示
- 目标：让 UI 不只是显示数值，而是帮助玩家理解局势。
- 具体改动：
  - 状态条改成更有层次的“情绪与局势”展示。
  - 紧张状态增加提示色和短提示。
- 相关文件：
  - [game/ui/HUD.gd](game/ui/HUD.gd)
  - [game/ui/PlayChrome.gd](game/ui/PlayChrome.gd)

#### 任务 13：优化场景切换与进入体验
- 目标：让地点切换更有“进入不同世界”的感觉。
- 具体改动：
  - 建筑进入时增加过渡效果。
  - 场景切换不要太硬切，增加视觉和节奏过渡。
- 相关文件：
  - [game/ui/LocationView.gd](game/ui/LocationView.gd)
  - [game/ui/SceneStage.gd](game/ui/SceneStage.gd)
  - [game/world/HarborOutdoor.gd](game/world/HarborOutdoor.gd)

---

## 17. 建议的开发顺序

如果你要开始做，建议按下面顺序推进：

1. 先做主路线和 3 个关键剧情节点
2. 再把关键选择后的反馈补完整
3. 再强化码头和公司这两个最重要的建筑氛围
4. 再做出租屋、商行、交易所的情绪差异
5. 最后统一收口 UI、演出、音效和展示节奏

---

## 18. 最后提醒

现在最值得投入的，不是继续扩“系统”，而是把现有系统变成“有情绪、有节奏、有记忆点”的体验。

如果你按上面的清单逐项推进，项目会比现在更像一个“能拿出去展示”的作品。

---

## 19. 第一批优先任务（建议你先做这 6 项）

下面这 6 项是“最容易见效、最值得先做”的内容。它们足够小，但会明显提升试玩体验。

### 任务 A：把开场做成“有反转”的第一段剧情
- 目标：让玩家从第一分钟就知道这不是普通复仇剧情。
- 重点：不要只介绍世界观，要让玩家立刻进入“局势已经不受自己控制”的感觉。
- 推荐做法：
  - 把开场文案改成更有悬念和压迫感的表达。
  - 让第一段剧情有一个“误导 + 反转”的结构。
- 相关文件：
  - [docs/tables/packs/core/events.csv](docs/tables/packs/core/events.csv)
  - [docs/tables/packs/core/dialogue_lines.csv](docs/tables/packs/core/dialogue_lines.csv)

### 任务 B：做一个“中段背叛”节点
- 目标：让玩家感到“我之前做的选择，真的把关系推向了另一边”。
- 重点：这一段要让人物关系发生明显翻转，而不只是数值变化。
- 推荐做法：
  - 在某个关键日子触发一个关系反转事件。
  - 事件后，角色的语气、立场、对选项的反应都要变化。
- 相关文件：
  - [docs/tables/packs/core/events.csv](docs/tables/packs/core/events.csv)
  - [docs/tables/packs/core/dialogue_line_variants.csv](docs/tables/packs/core/dialogue_line_variants.csv)

### 任务 C：把结局做成“有重量”的收束
- 目标：结局不能只是一句“你赢了/你输了”，而要让玩家感觉“这一切都指向了这一刻”。
- 重点：结局要有情绪和命运感。
- 推荐做法：
  - 结局文本要更短、更有压迫力。
  - 结局前加一个关键抉择或最后一段对话。
- 相关文件：
  - [docs/tables/packs/core/endings.csv](docs/tables/packs/core/endings.csv)
  - [docs/tables/packs/core/events.csv](docs/tables/packs/core/events.csv)

### 任务 D：让公司和码头各自有“不同的情绪”
- 目标：让玩家一进入不同建筑，就能感受到它们不像是同一个地方。
- 重点：公司要压迫，码头要粗粝和危险。
- 推荐做法：
  - 调整建筑内热点的文案和动作类型。
  - 给公司更“权力机器”的感觉，给码头更“风险和风声”的感觉。
- 相关文件：
  - [docs/tables/packs/core/hotspots.csv](docs/tables/packs/core/hotspots.csv)
  - [docs/tables/packs/core/actions.csv](docs/tables/packs/core/actions.csv)

### 任务 E：给关键选择加“结果反馈”
- 目标：不要让玩家只看到数值变化，要让他们看到“事情发生了”。
- 重点：关键选择后，要有短而强的反馈。
- 推荐做法：
  - 成功/失败后的反馈增加人物反应和局势变化。
  - 关键节点加一句强有力的提示文案。
- 相关文件：
  - [game/systems/ActionPipeline.gd](game/systems/ActionPipeline.gd)
  - [game/ui/PlayChrome.gd](game/ui/PlayChrome.gd)

### 任务 F：优化对话 UI，让选择更有“重量”
- 目标：让选择看起来像真正的选择，而不是一串按钮。
- 重点：选项文本、按钮视觉、对话节奏要更有区分度。
- 推荐做法：
  - 重点选项换成更强调代价和后果的文案。
  - 关键选项做更突出视觉处理。
- 相关文件：
  - [game/ui/DialoguePanel.gd](game/ui/DialoguePanel.gd)
  - [docs/tables/packs/core/dialogue_choices.csv](docs/tables/packs/core/dialogue_choices.csv)

---

## 20. 你现在最应该怎么开始

建议按这个顺序开始：

1. 先做任务 A 和任务 C：开场与结局。
2. 再做任务 B：中段背叛节点。
3. 然后做任务 D：公司和码头的情绪差异。
4. 最后做任务 E 和任务 F：反馈与 UI。

这样做的好处是：
- 你会先看到“剧情体验”有没有变强；
- 之后再补环境和UI，整体会更顺。

---

## 21. 按文件和字段拆的落地清单

下面这部分是给你“直接开改”的版本，按具体文件和字段来说明。

### 21.1 剧情相关：优先改这几个 CSV

#### 1) [docs/tables/packs/core/events.csv](docs/tables/packs/core/events.csv)
建议优先改的字段：
- `body`：把开场和中段事件的文案改成更有悬念、压迫和反转感的表达。
- `title`：关键事件标题要更有“冲击感”。
- `priority` / `weight`：让关键剧情更容易被触发。

建议动作：
- 给开场事件加一个“看似顺利、实则危险”的氛围。
- 给中段背叛事件加一个“关系突然翻转”的触发节点。
- 给结局前事件加一个压迫感更强的收束。

#### 2) [docs/tables/packs/core/dialogue_lines.csv](docs/tables/packs/core/dialogue_lines.csv)
建议优先改的字段：
- `text`：把台词改得更短、更有重量，减少解释性长句。
- `speaker_id`：确认哪些关键节点应该由谁说话，强化人物辨识度。

建议动作：
- 让人物在关键节点说出更有冲击力的句子。
- 尽量避免“为了推进剧情而解释”的台词。

#### 3) [docs/tables/packs/core/dialogue_choices.csv](docs/tables/packs/core/dialogue_choices.csv)
建议优先改的字段：
- `label`：把选项文案改得更像“立场选择”，而不是普通按钮。
- `effects`：让不同选择带来更明显的后果。

建议动作：
- 让选项有“退让 / 强硬 / 试探 / 迎合 / 毁谤”等立场差别。
- 重点选项的文案要更有代价感。

#### 4) [docs/tables/packs/core/endings.csv](docs/tables/packs/core/endings.csv)
建议优先改的字段：
- `name`：结局名称要更有“记忆点”。
- `description`：结局文案要更浓、更有情绪重量。

建议动作：
- 结局不要只是说明结果，而要让玩家感觉“这一切都在往这里走”。

---

### 21.2 建筑与热点相关：优先改这几个 CSV

#### 5) [docs/tables/packs/core/hotspots.csv](docs/tables/packs/core/hotspots.csv)
建议优先改的字段：
- `notes`：给不同热点加更明确的情绪定位。
- `periods`：让不同建筑的使用时段更有节奏区别。
- `suspicion_mult`：使用不同 hotspot 时，提升“风险感”的差异。

建议动作：
- 码头热点更强调危险、风声、隐秘。
- 公司热点更强调压迫、权力、控制。
- 出租屋热点更强调亲密、私密、情绪。

#### 6) [docs/tables/packs/core/actions.csv](docs/tables/packs/core/actions.csv)
建议优先改的字段：
- `name`：给不同行动更有辨识度的命名。
- `description`：让行动的代价和后果更清楚。
- `hotspot_id`：把不同建筑内的行动重新分组，避免同一层级太像。

建议动作：
- 给公司动作加更强的“权力/控制”色彩。
- 给码头动作加更强的“危险/秘密”色彩。

---

### 21.3 脚本相关：优先改这几个脚本

#### 7) [game/systems/ActionPipeline.gd](game/systems/ActionPipeline.gd)
建议优先改的逻辑：
- 在行动执行后，增加更清晰的结果反馈。
- 把“成功/失败/代价/后果”组织成更容易被玩家看懂的顺序。

建议动作：
- 关键行动执行后，除了更新状态，还要输出更加有戏剧性的提示。

#### 8) [game/ui/DialoguePanel.gd](game/ui/DialoguePanel.gd)
建议优先改的逻辑：
- 让对话面板更强调“抉择”和“情绪”。
- 关键选项可以做更强的视觉突出。

建议动作：
- 让对话窗口更像一个“人物对峙场景”，而不是纯文本阅读框。

#### 9) [game/ui/PlayChrome.gd](game/ui/PlayChrome.gd)
建议优先改的逻辑：
- 把行动面板中“代价”“后果”“风险”展示得更清楚。

建议动作：
- 让玩家在做抉择前就能感觉到“这一步会有什么后果”。

#### 10) [game/ui/HUD.gd](game/ui/HUD.gd)
建议优先改的逻辑：
- 把 HUD 做成更有“局势感”的状态层。

建议动作：
- 紧张状态用更明显的颜色和提示文案。
- 重要变化时增加短暂的视觉提醒。

---

### 21.4 视觉与演出相关：优先调整这几个地方

#### 11) [game/ui/SceneStage.gd](game/ui/SceneStage.gd)
建议优先改的逻辑：
- 给不同场景增加更明显的环境色调差异。
- 关键时刻增加短暂的视觉节奏变化。

建议动作：
- 公司可以偏冷、压抑。
- 码头可以偏暗、粗粝。
- 出租屋可以偏暖、私密。

#### 12) [game/world/HarborOutdoor.gd](game/world/HarborOutdoor.gd)
建议优先改的逻辑：
- 建筑入口和地图上的“进入感”可以更强。

建议动作：
- 让不同建筑入口更有辨识度，方便玩家一眼就记住它们。

---

## 22. 建议你现在就开始做的最小版本

如果你想先把最小有效改动做出来，建议先做这 4 项：

1. 先改开场和结局文案
2. 再加一个中段背叛事件
3. 再把公司和码头的热点文案和动作区分开
4. 最后给关键选择增加更强的反馈

这是最省事、最容易见效的一条路。

---

## 23. 第一周实施清单（最适合你现在开始）

下面这份是“第一周只做 5 件事”的版本，目标是尽快把 Demo 的体验感拉起来。

### 1. 先改开场剧情文本
- 目标：让第一分钟就有悬念和压迫感。
- 改动位置：
  - [docs/tables/packs/core/events.csv](docs/tables/packs/core/events.csv)
  - [docs/tables/packs/core/dialogue_lines.csv](docs/tables/packs/core/dialogue_lines.csv)
- 做法：
  - 把开场写成“看起来像顺风，实则已经被卷入更深局势”的内容。
  - 让第一段对话更像人物在试探，而不是在解释世界观。

### 2. 增加一个中段背叛节点
- 目标：让玩家感受到“我之前的选择，真的把关系推向了另一边”。
- 改动位置：
  - [docs/tables/packs/core/events.csv](docs/tables/packs/core/events.csv)
  - [docs/tables/packs/core/dialogue_line_variants.csv](docs/tables/packs/core/dialogue_line_variants.csv)
- 做法：
  - 在中段触发一个关系翻转或立场反转事件。
  - 触发后，相关人物的台词要发生明显变化。

### 3. 把结局收束得更有重量
- 目标：让结局不是“结果总结”，而是“命运落点”。
- 改动位置：
  - [docs/tables/packs/core/endings.csv](docs/tables/packs/core/endings.csv)
  - [docs/tables/packs/core/events.csv](docs/tables/packs/core/events.csv)
- 做法：
  - 结局文本更短、更像一句命运宣判。
  - 结局前加一个最关键的选择或最后一句台词。

### 4. 给公司和码头加明显的情绪差异
- 目标：让建筑之间不只是“地点不同”，而是“气质不同”。
- 改动位置：
  - [docs/tables/packs/core/hotspots.csv](docs/tables/packs/core/hotspots.csv)
  - [docs/tables/packs/core/actions.csv](docs/tables/packs/core/actions.csv)
- 做法：
  - 公司：更压迫、更控制、更权力化。
  - 码头：更危险、更粗粝、更隐秘。

### 5. 给关键选择加“结果反馈”
- 目标：让玩家能立即感知“刚才那一步，真的发生了事”。
- 改动位置：
  - [game/systems/ActionPipeline.gd](game/systems/ActionPipeline.gd)
  - [game/ui/PlayChrome.gd](game/ui/PlayChrome.gd)
- 做法：
  - 关键行动执行后输出更强的提示。
  - 反馈要包含人物反应和局势变化，而不只是数值变化。

---

## 24. 第一周建议的完成标准

如果你能把上面 5 件事完成，就已经比现在更像一个“有冲击力的 Demo”了。

完成后，你应该能明显感受到：
- 开场更有吸引力；
- 中段有反转；
- 结局更有重量；
- 不同建筑的气质更鲜明；
- 关键选择更有后果感。

这就已经足够让你拿去给朋友试玩，看看他们的第一反应是否更强。

---

## 25. 第一周可直接照着填的开发模板

下面这个模板可以直接拿来做第一周改动。

### 模板 A：开场剧情改写
- 目标：让玩家一开始就觉得“事情已经不对劲”。
- 文案方向：
  - 先看起来像顺利
  - 后面突然出现不对劲的信号
  - 最后给出一句让人觉得“我被卷进去了”的话
- 建议句式：
  - “我以为自己只是走一步顺手的路，结果……”
  - “原来这件事从一开始就不只是我一个人的选择。”
  - “有人已经在等我做这个决定了。”
- 适用文件：
  - [docs/tables/packs/core/events.csv](docs/tables/packs/core/events.csv)
  - [docs/tables/packs/core/dialogue_lines.csv](docs/tables/packs/core/dialogue_lines.csv)

### 模板 B：中段背叛节点
- 目标：让人物关系在某一刻突然翻转。
- 结构：
  1. 先建立信任或亲密感
  2. 突然出现一个让人意想不到的动作
  3. 立刻把关系推向敌意或疏远
- 建议句式：
  - “我一直以为你是站在我这边的。”
  - “原来你只是想把我推上去，再让别人替你收拾残局。”
  - “我现在才知道，你从来不是来帮我的。”
- 适用文件：
  - [docs/tables/packs/core/events.csv](docs/tables/packs/core/events.csv)
  - [docs/tables/packs/core/dialogue_line_variants.csv](docs/tables/packs/core/dialogue_line_variants.csv)

### 模板 C：结局收束
- 目标：让结局像“命运落下”的一击，而不是“说明文字”。
- 结构：
  1. 先让人物做出最后一次选择
  2. 再给一个短促的命运式收束
  3. 留下一个让人记住的句子
- 建议句式：
  - “你终于明白，所有人都在等你做这个决定。”
  - “这不是胜负，而是你终于被逼着承认自己已经站在了哪里。”
  - “你以为自己在复仇，其实你只是替别人把局势推到了尽头。”
- 适用文件：
  - [docs/tables/packs/core/endings.csv](docs/tables/packs/core/endings.csv)

### 模板 D：建筑情绪差异
- 目标：让不同建筑像不同世界。
- 适配思路：
  - 公司：压迫、权力、控制
  - 码头：危险、粗粝、风声
  - 出租屋：私密、犹豫、情绪
- 文案方向：
  - 公司里的话更像命令和算计
  - 码头里的话更像低声和试探
  - 出租屋里的话更像心事和停顿
- 适用文件：
  - [docs/tables/packs/core/hotspots.csv](docs/tables/packs/core/hotspots.csv)
  - [docs/tables/packs/core/actions.csv](docs/tables/packs/core/actions.csv)

### 模板 E：关键选择反馈
- 目标：让玩家在选择后立即感觉“这一步有重量”。
- 反馈建议：
  - 文字提示：一句有力度的话
  - 角色反应：有人沉默、有人冷笑、有人变脸
  - 局势变化：信任变了、嫌疑变了、关系变了
- 适用文件：
  - [game/systems/ActionPipeline.gd](game/systems/ActionPipeline.gd)
  - [game/ui/PlayChrome.gd](game/ui/PlayChrome.gd)

---

## 26. 你现在最值得优先填的内容

如果你现在就开始写，优先填下面这几项：

1. 开场事件文案
2. 中段背叛事件文案
3. 结局文案
4. 公司和码头热点文案
5. 关键选择反馈文案

这 5 项是最能直接提升“试玩感”的。
