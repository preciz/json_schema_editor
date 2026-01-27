defmodule JSONSchemaEditor.ConstTest do
  use ExUnit.Case, async: true
  alias JSONSchemaEditor

  defp setup_socket(schema) do
    %Phoenix.LiveView.Socket{
      assigns: %{
        id: "test",
        schema: schema,
        ui_state: %{},
        validation_errors: %{},
        history: [],
        future: [],
        show_import_modal: false,
        import_error: nil,
        import_mode: :schema,
        test_data_str: "{}",
        test_errors: [],
        __changed__: %{},
        on_save: nil,
        on_change: nil
      }
    }
  end

  test "handle_event update_const for string" do
    socket = setup_socket(%{"type" => "string"})
    path_json = JSON.encode!([])

    {:noreply, socket} =
      JSONSchemaEditor.handle_event(
        "update_const",
        %{"path" => path_json, "value" => "fixed_val"},
        socket
      )

    assert socket.assigns.schema["const"] == "fixed_val"
  end

  test "handle_event update_const for number" do
    socket = setup_socket(%{"type" => "number"})
    path_json = JSON.encode!([])

    {:noreply, socket} =
      JSONSchemaEditor.handle_event(
        "update_const",
        %{"path" => path_json, "value" => "42.5"},
        socket
      )

    assert socket.assigns.schema["const"] == 42.5
  end

  test "handle_event update_const for integer" do
    socket = setup_socket(%{"type" => "integer"})
    path_json = JSON.encode!([])

    {:noreply, socket} =
      JSONSchemaEditor.handle_event(
        "update_const",
        %{"path" => path_json, "value" => "10"},
        socket
      )

    assert socket.assigns.schema["const"] == 10
  end

  test "handle_event update_const for boolean" do
    socket = setup_socket(%{"type" => "boolean"})
    path_json = JSON.encode!([])

    {:noreply, socket} =
      JSONSchemaEditor.handle_event(
        "update_const",
        %{"path" => path_json, "value" => "true"},
        socket
      )

    assert socket.assigns.schema["const"] == true

    {:noreply, socket} =
      JSONSchemaEditor.handle_event(
        "update_const",
        %{"path" => path_json, "value" => "false"},
        socket
      )

    assert socket.assigns.schema["const"] == false
  end

  test "handle_event update_const removes empty value" do
    socket = setup_socket(%{"type" => "string", "const" => "foo"})
    path_json = JSON.encode!([])

    {:noreply, socket} =
      JSONSchemaEditor.handle_event(
        "update_const",
        %{"path" => path_json, "value" => ""},
        socket
      )

    refute Map.has_key?(socket.assigns.schema, "const")
  end
end
