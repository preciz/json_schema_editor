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
        __changed__: %{},
        on_save: nil
      }
    }
  end

  test "renders the component" do
    html = render_component(JSONSchemaEditor, id: "jse", schema: %{"type" => "object", "title" => "Test Schema"})
    assert html =~ "jse-container"
    assert html =~ "Test Schema"
    assert html =~ "Schema Root"
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
    html = render_component(JSONSchemaEditor, id: "jse", schema: %{"type" => "string"}, ui_state: ui_state)
    assert html =~ "Min Length"
    assert html =~ "Pattern"

    # Number with expanded constraints
    html = render_component(JSONSchemaEditor, id: "jse", schema: %{"type" => "number"}, ui_state: ui_state)
    assert html =~ "Minimum"
    assert html =~ "Multiple Of"

    # Array with expanded constraints
    html = render_component(JSONSchemaEditor, id: "jse", schema: %{"type" => "array"}, ui_state: ui_state)
    assert html =~ "Min Items"
    assert html =~ "Unique Items"

    # Object with expanded constraints
    html = render_component(JSONSchemaEditor, id: "jse", schema: %{"type" => "object"}, ui_state: ui_state)
    assert html =~ "Min Props"

    # Expanded description
    ui_state = %{"expanded_description:#{path_json}" => true}
    html = render_component(JSONSchemaEditor, id: "jse", schema: %{"type" => "string", "description" => "Long desc"}, ui_state: ui_state)
    assert html =~ "textarea"
    assert html =~ "Long desc"
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
    {:noreply, socket} = JSONSchemaEditor.handle_event("change_type", %{"path" => path_json, "type" => "object"}, socket)
    assert socket.assigns.schema["type"] == "object"
    assert is_map(socket.assigns.schema["properties"])

    # To array
    {:noreply, socket} = JSONSchemaEditor.handle_event("change_type", %{"path" => path_json, "type" => "array"}, socket)
    assert socket.assigns.schema["type"] == "array"
    assert socket.assigns.schema["items"] == %{"type" => "string"}

    # To string
    {:noreply, socket} = JSONSchemaEditor.handle_event("change_type", %{"path" => path_json, "type" => "string"}, socket)
    assert socket.assigns.schema == %{"type" => "string"}
  end

  test "handle_event add_property" do
    socket = setup_socket()
    path_json = JSON.encode!([])

    {:noreply, socket} = JSONSchemaEditor.handle_event("add_property", %{"path" => path_json}, socket)
    assert Map.has_key?(socket.assigns.schema["properties"], "new_field")
    
    # Add another
    {:noreply, socket} = JSONSchemaEditor.handle_event("add_property", %{"path" => path_json}, socket)
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

    {:noreply, socket} = JSONSchemaEditor.handle_event("delete_property", %{"path" => path_json, "key" => "name"}, socket)
    assert socket.assigns.schema["properties"] == %{}
    assert socket.assigns.schema["required"] == []
  end

  test "handle_event toggle_required" do
    schema = %{"type" => "object", "properties" => %{"name" => %{"type" => "string"}}}
    socket = setup_socket(schema)
    path_json = JSON.encode!([])

    # On
    {:noreply, socket} = JSONSchemaEditor.handle_event("toggle_required", %{"path" => path_json, "key" => "name"}, socket)
    assert socket.assigns.schema["required"] == ["name"]

    # Off
    {:noreply, socket} = JSONSchemaEditor.handle_event("toggle_required", %{"path" => path_json, "key" => "name"}, socket)
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
    {:noreply, socket} = JSONSchemaEditor.handle_event("rename_property", %{"path" => path_json, "old_key" => "a", "value" => "b"}, socket)
    assert Map.has_key?(socket.assigns.schema["properties"], "b")
    refute Map.has_key?(socket.assigns.schema["properties"], "a")
    assert socket.assigns.schema["required"] == ["b"]

    # Rename to existing (no-op)
    socket = setup_socket(%{"type" => "object", "properties" => %{"a" => %{}, "b" => %{}}})
    {:noreply, socket} = JSONSchemaEditor.handle_event("rename_property", %{"path" => path_json, "old_key" => "a", "value" => "b"}, socket)
    assert Map.has_key?(socket.assigns.schema["properties"], "a")

    # Rename to empty (no-op)
    {:noreply, socket} = JSONSchemaEditor.handle_event("rename_property", %{"path" => path_json, "old_key" => "a", "value" => " "}, socket)
    assert Map.has_key?(socket.assigns.schema["properties"], "a")
  end

  test "handle_event change_title and change_description" do
    socket = setup_socket()
    path_json = JSON.encode!([])

    {:noreply, socket} = JSONSchemaEditor.handle_event("change_title", %{"path" => path_json, "value" => "Hello"}, socket)
    assert socket.assigns.schema["title"] == "Hello"

    {:noreply, socket} = JSONSchemaEditor.handle_event("change_description", %{"path" => path_json, "value" => "World"}, socket)
    assert socket.assigns.schema["description"] == "World"

    # Clearing
    {:noreply, socket} = JSONSchemaEditor.handle_event("change_title", %{"path" => path_json, "value" => ""}, socket)
    refute Map.has_key?(socket.assigns.schema, "title")
  end

  test "handle_event toggle visibility flags" do
    socket = setup_socket()
    path_json = JSON.encode!([])

    {:noreply, socket} = JSONSchemaEditor.handle_event("toggle_description", %{"path" => path_json}, socket)
    assert socket.assigns.ui_state["expanded_description:#{path_json}"]

    {:noreply, socket} = JSONSchemaEditor.handle_event("toggle_constraints", %{"path" => path_json}, socket)
    assert socket.assigns.ui_state["expanded_constraints:#{path_json}"]
  end

  test "handle_event update_constraint" do
    socket = setup_socket(%{"type" => "string"})
    path_json = JSON.encode!([])

    # Integer
    {:noreply, socket} = JSONSchemaEditor.handle_event("update_constraint", %{"path" => path_json, "field" => "minLength", "value" => "10"}, socket)
    assert socket.assigns.schema["minLength"] == 10

    # Float
    socket = setup_socket(%{"type" => "number"})
    {:noreply, socket} = JSONSchemaEditor.handle_event("update_constraint", %{"path" => path_json, "field" => "minimum", "value" => "1.5"}, socket)
    assert socket.assigns.schema["minimum"] == 1.5

    # Boolean
    socket = setup_socket(%{"type" => "array"})
    {:noreply, socket} = JSONSchemaEditor.handle_event("update_constraint", %{"path" => path_json, "field" => "uniqueItems", "value" => "true"}, socket)
    assert socket.assigns.schema["uniqueItems"] == true

    # Clearing
    {:noreply, socket} = JSONSchemaEditor.handle_event("update_constraint", %{"path" => path_json, "field" => "uniqueItems", "value" => ""}, socket)
    refute Map.has_key?(socket.assigns.schema, "uniqueItems")

    # Unknown field (default case in cast)
    {:noreply, socket} = JSONSchemaEditor.handle_event("update_constraint", %{"path" => path_json, "field" => "unknown", "value" => "foo"}, socket)
    assert socket.assigns.schema["unknown"] == "foo"

    # Invalid number (Integer.parse failure)
    {:noreply, socket} = JSONSchemaEditor.handle_event("update_constraint", %{"path" => path_json, "field" => "minLength", "value" => "abc"}, socket)
    refute Map.has_key?(socket.assigns.schema, "minLength")

    # Invalid float (Float.parse failure)
    {:noreply, socket} = JSONSchemaEditor.handle_event("update_constraint", %{"path" => path_json, "field" => "minimum", "value" => "abc"}, socket)
    refute Map.has_key?(socket.assigns.schema, "minimum")
  end

  test "handle_event rename_property edge cases" do
    socket = setup_socket(%{"type" => "object", "properties" => %{"a" => %{}}})
    path_json = JSON.encode!([])

    # Rename to same key (should be no-reply socket unchanged)
    {:noreply, ^socket} = JSONSchemaEditor.handle_event("rename_property", %{"path" => path_json, "old_key" => "a", "value" => "a"}, socket)
  end

  test "handle_event save" do
    parent = self()
    on_save = fn schema -> send(parent, {:saved, schema}) end
    socket = %Phoenix.LiveView.Socket{assigns: %{schema: %{"type" => "string"}, on_save: on_save}}
    
    {:noreply, _socket} = JSONSchemaEditor.handle_event("save", %{}, socket)
    assert_receive {:saved, %{"type" => "string"}}
  end
end