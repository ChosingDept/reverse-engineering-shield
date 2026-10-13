# AI features and on-device models

Prompts, routing rules and fine-tuned weights are often a product's most valuable part.

## Prompts and agent logic

- System prompts, few-shot examples, tool definitions and routing logic live on the
  server. The client sends the user's input and receives the answer.
- Do not stream internal reasoning, tool calls or retrieved documents to the client
  unless the user is meant to see them.
- Guard against prompt-extraction attempts at the server (output filters, refusal of
  "repeat your instructions", monitoring), and assume a determined user may still
  extract parts of a prompt — keep the prompt free of secrets.

## Calling LLM providers

- Never call a paid model provider directly from a client with your key. Route through
  your API with per-user auth, quotas and logging.

## On-device models (ONNX, TFLite, Core ML, GGUF, safetensors)

- Weights shipped in an app can be copied and reused. Ship on-device only what you
  accept losing (small, generic or distilled models); keep the differentiating model
  behind your API.
- If you must ship a valuable model, use platform-provided encryption where available
  (for example, Core ML model encryption), and watermark models per release.
- Keep training data, evaluation sets and fine-tuning configs out of the app bundle.

## Verify

```bash
SHIELD_TERMS="You are,system prompt" scripts/audit.sh dist/
```

Check by hand which model files the final bundle contains.
