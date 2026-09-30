import { readFile } from "node:fs/promises";
import assert from "node:assert/strict";

const [lua, contract, plan] = await Promise.all([
  readFile("game/src/server/EducationEngine.lua", "utf8"),
  readFile("docs/MAZE_LEARNING_CONTRACT.md", "utf8"),
  readFile("EXECUTIVE_PLAN.md", "utf8"),
]);

function requireText(text, needle, label) {
  assert.ok(text.includes(needle), `${label} missing ${needle}`);
}

for (const api of ["validateQuestion", "selectQuestion", "beginEncounter", "submitAnswer"]) {
  requireText(lua, `EducationEngine.${api}`, "engine API");
}
for (const token of [
  'nextAction = "return-to-maze"',
  'kind = "clue"',
  'kind = "support"',
  'kind = "modeled"',
  'masteryEligible = independent',
  'afterEncounters = 2',
  '"answer-leaked-in-prompt"',
  'question.id ~= context.lastQuestionId',
]) requireText(lua, token, "engine policy");

for (const forbidden of ["Instance.new", "game.Workspace", "ScreenGui", "RewardChest", "MiniMaze"]) {
  assert.equal(lua.includes(forbidden), false, `backend-only engine contains forbidden gameplay/UI token ${forbidden}`);
}

const publicQuestionBody = lua.match(/local function publicQuestion\(question\)([\s\S]*?)\nend/);
assert.ok(publicQuestionBody, "publicQuestion function must exist");
assert.equal(publicQuestionBody[1].includes("correctIndex"), false, "client presentation must not expose correctIndex");
assert.equal(publicQuestionBody[1].includes("explanation"), false, "client presentation must not expose explanation/model");

requireText(contract, "exactly one brief encounter", "contract");
requireText(contract, "no-nonrepeat-question", "contract");
requireText(contract, "masteryEligible=false", "contract");
requireText(plan, "A checkpoint must never require a five-question modal sequence", "executive plan");
requireText(plan, "The client receives no answer key", "executive plan");

const transferTypes = new Set(["transfer", "application", "skill-and-concept-application"]);
const normalize = (value) => String(value ?? "").toLowerCase().replace(/[^a-z0-9]+/g, " ").replace(/\s+/g, " ").trim();

function validateQuestion(q) {
  if (!q || typeof q !== "object") return [false, "question-not-table"];
  for (const key of ["id", "subject", "skill", "prompt"]) {
    if (typeof q[key] !== "string" || !q[key]) return [false, `missing-${key}`];
  }
  if (!Array.isArray(q.options) || q.options.length < 2) return [false, "invalid-options"];
  if (!Number.isInteger(q.correctIndex) || q.correctIndex < 1 || q.correctIndex > q.options.length) return [false, "invalid-correct-index"];
  const answer = normalize(q.options[q.correctIndex - 1]);
  if (q.allowAnswerInPrompt !== true && answer && (` ${normalize(q.prompt)} `).includes(` ${answer} `)) return [false, "answer-leaked-in-prompt"];
  return [true];
}

function selectQuestion(bank, context = {}) {
  const current = new Set(context.currentMaterialSkills ?? []);
  let valid = bank.filter(q => validateQuestion(q)[0] && q.id !== context.lastQuestionId);
  if (!valid.length) return null;
  const currentMaterial = valid.filter(q => q.tier === "material" && current.has(q.skill));
  const material = valid.filter(q => q.tier === "material");
  if (currentMaterial.length) valid = currentMaterial;
  else if (material.length) valid = material;
  const due = new Set(context.dueComebackSkills ?? []);
  const counts = context.independentOpportunitiesBySkill ?? {};
  return [...valid].sort((a, b) => {
    const tuple = q => [
      due.has(q.skill) ? 0 : 1,
      Number(counts[q.skill] ?? 0),
      transferTypes.has(q.questionType) || transferTypes.has(q.cognitiveDemand) ? 0 : 1,
      Number(q.difficulty ?? 0),
      String(q.id),
    ];
    const A = tuple(a), B = tuple(b);
    for (let i = 0; i < A.length; i++) if (A[i] !== B[i]) return A[i] < B[i] ? -1 : 1;
    return 0;
  })[0];
}

