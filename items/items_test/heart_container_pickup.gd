extends Area2D

@export var containers_to_give: int = 1
@export var fill_new_containers: bool = true

var _consumed: bool = false

func _ready() -> void:
    monitoring = true      # IMPORTANT : écouter les bodies
    monitorable = true     # laisser les autres te détecter si besoin
    if has_node("."):
        body_entered.connect(_on_body_entered)
        area_entered.connect(_on_area_entered)

func _on_body_entered(body: Node) -> void:
    _try_consume_from(body)

func _on_area_entered(area: Area2D) -> void:
    _try_consume_from(area)

func _try_consume_from(node: Node) -> void:
    if _consumed or node == null:
        return

    # Remonte aux parents jusqu'au Player (groupe "player")
    var owner := node
    while owner and not owner.is_in_group("player"):
        owner = owner.get_parent()
    if owner == null:
        return

    var health := owner.get_node_or_null("Health")
    if health == null:
        return

    # ---- Consommer (désactiver + cacher + supprimer) ----
    _consumed = true
    monitoring = false
    monitorable = false
    visible = false
    set_deferred("collision_layer", 0)
    set_deferred("collision_mask", 0)

    if health.has_method("add_heart_container"):
        health.add_heart_container(containers_to_give, fill_new_containers)
    else:
        # fallback si tu n'as pas encore ajouté add_heart_container
        if health.has_variable("max_hearts"):
            health.max_hearts = clampi(int(health.max_hearts) + containers_to_give, 1, 12)
        if fill_new_containers and health.has_variable("hearts"):
            health.hearts = clamp(float(health.hearts) + float(containers_to_give), 0.0, float(health.max_hearts))
        if typeof(GameEvents) != TYPE_NIL:
            GameEvents.player_max_hearts_changed.emit(health.max_hearts)
            GameEvents.player_hearts_changed.emit(health.hearts)

    call_deferred("queue_free")
