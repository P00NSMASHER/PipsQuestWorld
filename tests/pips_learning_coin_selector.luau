local Selector = require('../game/src/serverStorage/PipsLearningCoinSelector')

local candidates = {
	{ key = 'maze/Coin-C', itemId = 9000008 },
	{ key = 'maze/Treasure', itemId = 9002008, onePerPlayer = true },
	{ key = 'maze/Coin-A', itemId = 9000001 },
	{ key = 'maze/Disabled', itemId = 9000005, eligible = false },
	{ key = 'maze/Coin-B', itemId = '9000005' },
}

local eligible = Selector.eligible(candidates)
assert(#eligible == 3)
assert(eligible[1].key == 'maze/Coin-A')
assert(eligible[2].key == 'maze/Coin-B')
assert(eligible[3].key == 'maze/Coin-C')

local first, firstErr = Selector.select('room-7:run-42', candidates)
assert(first and firstErr == nil)
assert(first.eligibleCount == 3)
assert(first.itemId == '9000001' or first.itemId == '9000005' or first.itemId == '9000008')

local reordered = {
	candidates[5],
	candidates[2],
	candidates[3],
	candidates[1],
	candidates[4],
}
local second = assert(Selector.select('room-7:run-42', reordered))
assert(second.key == first.key, 'selection must not depend on enumeration order')
assert(second.itemId == first.itemId)

local repeatSelection = assert(Selector.select('room-7:run-42', candidates))
assert(repeatSelection.key == first.key, 'selection must be deterministic for a run')

local otherRun = assert(Selector.select('room-7:run-43', candidates))
assert(otherRun.eligibleCount == 3)

local none, noneErr = Selector.select('run-empty', {
	{ key = 'treasure', itemId = 9002008, onePerPlayer = true },
	{ key = 'disabled', itemId = 9000001, eligible = false },
})
assert(none == nil and noneErr == 'no-eligible-coins')

local ok = pcall(function()
	Selector.select('', candidates)
end)
assert(not ok, 'empty run id must fail closed')

print('PIPS_LEARNING_COIN_SELECTOR_PASS')
