local Selector = {}

Selector.NORMAL_ITEM_IDS = {
	['9000001'] = true,
	['9000005'] = true,
	['9000008'] = true,
}

local function normalize(value)
	if value == nil then
		return nil
	end
	local text = tostring(value)
	if text == '' then
		return nil
	end
	return text
end

local function hashText(text)
	local hash = 2166136261
	for index = 1, #text do
		hash = bit32.bxor(hash, string.byte(text, index))
		hash = (hash * 16777619) % 4294967296
	end
	return hash
end

local function eligible(candidate)
	if type(candidate) ~= 'table' then
		return false
	end
	local key = normalize(candidate.key)
	local itemId = normalize(candidate.itemId)
	if not key or not itemId then
		return false
	end
	if candidate.onePerPlayer == true then
		return false
	end
	if candidate.normal == false then
		return false
	end
	return Selector.NORMAL_ITEM_IDS[itemId] == true
end

function Selector.eligibleCandidates(candidates)
	assert(type(candidates) == 'table', 'candidates must be a table')

	local result = {}
	local keys = {}
	for _, candidate in ipairs(candidates) do
		if eligible(candidate) then
			local key = normalize(candidate.key)
			if keys[key] then
				error('duplicate candidate key: ' .. key)
			end
			keys[key] = true
			table.insert(result, candidate)
		end
	end

	table.sort(result, function(left, right)
		return tostring(left.key) < tostring(right.key)
	end)
	return result
end

function Selector.choose(candidates, runIdValue)
	local runId = normalize(runIdValue)
	if not runId then
		return nil, 'invalid-run'
	end

	local pool = Selector.eligibleCandidates(candidates)
	if #pool == 0 then
		return nil, 'no-eligible-coins'
	end

	local index = (hashText(runId) % #pool) + 1
	return pool[index], nil
end

function Selector.isEligible(candidate)
	return eligible(candidate)
end

return Selector
