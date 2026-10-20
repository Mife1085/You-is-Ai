extends Cube

var value: int = 0

var _venn_quad: MeshInstance3D
var _venn_mat: StandardMaterial3D

func _ready() -> void:
	super._ready()
	type = "LOGIC"
	look_me = true

	_venn_quad = $Venn
	_venn_mat = $Venn.mesh.material 
	_venn_mat.albedo_texture = _make_venn_texture(value)
	_venn_quad.mesh.material = _venn_mat

## Смена значения по кругу.
func interact_alt() -> void:
	value = (value + 1) % 4
	_apply_venn()

func _apply_venn() -> void:
	_venn_mat.albedo_texture = _make_venn_texture(value)

# ============================================================
# Рисуем диаграмму Венна в Image и заворачиваем в ImageTexture.
# ============================================================
func _make_venn_texture(mode: int) -> ImageTexture:
	const S := 128
	var img := Image.create(S, S, false, Image.FORMAT_RGBA8)
	img.fill(Color.TRANSPARENT)   # тёмно-зелёная доска

	var c1 := Vector2(S * 0.35, S * 0.5)
	var c2 := Vector2(S * 0.65, S * 0.5)
	var r := S * 0.3

	# --- 1. Штриховка ---
	for y in S:
		for x in S:
			var p := Vector2(x, y)
			var in1 := p.distance_to(c1) < r
			var in2 := p.distance_to(c2) < r
			var paint := false

			match mode:
				0:  # AND — только пересечение, крест
					if in1 and in2:
						if _hatch(x, y):
							paint = true
				1:  # OR — всё объединение, один штрих
					if in1 or in2:
						if _hatch(x, y):
							paint = true
				2:  # XOR — разный штрих слева и справа, пересечение пусто
					if in1 and not in2:
						if _hatch(x, y): paint = true
					elif in2 and not in1:
						if _hatch(x, y): paint = true
				3:  # NOT — только левый круг
					if in2:
						if _hatch(x, y): paint = true

			if not paint:
				continue

			img.set_pixel(x, y, Color.WHITE)

	# --- 2. Обводка кругов (сплошная, как «основная линия мела») ---
	for y in S:
		for x in S:
			var p := Vector2(x, y)
			var e1: float = abs(p.distance_to(c1) - r)
			var e2: float = abs(p.distance_to(c2) - r)
			if e1 < 3 or e2 < 3:
				img.set_pixel(x, y, Color.WHITE)

	return ImageTexture.create_from_image(img)
	

static func _hatch(px: int, py: int) -> bool:
	return posmod(px + py, 8) < 6

func get_value():
	return ["AND","OR","XOR","IMP"][value]
