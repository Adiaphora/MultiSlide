extends Popup

"""
Split with handles
TODO Mapping
"""

signal newrects

onready var base = $Container
onready var info = $Panel/HBox/Info
onready var apply = $Panel/HBox/Accept
var m = Vector2(300, 300)
var data = {
    'p': []
}
var wsize = false
var csize = false

# Basic initial split
func _ready():
    wsize = get_viewport().size
    csize = $Container.rect_size
    split('h')
    info.text = "size: %s, splits: %d" % [
        wsize,
        $Container.get_child_count()
    ]
    apply.connect("pressed", self, 'toJSON')
    $Panel/HBox/Cancel.connect("pressed", self, "cancel")

func _input(event):
    if isM2Click(event):
        m = event.position

func toJSON():
    print(data)
    var rects = toRects(base.get_children())
    emit_signal("newrects", base.rect_size, rects)
    hide()

func toRects(nodes = []):
    var rects = []
    var g = Vector2(50, 50)
    var bg = base.get_global_position()
    for node in nodes:
        var subnodes = node.get_children()
        if subnodes:
            rects.append_array(toRects(subnodes))
        if node.get_class() != 'ColorRect':
            continue
        rects.append(Rect2(
            (node.get_global_position() - bg).snapped(g),
            node.rect_size.snapped(g)
        ))
    return rects

"""
Cancel
"""
func cancel():
    # reset()
    hide()

func split(mode):
  var vv = getSplit(mode)
  base.add_child(vv)

func getNode():
  var p = ColorRect.new()
  randomize()
  p.color = Color(randf(),randf(),randf())
  p.connect('gui_input', self, 'splitReplace', [p])
  return p

func getSplit(mode: String) -> SplitContainer:
    var vv = false
    var r = 0
    match mode:
        'v':
            vv = VSplitContainer.new()
            vv.split_offset = m.y if m.y else 300
            r = vv.split_offset / csize.x
        'h':
            vv = HSplitContainer.new()
            vv.split_offset = m.x if m.x else 500
            r = vv.split_offset / csize.y

    data.p.append({
        'd': mode,
        'r': int(r * 10) * 10,
        'pos': m,
        'childs': [
            '0.' + mode,
            '1.' + mode
        ]
    })

    var n = getNode()
    n.name = '0.' + mode
    vv.add_child(n)
    n = getNode()
    n.name = '1.' + mode
    vv.add_child(getNode())

    return vv

func dd(x):
  print(x)

func splitReplace(e, node):
  if !isClick(e): return
  m = node.get_local_mouse_position()
  if e.shift:
    node.replace_by(getSplit('v'))
  elif e.control:
    node.replace_by(getSplit('h'))
  elif e.alt:
    var s = node.get_parent()
    walkDelete(s)
    s.replace_by(getNode())

func isClick(e):
  return e is InputEventMouseButton and e.pressed

func isM1Click(e):
  return isClick(e) and e.button_index == 1

func isM2Click(e):
  return isClick(e) and e.button_index == 2

func vSplit():
  # replace current node
  split('v')
  pass # Replace with function body.

func hSplit():
  split('h')
  return true

func walkDelete(node):
  for n in node.get_children():
    node.remove_child(n)
    n.queue_free()

func cleanup():
  var child = $Container.get_child(0)
  if ! child:
    return true
  #if (child.has_children(): walkDelete(child)
  $Container.remove_child(child)
  child.queue_free()
  return true
