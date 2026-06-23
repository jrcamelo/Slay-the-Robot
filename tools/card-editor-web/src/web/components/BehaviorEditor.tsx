import {
  BEHAVIOR_GROUP_CONTEXTS,
  BEHAVIOR_GROUP_LABELS,
  type AdditionalActionEntry,
  type BehaviorEntry,
  type BehaviorGroupName,
  type EditorCardDocument,
  type EditorOption,
  type ParameterDefinition,
  type ScriptMetadata,
  isActionReferenceParameter,
} from "../../shared/types";
import { JsonEditor } from "./JsonEditor";

type Selection =
  | { kind: "group"; groupName: BehaviorGroupName; entryId: string }
  | { kind: "additional"; id: string }
  | null;

type BehaviorEditorProps = {
  document: EditorCardDocument;
  actions: ScriptMetadata[];
  validators: ScriptMetadata[];
  onChange: (document: EditorCardDocument) => void;
};

export function BehaviorEditor({
  document,
  actions,
  validators,
  onChange,
}: BehaviorEditorProps) {
  const selection = getDefaultSelection(document);
  const selectedEntry = selection
    ? selection.kind === "group"
      ? document.behavior.groups[selection.groupName].find(
          (entry) => entry.editorId === selection.entryId,
        ) ?? null
      : document.behavior.additionalActions.find((entry) => entry.id === selection.id) ?? null
    : null;

  return (
    <div className="behavior-layout">
      <div className="behavior-groups">
        {(
          Object.keys(document.behavior.groups) as BehaviorGroupName[]
        ).map((groupName) => (
          <BehaviorGroupSection
            key={groupName}
            groupName={groupName}
            entries={document.behavior.groups[groupName]}
            metadataList={groupName.includes("validator") ? validators : actions}
            additionalActions={document.behavior.additionalActions}
            selectedEntryId={selection?.kind === "group" && selection.groupName === groupName ? selection.entryId : ""}
            onSelect={(entryId) => {
              const nextSelection: Selection = { kind: "group", groupName, entryId };
              (window as Window & { __cardEditorSelection?: Selection }).__cardEditorSelection = nextSelection;
              onChange({ ...document });
            }}
            onDocumentChange={onChange}
            document={document}
          />
        ))}
        <AdditionalActionsSection
          document={document}
          actions={actions}
          selectedId={selection?.kind === "additional" ? selection.id : ""}
          onSelect={(id) => {
            const nextSelection: Selection = { kind: "additional", id };
            (window as Window & { __cardEditorSelection?: Selection }).__cardEditorSelection = nextSelection;
            onChange({ ...document });
          }}
          onDocumentChange={onChange}
        />
      </div>
      <div className="behavior-detail">
        {selectedEntry ? (
          <BehaviorDetailPane
            document={document}
            selectedEntry={selectedEntry}
            selection={selection}
            actions={actions}
            validators={validators}
            onChange={onChange}
          />
        ) : (
          <div className="empty-state">Select an action, validator, or additional action.</div>
        )}
      </div>
    </div>
  );
}

function BehaviorGroupSection(props: {
  groupName: BehaviorGroupName;
  entries: BehaviorEntry[];
  metadataList: ScriptMetadata[];
  additionalActions: AdditionalActionEntry[];
  selectedEntryId: string;
  document: EditorCardDocument;
  onSelect: (entryId: string) => void;
  onDocumentChange: (document: EditorCardDocument) => void;
}) {
  const context = BEHAVIOR_GROUP_CONTEXTS[props.groupName];
  const metadataOptions = props.metadataList.filter((entry) => entry.contexts.includes(context));
  const addToken = metadataOptions[0]?.resolvedToken ?? "";

  return (
    <section className="panel">
      <div className="panel-header">
        <h3>{BEHAVIOR_GROUP_LABELS[props.groupName]}</h3>
        <button
          type="button"
          onClick={() => {
            if (!addToken) {
              return;
            }
            const nextEntry = createBehaviorEntry(addToken, metadataOptions);
            props.onDocumentChange({
              ...props.document,
              behavior: {
                ...props.document.behavior,
                groups: {
                  ...props.document.behavior.groups,
                  [props.groupName]: [...props.entries, nextEntry],
                },
              },
            });
          }}
        >
          Add
        </button>
      </div>
      <div className="entry-list">
        {props.entries.length === 0 ? <div className="entry-empty">No entries.</div> : null}
        {props.entries.map((entry, index) => {
          const label =
            props.metadataList.find((metadata) => metadata.resolvedToken === entry.token)?.displayName ??
            entry.token;
          return (
            <div
              key={entry.editorId}
              className={`entry-row ${props.selectedEntryId === entry.editorId ? "selected" : ""}`}
            >
              <button type="button" className="entry-main" onClick={() => props.onSelect(entry.editorId)}>
                <span>{label}</span>
                <span className="entry-subtle">{entry.token}</span>
              </button>
              <EntryRowActions
                onMoveUp={() =>
                  props.onDocumentChange(updateGroupEntries(props.document, props.groupName, moveItem(props.entries, index, -1)))
                }
                onMoveDown={() =>
                  props.onDocumentChange(updateGroupEntries(props.document, props.groupName, moveItem(props.entries, index, 1)))
                }
                onDuplicate={() =>
                  props.onDocumentChange(
                    updateGroupEntries(props.document, props.groupName, [
                      ...props.entries.slice(0, index + 1),
                      { ...entry, editorId: createEditorId() },
                      ...props.entries.slice(index + 1),
                    ]),
                  )
                }
                onRemove={() =>
                  props.onDocumentChange(
                    updateGroupEntries(
                      props.document,
                      props.groupName,
                      props.entries.filter((candidate) => candidate.editorId !== entry.editorId),
                    ),
                  )
                }
              />
            </div>
          );
        })}
      </div>
    </section>
  );
}

