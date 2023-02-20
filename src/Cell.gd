# TODO move texture node
extends TextureRect

onready var progressTween = $ProgressTween
onready var pauseTween = $Tween
export var duration = 5 setget setDur,getDur
export var delay = 5
export var left = 0 setget setTo,getTo
export var fname = '' setget setName,getName
export var state = 'play'

signal fnchange

var useFX = true
var transDuration = 1
var pan = false
var cellSize = 0
var texSize = 0
onready var base = false

func _ready():
    base = get_node('.')
    #base.material["shader_param/t1"] = base.texture
    if (Config.showNames):
        $Filename.show()
    if (Config.showProgress):
        $ProgressBar.show()

    self.connect("mouse_entered", self, "showToggle")
    self.connect("mouse_exited", self, "hideToggle")
    var drag = $btnBar/HBox/btnDrag
    drag.connect('button_down', self, 'dragStart')
    drag.connect('button_up', self, 'dragEnd')
    drag.connect('pressed', self, 'dragEnd')

func _gui_input(event):
    var isM = event is InputEventMouse
    """
    if (event is InputEventMouseButton && event.is_action_released("click")):
        print('release')
        dragEnd()
    """

    if !pan:
        return

    var pos = get_local_mouse_position()
    if isM:
        var v = Vector2()
        v = (pos / cellSize) * (texSize - cellSize) / texSize
        self.material.set_shader_param("pos", v)

func track(e = false, data = false):
    print(e, data)

func can_drop_data(position: Vector2, data) -> bool:
    return typeof(data) == TYPE_OBJECT

func acceptable():
    pass

func get_drag_data(position: Vector2):
    # TODO track file change
    return texture

func drop_data(position: Vector2, data) -> void:
    emit_signal('fnchange', fname)
    texture = data

func setName(v):
  $Filename.text = str(v)

func getName():
  return fname

func setTo(v):
  $Ctr.text = str(v)

func getTo():
  return $Ctr.text

"""
Personal timer controls
"""
func setDur(v):
    if paused():
        return
    if !progressTween:
        return
    progressTween.reset($ProgressBar)
    progressTween.interpolate_property(
        $ProgressBar,
        "value",
        100,
        0,
        v
    )
    progressTween.start()

func getDur() -> int:
  return duration

func paused() -> bool:
  return state == 'pause'

"""
Change state
"""
func pause():
    state = 'pause'
    $c_lt.show()
    $c_rt.show()
    $c_rb.show()
    $c_lb.show()
    return
    if !$btnBar/HBox/btnPause.pressed:
        $btnBar/HBox/btnPause.pressed = true

"""
Change state
"""
func resume():
    state = 'play'
    $c_lt.hide()
    $c_rt.hide()
    $c_rb.hide()
    $c_lb.hide()
    return
    if $btnBar/HBox/btnPause.pressed:
        $btnBar/HBox/btnPause.pressed = false

"""
Change state and appearence
"""
func toggleState(_x = false):
    if self.paused():
        resume()
        progressTween.resume($ProgressBar)
    else:
        pause()
        progressTween.stop($ProgressBar)

func showToggle():
    $btnBar.show()

func hideToggle():
    $btnBar.hide()

func cancelFade():
    pauseTween.stop($Play)
    pauseTween.reset($Play)

func fadePause():
    pauseTween.interpolate_callback(
        self,
        3,
        "hideToggle"
    )
    pauseTween.start()

func toggleMode(pressed):
    var mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED if pressed else TextureRect.STRETCH_KEEP_ASPECT_COVERED
    self.stretch_mode = mode
    $TexOverlay.stretch_mode = mode

"""
Drop texture callback
"""
func setTexture(tex, name = ''):
    if !useFX || texture.get_class() == 'StreamTexture':
        texture = tex
    else:
        # TODO ratio, TEXTURE uniform
        updateTex(tex)
    rect_clip_content = false
    #stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
    material.set_shader_param("pos", Vector2(0,0))
    if name:
        fname = name

"""
Drag mode
TODO implement shader/mode movement
"""
func dragStart():
    pan = true
    cellSize = self.rect_size
    texSize = self.texture.get_size()
    self.rect_clip_content = true
    self.stretch_mode = TextureRect.STRETCH_KEEP

"""
Drag end handler
"""
func dragEnd():
    pan = false
    # leave / reset
    """
    self.rect_clip_content = false
    self.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
    self.material.set_shader_param("pos", Vector2(0,0))
    """
    pass # Replace with function body.

"""
Update texture with overlay TextureRect
"""
func updateTex(t2):
    var t1 = texture
    $TexOverlay.texture = t1
    $TexOverlay.modulate = Color(1.0,1.0,1.0,1.0)
    texture = t2
    var tween = $Tween
    tween.interpolate_property(
        $TexOverlay,
        "modulate",
        Color(1.0,1.0,1.0,1.0),
        Color(1.0,1.0,1.0,0.0),
        transDuration
    )
    if !tween.is_active():
        tween.start()
    if !tween.is_connected('tween_completed', self, 'swap'):
        tween.connect("tween_completed", self, "swap", [t2])

"""
Stab
"""
func swap(node, e, t2):
    $TexOverlay.texture = null
    pass

"""
Update texture with shader transition
TODO ratio
"""
func updateTexGL(tex):
    base.material["shader_param/t2"] = tex
    var ts = tex.get_size().normalized()
    base.material["shader_param/t2s"] = Vector2(100,100)
    var tween = $Tween
    tween.interpolate_property(
        base.get_material(),
        "shader_param/delta",
        0.0, 1.0, 1.75,
        Tween.TRANS_LINEAR, Tween.EASE_OUT
    )
    tween.start()
    tween.connect("tween_completed", self, "swap", [tex])

"""
Actual texture swap
TODO ratio
"""
func swapGL(tex):
    base.texture = tex
    base.material["shader_param/t1"] = tex
    base.material["UV"] = tex.get_size().normalized()
    base.material["shader_param/delta"] = 0
    base.material["shader_param/t2"] = false
