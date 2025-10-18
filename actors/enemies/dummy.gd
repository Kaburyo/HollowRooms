extends Node2D

@export var max_hp := 2.0
@export var respawn_time := 2.0
var hp := 2.0

@onready var visual_root: Node2D = $"VisualRoot"
@onready var body: CanvasItem = $"VisualRoot/Body"   # Sprite2D ou Polygon2D
@onready var flash: CanvasItem = $"VisualRoot/Flash" # optionnel (overlay)

# valeurs de base pour éviter tout "drift" après plusieurs hits
var _base_pos: Vector2
var _base_scale: Vector2
var _base_rot_deg: float
var _base_tint: Color

# tweens en cours (on les "kill" avant de rejouer l'anim)
var _tw_rot: Tween
var _tw_scale: Tween
var _tw_pos: Tween
var _tw_flash: Tween

func _ready():
    hp = max_hp
    if not is_instance_valid(visual_root) or not is_instance_valid(body):
        push_error("Dummy: VisualRoot/Body manquants.")
        return

    _base_pos = visual_root.position
    _base_scale = visual_root.scale
    _base_rot_deg = visual_root.rotation_degrees
    _base_tint = body.modulate

    # VisualRoot doit rester opaque (au cas où tu l'aurais mis à 0 avant)
    visual_root.modulate = Color(1,1,1,1)

    # Flash overlay : additif + invisible
    if is_instance_valid(flash):
        if flash.material == null or not (flash.material is CanvasItemMaterial):
            var mat := CanvasItemMaterial.new()
            mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
            flash.material = mat
        else:
            (flash.material as CanvasItemMaterial).blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
        flash.modulate = Color(1,1,1,0.0)
        flash.z_index = 100

func take_damage(amount: float) -> void:
    _hit_feedback()
    hp -= amount
    if hp <= 0.0:
        _respawn_later()
        queue_free()

func _kill_tweens() -> void:
    for t in [_tw_rot, _tw_scale, _tw_pos, _tw_flash]:
        if is_instance_valid(t):
            t.kill()
    # reposer les bases pour être sûr (évite tout cumul)
    if is_instance_valid(visual_root):
        visual_root.position = _base_pos
        visual_root.scale = _base_scale
        visual_root.rotation_degrees = _base_rot_deg
    if is_instance_valid(body):
        body.modulate = _base_tint
    if is_instance_valid(flash):
        flash.modulate = Color(1,1,1,0.0)

func _hit_feedback() -> void:
    if not is_instance_valid(visual_root) or not is_instance_valid(body):
        return

    _kill_tweens()  # empêche les superpositions et le "grossissement" permanent

    # --- FLASH ---
        # --- FLASH (overlay additif) ---
    if is_instance_valid(flash):
        flash.visible = true
        flash.modulate = Color(1, 1, 1, 0.0)   # alpha 0 au départ
        _tw_flash = create_tween()
        _tw_flash.tween_property(flash, "modulate:a", 1.0, 0.05)  # monte très vite
        _tw_flash.tween_property(flash, "modulate:a", 0.0, 0.12)  # s’estompe
    else:
        # fallback si pas de nœud Flash : petit blink sur Body
        body.modulate = Color(1, 1, 1, 0.5)
        _tw_flash = create_tween()
        _tw_flash.tween_property(body, "modulate", _base_tint, 0.12)


    # --- WOBBLE (rotation + squash&stretch + petit nudge) ---
    _tw_rot = create_tween()
    _tw_rot.tween_property(visual_root, "rotation_degrees", _base_rot_deg + 8.0, 0.06).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
    _tw_rot.tween_property(visual_root, "rotation_degrees", _base_rot_deg - 6.0, 0.08).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
    _tw_rot.tween_property(visual_root, "rotation_degrees", _base_rot_deg, 0.10).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

    _tw_scale = create_tween()
    _tw_scale.tween_property(visual_root, "scale", _base_scale * Vector2(1.08, 0.92), 0.06)
    _tw_scale.tween_property(visual_root, "scale", _base_scale * Vector2(0.96, 1.04), 0.08)
    _tw_scale.tween_property(visual_root, "scale", _base_scale, 0.10)

    _tw_pos = create_tween()
    _tw_pos.tween_property(visual_root, "position", _base_pos + Vector2(0, -4), 0.06)
    _tw_pos.tween_property(visual_root, "position", _base_pos, 0.18)

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
