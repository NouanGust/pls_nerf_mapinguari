class_name OriginRuntime
extends RefCounted

const BattleClock = preload("res://Scripts/Systems/battle_clock.gd")

## Gerencia o estado e as regras em tempo de combate das 9 novas origens.
## Cada unidade possui sua própria instância de OriginRuntime.

var unit: BaseUnit3D

# --- Seiva ---
var seiva_timer: float = 0.0
var seiva_stacks: int = 0
const MAX_SEIVA_STACKS: int = 3

# --- Vigília ---
var vigilia_triggered: bool = false
var vigilia_shield_end_msec: int = 0

# --- Correnteza ---
var correnteza_timer: float = 0.0
var correnteza_shield_end_msec: int = 0

# --- Vozes ---
var vozes_emitter_cd_msec: int = 0
var vozes_recipient_cd_msec: int = 0
static var _vozes_identity_cds: Dictionary = {}

# --- Ferocidade ---
var feroc_stacks: int = 0
var feroc_hit_counter: int = 0
const MAX_FEROC_STACKS: int = 8

# --- Travessia ---
var travessia_last_target_id: int = 0
var travessia_cd_end_msec: int = 0
var travessia_speed_end_msec: int = 0
var travessia_strike_ready: bool = false
var travessia_strike_target_id: int = 0
var travessia_strike_end_msec: int = 0

# --- Assombro ---
var assombro_targets_cd: Dictionary = {} # target_instance_id -> expire_msec
var assombro_debuff_pct: float = 0.0
var assombro_debuff_end_msec: int = 0

# --- Encanto ---
var encanto_charged: bool = false
var encanto_active_on_cast: bool = false

# --- Fulgor ---
var fulgor_used: bool = false
var fulgor_active_on_cast: bool = false

func _init(owner_unit: BaseUnit3D) -> void:
	unit = owner_unit

func reset_for_combat() -> void:
	seiva_timer = 0.0
	seiva_stacks = 0
	vigilia_triggered = false
	vigilia_shield_end_msec = 0
	correnteza_timer = 0.0
	correnteza_shield_end_msec = 0
	vozes_emitter_cd_msec = 0
	vozes_recipient_cd_msec = 0
	feroc_stacks = 0
	feroc_hit_counter = 0
	travessia_last_target_id = 0
	travessia_cd_end_msec = 0
	travessia_speed_end_msec = 0
	travessia_strike_ready = false
	travessia_strike_target_id = 0
	travessia_strike_end_msec = 0
	assombro_targets_cd.clear()
	assombro_debuff_pct = 0.0
	assombro_debuff_end_msec = 0
	encanto_charged = false
	encanto_active_on_cast = false
	fulgor_used = false
	fulgor_active_on_cast = false

	# Aplica bônus de abertura de combate do Fulgor
	var fulgor_mana := float(unit.synergy_bonuses.get("fulgor_mana", 0.0))
	if fulgor_mana > 0.0:
		unit.current_mana = minf(unit.stats.max_mana, unit.current_mana + fulgor_mana)
		unit.update_mana_bar()

func on_tick(delta: float) -> void:
	if not unit.in_combat or unit.current_state == BaseUnit3D.State.DEAD or unit.is_on_bench():
		return

	var now := BattleClock.now_msec()

	# Tick da Seiva (a cada 4s)
	var seiva_heal_pct := float(unit.synergy_bonuses.get("seiva_heal_pct", 0.0))
	if seiva_heal_pct > 0.0:
		seiva_timer += delta
		if seiva_timer >= 4.0:
			seiva_timer = 0.0
			var heal_amount := unit.get_max_health() * seiva_heal_pct
			unit.heal(heal_amount)
			if seiva_stacks < MAX_SEIVA_STACKS:
				seiva_stacks += 1
				CombatFeedback.create_status_indicator(unit, "CRESCIMENTO (%d)" % seiva_stacks, 1.5)

	# Tick da Correnteza (a cada 5s)
	var correnteza_mana := float(unit.synergy_bonuses.get("correnteza_mana", 0.0))
	var correnteza_sh_pct := float(unit.synergy_bonuses.get("correnteza_shield_pct", 0.0))
	if correnteza_mana > 0.0 or correnteza_sh_pct > 0.0:
		correnteza_timer += delta
		if correnteza_timer >= 5.0:
			correnteza_timer = 0.0
			if correnteza_mana > 0.0:
				unit.add_mana(correnteza_mana)
			if correnteza_sh_pct > 0.0:
				var sh := unit.get_max_health() * correnteza_sh_pct
				# Substitui pelo maior valor e renova por 2s
				if sh > unit.current_shield or now >= correnteza_shield_end_msec:
					unit.set_shield_with_source(sh, BaseUnit3D.ShieldSource.CLASS)
				correnteza_shield_end_msec = now + 2000

