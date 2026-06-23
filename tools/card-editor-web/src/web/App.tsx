import { useEffect, useMemo, useRef, useState } from "react";
import {
  BEHAVIOR_GROUPS,
  type Diagnostic,
  type EditorCardDocument,
  type EditorOption,
  type LibraryEntry,
  type PresetSummary,
  type ScriptMetadata,
  type SessionEnvelope,
} from "../shared/types";
import { BehaviorEditor } from "./components/BehaviorEditor";
import { JsonEditor } from "./components/JsonEditor";

type BootstrapResponse = {
  library: LibraryEntry[];
  actions: ScriptMetadata[];
  validators: ScriptMetadata[];
  presets: PresetSummary[];
};

const DEFAULT_DOCUMENT: EditorCardDocument = {
  identity: {
    objectId: "",
    objectUid: "",
    cardName: "",
    cardDescription: "",
    cardTexturePath: "",
    cardKeywordObjectIds: [],
    cardColorId: "color_green",
    cardTags: [],
  },
  classification: {
    cardKind: "VERSE",
    cardType: 0,
    cardRarity: 1,
    cardRequiresTarget: true,
    cardClickedTargetMode: "ENEMY_ONLY",
    cardAppearsInCardPacks: true,
  },
  costs: {
    cardEnergyCost: 1,
    cardEnergyCostUntilPlayed: -1,
    cardEnergyCostUntilTurn: -1,
    cardEnergyCostUntilCombat: -1,
    cardEnergyCostIsVariable: false,
    cardEnergyCostVariableUpperBound: -1,
    cardFirstShufflePriority: 0,
  },
  flags: {
    cardIsPlayable: true,
    cardExhausts: false,
    cardIsEthereal: false,
    cardIsRetained: false,
  },
  values: {
    cardValues: {},
    cardDescriptionPreviewOverrides: [],
  },
  upgrades: {
    cardUpgradeAmount: 0,
    cardUpgradeAmountMax: 1,
    cardFirstUpgradePropertyChanges: {},
    cardUpgradeValueImprovements: {},
  },
  deckFlags: {
    cardUnremovableFromDeck: false,
    cardUntransformableFromDeck: false,
  },
  metadata: {
    cardOwnerPartyIndex: -1,
    cardOwnerCharacterObjectId: "",
    cardListeners: [],
  },
  behavior: {
    groups: Object.fromEntries(BEHAVIOR_GROUPS.map((name) => [name, []])) as EditorCardDocument["behavior"]["groups"],
    additionalActions: [],
  },
  save: {
    originalResourcePath: "",
    activeSavePath: "",
    managedSavePath: "",
    managedTriageSavePath: "",
    managedOwnerBucketHint: "",
    savePolicy: "managed_triage",
    dirty: false,
  },
  diagnostics: [],
};

