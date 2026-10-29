extends Node

## Gerenciador global de economia do jogador (ouro, juros, sequências e compras)

signal gold_changed(new_gold: int, delta: int)
signal streak_changed(win_streak: int, loss_streak: int)
signal economy_resolved(earned_gold: int, breakdown: Dictionary)

@export var gold_on_win: int = 2
@export var gold_on_loss: int = 1
@export var gold_on_draw: int = 1
@export var starting_gold: int = 3
@export var reroll_cost: int = 2
@export var xp_cost: int = 4

var player_gold: int = 3
var win_streak: int = 0
var loss_streak: int = 0

func _ready() -> void:
	player_gold = starting_gold

func reset_game(initial_gold: int = 3) -> void:
	player_gold = initial_gold
	win_streak = 0
	loss_streak = 0
	gold_changed.emit(player_gold, 0)
	streak_changed.emit(win_streak, loss_streak)

func get_gold() -> int:
	return player_gold

func set_gold(val: int) -> void:
	var delta := val - player_gold
	player_gold = maxi(0, val)
	gold_changed.emit(player_gold, delta)

func add_gold(amount: int, _reason: String = "") -> void:
	if amount == 0:
		return
	player_gold += amount
	gold_changed.emit(player_gold, amount)

func can_afford(cost: int) -> bool:
	return player_gold >= cost

func spend_gold(amount: int) -> bool:
	if amount <= 0:
		return true
	if player_gold >= amount:
		player_gold -= amount
		gold_changed.emit(player_gold, -amount)
		return true
	return false

func calculate_interest(gold: int = -1) -> int:
	var amount := player_gold if gold < 0 else gold
	return clampi(int(amount / 10), 0, 5)

func calculate_streak_bonus(streak: int) -> int:
	if streak >= 5:
		return 3
	elif streak >= 3:
		return 2
	elif streak >= 1:
		return 1
	return 0

func resolve_round_economy(player_won: bool, is_draw: bool) -> Dictionary:
	var earned_gold: int = 0
	var round_gold: int = 0
	var streak_bonus: int = 0
	var interest: int = 0
	var outcome_name: String = ""

	if is_draw:
		win_streak = 0
		loss_streak = 0
		round_gold = gold_on_draw
		streak_bonus = 0
		interest = calculate_interest(player_gold)
		earned_gold = round_gold + streak_bonus + interest
		player_gold += earned_gold
		outcome_name = "Empate"
	elif player_won:
		win_streak += 1
		loss_streak = 0
		streak_bonus = calculate_streak_bonus(win_streak)
		round_gold = gold_on_win
		interest = calculate_interest(player_gold)
		earned_gold = round_gold + streak_bonus + interest
		player_gold += earned_gold
		outcome_name = "Vitória"
	else:
		loss_streak += 1
		win_streak = 0
		streak_bonus = calculate_streak_bonus(loss_streak)
		round_gold = gold_on_loss
		interest = calculate_interest(player_gold)
		earned_gold = round_gold + streak_bonus + interest
		player_gold += earned_gold
		outcome_name = "Derrota"

	streak_changed.emit(win_streak, loss_streak)
	gold_changed.emit(player_gold, earned_gold)

	var breakdown := {
		"earned_gold": earned_gold,
		"round_gold": round_gold,
		"streak_bonus": streak_bonus,
		"interest": interest,
		"outcome_name": outcome_name,
		"is_draw": is_draw,
		"player_won": player_won,
		"win_streak": win_streak,
		"loss_streak": loss_streak
	}

	economy_resolved.emit(earned_gold, breakdown)
	return breakdown
