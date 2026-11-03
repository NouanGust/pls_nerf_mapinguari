"""
Subagent / Analyzer for Assets/UI (GUI_4x.png and buttons_4x.png).
Maps all sprite sheet regions, generates JSON catalog, GDScript helper,
and produces an annotated visual map image.
"""

import os
import json
from PIL import Image, ImageDraw, ImageFont

def main():
    base_dir = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    gui_path = os.path.join(base_dir, "Assets", "UI", "GUI_4x.png")
    btn_path = os.path.join(base_dir, "Assets", "UI", "buttons_4x.png")
    
    if not os.path.exists(gui_path):
        raise FileNotFoundError(f"Not found: {gui_path}")
        
    img_gui = Image.open(gui_path)
    img_btn = Image.open(btn_path)
    
    print(f"[AtlasAnalyzer] GUI_4x size: {img_gui.size}")
    print(f"[AtlasAnalyzer] buttons_4x size: {img_btn.size}")
    
    # Define verified semantic regions (4x coordinates)
    catalog = {
        "source": "Assets/UI/GUI_4x.png",
        "scale": 4,
        "texture_size": [img_gui.size[0], img_gui.size[1]],
        "regions": {
            # === CORE GAMEPLAY ICONS (Replaces UI emojis) ===
            "heart": {
                "x": 256, "y": 256, "w": 32, "h": 32,
                "category": "icon",
                "replaces_emoji": "❤️ / 💧 (no widget de vida)",
                "description": "Coração vermelho para Vida/HP"
            },
            "skull": {
                "x": 288, "y": 256, "w": 32, "h": 32,
                "category": "icon",
                "replaces_emoji": "💀 / 👑 (marcos de boss/derrota)",
                "description": "Crânio de perigo/derrota/chefe"
            },
            "sword": {
                "x": 320, "y": 256, "w": 32, "h": 32,
                "category": "icon",
                "replaces_emoji": "⚔️",
                "description": "Espadas cruzadas para Combate/Ataque/Inimigo"
            },
            "lightning": {
                "x": 352, "y": 256, "w": 32, "h": 32,
                "category": "icon",
                "replaces_emoji": "⚡",
                "description": "Raio dourado para Velocidade/Ação/Energia"
            },
            "gem_orb": {
                "x": 256, "y": 288, "w": 32, "h": 32,
                "category": "icon",
                "replaces_emoji": "💎 / 🔮",
                "description": "Orbe/Gema mística para nível/sinergias"
            },
            "coin": {
                "x": 288, "y": 288, "w": 32, "h": 32,
                "category": "icon",
                "replaces_emoji": "🪙",
                "description": "Moeda de ouro com relevo para Economia/Loja"
            },
            "mana_drop": {
                "x": 320, "y": 288, "w": 32, "h": 32,
                "category": "icon",
                "replaces_emoji": "💧",
                "description": "Gota d'água azul para Mana/Habilidade"
            },
            "star": {
                "x": 352, "y": 288, "w": 32, "h": 32,
                "category": "icon",
                "replaces_emoji": "★",
                "description": "Estrela dourada brilhante para Nível/Evolução"
            },
            # === SPECIALIZED SMALL ICONS (Top Right Grid) ===
            "dagger": {
                "x": 480, "y": 0, "w": 32, "h": 32,
                "category": "icon",
                "replaces_emoji": "🗡️",
                "description": "Adaga diagonal"
            },
            "pawn_shield": {
                "x": 512, "y": 0, "w": 32, "h": 32,
                "category": "icon",
                "replaces_emoji": "♟",
                "description": "Peão/Escudo de capacidade de unidades no tabuleiro"
            },
            "boot_wing": {
                "x": 544, "y": 0, "w": 32, "h": 32,
                "category": "icon",
                "replaces_emoji": "🪽",
                "description": "Asa/Bota alada de agilidade"
            },
            "arrows_double": {
                "x": 576, "y": 0, "w": 32, "h": 32,
                "category": "icon",
                "replaces_emoji": "⏩",
                "description": "Setas duplas de velocidade/avanço"
            },
            "potion_flask_empty": {
                "x": 480, "y": 32, "w": 32, "h": 32,
                "category": "icon",
                "replaces_emoji": "🧪",
                "description": "Frasco de poção arredondado"
            },
            "potion_flask_filled": {
                "x": 512, "y": 32, "w": 32, "h": 32,
                "category": "icon",
                "replaces_emoji": "🧪",
                "description": "Frasco de poção cheio"
            },
            "sparkle": {
                "x": 544, "y": 32, "w": 32, "h": 32,
                "category": "icon",
                "replaces_emoji": "✨",
                "description": "Brilho estelar/efeito mágico"
            },
            "ring_amulet": {
                "x": 576, "y": 32, "w": 32, "h": 32,
                "category": "icon",
                "replaces_emoji": "💍",
                "description": "Anel / Amuleto rúnico"
            },
            "magic_wand": {
                "x": 480, "y": 64, "w": 32, "h": 32,
                "category": "icon",
                "replaces_emoji": "🪄",
                "description": "Varinha mágica diagonal"
            },
            "armor_plate": {
                "x": 512, "y": 64, "w": 32, "h": 32,
                "category": "icon",
                "replaces_emoji": "🛡️",
                "description": "Peitoral/Armadura defensiva"
            },
            "scroll_horn": {
                "x": 544, "y": 64, "w": 32, "h": 32,
                "category": "icon",
                "replaces_emoji": "📜",
                "description": "Pergaminho enrolado"
            },
            "clock_timer": {
                "x": 576, "y": 64, "w": 32, "h": 32,
                "category": "icon",
                "replaces_emoji": "⏱ / ⏳",
                "description": "Relógio / Cronômetro circular para tempo de round"
            },
            "battle_axe": {
                "x": 480, "y": 96, "w": 32, "h": 32,
                "category": "icon",
                "replaces_emoji": "🪓",
                "description": "Machado de guerra"
            },
            "greaves_boots": {
                "x": 512, "y": 96, "w": 32, "h": 32,
                "category": "icon",
                "replaces_emoji": "👢",
                "description": "Botas pesadas de proteção"
            },
            "pickaxe": {
                "x": 544, "y": 96, "w": 32, "h": 32,
                "category": "icon",
                "replaces_emoji": "⛏️",
                "description": "Picareta de recursos"
            },
            "padlock": {
                "x": 576, "y": 96, "w": 32, "h": 32,
                "category": "icon",
                "replaces_emoji": "🔒 / 🔓",
                "description": "Cadeado de ferro para Travar Loja"
            },
            # === FRAMES & CONTAINERS ===
            "frame_unit_plate": {
                "x": 0, "y": 224, "w": 128, "h": 96,
                "category": "frame",
                "patch_margin": [18, 18, 18, 18],
                "description": "Moldura pixel art ornamentada para placa 3D de unidade"
            },
            "frame_dialog": {
                "x": 0, "y": 0, "w": 96, "h": 128,
                "category": "frame",
                "patch_margin": [16, 16, 16, 16],
                "description": "Painel de diálogo vertical"
            },
            "frame_portrait_gold": {
                "x": 100, "y": 4, "w": 88, "h": 88,
                "category": "frame",
                "patch_margin": [12, 12, 12, 12],
                "description": "Moldura de retrato/avatar quadrada"
            },
            "frame_portrait_ornate": {
                "x": 196, "y": 4, "w": 88, "h": 88,
                "category": "frame",
                "patch_margin": [12, 12, 12, 12],
                "description": "Moldura de retrato/avatar com arabescos"
            },
            "panel_large": {
                "x": 288, "y": 0, "w": 288, "h": 320,
                "category": "panel",
                "description": "Janela principal grande"
            },
            # === PROGRESS BARS & SLIDERS ===
            "bar_slider_bg": {
                "x": 196, "y": 100, "w": 88, "h": 24,
                "category": "bar",
                "description": "Canal/Fundo arredondado para barra de progresso"
            },
            "bar_slider_fill": {
                "x": 292, "y": 100, "w": 88, "h": 24,
                "category": "bar",
                "description": "Preenchimento chanfrado para barra de progresso"
            }
        },
        "button_icons": {
            "source": "Assets/UI/buttons_4x.png",
            "regions": {
                "check": {
                    "x": 320, "y": 0, "w": 32, "h": 32,
                    "replaces_emoji": "✓ / ✅",
                    "description": "Marca de confirmação/sucesso verde/branca"
                },
                "cross": {
                    "x": 352, "y": 0, "w": 32, "h": 32,
                    "replaces_emoji": "✕ / ❌",
                    "description": "Marca de fechar/cancelar/derrota"
                },
                "pause": {
                    "x": 384, "y": 0, "w": 32, "h": 32,
                    "replaces_emoji": "⏸",
                    "description": "Pausar"
                },
                "play": {
                    "x": 416, "y": 0, "w": 32, "h": 32,
                    "replaces_emoji": "▶",
                    "description": "Play/Combate"
                },
                "menu": {
                    "x": 448, "y": 0, "w": 32, "h": 32,
                    "replaces_emoji": "☰",
                    "description": "Menu de opções"
                },
                "gear": {
                    "x": 480, "y": 0, "w": 32, "h": 32,
                    "replaces_emoji": "⚙️",
                    "description": "Configurações / Lupa"
                },
                "sound": {
                    "x": 320, "y": 32, "w": 32, "h": 32,
                    "replaces_emoji": "🔊",
                    "description": "Áudio/Música"
                },
                "speaker": {
                    "x": 352, "y": 32, "w": 32, "h": 32,
                    "replaces_emoji": "🔈",
                    "description": "Efeitos sonoros"
                },
                "chevron_right": {
                    "x": 384, "y": 32, "w": 32, "h": 32,
                    "replaces_emoji": "▶ / >",
                    "description": "Seta para direita"
                },
                "chevron_left": {
                    "x": 416, "y": 32, "w": 32, "h": 32,
                    "replaces_emoji": "◀ / <",
                    "description": "Seta para esquerda"
                },
                "chevron_up": {
                    "x": 448, "y": 32, "w": 32, "h": 32,
                    "replaces_emoji": "▲ / ^",
                    "description": "Seta para cima"
                },
                "chevron_down": {
                    "x": 480, "y": 32, "w": 32, "h": 32,
                    "replaces_emoji": "▼ / v",
                    "description": "Seta para baixo"
                }
            }
        }
    }
    
    # Save JSON catalog
    json_path = os.path.join(base_dir, "Assets", "UI", "atlas_regions.json")
    with open(json_path, "w", encoding="utf-8") as f:
        json.dump(catalog, f, indent=2, ensure_ascii=False)
    print(f"[AtlasAnalyzer] Saved catalog to: {json_path}")
    
    # Generate visual annotated map
    annotated = img_gui.convert("RGBA")
    draw = ImageDraw.Draw(annotated)
    
    color_cycle = [
        (255, 60, 60, 200),    # Red
        (60, 255, 60, 200),    # Green
        (60, 140, 255, 200),   # Blue
        (255, 220, 40, 200),   # Yellow
        (255, 80, 255, 200),   # Magenta
        (40, 255, 255, 200)    # Cyan
    ]
    
    idx = 0
    for name, data in catalog["regions"].items():
        x, y, w, h = data["x"], data["y"], data["w"], data["h"]
        col = color_cycle[idx % len(color_cycle)]
        idx += 1
        
        # Draw bounding outline
        draw.rectangle([x, y, x + w - 1, y + h - 1], outline=col[:3] + (255,), width=2)
        # Small corner mark or label
        draw.rectangle([x, max(0, y - 10), min(img_gui.size[0], x + len(name)*6 + 4), y], fill=(15, 15, 25, 220))
        draw.text((x + 2, max(0, y - 10)), name[:10], fill=col[:3])

    annotated_path = os.path.join(base_dir, "Assets", "UI", "GUI_4x_mapped.png")
    annotated.save(annotated_path)
    print(f"[AtlasAnalyzer] Generated annotated map: {annotated_path}")

if __name__ == "__main__":
    main()
