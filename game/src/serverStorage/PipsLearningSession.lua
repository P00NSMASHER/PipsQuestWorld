local LearningSession = {}
LearningSession.__index = LearningSession

LearningSession.DEFAULT_TIMEOUT_SECONDS = 30

local function normalizeKey(value)
	if value == nil then
		return nil
	end
	local key = tostring(value)
	if key == '' then
		return nil
	end
	return key
end

local function isInteger(value)
	return type(value) == 'number' and value % 1 == 0
end

local function defaultClock()
	return os.clock()
end

local function defaultIdFactory(playerKey, runId, serial)
	return ('pips:%s:%s:%d'):format(runId, playerKey, serial)
end

local function countKeys(map)
	local count = 0
	for _ in pairs(map) do
		count += 1
	end
	return count
end

function LearningSession.new(engine, bank, options)
	options = options or {}
	assert(type(engine) == 'table', 'education engine is required')
	local ok, err = engine.validateBank(bank)
	assert(ok, err)

	local timeoutSeconds = tonumber(options.timeoutSeconds)
		or LearningSession.DEFAULT_TIMEOUT_SECONDS
	assert(timeoutSeconds > 0, 'timeoutSeconds must be positive')

	local self = setmetatable({}, LearningSession)
	self.engine = engine
	self.bank = bank
	self.clock = options.clock or defaultClock
	self.idFactory = options.idFactory or defaultIdFactory
	self.timeoutSeconds = timeoutSeconds
	self.histories = {}
	self.active = {}
	self.usedRuns = {}
	self.serial = 0
	return self
end

function LearningSession:_history(playerKey)
	local history = self.histories[playerKey]
	if not history then
		history = self.engine.newHistory()
		self.histories[playerKey] = history
	end
	return history
end

function LearningSession:_markRunUsed(playerKey, runId)
	local runs = self.usedRuns[playerKey]
	if not runs then
		runs = {}
		self.usedRuns[playerKey] = runs
	end
	runs[runId] = true
end

function LearningSession:_wasRunUsed(playerKey, runId)
	local runs = self.usedRuns[playerKey]
	return runs ~= nil and runs[runId] == true
end

function LearningSession:_evidence(session, modeled)
	local misses = session.misses
	local independent = not modeled and self.engine.isIndependent(misses)
	return {
		questionId = session.question.id,
		skill = session.question.skill,
		runId = session.runId,
		attempts = modeled and misses or misses + 1,
		independent = independent,
		supported = not independent,
		modeled = modeled == true,
		points = self.engine.scoreResolution(misses, modeled == true),
		resolvedAt = self.clock(),
	}
end

function LearningSession:begin(playerKeyValue, runIdValue, rng)
	local playerKey = normalizeKey(playerKeyValue)
	local runId = normalizeKey(runIdValue)
	if not playerKey then
		return nil, 'invalid-player'
	end
	if not runId then
		return nil, 'invalid-run'
	end
	if self.active[playerKey] then
		return nil, 'session-active'
	end
	if self:_wasRunUsed(playerKey, runId) then
		return nil, 'run-already-used'
	end

	local history = self:_history(playerKey)
	self.engine.beginQuest(history)
	local question = self.engine.pickNextQuestion(self.bank, history, rng)
	self.engine.markShown(history, question)

	self.serial += 1
	local sessionId = tostring(self.idFactory(playerKey, runId, self.serial))
	assert(sessionId ~= '', 'idFactory returned an empty session id')

	local now = self.clock()
	local session = {
		id = sessionId,
		playerKey = playerKey,
		runId = runId,
		question = question,
		history = history,
		misses = 0,
		startedAt = now,
		expiresAt = now + self.timeoutSeconds,
	}
	self.active[playerKey] = session
	self:_markRunUsed(playerKey, runId)

	local view = self.engine.clientView(question, 1)
	view.questionNumber = 1
	view.questionTotal = 1

	return {
		sessionId = sessionId,
		question = view,
		expiresAt = session.expiresAt,
	}, nil
end

