extends Node

## Relógio de simulação: não avança enquanto SceneTree.paused estiver ativo.
var elapsed_seconds: float = 0.0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_PAUSABLE

func _physics_process(delta: float) -> void:
	elapsed_seconds += delta

func now_msec() -> int:
	return int(elapsed_seconds * 1000.0)
