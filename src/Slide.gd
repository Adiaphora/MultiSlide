extends Panel

# Layout 1
const DBG = true
# TODO screen dependent
const MAXSEGMENTS = 50

var cell = preload('res://scenes/Cell.tscn')
const Layout = preload('res://src/Layout.gd')
const Picture = preload('res://src/Picture.gd')
#const circ = preload('../assets/cursor.png')

export var srcPath = '.'
onready var timer = $Timer
onready var images = []

var Presets = false
var layouts = []
var unsorted = false
var currentIndex = 0
var timeStart = 0
var now = 0

var baseDelay = 3
var randomTimer = 0
var args = {}
# cellId: image path 
var display = {}
# actual nodes
var cells = []
# coords
var rects = []
# origins
var origs = {}
# window size
var wsize = 0
# initial size
var osize = 0
var defText: ImageTexture

var locked = false
# recursion safety
var lookupCounter = 0
var maxSteps = 10

var padding = 20
var pad = Vector2(padding, padding)
var maximized = false

signal update

"""
Main init
"""
func _ready():
    args = parseArg(OS.get_cmdline_args())
    if '?' in args:
        print("TileShow v1.0\nSwitches: -p -l -t -svg\nExample: tileshow.exe -p=C:/pictures -l='{\"v3\":0}'")
        get_tree().quit()
        pass

    # TODO cursor flickering
    #Input.set_custom_mouse_cursor(circ, CURSOR_ARROW, Vector2(60,60))

    # 1 handlers
    $SettingsBtn.connect("pressed", self, "showSettings")
    $LayoutBtn.connect("pressed", self, "showLayoutSettings")
    $LayoutSetup.btnDraw.connect("pressed", self, "showDraw")
    $LayoutSetup.btnSplit.connect("pressed", self, "showSetup")
    $LayoutSetup.connect("popup_hide", self, "resumeAll")
    $LayoutSetup.rawJson.connect("text_changed", self, "acceptJson")
    connect("update", self, "updateStats")
    Config.connect("toggle_random", self, "setOrder")
    Config.connect("newdelay", self, "setDelay")
    #connect("popup_hide", self, "resumeAll")
    $DrawPopup.connect("newrects", self, "acceptRects")
    $SplitPopup.connect("newrects", self, "acceptRects")

    unsorted = Config.random
    layouts = Layout.getTemplates()

    # TODO parse/add user templates
    for p in layouts:
        $LayoutSetup.presets.add_item(p.label)
    $LayoutSetup.presets.connect("item_selected", self, "setLayout")

    get_tree().get_root().connect("size_changed", self, "resize")

    # initial dims
    wsize = get_viewport_rect().size
    osize = wsize

    # 2 path timer window size
    if 'p' in args:
        srcPath = args['p']
    elif Config.imageFolder:
        srcPath = Config.imageFolder
    else:
        # avoid mass scan
        pass
    $SettingsPopup.connect("newdir", self, "newPath")
    $SettingsPopup.connect("popup_hide", self, "resumeAll")

    if 't' in args:
        setDelay(args['t'])
    elif Config.delay:
        setDelay(Config.delay)
    else:
        # default timeout
        pass

    if !FS.existsDir(srcPath):
        showSettings()
    else:
        $SettingsPopup/FileDialog.current_path = srcPath
        $SettingsPopup/Margin/Grid/TextEdit.text = srcPath
        call_deferred('newPath', srcPath)

func updateStats(data):
    $LayoutSetup.updateStats(data)

func setOrder():
    unsorted = !unsorted

func setDelay(n):
    timer.wait_time = n

"""
Set new path, regenerate layout
event handler
TODO slow, io
"""
func newPath(path):
    # wait for listing
    updatePath(path)
    if images.size() == 0:
        return false

    if cells.size() != 0:
        return true

    setRects(getRects())
    updateLayout(rects)

"""
Update layout with rectangles
slow, frames
"""
func acceptRects(source:Vector2, a = []):
    setRects(Layout.fitInstant(
        wsize,
        source,
        a
    ))

    updateLayout(rects)

