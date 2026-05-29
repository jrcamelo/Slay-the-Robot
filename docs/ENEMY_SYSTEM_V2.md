# Enemy System V2

This document explains how enemies currently work in the project after the V2 redesign.

The goal of this file is to give a future enemy-editor implementation a clear mental model of:

- what data exists
- what runtime state exists
- how stage flow works
- how previews work
- how reactive behavior works
- how targeting works
- how difficulty overrides work
- what must be validated in authoring tools

This document describes the current implementation in code, including a few prototype-specific simplifications and behaviors.

## High-Level Model

An enemy is made of:

- core stats and metadata
- a planned stage sequence
- optional reactive stages that can temporarily replace the planned stage
- one or more intent variants inside each stage
- optional extra actions attached to a stage
- optional difficulty overrides that patch the enemy or specific stages

The core idea is:

- a `stage` means "what this enemy is planning to do this turn"
- an `intent variant` means "which version of that stage is currently active"
- a `reactive stage` means "replace the normal planned stage if these conditions match"

The sequence system and the live intent system are separate:

- sequence progression is handled by `opening_stage_id` and each stage's `next_stage_id`
- live intent changes are handled by multiple intent variants inside the same stage

This is why a stage can stay the same while its visible preview changes during the player turn.

## Main Files

Core data:

- [EnemyData.gd](/F:/Godot/Projects/Slay-The-Robot-main/data/prototype/EnemyData.gd:1)
- [EnemyStageData.gd](/F:/Godot/Projects/Slay-The-Robot-main/data/prototype/EnemyStageData.gd:1)
- [EnemyReactiveStageData.gd](/F:/Godot/Projects/Slay-The-Robot-main/data/prototype/EnemyReactiveStageData.gd:1)
- [EnemyIntentVariantData.gd](/F:/Godot/Projects/Slay-The-Robot-main/data/prototype/EnemyIntentVariantData.gd:1)
- [EnemyIntentData.gd](/F:/Godot/Projects/Slay-The-Robot-main/data/prototype/EnemyIntentData.gd:1)
- [EnemyDifficultyOverrideData.gd](/F:/Godot/Projects/Slay-The-Robot-main/data/prototype/EnemyDifficultyOverrideData.gd:1)
- [EnemyStageOverrideData.gd](/F:/Godot/Projects/Slay-The-Robot-main/data/prototype/EnemyStageOverrideData.gd:1)
- [EnemyReactiveStageOverrideData.gd](/F:/Godot/Projects/Slay-The-Robot-main/data/prototype/EnemyReactiveStageOverrideData.gd:1)
- [EnemyIntentOverrideData.gd](/F:/Godot/Projects/Slay-The-Robot-main/data/prototype/EnemyIntentOverrideData.gd:1)

Runtime:

- [Enemy.gd](/F:/Godot/Projects/Slay-The-Robot-main/scripts/combatants/Enemy.gd:1)
- [Combat.gd](/F:/Godot/Projects/Slay-The-Robot-main/scripts/ui/Combat.gd:227)
- [EnemyContainer.gd](/F:/Godot/Projects/Slay-The-Robot-main/scripts/ui/EnemyContainer.gd:1)
- [Player.gd](/F:/Godot/Projects/Slay-The-Robot-main/scripts/combatants/Player.gd:127)

Validator infrastructure:

- [BaseValidator.gd](/F:/Godot/Projects/Slay-The-Robot-main/scripts/validators/BaseValidator.gd:1)
- [Scripts.gd](/F:/Godot/Projects/Slay-The-Robot-main/autoload/Scripts.gd:142)

## Top-Level Enemy Data

`EnemyData` currently contains:

- `enemy_object_id`
- `enemy_name`
- `enemy_texture_path`
- `enemy_health`
- `enemy_health_max`
- `enemy_poise`
- `enemy_poise_max`
- `enemy_block`
- `enemy_actions_on_death`
- `enemy_type`
- `enemy_is_minion`
- `opening_stage_id`
- `stages`
- `reactive_stages`
- `enemy_initial_status_effects`
- `difficulty_overrides`

Notes:

- `enemy_block` is mutable runtime state stored directly on the enemy data instance.
- `enemy_health` and `enemy_poise` are mutable runtime values.
- `stages` and `reactive_stages` are authored data.
- `difficulty_overrides` are applied to the duplicated enemy prototype before the enemy node is initialized.

## Stage Model