function AdditionalActionsSection(props: {
  document: EditorCardDocument;
  actions: ScriptMetadata[];
  selectedId: string;
  onSelect: (id: string) => void;
  onDocumentChange: (document: EditorCardDocument) => void;
}) {
  const metadataOptions = props.actions.filter((entry) => entry.contexts.includes("action_children"));
  const addToken = metadataOptions[0]?.resolvedToken ?? "";

  return (
    <section className="panel">
      <div className="panel-header">
        <h3>Additional Actions</h3>
        <button
          type="button"
          onClick={() => {
            if (!addToken) {
              return;
            }
            const entry = createAdditionalActionEntry(addToken, metadataOptions, props.document.behavior.additionalActions);
            props.onDocumentChange({
              ...props.document,
              behavior: {
                ...props.document.behavior,
                additionalActions: [...props.document.behavior.additionalActions, entry],
              },
            });
          }}
        >
          Add
        </button>
      </div>
      <div className="entry-list">
        {props.document.behavior.additionalActions.length === 0 ? (
          <div className="entry-empty">No additional actions.</div>
        ) : null}
        {props.document.behavior.additionalActions.map((entry, index) => {
          const label =
            props.actions.find((metadata) => metadata.resolvedToken === entry.token)?.displayName ?? entry.token;
          return (
            <div
              key={entry.id}
              className={`entry-row ${props.selectedId === entry.id ? "selected" : ""}`}
            >
              <button type="button" className="entry-main" onClick={() => props.onSelect(entry.id)}>
                <span>{label}</span>
                <span className="entry-subtle">{entry.id}</span>
              </button>
              <EntryRowActions
                onMoveUp={() =>
                  props.onDocumentChange({
                    ...props.document,
                    behavior: {
                      ...props.document.behavior,
                      additionalActions: moveItem(props.document.behavior.additionalActions, index, -1),
                    },
                  })
                }
                onMoveDown={() =>
                  props.onDocumentChange({
                    ...props.document,
                    behavior: {
                      ...props.document.behavior,
                      additionalActions: moveItem(props.document.behavior.additionalActions, index, 1),
                    },
                  })
                }
                onDuplicate={() =>
                  props.onDocumentChange({
                    ...props.document,
                    behavior: {
                      ...props.document.behavior,
                      additionalActions: [
                        ...props.document.behavior.additionalActions.slice(0, index + 1),
                        {
                          ...entry,
                          id: createAdditionalActionId(props.document.behavior.additionalActions),
                          editorId: createEditorId(),
                        },
                        ...props.document.behavior.additionalActions.slice(index + 1),
                      ],
                    },
                  })
                }
                onRemove={() =>
                  props.onDocumentChange(removeAdditionalAction(props.document, entry.id))
                }
              />
            </div>
          );
        })}
      </div>
    </section>
  );
}

