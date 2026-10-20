@tool
extends EditorScript
## Генерирует процедурные материалы с шумами и градиентами.
## Запуск: File → Run (Ctrl+Shift+X) в редакторе.

const FOLDER := "res://resources/Materials/"

func _run() -> void:
	DirAccess.make_dir_recursive_absolute(FOLDER)

	_make_wood_grain()
	_make_wood_aged()
	_make_metal_brushed()
	_make_metal_rusty()
	_make_plastic_worn()
	_make_concrete()
	_make_screen_scanlines()
	_make_fabric()
	_make_lamp_frosted()
	_make_rubber()
	_make_tile()

	print("[Materials] Все сгенерированы в ", FOLDER)

# ============================================================
# Хелперы
# ============================================================

## Создать NoiseTexture2D из параметров FastNoiseLite.
func _noise_tex(
		freq: float,
		octaves: int = 3,
		seed: int = 0,
		noise_type: int = FastNoiseLite.TYPE_SIMPLEX,
		domain_warp: bool = false,
		warp_amp: float = 30.0
) -> NoiseTexture2D:
	var n := FastNoiseLite.new()
	n.noise_type = noise_type
	n.frequency = freq
	n.fractal_octaves = octaves
	n.seed = seed
	n.domain_warp_enabled = domain_warp
	if domain_warp:
		n.domain_warp_amplitude = warp_amp

	var t := NoiseTexture2D.new()
	t.noise = n
	t.width = 256
	t.height = 256
	t.seamless = true
	return t

## Создать NoiseTexture2D с цветовой картой (gradient).
## Позволяет окрашивать шум: тёмные участки одного цвета, светлые — другого.
func _noise_tex_colored(
		freq: float,
		octaves: int,
		seed: int,
		dark_color: Color,
		light_color: Color
) -> NoiseTexture2D:
	var n := FastNoiseLite.new()
	n.noise_type = FastNoiseLite.TYPE_SIMPLEX
	n.frequency = freq
	n.fractal_octaves = octaves
	n.seed = seed

	var grad := Gradient.new()
	grad.set_color(0, dark_color)
	grad.set_color(1, light_color)

	var t := NoiseTexture2D.new()
	t.noise = n
	t.color_ramp = grad
	t.width = 256
	t.height = 256
	t.seamless = true
	return t

## Создать GradientTexture2D с полосами (для скан-линий).
func _stripes_tex(
		stripe_count: int = 16,
		dark: Color = Color(0, 0, 0),
		light: Color = Color(1, 1, 1),
		vertical: bool = true
) -> GradientTexture2D:
	var grad := Gradient.new()
	# Три точки: 0, 0.5, 1. Середина — граница между полосами
	grad.offsets = PackedFloat32Array([0.0, 0.5, 1.0])
	grad.colors = PackedColorArray([dark, light, dark])

	var t := GradientTexture2D.new()
	t.gradient = grad
	t.fill = GradientTexture2D.FILL_LINEAR
	if vertical:
		t.fill_from = Vector2(0, 0)
		t.fill_to = Vector2(0, 1)
	else:
		t.fill_from = Vector2(0, 0)
		t.fill_to = Vector2(1, 0)
	# Тайлим горизонтально
	t.width = 8
	t.height = 64
	t.repeat = GradientTexture2D.REPEAT
	return t

## Радиальный градиент для центрального свечения.
func _radial_tex(center_color: Color, edge_color: Color) -> GradientTexture2D:
	var grad := Gradient.new()
	grad.set_color(0, center_color)
	grad.set_color(1, edge_color)

	var t := GradientTexture2D.new()
	t.gradient = grad
	t.fill = GradientTexture2D.FILL_RADIAL
	t.fill_from = Vector2(0.5, 0.5)
	t.fill_to = Vector2(1.0, 0.5)
	t.width = 128
	t.height = 128
	return t

func _save(mat: StandardMaterial3D, name: String) -> void:
	var path := FOLDER + name + ".tres"
	ResourceSaver.save(mat, path)
	print("  ✓ ", name)

# ============================================================
# ДЕРЕВО
# ============================================================

## Дерево с волокнами. Шум с domain warp, растянутый вдоль оси.
func _make_wood_grain() -> void:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.55, 0.36, 0.18)
	mat.metallic = 0.0
	mat.roughness = 0.78
	mat.uv1_triplanar = true

	# Волокна: низкая частота, 4 октавы, domain warp — искривляет линии
	mat.albedo_texture = _noise_tex(
		0.015,     # частота: меньше = крупнее рисунок
		4,         # octaves: детализация
		12345,
		FastNoiseLite.TYPE_SIMPLEX,
		true,      # domain warp
		40.0
	)
	# Мелкая зернистость для roughness
	mat.roughness_texture = _noise_tex(0.2, 2, 777)

	_save(mat, "wood_grain")

## Старое дерево с тёмными пятнами (гниль, потёртости).
func _make_wood_aged() -> void:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.4, 0.27, 0.14)
	mat.metallic = 0.0
	mat.roughness = 0.92
	mat.uv1_triplanar = true

	# Cellular-шум даёт «пятна» — как гниль или высохшие участки
	mat.albedo_texture = _noise_tex(
		0.05,
		3,
		42,
		FastNoiseLite.TYPE_CELLULAR
	)
	mat.roughness_texture = _noise_tex(0.3, 3, 91)

	_save(mat, "wood_aged")

