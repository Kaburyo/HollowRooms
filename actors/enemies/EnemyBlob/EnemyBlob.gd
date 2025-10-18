extends CharacterBody2D

@export var max_hp := 5.0
@export var respawn_time := 3.0
var hp := 5.0
@export var bullet_damage: float = 1.0

@onready var hurtbox: Area2D = $Hurtbox
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D  # si pas déjà

var _debug_respawn := false
var _debug_respawn_time := -1.0
var _debug_respawn_hp_mult := 1.0
var _debug_respawn_scale_mult := 1.0
var _dead := false
var _spawn_pos: Vector2

@export var speed: float = 350.0
@export var accel: float = 1200.0
@export var bounce_keep: float = 0.90
@export var min_speed: float = 60.0
@export var max_speed: float = 350.0
@export var aggro_range: float = 15000.0
@export var seek_player: bool = true
var _player: Node2D



func _ready() -> void:
    add_to_group("enemy")
    hp = max_hp
    _spawn_pos = global_position

    # poursuite: retrouve le player (si ce n’est pas déjà fait ailleurs)
    var players := get_tree().get_nodes_in_group("player")
    if players.size() > 0:
        _player = players[0] as Node2D

    # connexions de la Hurtbox
    if is_instance_valid(hurtbox):
        hurtbox.body_entered.connect(_on_hurtbox_body_entered)
        hurtbox.area_entered.connect(_on_hurtbox_area_entered)

    # anim de départ (si tu veux)
    if sprite and sprite.sprite_frames:
        if sprite.sprite_frames.has_animation("idle"):
            sprite.animation = "idle"; sprite.play()
        elif sprite.sprite_frames.has_animation("hop"):
            sprite.animation = "hop"; sprite.play()
            
            
    var angle := randf() * TAU
    velocity = Vector2.RIGHT.rotated(angle) * speed
    # (anim "hop"/"idle" comme tu avais)

func _on_hurtbox_body_entered(body: Node) -> void:
    _try_take_bullet_damage(body)

func _on_hurtbox_area_entered(area: Area2D) -> void:
    _try_take_bullet_damage(area)

func _try_take_bullet_damage(other: Node) -> void:
    if _dead: 
        return
    if other == null:
        return

    var is_bullet: bool = false

    # 1) la balle est dans le groupe "player_bullet" ?
    if other.is_in_group("player_bullet"):
        is_bullet = true
    # 2) sinon, elle expose peut-être une méthode "is_player_bullet()"
    elif other.has_method("is_player_bullet") and other.call("is_player_bullet"):
        is_bullet = true
    # 3) ou tout simplement son nom contient "bullet"
    elif other.name.to_lower().find("bullet") != -1:
        is_bullet = true

    if is_bullet:
        take_damage(bullet_damage)
        # Laisse la balle se gérer si elle a "hit()", sinon on la détruit
        if other.has_method("hit"):
            other.call("hit")
        elif other is Node:
            other.queue_free()

func die() -> void:
    if _dead:
        return
    _dead = true
    call_deferred("_die_impl")  # évite de toucher aux Areas pendant un signal


func _die_impl() -> void:
    # Désactive proprement
    if is_instance_valid(hurtbox):
        hurtbox.set_deferred("monitoring", false)
        hurtbox.set_deferred("monitorable", false)
    if has_node("CollisionShape2D"):
        $CollisionShape2D.set_deferred("disabled", true)
    if is_instance_valid(sprite):
        sprite.visible = false

    # Si le respawn debug n'est PAS activé → mort définitive
    if !_debug_respawn:
        call_deferred("queue_free")
        return

    # Attente avant respawn (override si fourni)
    var wait := _debug_respawn_time if _debug_respawn_time > 0.0 else respawn_time
    await get_tree().create_timer(wait).timeout
    if !is_inside_tree():
        return

    # Respawn (HP/échelle optionnellement modifiés)
    hp = max_hp * _debug_respawn_hp_mult
    global_position = _spawn_pos

    if is_instance_valid(sprite):
        sprite.visible = true
        # Applique une réduction/augmentation cumulative si ≠ 1.0
        if abs(_debug_respawn_scale_mult - 1.0) > 0.001:
            sprite.scale *= _debug_respawn_scale_mult

    if has_node("CollisionShape2D"):
        $CollisionShape2D.set_deferred("disabled", false)
    if is_instance_valid(hurtbox):
        hurtbox.set_deferred("monitoring", true)
        hurtbox.set_deferred("monitorable", true)

    _dead = false
        
func _physics_process(delta: float) -> void:
    # poursuite
    var desired := velocity
    if seek_player and is_instance_valid(_player):
        var to_player := _player.global_position - global_position
        if to_player.length() <= aggro_range:
            desired = to_player.normalized() * speed
    velocity = velocity.move_toward(desired, accel * delta)

    var pre_vel := velocity
    move_and_slide()

    # rebond sur murs (uniquement)
    var wall_n := Vector2.ZERO
    for i in range(get_slide_collision_count()):
        var col: KinematicCollision2D = get_slide_collision(i)
        wall_n += col.get_normal()
    if wall_n != Vector2.ZERO:
        var n_avg := wall_n.normalized()
        velocity = pre_vel.bounce(n_avg) * bounce_keep

    # clamps
    var spd := velocity.length()
    if spd > max_speed:
        velocity = velocity.normalized() * max_speed
    elif spd < min_speed:
        if spd < 0.001:
            var ang := randf() * TAU
            velocity = Vector2.RIGHT.rotated(ang) * min_speed
        else:
            velocity = velocity.normalized() * min_speed

func take_damage(amount: float) -> void:
    if _dead:
        return
    hp -= amount
    _flash_on_hit()
    if hp <= 0.0:
        die()

func _flash_on_hit() -> void:
    if not is_instance_valid(sprite):
        return
    var t := create_tween()
    t.tween_property(sprite, "modulate", Color(1.0, 0.5, 0.5), 0.06)
    t.tween_property(sprite, "modulate", Color(1, 1, 1), 0.10)


func set_debug_respawn(enabled: bool, time_override: float, hp_mult: float, scale_mult: float) -> void:
    _debug_respawn = enabled
    _debug_respawn_time = time_override
    _debug_respawn_hp_mult = hp_mult
    _debug_respawn_scale_mult = scale_mult