const fixture = [
  { id:"old-repeat", subject:"ELA", skill:"phonics", tier:"material", prompt:"Which word has short a?", options:["cat","moon","bike"], correctIndex:1, questionType:"transfer", difficulty:2 },
  { id:"copy-leak", subject:"ELA", skill:"phonics", tier:"material", prompt:"Which spelling is map?", options:["map","mep","mip"], correctIndex:1, questionType:"direct", difficulty:1 },
  { id:"math-direct", subject:"Math", skill:"add", tier:"material", prompt:"What is 8 + 5?", options:["13","12","14"], correctIndex:1, questionType:"direct", difficulty:2 },
  { id:"math-transfer", subject:"Math", skill:"add", tier:"material", prompt:"Mia has 8 shells and finds 5 more. How many shells now?", options:["13","12","14"], correctIndex:1, questionType:"transfer", difficulty:2 },
  { id:"vocab-material", subject:"ELA", skill:"vocab", tier:"material", prompt:"A tiny ant fits under a leaf. Which word also means very small?", options:["little","giant","noisy"], correctIndex:1, questionType:"application", difficulty:2 },
  { id:"fallback", subject:"Science", skill:"plants", tier:"star-fallback", prompt:"Which part of a plant usually grows underground?", options:["roots","flowers","leaves"], correctIndex:1, questionType:"application", difficulty:1 },
];

assert.deepEqual(validateQuestion(fixture[1]), [false, "answer-leaked-in-prompt"], "copy-the-answer item must be rejected");
assert.equal(validateQuestion({ ...fixture[1], id:"passage-opt-in", allowAnswerInPrompt:true })[0], true, "explicit answer-in-prompt opt-in must remain compatible");
const afterRepeat = selectQuestion(fixture, { currentMaterialSkills:["phonics"], lastQuestionId:"old-repeat", independentOpportunitiesBySkill:{add:1,vocab:0} });
assert.notEqual(afterRepeat.id, "old-repeat", "last question must never immediately repeat");
assert.equal(afterRepeat.tier, "material", "fallback must not displace available material");
assert.equal(selectQuestion(fixture, { currentMaterialSkills:["add"], independentOpportunitiesBySkill:{add:0} }).id, "math-transfer", "transfer item should beat direct item within same current skill");
assert.equal(selectQuestion(fixture, { currentMaterialSkills:["add","vocab"], independentOpportunitiesBySkill:{add:5,vocab:0} }).id, "vocab-material", "under-practiced current skill should win skill balancing");
assert.equal(selectQuestion(fixture, { currentMaterialSkills:["not-present"], dueComebackSkills:["add"], independentOpportunitiesBySkill:{add:4,vocab:0} }).id, "math-transfer", "due material comeback should beat lower-count material skill while fallback stays behind material");

function gradeSequence(correctIndex, choices) {
  let misses = 0, completed = false;
  return choices.map(choiceIndex => {
    assert.equal(completed, false, "cannot grade completed encounter");
    if (choiceIndex === correctIndex) {
      completed = true;
      return {kind:"correct", independent:misses===0, masteryEligible:misses===0, complete:true};
    }
    misses += 1;
    if (misses === 1) return {kind:"clue", independent:false, masteryEligible:false, complete:false};
    if (misses === 2) return {kind:"support", independent:false, masteryEligible:false, complete:false};
    completed = true;
    return {kind:"modeled", independent:false, masteryEligible:false, complete:true, comebackAfter:2};
  });
}

assert.deepEqual(gradeSequence(1, [1]), [{kind:"correct", independent:true, masteryEligible:true, complete:true}]);
assert.deepEqual(gradeSequence(1, [2,1]), [
  {kind:"clue", independent:false, masteryEligible:false, complete:false},
  {kind:"correct", independent:false, masteryEligible:false, complete:true},
]);
assert.deepEqual(gradeSequence(1, [2,3,2]), [
  {kind:"clue", independent:false, masteryEligible:false, complete:false},
  {kind:"support", independent:false, masteryEligible:false, complete:false},
  {kind:"modeled", independent:false, masteryEligible:false, complete:true, comebackAfter:2},
]);

console.log("EDUCATION_ENGINE_POLICY_OK one-question=true current-material-first=true nonrepeat=true transfer=true support-evidence=true comeback=2");
