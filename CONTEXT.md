# Easydict

A macOS dictionary and translation app. This glossary pins down the ubiquitous
language for the text-task and service model, especially where the code has
historically conflated a task with the service that runs it.

## Language

### Tasks

**Polish**:
A text task that refines written text in its own (source) language for clarity,
coherence, grammar, and fluency, while preserving the original meaning. It does
not translate. A task, not a service - any engine service can execute it by
applying the polishing prompt.
_Avoid_: Polishing service (a service is the engine, not the task)

**Translate**:
A text task that converts text from a source language to a target language.

### Services

**Service**:
A provider that runs text tasks against a backend. Easydict splits services into
two kinds: engine services and task services.

**Engine service**:
A streaming service that executes any task's prompt on its own backend - e.g.
OpenAI, BuiltInAI, Gemini, Claude, Custom OpenAI, Ollama. Eligible to be picked
as the engine for the replace actions.
_Avoid_: Calling Polishing or Summary an engine

**Task service**:
A service that *is* a task: it owns a specific prompt and builds its own messages
(Polishing, Summary). Not an engine; excluded from the replace-action picker.

**Built-in service**:
A service whose API key and endpoint ship bundled with the app (BuiltInAI),
usable out of the box.

**Third-party service**:
A service the user configures with their own credentials (OpenAI, Custom OpenAI,
Gemini, Claude, …).
