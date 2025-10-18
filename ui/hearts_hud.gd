extends CanvasLayer

# --- Backing fields (valeurs internes) ---
var _heart_full: Texture2D
var _heart_half: Texture2D
var _heart_empty: Texture2D
var _hearts_per_row: int = 6
var _max_hearts: int = 3
var _current_hearts: float = 3.0
var _padding: int = 8
var _h_spacing: int = 1
var _v_spacing: int = 1

# --- Exports avec setters: push auto quand on change dans l’Inspector ---
@export var heart_full: Texture2D = null:
    set(value):
        _heart_full = value
        _push_params_if_ready()
    get:
        return _heart_full

@export var heart_half: Texture2D = null:
    set(value):
        _heart_half = value
        _push_params_if_ready()
    get:
        return _heart_half

@export var heart_empty: Texture2D = null:
    set(value):
        _heart_empty = value
        _push_params_if_ready()
    get:
        return _heart_empty

@export var hearts_per_row: int = 6:
    set(value):
        _hearts_per_row = max(1, value)
        _push_params_if_ready()
    get:
        return _hearts_per_row

@export var max_hearts: int = 3:
    set(value):
        _max_hearts = clampi(value, 1, _hearts_per_row * 2)
        _current_hearts = clamp(_current_hearts, 0.0, float(_max_hearts))
        _push_params_if_ready()
    get:
        return _max_hearts

@export var current_hearts: float = 3.0:
    set(value):
        _current_hearts = clamp(value, 0.0, float(_max_hearts))
        _push_params_if_ready()
    get:
        return _current_hearts

@export var padding: int = 8:
    set(value):
        _padding = max(0, value)
        _push_params_if_ready()
    get:
        return _padding

@export var h_spacing: int = 1:
    set(value):
        _h_spacing = max(0, value)
        _push_params_if_ready()
    get:
        return _h_spacing

@export var v_spacing: int = 1:
    set(value):
        _v_spacing = max(0, value)
        _push_params_if_ready()
    get:
        return _v_spacing

var draw_area: Control

func _push_params_if_ready() -> void:
    if not is_inside_tree():
        return
    _ensure_draw_area()     # <-- crée/attache DrawArea aussi en éditeur
    _push_params()


func _enter_tree() -> void:
    visible = true
    if layer < 200:
        layer = 200
    _ensure_draw_area()     # <-- important pour voir en éditeur


func _ready() -> void:
    _ensure_draw_area()

    # charge les textures si non assignées
    if _heart_full == null:  _heart_full  = load("res://ui/hearts/heart_full.tres")
    if _heart_half == null:  _heart_half  = load("res://ui/hearts/heart_half.tres")
    if _heart_empty == null: _heart_empty = load("res://ui/hearts/heart_empty.tres")


    # branche les events si présents (optionnel)
    if typeof(GameEvents) != TYPE_NIL:
        if not GameEvents.player_max_hearts_changed.is_connected(set_max_hearts):
            GameEvents.player_max_hearts_changed.connect(set_max_hearts)
        if not GameEvents.player_hearts_changed.is_connected(set_current_hearts):
            GameEvents.player_hearts_changed.connect(set_current_hearts)

    # pousse l'état initial après une frame
    call_deferred("_push_params")

func _ensure_draw_area() -> void:
    draw_area = get_node_or_null("DrawArea") as Control
    if draw_area == null:
        draw_area = Control.new()
        draw_area.name = "DrawArea"
        add_child(draw_area)

    # attache le script de dessin si pas encore
    if draw_area.get_script() == null:
        var s := load("res://ui/hearts_draw_area.gd")
        draw_area.set_script(s)

    draw_area.visible = true
    draw_area.set_anchors_preset(Control.PRESET_TOP_LEFT)
    draw_area.position = Vector2.ZERO
    draw_area.mouse_filter = Control.MOUSE_FILTER_IGNORE
    # safety: au cas où un parent Control aurait une modulate bizarre
    if draw_area is CanvasItem:
        (draw_area as CanvasItem).modulate = Color.WHITE

func _push_params() -> void:
    if draw_area == null: return
    if draw_area.has_method("update_params"):
        draw_area.call(
            "update_params",
            _heart_full, _heart_half, _heart_empty,
            _hearts_per_row, _max_hearts, _current_hearts,
            _padding, _h_spacing, _v_spacing
        )


func set_max_hearts(new_max: int) -> void:
    max_hearts = clampi(new_max, 1, hearts_per_row * 2)
    current_hearts = clamp(current_hearts, 0.0, float(max_hearts))
    _push_params()

func set_current_hearts(value: float) -> void:
    current_hearts = clamp(value, 0.0, float(max_hearts))
    _push_params()
