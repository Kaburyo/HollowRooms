extends Area2D

@export var value: int = 1
@export var bob_height: float = 3.0
@export var bob_time: float = 0.6
@export var respawn_time := 0.5

@onready var sprite: Node2D = $Sprite

func _ready() -> void:
    add_to_group("money")
    if not body_entered.is_connected(_on_body_entered):
        body_entered.connect(_on_body_entered)
    _start_bob()

func _start_bob() -> void:
    if not is_instance_valid(sprite): return
    sprite.position.y = 0.0
    var t := create_tween()
    t.set_loops()
    t.tween_property(sprite, "position:y", -bob_height, bob_time).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
    t.tween_property(sprite, "position:y", 0.0, bob_time).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

func _on_body_entered(body: Node) -> void:
    if body and body.is_in_group("player"):
        if body.has_method("add_coins"):
            body.add_coins(value)
        elif "coins" in body:
            body.coins += value
        _respawn_later()
        queue_free()
        
func _respawn_later() -> void:
    var where = global_position
    var parent = get_parent()
    var scene_path = get_scene_file_path()
    var packed = load(scene_path) as PackedScene
    get_tree().create_timer(respawn_time).timeout.connect(func():
        if is_instance_valid(parent) and packed:
            var d = packed.instantiate()
            d.global_position = where
            parent.add_child(d)
    )
