extends Object

var t = false
var d = 100
var s0 = 0
var items = []
var busy = false
var mono = false

signal done

func _init():
    s0 = OS.get_unix_time()
    #t = Thread.new()
    pass

func pend(x):
    put(x)
    run()

func put(x):
    if mono && isOn():
        return false
    items.append(x)

func stats():
    print(items)

func isOn():
    return busy

func run():
    if isOn():
        return false

    busy = true
    call_deferred('walk')
    #t.start(self, 'call_deferred', 'walk')

func walk():
    var x = true
    var c = 0
    while x:
        var s = OS.get_unix_time()
        x = items.pop_front()
        if !x: break
        c += 1
        x.node.setTexture(loadFile(x.path))
        x.node.fname = x.path.split('/')[-1]
        var e = OS.get_unix_time()
        var d = e - s
        if d < 2:
            OS.delay_msec(2000)
        print('Update:', e - s0)
    busy = false
    emit_signal('done', c)

func loadFile(path: String):
  var file = File.new()
  var err = file.open(path, File.READ)
  if err != 0:
    print('Unable to open file /%s/. Code: %s' % [path, err])
    return false
  var length = file.get_len()
  var bytes = file.get_buffer(length)
  file.close()
  #verbose dd("%s: %.1fK" % [path, length / 1024])
  var img = Image.new()
  var data = img.load_jpg_from_buffer(bytes)
  # detext aspect
  var size = img.get_size()
  var isV = size.x < size.y
  var texture = ImageTexture.new()
  var ok = texture.create_from_image(img)
  
  return texture