"""
{"v.25.75":{"0.h.30":0,"2.h3":0}}
{"v4":{"0.h2":0,"2.h3":0}}
{"h.5.90":{"0.v8":0,"2.v9":0}}
{"h.10.90":{"0.v7":0,"1.v.10.90":{"0.h3":0, "2.h4":0},"2.v9":0}}
"""
func acceptJson(raw: String):
    # validation regexp
    # ^\{\s*(\"[hv][\d\.]*\")\s*:\s*(\{.*\}|\d*,?)\}
    var fragments = Layout.new(Rect2(Vector2(0, 0), wsize))
    var segments = fragments.fromJson(raw)
    if !segments:
        return false

    Config.customJson(raw)
    $LayoutSetup.info = '%d segments' % segments.size()
    if segments.size() > MAXSEGMENTS:
        return false

    setRects(segments)
    updateLayout(rects)

"""
Procedure to break given rectangle into fragments
"""
func getRects():
    var fragments = Layout.new(Rect2(Vector2(0, 0), wsize))
    var layout = []
    if ('l' in args):
        layout = fragments.fromJson(args['l'])
    elif Config.isSVG():
        layout = fragments.fromSvg(Config.sourceSVG)
    elif ('svg' in args):
        layout = fragments.fromSvg(args.svg)
    else:
        var tid = getTemplate()
        layout = fragments.getSegments(layouts[tid].data)
    setRects(layout)

    return rects

"""
Setter
"""
func setRects(a):
    if ! a || a.size() == 0:
        return false

    rects = a
    return true

"""
Pick template id
"""
func getTemplate():
    if Config.templateid:
        return Config.templateid
    else:
        randomize()
        return randi() % layouts.size()

func _input(event):
    match event:
        InputEventKey:
            var code = event.scancode
            if event.pressed:
                if code == KEY_ESCAPE:
                    get_tree().quit()
                if code == KEY_SPACE:
                    # expand under cursor
                    pass

"""
Generate and update layout from template
"""
func setLayout(id: int = 0):
    var preset = pickLayout(id)
    # if presets chosen
    Config.setTemplate(id)
    var fragments = Layout.new(Rect2(Vector2(0, 0), wsize))
    setRects(fragments.getSegments(preset.data))
    updateLayout(rects)

"""
Pause all processes, generate actual cells
and start slideshow
"""
func updateLayout(segments: Array):
    timer.stop()
    resetLayout()
    cells = generateCells(segments)
    if images.size() > 0:
        timer.start()

    return cells

"""
Queue children removal
"""
func resetLayout():
    var nodes = get_tree().get_nodes_in_group('cells')
    for n in nodes:
        $Slides.remove_child(n)
        n.queue_free()

"""
Process cli
"""
func parseArg(args):
    var o = {}
    for x in args:
        if x.find("=") < 0:
            continue
        var s = x.split("=")
        o[s[0].lstrip("-")] = s[1]

    return o

"""
Reload source path
TODO thread?
"""
func updatePath(x):
    timeStart = OS.get_unix_time()
    var scan = FS.ls(x)
    if scan.size() > 0:
        Config.updateFolder(x)
        images = scan
        currentIndex = 0
        var ttl = OS.get_unix_time()
        dd('Total images: %d, Time: %d' % [images.size(), ttl - timeStart])
        # emit images.reloaded dd('%s: %s' % [x, scan.size()])
    $SettingsPopup/ImagesCount.text = str(scan.size())

"""
Generate and draw nodes
"""
func generateCells(rects: Array) -> Array:
    var data = []
    var i = 0
    display = {}
    for s in rects:
        var node = getCell(s)
        node.name = 'Tex%d' % i
        i += 1
        setTex(node, getImage())
        # cache
        data.append(node)
        $Slides.add_child(node)
        node.duration = getTimeout()

    var preview = Layout.fitInstant(Vector2(200, 130), wsize, rects)
    emit_signal('update', preview)

    return data

func getTimeout():
    if ! (randomTimer > 0):
        return baseDelay

    randomize()
    return baseDelay + ((randi() % randomTimer) if randomTimer > 0 else 0)

