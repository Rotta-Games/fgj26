extends Node

signal playerHealthState(data: Dictionary)
signal playerScoreState(data: Dictionary)
signal playerStartChange(player: Types.PlayerId, is_in_game: bool)
signal gamePausedChange(is_paused:bool)
signal boss_killed
