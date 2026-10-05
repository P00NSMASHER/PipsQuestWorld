local StudioStore = assert(loadfile("school/src/server/ProgressionStudioStore.lua"))()

local economyA = StudioStore.shared("economy")
local economyB = StudioStore.shared("economy")
local housing = StudioStore.shared("housing-layout")

assert(economyA == economyB, "same namespace must return one shared adapter")
assert(economyA ~= housing, "different namespaces must remain isolated")

local saved, version = economyA:compareAndSwap(101, 0, {
    revision = 1,
    balance = 25,
})
assert(saved == true and version == 1, "shared write failed")

local snapshot, readVersion = economyB:read(101)
assert(readVersion == 1 and snapshot.balance == 25, "shared namespace did not expose committed state")

local isolatedSnapshot, isolatedVersion = housing:read(101)
assert(isolatedSnapshot == nil and isolatedVersion == 0, "separate namespace leaked state")

print("STUDIO_STORE_SHARED_PASS")