"""
Init cell
"""
func getCell(r: Rect2):
    var node = cell.instance()
    node.add_to_group('cells')
    node.set_position(r.position)
    node.rect_size = r.size
    var tt = getTimeout()
    node.duration = tt
    node.delay = tt
    node.left = tt
    # TODO interfere with pause
    node.connect("gui_input", self, 'cellClick', [node])
    node.get_node("btnBar/HBox/btnMax").connect(
        "toggled",
        self,
        "toggleExpand",
        [node]
    )

    return node

func pauseAll(ex = false):
    timer.paused = true
    return

func pauseAllDirect(ex = false):    
    var cells = get_tree().get_nodes_in_group("cells")
    for c in cells:
        if ex && ex == c.name:
            continue
        c.pause()

func resumeAll(ex = false):
    timer.paused = false
    return

func resumeAllDirect(ex = false):
    var cells = get_tree().get_nodes_in_group("cells")
    for c in cells:
        if ex && ex == c.name:
            continue
        c.resume()

func matchOverlay(size):
    var wall = get_node('Wall')
    wall.rect_position = Vector2(0,0)
    wall.rect_size = size
    maximized.rect_position = pad
    maximized.rect_size = size - pad * 2

func toggleExpand(on:bool, node):
    var wall = get_node('Wall')
    if on:
        pauseAll(node.name)
        if ! wall:
            wall = ColorRect.new()
            wall.name = 'Wall'
            wall.rect_position = Vector2(0,0)
            wall.rect_size = wsize
            wall.color = Color(0,0,0,.7)
            self.add_child(wall)
        wall.show()
        maximized = node
        node.set_as_toplevel(true)
        # pause all
        origs[node.name] = Rect2(
            node.rect_position,
            node.rect_size
        )
        node.rect_position = pad
        node.rect_size = wsize - pad * 2
    else:
        maximized = false
        wall.hide()
        node.set_as_toplevel(false)
        # resume all
        node.rect_position = origs[node.name].position
        node.rect_size = origs[node.name].size
        resumeAll(node.name)

"""
Cell input handler
"""
func cellClick(e, node):
  var wheel = [BUTTON_WHEEL_DOWN, BUTTON_WHEEL_UP]
  #  && not e.is_echo()
  if e is InputEventMouseButton && e.pressed && (wheel.find(e.button_index) > -1):
    # TODO throttle
    # TODO fwd / rew
    if locked:
        print('too fast')
        return false
    locked = true
    updateNode(node)

func scrollImg(node, fwd = true):
  # find current index
  # switch to next/prev
  pass

func regenerateLayout():
    setLayout(randi() % layouts.size())

"""
Reload cell texture and timeout
"""
func updateNode(node):
    var tt = getTimeout()
    node.duration = tt
    node.delay = tt
    node.left = node.delay
    setTex(node, getImage())
    locked = false

func cellsLookup(s):
    return s in display

func resize():
    wsize = get_viewport_rect().size
    var delta = wsize / osize
    # TODO concern maximized cell
    for i in rects.size():
        cells[i].set_position(rects[i].position * delta)
        cells[i].rect_size = rects[i].size * delta
    for x in origs:
        origs[x].position = origs[x].position * delta
        origs[x].size = origs[x].size * delta
    if maximized:
        matchOverlay(wsize)

# https://stackoverflow.com/a/68770132 shader trans
func setTex(node, pic: Picture):
    if !pic:
        return false

    # track node: image
    display[node.name] = pic.path
    node.fname = pic.path.split('/')[-1]
    call_deferred('queueUpdate', node, pic.texture)
    return true

func queueUpdate(node, tex):
    # TODO queue
    node.setTexture(tex)

func getDefaultTexture():
  if defText:
    return defText

  defText = ImageTexture.new()
  var image = Image.new()
  image.load("res://assets/default.png")
  defText.create_from_image(image)

  return defText

