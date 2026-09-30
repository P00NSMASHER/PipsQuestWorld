import assert from 'node:assert/strict';

const ref = process.argv[2];
assert.ok(ref, 'usage: node scripts/test-pip-rewards-native-trail-unlock.mjs <exact-ref-or-sha>');

const root = `https://raw.githubusercontent.com/P00NSMASHER/PipsQuestWorld/${ref}/`;
async function read(path) {
  const response = await fetch(root + path);
  assert.equal(response.status, 200, `failed to fetch ${path}: HTTP ${response.status}`);
  return response.text();
}

const [finishThunk, datastore, inventoryObjects, roomLoop] = await Promise.all([
  read('game/src/common/thunks/playerFinishedRoom.lua'),
  read('game/src/common/GameDatastore.lua'),
  read('game/src/common/objects/InventoryObjects.lua'),
  read('game/src/common/thunks/startRoomGameLoop.lua'),
]);

const nativeSequence = [
  'Transporter:placePlayersToHomeSpawn({ player })',
  'local finishTime = os.time()',
  'store:dispatch(addPlayerFinishToRoom(player, roomId, finishTime, coins))',
  'store:dispatch(clientFinishGame(player, roomId, finishTime, coins))',
  'GameDatastore:incrementCoins(player, coins)',
  "'You won ' .. coins .. ' coins'",
  'Leaderboards:updateMostPlayed(player)',
  'Leaderboards:updateMostPlayed(player, roomId)',
];
let previous = -1;
for (const needle of nativeSequence) {
  const at = finishThunk.indexOf(needle);
  assert.ok(at > previous, `native completion step missing/reordered: ${needle}`);
  previous = at;
}

assert.ok(
  finishThunk.includes("local PIP_NATIVE_FINISH_REWARD_ID = '20004'"),
  'Pip reward must bind to the existing Path Pet Rainbow inventory item'
);
const inventoryRead = finishThunk.indexOf('local inventory = GameDatastore:getInventory(player)');
const ownershipGuard = finishThunk.indexOf('M.include(inventory, PIP_NATIVE_FINISH_REWARD_ID)');
const inventoryWrite = finishThunk.indexOf('GameDatastore:setInventoryItem(player, PIP_NATIVE_FINISH_REWARD_ID)');
assert.ok(inventoryRead > -1 && ownershipGuard > inventoryRead && inventoryWrite > ownershipGuard,
  'native inventory ownership check/write must stay idempotent and ordered');

const unlockCall = finishThunk.indexOf('local pipRewardItem = unlockPipNativeFinishReward(player)');
assert.ok(unlockCall > previous, 'Pip unlock must happen only after Maze World native reward + leaderboard work');
const pipDispatch = finishThunk.indexOf(
  'clientPipNativeFinishCelebration(player, roomId, finishTime, coins)'
);
assert.ok(pipDispatch > unlockCall, 'Pip finish celebration must remain downstream of the optional native inventory unlock');

assert.ok(
  finishThunk.includes("'Pip unlocked ' .. pipRewardItem.name .. ' in your Inventory!'"),
  'unlock feedback must reuse the native notification system'
);
assert.ok(
  finishThunk.includes("assets.brand['logo-icon']"),
  'unlock feedback should use existing Maze World reward presentation assets'
);

assert.ok(
  datastore.includes('return M.unique(M.push(currentInventory, id))'),
  'native inventory persistence must remain duplicate-safe'
);
assert.ok(
  inventoryObjects.includes("['20004'] = {") &&
    inventoryObjects.includes("name = 'Path Pet Rainbow'") &&
    inventoryObjects.includes('ability = PET_TYPES.TRAIL') &&
    inventoryObjects.includes("trailModelName = 'RainbowTrail'"),
  'reward must reuse Maze World\'s existing Path Pet Rainbow + RainbowTrail assets'
);

for (const forbidden of [
  'GameDatastore:decrementCoins(player',
  'PromptProductPurchase',
  'PromptGamePassPurchase',
  'PipFinishPad',
  'PipRewardRoom',
]) {
  assert.equal(
    finishThunk.includes(forbidden),
    false,
    `Pip native finish unlock must stay free and avoid parallel/paywalled flow: ${forbidden}`
  );
}
assert.ok(!roomLoop.includes('Pip'), 'Pip Rewards must not own or replace the room cooldown/replay loop');

console.log(`PASS Pip native inventory/trail unlock contract at ${ref}`);
