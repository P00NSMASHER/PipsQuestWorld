import fs from "node:fs";
import path from "node:path";

const root = path.resolve(process.argv[2] || process.cwd());
const read = (relative) => fs.readFileSync(path.join(root, relative), "utf8");

const coin = read("game/models/Money/Coin.rbxmx");
const pile = read("game/models/Money/PileOfCoins.rbxmx");
const inventory = read("game/src/common/objects/InventoryObjects.lua");
const serverMain = read("game/src/server/main.lua");

const tagBase64 = "Q29pbkJyaWNr";
if (!coin.includes(tagBase64)) throw new Error("Coin.rbxmx lost native CoinBrick tag");
if (!pile.includes(tagBase64)) throw new Error("PileOfCoins.rbxmx lost native CoinBrick tag");
if (!coin.includes("<double name=\"Value\">9000001</double>")) {
  throw new Error("Coin.rbxmx native itemId drifted");
}
if (!pile.includes("<double name=\"Value\">9000008</double>")) {
  throw new Error("PileOfCoins.rbxmx native itemId drifted");
}

for (const id of ["9000001", "9000005", "9000008"]) {
  const marker = "['" + id + "']";
  const index = inventory.indexOf(marker);
  if (index < 0) throw new Error("Missing normal CoinObjects id " + id);
  const block = inventory.slice(index, inventory.indexOf("\n\t},", index) + 4);
  if (block.includes("onePerPlayer = true")) {
    throw new Error("Normal coin id became onePerPlayer: " + id);
  }
}

for (const id of ["9002008", "9002009", "9002010", "9002011", "9002012"]) {
  const marker = "['" + id + "']";
  const index = inventory.indexOf(marker);
  if (index < 0) throw new Error("Missing treasure CoinObjects id " + id);
  const block = inventory.slice(index, inventory.indexOf("\n\t},", index) + 4);
  if (!block.includes("onePerPlayer = true")) {
    throw new Error("Treasure id lost onePerPlayer protection: " + id);
  }
}

const nativeRegistration = "TagItem.create(nil, 'CoinBrick'";
const nativeCount = serverMain.split(nativeRegistration).length - 1;
if (nativeCount !== 1) {
  throw new Error("Expected exactly one native CoinBrick TagItem registration, found " + nativeCount);
}

const pipsRoot = path.join(root, "game", "src", "serverStorage");
for (const entry of fs.readdirSync(pipsRoot, { withFileTypes: true })) {
  if (!entry.isFile() || !/^Pips.*\.lua$/.test(entry.name)) continue;
  const text = fs.readFileSync(path.join(pipsRoot, entry.name), "utf8");
  if (text.includes("TagItem.create") && text.includes("CoinBrick")) {
    throw new Error("Pips module must not register a competing CoinBrick TagItem handler: " + entry.name);
  }
}

console.log(JSON.stringify({
  verdict: "PASS",
  normalCoinItemIds: ["9000001", "9000005", "9000008"],
  generatedCoinModels: {
    Coin: "9000001",
    PileOfCoins: "9000008",
  },
  nativeCoinBrickHandlers: nativeCount,
  pipsCompetingHandlers: 0,
}));
