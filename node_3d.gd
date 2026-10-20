@tool
extends EditorScript

func _run() -> void:
	var folder := "res://resources/Materials/"
	DirAccess.make_dir_recursive_absolute(folder)

	# [имя_файла, словарь_свойств]
	var presets := [
		["wood",       {"albedo_color": Color(0.545, 0.353, 0.169), "roughness": 0.85}],
		["wood_light", {"albedo_color": Color(0.627, 0.416, 0.227), "roughness": 0.8}],
		["wood_dark",  {"albedo_color": Color(0.353, 0.227, 0.102), "roughness": 0.9}],
		["metal",      {"albedo_color": Color(0.4, 0.4, 0.42), "metallic": 1.0, "roughness": 0.25}],
		["metal_dark", {"albedo_color": Color(0.16, 0.16, 0.17), "metallic": 0.9, "roughness": 0.35}],
		["plastic_white", {"albedo_color": Color(0.85, 0.85, 0.85), "roughness": 0.4}],
		["plastic_dark",  {"albedo_color": Color(0.12, 0.12, 0.13), "roughness": 0.5}],

		["screen_on",  {"albedo_color": Color(0.04, 0.1, 0.04), "emission_enabled": true,
						"emission": Color(0, 1, 0.4), "emission_energy_multiplier": 2.5,
						"shading_mode": BaseMaterial3D.SHADING_MODE_UNSHADED}],
		["screen_off", {"albedo_color": Color(0.05, 0.05, 0.05), "roughness": 0.3,
						"shading_mode": BaseMaterial3D.SHADING_MODE_UNSHADED}],

		["lamp_green",  {"albedo_color": Color(0.05, 0.3, 0.05), "emission_enabled": true,
						 "emission": Color(0, 1, 0.2), "emission_energy_multiplier": 4.0}],
		["lamp_red",    {"albedo_color": Color(0.3, 0.05, 0.05), "emission_enabled": true,
						 "emission": Color(1, 0.1, 0.1), "emission_energy_multiplier": 4.0}],
		["lamp_yellow", {"albedo_color": Color(0.3, 0.25, 0.05), "emission_enabled": true,
						 "emission": Color(1, 0.9, 0.2), "emission_energy_multiplier": 4.0}],
		["lamp_off",    {"albedo_color": Color(0.15, 0.15, 0.15), "metallic": 0.5, "roughness": 0.4}],

		["btn_green",  {"albedo_color": Color(0, 1, 0), "emission_enabled": true, "emission": Color(0, 1, 0), "emission_energy_multiplier": 0.8, "roughness": 0.4}],
		["btn_red",    {"albedo_color": Color(1, 0.125, 0.125), "emission_enabled": true, "emission": Color(1, 0.125, 0.125), "emission_energy_multiplier": 0.8, "roughness": 0.4}],
		["btn_blue",   {"albedo_color": Color(0.125, 0.375, 1), "emission_enabled": true, "emission": Color(0.125, 0.375, 1), "emission_energy_multiplier": 0.8, "roughness": 0.4}],
		["btn_yellow", {"albedo_color": Color(1, 1, 0), "emission_enabled": true, "emission": Color(1, 1, 0), "emission_energy_multiplier": 0.8, "roughness": 0.4}],
		["btn_purple", {"albedo_color": Color(0.69, 0.25, 1), "emission_enabled": true, "emission": Color(0.69, 0.25, 1), "emission_energy_multiplier": 0.8, "roughness": 0.4}],
		["btn_orange", {"albedo_color": Color(1, 0.5, 0), "emission_enabled": true, "emission": Color(1, 0.5, 0), "emission_energy_multiplier": 0.8, "roughness": 0.4}],
	]

	for p in presets:
		var name: String = p[0]
		var props: Dictionary = p[1]
		var mat := StandardMaterial3D.new()
		for k in props:
			mat.set(k, props[k])
		var path := folder + name + ".tres"
		ResourceSaver.save(mat, path)
		print("Сохранено: ", path)
