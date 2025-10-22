extends Node

@onready var music: AudioStreamPlayer = $Music
@onready var fade: ColorRect = $ScreenFX/Fade

const FADE_TIME := 2.0  # durée du fondu d'entrée

func _ready():
    # --- Fade-in écran ---
    if fade:
        fade.color = Color(0, 0, 0, 1.0)  # noir opaque
        var t := create_tween()
        t.tween_property(fade, "color:a", 0.0, FADE_TIME).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
    
    # --- Musique ---
    if music:
        # démarre doucement (fade audio)
        if music.stream and not music.playing:
            music.volume_db = -24.0
            music.play()
            var ta := create_tween()
            ta.tween_property(music, "volume_db", -6.0, FADE_TIME).set_trans(Tween.TRANS_SINE)
        
        # sécurité: si jamais elle finit, on relance
        if not music.finished.is_connected(_on_music_finished):
            music.finished.connect(_on_music_finished)

func _on_music_finished():
    if music:
        music.play()

# --- Input: M pour mute/unmute la musique ---
func _input(event):
    if event.is_action_pressed("toggle_mute"):
        if music:
            music.stream_paused = not music.stream_paused

# -------------------------
# BONUS : Fondu pour transitions
# -------------------------
# Fondu noir sortant puis appelle 'callback' (ex: changement de scène)
func fade_out(callback: Callable, dur: float = 0.6) -> void:
    if not fade:
        callback.call()
        return
    # part de l'état actuel (transparent) vers noir
    fade.color = Color(0, 0, 0, fade.color.a)  # garde alpha courant
    var t := create_tween()
    t.tween_property(fade, "color:a", 1.2, dur).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
    t.finished.connect(func(): callback.call())

# Pratique : changement de scène avec fondu
func go_to_scene_with_fade(path: String, dur: float = 0.6) -> void:
    fade_out(func():
        get_tree().change_scene_to_file(path)
    , dur)
