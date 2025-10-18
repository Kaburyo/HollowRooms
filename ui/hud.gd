@tool
extends CanvasLayer

@export var heart_full: Texture2D
@export var heart_half: Texture2D
@export var heart_empty: Texture2D

@export var hearts_per_row: int = 6        # 6 par ligne (2 lignes max => 12)
@export var max_hearts: int = 3             # nb de "cases" visibles
@export var current_hearts: float = 3.0     # ex: 2.5 = 2 pleins + 1 demi
@export var padding: int = 8
@export var h_spacing: int = 1
@export var v_spacing: int = 1

var root_margin: MarginContainer
var hearts_grid: GridContainer
var _ready_done := false

func _ensure_structure() -> void:
    # Récupère ou crée RootMargin et HeartsGrid même si _ready() n'a pas encore tourné
    if root_margin == null or not is_instance_valid(root_margin):
        root_margin = get_node_or_null("RootMargin") as MarginContainer
        if root_margin == null:
            root_margin = MarginContainer.new()
            root_margin.name = "RootMargin"
            add_child(root_margin)

    if hearts_grid == null or not is_instance_valid(hearts_grid):
        hearts_grid = get_node_or_null("RootMargin/HeartsGrid") as GridContainer
        if hearts_grid == null:
            hearts_grid = GridContainer.new()
            hearts_grid.name = "HeartsGrid"
            root_margin.add_child(hearts_grid)

func _ready() -> void:
    _ensure_structure()

    # placement & style
    root_margin.add_theme_constant_override("margin_left", padding)
    root_margin.add_theme_constant_override("margin_top", padding)
    hearts_grid.columns = hearts_per_row
    hearts_grid.add_theme_constant_override("h_separation", h_spacing)
    hearts_grid.add_theme_constant_override("v_separation", v_spacing)

    # Connexion au bus d'événements si déjà autoloadé
    if typeof(GameEvents) != TYPE_NIL:
        GameEvents.player_max_hearts_changed.connect(set_max_hearts)
        GameEvents.player_hearts_changed.connect(set_current_hearts)

    _ready_done = true
    _rebuild()

func _rebuild() -> void:
    _ensure_structure()
    # nettoie et recrée les cases
    for c in hearts_grid.get_children():
        c.queue_free()

    for i in range(max_hearts):
        var r := TextureRect.new()
        r.stretch_mode = TextureRect.STRETCH_KEEP
        r.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
        r.texture_repeat = CanvasItem.TEXTURE_REPEAT_DISABLED
        hearts_grid.add_child(r)

    _refresh_icons()

func _refresh_icons() -> void:
    _ensure_structure()
    var hearts = clamp(current_hearts, 0.0, float(max_hearts))
    for i in range(max_hearts):
        var r: TextureRect = hearts_grid.get_child(i)
        var threshold_full := float(i) + 1.0
        var threshold_half := float(i) + 0.5
        if hearts >= threshold_full:
            r.texture = heart_full
        elif hearts >= threshold_half:
            r.texture = heart_half
        else:
            r.texture = heart_empty

func set_max_hearts(new_max: int) -> void:
    max_hearts = clampi(new_max, 1, hearts_per_row * 2)  # 12 max (6x2)
    current_hearts = clamp(current_hearts, 0.0, float(max_hearts))
    if _ready_done:
        _rebuild()
    else:
        # si on est appelé avant _ready(), on décale la reconstruction
        call_deferred("_rebuild")

func set_current_hearts(value: float) -> void:
    current_hearts = clamp(value, 0.0, float(max_hearts))
    if _ready_done:
        _refresh_icons()
    else:
        call_deferred("_refresh_icons")