`EnemyStageData` represents one planned enemy turn.

Fields:

- `object_id`
- `label`
- `intents`
- `extra_actions`
- `next_stage_id`

Meaning:

- `object_id` is the stable stage id used by references and difficulty patching.
- `label` is display/editor text.
- `intents` is an array of intent variants. The highest-priority matching variant wins.
- `extra_actions` are generic action payloads that run alongside the stage's native intent.
- `next_stage_id` is the base sequence continuation.

Important authoring rule:

- every stage must have a valid `next_stage_id`
- every stage must have at least one intent variant
- every stage should have an unconditional fallback variant with no conditions

## Intent Variant Model

`EnemyIntentVariantData` represents one possible resolved intent for a stage.

Fields:

- `conditions`
- `intent`
- `priority`

Meaning:

- `conditions` is an array of validator payload dictionaries
- `intent` is the native enemy intent payload
- `priority` decides which matching variant wins

The current resolution rule is:

- evaluate variants in the stage
- discard variants whose conditions fail
- choose the variant with the highest numeric priority
- if none match, fall back to the first intent in the array if it exists

Current validation expectation:

- author a default variant with no conditions
- give more specific variants higher priority than the default

## Native Intent Model

`EnemyIntentData` represents the native enemy intent.

Fields:

- `damage`
- `block`
- `number_of_attacks`
- `targeting_rule`
- `target_count`
- `allow_repeat_targets`

This model is intentionally enemy-native. It is not authored as generic action payloads.

Current built-in targeting rules:

- `random_living_player`
- `lowest_current_health_player`
- `highest_current_health_player`
- `lowest_health_percent_player`
- `highest_health_percent_player`
- `all_living_players`
- `random_distinct_players`

Runtime notes:

- `damage` and `number_of_attacks` are previewed through the action interception system so modifiers still affect the displayed preview.
- `block` is shown as part of the resolved stage data but is executed from the raw authored intent value.
- execution uses the raw authored intent data, not the preview-adjusted values, so interceptors are not double-applied.

## Reactive Stage Model

`EnemyReactiveStageData` represents an interrupt stage that can replace the current planned stage.

Fields:

- `object_id`
- `label`
- `priority`
- `conditions`
- `intents`
- `extra_actions`
- `resume_mode`
- `resume_stage_id`

Current resume modes:

- `resume_previous`
- `jump_to_stage`
- `start_new_sequence`

Current runtime meaning:

- `resume_previous`: after the reactive stage executes, continue using the base stage's `next_stage_id`
- `jump_to_stage`: after the reactive stage executes, set the planned stage to `resume_stage_id`
- `start_new_sequence`: same runtime behavior as `jump_to_stage`, but intended to communicate a phase shift

Reactive-stage resolution rule:

- evaluate all reactive stages every time enemy intent is refreshed
- choose the highest-priority matching reactive stage
- if none match, use the planned base stage

Reactive stages are exclusive. They do not stack.

## Difficulty Override Model

`EnemyDifficultyOverrideData` is patch-based.

Fields:

- `difficulty_level`
- `top_level_overrides`
- `stage_overrides`
- `reactive_stage_overrides`

Stage patch types:

- `EnemyStageOverrideData`
- `EnemyReactiveStageOverrideData`
- `EnemyIntentOverrideData`

Current patch capabilities:

- override top-level enemy fields like health, poise, or type
- override stage fields by `stage_id`
- override reactive-stage fields by `reactive_stage_id`
- patch intent values by variant index within a stage or reactive stage
- patch `extra_actions`
- optionally override intent variant priority
- optionally patch intent-variant conditions

Current implementation detail:

- stage and reactive-stage intent patches reference variants by `variant_index`, not by intent id
- this is simple for now but is less editor-friendly than a future stable variant id system

Editor implication:

- if the editor supports reordering variants, it should treat variant order carefully because difficulty patching currently uses array index

## Runtime Enemy State

The enemy node stores additional runtime-only state in [Enemy.gd](/F:/Godot/Projects/Slay-The-Robot-main/scripts/combatants/Enemy.gd:1).

Important runtime fields:

