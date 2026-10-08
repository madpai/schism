# Godot 4.7.2 / GDScript / Compatibility renderer

> DO NOT TURN SCHISM BACK INTO A MENU-HEAVY DASHBOARD GAME. The player interacts with places and objects.

Godot is selected for Android lifecycle, touch, 2D scenes, lightweight shaders, headless tests and established export support. GDScript avoids experimental mobile C# dependencies. Rendering uses a scene background plus independent interactive object overlays and environmental animation. The GL Compatibility renderer reaches older mobile GPUs. No runtime web service.

mobile/src/simulation.gd: deterministic validated command reducer; independent of Node, rendering, clocks, storage and network. Takes state, command and authored catalog, returns copied next state and events or rejects without mutation. Revision and serial counters scope IDs. Random state is stored. Transaction boundaries include needs/time, items, job stage, money/tax, detection and legal consequences together.

mobile/src/save_store.gd: versioned JSON envelope with payload SHA-256, revision, two rotating verified generations and atomic replacement of the older slot. Flush before replacement. A corrupt or missing newest slot falls back to the highest verified revision. Unsupported future schema opens recovery error rather than resetting or overwriting. v1/v2/v3 migration adds defaults without deleting possessions. Separate app namespace leaves browser citizen databases untouched.

mobile/src/session.gd: local command authority, change signals, persistence boundary, lifecycle hooks. State changes only after successful durable write; failure rolls back visible state and shows an actionable storage notice. mobile/src/main.gd owns navigation, sheets, scenes and object interaction. Authored content in mobile/data/catalog.json, scenes.json and objects.json. `src/presentation.gd` maps authoritative job/inventory state to raster textures and scene variants; it performs no transactions. All hotspot coordinates normalized to the scene canvas.

Item shape: id, kind, label, owner, rightful_owner, serial, origin, condition, acquired_minute, expiry_minute, storage, cold_minutes, legal, metadata, history. Money discoveries retain an evidence instance even after wallet transfer. Stage shape: id, job, stage, garments/crates, inspections, sorted/loaded, detergent/cycle, quality, found objects, risks, worked_minutes. Receipt is a once-settled state transition and immutable bounded event record.

Save schema v4 records identity/appearance, needs, wallet, housing, employment/history, inventory/instances/custody, legal/camp, room upgrades, discoveries, time, events/decisions, settings, random state, command sequence and revision. New fields default during migration. Old browser saves remain supported by the untouched legacy code and are deliberately not reinterpreted as a new-game wallet.

Android uses official export templates, Java 17 and the pinned template’s SDK components (measured minimum API 24, target API 36). Debug APK is for sideload testing, not a signed Play release. Release keystore stays outside version control. See https://docs.godotengine.org/en/stable/tutorials/export/exporting_for_android.html.

Storage keeps legal ownership separate from bag/locker/fridge placement. Relocation is a validated home-only command. Action-time accrues cold_minutes only for unspoiled food physically in a powered fridge, capped at 4320 minutes. Taking food out stops accrual without deleting prior cooling. v3 households retain their former global allowance for existing owned food once during migration; new purchases receive none. No offline cooling/decay tick. Existing schema 3 item serials also recover the serial counter to avoid ID reuse in sparse older records.

Presentation 0.3 keeps schema 4 unchanged. Plain bounded Panels, wrapped buttons and internal ScrollContainers prevent content minimum sizes from expanding interaction sheets beyond the viewport. Backpack paging is ephemeral view state. Washer animation is a masked shader, so pausing, disabling effects or restoring a save cannot repeat a wash, wage or resource charge.