function LearningSession:submit(playerKeyValue, runIdValue, sessionIdValue, selection)
	local playerKey = normalizeKey(playerKeyValue)
	local runId = normalizeKey(runIdValue)
	local sessionId = normalizeKey(sessionIdValue)
	if not playerKey then
		return nil, 'invalid-player'
	end
	if not runId then
		return nil, 'invalid-run'
	end
	if not sessionId then
		return nil, 'invalid-session'
	end

	local session = self.active[playerKey]
	if not session then
		return nil, 'no-active-session'
	end
	if session.id ~= sessionId then
		return nil, 'session-mismatch'
	end
	if session.runId ~= runId then
		return nil, 'run-mismatch'
	end

	if self.clock() >= session.expiresAt then
		self.active[playerKey] = nil
		return {
			status = 'cancelled',
			reason = 'expired',
			sessionId = session.id,
			runId = session.runId,
		}, nil
	end

	local optionIndex = tonumber(selection)
	if not isInteger(optionIndex)
		or optionIndex < 1
		or optionIndex > #session.question.options then
		return nil, 'invalid-selection'
	end

	if self.engine.isCorrect(session.question, optionIndex) then
		self.engine.markResolved(session.history)
		local evidence = self:_evidence(session, false)
		self.active[playerKey] = nil
		return {
			status = 'resolved',
			correct = true,
			modeled = false,
			evidence = evidence,
		}, nil
	end

	session.misses += 1
	local feedback, feedbackKind =
		self.engine.getWrongFeedback(session.question, optionIndex, session.misses)

	if feedbackKind == 'model' or session.misses >= 3 then
		self.engine.markResolved(session.history)
		self.engine.queueComeback(session.history, session.question, 1)
		local evidence = self:_evidence(session, true)
		self.active[playerKey] = nil
		return {
			status = 'resolved',
			correct = false,
			modeled = true,
			feedback = feedback,
			feedbackKind = feedbackKind,
			evidence = evidence,
		}, nil
	end

	return {
		status = 'active',
		correct = false,
		modeled = false,
		feedback = feedback,
		feedbackKind = feedbackKind,
		misses = session.misses,
	}, nil
end

function LearningSession:cancel(playerKeyValue, reason)
	local playerKey = normalizeKey(playerKeyValue)
	if not playerKey then
		return false
	end
	local session = self.active[playerKey]
	if not session then
		return false
	end
	self.active[playerKey] = nil
	return true, {
		status = 'cancelled',
		reason = reason or 'cancelled',
		sessionId = session.id,
		runId = session.runId,
	}
end

function LearningSession:cancelRun(runIdValue, reason)
	local runId = normalizeKey(runIdValue)
	if not runId then
		return 0
	end
	local cancelled = 0
	for playerKey, session in pairs(self.active) do
		if session.runId == runId then
			self.active[playerKey] = nil
			cancelled += 1
		end
	end
	return cancelled, reason or 'run-cancelled'
end

function LearningSession:closeRun(runIdValue)
	local runId = normalizeKey(runIdValue)
	if not runId then
		return 0
	end
	local cancelled = self:cancelRun(runId, 'run-closed')
	for playerKey, runs in pairs(self.usedRuns) do
		runs[runId] = nil
		if next(runs) == nil then
			self.usedRuns[playerKey] = nil
		end
	end
	return cancelled
end

function LearningSession:expire()
	local now = self.clock()
	local expired = 0
	for playerKey, session in pairs(self.active) do
		if now >= session.expiresAt then
			self.active[playerKey] = nil
			expired += 1
		end
	end
	return expired
end

function LearningSession:removePlayer(playerKeyValue)
	local playerKey = normalizeKey(playerKeyValue)
	if not playerKey then
		return false
	end
	local hadActive = self.active[playerKey] ~= nil
	self.active[playerKey] = nil
	self.histories[playerKey] = nil
	return hadActive
end

function LearningSession:hasActive(playerKeyValue)
	local playerKey = normalizeKey(playerKeyValue)
	return playerKey ~= nil and self.active[playerKey] ~= nil
end

function LearningSession:activeCount()
	return countKeys(self.active)
end

return LearningSession
