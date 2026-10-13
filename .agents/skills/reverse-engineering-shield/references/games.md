# Games (Unity, Unreal, Godot, custom engines)

Game clients are fully in the player's hands. Anything that decides an outcome —
economy, loot, matchmaking, rewards, anti-cheat verdicts — must be decided by the server.

## Server authority

- The server owns currency, inventory, progression and match results. The client sends
  inputs, the server validates and answers.
- Drop tables, prices and balancing values are served by the backend, versioned, so a
  copied client gets no data advantage.
- Leaderboards accept results only from server-validated sessions.

## Unity

- Use the **IL2CPP** scripting backend for release builds. The Mono backend ships
  `Assembly-CSharp.dll`, which decompiles to readable C#.
- Strip engine code (`Managed Stripping Level` high) and disable development builds,
  script debugging and the profiler connection.
- Do not keep API keys or service secrets in `ScriptableObject`s, `Resources/` or
  `StreamingAssets/`.
- Asset bundles are readable: don't put server rules or unreleased content keys in them.

## Unreal Engine

- Ship Shipping builds (not Development): no console commands, no debug symbols in the
  package; keep `.pdb`/`.debug` files private.
- Encrypt and sign `.pak` files (Project Settings → Crypto); keep keys out of source
  control and rotate per release if feasible.
- Blueprint logic is stored in assets: move valuable rules to the server or to C++.

## Godot

- Export with PCK encryption enabled (requires a custom export template with the key).
- GDScript is shipped as text or tokenized script: keep rules on the server.

## Verify

```bash
scripts/audit.sh Build/            # exported game folder
scripts/audit.sh game.apk
```

Check by hand: no `Assembly-CSharp.dll` in IL2CPP builds, no symbol files, no
development-build flags.
