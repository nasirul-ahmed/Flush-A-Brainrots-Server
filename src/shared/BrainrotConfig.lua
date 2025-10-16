-- Shared constants for all brainrot systems
return {
	SPAWN_THRESHOLD = 20,
	SPAWN_INTERVAL = 10,
	-- Input Keys
	PICKUP_KEY = Enum.KeyCode.F,
	THROW_KEY = Enum.KeyCode.Q,

	-- Carrying Configuration
	ARM_RAISE_DEGREES = 110,
	HAND_HEIGHT_R6 = 2.0,
	HAND_HEIGHT_R15 = 5.0,
	CARRY_FORWARD_OFFSET = -2.5,

	-- Throwing Configuration
	MAX_THROW_POWER = 100,
	MIN_THROW_POWER = 20,
	CHARGE_TIME = 3,
	THROW_ANGLE = 30,

	-- Trajectory Visualization
	TRAJECTORY_TIMESTEP = 0.15,
	TRAJECTORY_MAX_TIME = 5,
	TRAJECTORY_UPDATE_RATE = 0.1,

	-- Landing Configuration
	GROUND_LEVEL = -0.6,
	LANDING_STILL_TIME = 1.0,
	LANDING_MOVEMENT_THRESHOLD = 0.1,

	-- Wormhole Configuration
	WORMHOLE_ANIMATION_DURATION = 5,
	WORMHOLE_FADE_DURATION = 1.5,
	WORMHOLE_BASE_COLOR = Color3.new(0, 0.8, 1),

	-- Remote Event Names
	REMOTE_FOLDER_NAME = "BrainrotEvents",
	THROW_START_EVENT = "ThrowStart",
	THROW_RELEASE_EVENT = "ThrowRelease",
	TRAJECTORY_UPDATE_EVENT = "TrajectoryUpdate",

	-- Workspace Names
	ACTIVE_BRAINROTS_FOLDER = "ActiveBrainrots",
}
