import { useEffect, useState } from "react";

type JsonEditorProps = {
  label: string;
  value: unknown;
  onChange: (value: unknown) => void;
  height?: number;
};

export function JsonEditor({ label, value, onChange, height = 160 }: JsonEditorProps) {
  const [text, setText] = useState(() => JSON.stringify(value, null, 2));
  const [error, setError] = useState("");

  useEffect(() => {
    setText(JSON.stringify(value, null, 2));
    setError("");
  }, [value]);

  return (
    <label className="field-stack">
      <span className="field-label">{label}</span>
      <textarea
        className="json-editor"
        style={{ minHeight: `${height}px` }}
        value={text}
        onChange={(event) => setText(event.target.value)}
        onBlur={() => {
          try {
            const parsed = JSON.parse(text);
            setError("");
            onChange(parsed);
          } catch (caughtError) {
            setError(caughtError instanceof Error ? caughtError.message : "Invalid JSON.");
          }
        }}
      />
      {error ? <span className="field-error">{error}</span> : null}
    </label>
  );
}
