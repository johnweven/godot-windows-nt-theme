@tool
extends EditorPlugin

const FONT_PATH = "res://addons/windows_NT_theme/MS Sans Serif.ttf"
const THEME_PATH = "res://addons/windows_NT_theme/save1.tres"
const NT_NAVY_BLUE = Color("#000084") # Iconic active title bar blue code
const NT_GRAY = Color("#c0c0c0") # Mathematically precise corporate gray

func _enter_tree() -> void:
	# Run cleanly exactly once on project boot to keep loading completely instant
	_apply_universal_windows_nt_skin.call_deferred()

func _apply_universal_windows_nt_skin() -> void:
	var interface := get_editor_interface()
	if not interface:
		return

	var settings := interface.get_editor_settings()
	if not settings:
		return

	# 1. FORCE AUTHENTIC GREY: Zeroed contrast locks every single panel to true corporate gray
	settings.set("interface/theme/preset", "Custom")
	settings.set("interface/theme/base_color", NT_GRAY)
	settings.set("interface/theme/contrast", 0.0) 
	
	# 2. BYPASS RECOLORING FILTER: Forces the asset database to draw raw multi-colored PNG colors
	settings.set("interface/theme/icon_saturation", 1.0)
	settings.set("interface/theme/icon_max_contrast", 0.0)

	var base_control := interface.get_base_control()
	if not base_control:
		return

	var editor_theme := interface.get_editor_theme()
	if not editor_theme:
		return

	# 3. PORTABLE THEME GLOBALIZATION: Register the custom theme config path safely across external scopes
	if FileAccess.file_exists(THEME_PATH):
		var global_theme_path = ProjectSettings.globalize_path(THEME_PATH)
		settings.set_setting("interface/theme/custom_theme", global_theme_path)

	# 4. TYPOGRAPHY ENHANCEMENT: Loads your font file safely and smooths it across the interface
	if FileAccess.file_exists(FONT_PATH):
		var regular_font = load(FONT_PATH) as FontFile
		if regular_font:
			editor_theme.default_font = regular_font
			
			# Generate the bold variation strictly for the main window title text bar
			var bold_font_variation = FontVariation.new()
			bold_font_variation.base_font = regular_font
			bold_font_variation.variation_embolden = 1.2
			
			# Force override the top title bar area selectively and apply the bold weight
			_override_top_title_bar_elements(base_control, regular_font, bold_font_variation)

	# 5. DEFENSIVE THEME MERGE: Merges your custom entries on top of the live engine theme context.
	# This injects your artwork while keeping base engine icons perfectly intact.
	if FileAccess.file_exists(THEME_PATH):
		var custom_theme := load(THEME_PATH) as Theme
		if custom_theme:
			_merge_theme_styles_safely(editor_theme, custom_theme)

func _override_top_title_bar_elements(root: Control, regular_font: FontFile, bold_font: FontVariation) -> void:
	var title_bar = root.find_child("*EditorTitleBar*", true, false)
	if title_bar:
		# Apply font properties selectively to text nodes inside the header container
		_apply_top_bar_fonts_selective(title_bar, regular_font, bold_font)
		
		# Targeted dimension refresh: Fixes layout bounds without triggering size_changed console warnings
		if title_bar is Control:
			(title_bar as Control).update_minimum_size()

func _apply_top_bar_fonts_selective(node: Node, regular_font: FontFile, bold_font: FontVariation) -> void:
	if not node:
		return
		
	if node is Label or node is LinkButton or node is MenuButton:
		var txt: String = node.text
		# Only apply the bold FontVariation if this is the actual main title string text
		if "Windows NT" in txt or "UI Theme" in txt:
			node.add_theme_font_override("font", bold_font)
		else:
			# Keep secondary top buttons at a clean, regular weight
			node.add_theme_font_override("font", regular_font)
			
		node.add_theme_constant_override("outline_size", 0)
		node.add_theme_color_override("font_color", Color.BLACK)
		node.add_theme_color_override("font_outline_color", Color.BLACK)
		
	for child in node.get_children():
		_apply_top_bar_fonts_selective(child, regular_font, bold_font)

func _merge_theme_styles_safely(target: Theme, source: Theme) -> void:
	if not target or not source:
		return
		
	# Overlays ONLY your customized entries on top of the running engine theme, leaving base assets perfectly intact
	for color_type in source.get_color_type_list():
		for color_name in source.get_color_list(color_type):
			target.set_color(color_name, color_type, source.get_color(color_name, color_type))
	for const_type in source.get_constant_type_list():
		for const_name in source.get_constant_list(const_type):
			target.set_constant(const_name, const_type, source.get_constant(const_name, const_type))
	for style_type in source.get_stylebox_type_list():
		for style_name in source.get_stylebox_list(style_type):
			target.set_stylebox(style_name, style_type, source.get_stylebox(style_name, style_type))
	for font_type in source.get_font_type_list():
		for font_name in source.get_font_list(font_type):
			target.set_font(font_name, font_type, source.get_font(font_name, font_type))
	for icon_type in source.get_icon_type_list():
		for icon_name in source.get_icon_list(icon_type):
			target.set_icon(icon_name, icon_type, source.get_icon(icon_name, icon_type))

func _exit_tree() -> void:
	pass