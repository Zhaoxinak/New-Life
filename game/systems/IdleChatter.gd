extends Node
## Picks idle chatter lines for ambience.


func pick_for_current(hotspot_id: String = "") -> String:
	var candidates: Array = []
	var total_w := 0
	for row in PackDB.get_table("idle_chatter"):
		if str(row.get("enabled", "1")) == "0":
			continue
		var cid := str(row.get("id", ""))
		if str(row.get("location_id", "")) != GameState.location_id:
			continue
		var hp := str(row.get("hotspot_id", "")).strip_edges()
		if hp != "" and hotspot_id != "" and hp != hotspot_id:
			continue
		if hp != "" and hotspot_id == "":
			continue
		if not GameState.period_matches(str(row.get("periods", "any"))):
			continue
		var cd := int(row.get("cooldown_days", 0))
		var last := int(GameState.chatter_last_day.get(cid, -999))
		if cd > 0 and GameState.day - last < cd:
			continue
		var w := maxi(1, int(row.get("weight", 1)))
		candidates.append({"row": row, "w": w})
		total_w += w
	if candidates.is_empty() or total_w <= 0:
		return ""
	var roll := GameState.rng.randi_range(1, total_w)
	var acc := 0
	for item in candidates:
		acc += int(item["w"])
		if roll <= acc:
			var id := str(item["row"].get("id", ""))
			GameState.chatter_last_day[id] = GameState.day
			var text := L10n.t("idle_chatter.%s.text" % id, "")
			GameState.last_chatter_text = text
			return text
	return ""
