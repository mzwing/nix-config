# Game Audio in the Browser

Engines have their own mixers (Godot audio buses, Unity's AudioMixer); the bus layout, latency, and spatial rules below still apply there, while the unlock and Web Audio details are browser-only.

## 1. Autoplay unlock (iOS / mobile)

- Create and resume the `AudioContext` synchronously inside the first user gesture (`pointerdown`, `touchend`, `keydown`); an `await` before `resume()` breaks the gesture chain on iOS Safari and leaves audio silent.
- Resume again on `visibilitychange` and `focus`: mobile browsers re-suspend the context when the tab is backgrounded.

## 2. Library

- Never play SFX through `<audio>` or `Audio()` elements: high latency, few simultaneous voices, inconsistent on mobile. They only suit streaming long music (Howler `html5: true`).
- Default to Howler.js (handles the mobile unlock, audio sprites, fades, spatial audio, and voice pooling); drop to raw Web Audio only for custom DSP or sample-accurate scheduling.
- Decode every sound during the loading screen; decoding on first play causes an audible hitch.

## 3. Mixing

- Route every sound through music and SFX gain buses into a master gain from the first commit, with master, music, and SFX sliders and a mute.
- Ramp gain changes over about 10–50ms (`gain.setTargetAtTime(value, audioCtx.currentTime, 0.02)`); assigning `gain.value` mid-play clicks and pops.
- Map 0–1 sliders through `gain = slider * slider` so loudness feels linear.

## 4. Latency and voices

- Schedule rhythm and music cues against `audioCtx.currentTime` (`source.start(when)`), never `setTimeout`.
- Cap concurrent voices and disconnect finished sources in `onended`, or the graph keeps growing.

## 5. Spatial audio and formats

- 2D left/right panning uses a `StereoPannerNode`; keep `PannerNode` (HRTF or equalpower) for 3D, and set its position `AudioParam`s with `.value` or `setValueAtTime` to avoid zipper noise.
- Ship Opus or Vorbis (`.webm`, `.ogg`) with an `.mp3` or `.m4a` fallback for Safari; keep SFX mono (smaller, and it works with panners) and music stereo.
- Pack short SFX into audio sprites. Pitch variation and layering are in [game-feel.md](game-feel.md).
