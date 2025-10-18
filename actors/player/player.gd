extends CharacterBody2D

@export var move_speed := 250.0
@export var fire_cooldown := 0.60
@export var damage: float = 1.0
var _fire_timer := 0.0
const SHOOT_DEADZONE := 0.20  # évite les tirs fantômes du stick

@export var coins: int = 0
@export var max_hp := 3.0
var hp := 3.0
@export var invuln_time := 0.7
var invuln_timer := 0.0
@export var post_invuln_grace := 0.3   # délai après l’invulnérabilité
var grace_timer := 0.0                 # compte à rebours de cette grâce
var _enemy_damage_overlaps := 0
var _base_modulate: Color

@export var contact_pushback := 180.0   # force du petit recul au contact
@export var knockback_decay := 2800.0    # vitesse à laquelle le recul s’estompe
var knockback := Vector2.ZERO           # vecteur de recul courant
var _last_contact_dir := Vector2.ZERO   # dernière direction d'ennemi → joueur

@export var contact_tick_time := 0.7     # délai avant (re)prendre des dégâts sur l'ennemi
@export var contact_tick_damage := 0.25  # dégâts infligés à l'ennemi par “contact prolongé”
var _contact_overlaps := {}              # enemy_node -> temps cumulé de contact


@onready var sprite_root: Node2D = $SpriteRoot
@onready var muzzle: Node2D = $SpriteRoot/Muzzle
@onready var hurtbox: Area2D = $Hurtbox


func _ready():
    #donne un groupe pour les collision
    add_to_group("player")
    hp = max_hp
    _base_modulate = sprite_root.modulate
    if is_instance_valid(hurtbox):
        hurtbox.area_entered.connect(_on_hurtbox_area_entered)
        hurtbox.area_exited.connect(_on_hurtbox_area_exited)  # si tu as déjà ajouté cette ligne, garde-la
    
func _physics_process(delta):
    var move_dir := Input.get_vector("move_left","move_right","move_up","move_down")
    velocity = move_dir * move_speed + knockback
    move_and_slide()

    knockback = knockback.move_toward(Vector2.ZERO, knockback_decay * delta)

    # 3) Tir auto (flèches / stick droit mappés sur shoot_*)
    var aim := _get_aim_vector()
    _fire_timer -= delta
    if aim.length() > 0.0 and _fire_timer <= 0.0:
        _fire_timer = fire_cooldown
        _shoot(aim.normalized())

    # 4) Gestion invulnérabilité + "grâce"
    var was_invuln := invuln_timer > 0.0

    if invuln_timer > 0.0:
        invuln_timer -= delta
        if invuln_timer <= 0.0 and is_instance_valid(sprite_root):
            sprite_root.modulate.a = 1.0

    if was_invuln and invuln_timer <= 0.0:
        grace_timer = post_invuln_grace

    if grace_timer > 0.0:
        grace_timer -= delta

    # 5) Si encore en contact et plus protégé, on reprend un coup
    if invuln_timer <= 0.0 and grace_timer <= 0.0 and _enemy_damage_overlaps > 0:
        take_damage(1.0)

    # 6) Dégâts de contact répétés sur l’ennemi tant qu’on reste en chevauchement
    if _contact_overlaps.size() > 0:
        var to_remove: Array = []
        for enemy in _contact_overlaps.keys():
            if not is_instance_valid(enemy):
                to_remove.append(enemy)
                continue
            var t := float(_contact_overlaps[enemy])
            t += delta
            if t >= contact_tick_time:
                if enemy.has_method("take_damage"):
                    enemy.take_damage(contact_tick_damage)
                t -= contact_tick_time
            _contact_overlaps[enemy] = t
        for e in to_remove:
            _contact_overlaps.erase(e)


func _get_aim_vector() -> Vector2:
    var x := Input.get_action_strength("shoot_right") - Input.get_action_strength("shoot_left")
    var y := Input.get_action_strength("shoot_down") - Input.get_action_strength("shoot_up")
    var v := Vector2(x, y)
    if v.length() >= SHOOT_DEADZONE:
        return v
    return Vector2.ZERO

func _shoot(dir: Vector2) -> void:
    var b = preload("res://actors/projectiles/Bullet.tscn").instantiate()
    var spawn_base = muzzle.global_position if is_instance_valid(muzzle) else global_position
    b.global_position = spawn_base + dir * 20.0
    b.direction = dir
    get_tree().current_scene.add_child(b)

       
func _on_hurtbox_area_entered(area: Area2D) -> void:
    # 🔒 Ne réagit QUE aux vraies hitbox ennemies (propre, robuste)
    if not area.is_in_group("enemy_hitbox"):
        return
        
    _enemy_damage_overlaps += 1
        
    # direction du contact (ennemi → joueur) et petit recul
    _last_contact_dir = (global_position - area.global_position).normalized()
    knockback += _last_contact_dir * contact_pushback

    # référence vers l'ennemi
    var enemy: Node = area.get_parent()
    while enemy and not enemy.is_in_group("enemy"):
        enemy = enemy.get_parent()
    
    if enemy:
        # démarrer le chronomètre de “contact prolongé” pour cet ennemi
        _contact_overlaps[enemy] = 0.0
        # dégâts de contact immédiats (demande initiale)
        if enemy.has_method("take_damage"):
            enemy.take_damage(0.25)
        
    # dégâts au joueur (si pas invulnérable ni en grâce)
    if invuln_timer <= 0.0 and grace_timer <= 0.0:
        take_damage(0.5)
   

func _on_hurtbox_area_exited(area: Area2D) -> void:
    _enemy_damage_overlaps = max(0, _enemy_damage_overlaps - 1)
    var enemy: Node = area.get_parent()
    if enemy and _contact_overlaps.has(enemy):
        _contact_overlaps.erase(enemy)


func take_damage(amount: float) -> void:
    hp -= amount

    # mini push-back à chaque coup reçu
    if _last_contact_dir != Vector2.ZERO:
        knockback += _last_contact_dir * (contact_pushback * 0.6)

    invuln_timer = invuln_time
    _blink_invuln()

    # provisoire : on se “soigne” au lieu de mourir, pour tester
    if hp <= 0.0:
        hp = max_hp


func _blink_invuln() -> void:
    if not is_instance_valid(sprite_root):
        return
    var flash := Color(1.0, 0.6, 0.6, 0.45)  # rouge clair + semi-transparent
    sprite_root.modulate = _base_modulate

    var cycle := 0.16  # durée d’un on/off
    var loops := int(ceil(invuln_time / cycle))

    var t := create_tween()
    t.set_loops(loops)
    t.tween_property(sprite_root, "modulate", flash, cycle * 0.35).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
    t.tween_property(sprite_root, "modulate", _base_modulate, cycle * 0.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)

func add_coins(n: int) -> void:
    coins += n
    # TODO: jouer un son / MAJ UI