export function App() {
  const [bootstrap, setBootstrap] = useState<BootstrapResponse | null>(null);
  const [sessionId, setSessionId] = useState("");
  const [document, setDocument] = useState<EditorCardDocument>(DEFAULT_DOCUMENT);
  const [status, setStatus] = useState("Loading editor data...");
  const [search, setSearch] = useState("");
  const [loading, setLoading] = useState(false);
  const [selectedPreset, setSelectedPreset] = useState("");
  const lastPushedHash = useRef("");

  useEffect(() => {
    void loadBootstrap();
  }, []);

  const filteredLibrary = useMemo(() => {
    if (!bootstrap) {
      return [];
    }
    const normalizedSearch = search.trim().toLowerCase();
    if (normalizedSearch === "") {
      return bootstrap.library;
    }
    return bootstrap.library.filter((entry) => {
      const blob = `${entry.cardName} ${entry.objectId} ${entry.resourcePath} ${entry.ownerBucket}`.toLowerCase();
      return blob.includes(normalizedSearch);
    });
  }, [bootstrap, search]);

  const errorCount = document.diagnostics.filter((diagnostic) => diagnostic.severity === "error").length;
  const warningCount = document.diagnostics.filter((diagnostic) => diagnostic.severity === "warning").length;
  const editableHash = useMemo(() => hashEditableDocument(document), [document]);

  useEffect(() => {
    if (!sessionId) {
      return;
    }
    if (editableHash === lastPushedHash.current) {
      return;
    }
    const timeout = window.setTimeout(() => {
      void pushDocument();
    }, 350);
    return () => window.clearTimeout(timeout);
  }, [editableHash, sessionId]);

  async function loadBootstrap() {
    try {
      const [libraryResponse, presetsResponse] = await Promise.all([
        fetchJson<{ entries: LibraryEntry[] }>("/api/library"),
        fetchJson<{ entries: PresetSummary[] }>("/api/presets"),
      ]);
      const initialBootstrap: BootstrapResponse = {
        library: libraryResponse.entries,
        actions: [],
        validators: [],
        presets: presetsResponse.entries,
      };
      setBootstrap(initialBootstrap);
      setSelectedPreset(initialBootstrap.presets[0]?.id ?? "");
      setStatus("Ready.");
      void loadMetadata();
    } catch (error) {
      setStatus(error instanceof Error ? error.message : "Failed to load bootstrap data.");
    }
  }

  async function loadMetadata() {
    try {
      const [actionsResponse, validatorsResponse] = await Promise.all([
        fetchJson<{ entries: ScriptMetadata[] }>("/api/metadata/actions"),
        fetchJson<{ entries: ScriptMetadata[] }>("/api/metadata/validators"),
      ]);
      setBootstrap((current) =>
        current
          ? {
              ...current,
              actions: actionsResponse.entries,
              validators: validatorsResponse.entries,
            }
          : current,
      );
    } catch (error) {
      setStatus(error instanceof Error ? error.message : "Failed to load editor metadata.");
    }
  }

  async function createSession() {
    setLoading(true);
    try {
      const envelope = await postJson<SessionEnvelope>("/api/session/new", {
        presetId: selectedPreset,
      });
      adoptSession(envelope, "Started a new session.");
    } finally {
      setLoading(false);
    }
  }

  async function loadSession(resourcePath: string) {
    if (document.save.dirty && !window.confirm("Discard unsaved changes and load another card?")) {
      return;
    }
    setLoading(true);
    try {
      const envelope = await postJson<SessionEnvelope>("/api/session/load", { resourcePath });
      adoptSession(envelope, `Loaded ${envelope.document.identity.cardName || envelope.document.identity.objectId}.`);
    } finally {
      setLoading(false);
    }
  }

  async function duplicateSession() {
    if (!sessionId) {
      return;
    }
    setLoading(true);
    try {
      const envelope = await postJson<SessionEnvelope>("/api/session/duplicate", { sessionId });
      adoptSession(envelope, "Duplicated session.");
    } finally {
      setLoading(false);
    }
  }

  async function applyPreset() {
    if (!sessionId || !selectedPreset) {
      return;
    }
    setLoading(true);
    try {
      const envelope = await postJson<SessionEnvelope>("/api/session/apply-preset", {
        sessionId,
        presetId: selectedPreset,
        preserveIdentity: true,
      });
      adoptSession(envelope, "Applied preset.");
    } finally {
      setLoading(false);
    }
  }

  async function pushDocument() {
    if (!sessionId) {
      return;
    }
    try {
      const result = await putJson<{ diagnostics: Diagnostic[]; save: EditorCardDocument["save"] }>(
        "/api/session/document",
        {
          sessionId,
          document,
        },
      );
      lastPushedHash.current = editableHash;
      setDocument((current) => ({
        ...current,
        diagnostics: result.diagnostics,
        save: result.save,
      }));
    } catch (error) {
      setStatus(error instanceof Error ? error.message : "Failed to sync document.");
    }
  }

  async function saveSession(path: "triage" | "content") {
    if (!sessionId) {
      return;
    }
    setLoading(true);
    try {
      const result = await postJson<{ success: boolean; path: string; diagnostics: Diagnostic[]; document: EditorCardDocument }>(
        path === "triage" ? "/api/session/save-triage" : "/api/session/save-content",
        { sessionId },
      );
      lastPushedHash.current = hashEditableDocument(result.document);
      setDocument(result.document);
      setStatus(result.success ? `Saved to ${result.path}` : "Save blocked.");
    } finally {
      setLoading(false);
    }
  }

  async function rescanLibrary() {
    try {
      const result = await postJson<{ entries: LibraryEntry[] }>("/api/session/rescan-library", {});
      setBootstrap((current) =>
        current
          ? {
              ...current,
              library: result.entries,
            }
          : current,
      );
    } catch (error) {
      setStatus(error instanceof Error ? error.message : "Failed to rescan library.");
    }
  }

  function adoptSession(envelope: SessionEnvelope, message: string) {
    setSessionId(envelope.sessionId);
    setDocument(envelope.document);
    lastPushedHash.current = hashEditableDocument(envelope.document);
    setStatus(message);
  }

  return (
    <div className="app-shell">
      <header className="topbar">
        <div>
          <h1>Card Editor</h1>
          <p className="topbar-subtle">{status}</p>
        </div>
        <div className="topbar-actions">
          <select value={selectedPreset} onChange={(event) => setSelectedPreset(event.target.value)}>
            {(bootstrap?.presets ?? []).map((preset) => (
              <option key={preset.id} value={preset.id}>
                {preset.displayName}
              </option>
            ))}
          </select>
          <button type="button" disabled={loading} onClick={createSession}>
            New
          </button>
          <button type="button" disabled={loading || !sessionId} onClick={duplicateSession}>
            Duplicate
          </button>
          <button type="button" disabled={loading || !sessionId} onClick={applyPreset}>
            Apply Preset
          </button>
          <button type="button" disabled={loading || !sessionId || errorCount > 0} onClick={() => saveSession("triage")}>
            Save Triage
          </button>
          <button type="button" disabled={loading || !sessionId || errorCount > 0} onClick={() => saveSession("content")}>
            Save Content
          </button>
        </div>
      </header>

      <main className="workspace">
        <aside className="sidebar">
          <div className="panel panel-fill">
            <div className="panel-header">
              <h2>Library</h2>
              <button type="button" onClick={rescanLibrary}>
                Rescan
              </button>
            </div>
            <input
              type="search"
              placeholder="Search cards"
              value={search}
              onChange={(event) => setSearch(event.target.value)}
            />
            <div className="library-list">
              {filteredLibrary.map((entry) => (
                <button
                  key={entry.resourcePath}
                  type="button"
                  className={`library-item ${
                    document.save.originalResourcePath === entry.resourcePath ? "selected" : ""
                  }`}
                  onClick={() => void loadSession(entry.resourcePath)}
                >
                  <strong>{entry.cardName || entry.objectId}</strong>
                  <span>{entry.objectId}</span>
                  <span>{entry.ownerBucket}</span>
                </button>
              ))}
            </div>
          </div>
        </aside>

        <section className="main-column">
          <div className="column-grid">
            <div className="panel">
              <h2>Inspector</h2>
              <IdentitySection document={document} onChange={setDocument} />
              <ClassificationSection document={document} onChange={setDocument} />
              <CostSection document={document} onChange={setDocument} />
              <FlagsSection document={document} onChange={setDocument} />
              <ValuesSection document={document} onChange={setDocument} />
              <JsonEditor
                label="Description Preview Overrides"
                value={document.values.cardDescriptionPreviewOverrides}
                onChange={(value) =>
                  setDocument({
                    ...document,
                    values: {
                      ...document.values,
                      cardDescriptionPreviewOverrides: toJsonArray(value),
                    },
                  })
                }
              />
              <UpgradeSection document={document} onChange={setDocument} />
              <DeckFlagsSection document={document} onChange={setDocument} />
              <MetadataSection document={document} onChange={setDocument} />
            </div>

            <div className="panel panel-fill">
              <h2>Behavior</h2>
              <BehaviorEditor
                document={document}
                actions={bootstrap?.actions ?? []}
                validators={bootstrap?.validators ?? []}
                onChange={setDocument}
              />
            </div>

            <div className="panel">
              <h2>Preview</h2>
              <PreviewCard document={document} />
              <h2>Diagnostics</h2>
              <div className="diagnostic-summary">
                <span>{errorCount} error(s)</span>
                <span>{warningCount} warning(s)</span>
              </div>
              <div className="diagnostic-list">
                {document.diagnostics.map((diagnostic, index) => (
                  <div key={`${diagnostic.code}_${index}`} className={`diagnostic diagnostic-${diagnostic.severity}`}>
                    <strong>{diagnostic.severity.toUpperCase()}</strong>
                    <span>{diagnostic.field}</span>
                    <p>{diagnostic.message}</p>
                  </div>
                ))}
              </div>
              <h2>Save Paths</h2>
              <div className="field-stack">
                <span className="field-label">Current Path</span>
                <code>{document.save.activeSavePath || "unsaved"}</code>
              </div>
              <div className="field-stack">
                <span className="field-label">Managed Content</span>
                <code>{document.save.managedSavePath}</code>
              </div>
              <div className="field-stack">
                <span className="field-label">Managed Triage</span>
                <code>{document.save.managedTriageSavePath}</code>
              </div>
            </div>
          </div>
        </section>
      </main>
    </div>
  );
}

