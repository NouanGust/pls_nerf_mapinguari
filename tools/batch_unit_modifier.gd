extends SceneTree

# ==============================================================================
# FERRAMENTA DE MODIFICAÇÃO EM LOTE DE UNIDADES (FOLCHESS)
# ==============================================================================
# Permite alterar stats de todas as unidades (ou filtradas por tier) de uma vez:
#   - max_health (vida)
#   - attack_damage (dano)
#   - armor (defesa/armadura)
#   - magic_resist (resistência mágica)
#   - attack_speed (velocidade de ataque)
#   - ability_damage (dano de habilidade)
#   - ability_shield (escudo de habilidade)
#   - ability_heal (cura de habilidade)
#
# Exemplos de uso via terminal:
#   godot --headless -s tools/batch_unit_modifier.gd -- --health-mult=0.9 --damage-mult=0.85
#   godot --headless -s tools/batch_unit_modifier.gd -- --armor-mult=0.8 --tier=3
#   godot --headless -s tools/batch_unit_modifier.gd -- --health-mult=0.9 --dry-run
#   godot --headless -s tools/batch_unit_modifier.gd -- --restore
# ==============================================================================

const UNITS_DIR := "res://resources/units/"
const BACKUP_BASE_DIR := "res://resources/units/backups/"

func _init() -> void:
	var args := OS.get_cmdline_user_args()
	if args.is_empty():
		# Também verifica argumentos pós "--"
		var all_args := OS.get_cmdline_args()
		var dash_dash := all_args.find("--")
		if dash_dash != -1 and dash_dash < all_args.size() - 1:
			args = all_args.slice(dash_dash + 1)
	
	run_with_args(args)
	quit(0)

static func run_with_args(args: Array) -> void:
	if "--help" in args or "-h" in args:
		print_help()
		return
	
	if "--restore" in args:
		restore_latest_backup()
		return
	
	var config := parse_arguments(args)
	if config.get("has_multipliers", false) or config.get("force", false):
		execute_batch(config)
	else:
		print_help()

static func print_help() -> void:
	print("\n" + "=".repeat(75))
	print("  FOLCHESS - FERRAMENTA DE ALTERAÇÃO EM LOTE DE STATS DAS UNIDADES")
	print("=".repeat(75))
	print("Uso: godot --headless -s tools/batch_unit_modifier.gd -- [opções]\n")
	print("Multiplicadores (Ex: 0.9 = diminuir 10%, 1.15 = aumentar 15%):")
	print("  --health-mult=VAL         Multiplicador de vida máxima (max_health)")
	print("  --damage-mult=VAL         Multiplicador de dano de ataque (attack_damage)")
	print("  --armor-mult=VAL          Multiplicador de armadura/defesa (armor)")
	print("  --mr-mult=VAL             Multiplicador de resistência mágica (magic_resist)")
	print("  --atkspd-mult=VAL         Multiplicador de velocidade de ataque (attack_speed)")
	print("  --ability-damage-mult=VAL Multiplicador de dano de habilidade")
	print("  --ability-shield-mult=VAL Multiplicador de escudo de habilidade")
	print("  --ability-heal-mult=VAL   Multiplicador de cura de habilidade\n")
	print("Filtros e Modos:")
	print("  --tier=N                  Modifica apenas unidades do Tier N (1 a 5)")
	print("  --dry-run                 Simula as mudanças e imprime tabela sem salvar")
	print("  --no-backup               Desativa a criação automática de backup")
	print("  --restore                 Restaura os arquivos do último backup criado")
	print("=".repeat(75) + "\n")

static func parse_arguments(args: Array) -> Dictionary:
	var cfg := {
		"health_mult": 1.0,
		"damage_mult": 1.0,
		"armor_mult": 1.0,
		"mr_mult": 1.0,
		"atkspd_mult": 1.0,
		"ability_damage_mult": 1.0,
		"ability_shield_mult": 1.0,
		"ability_heal_mult": 1.0,
		"tier_filter": -1,
		"dry_run": false,
		"no_backup": false,
		"has_multipliers": false,
	}
	
	for arg in args:
		var s := str(arg)
		if s == "--dry-run":
			cfg["dry_run"] = true
		elif s == "--no-backup":
			cfg["no_backup"] = true
		elif s.begins_with("--health-mult="):
			cfg["health_mult"] = float(s.split("=")[1])
			cfg["has_multipliers"] = true
		elif s.begins_with("--damage-mult="):
			cfg["damage_mult"] = float(s.split("=")[1])
			cfg["has_multipliers"] = true
		elif s.begins_with("--armor-mult="):
			cfg["armor_mult"] = float(s.split("=")[1])
			cfg["has_multipliers"] = true
		elif s.begins_with("--mr-mult="):
			cfg["mr_mult"] = float(s.split("=")[1])
			cfg["has_multipliers"] = true
		elif s.begins_with("--atkspd-mult="):
			cfg["atkspd_mult"] = float(s.split("=")[1])
			cfg["has_multipliers"] = true
		elif s.begins_with("--ability-damage-mult="):
			cfg["ability_damage_mult"] = float(s.split("=")[1])
			cfg["has_multipliers"] = true
		elif s.begins_with("--ability-shield-mult="):
			cfg["ability_shield_mult"] = float(s.split("=")[1])
			cfg["has_multipliers"] = true
		elif s.begins_with("--ability-heal-mult="):
			cfg["ability_heal_mult"] = float(s.split("=")[1])
			cfg["has_multipliers"] = true
		elif s.begins_with("--tier="):
			cfg["tier_filter"] = int(s.split("=")[1])
			
	return cfg

