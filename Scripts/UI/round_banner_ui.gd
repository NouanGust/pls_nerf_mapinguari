class_name RoundBannerUI
extends RefCounted

## Banner Animado de Resolução de Rodada (Vitória / Derrota / Empate)

const UIAtlasCatalog = preload("res://Scripts/UI/ui_atlas_catalog.gd")

var root: Control
var resolution_banner: Control
var banner_title: Label
var banner_detail: Label
var banner_icon: TextureRect
var banner_tween: Tween

func setup(p_root: Control) -> void:
	root = p_root
	if not root:
		return
	resolution_banner = root.get_node_or_null("RoundResolutionBanner")
	if resolution_banner:
		banner_title = resolution_banner.get_node_or_null("Content/VBox/BannerTitle") as Label
		banner_detail = resolution_banner.get_node_or_null("Content/VBox/BannerDetail") as Label
		banner_icon = resolution_banner.get_node_or_null("Content/BannerIcon") as TextureRect

func show_banner(earned_gold: int, is_draw: bool, player_won: bool, round_gold: int = 0, streak_gold: int = 0, interest_gold: int = 0) -> void:
	if not resolution_banner:
		setup(root)
	if not resolution_banner:
		return
	
	if banner_icon:
		banner_icon.texture = UIAtlasCatalog.get_icon_texture("coin")
	
	if is_draw:
		if banner_title:
			banner_title.text = "EMPATE! +%d OURO" % earned_gold
			banner_title.add_theme_color_override("font_color", Color("#91c9d8"))
		if banner_detail:
			banner_detail.text = "+%dg round · Sequência zerada · +%dg juros" % [round_gold, interest_gold]
	elif player_won:
		if banner_title:
			banner_title.text = "VITÓRIA! +%d OURO" % earned_gold
			banner_title.add_theme_color_override("font_color", Color("#2ecc71"))
		if banner_detail:
			banner_detail.text = "+%dg round · +%dg sequência · +%dg juros" % [round_gold, streak_gold, interest_gold]
	else:
		if banner_title:
			banner_title.text = "DERROTA! +%d OURO" % earned_gold
			banner_title.add_theme_color_override("font_color", Color("#e74c3c"))
		if banner_detail:
			banner_detail.text = "+%dg round · +%dg sequência · +%dg juros" % [round_gold, streak_gold, interest_gold]
	
	resolution_banner.show()
	resolution_banner.modulate.a = 0.0
	if banner_tween and banner_tween.is_running():
		banner_tween.kill()
	if root and root.is_inside_tree():
		banner_tween = root.create_tween()
		banner_tween.tween_property(resolution_banner, "modulate:a", 1.0, 0.22)
		banner_tween.tween_interval(1.8)
		banner_tween.tween_property(resolution_banner, "modulate:a", 0.0, 0.3)
		banner_tween.tween_callback(resolution_banner.hide)