function BehaviorDetailPane(props: {
  document: EditorCardDocument;
  selectedEntry: BehaviorEntry | AdditionalActionEntry;
  selection: Selection;
  actions: ScriptMetadata[];
  validators: ScriptMetadata[];
  onChange: (document: EditorCardDocument) => void;
}) {
  const metadataList =
    props.selection?.kind === "group" && props.selection.groupName.includes("validator")
      ? props.validators
      : props.actions;
  const context =
    props.selection?.kind === "group"
      ? BEHAVIOR_GROUP_CONTEXTS[props.selection.groupName]
      : "action_children";
  const options = metadataList.filter((entry) => entry.contexts.includes(context));
  const metadata = metadataList.find((entry) => entry.resolvedToken === props.selectedEntry.token) ?? null;

  const replaceToken = (nextToken: string) => {
    const replacement =
      "id" in props.selectedEntry
        ? createAdditionalActionEntry(nextToken, props.actions, props.document.behavior.additionalActions, props.selectedEntry.id)
        : createBehaviorEntry(nextToken, metadataList, props.selectedEntry.values, props.selectedEntry.editorId);
    if (props.selection?.kind === "additional") {
      props.onChange({
        ...props.document,
        behavior: {
          ...props.document.behavior,
          additionalActions: props.document.behavior.additionalActions.map((entry) =>
            entry.id === props.selection?.id ? (replacement as AdditionalActionEntry) : entry,
          ),
        },
      });
      return;
    }
    if (props.selection?.kind === "group") {
      props.onChange({
        ...props.document,
        behavior: {
          ...props.document.behavior,
          groups: {
            ...props.document.behavior.groups,
            [props.selection.groupName]: props.document.behavior.groups[props.selection.groupName].map((entry) =>
              entry.editorId === props.selectedEntry.editorId ? (replacement as BehaviorEntry) : entry,
            ),
          },
        },
      });
    }
  };

  const updateValues = (nextValues: Record<string, unknown>) => {
    if (props.selection?.kind === "additional") {
      props.onChange({
        ...props.document,
        behavior: {
          ...props.document.behavior,
          additionalActions: props.document.behavior.additionalActions.map((entry) =>
            entry.id === props.selection?.id ? { ...entry, values: nextValues } : entry,
          ),
        },
      });
      return;
    }
    if (props.selection?.kind === "group") {
      props.onChange({
        ...props.document,
        behavior: {
          ...props.document.behavior,
          groups: {
            ...props.document.behavior.groups,
            [props.selection.groupName]: props.document.behavior.groups[props.selection.groupName].map((entry) =>
              entry.editorId === props.selectedEntry.editorId ? { ...entry, values: nextValues } : entry,
            ),
          },
        },
      });
    }
  };

  const values = props.selectedEntry.values;
  const parameters = metadata?.parameters ?? [];

  return (
    <section className="panel panel-fill">
      <div className="field-stack">
        <span className="field-label">Token</span>
        <SelectInput
          options={options.map((option) => ({ label: option.displayName, value: option.resolvedToken }))}
          value={props.selectedEntry.token}
          onChange={(value) => replaceToken(String(value))}
        />
      </div>
      {metadata?.description ? <p className="detail-description">{metadata.description}</p> : null}
      {parameters.length === 0 ? <div className="entry-empty">No parameters.</div> : null}
      {parameters.map((parameter) => (
        <ParameterEditor
          key={parameter.name}
          parameter={parameter}
          value={values[parameter.name] ?? parameter.defaultValue}
          document={props.document}
          onChange={(nextValue) => updateValues({ ...values, [parameter.name]: nextValue })}
        />
      ))}
      <JsonEditor
        label="Raw Values"
        value={values}
        onChange={(nextValue) => updateValues((nextValue as Record<string, unknown>) ?? {})}
        height={220}
      />
    </section>
  );
}

