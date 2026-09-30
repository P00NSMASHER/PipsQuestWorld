import fs from "node:fs";
import path from "node:path";

const root = process.cwd();
const clientRoots = [
  path.join(root, "game", "src", "common"),
  path.join(root, "game", "src", "client"),
];

const forbiddenNames = new Set([
  "PipsEducationEngine.lua",
  "PipsQuestionBank.lua",
  "PipsReleaseQuestionBank.lua",
]);

const leaks = [];
for (const base of clientRoots) {
  if (!fs.existsSync(base)) continue;
  const stack = [base];
  while (stack.length) {
    const dir = stack.pop();
    for (const entry of fs.readdirSync(dir, { withFileTypes: true })) {
      const full = path.join(dir, entry.name);
      if (entry.isDirectory()) stack.push(full);
      else if (forbiddenNames.has(entry.name)) leaks.push(path.relative(root, full));
    }
  }
}
if (leaks.length) {
  throw new Error("Client-reachable education authority leaked: " + leaks.join(", "));
}

const serverRoot = path.join(root, "game", "src", "serverStorage");
for (const required of [
  "PipsEducationEngine.lua",
  "PipsQuestionBank.lua",
  "PipsReleaseQuestionBank.lua",
]) {
  if (!fs.existsSync(path.join(serverRoot, required))) {
    throw new Error("Missing server-only education file: " + required);
  }
}

const engine = fs.readFileSync(path.join(serverRoot, "PipsEducationEngine.lua"), "utf8");
if (!engine.includes("function EducationEngine.clientView")) {
  throw new Error("clientView missing");
}
const clientView = engine.slice(engine.indexOf("function EducationEngine.clientView"));
if (clientView.split("function EducationEngine.pickQuestion")[0].includes("correctIndex")) {
  throw new Error("clientView leaks correctIndex");
}

console.log("PIPS_SERVER_ONLY_EDUCATION_BOUNDARY_PASS");
