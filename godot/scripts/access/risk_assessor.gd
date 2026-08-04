extends RefCounted
class_name RiskAssessor

## Safe / Risky / Dangerous, from whether the area is off-limits right now, whether the action
## itself is intrusive, and whether anyone could see you doing it — plus how loud the UI is about
## it, which is difficulty-scaled (Difficulty.risk_hints: explicit/shown/subtle/hidden).

static func assess(restricted: bool, intrusive: bool, witnesses: int) -> String:
	if not restricted and not intrusive:
		return "safe"
	if witnesses > 0:
		return "dangerous"
	return "risky"


static func hint_for(risk: String, risk_hints: String) -> String:
	if risk == "safe" or risk == "":
		return ""
	match risk_hints:
		"explicit", "shown":
			return "  [%s]" % risk.to_upper()
		"subtle":
			return "  [?]"
		_:
			return ""
