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

  describe "rendering" do
    test "renders object properties" do
      schema = %{
        "type" => "object",
        "properties" => %{"name" => %{"type" => "string"}},
        "required" => ["name"]
      }

      html = render_component(JSONSchemaEditor, id: "jse", schema: schema)
      assert html =~ "name"
      assert html =~ "Req"
    end

    test "renders expanded constraints" do
      path_json = JSON.encode!([])
      ui_state = %{"expanded_constraints:#{path_json}" => true}

      scenarios = [
        {"string", ["Min Length", "Pattern"]},
        {"number", ["Minimum", "Multiple Of"]},
        {"array", ["Min Items", "Unique Items"]},
        {"object", ["Min Props"]}
      ]

      for {type, expected_texts} <- scenarios do
        html =
          render_component(JSONSchemaEditor,
            id: "jse",
            schema: %{"type" => type},
            ui_state: ui_state
          )

        for text <- expected_texts, do: assert(html =~ text)
      end
    end

    test "renders advanced features" do
      path_json = JSON.encode!([])

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
      refute html =~ "hidden_field"

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

      # Array items rendering
      schema = %{"type" => "array", "items" => %{"type" => "string"}}
      html = render_component(JSONSchemaEditor, id: "jse", schema: schema)
      assert html =~ "jse-badge-info"
    end
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



  test "handle_event save without callback (noop)" do
    socket = setup_socket(%{"type" => "string"})
    # on_save is nil by default in setup_socket
    {:noreply, _socket} = JSONSchemaEditor.handle_event("save", %{}, socket)
    # Just ensuring it doesn't crash
  end

  test "update/2 initializes schema and defaults" do
    assigns = %{id: "test"}
    {:ok, socket} = JSONSchemaEditor.update(assigns, %Phoenix.LiveView.Socket{})

    assert socket.assigns.schema == %{
             "$schema" => "https://json-schema.org/draft-07/schema"
           }

    assert socket.assigns.active_tab == :editor
    assert is_map(socket.assigns.ui_state)

    # Test with existing schema
    assigns = %{id: "test", schema: %{"type" => "string"}}
    {:ok, socket} = JSONSchemaEditor.update(assigns, %Phoenix.LiveView.Socket{})

    assert socket.assigns.schema == %{
             "type" => "string",
             "$schema" => "https://json-schema.org/draft-07/schema"
           }

    # Test with existing $schema (preserve)
    assigns = %{id: "test", schema: %{"$schema" => "custom"}}
    {:ok, socket} = JSONSchemaEditor.update(assigns, %Phoenix.LiveView.Socket{})

    assert socket.assigns.schema["$schema"] == "custom"
  end

  test "handle_event delete_property (not required)" do
    schema = %{
      "type" => "object",
      "properties" => %{"name" => %{"type" => "string"}},
      "required" => []
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

    for type <- ["expanded_description", "expanded_constraints", "collapsed_node"] do
      {:noreply, socket} =
        JSONSchemaEditor.handle_event(
          "toggle_ui",
          %{"path" => path_json, "type" => type},
          socket
        )

      assert socket.assigns.ui_state["#{type}:#{path_json}"]

      # Toggle off
      {:noreply, socket} =
        JSONSchemaEditor.handle_event(
          "toggle_ui",
          %{"path" => path_json, "type" => type},
          socket
        )

      refute socket.assigns.ui_state["#{type}:#{path_json}"]
    end
  end

  describe "handle_event update_constraint" do
    test "updates constraints correctly based on type and input" do
      scenarios = [
        # {schema_type, field, value, expected_result (check key/value)}
        {"string", "minLength", "10", {"minLength", 10}},
        {"number", "minimum", "1.5", {"minimum", 1.5}},
        {"array", "uniqueItems", "true", {"uniqueItems", true}},
        # Clearing values
        {"string", "minLength", "", {"minLength", nil}},
        {"array", "uniqueItems", "false", {"uniqueItems", nil}},
        # Unknown field
        {"string", "unknown", "foo", {"unknown", "foo"}},
        # Invalid inputs
        {"string", "minLength", "abc", {"minLength", nil}},
        {"number", "minimum", "abc", {"minimum", nil}}
      ]

      path_json = JSON.encode!([])

      for {type, field, value, {key, expected_val}} <- scenarios do
        # Initialize schema with the key set if we expect to test removal/modification
        initial_schema =
          case type do
            "string" -> %{"type" => "string", "minLength" => 5}
            "number" -> %{"type" => "number", "minimum" => 10}
            "array" -> %{"type" => "array", "uniqueItems" => true}
            _ -> %{"type" => type}
          end

        socket = setup_socket(initial_schema)

        {:noreply, socket} =
          JSONSchemaEditor.handle_event(
            "update_constraint",
            %{"path" => path_json, "field" => field, "value" => value},
            socket
          )

        if expected_val == nil do
          refute Map.has_key?(socket.assigns.schema, key),
                 "Expected key #{key} to be removed for input #{inspect(value)}"
        else
          assert socket.assigns.schema[key] == expected_val,
                 "Expected #{key} to be #{inspect(expected_val)} for input #{inspect(value)}"
        end
      end
    end
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

    # Rename to empty/whitespace (should be no-reply socket unchanged)
    {:noreply, ^socket} =
      JSONSchemaEditor.handle_event(
        "rename_property",
        %{"path" => path_json, "old_key" => "a", "value" => "   "},
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

  test "renders const constraint for boolean type" do
    html =
      render_component(JSONSchemaEditor,
        id: "jse",
        schema: %{"type" => "boolean"},
        ui_state: %{"expanded_constraints:[]" => true}
      )

    assert html =~ "Const"
    refute html =~ "No constraints for this type"
  end

  describe "handle_event enum management" do
    test "manages enum list (add, update, remove)" do
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

      # Remove
      {:noreply, socket} =
        JSONSchemaEditor.handle_event(
          "remove_enum_value",
          %{"path" => path_json, "index" => "0"},
          socket
        )

      refute Map.has_key?(socket.assigns.schema, "enum")
    end

    test "handles type casting and defaults" do
      scenarios = [
        # {schema_type, action, params, expected_enum}
        # Unknown type -> update as string
        {"unknown", "update_enum_value", %{"index" => "0", "value" => "new"}, ["new"]},
        # Number -> cast to float
        {"number", "update_enum_value", %{"index" => "0", "value" => "1.5"}, [1.5]},
        # Integer -> cast to int
        {"integer", "update_enum_value", %{"index" => "0", "value" => "10"}, [10]},
        # Boolean -> cast to bool
        {"boolean", "update_enum_value", %{"index" => "0", "value" => "false"}, [false]},
        # Defaults on add
        {"number", "add_enum_value", %{}, [0.0]},
        {"integer", "add_enum_value", %{}, [0]},
        {"boolean", "add_enum_value", %{}, [true]},
        # Invalid inputs (no change)
        {"integer", "update_enum_value", %{"index" => "0", "value" => "abc"}, [0]},
        {"number", "update_enum_value", %{"index" => "0", "value" => "abc"}, [0.0]}
      ]

      path_json = JSON.encode!([])

      for {type, action, params, expected} <- scenarios do
        # Setup initial state based on type and expected action
        initial_enum =
          case type do
            "unknown" -> ["old"]
            "number" -> [0.0]
            "integer" -> [0]
            "boolean" -> [true]
            _ -> []
          end

        # For "add" tests with empty initial, or "update" tests with existing
        initial_schema = %{"type" => type}

        initial_schema =
          if action == "update_enum_value",
            do: Map.put(initial_schema, "enum", initial_enum),
            else: initial_schema

        socket = setup_socket(initial_schema)
        params = Map.put(params, "path", path_json)

        {:noreply, socket} = JSONSchemaEditor.handle_event(action, params, socket)

        assert socket.assigns.schema["enum"] == expected,
               "Failed for type: #{type}, action: #{action}, params: #{inspect(params)}"
      end
    end
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

  test "handle_event change_schema" do
    socket = setup_socket()

    # Update schema URI
    {:noreply, socket} =
      JSONSchemaEditor.handle_event(
        "change_schema",
        %{"value" => "https://example.com/schema"},
        socket
      )

    assert socket.assigns.schema["$schema"] == "https://example.com/schema"

    # Clear schema URI
    {:noreply, socket} =
      JSONSchemaEditor.handle_event(
        "change_schema",
        %{"value" => ""},
        socket
      )

    refute Map.has_key?(socket.assigns.schema, "$schema")
  end

  test "handle_event update_const" do
    socket = setup_socket(%{"type" => "string"})
    path_json = JSON.encode!([])

    # Set const value
    {:noreply, socket} =
      JSONSchemaEditor.handle_event(
        "update_const",
        %{"path" => path_json, "value" => "fixed"},
        socket
      )

    assert socket.assigns.schema["const"] == "fixed"

    # Clear const value
    {:noreply, socket} =
      JSONSchemaEditor.handle_event(
        "update_const",
        %{"path" => path_json, "value" => ""},
        socket
      )

    refute Map.has_key?(socket.assigns.schema, "const")

    # Type casting (boolean)
    socket = setup_socket(%{"type" => "boolean"})

    {:noreply, socket} =
      JSONSchemaEditor.handle_event(
        "update_const",
        %{"path" => path_json, "value" => "false"},
        socket
      )

    assert socket.assigns.schema["const"] == false
  end

  test "handle_event rename_property updates required list" do
    schema = %{
      "type" => "object",
      "properties" => %{"old_name" => %{}},
      "required" => ["old_name", "other"]
    }

    socket = setup_socket(schema)
    path_json = JSON.encode!([])

    {:noreply, socket} =
      JSONSchemaEditor.handle_event(
        "rename_property",
        %{"path" => path_json, "old_key" => "old_name", "value" => "new_name"},
        socket
      )

    assert Map.has_key?(socket.assigns.schema["properties"], "new_name")
    refute Map.has_key?(socket.assigns.schema["properties"], "old_name")
    assert "new_name" in socket.assigns.schema["required"]
    assert "other" in socket.assigns.schema["required"]
    refute "old_name" in socket.assigns.schema["required"]
  end

  test "renders enum errors" do
    # Create schema with duplicate enum values to trigger error
    schema = %{"type" => "string", "enum" => ["A", "A"]}
    path_json = JSON.encode!([])
    ui_state = %{"expanded_constraints:#{path_json}" => true}

    html = render_component(JSONSchemaEditor, id: "jse", schema: schema, ui_state: ui_state)

    assert html =~ "Values must be unique"
    assert html =~ "jse-enum-error"
  end

  test "renders array contains UI" do
    # State 1: No contains (Show Add button)
    schema = %{"type" => "array"}
    html = render_component(JSONSchemaEditor, id: "jse", schema: schema)
    
    assert html =~ "Add Contains Schema"
    refute html =~ "Remove Contains Schema"

    # State 2: With contains (Show Remove button)
    schema = %{"type" => "array", "contains" => %{"type" => "string"}}
    html = render_component(JSONSchemaEditor, id: "jse", schema: schema)

    refute html =~ "Add Contains Schema"
    assert html =~ "Remove Contains Schema"
    assert html =~ "phx-click=\"remove_contains\"" # Check for delete button presence
  end
end
