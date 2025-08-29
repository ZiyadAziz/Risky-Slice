extends CharacterBody2D

var health := 5.0
var isBlocking := false

func _physics_process(delta: float) -> void:
	if health <= 0.0:
			print("enemy dead")
			GameManager.p1_score += 1
			GameManager.reset_round()

func _on_hurtbox_area_entered(area: Area2D) -> void:
	if area.is_in_group("PlayerSword"):
		if isBlocking:
			health -= .25
		else:
			health -= 1.0
		

func _on_parry_area_area_entered(area: Area2D) -> void:
	if area.is_in_group("PlayerWindup"):
		print("player attack got parried")
	
func _on_windup_area_area_entered(area: Area2D) -> void:
	if area.is_in_group("PlayerParry"):
		print("enemy attack got parried")
		
