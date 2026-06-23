import { z } from "zod";
import { type JsonValue } from "./types.js";

const jsonValue: z.ZodType<JsonValue> = z.lazy(() =>
  z.union([z.null(), z.boolean(), z.number(), z.string(), z.array(jsonValue), z.record(jsonValue)]),
);

export const diagnosticSchema = z.object({
  code: z.string(),
  severity: z.enum(["info", "warning", "error"]),
  message: z.string(),
  field: z.string(),
  data: z.record(jsonValue),
});

export const optionSchema = z.object({
  label: z.string(),
  value: jsonValue,
});

export const parameterDefinitionSchema = z.object({
  name: z.string(),
  label: z.string(),
  valueType: z.string(),
  defaultValue: jsonValue,
  description: z.string(),
  options: z.array(optionSchema),
});

export const scriptMetadataSchema = z.object({
  kind: z.enum(["action", "validator"]),
  displayName: z.string(),
  description: z.string(),
  tokenOrPath: z.string(),
  resolvedPath: z.string(),
  resolvedToken: z.string(),
  scriptPath: z.string(),
  scriptClassName: z.string(),
  scriptGlobalName: z.string(),
  contexts: z.array(z.string()),
  parameters: z.array(parameterDefinitionSchema),
  relevantValueNames: z.array(z.string()),
});

export const behaviorEntrySchema = z.object({
  editorId: z.string(),
  token: z.string(),
  values: z.record(jsonValue),
});

export const additionalActionEntrySchema = behaviorEntrySchema.extend({
  id: z.string(),
});

export const editorCardDocumentSchema = z.object({
  identity: z.object({
    objectId: z.string(),
    objectUid: z.string(),
    cardName: z.string(),
    cardDescription: z.string(),
    cardTexturePath: z.string(),
    cardKeywordObjectIds: z.array(z.string()),
    cardColorId: z.string(),
    cardTags: z.array(z.string()),
  }),
  classification: z.object({
    cardKind: z.string(),
    cardType: z.number(),
    cardRarity: z.number(),
    cardRequiresTarget: z.boolean(),
    cardClickedTargetMode: z.string(),
    cardAppearsInCardPacks: z.boolean(),
  }),
  costs: z.object({
    cardEnergyCost: z.number(),
    cardEnergyCostUntilPlayed: z.number(),
    cardEnergyCostUntilTurn: z.number(),
    cardEnergyCostUntilCombat: z.number(),
    cardEnergyCostIsVariable: z.boolean(),
    cardEnergyCostVariableUpperBound: z.number(),
    cardFirstShufflePriority: z.number(),
  }),
  flags: z.object({
    cardIsPlayable: z.boolean(),
    cardExhausts: z.boolean(),
    cardIsEthereal: z.boolean(),
    cardIsRetained: z.boolean(),
  }),
  values: z.object({
    cardValues: z.record(jsonValue),
    cardDescriptionPreviewOverrides: z.array(jsonValue),
  }),
  upgrades: z.object({
    cardUpgradeAmount: z.number(),
    cardUpgradeAmountMax: z.number(),
    cardFirstUpgradePropertyChanges: z.record(jsonValue),
    cardUpgradeValueImprovements: z.record(jsonValue),
  }),
  deckFlags: z.object({
    cardUnremovableFromDeck: z.boolean(),
    cardUntransformableFromDeck: z.boolean(),
  }),
  metadata: z.object({
    cardOwnerPartyIndex: z.number(),
    cardOwnerCharacterObjectId: z.string(),
    cardListeners: z.array(jsonValue),
  }),
  behavior: z.object({
    groups: z.record(z.array(behaviorEntrySchema)),
    additionalActions: z.array(additionalActionEntrySchema),
  }),
  save: z.object({
    originalResourcePath: z.string(),
    activeSavePath: z.string(),
    managedSavePath: z.string(),
    managedTriageSavePath: z.string(),
    managedOwnerBucketHint: z.string(),
    savePolicy: z.enum(["managed_content", "managed_triage", "manual"]),
    dirty: z.boolean(),
  }),
  diagnostics: z.array(diagnosticSchema),
});

export const libraryEntrySchema = z.object({
  objectId: z.string(),
  cardName: z.string(),
  cardColorId: z.string(),
  cardRarity: z.number(),
  cardType: z.number(),
  cardKind: z.string(),
  cardRequiresTarget: z.boolean(),
  resourcePath: z.string(),
  sourceBucket: z.string(),
  ownerBucket: z.string(),
  searchBlob: z.string(),
});

export const sessionEnvelopeSchema = z.object({
  sessionId: z.string(),
  document: editorCardDocumentSchema,
});

export const sessionUpdateResultSchema = z.object({
  diagnostics: z.array(diagnosticSchema),
  save: editorCardDocumentSchema.shape.save,
});

export const saveResultSchema = z.object({
  success: z.boolean(),
  path: z.string(),
  diagnostics: z.array(diagnosticSchema),
  document: editorCardDocumentSchema,
});

export const presetSummarySchema = z.object({
  id: z.string(),
  displayName: z.string(),
  description: z.string(),
});

export const apiErrorSchema = z.object({
  error: z.string(),
  details: jsonValue.optional(),
});

export const loadSessionRequestSchema = z.object({
  resourcePath: z.string(),
});

export const duplicateSessionRequestSchema = z.object({
  sessionId: z.string(),
});

export const applyPresetRequestSchema = z.object({
  sessionId: z.string(),
  presetId: z.string(),
  preserveIdentity: z.boolean().optional(),
});

export const sessionIdRequestSchema = z.object({
  sessionId: z.string(),
});

export const updateDocumentRequestSchema = z.object({
  sessionId: z.string(),
  document: editorCardDocumentSchema,
});

export const bootstrapResponseSchema = z.object({
  library: z.array(libraryEntrySchema),
  actions: z.array(scriptMetadataSchema),
  validators: z.array(scriptMetadataSchema),
  presets: z.array(presetSummarySchema),
});
