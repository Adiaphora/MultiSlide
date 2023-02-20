extends Node

"""
FS related methods
"""

func _ready():
    pass

func existsFile(path: String) -> bool:
    var file = File.new()
    return file.file_exists(path)

func existsDir(path: String) -> bool:
    if !path:
        return false
    var dir = Directory.new()
    return dir.open(path) == OK

func loadData(defs: Dictionary):
    var opts = {}
    if ! existsFile(Config.SAVEFILE):
        # TODO version update/merge
        opts = defs
        saveData(opts)
    else:
        var raw = read(Config.SAVEFILE)
        opts = JSON.parse(raw).result

    return opts

func saveData(input: Dictionary):
    save(JSON.print(input, "  "))

func save(content):
    var file = File.new()
    file.open(Config.SAVEFILE, File.WRITE)
    file.store_string(content)
    file.close()

func read(path: String):
  var file = File.new()
  file.open(path, File.READ)
  var raw = file.get_as_text()
  file.close()

  return raw

func readRaw(path: String):
    var file = File.new()
    var err = file.open(path, File.READ)

    return false if err != 0 else file

func readBytes(path: String):
    var file = readRaw(path)
    if ! file:
        return false

    var length = file.get_len()
    var bytes = file.get_buffer(length)
    #verbose dd("%s: %.1fK" % [path, length / 1024])
    file.close()

    return bytes

# TODO max depth
func ls(path: String) -> Array:
    return lsJpeg(path)

"""
Scan directory for jpegs
"""
func lsJpeg(path: String) -> Array:
    var files: Array = []
    var dir := Directory.new()
    if dir.open(path) != OK:
        printerr("Warning: could not open directory: ", path)
        return []

    if dir.list_dir_begin(true, true) != OK:
        printerr("Warning: could not list contents of: ", path)
        return []

    var name := dir.get_next()
    var jpgs = RegEx.new()
    jpgs.compile("\\.(jpg|jpeg)")
    while name != "":
        var nm = dir.get_current_dir() + "/" + name
        if dir.current_is_dir():
            # TODO recursive
            #print('dir', nm)
            var sublist = lsJpeg(nm)
            name = dir.get_next()
            if sublist.size() > 0:
                files.append_array(lsJpeg(nm))
            continue

        if !jpgs.search(name.to_lower()):
            name = dir.get_next()
            continue

        files.append(dir.get_current_dir() + "/" + name)
        name = dir.get_next()

    return files

"""
List directory with aspect detection
"""
func lsAspect(path: String) -> Dictionary:
    var start = OS.get_unix_time()
    var listing = lsJpeg(path)
    var v = []
    var h = []
    # TODO yeld
    for uri in listing:
        var img = readImage(uri)
        var size = img.get_size()
        var isV = size.x < size.y
        if isV:
            v.append(uri)
        else:
            h.append(uri)

    var end = OS.get_unix_time()

    return {
        "delta": end - start,
        "v": v,
        "h": h,
        "ls": listing,
    }

func readImage(path: String):
    var bytes = readBytes(path)
    if ! bytes:
        print('Unable to open file /%s/.' % [path])
        return false

    var img = Image.new()
    # TODO formats
    var err = img.load_jpg_from_buffer(bytes)
    if err:
        print('Invalid image. Code %d' % err)
        return false

    return img
