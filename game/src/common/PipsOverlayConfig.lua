return {
	mode = 'shadow',

	-- Foundation rule: these remain false until an unchanged Maze World
	-- playthrough has been re-certified on the target device.
	blockFinish = false,
	replaceMazeUI = false,
	replaceMazeRewards = false,
	replaceMazeGeneration = false,

	-- Learning can be observed and prepared in shadow mode without changing
	-- movement, maze generation, original finish handling, or rewards.
	questionsEnabled = false,
	questionCount = 5,
}
