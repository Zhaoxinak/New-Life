extends Node
## 职级系统：set_rank 后兑现升职四件套（仪式/称呼/权限/月例）+ 恩怨窗提示。

const RANK_TITLE := {
	"apprentice": "学徒",
	"waichang": "外场",
	"paojie": "跑街",
	"houtang": "后堂",
}

## 月例档（演示数值；文案强调「月例」）
const MONTHLY_STIPEND := {
	"apprentice": 2,
	"waichang": 5,
	"paojie": 8,
	"houtang": 12,
}

var last_ceremony: Dictionary = {}


func _ready() -> void:
	if not DomainBus.rank_changed.is_connected(_on_rank_changed):
		DomainBus.rank_changed.connect(_on_rank_changed)


func title_for(rank: String) -> String:
	return String(RANK_TITLE.get(rank, rank))


func monthly_for(rank: String) -> int:
	return int(MONTHLY_STIPEND.get(rank, 0))


func next_rank_id(rank: String) -> String:
	match rank:
		"apprentice":
			return "waichang"
		"waichang":
			return "paojie"
		"paojie":
			return "houtang"
		_:
			return ""


func next_gate_lines(rank: String = "") -> PackedStringArray:
	## 下一阶门槛 + 当前进度，给 HUD 悬停用。
	if rank.is_empty():
		rank = RunState.player_rank()
	var lines: PackedStringArray = []
	var nxt := next_rank_id(rank)
	if nxt.is_empty():
		lines.append(L10n.t("hud.tip.rank.gate_top", "已近号内高位，暂无再升阶门槛。"))
		return lines
	lines.append(L10n.t("hud.tip.rank.gate_to", "升向【%s】需：") % title_for(nxt))
	match rank:
		"apprentice":
			lines.append_array(_gate_stat("stat_trust_firm", 45, L10n.t("stat.trust_firm", "商行信任")))
			lines.append_array(_gate_stat("stat_intel", 20, L10n.t("stat.intel", "情报")))
			if RunState.get_flag("flag_demoted", false) or RunState.get_flag("flag_fired", false):
				lines.append(L10n.t("hud.tip.rank.gate_bad", "✗ 已被降/开出——先把位子稳住"))
			else:
				lines.append(L10n.t("hud.tip.rank.gate_clean", "✓ 未降职、未开出"))
			lines.append(L10n.t("hud.tip.rank.gate_e020", "抬位事件：E020 / E020B / E020C（看你走哪条路）"))
		"waichang":
			lines.append_array(_gate_stat("stat_trust_firm", 50, L10n.t("stat.trust_firm", "商行信任")))
			lines.append(L10n.t("hud.tip.rank.gate_e018", "章终抬位：把暗账与站位顶到能改口「跑街」"))
		"paojie":
			lines.append(L10n.t("hud.tip.rank.gate_houtang", "后堂门槛未正式开放（章终只留门缝）"))
		_:
			pass
	return lines


func _gate_stat(stat_id: String, need: float, label: String) -> PackedStringArray:
	var cur := float(RunState.get_stat(stat_id, 0))
	var ok := cur >= need
	var mark := "✓" if ok else "✗"
	return PackedStringArray([
		L10n.t("hud.tip.rank.gate_stat", "%s %s：%s / %s") % [mark, label, _fmt(cur), _fmt(need)]
	])


func _fmt(v: float) -> String:
	if is_equal_approx(v, roundf(v)):
		return str(int(roundf(v)))
	return "%.1f" % v


func _rank_index(rank: String) -> int:
	var order: PackedStringArray = ["apprentice", "waichang", "paojie", "houtang"]
	return order.find(rank)


func _on_rank_changed(old_rank: String, new_rank: String) -> void:
	var title := title_for(new_rank)
	var monthly := monthly_for(new_rank)
	RunState.meta["monthly_stipend"] = monthly
	RunState.meta["rank_title"] = title
	RunState.set_flag("unlock_act_waichang_patrol", new_rank != "apprentice")

	var delta := _rank_index(new_rank) - _rank_index(old_rank)
	if delta < 0:
		RunState.append_history("rank", new_rank, "history.rank.demote", {"title": title, "monthly": monthly})
		DomainBus.tip.emit(L10n.t("promo.demote_tip", "降为%s · 月例档 %d 两") % [title, monthly])
		DomainBus.emit_domain("demotion_applied", {
			"old_rank": old_rank,
			"new_rank": new_rank,
			"title": title,
			"monthly": monthly,
		})
		return
	if delta == 0:
		return

	# 四件套 payload（表现层订阅，不在此改无关数值）
	var unlocks: PackedStringArray = []
	if new_rank != "apprentice":
		unlocks.append(L10n.t("promo.unlock.waichang", "外场巡街可走"))
	if new_rank == "paojie" or new_rank == "houtang":
		unlocks.append(L10n.t("promo.unlock.paojie", "跑街账路加宽"))
	if new_rank == "houtang":
		unlocks.append(L10n.t("promo.unlock.houtang", "后堂席位"))
	last_ceremony = {
		"old_rank": old_rank,
		"new_rank": new_rank,
		"title": title,
		"monthly": monthly,
		"unlocks": unlocks,
		"beats": [
			{"id": "ritual", "loc_key": "promo.beat.ritual"},
			{"id": "title", "loc_key": "promo.beat.title", "title": title},
			{"id": "permission", "loc_key": "promo.beat.permission", "unlocks": unlocks},
			{"id": "pay", "loc_key": "promo.beat.pay", "monthly": monthly},
		],
	}
	if RunState.get_flag("flag_grudge_window_light", false):
		last_ceremony["beats"].append({"id": "grudge_window", "loc_key": "promo.beat.grudge_window"})

	RunState.append_history("rank", new_rank, "history.rank.promote", {"title": title, "monthly": monthly})
	DomainBus.emit_domain("promotion_ceremony", last_ceremony)
	DomainBus.tip.emit(L10n.t("promo.tip", "升任%s · 月例档 %d 两") % [title, monthly])
