local Selector = require('../game/src/serverStorage/PipsLearningCoinSelector')

local base = {
	{ key = 'coin-c', itemId = 9000008 },
	{ key = 'coin-a', itemId = 9000001 },
	{ key = 'coin-b', itemId = 9000005 },
	{ key = 'treasure', itemId = 9002008, onePerPlayer = true },
	{ key = 'unknown', itemId = 12345 },
	{ key = 'disabled', itemId = 9000001, normal = false },
}

assert(Selector.isEligible(base[1]))
assert(Selector.isEligible(base[2]))
assert(Selector.isEligible(base[3]))
assert(not Selector.isEligible(base[4]))
assert(not Selector.isEligible(base[5]))
assert(not Selector.isEligible(base[6]))

local eligible = Selector.eligibleCandidates(base)
assert(#eligible == 3)
assert(eligible[1].key == 'coin-a')
assert(eligible[2].key == 'coin-b')
assert(eligible[3].key == 'coin-c')

local first = assert(Selector.choose(base, 'room-4:run-17'))
local reordered = {
	base[6],
	base[4],
	base[3],
	base[1],
	base[5],
	base[2],
}
local second = assert(Selector.choose(reordered, 'room-4:run-17'))
assert(first.key == second.key, 'selection must be order-independent')

local repeatPick = assert(Selector.choose(base, 'room-4:run-17'))
assert(first.key == repeatPick.key, 'same run must select the same coin')

local otherRun = assert(Selector.choose(base, 'room-4:run-18'))
assert(otherRun ~= nil)

local originalItem = base[1].itemId
local originalFlag = base[1].onePerPlayer
Selector.choose(base, 'mutation-check')
assert(base[1].itemId == originalItem)
assert(base[1].onePerPlayer == originalFlag)

local none, noneErr = Selector.choose({
	{ key = 'treasure-only', itemId = 9002008, onePerPlayer = true },
	{ key = 'unknown-only', itemId = 9999999 },
}, 'run-empty')
assert(none == nil and noneErr == 'no-eligible-coins')

local invalidRun, invalidRunErr = Selector.choose(base, '')
assert(invalidRun == nil and invalidRunErr == 'invalid-run')

local duplicateOk, duplicateErr = pcall(function()
	Selector.eligibleCandidates({
		{ key = 'same', itemId = 9000001 },
		{ key = 'same', itemId = 9000008 },
	})
end)
assert(not duplicateOk)
assert(string.find(tostring(duplicateErr), 'duplicate candidate key', 1, true))

print('PIPS_LEARNING_COIN_SELECTOR_PASS', first.key, otherRun.key)
