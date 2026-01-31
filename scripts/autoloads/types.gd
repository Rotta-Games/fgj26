extends Node

enum Side
{
	LEFT,
	RIGHT
}

enum PlayerId {
	PLAYER_1 = 1,
	PLAYER_2 = 2
}

enum EnemyState {IDLE = 1, DISABLED, SEEK, ATTACK, STUNNED, WAIT_FOR_ATTACK, JUMP, FLY, DEAD}

enum PlayerState {
	IDLE,
	WALKING,
	ATTACKING,
	STUNNED,
	DEAD,
}