function IdentitySection({
  document,
  onChange,
}: {
  document: EditorCardDocument;
  onChange: (document: EditorCardDocument) => void;
}) {
  const identity = document.identity;
  return (
    <div className="section-grid">
      <TextField label="Card Name" value={identity.cardName} onChange={(value) => onChange({ ...document, identity: { ...identity, cardName: value } })} />
      <TextField label="Object ID" value={identity.objectId} onChange={(value) => onChange({ ...document, identity: { ...identity, objectId: value } })} />
      <TextField label="Object UID" value={identity.objectUid} readOnly onChange={() => undefined} />
      <TextField label="Texture Path" value={identity.cardTexturePath} onChange={(value) => onChange({ ...document, identity: { ...identity, cardTexturePath: value } })} />
      <TextAreaField label="Description" value={identity.cardDescription} onChange={(value) => onChange({ ...document, identity: { ...identity, cardDescription: value } })} />
      <StringArrayField label="Keywords" values={identity.cardKeywordObjectIds} onChange={(value) => onChange({ ...document, identity: { ...identity, cardKeywordObjectIds: value } })} />
      <StringArrayField label="Tags" values={identity.cardTags} onChange={(value) => onChange({ ...document, identity: { ...identity, cardTags: value } })} />
      <TextField label="Color ID" value={identity.cardColorId} onChange={(value) => onChange({ ...document, identity: { ...identity, cardColorId: value } })} />
    </div>
  );
}

