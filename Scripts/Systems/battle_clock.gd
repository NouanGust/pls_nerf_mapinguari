extends Node

## Relógio de simulação: não avança enquanto SceneTree.paused estiver ativo.
static var _instance: Node
var elapsed_seconds: float = 0.0

func _enter_tree() -> void:
	_instance = self

func _exit_tree() -> void:
	if _instance == self:
		_instance = null

func _ready() -> void:
	_instance = self
	process_mode = Node.PROCESS_MODE_PAUSABLE

func _physics_process(delta: float) -> void:
	elapsed_seconds += delta

static func now_msec() -> int:
	if _instance:
		return int(_instance.elapsed_seconds * 1000.0)
	return Time.get_ticks_msec()
