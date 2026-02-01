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
enum BossState {IDLE = 1, RETURN_TO_THROWING, THROWING, SEEK, ATTACK, RAMPAGE, STUNNED, DEAD}

enum PlayerState {
	IDLE,
	WALKING,
	ATTACKING,
	STUNNED,
	DEAD,
}

enum PlayerMask {
	NONE,
	TIGER,
	FIRE,
}
