# Project Guide

This document explains how this Godot project is structured, how its main systems work, and what has already been changed for the current three-character shared-party prototype.

It is written for:
- future development work on this repository
- onboarding new agents quickly
- giving technical context before changing UI, combat logic, or content

## 1. What This Project Is

This is a Godot card-battler template inspired by Slay the Spire.

It is not built as a small scene-local prototype. It is closer to a lightweight framework with:
- autoload singletons for orchestration
- serializable data objects for run state and content
- an action system for card effects and game events
- interceptors for status/relic/power-style modifications
- UI scenes that mostly render and forward input rather than owning game state

The main implication is:
- game logic is often indirect
- state usually lives in data objects, not scene nodes
- cards usually describe behavior through action payloads, not custom scripts

## 2. High-Level Structure

Top-level folders:

- `autoload/`
  Global managers and helpers. This is the main backbone.
- `data/`
  Serializable non-Node data models, both read-only templates and mutable run state.
- `scripts/actions/`
  Reusable gameplay actions such as attack, block, draw, heal, apply status, visit location, open chest, etc.
- `scripts/combatants/`
  Runtime combat entity logic for players and enemies.
- `scripts/ui/`
  Hand, combat HUD, overlays, map, rewards, shop, dialogue, and related input/rendering code.
- `scenes/`
  Godot scenes for the visible game.
- `external/`
  Save data, user data, sprites, and mod-oriented content paths.

## 3. Important Autoloads

Declared in [project.godot](/F:/Godot/Projects/Slay-The-Robot-main/project.godot).

### `autoload/Global.gd`

Central registry and run manager.

Responsibilities:
- stores all loaded read-only content
- creates and owns the current `PlayerData`
- provides helper lookups for characters, cards, artifacts, events, locations, etc.
- starts and ends runs
- now also provides party-aware helper methods for the shared-party prototype

Important functions:
- `start_run(...)`
- `start_party_run(...)`
- `get_player()`
- `get_players()`
- `get_living_players()`
- `get_player_by_party_index(...)`
- `get_card_owner_player(...)`
- `get_context_party_member(...)`

### `autoload/ActionHandler.gd`

Executes actions in queues/stacks.

Responsibilities:
- add actions
- process them in order
- support async actions
- support interruptions, delays, and queue nesting

This is the runtime execution engine for most gameplay effects.

### `autoload/ActionGenerator.gd`

Convenience layer that turns dictionaries of action data into instantiated `BaseAction` objects.

This is used by:
- cards
- events
- shops
- rewards
- artifacts
- status effects
- map traversal

### `autoload/Random.gd`

Deterministic random helper functions.

Important uses:
- card reward drafting
- shop card drafting
- artifact rewards
- consumables
- array shuffling

This file now also contains party-aware random card drafting helpers.

### `autoload/Signals.gd`

The project-wide event bus.

Most systems communicate through signals rather than direct method calls.

## 4. Data Model

The project separates read-only template data from mutable runtime state.

### Core Base Types

- `SerializableData`
  Save/load capable exported-field data object.
- `PrototypeData`
  Serializable data that supports duplication into mutable runtime instances.

### Read-Only Template Data

Examples:
- `CharacterData`
- `CardData`
- `EnemyData`
- `ArtifactData`
- `ActData`
- `EventData`
- `StatusEffectData`

These are defined once and usually loaded or generated as prototypes.

### Mutable Runtime Data

Examples:
- `PlayerData`
- `LocationData`
- `ShopData`
- `CombatStatsData`
- `PartyMemberData`

These are the current run state.

## 5. Main Runtime State

### `data/prototype/PlayerData.gd`

`PlayerData` is the central mutable run object.

Originally it assumed a single player character.

It still contains legacy singleton fields such as:
- `player_health`
- `player_health_max`
- `player_block`
- `player_character_object_id`

But for the current prototype it now also supports:
- `player_party_members: Array[PartyMemberData]`

Shared run-level state remains here:
- deck
- draw/discard/exhaust/hand
- energy
- money
- consumables
- artifacts
- map progression
- current act and location
- reward settings

### `data/mutable/PartyMemberData.gd`

This was added for the three-character prototype.

It stores per-character state such as:
- party index
- owning character id
- display name
- health / max health
- combat block
- reward draft packs
- reward draft blacklist / whitelist
- rare-card pity modifier state
- per-character reward caches

This is the main data split that makes the shared-party system possible.

## 6. Cards and Ownership

### `data/prototype/CardData.gd`

Cards now carry owner metadata:
- `card_owner_party_index`
- `card_owner_character_object_id`

That ownership is used to determine:
- which combatant is considered the acting source when playing the card
- which status effects / interceptors modify it
- which party member should receive generated or purchased cards
- which reward pool a card belongs to conceptually

### Important Rule

The deck is shared.

Ownership is per card.

That means:
- the hand is shared
- draw/discard/exhaust are shared
- energy is shared
- but card effects should resolve through the owner’s combatant

## 7. Action System

### `scripts/actions/BaseAction.gd`

