extends Node

const SAVEFILE = "./settings.json"
const MODES = [
    'template',
    'json',
    'svg'
]

var data = {}
var defaults = {
    "fullscreen": false,
    "mode": "template",
    "delay": 3,
    "templateid": 0,
    "recursive": true,
    "random": true,
    "sourceSVG": "layout1.svg",
    "jsonSource": "",
    "imageFolder": "",
    "history": "",
    "transitions": false,
    "randomTimer": true,
    "showNames": false,
    "showProgress": false,
}

signal toggle_random
signal newdelay

func _ready():
    data = FS.loadData(defaults)

func _get(property, def = false):
    if (property in data):
        return data[property]
    return def

#func _set(k, v):
#    data[k] = v

func setMode(type):
    persist('mode', type)

func setTemplate(id):
    persist('templateid', id)

func updateFolder(path:String):
    persist('imageFolder', path)

func setDelay(n):
    emit_signal('newdelay', n)
    persist('delay', n)

func persist(prop, value):
    data[prop] = value
    FS.saveData(data)

func toggleFullscreen(toggle):
    OS.window_fullscreen = toggle
    persist('fullscreen', toggle)

func toggleNames(flag):
    # emit toggle names
    persist('showNames', flag)

func toggleProgress(flag):
    # emit toggle progress
    persist('showProgress', flag)

func toggleRecursive(toggle):
    persist('recursive', toggle)

func toggleRandom(toggle):
    emit_signal("toggle_random")
    persist('random', toggle)

func isSVG():
    return str(self.mode) == 'svg' && self.sourceSVG

func customJson(raw):
    persist('jsonSource', raw)
