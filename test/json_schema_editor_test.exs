defmodule JSONSchemaEditorTest do
  use ExUnit.Case, async: true
  alias JSONSchemaEditor

  test "update/2 initializes schema" do
    assigns = %{id: "test", schema: %{"type" => "object"}}
    {:ok, socket} = JSONSchemaEditor.update(assigns, %Phoenix.LiveView.Socket{})
    assert socket.assigns.schema == %{"type" => "object"}
  end

  test "initializes default schema" do
    assigns = %{id: "test"}
    {:ok, socket} = JSONSchemaEditor.update(assigns, %Phoenix.LiveView.Socket{})
    assert socket.assigns.schema == %{"type" => "object", "properties" => %{}}
  end

  test "updates title" do
    assigns = %{
      id: "test",
      schema: %{"type" => "string"}
    }

    {:ok, socket} = JSONSchemaEditor.update(assigns, %Phoenix.LiveView.Socket{})

    path_json = JSON.encode!([])

    {:noreply, socket} =
      JSONSchemaEditor.handle_event(
        "change_title",
        %{"path" => path_json, "value" => "  User Name  "},
        socket
      )

    assert socket.assigns.schema["title"] == "User Name"
  end

  test "toggles required field" do
    assigns = %{
      id: "test",
      schema: %{
        "type" => "object",
        "properties" => %{"name" => %{"type" => "string"}}
      }
    }

    {:ok, socket} = JSONSchemaEditor.update(assigns, %Phoenix.LiveView.Socket{})

    # Toggle on
    path_json = JSON.encode!([])

    {:noreply, socket} =
      JSONSchemaEditor.handle_event(
        "toggle_required",
        %{"path" => path_json, "key" => "name"},
        socket
      )

    assert socket.assigns.schema["required"] == ["name"]

    # Toggle off
    {:noreply, socket} =
      JSONSchemaEditor.handle_event(
        "toggle_required",
        %{"path" => path_json, "key" => "name"},
        socket
      )

    assert socket.assigns.schema["required"] == []
  end

  test "renaming property updates required list" do
    assigns = %{
      id: "test",
      schema: %{
        "type" => "object",
        "properties" => %{"old_name" => %{"type" => "string"}},
        "required" => ["old_name"]
      }
    }

    {:ok, socket} = JSONSchemaEditor.update(assigns, %Phoenix.LiveView.Socket{})

    path_json = JSON.encode!([])

    {:noreply, socket} =
      JSONSchemaEditor.handle_event(
        "rename_property",
        %{"path" => path_json, "old_key" => "old_name", "value" => "new_name"},
        socket
      )

    assert socket.assigns.schema["properties"]["new_name"]
    refute socket.assigns.schema["properties"]["old_name"]
    assert socket.assigns.schema["required"] == ["new_name"]
  end

  test "deleting property removes from required list" do
    assigns = %{
      id: "test",
      schema: %{
        "type" => "object",
        "properties" => %{"name" => %{"type" => "string"}},
        "required" => ["name"]
      }
    }

    {:ok, socket} = JSONSchemaEditor.update(assigns, %Phoenix.LiveView.Socket{})

    path_json = JSON.encode!([])

    {:noreply, socket} =
      JSONSchemaEditor.handle_event(
        "delete_property",
        %{"path" => path_json, "key" => "name"},
        socket
      )

    refute socket.assigns.schema["properties"]["name"]
    assert socket.assigns.schema["required"] == []
  end

  test "updates description" do
    assigns = %{
      id: "test",
      schema: %{"type" => "string"}
    }

    {:ok, socket} = JSONSchemaEditor.update(assigns, %Phoenix.LiveView.Socket{})

    path_json = JSON.encode!([])

    {:noreply, socket} =
      JSONSchemaEditor.handle_event(
        "change_description",
        %{"path" => path_json, "value" => "  A nice field  "},
        socket
      )

    assert socket.assigns.schema["description"] == "A nice field"

    # Clear description
    {:noreply, socket} =
      JSONSchemaEditor.handle_event(
        "change_description",
        %{"path" => path_json, "value" => ""},
        socket
      )

    refute Map.has_key?(socket.assigns.schema, "description")
  end

  test "toggles description visibility" do
    assigns = %{
      id: "test",
      schema: %{"type" => "string"}
    }

    {:ok, socket} = JSONSchemaEditor.update(assigns, %Phoenix.LiveView.Socket{})

    path_json = JSON.encode!([])

    # Toggle open
    {:noreply, socket} =
      JSONSchemaEditor.handle_event(
        "toggle_description",
        %{"path" => path_json},
        socket
      )

    assert socket.assigns.ui_state["expanded_description:#{path_json}"] == true

    # Toggle closed
    {:noreply, socket} =
      JSONSchemaEditor.handle_event(
        "toggle_description",
        %{"path" => path_json},
        socket
      )

    assert socket.assigns.ui_state["expanded_description:#{path_json}"] == false
  end

  test "updates validation constraints" do
    socket = %Phoenix.LiveView.Socket{
      assigns: %{
        schema: %{"type" => "string"},
        id: "test",
        ui_state: %{},
        __changed__: %{}
      }
    }

    path_json = JSON.encode!([])

    {:noreply, socket} =
      JSONSchemaEditor.handle_event(
        "update_constraint",
        %{"path" => path_json, "field" => "minLength", "value" => "5"},
        socket
      )

    assert socket.assigns.schema["minLength"] == 5

    {:noreply, socket} =
      JSONSchemaEditor.handle_event(
        "update_constraint",
        %{"path" => path_json, "field" => "pattern", "value" => "^[a-z]+$"},
        socket
      )

    assert socket.assigns.schema["pattern"] == "^[a-z]+$"

    {:noreply, socket} =
      JSONSchemaEditor.handle_event(
        "update_constraint",
        %{"path" => path_json, "field" => "minLength", "value" => ""},
        socket
      )

    refute Map.has_key?(socket.assigns.schema, "minLength")
  end
end