static func create_backup() -> String:
	var time_str := Time.get_datetime_string_from_system().replace(":", "-")
	var backup_dir := BACKUP_BASE_DIR + time_str + "/"
	DirAccess.make_dir_recursive_absolute(backup_dir)
	
	var dir := DirAccess.open(UNITS_DIR)
	if not dir:
		return ""
	
	dir.list_dir_begin()
	var file_name := dir.get_next()
	var count := 0
	while file_name != "":
		if file_name.ends_with(".tres"):
			var src := UNITS_DIR + file_name
			var dst := backup_dir + file_name
			DirAccess.copy_absolute(src, dst)
			count += 1
		file_name = dir.get_next()
	
	print("✓ Backup de %d arquivos criado em: %s" % [count, backup_dir])
	return backup_dir

static func restore_latest_backup() -> void:
	var base := DirAccess.open(BACKUP_BASE_DIR)
	if not base:
		print("Nenhum diretório de backup encontrado em %s." % BACKUP_BASE_DIR)
		return
	
	base.list_dir_begin()
	var subdirs: Array[String] = []
	var item := base.get_next()
	while item != "":
		if base.current_is_dir() and item not in [".", ".."]:
			subdirs.append(item)
		item = base.get_next()
	
	if subdirs.is_empty():
		print("Nenhum backup encontrado.")
		return
	subdirs.sort()
	var latest := subdirs[-1]
	var backup_path := BACKUP_BASE_DIR + latest + "/"
	print("Restaurando do backup mais recente: %s" % backup_path)
	
	var b_dir := DirAccess.open(backup_path)
	b_dir.list_dir_begin()
	var fn := b_dir.get_next()
	var restored := 0
	while fn != "":
		if fn.ends_with(".tres"):
			DirAccess.copy_absolute(backup_path + fn, UNITS_DIR + fn)
			restored += 1
		fn = b_dir.get_next()
	print("✓ %d unidades restauradas com sucesso a partir de %s!" % [restored, backup_path])

