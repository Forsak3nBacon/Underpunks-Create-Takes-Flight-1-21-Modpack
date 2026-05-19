# Underpunks MC Server — 1.21.1 Modlist Rebuild

Working reference for the packwiz rebuild. Libraries excluded — packwiz will resolve them as dependencies.

**Notation:**
- `*(was X)*` — remapped from a previous mod
- `*(new)*` — added in this rebuild
- `— CF` — install from CurseForge (`packwiz cf install`); default is Modrinth (`packwiz mr install`)

---

## ⚠️ Needs Extra Care Before Touching

Audit the world for these before committing — if it's just you using them, swap and replace.

- **Copper & Tuff Backport** — vanilla in 1.21.1 now. Check all placements; the block IDs will change.
- **Create: Steam 'n' Rails → Steam 'n' Rails Unofficial** — verify existing tracks/content migrate cleanly.

---

## Install List

### Create Ecosystem
- Create
- Create Crafts & Additions
- Create Deco
- Create Jetpack *(bump fuel cost in config)*
- Create Railways Navigator
- Create Slice & Dice
- Create: Copycats+
- Steam 'n' Rails Unofficial *(was Create: Steam 'n' Rails)*
- Create Additional Logistics *(new)*
- Create Power Grid *(new)*
- Create Dreams & Desires *(new)*
- Create Design n Deco *(new)*
- Create Aeronautics *(new)*
- Create Tracks — CF *(new)*
- Create Propulsion: Simulated *(new)*
- Drive-By-Wire With Sable *(new)*
- Create Connected *(new)*
- Create Ballast *(new)*
- Copycats+ Aeronautics Weight *(new)*
- Climbable Ropes for Create Aeronautics *(new)*
- Create: Compact Flap *(new)*
- Create Better FPS — CF *(new)*
- Create Transmission — CF *(new)*
- Create Cobblestone *(new)*
- Create Contraption Terminals *(new)*
- Create Copper and Zinc *(new)*
- Create Big Cannons *(new)*

### KubeJS / Scripting
- KubeJS
- KubeJS Create
- CC: Tweaked

### Storage
- Echo Chest *(new)*
- Refined Storage
- Sophisticated Backpacks
- Sophisticated Storage
- Storage Drawers
- Tom's Simple Storage Mod *(new)*

### Building / Decoration
- Amendments
- Armor Statues
- Building Gadgets 2 — CF
- Chipped
- chisels-and-bits — CF
- Connected Glass
- Decorative Blocks Reborn *(was Decorative Blocks)*
- Diagonal Fences *(new)*
- Diagonal Walls *(new)*
- Diagonal Windows *(new)*
- Effortless Building *(new)*
- FramedBlocks
- Fusion
- Handcrafted
- Jake's Build Tools *(new)*
- Macaw's Bridges *(new)*
- Macaw's Doors *(new)*
- Macaw's Fences and Walls
- Macaw's Furniture
- Macaw's Lights and Lamps *(new)*
- Macaw's Paintings *(new)*
- Macaw's Paths and Pavings *(new)*
- Macaw's Roofs
- Macaw's Stairs *(new)*
- Macaw's Trapdoors *(new)*
- Macaw's Windows
- Quark
- Rechiseled
- Rechiseled: Chipped
- Rechiseled: Create
- Stoneworks *(new)*
- Straw Statues *(new)*
- Supplementaries
- Visual Workbench *(new)*

### Performance / Rendering
- Sodium *(was Embeddium)*
- Chloride *(was Embeddium++)*
- Lithium *(new)*
- Sodium Extra *(new)*
- Sodium Leaf Culling *(new)*
- Sodium Dynamic Lights *(new)*
- Sodium Shadowy Path Blocks *(new)*
- Ferrite Core
- Entity Culling *(new)*
- Fast Item Frames *(new)*
- ImmediatelyFast *(new)*
- More Culling *(new)*
- Smooth Chunk Save — CF *(new)*
- Distant Horizons
- Oculus
- Oculus Flywheel Compat
- Too Fast

### QoL / UI
- AppleSkin
- Block Runner *(new)*
- Boat Item View *(new)*
- Catalogue — CF
- Chat Animation *(new)*
- Chat Heads
- Client Tweaks *(new)*
- Clumps
- Comforts
- Companion *(new)*
- Configured — CF *(new)*
- Controlling
- Corpse
- Crafting On A Stick
- CraftingTweaks
- Ding *(new)*
- Dynamic Crosshair *(new)*
- Easy Anvils *(new)*
- Easy Magic *(new)*
- Easy Shulker Boxes *(new)*
- Elytra Slot
- EnchantmentDescriptions
- Exposure *(new)*
- Exposure: Instant Polaroid *(new)*
- First Person Model *(new)*
- Food Effect Tooltips *(was EffectTooltips)*
- Freecam
- Jade
- Jade Addons
- Journeymap
- Just Enough Items
- Just Enough Professions
- Just Enough Resources
- Just Zoom *(was OkZoomer)*
- Leaves Be Gone *(was Fast Leaf Decay)*
- Let Me Despawn
- Light Overlay — CF
- Lootr
- Mindful Darkness *(new)*
- Mouse Tweaks
- NetherPortalFix *(new)*
- No Animal Tempt Delay *(new)*
- No Chat Reports
- Not Enough Animations *(new)*
- Personality *(new)*
- Polymorph
- Searchables
- Swing Through *(new)*
- Toast Control — CF *(new)*
- Trade Cycling
- Villager Names
- Visuality *(new)*
- WaveyCapes
- What Are They Up To *(new)*

### Server / Multiplayer
- Better Compatibility Checker *(new)*
- Connectivity — CF *(new)*
- FTB Chunks — CF
- FTB Teams — CF
- Simple Voice Chat

### Audio
- AmbientSounds
- Extreme Sound Muffler
- Immersive Melodies
- Sound Physics Remastered

### World / Gameplay
- Boat Load *(new)*
- Bountiful *(new)*
- Easy NPCs *(new)*
- Farmer's Delight
- Friends and Foes *(new)*
- Horseman *(new)*
- Respawning Animals *(new)*

---

## Removed

- BisectHosting
- Copper & Tuff Backport *(now vanilla — migration check needed)*
- Immersive Aircraft *(Create Aeronautics covers this)*
- Man of Many Planes *(Create Aeronautics covers this)*
- Refined Storage — JEI Integration *(built into RS 2.0)*
- WorldEdit
- kotlinforforge-4.10.0-all *(duplicate — Kotlin for Forge handles it)*

---

## Dropped — No 1.21 Version Yet

Re-check periodically; pull back in if updated.

- Callable Horses
- Canary
- Game Menu Mod Option
- Refined Storage Addons *(not yet ported to RS 2.0 / 1.21)*
- SerializationIsBad
- Simple Storage Network
- Trigger Block
