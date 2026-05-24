# Card Editor Backend

This project now includes a backend-oriented card editor foundation centered around:

- `scripts/tools/card_editor/CardEditorService.gd`
- `scripts/tools/card_editor/CardEditorSession.gd`
- `scripts/tools/card_editor/CardEditorPathUtils.gd`
- `scripts/tools/card_editor/CardEditorSchema.gd`
- `scripts/tools/card_editor/CardEditorPresets.gd`
- `scripts/tools/ScriptEditorMetadataRegistry.gd`

## What It Supports

- Discovery across both `res://content` and `res://triage`
- Library metadata for filtering/grouping:
  - source bucket (`content` vs `triage`)
  - owner bucket (`generic`, `character/red`, etc.)
  - color, rarity, type, kind, target usage
  - search blob for text search
- Session save policies:
  - managed content path
  - managed triage path
  - manual override path
- Draft-first workflow:
  - blank session creation
  - preset-backed session creation
  - duplicate existing cards into triage-friendly sessions
  - promote triage cards into canonical content paths
- Metadata-backed action and validator editing:
  - dropdown-friendly action/validator discovery
  - default payload generation
  - parameter type validation against editor metadata
- Richer validation:
  - save-path collisions
  - malformed action/validator entries
  - object ID formatting
  - duplicate object IDs across content roots
  - missing texture paths
  - unresolved description placeholders
  - duplicate string-array values
  - upgrade/cost configuration issues

## Intended UI Integration

The backend is designed so a future scene or dock can stay mostly declarative:

- Use `CardEditorService.list_library_cards()` to build the library.
- Use `CardEditorSchema` to render field sections and property controls.
- Use `CardEditorService.get_action_options()` / `get_validator_options()` for dropdowns.
- Use `CardEditorService.validate_session()` for live diagnostics.
- Use `save_session_to_triage()` and `promote_session_to_content()` for workflow buttons.

## Presets

Current presets:

- `blank_attack`
- `blank_block`
- `blank_power`
- `blank_status`
- `blank_transform`

These are intentionally lightweight scaffolds rather than final design templates.