function ClassificationSection({ document, onChange }: { document: EditorCardDocument; onChange: (document: EditorCardDocument) => void }) {
  const classification = document.classification;
  const kindOptions = [
    { label: "Intro", value: "INTRO" },
    { label: "Verse", value: "VERSE" },
    { label: "Jazz", value: "JAZZ" },
    { label: "Outro", value: "OUTRO" },
  ];
  const typeOptions = [
    { label: "Attack", value: 0 },
    { label: "Skill", value: 1 },
    { label: "Power", value: 2 },
    { label: "Status", value: 3 },
    { label: "Curse", value: 4 },
  ];
  const rarityOptions = [
    { label: "Basic", value: 0 },
    { label: "Common", value: 1 },
    { label: "Uncommon", value: 2 },
    { label: "Rare", value: 3 },
    { label: "Generated", value: 4 },
  ];
  const targetModeOptions = [
    { label: "Enemy Only", value: "ENEMY_ONLY" },
    { label: "Ally Only", value: "ALLY_ONLY" },
    { label: "Any Combatant", value: "ANY_COMBATANT" },
  ];
  return (
    <div className="section-grid">
      <SelectField label="Kind" options={kindOptions} value={classification.cardKind} onChange={(value) => onChange({ ...document, classification: { ...classification, cardKind: String(value) } })} />
      <SelectField label="Type" options={typeOptions} value={classification.cardType} onChange={(value) => onChange({ ...document, classification: { ...classification, cardType: Number(value) } })} />
      <SelectField label="Rarity" options={rarityOptions} value={classification.cardRarity} onChange={(value) => onChange({ ...document, classification: { ...classification, cardRarity: Number(value) } })} />
      <SelectField label="Target Mode" options={targetModeOptions} value={classification.cardClickedTargetMode} onChange={(value) => onChange({ ...document, classification: { ...classification, cardClickedTargetMode: String(value) } })} />
      <CheckboxField label="Requires Target" checked={classification.cardRequiresTarget} onChange={(checked) => onChange({ ...document, classification: { ...classification, cardRequiresTarget: checked } })} />
      <CheckboxField label="Appears In Card Packs" checked={classification.cardAppearsInCardPacks} onChange={(checked) => onChange({ ...document, classification: { ...classification, cardAppearsInCardPacks: checked } })} />
    </div>
  );
}

