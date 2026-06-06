# Dev notes

Operational notes for working on this modpack repo.

## One-time setup

After cloning, enable the local git hooks:

```sh
git config core.hooksPath .githooks
```

This activates `.githooks/pre-commit`, which runs `packwiz refresh` before every commit and restages `index.toml` / `pack.toml` if their hashes changed. Without this, you can commit a pack where `index.toml` is out of sync with `mods/*.pw.toml` and CI builds will look wrong.

Install packwiz if you don't have it:

```sh
go install github.com/packwiz/packwiz@latest
```

The hook is a no-op if packwiz isn't on PATH — it won't block commits, but you'll lose the auto-refresh.

## Day-to-day: adding / updating mods

```sh
packwiz mr add <modrinth-slug>      # add a Modrinth mod
packwiz cf add <curseforge-slug>    # add a CurseForge mod
packwiz update <mod-name>           # update one
packwiz update --all                # update everything
```

Then `git add mods/<mod>.pw.toml` and commit — the pre-commit hook handles `index.toml`/`pack.toml`.

For client-only or server-only mods, edit the `side =` field in the generated `.pw.toml`. The CI build relies on this to split client vs. server.

## Releases (tags)

CI builds the `.mrpack` and server-files zip on every push to `main`, but only attaches them to a **GitHub release** when you push a tag matching `v*`.

Note: make sure you update `index.toml` with the latest version to match tags.

Release flow:

```sh
# 1. Make sure main is up to date
git checkout main
git pull

# 2. Bump version in pack.toml (e.g. 2.0.0 -> 2.0.1) and commit
$EDITOR pack.toml
git commit -am "Release 2.0.1"
git push

# 3. Tag and push
git tag -a v2.0.1 -m "Release 2.0.1"
git push --tags
```

CI then:

- Builds `underpunks-the-create-age-2.0.1.mrpack` (client install for Modrinth / Prism / ATLauncher)
- Builds `underpunks-the-create-age-2.0.1-server-files.zip` (mods/configs/kubejs for server, no Minecraft jar)
- Creates a GitHub release at `v2.0.1` with both attached

Versioning convention: `vMAJOR.MINOR.PATCH`.

- PATCH: config tweaks, single mod swap, bugfix
- MINOR: new mods, new features, kubejs additions
- MAJOR: MC version bump or large reworks

Keep `pack.toml` `version =` in lockstep with the tag.

### Fixing a bad tag

```sh
git tag -d v2.0.1
git push --delete origin v2.0.1
# then re-tag the right commit
```

Re-using a tag name after a release has been published is messy — prefer bumping to the next patch instead.

## Deploying a server

The server-files zip is *not* a complete server. It only has mods, configs, and kubejs (no Minecraft, no NeoForge, no `run.sh`).

To stand up a server:

1. Download the NeoForge 21.1.230 installer from <https://projects.neoforged.net/neoforged/neoforge>
2. Run it in a fresh directory — produces `libraries/`, `run.sh`, `user_jvm_args.txt`
3. Unzip the server-files zip on top of that directory
4. Edit `user_jvm_args.txt` to use Java 21 + ZGC:

   ```
   -Xmx6G
   -Xms4G
   -XX:+UseZGC
   -XX:+ZGenerational
   -XX:+AlwaysPreTouch
   -XX:+DisableExplicitGC
   ```

5. Ensure Java 21 is on PATH (Temurin 21 recommended). The bundled mixin doesn't support Java class file versions newer than 21.
6. `./run.sh`

## Client install

The `.mrpack` is the canonical client install. Players open it in the Modrinth app, Prism Launcher, or ATLauncher and it pulls everything down.

## Local builds

To produce the same artifacts CI does, without committing or pushing:

```sh
./scripts/build.sh
```

Outputs to `build/`:

- `build/<slug>-<version>.mrpack`
- `build/<slug>-<version>-server-files.zip`

Requires `packwiz`, `java` (21), `curl`, `zip` on PATH. The script is what CI calls too, so local builds match CI exactly.

## Workflow file

`.github/workflows/build.yml` — thin wrapper that installs tools and runs `scripts/build.sh`. Triggers:

- Push to `main` → artifacts uploaded as workflow artifacts (not a release)
- Tag `v*` → artifacts also attached to a GitHub release
- Manual: Actions tab → "Build modpack" → Run workflow
