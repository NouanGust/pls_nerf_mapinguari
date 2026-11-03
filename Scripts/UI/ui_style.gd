class_name UIStyle
extends RefCounted

## UIStyle: Sistema de estilos e temas inspirado em TFT (Hextech / Dark Slate / Gold).
## Centraliza todas as cores, bordas, sombras e geradores de StyleBox para facilitar
## a manutenção e futuras modificações cosméticas em um único arquivo.

# --- Paleta de Cores Principais ---
const BG_DARK := Color(0.04, 0.08, 0.12, 0.95)           # #0a141f - Fundo escuro translúcido
const BG_DARK_ALT := Color(0.06, 0.11, 0.16, 0.96)       # #0f1c29 - Fundo alternativo
const BG_CARD := Color(0.05, 0.07, 0.10, 0.97)           # #0d121a - Fundo das cartas de loja
const BG_SLOT := Color(0.08, 0.12, 0.16, 0.92)           # #141f29 - Fundo do pedestal do banco
const BG_SLOT_EMPTY := Color(0.06, 0.09, 0.12, 0.85)     # #0f171f - Pedestal vazio

# --- Botões ---
const BG_BUTTON_NORMAL := Color(0.08, 0.15, 0.22, 0.95)   # #142638
const BG_BUTTON_HOVER := Color(0.12, 0.22, 0.32, 0.98)    # #1f3852
const BG_BUTTON_PRESSED := Color(0.05, 0.10, 0.15, 0.98)  # #0d1a26
const BG_BUTTON_DISABLED := Color(0.06, 0.08, 0.10, 0.60) # #0f141a

# --- Bordas e Detalhes Metálicos ---
const BORDER_GOLD := Color(0.78, 0.67, 0.43, 1.0)         # #c8ab6e - Ouro Hextech TFT
const BORDER_GOLD_BRIGHT := Color(0.96, 0.88, 0.67, 1.0)  # #f5e0ab - Ouro reluzente
const BORDER_GOLD_MUTED := Color(0.48, 0.38, 0.22, 0.9)   # #7a6138 - Bronze metálico
const BORDER_SLATE := Color(0.20, 0.28, 0.35, 0.90)       # #334759 - Borda de pedra/ardósia
const BORDER_CYAN := Color(0.16, 0.78, 0.72, 1.0)         # #29c7b8 - Ciano rúnico
const BORDER_RED := Color(0.90, 0.30, 0.25, 1.0)          # #e64d40 - Alerta / dano

# --- Cores de Raridade por Tier (1 a 5) ---
const TIER_COLORS := {
	1: Color(0.62, 0.66, 0.72),  # Tier 1: Cinza / Prata (#9ea8b8)
	2: Color(0.17, 0.74, 0.46),  # Tier 2: Verde Esmeralda (#2bbd75)
	3: Color(0.15, 0.52, 0.95),  # Tier 3: Azul Cobalto (#2685f2)
	4: Color(0.68, 0.26, 0.95),  # Tier 4: Roxo Ametista (#ad42f2)
	5: Color(1.00, 0.55, 0.10),  # Tier 5: Ouro / Âmbar (#ff8c1a)
}

# --- Cores de Texto ---
const TEXT_GOLD := Color(0.94, 0.88, 0.75)                 # #f0e0c0 - Texto principal dourado
const TEXT_GOLD_BRIGHT := Color(1.0, 0.87, 0.35)          # #ffde59 - Moedas / valores
const TEXT_WHITE := Color(0.96, 0.97, 0.98)               # #f5f7fa
const TEXT_MUTED := Color(0.60, 0.67, 0.72)               # #99abb8
const TEXT_CYAN := Color(0.30, 0.88, 0.82)                # #4de0d1
const TEXT_HEALTH := Color(0.22, 0.85, 0.55)              # #38d98c

# --- Geradores de StyleBox ---

static func make_panel_style(bg: Color = BG_DARK, border: Color = BORDER_GOLD, border_width: int = 2, radius: int = 6) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg
	style.border_color = border
	style.set_border_width_all(border_width)
	style.set_corner_radius_all(radius)
	style.shadow_color = Color(0.0, 0.0, 0.0, 0.45)
	style.shadow_size = 6
	style.content_margin_left = 10.0
	style.content_margin_right = 10.0
	style.content_margin_top = 8.0
	style.content_margin_bottom = 8.0
	return style

static func make_card_style(tier: int, hovered: bool = false) -> StyleBoxFlat:
	var tier_color: Color = TIER_COLORS.get(tier, Color.WHITE)
	var style := StyleBoxFlat.new()
	style.bg_color = BG_CARD
	style.border_color = tier_color.lightened(0.25) if hovered else tier_color
	style.set_border_width_all(3 if hovered else 2)
	style.set_corner_radius_all(5)
	style.shadow_color = Color(tier_color.r, tier_color.g, tier_color.b, 0.35 if hovered else 0.15)
	style.shadow_size = 10 if hovered else 4
	style.content_margin_left = 6.0
	style.content_margin_right = 6.0
	style.content_margin_top = 6.0
	style.content_margin_bottom = 6.0
	return style

static func make_pedestal_style(border: Color = BORDER_SLATE, occupied: bool = false) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = BG_SLOT if occupied else BG_SLOT_EMPTY
	style.border_color = border
	style.set_border_width_all(2)
	style.set_corner_radius_all(4)
	style.shadow_color = Color(0.0, 0.0, 0.0, 0.3)
	style.shadow_size = 3
	style.content_margin_left = 4.0
	style.content_margin_right = 4.0
	style.content_margin_top = 4.0
	style.content_margin_bottom = 4.0
	return style

static func make_button_style(bg: Color, border: Color = BORDER_GOLD, radius: int = 4) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg
	style.border_color = border
	style.set_border_width_all(2)
	style.set_corner_radius_all(radius)
	style.content_margin_left = 10.0
	style.content_margin_right = 10.0
	style.content_margin_top = 6.0
	style.content_margin_bottom = 6.0
	return style

static func apply_button_skin(button: Button, border_color: Color = BORDER_GOLD, gold_text: bool = true) -> void:
	if not is_instance_valid(button):
		return
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	var normal := make_button_style(BG_BUTTON_NORMAL, border_color)
	var hover := make_button_style(BG_BUTTON_HOVER, border_color.lightened(0.25))
	var pressed := make_button_style(BG_BUTTON_PRESSED, border_color.darkened(0.2))
	var disabled := make_button_style(BG_BUTTON_DISABLED, BORDER_SLATE)
	
	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", pressed)
	button.add_theme_stylebox_override("disabled", disabled)
	button.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	
	var text_col := TEXT_GOLD if gold_text else TEXT_WHITE
	button.add_theme_color_override("font_color", text_col)
	button.add_theme_color_override("font_hover_color", TEXT_GOLD_BRIGHT)
	button.add_theme_color_override("font_pressed_color", text_col.darkened(0.2))
	button.add_theme_color_override("font_disabled_color", TEXT_MUTED)