function CostSection({ document, onChange }: { document: EditorCardDocument; onChange: (document: EditorCardDocument) => void }) {
  const costs = document.costs;
  return (
    <div className="section-grid">
      <NumberField label="Energy Cost" value={costs.cardEnergyCost} onChange={(value) => onChange({ ...document, costs: { ...costs, cardEnergyCost: value } })} />
      <NumberField label="Until Played" value={costs.cardEnergyCostUntilPlayed} onChange={(value) => onChange({ ...document, costs: { ...costs, cardEnergyCostUntilPlayed: value } })} />
      <NumberField label="Until Turn" value={costs.cardEnergyCostUntilTurn} onChange={(value) => onChange({ ...document, costs: { ...costs, cardEnergyCostUntilTurn: value } })} />
      <NumberField label="Until Combat" value={costs.cardEnergyCostUntilCombat} onChange={(value) => onChange({ ...document, costs: { ...costs, cardEnergyCostUntilCombat: value } })} />
      <NumberField label="Variable Upper Bound" value={costs.cardEnergyCostVariableUpperBound} onChange={(value) => onChange({ ...document, costs: { ...costs, cardEnergyCostVariableUpperBound: value } })} />
      <NumberField label="Shuffle Priority" value={costs.cardFirstShufflePriority} onChange={(value) => onChange({ ...document, costs: { ...costs, cardFirstShufflePriority: value } })} />
      <CheckboxField label="Variable Cost" checked={costs.cardEnergyCostIsVariable} onChange={(checked) => onChange({ ...document, costs: { ...costs, cardEnergyCostIsVariable: checked } })} />
    </div>
  );
}

function FlagsSection({ document, onChange }: { document: EditorCardDocument; onChange: (document: EditorCardDocument) => void }) {
  const flags = document.flags;
  return (
    <div className="section-grid">
      <CheckboxField label="Playable" checked={flags.cardIsPlayable} onChange={(checked) => onChange({ ...document, flags: { ...flags, cardIsPlayable: checked } })} />
      <CheckboxField label="Exhausts" checked={flags.cardExhausts} onChange={(checked) => onChange({ ...document, flags: { ...flags, cardExhausts: checked } })} />
      <CheckboxField label="Ethereal" checked={flags.cardIsEthereal} onChange={(checked) => onChange({ ...document, flags: { ...flags, cardIsEthereal: checked } })} />
      <CheckboxField label="Retained" checked={flags.cardIsRetained} onChange={(checked) => onChange({ ...document, flags: { ...flags, cardIsRetained: checked } })} />
    </div>
  );
}

function ValuesSection({ document, onChange }: { document: EditorCardDocument; onChange: (document: EditorCardDocument) => void }) {
  const values = document.values.cardValues;
  const entries = Object.entries(values);
  return (
    <div className="field-stack">
      <span className="field-label">Card Values</span>
      <div className="dictionary-editor">
        {entries.map(([key, value]) => (
          <div key={key} className="dictionary-row">
            <input
              type="text"
              value={key}
              onChange={(event) => {
                const nextEntries = { ...values };
                const nextValue = nextEntries[key];
                delete nextEntries[key];
                nextEntries[event.target.value] = nextValue;
                onChange({ ...document, values: { ...document.values, cardValues: nextEntries } });
              }}
            />
            <input
              type="text"
              value={String(value ?? "")}
              onChange={(event) => {
                onChange({
                  ...document,
                  values: {
                    ...document.values,
                    cardValues: {
                      ...values,
                      [key]: coerceStringValue(event.target.value),
                    },
                  },
                });
              }}
            />
            <button
              type="button"
              className="danger"
              onClick={() => {
                const nextEntries = { ...values };
                delete nextEntries[key];
                onChange({ ...document, values: { ...document.values, cardValues: nextEntries } });
              }}
            >
              Remove
            </button>
          </div>
        ))}
        <button
          type="button"
          onClick={() =>
            onChange({
              ...document,
              values: {
                ...document.values,
                cardValues: {
                  ...values,
                  [`value_${entries.length + 1}`]: 0,
                },
              },
            })
          }
        >
          Add Value
        </button>
      </div>
    </div>
  );
}

