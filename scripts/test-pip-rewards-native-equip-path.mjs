import assert from 'node:assert/strict';

const ref = process.argv[2];
assert.ok(ref, 'usage: node scripts/test-pip-rewards-native-equip-path.mjs <exact-ref-or-sha>');

const root = `https://raw.githubusercontent.com/P00NSMASHER/PipsQuestWorld/${ref}/`;
async function read(path) {
  const response = await fetch(root + path);
  assert.equal(response.status, 200, `failed to fetch ${path}: HTTP ${response.status}`);
  return response.text();
}

const [
  finishThunk,
  serverMain,
  datastore,
  inventoryObjects,
  inventoryButtons,
  shopItem,
  equipPlayer,
  pet,
] = await Promise.all([
  read('game/src/common/thunks/playerFinishedRoom.lua'),
  read('game/src/server/main.lua'),
  read('game/src/common/GameDatastore.lua'),
  read('game/src/common/objects/InventoryObjects.lua'),
  read('game/src/client/Components/InventoryAndShopButtons.lua'),
  read('game/src/client/Components/ShopItem.lua'),
  read('game/src/common/thunks/equipPlayer.lua'),
  read('game/src/common/Pet.lua'),
]);

assert.ok(
  finishThunk.includes("local PIP_NATIVE_FINISH_REWARD_ID = '20004'") &&
    finishThunk.includes('GameDatastore:setInventoryItem(player, PIP_NATIVE_FINISH_REWARD_ID)'),
  'Pip finish reward must remain a native inventory unlock'
);
assert.equal(
  finishThunk.includes('GameDatastore:setEquippedPet(player, PIP_NATIVE_FINISH_REWARD_ID)'),
  false,
  'Pip reward must not auto-equip or bypass Maze World choice'
);

assert.ok(
  serverMain.includes('local inventoryItems = M.reduce(inventoryItemIds, getInventoryObject, {})') &&
    serverMain.includes('store:dispatch(addItemsToPlayerInventory(playerId, inventoryItems))') &&
    serverMain.includes('GameDatastore:onInventoryUpdated(player, updateInventoryInState)'),
  'native inventory replication must remain connected to datastore updates'
);
assert.ok(
  inventoryButtons.includes('inventory = M.map(M.filter(state.inventory, isVisible), byId)'),
  'native Inventory UI must continue to expose replicated owned items'
);

const ownedBranch = shopItem.indexOf('elseif isOwned then\n\t\t\tequipItem(item.id)');
const buyBranch = shopItem.indexOf('else\n\t\t\tbuyItem(item.id)');
assert.ok(ownedBranch > -1 && buyBranch > ownedBranch, 'owned native pet must equip instead of buying');
assert.ok(shopItem.includes("buttonText = 'Equip'"), 'owned pet must present the native Equip action');

const equipApi = serverMain.indexOf('equipItem = function(player, productId)');
const equipWrite = serverMain.indexOf('GameDatastore:setEquippedPet(player, product.id)', equipApi);
assert.ok(equipApi > -1 && equipWrite > equipApi, 'native equip API must persist the selected pet');

assert.ok(
  datastore.includes('function GameDatastore:setEquippedPet(player, id)') &&
    datastore.includes('return M.unique(M.push(currentPets, id))') &&
    datastore.includes('GameDatastore:onEquippedPetsUpdated(player, updetePetsEquippedInState)') === false,
  'native equipped datastore must stay duplicate-safe'
);
assert.ok(
  serverMain.includes('GameDatastore:onEquippedPetsUpdated(player, updetePetsEquippedInState)'),
  'native equipped datastore updates must dispatch through the existing equip thunk'
);
assert.ok(
  equipPlayer.includes('PetManager:addToCharacter(petObjects, player.Character, playerSlotsCount)') &&
    equipPlayer.includes('store:dispatch(clientEquipped(tostring(player.UserId), petIds))'),
  'native equip thunk must remain authoritative for pet/trail attachment and client state'
);

assert.ok(
  inventoryObjects.includes("['20004'] = {") &&
    inventoryObjects.includes("name = 'Path Pet Rainbow'") &&
    inventoryObjects.includes('ability = PET_TYPES.TRAIL') &&
    inventoryObjects.includes("trailModelName = 'RainbowTrail'"),
  'Pip reward must remain bound to Maze World Path Pet Rainbow'
);
assert.ok(
  pet.includes('if self.petObject.ability == PET_TYPES.TRAIL then') &&
    pet.includes('self:addTrailToCharacter()') &&
    pet.includes('local name = self.petObject.trailModelName'),
  'native Pet path must remain responsible for attaching the unlocked RainbowTrail'
);

for (const forbidden of [
  'PipEquip',
  'PipInventory',
  'PipCurrency',
  'PipFinishPad',
  'PipRewardRoom',
]) {
  assert.equal(
    (finishThunk + serverMain + equipPlayer).includes(forbidden),
    false,
    `parallel Pip equip/progression surface detected: ${forbidden}`
  );
}

console.log(`PASS Pip native inventory/equip path contract at ${ref}`);
