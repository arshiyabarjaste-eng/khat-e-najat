## settings.gd
## -----------------------------------------------------------------------------
## Settings page. Controls sound toggle, music toggle, volumes, language
## (if a second language were supported — currently only fa), and a
## "reset progress" button (with confirmation).
## -----------------------------------------------------------------------------
extends Control
class_name SettingsPage

@onready var sound_toggle: CheckButton = %SoundToggle
@onready var music_toggle: CheckButton = %MusicToggle
@onready var sound_slider: HSlider = %SoundSlider
@onready var music_slider: HSlider = %MusicSlider
@onready var language_option: OptionButton = %LanguageOption
@onready var reset_button: Button = %ResetButton
@onready var back_button: Button = %BackButton
@onready var confirm_panel: ColorRect = %ConfirmPanel
@onready var confirm_yes: Button = %ConfirmYes
@onready var confirm_no: Button = %ConfirmNo


func _ready() -> void:
        # Hook buttons.
        if sound_toggle and not sound_toggle.toggled.is_connected(_on_sound_toggled):
                sound_toggle.toggled.connect(_on_sound_toggled)
        if music_toggle and not music_toggle.toggled.is_connected(_on_music_toggled):
                music_toggle.toggled.connect(_on_music_toggled)
        if sound_slider and not sound_slider.value_changed.is_connected(_on_sound_volume):
                sound_slider.value_changed.connect(_on_sound_volume)
        if music_slider and not music_slider.value_changed.is_connected(_on_music_volume):
                music_slider.value_changed.connect(_on_music_volume)
        if language_option and not language_option.item_selected.is_connected(_on_language_changed):
                language_option.item_selected.connect(_on_language_changed)
        if reset_button and not reset_button.pressed.is_connected(_on_reset):
                reset_button.pressed.connect(_on_reset)
        if back_button and not back_button.pressed.is_connected(_on_back):
                back_button.pressed.connect(_on_back)
        if confirm_yes and not confirm_yes.pressed.is_connected(_on_reset_confirmed):
                confirm_yes.pressed.connect(_on_reset_confirmed)
        if confirm_no and not confirm_no.pressed.is_connected(_on_reset_cancelled):
                confirm_no.pressed.connect(_on_reset_cancelled)

        # Load current settings.
        sound_toggle.button_pressed = SaveManager.is_sound_enabled()
        music_toggle.button_pressed = SaveManager.is_music_enabled()
        sound_slider.value = SaveManager.get_sound_volume()
        music_slider.value = SaveManager.get_music_volume()

        # Language option (fa default; en placeholder for future).
        language_option.clear()
        language_option.add_item("فارسی", 0)
        language_option.add_item("English (آینده)", 1)
        var lang := String(SaveManager.get_setting("language", "fa"))
        language_option.selected = 0 if lang == "fa" else 1

        confirm_panel.visible = false


# --- Handlers ---------------------------------------------------------------

func _on_sound_toggled(enabled: bool) -> void:
        SaveManager.set_setting("sound_enabled", enabled)
        SaveManager.save_async()
        if AudioManager and enabled:
                AudioManager.play_sfx(AudioManager.SFX.BUTTON)


func _on_music_toggled(enabled: bool) -> void:
        SaveManager.set_setting("music_enabled", enabled)
        SaveManager.save_async()
        if AudioManager:
                if enabled:
                        AudioManager.play_music()
                else:
                        AudioManager.stop_music()


func _on_sound_volume(value: float) -> void:
        SaveManager.set_setting("sound_volume", value)
        if AudioManager:
                # Trigger audio settings re-apply.
                AudioManager._apply_settings()
        if SaveManager.is_sound_enabled():
                AudioManager.play_sfx(AudioManager.SFX.BUTTON)


func _on_music_volume(value: float) -> void:
        SaveManager.set_setting("music_volume", value)
        if AudioManager:
                AudioManager._apply_settings()


func _on_language_changed(idx: int) -> void:
        var lang := "fa" if idx == 0 else "en"
        SaveManager.set_setting("language", lang)
        SaveManager.save_async()


func _on_reset() -> void:
        if AudioManager:
                AudioManager.play_sfx(AudioManager.SFX.BUTTON)
        confirm_panel.visible = true


func _on_reset_confirmed() -> void:
        if AudioManager:
                AudioManager.play_sfx(AudioManager.SFX.BUTTON)
        GameManager.reset_progress()
        confirm_panel.visible = false
        # Reload this scene to refresh toggles.
        get_tree().reload_current_scene()


func _on_reset_cancelled() -> void:
        if AudioManager:
                AudioManager.play_sfx(AudioManager.SFX.BUTTON)
        confirm_panel.visible = false


func _on_back() -> void:
        if AudioManager:
                AudioManager.play_sfx(AudioManager.SFX.BUTTON)
        GameManager.current_state = GameManager.GameState.MAIN_MENU
        get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
