defmodule JSONSchemaEditorTest do
  use ExUnit.Case, async: true
  import Phoenix.LiveViewTest
  alias JSONSchemaEditor

  defp setup_socket(schema \\ %{"type" => "object", "properties" => %{}}) do
    %Phoenix.LiveView.Socket{
      assigns: %{
        id: "test",
        schema: schema,
        ui_state: %{},
        validation_errors: %{},
        __changed__: %{},
        on_save: nil
      }
    }
  end

  test "renders the component" do
    html =
      render_component(JSONSchemaEditor,
        id: "jse",
        schema: %{"type" => "object", "title" => "Test Schema"}
      )

    assert html =~ "jse-container"
    assert html =~ "Test Schema"
  end

  test "supports soft encapsulation (custom class and rest attributes)" do
    html =
      render_component(JSONSchemaEditor,
        id: "jse",
        schema: %{"type" => "object"},
        class: "my-custom-class",
        "data-testid": "json-editor-component",
        style: "margin-top: 2rem;"
      )

    assert html =~ "jse-host"
    assert html =~ "my-custom-class"
    assert html =~ "data-testid=\"json-editor-component\""
    assert html =~ "style=\"margin-top: 2rem;\""
  end

  test "renders with different types and states" do
    # Object with properties
    schema = %{
      "type" => "object",
      "properties" => %{"name" => %{"type" => "string"}},
      "required" => ["name"]
    }

    html = render_component(JSONSchemaEditor, id: "jse", schema: schema)
    assert html =~ "name"
    assert html =~ "Req"

    # String with expanded constraints
    path_json = JSON.encode!([])
    ui_state = %{"expanded_constraints:#{path_json}" => true}

    html =
      render_component(JSONSchemaEditor,
        id: "jse",
        schema: %{"type" => "string"},
        ui_state: ui_state
      )

    assert html =~ "Min Length"
    assert html =~ "Pattern"

    # Number with expanded constraints
    html =
      render_component(JSONSchemaEditor,
        id: "jse",
        schema: %{"type" => "number"},
        ui_state: ui_state
      )

    assert html =~ "Minimum"
    assert html =~ "Multiple Of"

    # Array with expanded constraints
    html =
      render_component(JSONSchemaEditor,
        id: "jse",
        schema: %{"type" => "array"},
        ui_state: ui_state
      )

    assert html =~ "Min Items"
    assert html =~ "Unique Items"

    # Object with expanded constraints
    html =
      render_component(JSONSchemaEditor,
        id: "jse",
        schema: %{"type" => "object"},
        ui_state: ui_state
      )

    assert html =~ "Min Props"

    # Expanded description
    ui_state = %{"expanded_description:#{path_json}" => true}

    html =
      render_component(JSONSchemaEditor,
        id: "jse",
        schema: %{"type" => "string", "description" => "Long desc"},
        ui_state: ui_state
      )

    assert html =~ "textarea"
    assert html =~ "Long desc"

    # Enum section
    ui_state = %{"expanded_constraints:#{path_json}" => true}

    html =
      render_component(JSONSchemaEditor,
        id: "jse",
        schema: %{"type" => "string", "enum" => ["A", "B"]},
        ui_state: ui_state
      )

    assert html =~ "Enum Values"
    assert html =~ "value=\"A\""
    assert html =~ "value=\"B\""

    # Collapsed node
    schema = %{"type" => "object", "properties" => %{"hidden_field" => %{"type" => "string"}}}
    ui_state = %{"collapsed_node:#{path_json}" => true}
    html = render_component(JSONSchemaEditor, id: "jse", schema: schema, ui_state: ui_state)
    assert html =~ "jse-collapsed"

    # Check that it's hidden in the editor pane
    refute html =~ "hidden_field"

    # Preview panel rendering (requires switching tab or manual check)
    # We'll check this in a separate test for tab switching logic

    # Logic composition rendering
    schema = %{"oneOf" => [%{"type" => "string"}, %{"type" => "number"}]}
    html = render_component(JSONSchemaEditor, id: "jse", schema: schema)
    assert html =~ "Oneof Branches"
    assert html =~ "Branch 1"
    assert html =~ "Branch 2"

    schema = %{"anyOf" => [%{"type" => "string"}]}
    html = render_component(JSONSchemaEditor, id: "jse", schema: schema)
    assert html =~ "Anyof Branches"

    schema = %{"allOf" => [%{"type" => "string"}]}
    html = render_component(JSONSchemaEditor, id: "jse", schema: schema)
    assert html =~ "Allof Branches"

    # Array items rendering (triggers badge-info and plus icon)
    schema = %{"type" => "array", "items" => %{"type" => "string"}}
    html = render_component(JSONSchemaEditor, id: "jse", schema: schema)
    assert html =~ "jse-badge-info"
  end

  test "handles tab switching and preview rendering" do
    # Default is editor tab
    html = render_component(JSONSchemaEditor, id: "jse", schema: %{"type" => "string"})
    assert html =~ "class=\"jse-editor-pane\""
    refute html =~ "class=\"jse-preview-panel\""

    # Switch to preview tab
    html =
      render_component(JSONSchemaEditor,
        id: "jse",
        schema: %{"type" => "string"},
        active_tab: :preview
      )

    refute html =~ "class=\"jse-editor-pane\""
    assert html =~ "class=\"jse-preview-panel\""
    assert html =~ "Current Schema"
    assert html =~ "jse-code-block"
  end

  test "renders badge with custom class" do
    html = render_component(JSONSchemaEditor, id: "jse", schema: %{"type" => "array"})
    # The default badge has no extra class, but let's force check the badge component
    # Since badge is private, we check it through the main render which uses it
    assert html =~ "jse-badge"
  end

  test "handle_event update_enum_value with unknown type" do
    # Create a socket with a fake type to trigger the default branch in cast_value_by_type
    socket = setup_socket(%{"type" => "unknown", "enum" => ["old"]})
    path_json = JSON.encode!([])

    {:noreply, socket} =
      JSONSchemaEditor.handle_event(
        "update_enum_value",
        %{"path" => path_json, "index" => "0", "value" => "new"},
        socket
      )

    assert socket.assigns.schema["enum"] == ["new"]
  end

  test "handle_event save without callback (noop)" do
    socket = setup_socket(%{"type" => "string"})
    # on_save is nil by default in setup_socket
    {:noreply, _socket} = JSONSchemaEditor.handle_event("save", %{}, socket)
    # Just ensuring it doesn't crash
  end

  test "update/2 initializes schema and defaults" do
    assigns = %{id: "test"}
    {:ok, socket} = JSONSchemaEditor.update(assigns, %Phoenix.LiveView.Socket{})
    assert socket.assigns.schema == %{"type" => "object", "properties" => %{}}
    assert socket.assigns.ui_state == %{}

    assigns = %{id: "test", schema: %{"type" => "string"}}
    {:ok, socket} = JSONSchemaEditor.update(assigns, %Phoenix.LiveView.Socket{})
    assert socket.assigns.schema == %{"type" => "string"}
  end

  test "handle_event change_type" do
    socket = setup_socket()
    path_json = JSON.encode!([])

    # To object
    {:noreply, socket} =
      JSONSchemaEditor.handle_event(
        "change_type",
        %{"path" => path_json, "type" => "object"},
        socket
      )

    assert socket.assigns.schema["type"] == "object"
    assert is_map(socket.assigns.schema["properties"])

    # To array
    {:noreply, socket} =
      JSONSchemaEditor.handle_event(
        "change_type",
        %{"path" => path_json, "type" => "array"},
        socket
      )

    assert socket.assigns.schema["type"] == "array"
    assert socket.assigns.schema["items"] == %{"type" => "string"}

    # To string
    {:noreply, socket} =
      JSONSchemaEditor.handle_event(
        "change_type",
        %{"path" => path_json, "type" => "string"},
        socket
      )

    assert socket.assigns.schema == %{"type" => "string"}
  end

  test "handle_event add_property" do
    socket = setup_socket()
    path_json = JSON.encode!([])

    {:noreply, socket} =
      JSONSchemaEditor.handle_event("add_property", %{"path" => path_json}, socket)

    assert Map.has_key?(socket.assigns.schema["properties"], "new_field")

    # Add another
    {:noreply, socket} =
      JSONSchemaEditor.handle_event("add_property", %{"path" => path_json}, socket)

    assert Map.has_key?(socket.assigns.schema["properties"], "new_field_2")
  end

  test "handle_event delete_property" do
    schema = %{
      "type" => "object",
      "properties" => %{"name" => %{"type" => "string"}},
      "required" => ["name"]
    }

    socket = setup_socket(schema)
    path_json = JSON.encode!([])

    {:noreply, socket} =
      JSONSchemaEditor.handle_event(
        "delete_property",
        %{"path" => path_json, "key" => "name"},
        socket
      )

    assert socket.assigns.schema["properties"] == %{}
    assert socket.assigns.schema["required"] == []
  end

  test "handle_event toggle_required" do
    schema = %{"type" => "object", "properties" => %{"name" => %{"type" => "string"}}}
    socket = setup_socket(schema)
    path_json = JSON.encode!([])

    # On
    {:noreply, socket} =
      JSONSchemaEditor.handle_event(
        "toggle_required",
        %{"path" => path_json, "key" => "name"},
        socket
      )

    assert socket.assigns.schema["required"] == ["name"]

    # Off
    {:noreply, socket} =
      JSONSchemaEditor.handle_event(
        "toggle_required",
        %{"path" => path_json, "key" => "name"},
        socket
      )

    assert socket.assigns.schema["required"] == []
  end

  test "handle_event rename_property" do
    schema = %{
      "type" => "object",
      "properties" => %{"a" => %{"type" => "string"}},
      "required" => ["a"]
    }

    socket = setup_socket(schema)
    path_json = JSON.encode!([])

    # Normal rename
    {:noreply, socket} =
      JSONSchemaEditor.handle_event(
        "rename_property",
        %{"path" => path_json, "old_key" => "a", "value" => "b"},
        socket
      )

    assert Map.has_key?(socket.assigns.schema["properties"], "b")
    refute Map.has_key?(socket.assigns.schema["properties"], "a")
    assert socket.assigns.schema["required"] == ["b"]

    # Rename to existing (no-op)
    socket = setup_socket(%{"type" => "object", "properties" => %{"a" => %{}, "b" => %{}}})

    {:noreply, socket} =
      JSONSchemaEditor.handle_event(
        "rename_property",
        %{"path" => path_json, "old_key" => "a", "value" => "b"},
        socket
      )

    assert Map.has_key?(socket.assigns.schema["properties"], "a")

    # Rename to empty (no-op)
    {:noreply, socket} =
      JSONSchemaEditor.handle_event(
        "rename_property",
        %{"path" => path_json, "old_key" => "a", "value" => " "},
        socket
      )

    assert Map.has_key?(socket.assigns.schema["properties"], "a")
  end

  test "handle_event change_title and change_description" do
    socket = setup_socket()
    path_json = JSON.encode!([])

    {:noreply, socket} =
      JSONSchemaEditor.handle_event(
        "change_title",
        %{"path" => path_json, "value" => "Hello"},
        socket
      )

    assert socket.assigns.schema["title"] == "Hello"

    {:noreply, socket} =
      JSONSchemaEditor.handle_event(
        "change_description",
        %{"path" => path_json, "value" => "World"},
        socket
      )

    assert socket.assigns.schema["description"] == "World"

    # Clearing
    {:noreply, socket} =
      JSONSchemaEditor.handle_event("change_title", %{"path" => path_json, "value" => ""}, socket)

    refute Map.has_key?(socket.assigns.schema, "title")
  end

  test "handle_event toggle visibility flags" do
    socket = setup_socket()
    path_json = JSON.encode!([])

    {:noreply, socket} =
      JSONSchemaEditor.handle_event(
        "toggle_ui",
        %{"path" => path_json, "type" => "expanded_description"},
        socket
      )

    assert socket.assigns.ui_state["expanded_description:#{path_json}"]

    {:noreply, socket} =
      JSONSchemaEditor.handle_event(
        "toggle_ui",
        %{"path" => path_json, "type" => "expanded_constraints"},
        socket
      )

    assert socket.assigns.ui_state["expanded_constraints:#{path_json}"]

    {:noreply, socket} =
      JSONSchemaEditor.handle_event(
        "toggle_ui",
        %{"path" => path_json, "type" => "collapsed_node"},
        socket
      )

    assert socket.assigns.ui_state["collapsed_node:#{path_json}"]
  end

  test "handle_event update_constraint" do
    socket = setup_socket(%{"type" => "string"})
    path_json = JSON.encode!([])

    # Integer
    {:noreply, socket} =
      JSONSchemaEditor.handle_event(
        "update_constraint",
        %{"path" => path_json, "field" => "minLength", "value" => "10"},
        socket
      )

    assert socket.assigns.schema["minLength"] == 10

    # Float
    socket = setup_socket(%{"type" => "number"})

    {:noreply, socket} =
      JSONSchemaEditor.handle_event(
        "update_constraint",
        %{"path" => path_json, "field" => "minimum", "value" => "1.5"},
        socket
      )

    assert socket.assigns.schema["minimum"] == 1.5

    # Boolean
    socket = setup_socket(%{"type" => "array"})

    {:noreply, socket} =
      JSONSchemaEditor.handle_event(
        "update_constraint",
        %{"path" => path_json, "field" => "uniqueItems", "value" => "true"},
        socket
      )

    assert socket.assigns.schema["uniqueItems"] == true

    # Clearing
    {:noreply, socket} =
      JSONSchemaEditor.handle_event(
        "update_constraint",
        %{"path" => path_json, "field" => "uniqueItems", "value" => ""},
        socket
      )

    refute Map.has_key?(socket.assigns.schema, "uniqueItems")

    # Unknown field (default case in cast)
    {:noreply, socket} =
      JSONSchemaEditor.handle_event(
        "update_constraint",
        %{"path" => path_json, "field" => "unknown", "value" => "foo"},
        socket
      )

    assert socket.assigns.schema["unknown"] == "foo"

    # Invalid number (Integer.parse failure)
    {:noreply, socket} =
      JSONSchemaEditor.handle_event(
        "update_constraint",
        %{"path" => path_json, "field" => "minLength", "value" => "abc"},
        socket
      )

    refute Map.has_key?(socket.assigns.schema, "minLength")

    # Invalid float (Float.parse failure)
    {:noreply, socket} =
      JSONSchemaEditor.handle_event(
        "update_constraint",
        %{"path" => path_json, "field" => "minimum", "value" => "abc"},
        socket
      )

    refute Map.has_key?(socket.assigns.schema, "minimum")
  end

  test "handle_event rename_property edge cases" do
    socket = setup_socket(%{"type" => "object", "properties" => %{"a" => %{}}})
    path_json = JSON.encode!([])

    # Rename to same key (should be no-reply socket unchanged)
    {:noreply, ^socket} =
      JSONSchemaEditor.handle_event(
        "rename_property",
        %{"path" => path_json, "old_key" => "a", "value" => "a"},
        socket
      )
  end

  test "handle_event save" do
    parent = self()
    on_save = fn schema -> send(parent, {:saved, schema}) end
    socket = setup_socket(%{"type" => "string"})
    socket = Phoenix.Component.assign(socket, on_save: on_save)

    # Success case
    {:noreply, _socket} = JSONSchemaEditor.handle_event("save", %{}, socket)
    assert_receive {:saved, %{"type" => "string"}}

    # Failure case (with errors)
    socket = Phoenix.Component.assign(socket, validation_errors: %{"key" => "error"})
    {:noreply, _socket} = JSONSchemaEditor.handle_event("save", %{}, socket)
    refute_receive {:saved, _}
  end

  test "handle_event logic composition" do
    socket = setup_socket()
    path_json = JSON.encode!([])

    # Change to oneOf
    {:noreply, socket} =
      JSONSchemaEditor.handle_event(
        "change_type",
        %{"path" => path_json, "type" => "oneOf"},
        socket
      )

    assert Map.has_key?(socket.assigns.schema, "oneOf")
    assert length(socket.assigns.schema["oneOf"]) == 1

    # Add branch
    {:noreply, socket} =
      JSONSchemaEditor.handle_event(
        "add_logic_branch",
        %{"path" => path_json, "type" => "oneOf"},
        socket
      )

    assert length(socket.assigns.schema["oneOf"]) == 2

    # Remove branch
    {:noreply, socket} =
      JSONSchemaEditor.handle_event(
        "remove_logic_branch",
        %{"path" => path_json, "type" => "oneOf", "index" => "0"},
        socket
      )

    assert length(socket.assigns.schema["oneOf"]) == 1

    # Remove last branch (should revert to string)
    {:noreply, socket} =
      JSONSchemaEditor.handle_event(
        "remove_logic_branch",
        %{"path" => path_json, "type" => "oneOf", "index" => "0"},
        socket
      )

    assert socket.assigns.schema["type"] == "string"
    refute Map.has_key?(socket.assigns.schema, "oneOf")

    # anyOf and allOf types
    {:noreply, socket} =
      JSONSchemaEditor.handle_event(
        "change_type",
        %{"path" => path_json, "type" => "anyOf"},
        socket
      )

    assert Map.has_key?(socket.assigns.schema, "anyOf")

    {:noreply, socket} =
      JSONSchemaEditor.handle_event(
        "change_type",
        %{"path" => path_json, "type" => "allOf"},
        socket
      )

    assert Map.has_key?(socket.assigns.schema, "allOf")
  end

  test "handle_event rename to existing key (noop)" do
    schema = %{
      "type" => "object",
      "properties" => %{"a" => %{"type" => "string"}, "b" => %{"type" => "number"}}
    }

    socket = setup_socket(schema)
    path_json = JSON.encode!([])

    {:noreply, socket} =
      JSONSchemaEditor.handle_event(
        "rename_property",
        %{"path" => path_json, "old_key" => "a", "value" => "b"},
        socket
      )

    assert Map.has_key?(socket.assigns.schema["properties"], "a")
    assert Map.has_key?(socket.assigns.schema["properties"], "b")
  end

  test "handle_event update_constraint with empty/false values (removal)" do
    schema = %{"type" => "string", "minLength" => 5, "uniqueItems" => true}
    socket = setup_socket(schema)
    path_json = JSON.encode!([])

    # Remove minLength
    {:noreply, socket} =
      JSONSchemaEditor.handle_event(
        "update_constraint",
        %{"path" => path_json, "field" => "minLength", "value" => ""},
        socket
      )

    refute Map.has_key?(socket.assigns.schema, "minLength")

    # Remove uniqueItems
    {:noreply, socket} =
      JSONSchemaEditor.handle_event(
        "update_constraint",
        %{"path" => path_json, "field" => "uniqueItems", "value" => "false"},
        socket
      )

    refute Map.has_key?(socket.assigns.schema, "uniqueItems")
  end

  test "handle_event update_constraint with invalid numbers" do
    socket = setup_socket(%{"type" => "string"})
    path_json = JSON.encode!([])

    # Invalid integer
    {:noreply, socket} =
      JSONSchemaEditor.handle_event(
        "update_constraint",
        %{"path" => path_json, "field" => "minLength", "value" => "abc"},
        socket
      )

    refute Map.has_key?(socket.assigns.schema, "minLength")

    # Invalid float
    socket = setup_socket(%{"type" => "number"})

    {:noreply, socket} =
      JSONSchemaEditor.handle_event(
        "update_constraint",
        %{"path" => path_json, "field" => "minimum", "value" => "abc"},
        socket
      )

    refute Map.has_key?(socket.assigns.schema, "minimum")
  end

  test "handle_event change_title and description to empty (removal)" do
    schema = %{"type" => "string", "title" => "T", "description" => "D"}
    socket = setup_socket(schema)
    path_json = JSON.encode!([])

    {:noreply, socket} =
      JSONSchemaEditor.handle_event("change_title", %{"path" => path_json, "value" => ""}, socket)

    refute Map.has_key?(socket.assigns.schema, "title")

    {:noreply, socket} =
      JSONSchemaEditor.handle_event(
        "change_description",
        %{"path" => path_json, "value" => "  "},
        socket
      )

    refute Map.has_key?(socket.assigns.schema, "description")
  end

  test "renders no constraints for boolean type" do
    html =
      render_component(JSONSchemaEditor,
        id: "jse",
        schema: %{"type" => "boolean"},
        ui_state: %{"expanded_constraints:[]" => true}
      )

    assert html =~ "No constraints for this type"
  end

  test "handle_event enum management" do
    socket = setup_socket(%{"type" => "string"})
    path_json = JSON.encode!([])

    # Add
    {:noreply, socket} =
      JSONSchemaEditor.handle_event("add_enum_value", %{"path" => path_json}, socket)

    assert socket.assigns.schema["enum"] == ["new value"]

    # Update
    {:noreply, socket} =
      JSONSchemaEditor.handle_event(
        "update_enum_value",
        %{"path" => path_json, "index" => "0", "value" => "fixed"},
        socket
      )

    assert socket.assigns.schema["enum"] == ["fixed"]

    # Add another
    {:noreply, socket} =
      JSONSchemaEditor.handle_event("add_enum_value", %{"path" => path_json}, socket)

    assert socket.assigns.schema["enum"] == ["fixed", "new value"]

    # Remove
    {:noreply, socket} =
      JSONSchemaEditor.handle_event(
        "remove_enum_value",
        %{"path" => path_json, "index" => "0"},
        socket
      )

    assert socket.assigns.schema["enum"] == ["new value"]

    # Remove last one
    {:noreply, socket} =
      JSONSchemaEditor.handle_event(
        "remove_enum_value",
        %{"path" => path_json, "index" => "0"},
        socket
      )

    refute Map.has_key?(socket.assigns.schema, "enum")

    # Type casting - Number
    socket = setup_socket(%{"type" => "number", "enum" => [0.0]})

    {:noreply, socket} =
      JSONSchemaEditor.handle_event(
        "update_enum_value",
        %{"path" => path_json, "index" => "0", "value" => "1.5"},
        socket
      )

    assert socket.assigns.schema["enum"] == [1.5]

    # Type casting - Integer
    socket = setup_socket(%{"type" => "integer", "enum" => [0]})

    {:noreply, socket} =
      JSONSchemaEditor.handle_event(
        "update_enum_value",
        %{"path" => path_json, "index" => "0", "value" => "10"},
        socket
      )

    assert socket.assigns.schema["enum"] == [10]

    # Type casting - Boolean
    socket = setup_socket(%{"type" => "boolean", "enum" => [true]})

    {:noreply, socket} =
      JSONSchemaEditor.handle_event(
        "update_enum_value",
        %{"path" => path_json, "index" => "0", "value" => "false"},
        socket
      )

    assert socket.assigns.schema["enum"] == [false]

    # Default values for different types
    socket = setup_socket(%{"type" => "number"})

    {:noreply, socket} =
      JSONSchemaEditor.handle_event("add_enum_value", %{"path" => path_json}, socket)

    assert socket.assigns.schema["enum"] == [0.0]

    socket = setup_socket(%{"type" => "integer"})

    {:noreply, socket} =
      JSONSchemaEditor.handle_event("add_enum_value", %{"path" => path_json}, socket)

    assert socket.assigns.schema["enum"] == [0]

    socket = setup_socket(%{"type" => "boolean"})

    {:noreply, socket} =
      JSONSchemaEditor.handle_event("add_enum_value", %{"path" => path_json}, socket)

    assert socket.assigns.schema["enum"] == [true]

    # Invalid casting defaults
    socket = setup_socket(%{"type" => "integer", "enum" => [0]})

    {:noreply, socket} =
      JSONSchemaEditor.handle_event(
        "update_enum_value",
        %{"path" => path_json, "index" => "0", "value" => "abc"},
        socket
      )

    assert socket.assigns.schema["enum"] == [0]

    socket = setup_socket(%{"type" => "number", "enum" => [0.0]})

    {:noreply, socket} =
      JSONSchemaEditor.handle_event(
        "update_enum_value",
        %{"path" => path_json, "index" => "0", "value" => "abc"},
        socket
      )

    assert socket.assigns.schema["enum"] == [0.0]
  end

  test "handle_event toggle_additional_properties" do
    socket = setup_socket(%{"type" => "object"})
    path_json = JSON.encode!([])

    # Enable Strict Mode
    {:noreply, socket} =
      JSONSchemaEditor.handle_event(
        "toggle_additional_properties",
        %{"path" => path_json},
        socket
      )

    assert socket.assigns.schema["additionalProperties"] == false

    # Disable Strict Mode
    {:noreply, socket} =
      JSONSchemaEditor.handle_event(
        "toggle_additional_properties",
        %{"path" => path_json},
        socket
      )

    refute Map.has_key?(socket.assigns.schema, "additionalProperties")
  end

  test "handle_event change_format" do
    socket = setup_socket(%{"type" => "string"})
    path_json = JSON.encode!([])

    # Set format
    {:noreply, socket} =
      JSONSchemaEditor.handle_event(
        "change_format",
        %{"path" => path_json, "value" => "email"},
        socket
      )

    assert socket.assigns.schema["format"] == "email"

    # Unset format
    {:noreply, socket} =
      JSONSchemaEditor.handle_event(
        "change_format",
        %{"path" => path_json, "value" => ""},
        socket
      )

    refute Map.has_key?(socket.assigns.schema, "format")
  end

  test "handle_event switch_tab" do
    socket = setup_socket()

    {:noreply, socket} =
      JSONSchemaEditor.handle_event("switch_tab", %{"tab" => "preview"}, socket)

    assert socket.assigns.active_tab == :preview

    {:noreply, socket} = JSONSchemaEditor.handle_event("switch_tab", %{"tab" => "editor"}, socket)
    assert socket.assigns.active_tab == :editor
  end

  test "renders validation errors" do
    # Schema with an invalid constraint (min > max)
    schema = %{"type" => "string", "minLength" => 10, "maxLength" => 5}
    path_json = JSON.encode!([])
    ui_state = %{"expanded_constraints:#{path_json}" => true}

    html = render_component(JSONSchemaEditor, id: "jse", schema: schema, ui_state: ui_state)

    assert html =~ "Must be ≤ maxLength"
    assert html =~ "jse-input-error"
  end
end
