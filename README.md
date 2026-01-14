# JSON Schema Editor

[![test](https://github.com/preciz/json_schema_editor/actions/workflows/test.yml/badge.svg?branch=master)](https://github.com/preciz/json_schema_editor/actions/workflows/test.yml)

A robust Phoenix LiveComponent for visually building, editing, and validating JSON Schemas.

## Features

- **Visual Editing**: Recursively build and edit deeply nested objects and arrays.
- **Real-time Validation**: In-editor logic checking (e.g., `min <= max`) with visual feedback.
- **Full Schema Support**: Easily manage constraints, enums, titles, and descriptions.
- **Optimized for Large Schemas**: Collapsible nodes for easier navigation of complex trees.
- **Isolated Styles**: Scoped CSS to ensure seamless integration into any Phoenix application.
- **Lightweight**: The only dependency is `phoenix_live_view`.

## Installation

The package can be installed by adding `json_schema_editor` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:json_schema_editor, "~> 0.1.0"}
  ]
end
```

### Asset Integration

This library uses Tailwind CSS and a small JavaScript hook for clipboard functionality.

#### 1. Configure CSS

**For Tailwind v4:**
Add the following to your `app.css`:

```css
@import "tailwindcss";
@import "../../deps/json_schema_editor/assets/css/json_schema_editor.css";

/* Ensure Tailwind scans the library for classes */
@source "../../deps/json_schema_editor/lib/**/*.ex";
```

**For Tailwind v3:**
Update your `tailwind.config.js`:

```javascript
module.exports = {
  content: [
    "./js/**/*.js",
    "../lib/*_web/**/*.*ex",
    "../deps/json_schema_editor/lib/**/*.ex" // Add this line
  ],
  // ...
}
```

And import the CSS in your `app.css`:

```css
@import "../../deps/json_schema_editor/assets/css/json_schema_editor.css";
```

#### 2. Configure JavaScript Hooks

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
