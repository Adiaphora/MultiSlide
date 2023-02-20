extends HBoxContainer

func _ready() -> void:
  $btnDrag.connect('mouse_entered', self, 'hilight', [$btnDrag])
  $btnDrag.connect('mouse_exited', self, 'lolight', [$btnDrag])
  $btnMax.connect('mouse_entered', self, 'hilight', [$btnMax])
  $btnMax.connect('mouse_exited', self, 'lolight', [$btnMax])
  $btnFit.connect('mouse_entered', self, 'hilight', [$btnFit])
  $btnFit.connect('mouse_exited', self, 'lolight', [$btnFit])
  #$btnDrag.connect('mouse_entered', self, 'hilight', [$btnDrag])

func hilight(node):
  node.modulate = Color(1,1,1,1)

func lolight(node):
  node.modulate = Color(1,1,1,.75)
