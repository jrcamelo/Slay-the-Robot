export const ACTION_REFERENCE_PARAMETER_NAMES = [
  "action_data",
  "passed_action_data",
  "failed_action_data",
  "actions_on_lethal",
] as const;

export const BEHAVIOR_GROUPS = [
  "card_play_actions",
  "card_discard_actions",
  "card_end_of_turn_actions",
  "card_exhaust_actions",
  "card_draw_actions",
  "card_retain_actions",
  "card_right_click_actions",
  "card_initial_combat_actions",
  "card_add_to_deck_actions",
  "card_remove_from_deck_actions",
  "card_transform_in_deck_actions",
  "card_play_validators",
  "card_glow_validators",
] as const;

export type BehaviorGroupName = (typeof BEHAVIOR_GROUPS)[number];
export type ActionReferenceParameterName =
  (typeof ACTION_REFERENCE_PARAMETER_NAMES)[number];

export type JsonValue =
  | null
  | boolean
  | number
  | string
  | JsonValue[]
  | { [key: string]: JsonValue };

export type EditorSeverity = "info" | "warning" | "error";
export type SavePolicy = "managed_content" | "managed_triage" | "manual";
export type MetadataKind = "action" | "validator";

export interface Diagnostic {
  code: string;
  severity: EditorSeverity;
  message: string;
  field: string;
  data: Record<string, JsonValue>;
}

export interface LibraryEntry {
  objectId: string;
  cardName: string;
  cardColorId: string;
  cardRarity: number;
  cardType: number;
  cardKind: string;
  cardRequiresTarget: boolean;
  resourcePath: string;
  sourceBucket: string;
  ownerBucket: string;
  searchBlob: string;
}

export interface EditorOption {
  label: string;
  value: JsonValue;
}

export interface ParameterDefinition {
  name: string;
  label: string;
  valueType: string;
  defaultValue: JsonValue;
  description: string;
  options: EditorOption[];
}

export interface ScriptMetadata {
  kind: MetadataKind;
  displayName: string;
  description: string;
  tokenOrPath: string;
  resolvedPath: string;
  resolvedToken: string;
  scriptPath: string;
  scriptClassName: string;
  scriptGlobalName: string;
  contexts: string[];
  parameters: ParameterDefinition[];
  relevantValueNames: string[];
}

export interface BehaviorEntry {
  editorId: string;
  token: string;
  values: Record<string, JsonValue>;
}

export interface AdditionalActionEntry extends BehaviorEntry {
  id: string;
}

export interface IdentitySection {
  objectId: string;
  objectUid: string;
  cardName: string;
  cardDescription: string;
  cardTexturePath: string;
  cardKeywordObjectIds: string[];
  cardColorId: string;
  cardTags: string[];
}

export interface ClassificationSection {
  cardKind: string;
  cardType: number;
  cardRarity: number;
  cardRequiresTarget: boolean;
  cardClickedTargetMode: string;
  cardAppearsInCardPacks: boolean;
}

export interface CostsSection {
  cardEnergyCost: number;
  cardEnergyCostUntilPlayed: number;
  cardEnergyCostUntilTurn: number;
  cardEnergyCostUntilCombat: number;
  cardEnergyCostIsVariable: boolean;
  cardEnergyCostVariableUpperBound: number;
  cardFirstShufflePriority: number;
}

export interface FlagsSection {
  cardIsPlayable: boolean;
  cardExhausts: boolean;
  cardIsEthereal: boolean;
  cardIsRetained: boolean;
}

export interface ValuesSection {
  cardValues: Record<string, JsonValue>;
  cardDescriptionPreviewOverrides: JsonValue[];
}

export interface UpgradesSection {
  cardUpgradeAmount: number;
  cardUpgradeAmountMax: number;
  cardFirstUpgradePropertyChanges: Record<string, JsonValue>;
  cardUpgradeValueImprovements: Record<string, JsonValue>;
}

export interface DeckFlagsSection {
  cardUnremovableFromDeck: boolean;
  cardUntransformableFromDeck: boolean;
}

export interface MetadataSection {
  cardOwnerPartyIndex: number;
  cardOwnerCharacterObjectId: string;
  cardListeners: JsonValue[];
}

export interface SaveSection {
  originalResourcePath: string;
  activeSavePath: string;
  managedSavePath: string;
  managedTriageSavePath: string;
  managedOwnerBucketHint: string;
  savePolicy: SavePolicy;
  dirty: boolean;
}

export interface BehaviorSection {
  groups: Record<string, BehaviorEntry[]>;
  additionalActions: AdditionalActionEntry[];
}

export interface EditorCardDocument {
  identity: IdentitySection;
  classification: ClassificationSection;
  costs: CostsSection;
  flags: FlagsSection;
  values: ValuesSection;
  upgrades: UpgradesSection;
  deckFlags: DeckFlagsSection;
  metadata: MetadataSection;
  behavior: BehaviorSection;
  save: SaveSection;
  diagnostics: Diagnostic[];
}

export interface SessionEnvelope {
  sessionId: string;
  document: EditorCardDocument;
}

export interface PresetSummary {
  id: string;
  displayName: string;
  description: string;
}

export interface SaveResult {
  success: boolean;
  path: string;
  diagnostics: Diagnostic[];
  document: EditorCardDocument;
}

export interface SessionUpdateResult {
  diagnostics: Diagnostic[];
  save: SaveSection;
}

export interface ApiErrorShape {
  error: string;
  details?: JsonValue;
}

export const BEHAVIOR_GROUP_LABELS: Record<BehaviorGroupName, string> = {
  card_play_actions: "Play Actions",
  card_discard_actions: "Discard Actions",
  card_end_of_turn_actions: "End Of Turn Actions",
  card_exhaust_actions: "Exhaust Actions",
  card_draw_actions: "Draw Actions",
  card_retain_actions: "Retain Actions",
  card_right_click_actions: "Right Click Actions",
  card_initial_combat_actions: "Initial Combat Actions",
  card_add_to_deck_actions: "Add To Deck Actions",
  card_remove_from_deck_actions: "Remove From Deck Actions",
  card_transform_in_deck_actions: "Transform In Deck Actions",
  card_play_validators: "Play Validators",
  card_glow_validators: "Glow Validators",
};

export const BEHAVIOR_GROUP_CONTEXTS: Record<BehaviorGroupName, string> = {
  card_play_actions: "card_play_actions",
  card_discard_actions: "card_trigger_actions",
  card_end_of_turn_actions: "card_trigger_actions",
  card_exhaust_actions: "card_trigger_actions",
  card_draw_actions: "card_trigger_actions",
  card_retain_actions: "card_trigger_actions",
  card_right_click_actions: "card_trigger_actions",
  card_initial_combat_actions: "card_trigger_actions",
  card_add_to_deck_actions: "card_trigger_actions",
  card_remove_from_deck_actions: "card_trigger_actions",
  card_transform_in_deck_actions: "card_trigger_actions",
  card_play_validators: "card_play_validators",
  card_glow_validators: "card_glow_validators",
};

export function isActionReferenceParameter(
  parameterName: string,
): parameterName is ActionReferenceParameterName {
  return ACTION_REFERENCE_PARAMETER_NAMES.includes(
    parameterName as ActionReferenceParameterName,
  );
}
