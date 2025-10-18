extends Control

var heart_full: Texture2D
var heart_half: Texture2D
var heart_empty: Texture2D

var hearts_per_row: int = 6
var max_hearts: int = 3
var current_hearts: float = 3.0
var padding: int = 8
var h_spacing: int = 1
var v_spacing: int = 1

var cell: Vector2i = Vector2i(16, 16)

func _ready() -> void:
    set_anchors_preset(PRESET_TOP_LEFT)
    mouse_filter = MOUSE_FILTER_IGNORE
    visible = true

func update_params(full: Texture2D, half: Texture2D, empty: Texture2D,
        per_row: int, maxh: int, curh: float, pad: int, hs: int, vs: int) -> void:
    heart_full = full
    heart_half = half
    heart_empty = empty
    hearts_per_row = max(1, per_row)
    max_hearts = max(1, maxh)
    current_hearts = clamp(curh, 0.0, float(max_hearts))
    cell = (heart_full.get_size() if heart_full != null else Vector2i(16, 16))

    var cols: int = min(max_hearts, hearts_per_row)
    var rows: int = int(ceil(float(max_hearts) / float(hearts_per_row)))

    var w: int = cols * cell.x + max(0, cols - 1) * hs + pad * 2
    var h: int = rows * cell.y + max(0, rows - 1) * vs + pad * 2
    custom_minimum_size = Vector2(w, h)
    size = custom_minimum_size
    position = Vector2(pad, pad)  # en haut-gauche, avec padding
    queue_redraw()

func _draw() -> void:
    if heart_full == null or heart_half == null or heart_empty == null:
        return

    var hearts = clamp(current_hearts, 0.0, float(max_hearts))
    for i in range(max_hearts):
        var col: int = i % hearts_per_row
        var row: int = i / hearts_per_row
        var pos := Vector2(
            col * (cell.x + h_spacing),
            row * (cell.y + v_spacing)
        )

        var tf := float(i) + 1.0
        var th := float(i) + 0.5
        var tex: Texture2D = heart_empty
        if hearts >= tf:
            tex = heart_full
        elif hearts >= th:
            tex = heart_half

        draw_texture(tex, pos)
