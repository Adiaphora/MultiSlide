extends Popup

const MINDELAY = 2

signal newdir

func _ready():
    if Config.random:
        $Margin/Grid/cbRandom.pressed = true
    if Config.delay:
        $Margin/Grid/HBoxDelay/Sec.value = Config.delay
    $Margin/Grid/cbNames.connect("toggled", self, "setNames")
    $Margin/Grid/cbRandom.connect("toggled", self, "setRandom")
    $Margin/Grid/cbOntop.connect("toggled", self, "setOntop")
    $Margin/Grid/cbFullscreen.connect("toggled", self, "setFullscreen")
    $Open.connect("pressed", self, "showFileDialog")
    $FileDialog.connect("dir_selected", self, "setDir")
    $Margin/Grid/TextEdit.connect("text_changed", self, "broadcast")
    #TODO debounce
    $Margin/Grid/HBoxDelay/Sec.connect("value_changed", self, "delayChange")

func showFileDialog():
    $FileDialog.show()

"""
Set and emit
"""
func setDir(path):
    $Margin/Grid/TextEdit.text = path
    broadcast(path)

"""
Emit only
"""
func broadcast(path):
    emit_signal('newdir', path)

func setNames(f: bool):
    Config.toggleNames(f)

func setOntop(f: bool):
    OS.set_window_always_on_top(!OS.is_window_always_on_top())

func setFullscreen(f: bool):
    Config.toggleFullscreen(f)

func setRandom(f):
    Config.toggleRandom(f)

func delayChange(v):
    var n = int(v)
    if n < MINDELAY: n = MINDELAY
    Config.setDelay(int(v))
