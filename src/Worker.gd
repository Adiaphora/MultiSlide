extends Object

"""
Multithreaded implementation
"""

var thread = Thread.new()
var listing = []
var callback = false

signal loaded

"""
Scan folder for images
"""
func lsImages(arg):
    var start = OS.get_unix_time()
    var images = FS.ls(arg)
    var v = []
    var h = []
    for uri in images:
        var img = FS.readImage(uri)
        var size = img.get_size()
        var isV = size.x < size.y
        if isV:
            v.append(uri)
        else:
            h.append(uri)

    var end = OS.get_unix_time()

    call_deferred(
        'done',
        {
            "delta": end - start,
            "v": v,
            "h": h,
            "ls": images,
        }
    )

func listImages(path):
    runJob("lsImages", path)

func runJob(fn, args):
    if not thread.is_active(): # Can't run on active thread
        thread.start(self, fn, args)
        return
    print('Already running')

func done(data):
    thread.wait_to_finish()
    emit_signal('loaded', data)