static func execute_batch(cfg: Dictionary) -> Array[Dictionary]:
	var dry_run: bool = cfg.get("dry_run", false)
	var tier_filter: int = cfg.get("tier_filter", -1)
	
	print("\n" + "=".repeat(75))
	print("EXECUTANDO ALTERAÇÃO EM LOTE %s" % ("[MODO SIMULAÇÃO / DRY-RUN]" if dry_run else "[MODO REAL]"))
	if tier_filter != -1:
		print("Filtro: Apenas Unidades do Tier %d" % tier_filter)
	else:
		print("Filtro: Todas as Unidades (Tier 1 a 5)")
	print("Multiplicadores Aplicados:")
	if cfg["health_mult"] != 1.0: print("  - Vida (max_health): x%.3f (%+.1f%%)" % [cfg["health_mult"], (cfg["health_mult"] - 1.0) * 100.0])
	if cfg["damage_mult"] != 1.0: print("  - Dano (attack_damage): x%.3f (%+.1f%%)" % [cfg["damage_mult"], (cfg["damage_mult"] - 1.0) * 100.0])
	if cfg["armor_mult"] != 1.0: print("  - Armadura (armor): x%.3f (%+.1f%%)" % [cfg["armor_mult"], (cfg["armor_mult"] - 1.0) * 100.0])
	if cfg["mr_mult"] != 1.0: print("  - Resist. Mágica (magic_resist): x%.3f (%+.1f%%)" % [cfg["mr_mult"], (cfg["mr_mult"] - 1.0) * 100.0])
	if cfg["atkspd_mult"] != 1.0: print("  - Vel. Ataque (attack_speed): x%.3f (%+.1f%%)" % [cfg["atkspd_mult"], (cfg["atkspd_mult"] - 1.0) * 100.0])
	if cfg["ability_damage_mult"] != 1.0: print("  - Dano Habilidade: x%.3f (%+.1f%%)" % [cfg["ability_damage_mult"], (cfg["ability_damage_mult"] - 1.0) * 100.0])
	if cfg["ability_shield_mult"] != 1.0: print("  - Escudo Habilidade: x%.3f (%+.1f%%)" % [cfg["ability_shield_mult"], (cfg["ability_shield_mult"] - 1.0) * 100.0])
	if cfg["ability_heal_mult"] != 1.0: print("  - Cura Habilidade: x%.3f (%+.1f%%)" % [cfg["ability_heal_mult"], (cfg["ability_heal_mult"] - 1.0) * 100.0])
	print("=".repeat(75))
	
	if not dry_run and not cfg.get("no_backup", false):
		create_backup()
	
	var dir := DirAccess.open(UNITS_DIR)
	if not dir:
		print("Erro ao abrir diretório de unidades: %s" % UNITS_DIR)
		return []
		
	dir.list_dir_begin()
	var file_name := dir.get_next()
	var results: Array[Dictionary] = []
	
	while file_name != "":
		if file_name.ends_with(".tres"):
			var file_path := UNITS_DIR + file_name
			var res: UnitStats = load(file_path)
			if res and (tier_filter == -1 or res.tier == tier_filter):
				var old_hp := res.max_health
				var old_dmg := res.attack_damage
				var old_arm := res.armor
				var old_mr := res.magic_resist
				var old_spd := res.attack_speed
				var old_ab_dmg := res.ability_damage
				var old_ab_shd := res.ability_shield
				var old_ab_hl := res.ability_heal
				
				# Aplica multiplicadores com arredondamento limpo
				if cfg["health_mult"] != 1.0:
					res.max_health = roundf(res.max_health * cfg["health_mult"])
				if cfg["damage_mult"] != 1.0:
					res.attack_damage = roundf(res.attack_damage * cfg["damage_mult"])
				if cfg["armor_mult"] != 1.0:
					res.armor = roundf(res.armor * cfg["armor_mult"])
				if cfg["mr_mult"] != 1.0:
					res.magic_resist = roundf(res.magic_resist * cfg["mr_mult"])
				if cfg["atkspd_mult"] != 1.0:
					res.attack_speed = snappedf(res.attack_speed * cfg["atkspd_mult"], 0.05)
				if cfg["ability_damage_mult"] != 1.0:
					res.ability_damage = roundf(res.ability_damage * cfg["ability_damage_mult"])
				if cfg["ability_shield_mult"] != 1.0:
					res.ability_shield = roundf(res.ability_shield * cfg["ability_shield_mult"])
				if cfg["ability_heal_mult"] != 1.0:
					res.ability_heal = roundf(res.ability_heal * cfg["ability_heal_mult"])
				
				if not dry_run:
					ResourceSaver.save(res, file_path)
				
				results.append({
					"id": res.unit_id,
					"name": res.unit_name,
					"tier": res.tier,
					"hp": [old_hp, res.max_health],
					"dmg": [old_dmg, res.attack_damage],
					"armor": [old_arm, res.armor],
					"mr": [old_mr, res.magic_resist],
					"spd": [old_spd, res.attack_speed],
				})
		file_name = dir.get_next()
	
	results.sort_custom(func(a, b): return a["tier"] < b["tier"] if a["tier"] != b["tier"] else a["id"] < b["id"])
	
	print("\nTABELA DE ALTERAÇÕES (%d unidades):" % results.size())
	print("%-4s | %-20s | %-16s | %-16s | %-16s" % ["Tier", "Unidade", "Vida (HP)", "Dano (ATK)", "Armadura (DEF)"])
	print("-".repeat(75))
	for r in results:
		var hp_str := "%.0f -> %.0f" % [r["hp"][0], r["hp"][1]] if r["hp"][0] != r["hp"][1] else "%.0f" % r["hp"][0]
		var dmg_str := "%.0f -> %.0f" % [r["dmg"][0], r["dmg"][1]] if r["dmg"][0] != r["dmg"][1] else "%.0f" % r["dmg"][0]
		var arm_str := "%.0f -> %.0f" % [r["armor"][0], r["armor"][1]] if r["armor"][0] != r["armor"][1] else "%.0f" % r["armor"][0]
		print("T%-3d | %-20s | %-16s | %-16s | %-16s" % [r["tier"], r["name"], hp_str, dmg_str, arm_str])
	
	print("-".repeat(75))
	if dry_run:
		print("ℹ Simulação concluída. Nenhuma alteração foi gravada em disco. Remova --dry-run para aplicar.\n")
	else:
		print("✓ %d unidades salvas com sucesso em %s!\n" % [results.size(), UNITS_DIR])
		
	return results
