// Sophisticated Backpacks: re-link migrated backpack items to their contents.
//
// On the 1.20.1->1.21.1 jump the vanilla DataFixer moves a backpack's old
// `tag.contentsUuid` into the `minecraft:custom_data` component instead of the
// `sophisticatedcore:storage_uuid` component SBP reads. SBP then mints a NEW empty
// storage and the backpack opens blank, while the real contents sit safe in
// sophisticatedbackpacks.dat under the original UUID. Fix = copy
// custom_data.contentsUuid back into sophisticatedcore:storage_uuid after the game has
// loaded the item (login / inventory move / chest open).
//
// DEBUG=true logs every decision so we can see exactly what the KubeJS 1.21 API does.
// Set false once it's confirmed working.

const DEBUG = true
const TAG = '[sbp-relink]'

function dbg(msg) { if (DEBUG) console.info(`${TAG} ${msg}`) }

function isBackpackId(id) {
  id = String(id)
  if (id.indexOf('sophisticatedbackpacks:') !== 0) return false
  var path = id.substring(id.indexOf(':') + 1)
  return path === 'backpack' || path.endsWith('_backpack')
}

function isBackpack(stack) {
  return stack && !stack.empty && isBackpackId(stack.id)
}

// Try several ways to reach the custom_data CompoundTag; return it or null.
function customData(stack) {
  // 1) KubeJS legacy alias (often maps to the custom_data component in 1.21)
  try {
    var n = stack.nbt
    if (n && n.contains && n.contains('contentsUuid')) { dbg('  read via stack.nbt'); return n }
  } catch (e) { dbg('  stack.nbt threw: ' + e) }
  // 2) component API -> CustomData -> copyTag()
  try {
    var cd = stack.get('minecraft:custom_data')
    if (cd) {
      var t = cd.copyTag ? cd.copyTag() : cd
      if (t && t.contains && t.contains('contentsUuid')) { dbg('  read via get(custom_data).copyTag'); return t }
    }
  } catch (e) { dbg('  get(minecraft:custom_data) threw: ' + e) }
  return null
}

function arrEq(a, b) {
  if (!a || !b || a.length !== 4 || b.length !== 4) return false
  for (var i = 0; i < 4; i++) if (a[i] !== b[i]) return false
  return true
}

// Set sophisticatedcore:storage_uuid from an int[4] (the UUIDUtil.CODEC persisted form,
// which is exactly what KubeJS get() returns for this component).
function setStorageUuid(stack, arr) {
  try {
    stack.set('sophisticatedcore:storage_uuid', [arr[0], arr[1], arr[2], arr[3]])
    dbg('  set via int[4] OK'); return true
  } catch (e) {
    console.error(`${TAG} could not set storage_uuid on ${stack.id}: ${e}`); return false
  }
}

// Fix one stack in place. Returns true if changed.
function relinkStack(stack, where) {
  if (!isBackpack(stack)) return false
  var id = String(stack.id)
  var tag = customData(stack)
  if (!tag) { dbg(`${where}: ${id} -> NO custom_data with contentsUuid (nothing to recover / API miss)`); return false }
  var arr = tag.getIntArray('contentsUuid')
  if (!arr || arr.length !== 4) { dbg(`${where}: ${id} -> contentsUuid not a 4-int array`); return false }
  // KubeJS returns sophisticatedcore:storage_uuid as an int[4] (the codec form), NOT a
  // UUID object -- so compare int-arrays directly. No UUID conversion (that was the
  // "NativeJavaArray to int" error).
  var cur = null
  try { cur = stack.get('sophisticatedcore:storage_uuid') } catch (e) { dbg('  get storage_uuid threw: ' + e) }
  if (cur && cur.length === 4 && arrEq(cur, arr)) { dbg(`${where}: ${id} -> already correct`); return false }
  var ok = setStorageUuid(stack, arr)
  if (ok) console.info(`${TAG} relinked ${id} (${where})`)
  return ok
}

function sweepContainer(container, where) {
  var count = 0
  var size = container.getContainerSize()
  for (var i = 0; i < size; i++) {
    if (relinkStack(container.getItem(i), where)) count++
  }
  return count
}

// ---- on login: sweep inventory + ender chest ----
try {
  PlayerEvents.loggedIn(event => {
    var player = event.player
    dbg(`loggedIn fired for ${player.username}`)
    var fixed = 0
    try { fixed += sweepContainer(player.inventory, 'inv') }
    catch (e) { console.error(`${TAG} inventory scan failed: ${e}`) }
    try { fixed += sweepContainer(player.getEnderChestInventory(), 'ender') }
    catch (e) { console.error(`${TAG} ender-chest scan failed: ${e}`) }
    if (fixed > 0) {
      try { player.inventoryMenu.broadcastChanges() } catch (e) { /* best effort */ }
      console.info(`${TAG} relinked ${fixed} backpack(s) for ${player.username} on login`)
    } else {
      dbg(`no backpacks relinked on login for ${player.username}`)
    }
  })
} catch (e) { console.error(`${TAG} could not register loggedIn handler: ${e}`) }

// ---- real time: heal a backpack as it enters a player's inventory ----
try {
  PlayerEvents.inventoryChanged(event => {
    try { relinkStack(event.item, 'invChanged') }
    catch (e) { console.error(`${TAG} inventoryChanged failed: ${e}`) }
  })
} catch (e) { console.error(`${TAG} could not register inventoryChanged handler: ${e}`) }

// ---- chest open: scan the right-clicked block's container ----
try {
  BlockEvents.rightClicked(event => {
    try {
      var block = event.block
      if (!block) return

      // NOTE: backpacks PLACED as blocks are intentionally NOT handled. Their pointer is
      // destroyed on first 1.21.1 load (the modded block entity's nested stack isn't
      // datafixed, so contentsUuid is lost) and can't be recovered at runtime. Decided
      // out of scope -- contents remain in sophisticatedbackpacks.dat if ever needed.

      // Containers (chest/barrel/...): scan slots for backpack ITEMS.
      var inv = null
      try { inv = block.inventory } catch (e) { dbg('block.inventory threw: ' + e) }
      if (!inv) return
      var size = (inv.size !== undefined) ? inv.size : (inv.getSlots ? inv.getSlots() : 0)
      var fixed = 0
      for (var i = 0; i < size; i++) {
        var st = inv.getStackInSlot ? inv.getStackInSlot(i) : null
        if (st && relinkStack(st, 'chest')) {
          try { if (inv.setStackInSlot) inv.setStackInSlot(i, st) } catch (e) { dbg('setStackInSlot threw: ' + e) }
          fixed++
        }
      }
      if (fixed > 0) {
        try { if (block.entity && block.entity.setChanged) block.entity.setChanged() } catch (e) { /* best effort */ }
        console.info(`${TAG} relinked ${fixed} backpack(s) in container at ${block.pos}`)
      }
    } catch (e) { console.error(`${TAG} chest scan failed: ${e}`) }
  })
} catch (e) { console.error(`${TAG} could not register rightClicked handler: ${e}`) }

console.info(`${TAG} loaded (DEBUG=${DEBUG})`)
