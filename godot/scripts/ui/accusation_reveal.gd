extends CanvasLayer

signal confirmed(suspect_id: String, ending_id: String)
signal cancelled()

@onready var _portrait: TextureRect = $Backdrop/Panel/Margin/VBox/Body/PortraitPanel/Margin/Portrait
@onready var _name: Label = $Backdrop/Panel/Margin/VBox/Body/Info/Name
@onready var _role: Label = $Backdrop/Panel/Margin/VBox/Body/Info/Role
@onready var _headline: Label = $Backdrop/Panel/Margin/VBox/Headline
@onready var _summary: Label = $Backdrop/Panel/Margin/VBox/Body/Info/Summary
@onready var _evidence: Label = $Backdrop/Panel/Margin/VBox/Body/Info/Evidence
@onready var _confirm: Button = $Backdrop/Panel/Margin/VBox/Buttons/Confirm
@onready var _back: Button = $Backdrop/Panel/Margin/VBox/Buttons/Back

var _suspect_id := ""
var _ending_id := ""

func _ready() -> void:
	visible = false
	_confirm.pressed.connect(_on_confirm)
	_back.pressed.connect(_on_back)

func open(suspect_id: String, result: Dictionary) -> void:
	_suspect_id = suspect_id
	_ending_id = str(result.get("ending_id", ""))
	var suspect: Dictionary = CaseData.SUSPECTS.get(suspect_id, {})
	_name.text = str(suspect.get("name", suspect_id)).to_upper()
	_role.text = _role_for(suspect_id)
	_headline.text = "THE CASE TURNS"
	_summary.text = "The evidence is sufficient to move forward. Every clue you found will become part of the accusation record." if bool(result.get("accepted", false)) else "The evidence is not sufficient to make this accusation."
	var strength := int(result.get("strength", 0))
	var threshold := int(result.get("threshold", 0))
	_evidence.text = "CASE FILE  •  EVIDENCE %02d / %02d" % [strength, threshold]
	var portrait_path := "res://assets/ui/portraits/%s.svg" % suspect_id
	var tex := load(portrait_path)
	if tex is Texture2D:
		_portrait.texture = tex
	_confirm.disabled = not bool(result.get("accepted", false))
	visible = true
	$Backdrop/Panel.modulate.a = 0.0
	var tw := create_tween()
	tw.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property($Backdrop/Panel, "modulate:a", 1.0, 0.22)
	SFXHelper.accusation_reveal()
	Effects.shake_subtle()

func _on_confirm() -> void:
	if _suspect_id == "":
		return
	confirmed.emit(_suspect_id, _ending_id)
	close()

func _on_back() -> void:
	cancelled.emit()
	close()

func close() -> void:
	visible = false

func _role_for(id: String) -> String:
	return {
		"alex": "RESIDENT ADVISOR",
		"jordan": "THEATER STUDENT",
		"sam": "COMPUTER SCIENCE STUDENT",
		"riley": "PRE-MED STUDENT",
		"morgan": "TRACK ATHLETE",
		"casey": "ART STUDENT",
		"dean": "DEAN WHITFIELD",
	}.get(id, "SUSPECT")
