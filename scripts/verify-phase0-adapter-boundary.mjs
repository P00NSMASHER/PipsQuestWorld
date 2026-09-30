import fs from "node:fs";
import path from "node:path";

const root = path.resolve(process.argv[2] || process.cwd());
const srcRoot = path.join(root, "game", "src");

const allowedPipsFiles = new Set([
  path.normalize("game/src/common/PipsOverlayConfig.lua"),
  path.normalize("game/src/server/PipsLearningShadow.server.lua"),
]);

function walk(dir, result = []) {
  for (const entry of fs.readdirSync(dir, { withFileTypes: true })) {
    const full = path.join(dir, entry.name);
    if (entry.isDirectory()) walk(full, result);
    else result.push(full);
  }
  return result;
}

const pipsFiles = walk(srcRoot)
  .filter((file) => /^Pips.*\.lua$/.test(path.basename(file)))
  .map((file) => path.normalize(path.relative(root, file)));

const violations = [];
for (const relative of pipsFiles) {
  if (relative.startsWith(path.normalize("game/src/serverStorage/"))) continue;
  if (!allowedPipsFiles.has(relative)) violations.push(relative);
}
if (violations.length) {
  throw new Error(
    "Phase-0 live adapter/UI/gameplay code is not authorized outside serverStorage/shadow files: "
      + violations.join(", ")
  );
}

const configPath = path.join(root, "game", "src", "common", "PipsOverlayConfig.lua");
const config = fs.readFileSync(configPath, "utf8");
for (const required of [
  "mode = 'shadow'",
  "blockFinish = false",
  "replaceMazeUI = false",
  "replaceMazeRewards = false",
  "replaceMazeGeneration = false",
  "questionsEnabled = false",
]) {
  if (!config.includes(required)) {
    throw new Error("Phase-0 config drifted: " + required);
  }
}

const shadowPath = path.join(root, "game", "src", "server", "PipsLearningShadow.server.lua");
const shadow = fs.readFileSync(shadowPath, "utf8");
for (const forbidden of [
  "CoinBrick",
  "PipsEducationEngine",
  "PipsQuestionBank",
  "PipsReleaseQuestionBank",
  "PipsLearningSession",
  "PipsLearningCoinSelector",
  "RemoteEvent",
  "RemoteFunction",
]) {
  if (shadow.includes(forbidden)) {
    throw new Error("Shadow observer gained unauthorized live-integration dependency: " + forbidden);
  }
}

console.log(JSON.stringify({
  verdict: "PASS",
  phase: 0,
  pipsFiles: pipsFiles.length,
  liveGameplayAdapters: 0,
  clientPipsFiles: pipsFiles.filter((p) => p.startsWith(path.normalize("game/src/client/"))).length,
  shadowOnly: true,
}));
