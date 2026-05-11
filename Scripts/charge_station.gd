extends Node3D

signal fully_charged

@export
var Bar : Node3D
@export
var NotBar : Node3D
@export
var ChargeBar : Node3D
@export
var Gyro : Node3D
@export
var ChargeZone : MeshInstance3D
@export
var ChargingMat : StandardMaterial3D
@export
var NotChargingMat : StandardMaterial3D
var charging : bool = false
var charge_mid_level : float = 0
var charge_level : int = 0
var gyro_speed :float = 7

func _ready() -> void:
	Bar.scale.y = 0
	NotBar.scale.y = 5
	ChargeBar.scale.y = 0

func _process(delta: float) -> void:
	ChargeBar.scale.y = clampf(charge_mid_level, 0, 1)
	NotBar.scale.y = (5 - charge_level) - clampf(charge_mid_level, 0, 1)
	if charging and charge_level < 5:
		charge_mid_level += delta * 2
		if charge_mid_level > 1 :
			charge_level += 1
			Bar.scale.y = charge_level
			NotBar.scale.y = 5 - charge_level
			ChargeBar.scale.y = 0
			ChargeBar.position.y = charge_level / 2.0 - 0.05
			charge_mid_level = 0
			if charge_level == 5 :
				fully_charged.emit()
				(Gyro.get_child(0) as SpotLight3D).light_color = Color(0, 1, 0)
				(Gyro.get_child(1) as SpotLight3D).light_color = Color(0, 1, 0)
				gyro_speed = 2.5
	Gyro.rotate_y(gyro_speed * delta)


func _on_area_3d_body_entered(_body: Node3D) -> void:
	charging = true
	ChargeZone.material_override = ChargingMat


func _on_area_3d_body_exited(_body: Node3D) -> void:
	charging = false
	charge_mid_level = 0
	ChargeZone.material_override = NotChargingMat