- `planned_stage_id`
- `previous_executed_stage_id`
- `planned_stage_started_turn_count`
- `stage_id_to_execution_count`
- `enemy_active_stage_id`
- `enemy_active_base_stage_id`
- `enemy_active_reactive_stage_id`
- `enemy_active_stage_is_reactive`
- `enemy_active_stage_extra_actions`
- `enemy_active_intent_data`
- `enemy_intent_attack_damage`
- `enemy_intent_number_of_attacks`
- `enemy_intent_block`
- `enemy_intent_target_party_member_indices`
- `intent_preview_hidden`
- `cached_random_target_signature`
- `cached_random_target_party_member_indices`

Meaning:

- `planned_stage_id` is the base sequence stage the enemy is currently on
- `previous_executed_stage_id` is the last stage that actually executed
- `planned_stage_started_turn_count` tracks when the current planned stage began
- `stage_id_to_execution_count` counts how many times each stage has executed
- `enemy_active_*` fields describe the currently resolved stage for this moment
- `enemy_intent_*` fields describe the currently resolved preview data
- `intent_preview_hidden` suppresses the preview during enemy-turn execution
- `cached_random_target_*` keeps random targeting stable during mid-turn refreshes

## Base Sequence Flow

Base sequence flow is simple:

1. At initialization, `planned_stage_id = opening_stage_id`.
2. The enemy resolves its active stage from that planned stage, possibly replaced by a reactive stage.
3. When the enemy executes, it performs the resolved stage.
4. After execution, it advances the planned stage.

Normal advancement:

- set `planned_stage_id` to the base stage's `next_stage_id`

Reactive advancement:

- if the active stage was reactive and `resume_mode = resume_previous`, still advance using the base stage's `next_stage_id`
- if the active stage was reactive and `resume_mode = jump_to_stage`, set `planned_stage_id = resume_stage_id`
- if the active stage was reactive and `resume_mode = start_new_sequence`, also set `planned_stage_id = resume_stage_id`

The main point is:

- the planned stage is the sequence backbone
- the reactive stage is a temporary override unless it explicitly changes continuation

## Intent Refresh Timing

Intent resolution currently happens during the player turn.

Enemy intent refresh is triggered by:

- player turn start
- energy changes
- card played
- card queue refunded
- player health changes
- combatant damaged
- player death animation finished
- enemy death animation finished
- party member removed
- status changes from `BaseCombatant`

This allows a stage's intent variant to change live as conditions change.

Typical example:

- one stage
- low energy variant
- medium energy variant
- high energy variant

The stage stays the same, but the resolved intent can change as the player's energy changes.

## Preview Lifecycle

Intent preview is intentionally a player-turn UI only.

Current behavior:

- on player turn start, enemies refresh and show previews
- during player turn, previews may update live as conditions change
- right before an enemy acts, its preview is hidden
- while enemies are acting, previews remain hidden
- previews do not immediately switch to the next planned stage during enemy execution
- on the next player turn start, previews are recomputed and shown again

This is implemented with `intent_preview_hidden` in [Enemy.gd](/F:/Godot/Projects/Slay-The-Robot-main/scripts/combatants/Enemy.gd:24).

Editor implication:

- the editor should treat the preview as "what the player sees during their turn", not "always-visible current enemy state"

## Random Targeting Behavior

Random targeting is sticky during a planned stage.

Current implemented rule:

- if an intent uses a random targeting rule, the chosen targets are cached
- the enemy keeps the same random target choice during mid-turn refreshes
- the random target is rerolled only when:
  - the enemy advances to a new planned stage
  - a cached target is no longer alive

This avoids previews jumping to different random players every time a card or action changes the game state.

Current implementation detail:

- cache identity includes the planned stage id, targeting rule, target count, repeat flag, and reactive stage id

## Target Resolution Details

Target resolution happens in [Enemy.gd](/F:/Godot/Projects/Slay-The-Robot-main/scripts/combatants/Enemy.gd:213).

Current targeting semantics:

- `all_living_players`: returns all living players
- `lowest_current_health_player`: sorts by current health ascending
- `highest_current_health_player`: sorts by current health descending
- `lowest_health_percent_player`: sorts by health percentage ascending
- `highest_health_percent_player`: sorts by health percentage descending
- `random_distinct_players`: shuffled unique targets
- `random_living_player`: random targets, distinct or repeated depending on `allow_repeat_targets`

Tie-breaking for sorted targeting:

- if two players have the same compared value, lower `party_member_index` wins

Important note:

- target resolution is used for preview
- execution then uses those resolved targets
- this keeps final behavior aligned with what the player saw at the end of their turn

## Extra Actions

Stages and reactive stages can carry `extra_actions`.

