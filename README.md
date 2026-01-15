# JSON Schema Editor

[![test](https://github.com/preciz/json_schema_editor/actions/workflows/test.yml/badge.svg?branch=master)](https://github.com/preciz/json_schema_editor/actions/workflows/test.yml)

A Phoenix LiveComponent for visually building, editing, and validating JSON Schemas.

![JSON Schema Editor Screenshot](screenshot.png)

## Features

- **Visual Editing**: Recursively build and edit deeply nested objects and arrays.
- **Tabbed Interface**: Switch between a visual editor and a live JSON preview.
- **Logical Composition**: Support for `oneOf`, `anyOf`, and `allOf` composition types.
- **Real-time Validation**: In-editor logic checking (e.g., `min <= max`) with immediate visual feedback.
- **Full Draft 07 Support**: Includes constraints (minimum, pattern, etc.), enums, constants, and $schema management.
- **Copy to Clipboard**: One-click export of the generated schema.
- **Lightweight**: Zero external JS dependencies (uses native Phoenix hooks), only requires `phoenix_live_view`.

## Installation

This library uses a small CSS file for styling and a JavaScript hook for clipboard functionality.

#### 1. Add `json_schema_editor` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:json_schema_editor, "~> 0.3.0"}
  ]
end
```

#### 2. Import the library's CSS in your `assets/css/app.css` (or equivalent):

```css
@import "../../deps/json_schema_editor/assets/css/json_schema_editor.css";
```

#### 3. Configure JavaScript Hooks (Clipboard Support):

In your `assets/js/app.js`, import and register the hook:

```javascript
import { Hooks as JSEHooks } from "../../deps/json_schema_editor/assets/js/json_schema_editor"

// ... existing hooks
let liveSocket = new LiveSocket("/live", Socket, {
  params: {_csrf_token: csrfToken},
  hooks: { ...JSEHooks, ...other_hooks }
})
```

## Usage

The editor supports JSON Schema Draft 07. It automatically injects the `$schema` URI if not provided.

### 1. Initialize the Schema

```elixir
def mount(_params, _session, socket) do
  schema = %{
    "type" => "object",
    "properties" => %{
      "user" => %{
        "type" => "object",
        "properties" => %{
          "name" => %{"type" => "string", "minLength" => 2}
        }
      }
    }
  }

  {:ok, assign(socket, my_schema: schema)}
end
```

### 2. Render the Component

```heex
<.live_component
  module={JSONSchemaEditor}
  id="json-editor"
  schema={@my_schema}
  on_save={fn updated_schema -> send(self(), {:schema_saved, updated_schema}) end}
/>
```

### 3. Handle Updates

```elixir
def handle_info({:schema_saved, updated_schema}, socket) do
  # The schema is guaranteed to be logically consistent here
  {:noreply, assign(socket, my_schema: updated_schema)}
end
```

## Development

### Running Tests
```bash
mix test --cover
```

### Running the Demo
```bash
elixir examples/demo.exs
```
Visit `http://localhost:4040` to see the editor in action with a sample schema.
