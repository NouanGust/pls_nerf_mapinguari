extends RefCounted

## Curva exclusiva do jogador. O inimigo usa os marcos de region_rosters.gd.
## XP excedente é descartado no teto.
const MAX_LEVEL: int = 9
const ROUND_XP: int = 2
const PURCHASE_XP: int = 4

static func required_xp(level: int) -> int:
	return 0 if level >= MAX_LEVEL else maxi(level, 1) * 2

static func gain_xp(level: int, xp: int, amount: int) -> Vector2i:
	level = clampi(level, 1, MAX_LEVEL)
	xp = maxi(xp, 0) + maxi(amount, 0)
	while level < MAX_LEVEL and xp >= required_xp(level):
		xp -= required_xp(level)
		level += 1
	return Vector2i(level, 0 if level == MAX_LEVEL else xp)