Every gameplay effect is modeled as an action.

Common fields:
- `parent_combatant`
- `card_play_request`
- `targets`
- `values`
- `time_delay`
- `parent_action`

### Value Resolution

`BaseAction.get_action_value(...)` resolves values in this order:
- action-local values
- card play request values
- card data values
- player global values
- fallback default

This is a key technique in the project because it allows a small set of generic action scripts to be reused across many card designs.

### Typical Card Flow

1. A card is clicked in [Hand.gd](/F:/Godot/Projects/Slay-The-Robot-main/scripts/ui/Hand.gd).
2. A `CardPlayRequest` is built.
3. The owner combatant is resolved from the card.
4. `ActionGenerator` creates the card play actions.
5. `ActionHandler` executes them.
6. Interceptors can modify values during execution.
7. Signals update UI and other systems.

## 8. Interceptors and Status-Like Behavior

Interceptors are the project’s main extension mechanism for:
- powers
- status effects
- relic-like behavior
- run modifiers

They let effects modify actions without rewriting the actions themselves.

This is why the party prototype fits the existing design reasonably well:
- combatants already own their own interceptors
- if the card owner is resolved correctly, owner-specific modifications naturally work

## 9. Combat Runtime

### Main Files

- [Combat.gd](/F:/Godot/Projects/Slay-The-Robot-main/scripts/ui/Combat.gd)
- [Hand.gd](/F:/Godot/Projects/Slay-The-Robot-main/scripts/ui/Hand.gd)
- [Player.gd](/F:/Godot/Projects/Slay-The-Robot-main/scripts/combatants/Player.gd)
- [Enemy.gd](/F:/Godot/Projects/Slay-The-Robot-main/scripts/combatants/Enemy.gd)

### Current Combat Model

The original template assumes:
- one player combatant
- many enemies

The current prototype backend adapts this by:
- keeping the visible primary player node
- spawning hidden `Player` proxy combatants for additional party members
- resolving card ownership against those proxy players
- letting enemies choose random living allies

This means the backend can already support:
- separate HP per ally
- separate block per ally
- separate statuses/interceptors per ally
- shared hand/deck/energy
- per-owner card behavior

But the full UI for three visible characters is not implemented yet.

## 10. Current Three-Character Prototype Rules

The current backend is implementing this design:

- three player characters in one shared party
- shared hand
- shared deck / draw / discard / exhaust
- shared turn
- shared energy
- cards have owners
- owner’s statuses and interceptors affect that card
- self-target cards affect the owner
- dead character cards are removed from combat piles for the rest of the fight
- all party members dead = loss
- dead members revive to 1 HP after combat if the run continues
- enemies target random living party members

## 11. What Has Already Been Changed For The Party Prototype

This section is important for future agents.

### Run Start

[Global.gd](/F:/Godot/Projects/Slay-The-Robot-main/autoload/Global.gd) now supports:
- `start_party_run(...)`

It:
- creates a shared run state
- creates one `PartyMemberData` per selected character
- merges starting decks into one shared permanent deck
- tags every card with its owner
- merges artifact packs and starting artifacts

### Combatants

[Player.gd](/F:/Godot/Projects/Slay-The-Robot-main/scripts/combatants/Player.gd):
- supports `party_member_index`
- reads and writes HP/block from `PartyMemberData`
- emits death per member
- now calculates incoming intent damage only for enemies targeting that player

[Combat.gd](/F:/Godot/Projects/Slay-The-Robot-main/scripts/ui/Combat.gd):
- creates hidden proxy players for additional party members
- runs status phases over all living players
- uses party-aware defeat logic

[Enemy.gd](/F:/Godot/Projects/Slay-The-Robot-main/scripts/combatants/Enemy.gd):
- stores `enemy_intent_target_party_member_index`
- rolls a random living player target
- previews and executes against that chosen ally

### Hand / Card Play

[Hand.gd](/F:/Godot/Projects/Slay-The-Robot-main/scripts/ui/Hand.gd):
- resolves card owner combatant before playing cards
- uses owner combatant for draw/discard/exhaust/retain/right-click/end-of-turn card actions
- removes dead-owner cards from combat piles and queue

### Card Ownership Propagation

Ownership is now preserved or assigned in several places, including:
- `PlayerData.generate_combat_deck()`
- `PlayerData.add_card_to_deck(...)`
- `ActionCreateCards`
- `ActionAddCardsToHand`
- `ActionAddCardsToDeck`
- `ActionAddCardsToDraw`
- random draft generation paths

### Rewards

[Random.gd](/F:/Godot/Projects/Slay-The-Robot-main/autoload/Random.gd):
- party reward drafts now choose a random party member per card slot
- draft from that member’s reward pool
- tag the card with that owner

### Shops

[ShopData.gd](/F:/Godot/Projects/Slay-The-Robot-main/data/mutable/ShopData.gd):
- party shop cards now choose a random party member per shop card slot
- draft from that member’s pool
- preserve owner metadata on the generated card

