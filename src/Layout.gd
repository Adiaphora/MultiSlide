extends Node

"""
Tiles logic
layout generator / json decoder
"""

const SVG = preload('res://src/SVG.gd')

var rects = []
var baseRect = false

func _init(r: Rect2):
    baseRect = r

"""
Parse layout description
"""
func getSegments(layout):
    var base = layout.keys()[0]
    rects = getSlices(baseRect, decode(base), layout[base])
    return rects

"""
Split rect2 according to o options
"""
func getSlices(r: Rect2, o: Dictionary, child = false) -> Array:
    # splits
    var v = []
    if o.dir == 'v':
        v = vSplit(r.abs(), o.slices)
    else:
        v = hSplit(r.abs(), o.slices)
    var hasChild = !!child
    var ck = {}
    if hasChild:
        for k in child:
            if typeof(k) != TYPE_STRING:
                continue

            # parse 0.v.30
            var parts = Array(k.split('.'))
            ck[int(parts.pop_front())] = {
                'orig': k,
                'code': PoolStringArray(parts).join('.')
            }

    var cc = 0
    var data = []
    for i in range(v.size()):
        var x = v[i]
        if ck.has(i):
            # process child
            var section = ck[i]
            var slices = getSlices(x, decode(section.code), child[section.orig])
            if slices.size():
                data.append_array(slices)
        else:
            data.append(x)
            cc += 1

    return data

"""
Decode 0.v.20.50
@param x slice definition
@return Dictionary {slices}
"""
static func decode(x: String) -> Dictionary:
    var o = Array(x.split('.'))
    var d = o.pop_front()
    var data = o
    var re = RegEx.new()
    re.compile('([vh])(\\d+)')
    var result = re.search(d)
    var dir = d
    if result:
        dir = result.get_string(1)
        data = slices(int(result.get_string(2)))

    return {
        'dir': dir,
        'slices': data
    }

"""
Get stops
"""
static func slices(d: int) -> Array:
    var o = []
    var s = 100 / d

    for i in range(1, d):
         o.append(s * i)

    return o

func pct(x, v) -> float:
    return x / 100 * int(v)

"""
Vertical split with stops
"""
func vSplit(r: Rect2, stops: Array) -> Array:
    var points = [r.position.x]
    for x in stops:
        points.append(r.position.x + pct(r.size.x, x))

    points.append(r.position.x + r.size.x)
    var segments = []
    var l = points.size()
    for i in range(0, points.size() - 1):
        var px = points[i]
        var pw = points[i+1] - px
        segments.append(Rect2(px, r.position.y, pw, r.size.y))

    return segments

"""
Horizontal split with stops
"""
func hSplit(r: Rect2, stops: Array) -> Array:
    var points = [r.position.y]
    for y in stops:
        points.append(r.position.y + pct(r.size.y, y))
    points.append(r.position.y + r.size.y)

    var segments = []
    var l = points.size()
    for i in range(0, points.size() - 1):
        var py = points[i]
        var ph = points[i+1] - py
        segments.append(Rect2(r.position.x, py, r.size.x, ph))

    return segments

func fromSvg(path: String) -> Array:
    var svg = SVG.new(path)

    return fitInstant(
        baseRect.size,
        Vector2(svg.w, svg.h),
        svg.rects
    )

func fromJson(raw:String) -> Array:
    var json = JSON.parse(raw)
    if !json || json.error != OK:
        return []

    return getSegments(json.result)

"""
TODO safe
"""
func parseJson(raw: String):
    return JSON.parse(raw)

static func fit(target:Vector2, source:Vector2, segments = []):
    return remap(
        target,
        normalize(
            source,
            segments
        )
    )

"""
Generate array of rectangles
by applying source/segments on target
"""
static func fitInstant(target: Vector2, source: Vector2, segments = []):
    var data = []
    for s in segments:
        data.append(Rect2(
            target * s.position / source,
            target * s.size / source
        ))

    return data

"""
Generate array of rectangles
by multiplying target size with normalized source
"""
static func remap(target:Vector2, source: Array):
    var data = []
    for s in source:
        data.append(target * s)
    return data

"""
Generate array of normalized rectangles
inside source size
"""
static func normalize(source: Vector2, segments: Array = []):
    var data = []
    for s in segments:
        data.append(Rect2(
            s.position / source,
            s.size / source
        ))

    return data

"""
Default templates
"""
static func getTemplates():
  return [
    {
        'label': 'default',
        'data': {
        'h.55': {
            '0.v.30': 0,
            '1.v.70': 0
        }
        }
    },

    {
        'label': 'two rows progress',
        'data': {
        'h.45': {
            '0.v.10.26.52': 0,
            '1.v.45.75': 0
        }
        }
    },

    {
        'label': 'big picture',
        'data': {
        'v.70': {
            '1.h5': 0
        }
        }
    },

    {
        'label': 'three column mid',
        'data': {
        'v.25.80': {
            '0.h.45': 0,
            '1.h.30.80': {
            '0.v2': 0,
            '2.v3': 0,
            },
            '2.h.70': 0
        }
        }
    },

    {
        'label': 'three column mid big',
        'data': {
        'v.20.80': {
            '0.h2': 0,
            '2.h2': 0
        }
        }
    },

    {
        'label': 'three column right, off',
        'data': {
        'v.40': {
            '1.h.70': {
            '0.v.50': {
                '1.h.60': 0
            },
            '1.v.45': 0
            }
        }
        }
    },

    {
        'label': 'three column right strict',
        'data': {
        'v.40.70': {
            '1.h.70': 0,
            '2.h.45.70': 0
        }
        }
    },


    {
        'label': 'three column sub',
        'data': {
        'v.30.70': {
            '0.h.33': {'0.v.50':0},
            '1.h.50': 0,
            '2.h.60': {'1.v.70':0}
        }
        }
    },

    {
        'label': 'mill',
        'data': {
        'h.45': {
            '0.v.15.30.45': 0,
            '1.v.45.75': 0 # 40 slightly off
        }
        }
    },

    {
        'label': 'left top',
        'data': {
        'v.80': {
            '0.h.66': {
            '0.v.60': {
                '1.h2': {
                '0.v2': 0
                }
            },
            '1.v.35.70': 0
            },
            '1.h.40': 0,
        }
        }
    },

    {
        'label': 'grid',
        'data': {
        'h3': {
            '0.v4': 0,
            '1.v4': 0,
            '2.v4': 0
        }
        }
    },

    {
        'label': 'two rows cinema',
        'data': {
        'h.66': {
            '0.v.55.90': 0,
            '1.v.20.37.80': 0
        }
        }
    },

    {
        'label': 'two quads',
        'data': {
        'v.60': {
            '0.h.33': {'0.v3':0},
            '1.h.60': {'1.v.70':0}
        }
        }
    },

    {
        'label': '7even columns',
        'data': {'v7': 0}
    },

    {
        'label': '5ive rows',
        'data': {'h5': 0}
    },

    {
        'label': 'three rows cinema',
        'data': {
            'h.20.70': {
                '0.v5': 0,
                '1.v.30': 0,
                '2.v3': 0
            }
        }
    },

    {
        'label': 'multi',
        'data': {
            'h.10.90': {
                '0.v9': 0,
                '1.v.10.90': {
                    '0.h5': 0,
                    '2.h5': 0
                },
                '2.v8': 0
            }
        }
    }
  ]
