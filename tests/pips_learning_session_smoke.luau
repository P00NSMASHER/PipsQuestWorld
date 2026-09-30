local Engine = require('../game/src/serverStorage/PipsEducationEngine')
local Bank = require('../game/src/serverStorage/PipsReleaseQuestionBank')
local LearningSession = require('../game/src/serverStorage/PipsLearningSession')

local Deterministic = {}
Deterministic.__index = Deterministic
function Deterministic.new()
	return setmetatable({}, Deterministic)
end
function Deterministic:NextInteger(minimum, _maximum)
	return minimum
end

local now = 100
local serial = 0
local manager = LearningSession.new(Engine, Bank, {
	timeoutSeconds = 30,
	clock = function()
		return now
	end,
	idFactory = function(_playerKey, _runId, _serial)
		serial += 1
		return 'session-' .. serial
	end,
})
local rng = Deterministic.new()

local function serverQuestionById(id)
	for _, question in ipairs(Bank) do
		if question.id == id then
			return question
		end
	end
	error('question not found: ' .. tostring(id))
end

local function wrongIndex(question)
	return question.correctIndex == 1 and 2 or 1
end

local first, err = manager:begin('player-a', 'run-1', rng)
assert(first and err == nil)
assert(first.sessionId == 'session-1')
assert(first.question.correctIndex == nil, 'client payload leaked correctIndex')
assert(first.question.questionNumber == 1 and first.question.questionTotal == 1)
assert(manager:hasActive('player-a'))
assert(manager:activeCount() == 1)

local duplicate, duplicateErr = manager:begin('player-a', 'run-1', rng)
assert(duplicate == nil and duplicateErr == 'session-active')

local invalid, invalidErr = manager:submit('player-a', 'run-1', first.sessionId, 99)
assert(invalid == nil and invalidErr == 'invalid-selection')
assert(manager:hasActive('player-a'))

local firstServer = serverQuestionById(first.question.id)
local wrong = wrongIndex(firstServer)

local miss1 = assert(manager:submit('player-a', 'run-1', first.sessionId, wrong))
assert(miss1.status == 'active' and miss1.feedbackKind == 'clue' and miss1.misses == 1)
local miss2 = assert(manager:submit('player-a', 'run-1', first.sessionId, wrong))
assert(miss2.status == 'active' and miss2.feedbackKind == 'support' and miss2.misses == 2)
local miss3 = assert(manager:submit('player-a', 'run-1', first.sessionId, wrong))
assert(miss3.status == 'resolved' and miss3.modeled == true)
assert(miss3.evidence.points == 0 and miss3.evidence.independent == false)
assert(not manager:hasActive('player-a'))

local reused, reusedErr = manager:begin('player-a', 'run-1', rng)
assert(reused == nil and reusedErr == 'run-already-used')

local second = assert(manager:begin('player-a', 'run-2', rng))
local secondServer = serverQuestionById(second.question.id)
local solved = assert(manager:submit(
	'player-a',
	'run-2',
	second.sessionId,
	secondServer.correctIndex
))
assert(solved.status == 'resolved' and solved.correct == true)
assert(solved.evidence.points == 25 and solved.evidence.independent == true)

local third = assert(manager:begin('player-a', 'run-3', rng))
local thirdServer = serverQuestionById(third.question.id)
local thirdWrong = wrongIndex(thirdServer)
local correction = assert(manager:submit('player-a', 'run-3', third.sessionId, thirdWrong))
assert(correction.status == 'active')
local corrected = assert(manager:submit(
	'player-a',
	'run-3',
	third.sessionId,
	thirdServer.correctIndex
))
assert(corrected.status == 'resolved')
assert(corrected.evidence.points == 20 and corrected.evidence.independent == false)

local expiring = assert(manager:begin('player-a', 'run-4', rng))
now += 31
local expired = assert(manager:submit('player-a', 'run-4', expiring.sessionId, 1))
assert(expired.status == 'cancelled' and expired.reason == 'expired')
assert(not manager:hasActive('player-a'))

now += 1
local cancellable = assert(manager:begin('player-a', 'run-5', rng))
local cancelled, cancelPayload = manager:cancel('player-a', 'character-reset')
assert(cancelled and cancelPayload.sessionId == cancellable.sessionId)
local retryCancelledRun, retryErr = manager:begin('player-a', 'run-5', rng)
assert(retryCancelledRun == nil and retryErr == 'run-already-used')

local b = assert(manager:begin('player-b', 'run-shared', rng))
local c = assert(manager:begin('player-c', 'run-shared', rng))
assert(b and c and manager:activeCount() == 2)
assert(manager:cancelRun('run-shared') == 2)
assert(manager:activeCount() == 0)
assert(manager:closeRun('run-shared') == 0)
assert(manager:begin('player-b', 'run-shared', rng), 'closed run should release run-local use marker')

local leaving = assert(manager:begin('player-z', 'run-leave', rng))
assert(leaving and manager:removePlayer('player-z') == true)
assert(not manager:hasActive('player-z'))
local rejoinSameRun, rejoinErr = manager:begin('player-z', 'run-leave', rng)
assert(rejoinSameRun == nil and rejoinErr == 'run-already-used')

print('PIPS_LEARNING_SESSION_SMOKE_PASS')
