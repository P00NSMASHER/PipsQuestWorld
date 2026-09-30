-- Release pool for the first Maze World learning seam.
-- The full PipsQuestionBank is retained as a QA/archive source, but is not
-- eligible for gameplay until duplicate/metadata/content issues are repaired.

local archive = require(script.Parent.PipsQuestionBank)
local release = {}

for _, question in ipairs(archive) do
	if question.photoDerived == true then
		table.insert(release, question)
	end
end

return release
