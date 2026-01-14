# JSON Schema Editor

A Phoenix LiveComponent for visually building and editing JSON Schemas.

## Features

- **Visual Editor**: Intuitive UI for defining JSON Schema structures.
- **Type Support**: Strings, Numbers, Integers, Booleans, Objects, and Arrays.
- **Nested Structures**: Full support for deeply nested objects and properties.
- **Interactive**:
  - Add, remove, and rename properties.
  - Change property types dynamically.
- **Self-Contained**: Includes necessary styles (scoped) and logic.

## Installation

Add `json_schema_editor_lib` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:json_schema_editor_lib, "~> 0.1.0"}
  ]
end
```

## Usage

Use the `JSONSchemaEditor` component within your LiveView.

### 1. Mount the schema

Initialize the schema in your LiveView's `mount/3`:

```elixir
def mount(_params, _session, socket) do
  schema = %{
    "type" => "object",
    "properties" => %{
      "name" => %{"type" => "string"},
      "age" => %{"type" => "integer"}
    }
  }

  {:ok, assign(socket, my_schema: schema)}
end
```

### 2. Render the component

Add the component to your HEEx template. Pass the `schema` and an `on_save` callback.

```heex
<.live_component
  module={JSONSchemaEditor}
  id="json-editor"
  schema={@my_schema}
  on_save={fn updated_schema -> send(self(), {:schema_saved, updated_schema}) end}
/>
```

### 3. Handle updates

Handle the save event in your LiveView:

```elixir
def handle_info({:schema_saved, updated_schema}, socket) do
  # Save to database or perform other actions
  IO.inspect(updated_schema, label: "Schema Saved")
  {:noreply, assign(socket, my_schema: updated_schema)}
end
```

## Running the Demo

A standalone demo script is included in `examples/demo.exs`. You can run it directly:

```bash
elixir examples/demo.exs
```

Then visit `http://localhost:4040` in your browser.