"""
Get specific/random path
"""
func getImage():
    var isize = images.size()
    if isize == 0:
        # no source
        return false

    if lookupCounter > maxSteps:
        lookupCounter = 0
        return false

    lookupCounter +=1

    var index = 0
    if unsorted:
        randomize()
        index = randi() % isize
    else:
        index = currentIndex
        currentIndex += 1
        if currentIndex > isize - 1:
            currentIndex = 0

    var path = images[index]
    var shown = display.values().has(path)
    var pic = false
    # read fs
    pic = loadJpeg(path)
    if !pic:
        # TODO failed load, recursive
        return getImage()

    # new image
    if !shown:
        # display
        lookupCounter = 0
        return pic

    # already shown
    # no more uniq images
    if isize < rects.size():
        # display
        lookupCounter = 0
        return pic

    # there are more
    return getImage()

func showSettings():
    pauseAll()
    $SettingsPopup.popup_centered()

func showSetup():
    pauseAll()
    $SplitPopup.popup_centered()

func showDraw():
    pauseAll()
    $DrawPopup.popup_centered()

func showLayoutSettings():
    pauseAll()
    $LayoutSetup.popup_centered()

"""
Switch images
Single image at a time
"""
func interval():
    if cells.size() == 0:
        return false

    call_deferred('updateRandomCell')

"""
Pick random cell
TODO image aspect based
"""
func updateRandomCell():
    var ids = listActive()
    if ids.size() == 0:
        return false

    ids.shuffle()
    var node = cells[ids.pop_front()]
    updateNode(node)

"""
TODO use assoc keys
"""
func listActive():
    var ids = []
    var x = range(cells.size())
    for id in x:
        if cells[id].paused():
            continue
        ids.append(id)
    
    return ids

"""
TODO individual timeouts
"""
func updateRandomCellTimeout():
    var now = OS.get_unix_time()
    var elapsed = now - timeStart
    if elapsed == 0: return
    var updated = false
    var ids = listActive()
    ids.shuffle()
    for id in ids:
        # refresh every cell counters
        updated = updateTimeout(cells[id], elapsed)
        if updated:
            # TODO simulteneous
            break

"""
Personal timer updater on specific Cell
"""
func updateTimeout(node, elapsed):
    if (node.paused()):
        return false
    # set pending state
    if node.delay < 1: node.delay = -1
    var d = elapsed % node.delay
    node.delay -= 1
    d = node.delay
    node.left = d
    if d < 1:
        updateNode(node)
        return true

    return false

"""
TODO load any format
"""
func loadImg(path: String):
    var image = Image.new()
    var err = image.load(path)
    if err != OK:
        dd('fail: %s' % path)
        return false

    var texture = ImageTexture.new()
    var ok = texture.create_from_image(image)

    return texture

"""
Path to ImageTexture
@deprecated
"""
func loadJpegTexture(path: String):
    var bytes = FS.readBytes(path)
    if ! bytes:
        dd('Unable to open file /%s/.' % [path])
        return false

    var img = Image.new()
    var err = img.load_jpg_from_buffer(bytes)
    if err:
        dd('Code %d; Invalid image %s' % [err, path])
        return false
        
    var texture = ImageTexture.new()
    err = texture.create_from_image(img)

    return texture

"""
Load jpeg by path
TODO return Picture | bool
@return Picture
"""
func loadJpeg(path: String):
    var bytes = FS.readBytes(path)
    if ! bytes:
        dd('Unable to open file /%s/.' % [path])
        return false

    var img = Image.new()
    var err = img.load_jpg_from_buffer(bytes)
    if err:
        dd('Code %d; Invalid image %s' % [err, path])
        return false

    var pic = Picture.new()
    pic.path = path
    pic.size = bytes.size()
    pic.dim = img.get_size()

    var texture = ImageTexture.new()
    var ok = texture.create_from_image(img)
    pic.texture = texture

    return pic

func pickLayout(n):
    return layouts[n]

func dd(x):
    if (DBG): print(x)

"""
Scope: Image utils
"""
func resizeTexture(
    t: Texture,
    width: int = 0,
    height: int = 0) -> ImageTexture:
    var image = t.get_data()
    if width > 0 && height > 0:
        image.resize(width, height)
    var itex = ImageTexture.new()
    itex.create_from_image(image)

    return itex

# deprecated
func changeColor(node):
  node.color = randColor()
  return

# deprecated
func randColor():
  randomize()
  var l = .2
  return Color(
    l + randf(),
    l + randf(),
    l + randf()
  )