# ============================================================
# МЕТАЛЛ
# ============================================================

## Шлифованный металл. Полосы вдоль одной оси (диффузное отражение).
func _make_metal_brushed() -> void:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.65, 0.65, 0.68)
	mat.metallic = 1.0
	mat.roughness = 0.35
	# Сильно растянутый UV вдоль X — полосы
	mat.uv1_scale = Vector3(1, 40, 1)

	mat.albedo_texture = _noise_tex(0.5, 1, 3)
	mat.roughness_texture = _noise_tex(0.6, 2, 55)

	_save(mat, "metal_brushed")

## Ржавый металл. Тёмные пятна ржавчины на сером металле.
func _make_metal_rusty() -> void:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.5, 0.42, 0.32)
	mat.metallic = 0.85
	mat.roughness = 0.75
	mat.uv1_triplanar = true

	# Цветной шум: тёмно-коричневый → светло-серый. Даёт «пятна» ржавчины.
	mat.albedo_texture = _noise_tex_colored(
		0.06,
		3,
		111,
		Color(0.25, 0.12, 0.05),   # тёмная ржавчина
		Color(0.75, 0.75, 0.75)    # чистый металл
	)
	mat.roughness_texture = _noise_tex(0.15, 3, 222)

	_save(mat, "metal_rusty")

# ============================================================
# ПЛАСТИК / РЕЗИНА
# ============================================================

## Потёртый пластик. Мелкие царапины и потёртости.
func _make_plastic_worn() -> void:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.55, 0.55, 0.58)
	mat.metallic = 0.0
	mat.roughness = 0.5
	mat.uv1_scale = Vector3(3, 3, 3)

	mat.albedo_texture = _noise_tex(0.4, 2, 99)
	mat.roughness_texture = _noise_tex(0.5, 2, 100)

	_save(mat, "plastic_worn")

## Резина. Тёмная, матовая, с мелким шумом.
func _make_rubber() -> void:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.08, 0.08, 0.08)
	mat.metallic = 0.0
	mat.roughness = 0.95
	mat.uv1_scale = Vector3(4, 4, 4)

	mat.roughness_texture = _noise_tex(0.8, 2, 5)

	_save(mat, "rubber")

# ============================================================
# СТРОИТЕЛЬНЫЕ
# ============================================================

## Бетон. Cellular-шум для «крупных песчинок».
func _make_concrete() -> void:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.45, 0.45, 0.42)
	mat.metallic = 0.0
	mat.roughness = 0.9
	mat.uv1_scale = Vector3(2, 2, 2)

	mat.albedo_texture = _noise_tex(
		0.1,
		3,
		17,
		FastNoiseLite.TYPE_CELLULAR
	)
	mat.roughness_texture = _noise_tex(0.3, 2, 19)

	_save(mat, "concrete")

## Плитка — правильная сетка швов. Делается через быстрый шум + UV-обрезку.
## Простая версия: мелкий шум, имитирующий микротрещины.
func _make_tile() -> void:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.75, 0.72, 0.68)
	mat.metallic = 0.1
	mat.roughness = 0.45
	mat.uv1_scale = Vector3(4, 4, 4)

	mat.albedo_texture = _noise_tex(0.3, 2, 13)
	mat.roughness_texture = _noise_tex(0.5, 3, 21)

	_save(mat, "tile")

# ============================================================
# ЭКРАН С СКАН-ЛИНИЯМИ
# ============================================================

## Экран с полосами. Чёрно-зелёный, эмиссия.
## Полосы идут горизонтально — как у старых ЭЛТ.
func _make_screen_scanlines() -> void:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.0, 1.0, 0.4)
	mat.emission_enabled = true
	mat.emission = Color(0.0, 1.0, 0.4)
	mat.emission_energy_multiplier = 2.0
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED

	# Полосы в UV: вертикальные «нити» вдоль Y, тайлятся по X
	mat.albedo_texture = _stripes_tex(16, Color(0.2, 0.2, 0.2), Color(1, 1, 1), true)
	mat.uv1_scale = Vector3(1, 30, 1)     # много повторов по вертикали

	_save(mat, "screen_scanlines")

# ============================================================
# ТКАНЬ
# ============================================================

## Ткань — переплетение нитей. Делается через комбинацию двух шумов.
func _make_fabric() -> void:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.45, 0.2, 0.25)
	mat.metallic = 0.0
	mat.roughness = 0.95
	mat.uv1_scale = Vector3(20, 20, 1)   # сильно тайлим — эффект «нитей»

	mat.albedo_texture = _noise_tex(0.9, 2, 8)
	mat.roughness_texture = _noise_tex(0.9, 2, 9)

	_save(mat, "fabric")

# ============================================================
# МАТОВОЕ СТЕКЛО ЛАМПЫ
# ============================================================

## Матовое стекло. Радиальный градиент — центр ярче, к краям темнее.
## Эмиссия даёт эффект «горящей лампы».
func _make_lamp_frosted() -> void:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(1.0, 1.0, 1.0)
	mat.emission_enabled = true
	mat.emission = Color(0.4, 1.0, 0.6)
	mat.emission_energy_multiplier = 3.0
	mat.roughness = 0.9
	mat.metallic = 0.0
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED

	# Радиальный градиент — центральная точка светится
	mat.albedo_texture = _radial_tex(Color(1, 1, 1), Color(0.3, 0.5, 0.4))

	_save(mat, "lamp_frosted")
