import fs from "node:fs";
import path from "node:path";

const root = path.resolve(process.argv[2] || process.cwd());
const mustExist = [
  "game/maze-world.rbxl",
  "game/Place.rbxmx",
  "game/PlaceTerrain.rbxmx",
  "game/models/Prefabs/SpawnPlaceholder.rbxmx",
  "game/models/Prefabs/FinishPlaceholder.rbxmx",
  "game/models/Money/Coin.rbxmx",
  "game/models/Money/PileOfCoins.rbxmx",
  "game/models/Walls/Walls_1.rbxmx",
  "game/models/Trails/RainbowTrail.rbxmx",
  "game/src/common/Maze.lua",
  "game/src/common/MazeGenerator.lua",
  "game/src/common/thunks/startGame.lua",
  "game/src/common/thunks/playerFinishedRoom.lua",
  "game/src/client/Components/FinishScreen.lua",
];
const missing = mustExist.filter((item) => !fs.existsSync(path.join(root, item)));
if (missing.length) throw new Error("Missing foundation files: " + missing.join(", "));

function walk(dir, result = []) {
  for (const entry of fs.readdirSync(dir, { withFileTypes: true })) {
    const full = path.join(dir, entry.name);
    if (entry.isDirectory()) walk(full, result);
    else result.push(full);
  }
  return result;
}

const firstPartyRoot = path.join(root, "game", "src");
const luaFiles = walk(firstPartyRoot).filter((file) => file.endsWith(".lua"));
if (luaFiles.length < 100) {
  throw new Error("Unexpectedly small first-party source tree: " + luaFiles.length);
}

const forbidden = [
  "PipsQuestWorld",
  "PipsQuestHUD",
  "RewardChest",
  "LearningGate",
  "QuestionTrigger",
  "WorldBuilder",
];
for (const file of luaFiles) {
  const text = fs.readFileSync(file, "utf8");
  const hit = forbidden.find((token) => text.includes(token));
  if (hit) throw new Error("Legacy custom-world marker " + hit + " in " + file);
}

const read = (relative) => fs.readFileSync(path.join(root, relative), "utf8");
const config = read("game/src/common/PipsOverlayConfig.lua");
for (const required of [
  "mode = 'shadow'",
  "blockFinish = false",
  "replaceMazeUI = false",
  "replaceMazeRewards = false",
  "replaceMazeGeneration = false",
]) {
  if (!config.includes(required)) throw new Error("Shadow config drift: " + required);
}

const generator = read("game/src/common/MazeGenerator.lua");
for (const required of ["recursive_backtracker", "AddCoinPart", "DrawStart", "DrawFinish"]) {
  if (!generator.includes(required)) throw new Error("Maze generator seam missing: " + required);
}

const startGame = read("game/src/common/thunks/startGame.lua");
for (const required of ["MazeGenerator:generate", "FinishPlaceholder", "clientStartGame", "playerFinishedRoom"]) {
  if (!startGame.includes(required)) throw new Error("Maze game loop seam missing: " + required);
}

const finish = read("game/src/common/thunks/playerFinishedRoom.lua");
for (const required of ["clientFinishGame", "incrementCoins", "placePlayersToHomeSpawn"]) {
  if (!finish.includes(required)) throw new Error("Native finish/reward seam missing: " + required);
}

const modelFiles = walk(path.join(root, "game", "models")).filter((file) => file.endsWith(".rbxmx"));
if (modelFiles.length < 15) {
  throw new Error("Unexpectedly small model tree: " + modelFiles.length);
}

console.log(JSON.stringify({
  verdict: "PASS",
  firstPartyLuaFiles: luaFiles.length,
  modelFiles: modelFiles.length,
  requiredFoundationFiles: mustExist.length,
  shadowMode: true,
  legacyCustomWorldMarkers: 0,
}));
