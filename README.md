# JSON Schema Editor

A robust Phoenix LiveComponent for visually building, editing, and validating JSON Schemas.

## Features

- **Visual Editor**: Intuitive UI for defining complex JSON Schema structures.
- **Recursive Depth**: Full support for deeply nested objects and array items.
- **Logical Validation**: 
    - Real-time checking of constraints (e.g., `minLength` vs `maxLength`, `minItems` vs `maxItems`).
    - Visual error feedback (red borders and descriptive messages).
    - Prevents saving if the schema is in an invalid state.
- **Advanced Constraints**:
    - **Strings**: minLength, maxLength, pattern.
    - **Numbers**: minimum, maximum, multipleOf.
    - **Arrays**: minItems, maxItems, uniqueItems.
    - **Objects**: minProperties, maxProperties, required fields.
- **Enum Support**: Type-safe management of enumeration values.
- **Metadata**: Support for `title` and `description` at every node level.
- **UX Focused**:
    - **Collapsible Nodes**: Collapse/Expand entire object/array trees for better navigation.
    - **UI Isolation**: Scoped CSS styles (`jse-` prefix) to prevent host application conflicts.
    - **Pure State**: UI-specific states (expansion/collapse) are separated from the exported JSON Schema.
- **Testing**: Maintained with ~100% test coverage.

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
