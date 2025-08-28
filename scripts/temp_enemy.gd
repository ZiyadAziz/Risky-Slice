extends CharacterBody2D

var health := 3

func _on_hurtbox_area_entered(area: Area2D) -> void:
	if area.is_in_group("Sword"):
		print("hit")
		health -= 1
		print(GameManager.p1_score)
		if health <= 0:
			print("dead")
			GameManager.p1_score += 1
			print(GameManager.p1_score)
			GameManager.reset_round()
			print(GameManager.p1_score)
		

func _on_parry_area_area_entered(area: Area2D) -> void:
	print("parried")
	
