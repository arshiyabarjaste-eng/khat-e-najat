## AudioManager.gd
## -----------------------------------------------------------------------------
## Singleton (Autoload). Centralizes SFX and music playback. Reads the user's
## settings from SaveManager and applies them. Streams are loaded lazily and
## pooled for SFX to avoid per-frame allocation.
## -----------------------------------------------------------------------------
extends Node
# AudioManager — registered as autoload singleton in project.godot.
# Do NOT add `class_name` here; it conflicts with the autoload name in Godot 4.x.

# Sound effect identifiers (lookup keys). Keep these short and stable.
enum SFX {
        BUTTON,
        START_SIM,
        DRAW_LINE,
        IMPACT,
        WIN,
        LOSE,
        COIN,
        LEVEL_UNLOCK,
}

# Audio bus names. We use "Master" by default; if the project has dedicated
# "SFX" and "Music" buses, they will be created automatically when the user
# adds them. Until then, fall back to Master.
const BUS_MASTER := "Master"
const BUS_SFX := "SFX"
const BUS_MUSIC := "Music"

# Cached stream players.
var _sfx_pool: Dictionary = {}   # SFX -> Array[AudioStreamPlayer]
var _music_player: AudioStreamPlayer = null
var _current_music: AudioStream = null
var _pool_size: int = 4

# In case audio files are missing (early dev), gracefully no-op.
var _missing_logged: Dictionary = {}


func _ready() -> void:
        # Apply initial volumes from save.
        _apply_settings()
        # Hook into save changes.
        if SaveManager:
                if not SaveManager.data_loaded.is_connected(_on_data_loaded):
                        SaveManager.data_loaded.connect(_on_data_loaded)


func _on_data_loaded(_data: Dictionary) -> void:
        _apply_settings()


# --- Public API --------------------------------------------------------------

func play_sfx(sfx_id: int) -> void:
        if not SaveManager.is_sound_enabled():
                return
        var stream := _get_sfx_stream(sfx_id)
        if stream == null:
                _log_missing_once(sfx_id)
                return
        var player := _get_or_create_sfx_player(sfx_id)
        if player == null:
                return
        player.stream = stream
        player.volume_db = linear_to_db(SaveManager.get_sound_volume())
        player.pitch_scale = _pitch_for(sfx_id)
        player.play()


func play_music(stream: AudioStream = null, loop: bool = true) -> void:
        if not SaveManager.is_music_enabled():
                stop_music()
                return
        if stream == null:
                stream = _get_default_music()
        if stream == null:
                _log_missing_once("music_default")
                return
        if _music_player == null:
                _music_player = AudioStreamPlayer.new()
                _music_player.bus = BUS_MUSIC
                add_child(_music_player)
                # Try to enable looping for OGG/MP3 streams.
        if _current_music == stream and _music_player.playing:
                return  # Already playing the right track.
        _music_player.stream = stream
        _music_player.volume_db = linear_to_db(SaveManager.get_music_volume())
        # Configure looping for known stream types.
        if stream is AudioStreamOggVorbis:
                (stream as AudioStreamOggVorbis).loop = loop
        elif stream is AudioStreamMP3:
                (stream as AudioStreamMP3).loop = loop
        _music_player.play()
        _current_music = stream


func stop_music() -> void:
        if _music_player != null:
                _music_player.stop()


func stop_all_sfx() -> void:
        for sfx_id in _sfx_pool:
                for player in _sfx_pool[sfx_id]:
                        (player as AudioStreamPlayer).stop()


# --- Internal helpers --------------------------------------------------------

func _apply_settings(_data: Variant = null) -> void:
        # Re-apply bus volumes. If dedicated buses don't exist, use Master.
        # The `_data` argument is unused but kept for backward-compat with
        # callers that pass SaveManager._data.
        _set_bus_volume(BUS_SFX, SaveManager.get_sound_volume() if SaveManager.is_sound_enabled() else 0.0)
        _set_bus_volume(BUS_MUSIC, SaveManager.get_music_volume() if SaveManager.is_music_enabled() else 0.0)


func _set_bus_volume(bus_name: String, linear: float) -> void:
        var idx := AudioServer.get_bus_index(bus_name)
        if idx == -1:
                idx = AudioServer.get_bus_index(BUS_MASTER)
        if idx == -1:
                return
        AudioServer.set_bus_volume_db(idx, linear_to_db(clampf(linear, 0.0, 1.0)))
        AudioServer.set_bus_mute(idx, linear <= 0.001)


func _get_or_create_sfx_player(sfx_id: int) -> AudioStreamPlayer:
        if not _sfx_pool.has(sfx_id):
                _sfx_pool[sfx_id] = []
        var arr: Array = _sfx_pool[sfx_id]
        # Find an idle player.
        for p in arr:
                if not (p as AudioStreamPlayer).playing:
                        return p
        # All busy — expand pool (cap to _pool_size).
        if arr.size() < _pool_size:
                var np := AudioStreamPlayer.new()
                np.bus = BUS_SFX
                add_child(np)
                arr.append(np)
                return np
        # Fallback: reuse the oldest (will interrupt that SFX).
        return arr[0]


func _get_sfx_stream(sfx_id: int) -> AudioStream:
        # NOTE: Audio files are expected under res://assets/audio/sfx/.
        # Naming convention: <id>.ogg
        # If the file is missing, we return null and the caller logs once.
        var path := "res://assets/audio/sfx/%s.ogg" % _sfx_name(sfx_id)
        if not ResourceLoader.exists(path):
                return null
        return load(path) as AudioStream


func _get_default_music() -> AudioStream:
        var path := "res://assets/audio/music/ambient.ogg"
        if not ResourceLoader.exists(path):
                return null
        return load(path) as AudioStream


func _sfx_name(sfx_id: int) -> String:
        match sfx_id:
                SFX.BUTTON: return "button"
                SFX.START_SIM: return "start_sim"
                SFX.DRAW_LINE: return "draw_line"
                SFX.IMPACT: return "impact"
                SFX.WIN: return "win"
                SFX.LOSE: return "lose"
                SFX.COIN: return "coin"
                SFX.LEVEL_UNLOCK: return "level_unlock"
                _: return "unknown"


func _pitch_for(sfx_id: int) -> float:
        # Slight randomization to avoid monotony.
        match sfx_id:
                SFX.IMPACT: return randf_range(0.85, 1.15)
                SFX.COIN: return randf_range(0.95, 1.05)
                _: return 1.0


func _log_missing_once(key) -> void:
        if _missing_logged.has(key):
                return
        _missing_logged[key] = true
        var label: String = key if (key is String) else _sfx_name(key)
        push_warning("[AudioManager] Missing audio asset: %s — game will run silent for this event." % label)
