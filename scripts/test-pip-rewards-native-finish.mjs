import assert from 'node:assert/strict';

const ref = process.argv[2];
assert.ok(ref, 'usage: node scripts/test-pip-rewards-native-finish.mjs <exact-ref-or-sha>');

const root = `https://raw.githubusercontent.com/P00NSMASHER/PipsQuestWorld/${ref}/`;
async function read(path) {
  const response = await fetch(root + path);
  assert.equal(response.status, 200, `failed to fetch ${path}: HTTP ${response.status}`);
  return response.text();
}

const [finishThunk, finishAction, playerReducer, finishScreen, roomLoop, pipAction] =
  await Promise.all([
    read('game/src/common/thunks/playerFinishedRoom.lua'),
    read('game/src/common/actions/toClient/clientFinishGame.lua'),
    read('game/src/client/clientReducers/player.lua'),
    read('game/src/client/Components/FinishScreen.lua'),
    read('game/src/common/thunks/startRoomGameLoop.lua'),
    read('game/src/common/actions/toClient/clientPipNativeFinishCelebration.lua'),
  ]);

const nativeSequence = [
  'Transporter:placePlayersToHomeSpawn({ player })',
  'store:dispatch(addPlayerFinishToRoom(player, roomId, os.time(), coins))',
  'store:dispatch(clientFinishGame(player, roomId, os.time(), coins))',
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
const pipDispatch = finishThunk.indexOf(
  'clientPipNativeFinishCelebration(player, roomId, os.time(), coins)'
);
assert.ok(pipDispatch > previous, 'Pip celebration must dispatch after the full native completion path');

assert.ok(finishAction.includes("type = script.Name"), 'native clientFinishGame action changed unexpectedly');
assert.ok(playerReducer.includes("AudioPlayer.playAudio('Finish')"), 'native finish sound must remain');
assert.ok(
  playerReducer.includes("if state.lastPipNativeFinishKey == rewardKey then\n\t\t\treturn state"),
  'Pip celebration must be idempotent for a repeated native-finish event'
);
assert.ok(
  finishScreen.includes('PipRewardFeedback = pipRewardFeedback'),
  'Pip feedback must render inside the existing native FinishScreen'
);
assert.ok(
  finishScreen.includes('pipRewardMessage = state.player.pipNativeFinishMessage'),
  'native FinishScreen must consume Pip finish feedback state'
);
assert.ok(!roomLoop.includes('Pip'), 'Pip Rewards must not own or replace the room replay loop');

const changedSurface = finishThunk + playerReducer + finishScreen + pipAction;
for (const forbidden of [
  'PromptProductPurchase',
  'PromptGamePassPurchase',
  'DeveloperProducts',
  'MarketplaceService',
  'PipFinishPad',
  'PipRewardRoom',
]) {
  assert.equal(changedSurface.includes(forbidden), false, `forbidden parallel/paywalled surface: ${forbidden}`);
}

console.log(`PASS Pip native-finish reward contract at ${ref}`);
