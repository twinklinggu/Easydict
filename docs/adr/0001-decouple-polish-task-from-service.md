# Decouple AI-tool tasks (polish) from the service; inject the task prompt per-request

`translateAndReplace` / `polishAndReplace` hardcoded `BuiltInAIService` / `PolishingService`,
and `PolishingService`'s identity was its prompt (a `ServiceType` owning a prompt), so
pointing the action at a third-party service lost polish semantics - the prompt lived in a
`chatMessageDicts` class override the third-party service did not share. We model polish as
a task (a prompt) separate from the engine (a `StreamService`): factor the polishing prompt
into a shared builder, carry pre-built `[ChatMessage]` through `TranslationRequest` ->
`ChatQueryParam`, and have `chatMessageDicts` return them when present so any streaming
engine runs them on its own backend. Translate uses the engine's default path; polish
injects the polishing prompt.

## Considered Options

- Refactor `PolishingService` / `AIToolService` into a prompt layer over a configurable
  engine (composition over inheritance): rejected - larger refactor of a hierarchy that
  `SummaryService` also depends on, for the same outcome.
- Reuse the per-service custom-prompt config (`enableCustomPrompt` / `systemPrompt` /
  `userPrompt`): rejected - wrong scope (global per service, can't carry the few-shot pairs
  or the dynamic user template, and clobbers the user's own custom-prompt settings).

## Consequences

Polish semantics are preserved (source-language refinement; ignores target language).
`PolishingService` stays (main-window polish is unchanged) but delegates prompt-building to
the shared builder - one source of truth. Eligible engines exclude the task-services
`Polishing` / `Summary` (they override `chatMessageDicts` and would ignore the injected
prompt) and all non-streaming translators. Selection is instance-level (`type#uuid`) from
the main translation window's configured service list, with stale-selection fallback to
`BuiltInAI`; selected-service failures (missing API key, missing CLI binary, streaming
error) surface visible errors.