func on_target_acquired(new_target: BaseUnit3D) -> void:
	if not is_instance_valid(new_target):
		return
	var tid := new_target.get_instance_id()
	if tid == travessia_last_target_id:
		return
	travessia_last_target_id = tid

	var speed_pct := float(unit.synergy_bonuses.get("travessia_speed_pct", 0.0))
	if speed_pct > 0.0:
		var now := BattleClock.now_msec()
		if now >= travessia_cd_end_msec:
			travessia_cd_end_msec = now + 4000
			travessia_speed_end_msec = now + 2000
			travessia_strike_ready = true
			travessia_strike_target_id = tid
			travessia_strike_end_msec = now + 4000
			CombatFeedback.create_status_indicator(unit, "TRAVESSIA", 2.0)

func on_basic_attack_hit(target: BaseUnit3D) -> void:
	var now := BattleClock.now_msec()

	# Ferocidade: acúmulos de Ímpeto e cura no 3º ataque
	var feroc_per_stack := float(unit.synergy_bonuses.get("feroc_per_stack", 0.0))
	if feroc_per_stack > 0.0:
		if feroc_stacks < MAX_FEROC_STACKS:
			feroc_stacks += 1
		feroc_hit_counter += 1
		if feroc_hit_counter >= 3:
			feroc_hit_counter = 0
			var heal_pct := float(unit.synergy_bonuses.get("feroc_heal_pct", 0.0))
			if heal_pct > 0.0:
				unit.heal(unit.get_max_health() * heal_pct)
				CombatFeedback.create_status_indicator(unit, "ÍMPETO VITAL", 1.0)

	# Travessia: consome golpe de aproximação
	if travessia_strike_ready and is_instance_valid(target) and target.get_instance_id() == travessia_strike_target_id:
		if now <= travessia_strike_end_msec:
			travessia_strike_ready = false

	# Assombro: aplica marca de redução de defesa
	apply_assombro_to_target(target)

func apply_assombro_to_target(target: BaseUnit3D) -> void:
	if not is_instance_valid(target) or target.current_state == BaseUnit3D.State.DEAD:
		return
	var assombro_pct := float(unit.synergy_bonuses.get("assombro_pct", 0.0))
	if assombro_pct <= 0.0:
		return
	var now := BattleClock.now_msec()
	var tid := target.get_instance_id()
	if assombro_targets_cd.get(tid, 0) > now:
		return
	assombro_targets_cd[tid] = now + 6000
	if target.origin_runtime:
		target.origin_runtime.receive_assombro_mark(assombro_pct, 4.0)

func receive_assombro_mark(pct: float, duration_sec: float) -> void:
	var now := BattleClock.now_msec()
	# Não se somam: vale a maior redução ativa, com teto de 30%
	var new_pct := clampf(maxf(assombro_debuff_pct, pct), 0.0, 0.30)
	assombro_debuff_pct = new_pct
	assombro_debuff_end_msec = now + int(duration_sec * 1000.0)
	CombatFeedback.create_status_indicator(unit, "ASSOMBRO", duration_sec)

func get_defense_reduction_multiplier() -> float:
	var now := BattleClock.now_msec()
	if now < assombro_debuff_end_msec:
		return clampf(1.0 - assombro_debuff_pct, 0.70, 1.0)
	return 1.0

func check_vigilia_trigger(incoming_damage: float) -> void:
	if vigilia_triggered:
		return
	var vigilia_sh_pct := float(unit.synergy_bonuses.get("vigilia_shield_pct", 0.0))
	if vigilia_sh_pct <= 0.0:
		return
	var max_hp := unit.get_max_health()
	if unit.current_health - incoming_damage < max_hp * 0.50 or unit.current_health < max_hp * 0.50:
		vigilia_triggered = true
		var shield_amount := max_hp * vigilia_sh_pct
		unit.set_shield_with_source(shield_amount, BaseUnit3D.ShieldSource.CLASS)
		vigilia_shield_end_msec = BattleClock.now_msec() + 4000
		CombatFeedback.create_status_indicator(unit, "VIGÍLIA", 2.0)

func has_active_vigilia_shield() -> bool:
	return vigilia_triggered and unit.has_active_shield() and BattleClock.now_msec() < vigilia_shield_end_msec

func get_control_resist_bonus() -> float:
	if has_active_vigilia_shield():
		return float(unit.synergy_bonuses.get("vigilia_control_resist", 0.0))
	return 0.0

