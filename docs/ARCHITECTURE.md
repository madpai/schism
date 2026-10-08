# Godot 4.7.2 / GDScript / Compatibility renderer

> DO NOT TURN SCHISM BACK INTO A MENU-HEAVY DASHBOARD GAME. The player interacts with places and objects.

Godot is selected for Android lifecycle, touch, 2D scenes, lightweight shaders, headless tests and established export support. GDScript avoids experimental mobile C# dependencies. Rendering uses a scene background plus independent interactive object overlays and environmental animation. The GL Compatibility renderer reaches older mobile GPUs. No runtime web service.

mobile/src/simulation.gd: deterministic validated command reducer; independent of Node, rendering, clocks, storage and network. Takes state, command and authored catalog, returns copied next state and events or rejects without mutation. Revision and serial counters scope IDs. Random state is stored. Transaction boundaries include needs/time, items, job stage, money/tax, detection and legal consequences together.

mobile/src/save_store.gd: versioned JSON envelope with payload SHA-256, revision, two rotating verified generations and atomic replacement of the current pointer. Flush before replacement. Corrupt/missing current loads highest verified revision. Unsupported future schema opens recovery error rather than resetting or overwriting. v1/v2 migration adds defaults without deleting possessions. Separate app namespace leaves browser citizen databases untouched.

mobile/src/session.gd: local command authority, change signals, persistence boundary, lifecycle hooks. State changes only after successful durable write; failure rolls back visible state and shows an actionable storage notice. mobile/src/main.gd owns navigation, sheets, scenes and object interaction. Authored content in mobile/data/catalog.json, scenes.json. All hotspot coordinates normalized to the scene canvas.

Item shape: id, kind, label, owner, rightful_owner, serial, origin, condition, acquired_minute, expiry_minute, legal, metadata, history. Money discoveries retain an evidence instance even after wallet transfer. Stage shape: id, job, stage, garments/crates, inspections, sorted/loaded, detergent/cycle, quality, found objects, risks, worked_minutes. Receipt is a once-settled state transition and immutable bounded event record.

Save schema v3 records identity/appearance, needs, wallet, housing, employment/history, inventory/instances/custody, legal/camp, room upgrades, discoveries, time, events/decisions, settings, random state, command sequence and revision. New fields default during migration. Old browser saves remain supported by the untouched legacy code and are deliberately not reinterpreted as a new-game wallet.

Android uses official export templates, Java 17 and SDK 35. Debug APK is for sideload testing, not a signed Play release. Release keystore stays outside version control. See https://docs.godotengine.org/en/stable/tutorials/export/exporting_for_android.html.
