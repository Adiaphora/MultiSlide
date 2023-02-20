extends Object

var file_path = ''
var xml = XMLParser.new()
var rects = []
var w = 0
var h = 0

func _init(path) -> void:
    file_path = path
    if xml.open(file_path) != OK:
        print("Error opening file: ", file_path)
        return

    parse(xml)
    print('%dx%d %d rects' % [w,h,rects.size()])

"""
Loop through all nodes and create the respective element.
"""
func parse(xml: XMLParser) -> void:
    while xml.read() == OK:
        if not xml.get_node_type() in [XMLParser.NODE_ELEMENT, XMLParser.NODE_ELEMENT_END]:
            continue
        match xml.get_node_name():
            "svg":
                if ! xml.has_attribute("width"):
                    # end tag
                    break
                w = int(xml.get_named_attribute_value("width"))
                h = int(xml.get_named_attribute_value("height"))
            "rect":
                var rect = readRectangle(xml)
                rects.append(rect)

        """
        elif xml.get_node_name() == "g":
            if xml.get_node_type() == XMLParser.NODE_ELEMENT:
                process_group(xml_data)
            elif xml.get_node_type() == XMLParser.NODE_ELEMENT_END:
                current_node = current_node.get_parent()
        """

func readRectangle(node:XMLParser) -> Rect2:
    var x = int(node.get_named_attribute_value("x"))
    var y = int(node.get_named_attribute_value("y"))
    var width = int(node.get_named_attribute_value("width"))
    var height = int(node.get_named_attribute_value("height"))
    return Rect2(Vector2(x, y), Vector2(width, height))
