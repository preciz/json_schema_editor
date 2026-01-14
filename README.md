# JSON Schema Editor

A robust Phoenix LiveComponent for visually building, editing, and validating JSON Schemas.

## Features

- **Visual Editing**: Recursively build and edit deeply nested objects and arrays.
- **Real-time Validation**: In-editor logic checking (e.g., `min <= max`) with visual feedback.
- **Full Schema Support**: Easily manage constraints, enums, titles, and descriptions.
- **Optimized for Large Schemas**: Collapsible nodes for easier navigation of complex trees.
- **Isolated Styles**: Scoped CSS to ensure seamless integration into any Phoenix application.
- **Lightweight**: The only dependency is `phoenix_live_view`.

## Installation

Add `json_schema_editor` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:json_schema_editor, "~> 0.1.0"}
  ]
end
```

## Usage

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
