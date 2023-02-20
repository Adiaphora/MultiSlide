extends Popup

"""
Layout Popup Controller
"""

onready var cbTemplate = $Margin/HSplitContainer/VSplitContainer/Templates/CheckButton
onready var jsonHint = $Margin/HSplitContainer/Opts/Stats/Hint
onready var rawJson = $Margin/HSplitContainer/Opts/JSON/VBoxContainer/RawJson
onready var preview = $Margin/HSplitContainer/Opts/Preview
onready var btnDraw = $Margin/HSplitContainer/Opts/btnDraw
onready var btnSplit = $Margin/HSplitContainer/Opts/btnSplit
onready var presets = $Margin/HSplitContainer/VSplitContainer/Presets

export var info = '' setget setInfo,getInfo

func _ready():
    if Config.mode == 'template':
        cbTemplate.pressed = true
    
    if Config.jsonSource:
        rawJson.text = Config.jsonSource

    var cbJSON = $Margin/HSplitContainer/Opts/JSON/CheckButton
    if Config.mode == 'json':
        cbJSON.pressed = true

    var cbSVG = $Margin/HSplitContainer/Opts/SVG/CheckButton
    if Config.mode == 'svg':
        cbSVG.pressed = true

    cbTemplate.connect("toggled", self, "setTemplate")
    presets.connect('item_selected', self, 'autocheck')
    cbJSON.connect("toggled", self, "setJSON")
    cbSVG.connect("toggled", self, "setSVG")

func autocheck(id: int = 0):
    if ! cbTemplate.pressed:
        cbTemplate.pressed = true

func setTemplate(f: bool):
    if f:
        Config.setMode('template')

func setSVG(f: bool):
    if f:
        # check if exists and valid
        Config.setMode('svg')

func setJSON(f: bool):
    if f:
        # check if valid
        Config.setMode('json')

func setInfo(data):
    jsonHint.text = data

func getInfo():
    return jsonHint.text

func updateStats(data):
    jsonHint.text = 'Segments: %d' % data.size()
    genPreview(data)

func genPreview(data = []):
    for c in preview.get_children():
        preview.remove_child(c)
        c.queue_free()

    for s in data:
        var r = ColorRect.new()
        #r.rect_size = Vector2(100, 100)
        r.set_size(s.size)
        r.rect_position = s.position
        r.color = randColor()
        preview.add_child(r)

# TODO scope
func randColor():
    randomize()
    var l = .2
    return Color(
        l + randf(),
        l + randf(),
        l + randf()
    )
