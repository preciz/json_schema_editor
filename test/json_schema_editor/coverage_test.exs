defmodule JSONSchemaEditor.CoverageTest do
  use ExUnit.Case, async: true
  import Phoenix.LiveViewTest
  alias JSONSchemaEditor

  defp setup_socket(schema \\ %{}) do
    assigns = %{
      id: "editor",
      schema: Map.put_new(schema, "$schema", "https://json-schema.org/draft-07/schema"),
      on_save: fn _ -> :saved end,
      ui_state: %{},
      history: [],
      future: [],
      test_data_str: "{}",
      test_errors: [],
      validation_errors: %{},
      active_tab: :editor,
      types: ~w(string number integer boolean object array null),
      logic_types: ~w(anyOf oneOf allOf),
      formats: ~w(email),
      # Fake show_import_modal etc to avoid missing keys if components use them
      show_import_modal: false,
      import_error: nil,
      import_mode: :schema,
      myself: %Phoenix.LiveComponent.CID{cid: 1},
      __changed__: %{}
    }

    struct(Phoenix.LiveView.Socket, assigns: assigns)
  end

  describe "JSONSchemaEditor event coverage" do
    test "handle_event save: respects validation errors" do
      socket = setup_socket(%{"type" => "string", "minLength" => -1}) # Invalid schema
      # We need to run validate_and_assign_errors logic roughly or just manually set errors
      socket = Phoenix.Component.assign(socket, :validation_errors, %{"root" => "error"})

      # Should NOT call on_save (which we can't easily spy on here without sending a message)
      # But we can check return.
      # Actually, better to pass a pid and assert no message received.
      parent = self()
      socket = Phoenix.Component.assign(socket, :on_save, fn _ -> send(parent, :saved) end)

      {:noreply, _} = JSONSchemaEditor.handle_event("save", %{}, socket)
      refute_receive :saved
    end

    test "handle_event save: works without on_save callback" do
      socket = setup_socket()
      socket = Phoenix.Component.assign(socket, :on_save, nil)
      # Should crash if it tries to call nil, so strict pass means it handled it.
      {:noreply, _} = JSONSchemaEditor.handle_event("save", %{}, socket)
    end

    test "handle_event rename_property: edge cases" do
      socket = setup_socket()
      path = JSON.encode!([])
      
      # 1. Empty new name
      {:noreply, s1} = JSONSchemaEditor.handle_event("rename_property", %{"path" => path, "old_key" => "a", "value" => "  "}, socket)
      assert s1 == socket

      # 2. Same name
      {:noreply, s2} = JSONSchemaEditor.handle_event("rename_property", %{"path" => path, "old_key" => "a", "value" => "a"}, socket)
      assert s2 == socket

      # 3. Collision
      socket_w_props = Phoenix.Component.assign(socket, :schema, %{"type" => "object", "properties" => %{"a" => 1, "b" => 2}})
      {:noreply, s3} = JSONSchemaEditor.handle_event("rename_property", %{"path" => path, "old_key" => "a", "value" => "b"}, socket_w_props)
      assert s3 == socket_w_props # No change
    end

    test "handle_event toggle_required" do
      socket = setup_socket(%{"type" => "object", "required" => ["a"]})
      path = JSON.encode!([])
      
      # Remove
      {:noreply, s1} = JSONSchemaEditor.handle_event("toggle_required", %{"path" => path, "key" => "a"}, socket)
      assert s1.assigns.schema["required"] == []

      # Add
      {:noreply, s2} = JSONSchemaEditor.handle_event("toggle_required", %{"path" => path, "key" => "b"}, s1)
      assert s2.assigns.schema["required"] == ["b"]
    end

    test "handle_event add_enum_value: defaults for types" do
      path = JSON.encode!([])

      # Integer
      socket = setup_socket(%{"type" => "integer"})
      {:noreply, s1} = JSONSchemaEditor.handle_event("add_enum_value", %{"path" => path}, socket)
      assert s1.assigns.schema["enum"] == [0]

      # Boolean
      socket = setup_socket(%{"type" => "boolean"})
      {:noreply, s2} = JSONSchemaEditor.handle_event("add_enum_value", %{"path" => path}, socket)
      assert s2.assigns.schema["enum"] == [true]

      # Null
      socket = setup_socket(%{"type" => "null"})
      {:noreply, s3} = JSONSchemaEditor.handle_event("add_enum_value", %{"path" => path}, socket)
      assert s3.assigns.schema["enum"] == [nil]

      # Number
      socket = setup_socket(%{"type" => "number"})
      {:noreply, s4} = JSONSchemaEditor.handle_event("add_enum_value", %{"path" => path}, socket)
      assert s4.assigns.schema["enum"] == [0.0]

      # Unknown
      socket = setup_socket(%{"type" => "other"})
      {:noreply, s5} = JSONSchemaEditor.handle_event("add_enum_value", %{"path" => path}, socket)
      assert s5.assigns.schema["enum"] == ["new value"]
    end

    test "handle_event remove_enum_value: cleanups" do
      path = JSON.encode!([])
      socket = setup_socket(%{"enum" => ["a"]})
      {:noreply, s1} = JSONSchemaEditor.handle_event("remove_enum_value", %{"path" => path, "index" => "0"}, socket)
      refute Map.has_key?(s1.assigns.schema, "enum")
    end

    test "handle_event change_type: logic types" do
      path = JSON.encode!([])
      socket = setup_socket(%{})
      
      for t <- ~w(anyOf oneOf allOf) do
        {:noreply, s} = JSONSchemaEditor.handle_event("change_type", %{"path" => path, "type" => t}, socket)
        assert Map.has_key?(s.assigns.schema, t)
        assert s.assigns.schema[t] == [%{"type" => "string"}]
      end
    end

    test "handle_event remove_logic_branch: cleanup" do
      path = JSON.encode!([])
      socket = setup_socket(%{"anyOf" => [%{"type" => "string"}]})
      
      {:noreply, s1} = JSONSchemaEditor.handle_event("remove_logic_branch", %{"path" => path, "type" => "anyOf", "index" => "0"}, socket)
      # Should revert to default type string (or just be empty, code says default string)
      assert s1.assigns.schema["type"] == "string"
      refute Map.has_key?(s1.assigns.schema, "anyOf")
    end
  end

  describe "Components coverage via rendering" do
    # We can use render_component to test the live component rendering with different schemas
    
    test "renders logic types" do
      schema = %{"anyOf" => [%{"type" => "string"}]}
      html = render_component(JSONSchemaEditor, id: "test", schema: schema)
      assert html =~ "Anyof Branches"
    end

    test "renders all constraints types" do
      ui_state = %{"expanded_constraints:[]" => true}
      
      # Integer
      html = render_component(JSONSchemaEditor, id: "test", schema: %{"type" => "integer"}, ui_state: ui_state)
      assert html =~ "Multiple Of"

      # Boolean (has const input)
      html = render_component(JSONSchemaEditor, id: "test", schema: %{"type" => "boolean"}, ui_state: ui_state)
      assert html =~ "jse-input-boolean"

      # Null (No specific constraints block, but Enum is there)
      html = render_component(JSONSchemaEditor, id: "test", schema: %{"type" => "null"}, ui_state: ui_state)
      refute html =~ "No constraints for this type"
      assert html =~ "Enum Values"

      # Unknown
      html = render_component(JSONSchemaEditor, id: "test", schema: %{"type" => "unknown"}, ui_state: ui_state)
      assert html =~ "No constraints for this type"
    end

    test "renders array items and contains" do
      schema = %{"type" => "array", "items" => %{"type" => "string"}, "contains" => %{"type" => "number"}}
      html = render_component(JSONSchemaEditor, id: "test", schema: schema)
      assert html =~ "Array Items"
      assert html =~ "Contains"
    end

    test "renders expanded description" do
      path = JSON.encode!([])
      ui_state = %{"expanded_description:#{path}" => true}
      schema = %{"description" => "Desc"}
      html = render_component(JSONSchemaEditor, id: "test", schema: schema, ui_state: ui_state)
      assert html =~ "<textarea"
    end

    test "renders import modal and close icon" do
      # Pass show_import_modal in assigns
      html = render_component(JSONSchemaEditor, id: "test", schema: %{}, show_import_modal: true)
      assert html =~ "jse-modal-overlay"
      # Icon check (close)
      assert html =~ "d=\"M6.28 5.22a.75.75" 
    end

    test "renders collapsed node icon" do
      path = JSON.encode!([])
      ui_state = %{"collapsed_node:#{path}" => true}
      html = render_component(JSONSchemaEditor, id: "test", schema: %{"type" => "object"}, ui_state: ui_state)
      # Chevron right path
      assert html =~ "d=\"M7.21 14.77a.75.75" 
    end

    test "renders string and number constraints" do
      ui_state = %{"expanded_constraints:[]" => true}
      
      html = render_component(JSONSchemaEditor, id: "test", schema: %{"type" => "string"}, ui_state: ui_state)
      assert html =~ "Min Length"
      assert html =~ "Pattern"

      html = render_component(JSONSchemaEditor, id: "test", schema: %{"type" => "number"}, ui_state: ui_state)
      assert html =~ "Minimum"
    end

    test "renders object properties" do
      schema = %{"type" => "object", "properties" => %{"prop1" => %{"type" => "string"}}}
      html = render_component(JSONSchemaEditor, id: "test", schema: schema)
      assert html =~ "prop1"
      assert html =~ "Strict Mode"
    end
  end
end
