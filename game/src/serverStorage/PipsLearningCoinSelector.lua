local CoinSelector = {}

local function isNonEmptyString(value)
	return type(value) == 'string' and value:match('%S') ~= nil
end

local function normalizeId(value)
	if value == nil then
		return nil
	end
	local result = tostring(value)
	if result == '' then
		return nil
	end
	return result
end

local function stableHash(text)
	local hash = 2166136261
	for index = 1, #text do
		hash = bit32.bxor(hash, string.byte(text, index))
		hash = (hash * 16777619) % 4294967296
	end
	return hash
end

local function normalizedCandidate(candidate)
	if type(candidate) ~= 'table' then
		return nil
	end
	if candidate.onePerPlayer == true then
		return nil
	end
	if candidate.eligible == false then
		return nil
	end

	local key = normalizeId(candidate.key)
	local itemId = normalizeId(candidate.itemId)
	if not key or not itemId then
		return nil
	end

	return {
		key = key,
		itemId = itemId,
		sourceIndex = candidate.sourceIndex,
	}
end

function CoinSelector.eligible(candidates)
	local result = {}
	for _, candidate in ipairs(candidates or {}) do
		local normalized = normalizedCandidate(candidate)
		if normalized then
			table.insert(result, normalized)
		end
	end

	table.sort(result, function(left, right)
		if left.key == right.key then
			return left.itemId < right.itemId
		end
		return left.key < right.key
	end)
	return result
end

function CoinSelector.select(runId, candidates)
	assert(isNonEmptyString(runId), 'runId is required')

	local eligible = CoinSelector.eligible(candidates)
	if #eligible == 0 then
		return nil, 'no-eligible-coins'
	end

	local index = (stableHash(runId) % #eligible) + 1
	local selected = eligible[index]
	return {
		key = selected.key,
		itemId = selected.itemId,
		index = index,
		eligibleCount = #eligible,
	}, nil
end

return CoinSelector