function ParameterEditor(props: {
  parameter: ParameterDefinition;
  value: unknown;
  document: EditorCardDocument;
  onChange: (value: unknown) => void;
}) {
  const { parameter, value } = props;
  const label = parameter.label || parameter.name;

  if (isActionReferenceParameter(parameter.name)) {
    return (
      <label className="field-stack">
        <span className="field-label">{label}</span>
        <ActionReferenceEditor
          value={Array.isArray(value) ? value.map(String) : []}
          additionalActions={props.document.behavior.additionalActions}
          actionMetadata={[]}
          onChange={props.onChange}
          document={props.document}
        />
      </label>
    );
  }

  switch (parameter.valueType) {
    case "bool":
      return (
        <label className="checkbox-row">
          <input
            type="checkbox"
            checked={Boolean(value)}
            onChange={(event) => props.onChange(event.target.checked)}
          />
          <span>{label}</span>
        </label>
      );
    case "int":
    case "float":
      return (
        <label className="field-stack">
          <span className="field-label">{label}</span>
          <input
            type="number"
            value={Number(value ?? 0)}
            step={parameter.valueType === "float" ? "0.1" : "1"}
            onChange={(event) =>
              props.onChange(
                parameter.valueType === "float"
                  ? Number(event.target.value)
                  : Math.trunc(Number(event.target.value)),
              )
            }
          />
        </label>
      );
    case "enum":
      return (
        <label className="field-stack">
          <span className="field-label">{label}</span>
          <SelectInput options={parameter.options} value={value} onChange={props.onChange} />
        </label>
      );
    case "string_array":
    case "card_array":
      return (
        <label className="field-stack">
          <span className="field-label">{label}</span>
          <input
            type="text"
            value={Array.isArray(value) ? value.map(String).join(", ") : ""}
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
    case "enum_array":
      return (
        <label className="field-stack">
          <span className="field-label">{label}</span>
          <MultiSelectCheckboxes
            options={parameter.options}
            value={Array.isArray(value) ? value : []}
            onChange={props.onChange}
          />
        </label>
      );
    case "string":
    case "resource_path":
    case "multiline_string":
      return (
        <label className="field-stack">
          <span className="field-label">{label}</span>
          {parameter.valueType === "multiline_string" ? (
            <textarea value={String(value ?? "")} onChange={(event) => props.onChange(event.target.value)} />
          ) : (
            <input type="text" value={String(value ?? "")} onChange={(event) => props.onChange(event.target.value)} />
          )}
        </label>
      );
    default:
      return (
        <JsonEditor label={label} value={value} onChange={props.onChange} height={140} />
      );
  }
}

function ActionReferenceEditor(props: {
  value: string[];
  additionalActions: AdditionalActionEntry[];
  actionMetadata: ScriptMetadata[];
  document: EditorCardDocument;
  onChange: (value: string[]) => void;
}) {
  const existingOptions: EditorOption[] = props.additionalActions.map((entry) => ({
    label: `${entry.id} (${entry.token})`,
    value: entry.id,
  }));

  return (
    <div className="reference-editor">
      {props.value.map((referenceId, index) => (
        <div key={`${referenceId}_${index}`} className="reference-row">
          <button type="button" className="link-button">
            {referenceId}
          </button>
          <EntryRowActions
            compact
            onMoveUp={() => props.onChange(moveItem(props.value, index, -1))}
            onMoveDown={() => props.onChange(moveItem(props.value, index, 1))}
            onDuplicate={() =>
              props.onChange([
                ...props.value.slice(0, index + 1),
                referenceId,
                ...props.value.slice(index + 1),
              ])
            }
            onRemove={() =>
              props.onChange(props.value.filter((candidate, candidateIndex) => candidateIndex !== index))
            }
          />
        </div>
      ))}
      <SelectAdder
        options={existingOptions}
        buttonLabel="Add Existing"
        onAdd={(value) => props.onChange([...props.value, String(value)])}
      />
    </div>
  );
}

function EntryRowActions(props: {
  onMoveUp: () => void;
  onMoveDown: () => void;
  onDuplicate: () => void;
  onRemove: () => void;
  compact?: boolean;
}) {
  return (
    <div className={`entry-actions ${props.compact ? "compact" : ""}`}>
      <button type="button" onClick={props.onMoveUp}>
        Up
      </button>
      <button type="button" onClick={props.onMoveDown}>
        Down
      </button>
      <button type="button" onClick={props.onDuplicate}>
        Duplicate
      </button>
      <button type="button" className="danger" onClick={props.onRemove}>
        Remove
      </button>
    </div>
  );
}

function SelectAdder(props: {
  options: EditorOption[];
  buttonLabel: string;
  onAdd: (value: unknown) => void;
}) {
  const option = props.options[0];
  return (
    <button type="button" disabled={!option} onClick={() => option && props.onAdd(option.value)}>
      {props.buttonLabel}
    </button>
  );
}

function SelectInput(props: {
  options: EditorOption[];
  value: unknown;
  onChange: (value: unknown) => void;
}) {
  const selectedIndex = Math.max(
    0,
    props.options.findIndex((option) => JSON.stringify(option.value) === JSON.stringify(props.value)),
  );

  return (
    <select
      value={String(selectedIndex)}
      onChange={(event) => props.onChange(props.options[Number(event.target.value)]?.value ?? null)}
    >
      {props.options.map((option, index) => (
        <option key={`${option.label}_${index}`} value={String(index)}>
          {option.label}
        </option>
      ))}
    </select>
  );
}

function MultiSelectCheckboxes(props: {
  options: EditorOption[];
  value: unknown[];
  onChange: (value: unknown[]) => void;
}) {
  return (
    <div className="checkbox-list">
      {props.options.map((option, index) => {
        const checked = props.value.some(
          (candidate) => JSON.stringify(candidate) === JSON.stringify(option.value),
        );
        return (
          <label key={`${option.label}_${index}`} className="checkbox-row">
            <input
              type="checkbox"
              checked={checked}
              onChange={(event) => {
                const nextValue = checked
                  ? props.value.filter(
                      (candidate) => JSON.stringify(candidate) !== JSON.stringify(option.value),
                    )
                  : [...props.value, option.value];
                props.onChange(nextValue);
              }}
            />
            <span>{option.label}</span>
          </label>
        );
      })}
    </div>
  );
}

function updateGroupEntries(
  document: EditorCardDocument,
  groupName: BehaviorGroupName,
  entries: BehaviorEntry[],
) {
  return {
    ...document,
    behavior: {
      ...document.behavior,
      groups: {
        ...document.behavior.groups,
        [groupName]: entries,
      },
    },
  };
}

function removeAdditionalAction(document: EditorCardDocument, additionalActionId: string): EditorCardDocument {
  const nextGroups = Object.fromEntries(
    (Object.keys(document.behavior.groups) as BehaviorGroupName[]).map((groupName) => [
      groupName,
      document.behavior.groups[groupName].map((entry) => ({
        ...entry,
        values: scrubReferenceValues(entry.values, additionalActionId),
      })),
    ]),
  ) as EditorCardDocument["behavior"]["groups"];

  return {
    ...document,
    behavior: {
      ...document.behavior,
      groups: nextGroups,
      additionalActions: document.behavior.additionalActions.filter((entry) => entry.id !== additionalActionId),
    },
  };
}

function scrubReferenceValues(
  values: Record<string, unknown>,
  additionalActionId: string,
): Record<string, unknown> {
  const nextValues: Record<string, unknown> = { ...values };
  for (const key of Object.keys(nextValues)) {
    if (!isActionReferenceParameter(key) || !Array.isArray(nextValues[key])) {
      continue;
    }
    nextValues[key] = (nextValues[key] as unknown[]).filter((value) => String(value) !== additionalActionId);
  }
  return nextValues;
}

function createBehaviorEntry(
  token: string,
  metadataList: ScriptMetadata[],
  currentValues?: Record<string, unknown>,
  editorId = createEditorId(),
): BehaviorEntry {
  const metadata = metadataList.find((entry) => entry.resolvedToken === token);
  const defaults = Object.fromEntries(
    (metadata?.parameters ?? []).map((parameter) => [parameter.name, parameter.defaultValue]),
  );
  const nextValues = { ...defaults };
  if (currentValues) {
    for (const key of Object.keys(currentValues)) {
      if (key in nextValues) {
        nextValues[key] = currentValues[key];
      }
    }
  }
  return {
    editorId,
    token,
    values: nextValues,
  };
}

function createAdditionalActionEntry(
  token: string,
  metadataList: ScriptMetadata[],
  existing: AdditionalActionEntry[],
  id = createAdditionalActionId(existing),
): AdditionalActionEntry {
  return {
    ...createBehaviorEntry(token, metadataList, undefined, createEditorId()),
    id,
  };
}

function createAdditionalActionId(existing: AdditionalActionEntry[]) {
  let index = 1;
  while (existing.some((entry) => entry.id === `additional_action_${index}`)) {
    index += 1;
  }
  return `additional_action_${index}`;
}

function createEditorId() {
  return `entry_${Math.random().toString(36).slice(2, 10)}`;
}

function moveItem<T>(items: T[], index: number, delta: -1 | 1) {
  const targetIndex = index + delta;
  if (targetIndex < 0 || targetIndex >= items.length) {
    return items;
  }
  const nextItems = [...items];
  const [item] = nextItems.splice(index, 1);
  nextItems.splice(targetIndex, 0, item);
  return nextItems;
}

function getDefaultSelection(document: EditorCardDocument): Selection {
  const existing = (window as Window & { __cardEditorSelection?: Selection }).__cardEditorSelection;
  if (existing?.kind === "group") {
    const exists = document.behavior.groups[existing.groupName].some(
      (entry) => entry.editorId === existing.entryId,
    );
    if (exists) {
      return existing;
    }
  }
  if (existing?.kind === "additional") {
    const exists = document.behavior.additionalActions.some((entry) => entry.id === existing.id);
    if (exists) {
      return existing;
    }
  }
  for (const groupName of Object.keys(document.behavior.groups) as BehaviorGroupName[]) {
    const entry = document.behavior.groups[groupName][0];
    if (entry) {
      return { kind: "group", groupName, entryId: entry.editorId };
    }
  }
  const additionalAction = document.behavior.additionalActions[0];
  if (additionalAction) {
    return { kind: "additional", id: additionalAction.id };
  }
  return null;
}
