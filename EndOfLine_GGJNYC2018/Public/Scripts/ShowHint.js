// -----JS CODE-----
// @input string hintId {"widget": "combobox","values": [{"label": "Open your mouth", "value": "lens_hint_open_your_mouth"},{"label": "Open your mouth, Voice Changer", "value": "lens_hint_open_your_mouth_voice_changer"},{"label": "Raise your eyebrows", "value": "lens_hint_raise_your_eyebrows"},{"label": "Kiss", "value": "lens_hint_kiss"},{"label": "Blow a kiss", "value": "lens_hint_blow_a_kiss"},{"label": "Raise eyebrows or open mouth", "value": "lens_hint_raise_eyebrows_or_open_mouth"},{"label": "Face swap", "value": "lens_hint_face_swap"},{"label": "Face swap camera roll", "value": "lens_hint_face_swap_camera_roll"},{"label": "Blink", "value": "lens_hint_blink"},{"label": "Smile", "value": "lens_hint_smile"},{"label": "Try rear camera", "value": "lens_hint_try_rear_camera"},{"label": "Try friend", "value": "lens_hint_try_friend"},{"label": "Voice changer", "value": "lens_hint_voice_changer"},{"label": "Raise your eyebrows again", "value": "lens_hint_raise_your_eyebrows_again"},{"label": "Open your mouth again", "value": "lens_hint_open_your_mouth_again"},{"label": "Kiss again", "value": "lens_hint_kiss_again"},{"label": "Smile again", "value": "lens_hint_smile_again"},{"label": "Now raise your eyebrows", "value": "lens_hint_now_raise_your_eyebrows"},{"label": "Now kiss", "value": "lens_hint_now_kiss"},{"label": "Now smile", "value": "lens_hint_now_smile"},{"label": "Now open your mouth", "value": "lens_hint_now_open_your_mouth"},{"label": "Keep raising your eyebrows", "value": "lens_hint_keep_raising_your_eyebrows"},{"label": "Draw with your finger", "value": "lens_hint_draw_with_your_finger"},{"label": "Raise your eyebrows to start the game", "value": "lens_hint_raise_your_eyebrows_to_start_the_game"},{"label": "Tap", "value": "lens_hint_tap"},{"label": "Look up", "value": "lens_hint_look_up"},{"label": "Look around", "value": "lens_hint_look_around"},{"label": "Swap camera", "value": "lens_hint_swap_camera"},{"label": "Make some noise", "value": "lens_hint_make_some_noise"},{"label": "Blow a kiss voice changer", "value": "lens_hint_blow_a_kiss_voice_changer"},{"label": "Do not smile", "value": "lens_hint_do_not_smile"},{"label": "Do not try with a friend", "value": "lens_hint_do_not_try_with_a_friend"},{"label": "Raise your eyebrows voice changer", "value": "lens_hint_raise_your_eyebrows_voice_changer"},{"label": "Smile voice changer", "value": "lens_hint_smile_voice_changer"},{"label": "Find face", "value": "lens_hint_find_face"},{"label": "Nod your head", "value": "lens_hint_nod_your_head"}]}
// @input float inputShowTime = 2.0 {"label": "Show Time"}
// @input float inputDelayTime {"label": "Delay Time"}
// @input bool inputShowOnce = true {"label": "Show Once"}

var show = false
if (self.inputShowOnce) {
    show = self.script.api["___hintWasShowed___"]
}
if (show === undefined || show === null || show === false) {
    var kHintComponentName = "Component.HintsComponent"
    var kDelayedCallbackEventName = "DelayedCallbackEvent"

    if(self.script.getSceneObject().getComponentCount(kHintComponentName) == 0)
        var hintComponent = self.script.getSceneObject().createComponent(kHintComponentName)
    else
        var hintComponent = self.script.getSceneObject().getFirstComponent(kHintComponentName);
    var delayEvent = self.script.createEvent(kDelayedCallbackEventName)
    delayEvent.bind(function(eventData) {
        hintComponent.showHint(self.hintId, self.inputShowTime)
    })
    delayEvent.reset(self.inputDelayTime)
    if (self.inputShowOnce) {
        self.script.api["___hintWasShowed___"] = true
    }
    
}
