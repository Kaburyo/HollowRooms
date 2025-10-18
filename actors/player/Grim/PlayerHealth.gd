extends Node
class_name PlayerHealth   # <— permet d'appeler en typé depuis Grim

signal health_changed(value: float)
signal max_hearts_changed(value: int)

@export var max_hearts: int = 3
@export var hearts: float = 3.0
@export var invuln_duration: float = 0.4

var _invuln := false

# ✨ Appelée par Grim une fois au démarrage pour synchroniser le HUD
func initialize(max_in: int, hearts_in: float) -> void:
    await get_tree().process_frame  # s'assure que le HUD est prêt
    max_hearts = clampi(max_in, 1, 12)
    hearts = clamp(hearts_in, 0.0, float(max_hearts))
    if typeof(GameEvents) != TYPE_NIL:
        GameEvents.player_max_hearts_changed.emit(max_hearts)
        GameEvents.player_hearts_changed.emit(hearts)
        
        
func set_max_hearts(new_max: int, preserve_fraction: bool = true) -> void:
    var frac := 0.0
    if preserve_fraction and max_hearts > 0:
        frac = hearts / float(max_hearts)
    max_hearts = clampi(new_max, 1, 12)   # 6x2
    if preserve_fraction:
        hearts = clamp(frac * float(max_hearts), 0.0, float(max_hearts))
    else:
        hearts = clamp(hearts, 0.0, float(max_hearts))
    if typeof(GameEvents) != TYPE_NIL:
        GameEvents.player_max_hearts_changed.emit(max_hearts)
        GameEvents.player_hearts_changed.emit(hearts)
        

func take_damage(amount: float) -> bool:
    if _invuln or amount <= 0.0:
        return false
    hearts = clamp(hearts - amount, 0.0, float(max_hearts))
    if typeof(GameEvents) != TYPE_NIL:
        GameEvents.player_hearts_changed.emit(hearts)
    _start_invuln()
    return true

func heal(amount: float) -> float:
    if amount <= 0.0:
        return 0.0
    var before := hearts
    hearts = clamp(hearts + amount, 0.0, float(max_hearts))
    if typeof(GameEvents) != TYPE_NIL:
        GameEvents.player_hearts_changed.emit(hearts)
    return hearts - before

func _start_invuln() -> void:
    _invuln = true
    await get_tree().create_timer(invuln_duration).timeout
    _invuln = false

# Ajoute N conteneurs de cœur (capacité) ; si fill_new = true, on remplit aussi les nouveaux
func add_heart_container(n: int = 1, fill_new: bool = true) -> void:
    var before_max := max_hearts
    max_hearts = clampi(max_hearts + n, 1, 12)  # 12 = 6x2
    var gained := max_hearts - before_max
    if gained <= 0:
        return

    if fill_new:
        hearts = clamp(hearts + float(gained), 0.0, float(max_hearts))
    else:
        hearts = clamp(hearts, 0.0, float(max_hearts))

    if typeof(GameEvents) != TYPE_NIL:
        GameEvents.player_max_hearts_changed.emit(max_hearts)
        GameEvents.player_hearts_changed.emit(hearts)