These still use the existing action payload format:

- array of action dictionaries
- same system used elsewhere in the project

Examples:

- apply status
- summon enemies
- validator-based side branches
- debug actions
- custom UI actions

Current behavior:

- `extra_actions` are executed together with the native intent during enemy turn
- native intent remains the main authored intent model
- `extra_actions` are an extension point, not the main authoring structure

## Enemy Turn Execution Flow

Enemy turn execution currently works like this in [Combat.gd](/F:/Godot/Projects/Slay-The-Robot-main/scripts/ui/Combat.gd:227):

1. For each living enemy:
2. Run enemy start-of-turn status effects.
3. Hide that enemy's intent preview.
4. Resolve the current active stage and intent again.
5. Resolve targets again.
6. Build action payloads from:
   - stage `extra_actions`
   - raw intent damage and number of attacks
   - raw intent block
7. Execute the actions.
8. Advance the planned stage.
9. Run enemy end-of-turn status effects.

Notes:

- previews are hidden before step 4
- execution still uses the resolved stage/intents behind the scenes
- stage advancement happens after execution, not at preview time

## Validation Rules in Code

`EnemyData.validate_enemy_behavior()` currently validates:

- `opening_stage_id` exists
- stage ids are non-empty and unique
- reactive stage ids are non-empty and unique
- reactive stage ids do not collide with base stage ids
- every stage has a non-empty valid `next_stage_id`
- every reactive stage has a valid `resume_mode`
- every reactive stage that is not `resume_previous` has a valid `resume_stage_id`
- every stage and reactive stage has at least one intent variant
- every stage and reactive stage has at least one unconditional intent variant
- every intent passes basic intent validation
- difficulty override stage references point to real stages
- difficulty override reactive-stage references point to real reactive stages
- difficulty intent variant indices are in range

Intent-level validation in `EnemyIntentData` currently checks:

- `damage >= 0`
- `block >= 0`
- `number_of_attacks >= 0`
- `targeting_rule` is supported
- `target_count > 0` unless the rule is `all_living_players`

Current validation limitations:

- it does not yet detect duplicate priorities
- it does not yet deeply validate the meaning of every validator payload
- it does not yet verify whether a given targeting rule and target count combination is design-sensible beyond the basic structural check

## Condition System

Conditions are arrays of validator payload dictionaries.

Example shape:

```gdscript
[
	{
		"VALIDATOR_PLAYER_CURRENT_ENERGY": {
			"operator": ">=",
			"comparison_value": 4
		}
	},
	{
		"VALIDATOR_PLAYER_CURRENT_ENERGY": {
			"operator": "<=",
			"comparison_value": 6
		}
	}
]
```

Semantics:

- every validator in the array must pass
- if any validator fails, the condition list fails

Runtime implementation detail:

- enemy stage-condition validation uses `validator.validate(null, null, validator_values)`
- the enemy node injects `_source_combatant = self`
- target-aware validators can also accept `_targets`

This is why stage/reactive conditions can reuse the normal validator system without manufacturing fake actions.

## Enemy-Specific Validators Available for Authoring

Previously existing:

- `VALIDATOR_ENEMY_TYPE`
- `VALIDATOR_ENEMY_ATTACKING`
- `VALIDATOR_ENEMY_BROKEN_POISE`
- `VALIDATOR_ENEMY_HALF_POISE`
- `VALIDATOR_ENEMY_HALF_HEALTH`
- `VALIDATOR_SOURCE_HAS_STATUS_EFFECT`
- `VALIDATOR_TARGET_HAS_STATUS_EFFECT`

Added for the V2 system:

- `VALIDATOR_SOURCE_CURRENT_HEALTH`
- `VALIDATOR_SOURCE_HEALTH_PERCENT`
- `VALIDATOR_PLAYER_CURRENT_ENERGY`
- `VALIDATOR_CURRENT_PLANNED_STAGE_ID`
- `VALIDATOR_PREVIOUS_EXECUTED_STAGE_ID`
- `VALIDATOR_TURNS_SINCE_CURRENT_STAGE_STARTED`
- `VALIDATOR_STAGE_EXECUTION_COUNT`
- `VALIDATOR_LIVING_ALLY_MINION_COUNT`

See:

- [Scripts.gd](/F:/Godot/Projects/Slay-The-Robot-main/autoload/Scripts.gd:145)
- individual validator files in [scripts/validators](/F:/Godot/Projects/Slay-The-Robot-main/scripts/validators)

