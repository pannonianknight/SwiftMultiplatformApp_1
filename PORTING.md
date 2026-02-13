# UI Overview — SwiftUI tvOS Configurator

---

## Layout

The root view is `TVOSBoatConfiguratorView` — a `ZStack` with four layers:

```
ZStack
├── Layer 0 — full-screen 3D area (BoatDisplayView placeholder)
├── Layer 1 — left sidebar + right sidebar (always visible)
├── Layer 2 — top bar + bottom cards (hidden when orbit is ON)
└── Layer 3 — selection overlay (appears when a bottom card is tapped)
```

---

## State Objects

### `OrbitManager`
Controls the orbit/rotate mode.

| Property | Type | Description |
|---|---|---|
| `isEnabled` | `Bool` | Orbit is active. When `true`, the UI hides controls and the 3D area captures remote input. |
| `zoomLevel` | `Int` | Discrete zoom step, range `[-3, +3]`, resets to `0` when orbit turns off. |

Toggled by the **Play/Pause** button on the Siri Remote (`.onPlayPauseCommand`).
Zoom changed by **D-pad up/down** on the remote, only while orbit is active.

---

### `TVOSConfigurationManager`
Holds the user's configuration selections.

| Property | Type | Description |
|---|---|---|
| `selectedCamera` | `CameraView` | `.front` `.side` `.rear` `.interior` — driven by top bar buttons |
| `selectedChoices` | `[UUID: String]` | Maps each `ConfigurationOption.id` to the chosen string value |

Configuration options (bottom cards):
- **Hull Color** — White / Blue / Red / Black
- **Deck Style** — Classic / Sport / Luxury
- **Engine** — Standard / Performance / Eco
- **Interior** — Leather / Fabric / Wood
- **Electronics** — Basic / Advanced / Premium

---

### `TouchPanelObserver`
Reads the Siri Remote touch surface via `GameController`.

| Property / Callback | Description |
|---|---|
| `x`, `y` | `Float` — normalised touch position `[-1, +1]`, updated continuously while orbit is active |
| `onZoomIn` / `onZoomOut` | Callbacks fired by D-pad up/down |
| `onClicked` | Callback fired by center button press |

---

## Behaviour Summary

| User action | What happens in the UI |
|---|---|
| Press Play/Pause | Toggles orbit. Controls hide/show with 0.25s animation. |
| Orbit ON | Bottom cards and sidebar buttons disappear. 3D area becomes focusable. |
| Orbit OFF | Controls reappear. Focus moves to first bottom card (0.3s delay for animation). |
| D-pad up/down (orbit ON) | `OrbitManager.zoomLevel` steps ±1 |
| Touch surface (orbit ON) | `TouchPanelObserver.x/y` update every frame |
| Select a bottom card | Opens `SelectionMenuOverlay` for that option |
| Choose in overlay | Updates `selectedChoices[option.id]`, overlay dismisses |
| Top bar camera buttons | Updates `selectedCamera` |
