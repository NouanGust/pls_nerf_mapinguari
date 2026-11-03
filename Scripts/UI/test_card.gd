extends Control

@onready var card: UnitCard = $UnitCard

func _ready() -> void:
	# Carregar uma unidade para testar
	var unit: UnitStats = load("res://resources/units/anhanga.tres")
	
	if unit:
		card.set_unit(unit)
		print("Card configurado com %s" % unit.unit_name)
	else:
		print("Falha ao carregar unidade")
