extends SceneTree

## One-off tool: builds a shared UI Theme applied project-wide (gui/theme/custom in
## project.godot), so every screen picks it up with zero per-scene edits. No visual Kenney UI Pack
## was actually downloaded into asset dump/ (only kenney_ui-audio.zip, which is sound) — same
## situation as the floor tiles, so this is generated procedurally via StyleBoxFlat rather than
## waiting on another download.
##
## Run headless: godot --headless --path godot -s res://tools/build_ui_theme.gd

const OUT_PATH := "res://resources/theme/detective_theme.tres"

# a warm, dark detective-noir palette — matches the tone already established by the dorm's
# brightened-but-still-warm floor tint, not a generic default-Godot blue
const PANEL_BG := Color(0.14, 0.12, 0.11, 0.96)
const PANEL_BORDER := Color(0.55, 0.42, 0.24, 1.0)
const BTN_NORMAL := Color(0.24, 0.19, 0.15, 1.0)
const BTN_HOVER := Color(0.34, 0.27, 0.19, 1.0)
const BTN_PRESSED := Color(0.55, 0.42, 0.24, 1.0)
const BTN_DISABLED := Color(0.18, 0.16, 0.15, 0.6)
const FONT_COLOR := Color(0.92, 0.88, 0.80, 1.0)
const FONT_DISABLED := Color(0.55, 0.52, 0.48, 1.0)


func _box(bg: Color, border: Color = Color(0, 0, 0, 0), border_width: int = 0, radius: int = 4) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.set_border_width_all(border_width)
	sb.border_color = border
	sb.set_corner_radius_all(radius)
	sb.set_content_margin_all(8)
	return sb


func _initialize() -> void:
	DirAccess.make_dir_recursive_absolute("res://resources/theme")
	var theme := Theme.new()

	theme.set_stylebox("panel", "Panel", _box(PANEL_BG, PANEL_BORDER, 2))
	theme.set_stylebox("panel", "PanelContainer", _box(PANEL_BG, PANEL_BORDER, 2))

	theme.set_stylebox("normal", "Button", _box(BTN_NORMAL, PANEL_BORDER, 1))
	theme.set_stylebox("hover", "Button", _box(BTN_HOVER, PANEL_BORDER, 1))
	theme.set_stylebox("pressed", "Button", _box(BTN_PRESSED, PANEL_BORDER, 1))
	theme.set_stylebox("disabled", "Button", _box(BTN_DISABLED))
	theme.set_color("font_color", "Button", FONT_COLOR)
	theme.set_color("font_hover_color", "Button", FONT_COLOR)
	theme.set_color("font_pressed_color", "Button", FONT_COLOR)
	theme.set_color("font_disabled_color", "Button", FONT_DISABLED)

	theme.set_color("font_color", "Label", FONT_COLOR)
	theme.set_color("font_shadow_color", "Label", Color(0, 0, 0, 0.6))
	theme.set_constant("shadow_offset_x", "Label", 1)
	theme.set_constant("shadow_offset_y", "Label", 1)

	theme.set_stylebox("panel", "PopupPanel", _box(PANEL_BG, PANEL_BORDER, 2))

	var err := ResourceSaver.save(theme, OUT_PATH)
	if err != OK:
		printerr("failed to save theme: %d" % err)
	else:
		print("saved %s" % OUT_PATH)

	print("BUILD_UI_THEME_DONE")
	print("NOTE: set [gui] theme/custom=\"%s\" in project.godot by hand — a ConfigFile" % OUT_PATH)
	print("      round-trip of the whole file risks reformatting sections it shouldn't touch.")
	quit()
