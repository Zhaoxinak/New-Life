# 轻量自由层 + 可选复仇主线（执行清单）

> 版本：2026-08-09 · pack `core` 0.9.8  
> 选定方向：1A（轻量雇佣）+ 保留 A/B/C 复仇主线（塞尔达式可选）  
> 与已完成的 `IMPROVEMENT_PLAN.md` 分开；本稿为雇佣/主线自由化验收单。

---

## Phase 0 — 雇佣骨架

- [x] `GameState.employer_id` / `active_career_track` + 存读档
- [x] `ConditionEval`：`employer` / `career_track`
- [x] `EffectApplier`：`employer` effect
- [x] 行动 `co_resign` + 宏远办公行动雇主门闩
- [x] 解雇 → 失业（`ending_fail_fired` 停用；`ev_fail_fired` 叙事）
- [x] HUD 显示雇主 / 职级

## Phase 1 — 双轨职涯

- [x] `tongyang_trust` + `tongyang_career` ranks
- [x] 通洋入职不绑 `route_focus_a`；入职切雇主 + 初始化通洋信任
- [x] `rival_work` 日常攒通洋信任
- [x] 留司 `co_ask_promotion` + HUD/档案「下一晋升」

## Phase 2 — 塞尔达式任务栏

- [x] 短强制引导（走近门 → 码头搬货 → 回家安顿）；去掉必进公司
- [x] 主线步 `optional=1`；文案带「可稍后再做」
- [x] 任务栏收起/显示写入 `quest_pinned`
- [x] D7：软触发 + `ch_d7_wait` 可推迟；`max_triggers=0` 直至选线

## Phase 3 — 打磨

- [x] 辞职/开除/通洋后的码头对话变体
- [x] 通洋入职台词区分「职涯跳槽」与纯复仇
- [x] Debug 面板显示雇主 / 通洋信任
- [x] `rank_min` 按职涯轨隔离（避免通洋职级误开宏远财务）

---

## 验收（试玩勾选）

- [ ] 新开档 D2 前可辞职，靠码头续命；宏远 `日常办公` 灰显正确
- [ ] 不选 D7 也能玩到 D10+（选「还不到时候」）
- [ ] 未选 A 线，门槛够后可入职通洋并看到通洋职级进度
- [ ] 主线收起后仍可撞上线索；钉住时可推到阶段结局
- [ ] 存读档恢复雇主与职级显示
- [ ] 嫌疑爆表被开 → 失业继续玩，不进「身败名裂」终局；破产仍可失败

---

## 关键 ID 速查

| 用途 | ID |
|---|---|
| 辞职 | `co_resign` / `dlg_co_resign` / `resigned_hongyuan` |
| 留司晋升 | `co_ask_promotion` / `claimed_hongyuan_promo` |
| 通洋打工 | `rival_work` / `tongyang_trust` / ranks `ty_*` |
| 解雇失业 | `ev_fail_fired` / `hongyuan_fired` / employer `none` |
| 主线可选 | `quests.optional` / `q_main_pulse` / `ch_d7_wait` |