function UpgradeSection({ document, onChange }: { document: EditorCardDocument; onChange: (document: EditorCardDocument) => void }) {
  const upgrades = document.upgrades;
  return (
    <>
      <div className="section-grid">
        <NumberField label="Upgrade Amount" value={upgrades.cardUpgradeAmount} onChange={(value) => onChange({ ...document, upgrades: { ...upgrades, cardUpgradeAmount: value } })} />
        <NumberField label="Upgrade Amount Max" value={upgrades.cardUpgradeAmountMax} onChange={(value) => onChange({ ...document, upgrades: { ...upgrades, cardUpgradeAmountMax: value } })} />
      </div>
      <JsonEditor
        label="First Upgrade Property Changes"
        value={upgrades.cardFirstUpgradePropertyChanges}
        onChange={(value) => onChange({ ...document, upgrades: { ...upgrades, cardFirstUpgradePropertyChanges: toJsonRecord(value) } })}
      />
      <JsonEditor
        label="Upgrade Value Improvements"
        value={upgrades.cardUpgradeValueImprovements}
        onChange={(value) => onChange({ ...document, upgrades: { ...upgrades, cardUpgradeValueImprovements: toJsonRecord(value) } })}
      />
    </>
  );
}

function DeckFlagsSection({ document, onChange }: { document: EditorCardDocument; onChange: (document: EditorCardDocument) => void }) {
  const deckFlags = document.deckFlags;
  return (
    <div className="section-grid">
      <CheckboxField label="Unremovable" checked={deckFlags.cardUnremovableFromDeck} onChange={(checked) => onChange({ ...document, deckFlags: { ...deckFlags, cardUnremovableFromDeck: checked } })} />
      <CheckboxField label="Untransformable" checked={deckFlags.cardUntransformableFromDeck} onChange={(checked) => onChange({ ...document, deckFlags: { ...deckFlags, cardUntransformableFromDeck: checked } })} />
    </div>
  );
}

function MetadataSection({ document, onChange }: { document: EditorCardDocument; onChange: (document: EditorCardDocument) => void }) {
  const metadata = document.metadata;
  return (
    <>
      <div className="section-grid">
        <NumberField label="Owner Party Index" value={metadata.cardOwnerPartyIndex} onChange={(value) => onChange({ ...document, metadata: { ...metadata, cardOwnerPartyIndex: value } })} />
        <TextField label="Owner Character ID" value={metadata.cardOwnerCharacterObjectId} onChange={(value) => onChange({ ...document, metadata: { ...metadata, cardOwnerCharacterObjectId: value } })} />
      </div>
      <JsonEditor
        label="Card Listeners"
        value={metadata.cardListeners}
        onChange={(value) => onChange({ ...document, metadata: { ...metadata, cardListeners: toJsonArray(value) } })}
      />
    </>
  );
}

function PreviewCard({ document }: { document: EditorCardDocument }) {
  return (
    <div className="preview-card">
      <div className="preview-head">
        <span className="preview-cost">
          {document.costs.cardEnergyCostIsVariable ? "X" : document.costs.cardEnergyCost}
        </span>
        <div>
          <h3>{document.identity.cardName || "Untitled Card"}</h3>
          <span>
            {document.classification.cardColorId} · {document.classification.cardKind}
          </span>
        </div>
      </div>
      <p>{document.identity.cardDescription || "No description."}</p>
      <div className="preview-meta">
        <span>Type: {document.classification.cardType}</span>
        <span>Rarity: {document.classification.cardRarity}</span>
      </div>
      <div className="tag-list">
        {document.identity.cardTags.map((tag) => (
          <span key={tag} className="tag">
            {tag}
          </span>
        ))}
      </div>
    </div>
  );
}