func on_ability_start() -> float:
	# Retorna multiplicador de potência da habilidade (dano, cura, escudos)
	var multiplier := 1.0
	
	# Seiva Crescimento
	var seiva_growth_pct := float(unit.synergy_bonuses.get("seiva_growth_pct", 0.0))
	if seiva_growth_pct > 0.0 and seiva_stacks > 0:
		multiplier += seiva_stacks * seiva_growth_pct

	# Fulgor
	var fulgor_pct := float(unit.synergy_bonuses.get("fulgor_pct", 0.0))
	if fulgor_pct > 0.0 and not fulgor_used:
		fulgor_used = true
		fulgor_active_on_cast = true
		multiplier += fulgor_pct
		CombatFeedback.create_status_indicator(unit, "FULGOR", 1.5)

	# Encanto
	var encanto_pct := float(unit.synergy_bonuses.get("encanto_pct", 0.0))
	if encanto_pct > 0.0 and encanto_charged:
		encanto_charged = false
		encanto_active_on_cast = true
		multiplier += encanto_pct
		CombatFeedback.create_status_indicator(unit, "ENCANTO", 1.5)

	return multiplier

func on_ability_concluded() -> void:
	fulgor_active_on_cast = false
	encanto_active_on_cast = false

	# Encanto: prepara próxima habilidade
	var encanto_pct := float(unit.synergy_bonuses.get("encanto_pct", 0.0))
	if encanto_pct > 0.0:
		encanto_charged = true

	# Vozes: emite Eco
	var vozes_echo_mana := float(unit.synergy_bonuses.get("vozes_echo_mana", 0.0))
	if vozes_echo_mana > 0.0:
		emit_vozes_eco(vozes_echo_mana)

func emit_vozes_eco(mana_amount: float) -> void:
	var now := BattleClock.now_msec()
	# Intervalo do emissor: 4s (compartilhado por cópias da mesma identidade)
	var identity_key: String = "%s_%d" % [unit.stats.unit_id, unit.team]
	if _vozes_identity_cds.get(identity_key, 0) > now or vozes_emitter_cd_msec > now:
		return
	vozes_emitter_cd_msec = now + 4000
	_vozes_identity_cds[identity_key] = now + 4000

	var board := unit._get_combat_board()
	if not board:
		return
	var my_cell := board.get_grid_position(board.to_local(unit.global_position))
	if not board.get_cell(my_cell):
		return

	var ally_group := "player_units" if unit.team == 0 else "enemy_units"
	var candidates: Array = []
	for node in unit.get_tree().get_nodes_in_group(ally_group):
		var ally: BaseUnit3D = node as BaseUnit3D
		if not is_instance_valid(ally) or ally == unit or ally.current_state == BaseUnit3D.State.DEAD or ally.is_on_bench():
			continue
		if not ally.stats or not ally.stats.origins.has("Vozes"):
			continue
		if ally.has_active_shield():
			continue
		if ally.origin_runtime and ally.origin_runtime.vozes_recipient_cd_msec > now:
			continue
		var cell := board.get_grid_position(board.to_local(ally.global_position))
		if not board.get_cell(cell):
			continue
		var dist := board.get_hex_distance(my_cell, cell)
		if dist <= 2:
			candidates.append({"unit": ally, "dist": dist})

	# Ordena por proximidade e entrega a até 2 aliados
	candidates.sort_custom(func(a, b): return a["dist"] < b["dist"])
	var sent := 0
	for item in candidates:
		if sent >= 2:
			break
		var recipient: BaseUnit3D = item["unit"]
		recipient.origin_runtime.vozes_recipient_cd_msec = now + 2000
		recipient.add_mana(mana_amount)
		CombatFeedback.create_status_indicator(recipient, "+ECO MANA", 1.2)
		sent += 1

func get_attack_bonus_multiplier() -> float:
	# Ferocidade bônus no ataque base
	var feroc_per_stack := float(unit.synergy_bonuses.get("feroc_per_stack", 0.0))
	if feroc_per_stack > 0.0 and feroc_stacks > 0:
		return 1.0 + (feroc_stacks * feroc_per_stack)
	return 1.0

func get_speed_multiplier() -> float:
	# Travessia bônus de movimento
	var now := BattleClock.now_msec()
	if now < travessia_speed_end_msec:
		var speed_pct := float(unit.synergy_bonuses.get("travessia_speed_pct", 0.0))
		return 1.0 + speed_pct
	return 1.0

func get_approach_damage_multiplier(target: BaseUnit3D) -> float:
	# Travessia bônus de dano de aproximação
	var now := BattleClock.now_msec()
	if travessia_strike_ready and is_instance_valid(target) and target.get_instance_id() == travessia_strike_target_id:
		if now <= travessia_strike_end_msec:
			var strike_pct := float(unit.synergy_bonuses.get("travessia_strike_pct", 0.0))
			return 1.0 + strike_pct
	return 1.0
