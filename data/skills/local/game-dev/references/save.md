# Saves

## 1. Where to store

- Native games write to the per-user data directory, never next to the executable: Godot `user://`, Unity `Application.persistentDataPath`, SDL `SDL_GetPrefPath`, the `dirs` or `directories` crates in Rust.
- Browser: pick the storage API per the modern-web-guidance skill. Never write saves every frame, and keep large or frequent saves off synchronous `localStorage`.
- Browser storage is per origin and can be evicted; offer export and import of a save file for anything precious, and cloud saves for accounts.

## 2. Versioning

Every save carries a `version` from the first release, and loading runs migrations in sequence (v1 → v2 → v3) so any old save upgrades.

- Merge loaded data over defaults (`{ ...defaults, ...loaded }`) so older saves gain new fields instead of `undefined`.
- Keep the previous save as a backup until the new one is written and its migration succeeded.
- IndexedDB's own schema version (`open(name, version)`, `idb`'s `upgrade`) only shapes object stores; the save data still needs its own version.

## 3. What to save

- Plain data (positions, inventory, flags, RNG seed and counters), never class instances, functions, or engine objects.
- Procedural games save the seed and progress and regenerate the world on load ([procedural-generation.md](procedural-generation.md)).
- JSON drops `Map`, `Set`, `Date`, typed arrays, and `undefined`, and turns `NaN` and `Infinity` into `null`; convert them explicitly or use `structuredClone` and IndexedDB.
- Wrap every load in try/catch; a corrupt save falls back to defaults instead of a blank screen.
- Client saves are trivially editable: validate leaderboard scores on a server.

## 4. Autosave

- Save on meaningful events (checkpoint, level complete, item gained) plus a throttled timer, at most every few seconds.
- Save on `visibilitychange` to hidden and on `pagehide`: mobile browsers kill background tabs without a reliable `beforeunload`.
- Write atomically: on disk write a temp file, flush, and rename it over the old one; in IndexedDB use one transaction; in `localStorage` set one complete blob, never several keys.
