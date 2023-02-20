extends Object

"""
Image model
"""

# full path
var path: String = ''
# physical size
var size = 0
# dimensions
var dim: Vector2
# texture object
var texture: ImageTexture = null

func isVertical():
    return  dim.x < dim.y
