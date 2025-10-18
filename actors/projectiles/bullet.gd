extends Area2D

@export var bullet_gravity: float = 120.0      # pixels/s²
@export var speed: float = 1000.0
@export var life_time: float = 1.5
@export var damage: float = 0.5
@export var spin_period: float = 0.3           # secondes pour 360°

# --- Knockback sans modifier les ennemis ---
@export var knockback_px: float = 35.0         # distance poussée (px)
@export var knockback_time: float = 0.1       # durée du push (s)
@export var rb_impulse: float = 180.0          # impulsion pour RigidBody2D

var direction: Vector2 = Vector2.RIGHT
var velocity: Vector2 = Vector2.ZERO
var _t: float = 0.0

const FULL_TURN := PI * 2.0

@export var outline_width: float = 20.0
@export var outline_color: Color = Color(0, 0, 0) # noir

@onready var poly: Polygon2D = $Polygon2D
var _outline: Line2D

func _ready() -> void:
    body_entered.connect(_on_body_entered)
    area_entered.connect(_on_area_entered)
    velocity = direction.normalized() * speed
    rotation = direction.angle()   # oriente la balle au tir
    _make_outline_line2d()   # <-- crée le contour
    
func _physics_process(delta: float) -> void:
    # Gravité + déplacement
    velocity.y += bullet_gravity * delta
    position += velocity * delta

    # Rotation 360° en spin_period
    var ang_speed = FULL_TURN / max(0.001, spin_period)
    rotation += ang_speed * delta

    # Durée de vie
    _t += delta
    if _t >= life_time:
        queue_free()

func _on_body_entered(_body: Node) -> void:
    queue_free()

func _on_area_entered(area: Area2D) -> void:
    # Remonte jusqu'au node "enemy"
    var target: Node = area.get_parent()
    while target and not target.is_in_group("enemy"):
        target = target.get_parent()

    if target:
        # 1) Dégâts
        if target.has_method("take_damage"):
            target.take_damage(damage)

        # 2) Knockback sans toucher au code ennemi
        _apply_knockback(target)

    queue_free()

func _apply_knockback(target: Node) -> void:
    # Direction: de la balle vers la cible (poussée à l'opposé du point d'impact)
    var dir = (target.global_position - global_position).normalized()
    if dir == Vector2.ZERO:
        dir = direction.normalized()

    if target is RigidBody2D:
        # Impulsion physique native si l'ennemi est un RigidBody2D
        (target as RigidBody2D).apply_impulse(dir * rb_impulse)
        return

    # Pour CharacterBody2D / Node2D : petit tween de position (pas besoin de code ennemi)
    var start = target.global_position
    var end = start + dir * knockback_px
    var t := target.create_tween()
    t.tween_property(target, "global_position", end, knockback_time)\
        .set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
        
        
func _make_outline_line2d() -> void:
    if not is_instance_valid(poly) or poly.polygon.is_empty():
        return
    # évite les doublons si tu recrées la balle souvent
    var existing := get_node_or_null("Outline")
    if existing:
        existing.queue_free()

    _outline = Line2D.new()
    _outline.name = "Outline"
    _outline.closed = true
    _outline.width = outline_width
    _outline.default_color = outline_color
    _outline.z_index = poly.z_index - 1   # derrière le remplissage (met +1 si tu préfères au-dessus)
    add_child(_outline)

    # aligne la position locale si ton Polygon2D n’est pas à (0,0)
    _outline.position = poly.position

    # points du contour = sommets du Polygon2D
    _outline.points = poly.polygon
