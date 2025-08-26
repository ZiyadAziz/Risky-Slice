#This node is global, later on I think it should be able to handle things like choosing between singleplayer or 1v1, and choosing what difficulty bot you wanna go against 
extends Node

var p1_score := 0
var p2_score := 0
var rounds_played := 0

func reset_round():
	print("Resetting round...")
	get_tree().change_scene_to_file("res://scenes/game.tscn")
