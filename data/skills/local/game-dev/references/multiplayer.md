# Multiplayer

Pick the topology from who plays together, not from what is easiest to code.

| Topology | Fits | Trust |
|---|---|---|
| Peer-to-peer mesh (WebRTC data channels) | 2–8 friends in co-op or casual realtime: shared cursors, drawing, party games | none: every peer runs the rules and can lie |
| Relay server (forwards messages, holds no state) | the same, when peers can't connect directly | none |
| Authoritative server (clients send inputs, the server simulates) | competitive play, strangers, persistent worlds, hidden information | the server decides |

Never put competitive, ranked, or cheat-sensitive play on P2P. Peers also learn each other's IP addresses while connecting, so P2P is for people who chose to play together.

## Peer-to-peer

- A full mesh costs O(N²) connections; cap rooms at about 8 peers.
- Roughly 10–20% of peer pairs sit behind NATs that block a direct connection. Without a TURN relay those pairs fail; show each peer's connection state in the UI instead of hanging.
- Connecting needs signaling: something that passes session descriptions and ICE candidates between peers, such as a WebSocket or a polled HTTP endpoint backed by a store. Only the handshake goes through it; game data flows peer to peer.
- A room is just a rendezvous key. Use one shared room when everyone on the site plays together, and a short code in the URL for private lobbies.

## Channels

- Continuously refreshed state (positions, cursors) goes on an unreliable, unordered channel at about 20 sends per second; stale packets drop and clients interpolate between snapshots for smooth motion.
- Events that must arrive exactly once (a hit, a pickup, chat) go on a reliable, ordered channel. Never stream game-rate state on it: one lost packet stalls everything behind it.

## Joining and leaving

- Late joiners know nothing. When a new peer appears, exactly one existing peer sends it the current state: the one with the smallest id among the peers that were already there, so two simultaneous joiners are neither answered twice nor missed.
- Peers vanish without saying goodbye (closed tab, sleep, lost network). Treat a peer missing from the roster, or silent past a timeout, as gone and remove its entities.

## Authoritative servers

- Run the simulation on a fixed tick; clients send inputs, not results.
- Clients predict their own movement and reconcile when the server's state arrives; other players are interpolated slightly in the past.
- Validate everything a client sends, scores and saves included.
- Deterministic lockstep needs every machine to run the same random number generator in the same order ([procedural-generation.md](procedural-generation.md)).

## Sources

- Gabriel Gambetta, Fast-Paced Multiplayer: https://www.gabrielgambetta.com/client-server-game-architecture.html
- Glenn Fiedler, Gaffer On Games: https://gafferongames.com
- MDN, Using WebRTC data channels: https://developer.mozilla.org/en-US/docs/Web/API/WebRTC_API/Using_data_channels