As a result:
- buying a card keeps that owner
- adding the bought card to the deck preserves that ownership

### Validators

Some validators are now owner-aware, including:
- `ValidatorPlayerHealth`
- `ValidatorCardDraftable`

These now try to resolve the acting party member instead of always consulting the legacy single-player fields.

## 12. Important Compatibility Layer

The project still contains a transitional compatibility layer.

`PlayerData` still mirrors the primary party member into legacy fields:
- `player_health`
- `player_health_max`
- `player_block`
- `player_character_object_id`

Why this exists:
- many older systems still expect a single player
- it keeps the game running while the backend is being converted incrementally

Implication:
- if something still behaves like “character 0 is the real player,” it is usually because that code path still reads the legacy mirrored fields

## 13. Systems Still Mostly Single-Player In UI

The backend is ahead of the UI.

Not fully implemented yet:
- three visible player combat panels
- ally targeting by click/hover
- owner icons on cards
- owner labels in rewards and shops
- new run UI for choosing multiple characters
- deck viewer filters by owner
- explicit enemy intent UI for which ally is being targeted

The backend is currently designed so those UI changes can be layered on top later.

## 14. Current Design Assumptions

These are the current working assumptions and should be preserved unless intentionally changed:

- “self” means the owner of the card
- support cards do not yet target other allies
- block cards still block the owner only
- healing/health validators are owner-based unless otherwise specified
- relics/artifacts are effectively global run-side effects for now
- shop cards and random rewards are random across participating character pools

## 15. Good Files To Read First

If a new agent needs to understand the project quickly, start here:

- [project.godot](/F:/Godot/Projects/Slay-The-Robot-main/project.godot)
- [autoload/Global.gd](/F:/Godot/Projects/Slay-The-Robot-main/autoload/Global.gd)
- [autoload/ActionHandler.gd](/F:/Godot/Projects/Slay-The-Robot-main/autoload/ActionHandler.gd)
- [autoload/ActionGenerator.gd](/F:/Godot/Projects/Slay-The-Robot-main/autoload/ActionGenerator.gd)
- [autoload/Random.gd](/F:/Godot/Projects/Slay-The-Robot-main/autoload/Random.gd)
- [data/prototype/PlayerData.gd](/F:/Godot/Projects/Slay-The-Robot-main/data/prototype/PlayerData.gd)
- [data/mutable/PartyMemberData.gd](/F:/Godot/Projects/Slay-The-Robot-main/data/mutable/PartyMemberData.gd)
- [data/prototype/CardData.gd](/F:/Godot/Projects/Slay-The-Robot-main/data/prototype/CardData.gd)
- [scripts/actions/BaseAction.gd](/F:/Godot/Projects/Slay-The-Robot-main/scripts/actions/BaseAction.gd)
- [scripts/ui/Combat.gd](/F:/Godot/Projects/Slay-The-Robot-main/scripts/ui/Combat.gd)
- [scripts/ui/Hand.gd](/F:/Godot/Projects/Slay-The-Robot-main/scripts/ui/Hand.gd)
- [scripts/combatants/Player.gd](/F:/Godot/Projects/Slay-The-Robot-main/scripts/combatants/Player.gd)
- [scripts/combatants/Enemy.gd](/F:/Godot/Projects/Slay-The-Robot-main/scripts/combatants/Enemy.gd)

## 16. Recommended Mental Model For Future Work

When modifying the project, think in these layers:

1. Run state
   Usually `PlayerData` and `PartyMemberData`.
2. Runtime combatants
   `Player` and `Enemy` nodes that expose combat behavior and interceptors.
3. Actions
   Reusable effect scripts that do the work.
4. Signals
   State-change notifications across systems.
5. UI
   Rendering and input only.

For the current party prototype, the most important question in any new change is:

`who is the acting owner of this effect?`

If that answer is wrong, the rest of the behavior usually becomes wrong too.

## 17. Known Open Areas

These are not necessarily bugs, but unfinished areas:

- ally-targeting cards and UI are not implemented
- shops use correct owner tagging, but the visual shop UI does not yet show owner
- card rewards use correct owner tagging, but reward UI does not yet show owner
- legacy single-player fields still exist as compatibility state
- some older systems may still implicitly mean “primary member”

## 18. If You Are Another Agent

Before changing anything:

1. Read this file.
2. Read the files listed in section 15.
3. Check whether the intended behavior is:
   - shared run state
   - per-card owner state
   - per-party-member combat state
4. Avoid removing the legacy compatibility layer unless you are intentionally doing a full migration.
5. Be careful with any code path that still assumes `Global.get_player()` means “the only player.”

## 19. Summary

This repository is:
- a framework-like Godot card battler
- centered around actions, interceptors, and serializable data
- currently being adapted from a one-player model into a three-character shared-party model

The shared-party backend already supports:
- owned cards
- per-character HP/block/status/interceptors
- shared deck/hand/energy
- party-aware rewards
- party-aware shop cards
- random enemy targeting among living allies

The biggest remaining work is mostly UI and input exposure, not the core backend model.