function TextField(props: { label: string; value: string; onChange: (value: string) => void; readOnly?: boolean }) {
  return (
    <label className="field-stack">
      <span className="field-label">{props.label}</span>
      <input type="text" value={props.value} readOnly={props.readOnly} onChange={(event) => props.onChange(event.target.value)} />
    </label>
  );
}

function TextAreaField(props: { label: string; value: string; onChange: (value: string) => void }) {
  return (
    <label className="field-stack field-span">
      <span className="field-label">{props.label}</span>
      <textarea value={props.value} onChange={(event) => props.onChange(event.target.value)} />
    </label>
  );
}

function NumberField(props: { label: string; value: number; onChange: (value: number) => void }) {
  return (
    <label className="field-stack">
      <span className="field-label">{props.label}</span>
      <input type="number" value={props.value} onChange={(event) => props.onChange(Number(event.target.value))} />
    </label>
  );
}

function CheckboxField(props: { label: string; checked: boolean; onChange: (checked: boolean) => void }) {
  return (
    <label className="checkbox-row">
      <input type="checkbox" checked={props.checked} onChange={(event) => props.onChange(event.target.checked)} />
      <span>{props.label}</span>
    </label>
  );
}

function SelectField(props: { label: string; options: EditorOption[]; value: unknown; onChange: (value: unknown) => void }) {
  const selectedIndex = Math.max(
    0,
    props.options.findIndex((option) => JSON.stringify(option.value) === JSON.stringify(props.value)),
  );
  return (
    <label className="field-stack">
      <span className="field-label">{props.label}</span>
      <select value={String(selectedIndex)} onChange={(event) => props.onChange(props.options[Number(event.target.value)]?.value ?? null)}>
        {props.options.map((option, index) => (
          <option key={`${option.label}_${index}`} value={String(index)}>
            {option.label}
          </option>
        ))}
      </select>
    </label>
  );
}

function StringArrayField(props: { label: string; values: string[]; onChange: (values: string[]) => void }) {
  return (
    <label className="field-stack field-span">
      <span className="field-label">{props.label}</span>
      <input
        type="text"
        value={props.values.join(", ")}
        onChange={(event) =>
          props.onChange(
            event.target.value
              .split(",")
              .map((item) => item.trim())
              .filter(Boolean),
          )
        }
      />
    </label>
  );
}

async function fetchJson<T>(url: string): Promise<T> {
  const response = await fetch(url);
  if (!response.ok) {
    throw new Error(await response.text());
  }
  return (await response.json()) as T;
}

async function postJson<T>(url: string, body: unknown): Promise<T> {
  const response = await fetch(url, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify(body),
  });
  if (!response.ok) {
    throw new Error(await response.text());
  }
  return (await response.json()) as T;
}

async function putJson<T>(url: string, body: unknown): Promise<T> {
  const response = await fetch(url, {
    method: "PUT",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify(body),
  });
  if (!response.ok) {
    throw new Error(await response.text());
  }
  return (await response.json()) as T;
}

function hashEditableDocument(document: EditorCardDocument) {
  return JSON.stringify({
    identity: document.identity,
    classification: document.classification,
    costs: document.costs,
    flags: document.flags,
    values: document.values,
    upgrades: document.upgrades,
    deckFlags: document.deckFlags,
    metadata: document.metadata,
    behavior: document.behavior,
  });
}

function toJsonRecord(value: unknown) {
  return typeof value === "object" && value && !Array.isArray(value)
    ? (value as Record<string, unknown>)
    : {};
}

function toJsonArray(value: unknown) {
  return Array.isArray(value) ? value : [];
}

function coerceStringValue(rawValue: string): unknown {
  if (rawValue === "true") {
    return true;
  }
  if (rawValue === "false") {
    return false;
  }
  if (rawValue !== "" && !Number.isNaN(Number(rawValue))) {
    return Number(rawValue);
  }
  return rawValue;
}