## Current Authoring Pattern for the Prototype

The current prototype assumes a common pattern:

- one stage usually represents one turn in the sequence
- many stages will contain multiple intent variants based on player energy

This means:

- the sequence remains easy to read
- you do not need a different stage for every energy band
- the same stage can have low-energy, medium-energy, and high-energy variants

Recommended authoring pattern:

- create one unconditional default variant
- create one or more higher-priority energy-gated variants
- use `VALIDATOR_PLAYER_CURRENT_ENERGY` for the energy checks

Example mental model:

- stage `"pressure_turn"`
- if energy `<= 3`, attack one target
- if energy `4..6`, attack two targets
- if energy `>= 7`, attack three targets

The planned stage remains `"pressure_turn"` the whole time.

## Current Placeholder Enemy Content

Current enemy `.tres` files under [content/enemies](/F:/Godot/Projects/Slay-The-Robot-main/content/enemies) have already been migrated to the V2 schema.

Notes about current placeholder content:

- many simple enemies currently use a two-stage loop based on the old default attack-state values
- `BigAttackEnemy` was converted into a three-stage deterministic loop that preserves its special side effect
- `Act1Boss` preserves its summon behavior as stage `extra_actions`
- difficulty patches currently only modify top-level values in the placeholder content

This content is valid enough to drive the runtime and to act as examples for an editor, but it is still placeholder design content.

## Editor Requirements Suggested by the Current Implementation

An editor should ideally expose:

- top-level enemy metadata
- a stage list
- a reactive-stage list
- stable ids for every stage and reactive stage
- per-stage intent-variant list
- per-variant conditions and priority
- per-variant intent fields
- stage `extra_actions`
- difficulty override patches

The editor should also make these relationships obvious:

- `opening_stage_id`
- stage `next_stage_id`
- reactive-stage `resume_mode`
- reactive-stage `resume_stage_id`

Because the runtime is id-based, the editor should prefer id-driven workflows over index-driven workflows wherever possible.

Particularly important:

- stages are stable by `object_id`
- reactive stages are stable by `object_id`
- intent variants are currently only patchable by index, so the editor should either preserve variant order carefully or introduce future variant ids as a follow-up improvement

## Good Editor UX Ideas Based on This System

An editor would likely be easiest to use if it presents:

- one panel/card per stage
- one subpanel per intent variant
- one list for reactive stages with visible priority and resume behavior
- clear "default variant" highlighting
- quick targeting summaries like:
  - `Attack 10`
  - `Attack 4 x 2`
  - `Block 8`
  - `Target: Lowest HP`
  - `Target: 2 random distinct players`

Useful derived summaries:

- visible stage sequence graph from `next_stage_id`
- visible "reactive overrides" list sorted by priority
- visible "difficulty changes" summary per difficulty level

Validation UX should surface:

- missing default intent variant
- bad stage links
- bad reactive resume links
- invalid difficulty patch references
- unsupported targeting rules

## Known Implementation Limitations

This document describes the current implementation, not the ideal future endpoint.

Current limitations include:

- intent variant difficulty patching is index-based, not id-based
- preview currently shows one target portrait texture even when multiple targets are resolved
- the intent UI still fundamentally comes from the old single-target visual widget
- there is no dedicated native UI yet for showing multi-target targeting semantics
- difficulty validation does not fully inspect every possible override field
- there is no standalone enemy-editor schema/export service yet

These do not block editor design, but the editor should be built with them in mind.

## Recommended Follow-Up Improvements

If the editor is going to become a serious tool, these follow-ups would make the runtime model easier to work with:

- add stable ids to intent variants so difficulty patches do not rely on array index
- add richer preview metadata for UI summaries, especially multi-target previews
- add an explicit editor-facing validation/report service instead of relying only on `push_error`
- add a dedicated target-preview formatter at the data/service layer
- add id-based references for extra-action patch targets if those become more complex

## Short Mental Model

If another chat only needs the simplest possible summary:

- A stage is one planned enemy turn.
- Each stage points to the next stage in the base sequence.
- A stage can have several intent variants, and the highest-priority matching one is the current preview/action.
- Reactive stages can temporarily replace the current planned stage.
- After a reactive stage executes, its resume mode decides how sequence progression continues.
- Difficulty overrides patch specific parts of the enemy instead of replacing the whole enemy.
