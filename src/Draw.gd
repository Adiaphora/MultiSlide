extends Popup

signal newrects

var cells = []
var start = OS.get_unix_time()
var drag = false
var p0 = false
var p1 = false
var m0 = false
var m1 = false
var mr = false
var rr = false
var s = false
var cc = 0

var wsize = 0
var osize = 0
var grid = 50
var ogrid = 50
var base = false
var State = {
       "rects": []
    }

func _ready():
    base = $Segments
    #$HBox.set_as_toplevel(true)
    base.connect("gui_input", self, "track")
    $HBox/Cancel.connect("pressed", self, "cancel")
    $HBox/Reset.connect("pressed", self, "reset")
    $HBox/Accept.connect("pressed", self, "save")
    osize = base.rect_size
    wsize = osize
    var mx = osize.x > osize.y
    var v12 = 0
    var ar = 0
    v12 = osize.x / 12
    ar = osize.y / v12
    grid = Vector2(v12, osize.y / round(ar))
    ogrid = grid
    
    get_tree().get_root().connect("size_changed", self, "resize")
    s = ColorRect.new()
    s.color = Color(1,1,1,.5)
    base.add_child(s)
    mr = Rect2(0, 0, 0, 0)
    
    if State.rects:
        for r in State.rects:
            var c = newCell()
            c.set_position(r.position)
            c.rect_size = r.size
    else:
        var c = newCell()
        c.set_position(grid)
        c.rect_size = grid * 3
    return

"""
Draw sections
"""
func track(event):
    var c = base.get_local_mouse_position()
    var g = Vector2(100, 100)
    var snap = c.snapped(grid)
    if event is InputEventMouseButton:
        if event.is_pressed():
            drag = true
            rr = newCell()
            m0 = c
        else:
            rr = false
            drag = false
    if !drag:
        return

    m1 = c
    mr = Rect2(m0, m1 - m0).abs()
    s.rect_position = mr.position
    s.rect_size = mr.size
    var select = detectArea(wsize, mr, grid)
    rr.rect_position = select.position
    rr.rect_size = select.size
    return

    # TODO intersection
    var re = select
    for cs in cells:
        if rr.name == cs.name:
            continue
        var rs = Rect2(cs.rect_position, cs.rect_size)
        if re.intersects(rs):
            print('violation')
            return false

"""
Apply configuration
"""
func save():
    var data = []
    var g = Vector2(10, 10)
    for c in cells:
        data.append(Rect2(
            c.rect_position.snapped(g),
            c.rect_size.snapped(g)
        ))
    emit_signal("newrects", base.rect_size, data)
    # normalize
    #State.setRects(data)
    hide()

"""
Cancel
"""
func cancel():
    # reset()
    hide()

func reset():
    for n in cells:
        base.remove_child(n)
        n.queue_free()
    cells = []

func resize():
    wsize = base.rect_size
    var delta = wsize / osize
    osize = wsize

    grid = ogrid * delta
    ogrid = grid
    # TODO concern maximized cell
    for cs in cells:
        cs.set_position(cs.rect_position * delta)
        cs.rect_size = cs.rect_size * delta


func detectArea(r1, r2, div):
    var area = Rect2(0,0,0,0)
    var u = range(floor(r1.x / div.x) + 1)
    var v = range(floor(r1.y / div.y) + 1)
    for i in u:
        for j in v:
            var segment = Rect2(div * Vector2(i, j), div)
            if segment.has_point(r2.position):
                area = segment

    for i in u:
        for j in v:
            var segment = Rect2(div * Vector2(i, j), div)
            if segment.intersects(r2):
                area = area.merge(segment)

    return area

func newCell():
    var cell = ColorRect.new()
    cell.rect_clip_content = true
    var btn = Button.new()
    # btn.align = Button.ALIGN_CENTER
    btn.rect_pivot_offset.x = 150
    btn.set_anchors_and_margins_preset(Control.PRESET_CENTER)
    btn.text = 'X'
    cell.add_child(btn)
    btn.connect("pressed", self, "drop", [cell])
    cell.add_to_group('segments')
    cell.color = Color(.5+randf(),.5+randf(),.5+randf(), .4)
    cell.name = 'c%d' % cc
    cc += 1
    cells.append(cell)
    base.add_child(cell)

    return cell

func drop(node):
    var p = node.get_parent()
    for c in cells:
        if c.name == node.name:
            cells.remove(cells.find(c))
    p.remove_child(node)
    node.queue_free()
