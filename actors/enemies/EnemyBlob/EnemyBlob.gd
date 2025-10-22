extends CharacterBody2D

@export var max_hp := 5.0
var hp := 5.0
@export var bullet_damage: float = 1.0

@onready var hurtbox: Area2D = $Hurtbox
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

var _dead := false

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

    # poursuite: retrouve le player
    var players := get_tree().get_nodes_in_group("player")
    if players.size() > 0:
        _player = players[0] as Node2D

    # connexions de la Hurtbox
    if is_instance_valid(hurtbox):
        hurtbox.body_entered.connect(_on_hurtbox_body_entered)
        hurtbox.area_entered.connect(_on_hurtbox_area_entered)

    # animation de départ
    if sprite and sprite.sprite_frames:
        if sprite.sprite_frames.has_animation("idle"):
            sprite.animation = "idle"
            sprite.play()
        elif sprite.sprite_frames.has_animation("hop"):
            sprite.animation = "hop"
            sprite.play()
    
    # direction aléatoire au départ
    var angle := randf() * TAU
    velocity = Vector2.RIGHT.rotated(angle) * speed


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

    # Détection de balle
    if other.is_in_group("player_bullet"):
        is_bullet = true
    elif other.has_method("is_player_bullet") and other.call("is_player_bullet"):
        is_bullet = true
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
    queue_free()  # Mort définitive


func _physics_process(delta: float) -> void:
    if _dead:
        return
    
    # poursuite du joueur
    var desired := velocity
    if seek_player and is_instance_valid(_player):
        var to_player := _player.global_position - global_position
        if to_player.length_squared() <= aggro_range * aggro_range:
            desired = to_player.normalized() * speed
    velocity = velocity.move_toward(desired, accel * delta)

    var pre_vel := velocity
    move_and_slide()

    # rebond sur murs
    var wall_n := Vector2.ZERO
    for i in range(get_slide_collision_count()):
        var col: KinematicCollision2D = get_slide_collision(i)
        wall_n += col.get_normal()
    if wall_n != Vector2.ZERO:
        var n_avg := wall_n.normalized()
        velocity = pre_vel.bounce(n_avg) * bounce_keep

    # clamps de vitesse
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
