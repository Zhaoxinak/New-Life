extends Control
## Top HUD: day / period / money / trust / suspicion / intel / rank

@onready var day_label: Label = %DayLabel
@onready var period_label: Label = %PeriodLabel
@onready var money_label: Label = %MoneyLabel
@onready var trust_label: Label = %TrustLabel
@onready var suspicion_label: Label = %SuspicionLabel
@onready var intel_label: Label = %IntelLabel
@onready var rank_label: Label = %RankLabel


func _ready() -> void:
	if not GameState.state_changed.is_connected(_refresh):
		GameState.state_changed.connect(_refresh)
	if not L10n.locale_changed.is_connected(_on_locale):
		L10n.locale_changed.connect(_on_locale)
	_refresh()


func _on_locale(_locale: String) -> void:
	_refresh()


func _refresh() -> void:
	day_label.text = L10n.tf("ui.hud.day", {"day": GameState.day}, "第 %d 天" % GameState.day)
	var period_key := "ui.hud.period_%s" % GameState.period
	period_label.text = "%s：%s" % [
		L10n.t("ui.hud.period", "时段"),
		L10n.t(period_key, L10n.t("periods.%s.name" % GameState.period, GameState.period)),
	]
	money_label.text = "%s %d" % [L10n.t("ui.hud.money", "金钱"), int(GameState.get_stat("money"))]
	trust_label.text = "%s %d" % [L10n.t("ui.hud.trust", "信任"), int(GameState.get_stat("trust"))]
	var sus := int(GameState.get_stat("suspicion"))
	suspicion_label.text = "%s %d" % [L10n.t("ui.hud.suspicion", "嫌疑"), sus]
	if sus >= 70:
		suspicion_label.add_theme_color_override("font_color", UiStyle.DANGER)
	else:
		suspicion_label.add_theme_color_override("font_color", UiStyle.TEXT)
	intel_label.text = "%s %d" % [L10n.t("ui.hud.intel", "情报"), int(GameState.get_stat("intel"))]
	var rid := GameState.get_rank_id()
	rank_label.text = L10n.t("ranks.%s.name" % rid, rid)
	rank_label.add_theme_color_override("font_color", UiStyle.BRASS)
