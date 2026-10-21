class_name UIAtlasCatalog
extends RefCounted

## Catálogo de Texturas e Regiões Atlas da Interface (GUI_4x.png e buttons_4x.png).
## Fornece ícones em pixel art nativos para substituir emojis que desalinham em builds Web/Desktop.

const GUI_ATLAS: Texture2D = preload("res://Assets/UI/GUI_4x.png")
const BUTTONS_ATLAS: Texture2D = preload("res://Assets/UI/buttons_4x.png")

# Regiões principais de ícones (GUI_4x.png)
const REGIONS: Dictionary = {
	"heart": Rect2(256, 256, 32, 32),
	"skull": Rect2(288, 256, 32, 32),
	"sword": Rect2(320, 256, 32, 32),
	"lightning": Rect2(352, 256, 32, 32),
	"gem_orb": Rect2(256, 288, 32, 32),
	"coin": Rect2(288, 288, 32, 32),
	"mana_drop": Rect2(320, 288, 32, 32),
	"star": Rect2(352, 288, 32, 32),
	"dagger": Rect2(480, 0, 32, 32),
	"pawn_shield": Rect2(512, 0, 32, 32),
	"boot_wing": Rect2(544, 0, 32, 32),
	"arrows_double": Rect2(576, 0, 32, 32),
	"potion_empty": Rect2(480, 32, 32, 32),
	"potion_filled": Rect2(512, 32, 32, 32),
	"sparkle": Rect2(544, 32, 32, 32),
	"ring_amulet": Rect2(576, 32, 32, 32),
	"magic_wand": Rect2(480, 64, 32, 32),
	"armor_plate": Rect2(512, 64, 32, 32),
	"scroll_horn": Rect2(544, 64, 32, 32),
	"clock_timer": Rect2(576, 64, 32, 32),
	"battle_axe": Rect2(480, 96, 32, 32),
	"greaves_boots": Rect2(512, 96, 32, 32),
	"pickaxe": Rect2(544, 96, 32, 32),
	"padlock": Rect2(576, 96, 32, 32),
	"frame_unit_plate": Rect2(0, 224, 128, 96),
	"frame_dialog": Rect2(0, 0, 96, 128),
	"frame_portrait_gold": Rect2(100, 4, 88, 88),
	"frame_portrait_ornate": Rect2(196, 4, 88, 88),
	"bar_slider_bg": Rect2(196, 100, 88, 24),
	"bar_slider_fill": Rect2(292, 100, 88, 24)
}

# Regiões de ícones utilitários (buttons_4x.png)
const BUTTON_REGIONS: Dictionary = {
	"check": Rect2(320, 0, 32, 32),
	"cross": Rect2(352, 0, 32, 32),
	"pause": Rect2(384, 0, 32, 32),
	"play": Rect2(416, 0, 32, 32),
	"menu": Rect2(448, 0, 32, 32),
	"gear": Rect2(480, 0, 32, 32),
	"sound": Rect2(320, 32, 32, 32),
	"speaker": Rect2(352, 32, 32, 32),
	"chevron_right": Rect2(384, 32, 32, 32),
	"chevron_left": Rect2(416, 32, 32, 32),
	"chevron_up": Rect2(448, 32, 32, 32),
	"chevron_down": Rect2(480, 32, 32, 32)
}

static var _texture_cache: Dictionary = {}

static func get_icon_region(icon_name: String) -> Rect2:
	return REGIONS.get(icon_name, Rect2(0, 0, 32, 32))

static func get_icon_texture(icon_name: String) -> AtlasTexture:
	var cache_key := "gui_" + icon_name
	if _texture_cache.has(cache_key):
		return _texture_cache[cache_key]
	
	var atlas_tex := AtlasTexture.new()
	atlas_tex.atlas = GUI_ATLAS
	atlas_tex.region = get_icon_region(icon_name)
	atlas_tex.filter_clip = true
	_texture_cache[cache_key] = atlas_tex
	return atlas_tex

static func get_button_texture(btn_name: String) -> AtlasTexture:
	var cache_key := "btn_" + btn_name
	if _texture_cache.has(cache_key):
		return _texture_cache[cache_key]
		
	var atlas_tex := AtlasTexture.new()
	atlas_tex.atlas = BUTTONS_ATLAS
	atlas_tex.region = BUTTON_REGIONS.get(btn_name, Rect2(0, 0, 32, 32))
	atlas_tex.filter_clip = true
	_texture_cache[cache_key] = atlas_tex
	return atlas_tex

## Cria um TextureRect pré-configurado pronto para ser adicionado em containers da UI
static func create_icon_rect(icon_name: String, target_size: Vector2 = Vector2(16, 16)) -> TextureRect:
	var rect := TextureRect.new()
	rect.texture = get_icon_texture(icon_name)
	rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	rect.custom_minimum_size = target_size
	rect.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return rect

## Cria um TextureRect para ícones de botões (buttons_4x.png)
static func create_button_icon_rect(btn_name: String, target_size: Vector2 = Vector2(16, 16)) -> TextureRect:
	var rect := TextureRect.new()
	rect.texture = get_button_texture(btn_name)
	rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	rect.custom_minimum_size = target_size
	rect.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return rect

## Cria um conjunto de estrelas visuais em HBoxContainer usando a textura da estrela
static func create_star_row(star_count: int, star_size: Vector2 = Vector2(14, 14)) -> HBoxContainer:
	var container := HBoxContainer.new()
	container.add_theme_constant_override("separation", 2)
	container.alignment = BoxContainer.ALIGNMENT_CENTER
	for i in range(clampi(star_count, 1, 3)):
		var star_icon := create_icon_rect("star", star_size)
		container.add_child(star_icon)
	return container
