extends CharacterBody2D


@export var speed: float = 500.0
@export var accel: float = 2400.0
@export var friction: float = 3600.0
@export var move_deadzone: float = 4.0  # pixels/s

@export var fire_cooldown := 0.60
@export var damage: float = 1.0
var _fire_timer := 0.0
const SHOOT_DEADZONE := 0.20

@onready var health: PlayerHealth = $Health

@export var coins: int = 0

@export var invuln_time := 0.7
var invuln_timer := 0.0

@export var post_invuln_grace := 0.3   # délai après l'invulnérabilité
var grace_timer := 0.0                 # compte à rebours de cette grâce
var _enemy_damage_overlaps := 0
var contact_lockout := 0.0  # secondes avant de pouvoir reprendre un "tick" de contact


@export var contact_pushback := 350.0   # force du petit recul au contact
@export var knockback_decay := 1800.0    # vitesse à laquelle le recul s'estompe
var knockback := Vector2.ZERO           # vecteur de recul courant
var _last_contact_dir := Vector2.ZERO   # dernière direction d'ennemi → joueur

@export var contact_tick_time := 0.5     # délai avant (re)prendre des dégâts sur l'ennemi
@export var contact_tick_damage := 0.25  # dégâts infligés à l'ennemi par "contact prolongé"
var _contact_overlaps := {}              # enemy_node -> temps cumulé de contact

@onready var body: AnimatedSprite2D = $Visuals/Body

@onready var sprite_root: Node2D = $SpriteRoot
@onready var muzzle: Node2D = $SpriteRoot/Muzzle
@onready var hurtbox: Area2D = $Hurtbox

var facing: int = 1  # 1 = regarde à droite, -1 = regarde à gauche
var _base_mod_body: Color

func _ready():
    add_to_group("player")

    _base_mod_body = body.modulate

    if is_instance_valid(hurtbox):
        hurtbox.area_entered.connect(_on_hurtbox_area_entered)
        hurtbox.area_exited.connect(_on_hurtbox_area_exited)


func _physics_process(delta: float) -> void:
    # --- DÉCROISSANCE DU KNOCKBACK (en premier) ---
    knockback = knockback.move_toward(Vector2.ZERO, knockback_decay * delta)

    # --- INPUT DÉPLACEMENT ---
    var input_dir := Input.get_vector("move_left", "move_right", "move_up", "move_down")

    # --- TIR AUTO (stick droit / flèches de visée) ---
    var aim := _get_aim_vector()
    _fire_timer -= delta
    if aim.length() > 0.0 and _fire_timer <= 0.0:
        _fire_timer = fire_cooldown
        _shoot(aim.normalized())

    # --- INVULN / GRÂCE ---
    var was_invuln := invuln_timer > 0.0

    # décrémente le verrou de contact
    if contact_lockout > 0.0:
        contact_lockout -= delta

    if invuln_timer > 0.0:
        invuln_timer -= delta
        if invuln_timer <= 0.0:
            # fin d'invuln : remettre les couleurs d'origine
            if is_instance_valid(body): 
                body.modulate = _base_mod_body

    if was_invuln and invuln_timer <= 0.0:
        grace_timer = post_invuln_grace

    if grace_timer > 0.0:
        grace_timer -= delta

    # Si on reste en contact après invuln+grâce, reprendre un coup
    if invuln_timer <= 0.0 and grace_timer <= 0.0 and _enemy_damage_overlaps > 0:
        take_damage(0.5)

    # --- DÉGÂTS DE CONTACT PROLONGÉS SUR L'ENNEMI ---
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

    # --- MOUVEMENT (moins de glisse) ---
    if input_dir != Vector2.ZERO:
        input_dir = input_dir.normalized()
        var target := input_dir * speed
        velocity = velocity.move_toward(target, accel * delta)
    else:
        velocity = velocity.move_toward(Vector2.ZERO, friction * delta)
        # snap-to-zero pour éviter le flottement résiduel
        if velocity.length() < 8.0:
            velocity = Vector2.ZERO

    # --- APPLIQUER KNOCKBACK + BOUGER (une seule fois) ---
    var base_vel := velocity
    velocity = base_vel + knockback
    move_and_slide()
    velocity = base_vel

    # --- ANIMS & ORIENTATION ---
    var moving := velocity.length_squared() > move_deadzone * move_deadzone
    set_move_state(moving)
    update_facing(input_dir)  # mémorise la dernière direction horizontale

func heal(amount: float) -> float:
    if not is_instance_valid(health): 
        return 0.0
    return float(health.call("heal", amount))
    
func set_move_state(moving: bool) -> void:
    if moving:
        body.play("walk")
    else:
        body.play("idle")

func update_facing(dir: Vector2) -> void:
    # Met à jour la mémoire de direction uniquement si on a un input horizontal clair
    if dir.x < -0.1:
        facing = -1
    elif dir.x > 0.1:
        facing = 1

    var flip := (facing == -1)
    body.flip_h = flip
    
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
        # démarrer le chronomètre de "contact prolongé" pour cet ennemi
        _contact_overlaps[enemy] = 0.0
        # dégâts de contact immédiats (demande initiale)
        if enemy.has_method("take_damage"):
            enemy.take_damage(0.25)
    
    var dmg_to_player := 0.5
    if enemy and (enemy.is_in_group("elite") or enemy.is_in_group("boss")):
        dmg_to_player = 1.0

    # ⚠️ ne pas infliger si verrou actif
    if invuln_timer <= 0.0 and grace_timer <= 0.0 and contact_lockout <= 0.0:
        take_damage(dmg_to_player)
   

func _on_hurtbox_area_exited(area: Area2D) -> void:
    _enemy_damage_overlaps = max(0, _enemy_damage_overlaps - 1)
    var enemy: Node = area.get_parent()
    if enemy and _contact_overlaps.has(enemy):
        _contact_overlaps.erase(enemy)


func take_damage(amount: float) -> void:
    if amount <= 0.0:
        return

    # passe par PlayerHealth (déjà en place)
    if is_instance_valid(health):
        health.call("take_damage", amount)

    # verrou de contact = invuln + grâce (empêche la double-perte instantanée)
    contact_lockout = invuln_time + post_invuln_grace

    # mini push-back, blink, etc. (inchangé)
    if _last_contact_dir != Vector2.ZERO:
        knockback += _last_contact_dir * (contact_pushback * 0.6)

    invuln_timer = invuln_time
    _blink_invuln()

    if is_instance_valid(health) and float(health.hearts) <= 0.0:
        health.hearts = float(health.max_hearts)
        if typeof(GameEvents) != TYPE_NIL:
            GameEvents.player_hearts_changed.emit(health.hearts)


func _blink_invuln() -> void:
    if not is_instance_valid(body):
        return

    # Rouge visible mais pas 100% opaque (garde un peu du sprite d'origine)
    var flash := Color(1.0, 0.25, 0.25, 1.0)
    var cycle := 0.16                         # durée d'un on/off
    var loops := int(ceil(invuln_time / cycle))

    # reset propre avant de démarrer
    body.modulate = _base_mod_body

    var t := create_tween()
    t.set_loops(loops)

    # phase "on" pour body
    t.tween_property(body, "modulate", flash, cycle * 0.45)\
        .set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

    # phase "off" (retour aux couleurs d'origine)
    t.tween_property(body, "modulate", _base_mod_body, cycle * 0.55)\
        .set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)

func add_coins(n: int) -> void:
    coins += n
    # TODO: jouer un son / MAJ UI
