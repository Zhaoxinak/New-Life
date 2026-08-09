extends Node


const SEGMENT_SEP: = "|||"
const MIN_SEGMENT_SEC: = 0.35
const CHOICE_DELAY_SEC: = 0.4
const CHOICE_STAGGER_SEC: = 0.12

const BACKDROP_WARM: = Color(0.08, 0.06, 0.04, 0.55)
const BACKDROP_COLD: = Color(0.04, 0.06, 0.12, 0.72)


func split_body(body: String) -> PackedStringArray:
	var text: = body.strip_edges()
	if text == "":
		return PackedStringArray([""])
	if not text.contains(SEGMENT_SEP):
		return PackedStringArray([text])
	var parts: = text.split(SEGMENT_SEP, false)
	var out: PackedStringArray = PackedStringArray()
	for p in parts:
		var s: = str(p).strip_edges()
		if s != "":
			out.append(s)
	if out.is_empty():
		out.append(text)
	return out


func _base(
	stingers: Array = [], 
	dim_from: int = -1, 
	stagger: bool = false, 
	delay: float = 0.0, 
	cold: bool = false, 
	extra: Dictionary = {}
) -> Dictionary:
	var d: = {
		"stingers": stingers, 
		"dim_from_segment": dim_from, 
		"choice_stagger": stagger, 
		"choice_delay": delay, 
		"backdrop_cold": cold, 
		"duck_ambience": 0.0, 
		"post_choice_pause": 0.0, 
		"accent_speaker": "", 
		"choice_stingers": {}, 
		"route_choice_styles": false, 
	}
	for k in extra.keys():
		d[k] = extra[k]
	return d


func preset_for(event_id: String) -> Dictionary:


	match event_id:
		"ev_day1_intro":
			return _base(["", "laugh", ""], 1, false, CHOICE_DELAY_SEC, true, {
				"duck_ambience": 0.4, 
				"post_choice_pause": 0.55, 
			})
		"ev_day6_su_distance":
			return _base(["", "hush"], 1, false, CHOICE_DELAY_SEC, true, {
				"choice_stingers": {"ch_d6_ask": "thud", "ch_d6_hold": "hush"}, 
			})
		"ev_day7_choice":
			return _base(["tide", ""], 0, true, CHOICE_DELAY_SEC, true, {
				"route_choice_styles": true, 
			})
		"ev_b_public_clash":
			return _base(["shatter", ""], 0, false, CHOICE_DELAY_SEC, true)
		"ev_day5_promotion_stolen":
			return _base(["thud", ""], 0, false, CHOICE_DELAY_SEC, true, {
				"duck_ambience": 0.55, 
				"post_choice_pause": 0.45, 
			})
		"ev_day3_son_notice":
			return _base(["", "laugh"], 1, false, CHOICE_DELAY_SEC, true, {
				"accent_speaker": "zhou_shaoting", 
			})
		"ev_a_first_strike":
			return _base(["paper", ""], 0, false, CHOICE_DELAY_SEC, true)
		"ev_c_first_short":
			return _base(["tick", ""], 0, false, CHOICE_DELAY_SEC, true)
		"ev_b_d22_rain":
			return _base(["rain", ""], 0, false, CHOICE_DELAY_SEC, true)
		"ev_b_d24_boardroom_noise":
			return _base(["thud", ""], 0, false, CHOICE_DELAY_SEC, true)
		"ev_d16_festival":
			return _base(["bell", ""], 0, false, 0.25, true)
		"ev_d20_storm":
			return _base(["tide", ""], 0, false, 0.25, true)
		_:
			return _base()


func stinger_for_segment(preset: Dictionary, segment_index: int) -> String:
	var stingers: Array = preset.get("stingers", [])
	if segment_index < 0 or segment_index >= stingers.size():
		return ""
	return str(stingers[segment_index]).strip_edges()


func choice_stinger(preset: Dictionary, choice_id: String) -> String:
	var map: Dictionary = preset.get("choice_stingers", {})
	return str(map.get(choice_id, "")).strip_edges()


func route_choice_weight(choice_id: String) -> String:

	match choice_id:
		"ch_d7_endure":
			return "soft"
		"ch_d7_defect":
			return "hard"
		"ch_d7_finance":
			return "probe"
		_:
			return "normal"


func ending_stage(ending_id: String, win: bool) -> Dictionary:

	if not win:
		return {
			"staged": true, 
			"stinger": "", 
			"veil": Color(0.22, 0.06, 0.06, 0.9), 
			"use_fail_sfx": true, 
		}
	match ending_id:
		"ending_b":
			return {
				"staged": true, 
				"stinger": "shatter", 
				"veil": Color(0.04, 0.05, 0.1, 0.88), 
				"use_fail_sfx": false, 
			}
		"ending_a":
			return {
				"staged": true, 
				"stinger": "paper", 
				"veil": Color(0.05, 0.1, 0.08, 0.88), 
				"use_fail_sfx": false, 
			}
		"ending_c":
			return {
				"staged": true, 
				"stinger": "tick", 
				"veil": Color(0.1, 0.08, 0.04, 0.88), 
				"use_fail_sfx": false, 
			}
		_:
			return {
				"staged": false, 
				"stinger": "", 
				"veil": Color(0.1, 0.07, 0.04, 0.72), 
				"use_fail_sfx": false, 
			}
