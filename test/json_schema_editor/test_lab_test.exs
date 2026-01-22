defmodule JSONSchemaEditor.TestLabTest do
  use ExUnit.Case, async: true
  alias JSONSchemaEditor

  defp setup_socket(schema \\ %{"type" => "object"}) do
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
        on_save: nil
      }
    }
  end

  test "handle_event update_test_data with valid json" do
    socket = setup_socket(%{"type" => "string"})

    {:noreply, socket} =
      JSONSchemaEditor.handle_event("update_test_data", %{"value" => "\"hello\""}, socket)

    assert socket.assigns.test_data_str == "\"hello\""
    assert socket.assigns.test_errors == :ok
  end

  test "handle_event update_test_data with invalid json" do
    socket = setup_socket()

    {:noreply, socket} =
      JSONSchemaEditor.handle_event("update_test_data", %{"value" => "{invalid"}, socket)

    assert socket.assigns.test_errors == ["Invalid JSON Syntax"]
  end

  test "handle_event update_test_data with validation errors" do
    socket = setup_socket(%{"type" => "string"})

    {:noreply, socket} =
      JSONSchemaEditor.handle_event("update_test_data", %{"value" => "123"}, socket)

    assert socket.assigns.test_errors != :ok
    assert length(socket.assigns.test_errors) > 0
  end

  test "validate_test_data handles invalid json syntax error" do
    socket = setup_socket()
    socket = %{socket | assigns: %{socket.assigns | test_data_str: "invalid json"}}

    # We can trigger it via any event that calls validate_test_data or calling it via handle_event update_test_data
    {:noreply, socket} =
      JSONSchemaEditor.handle_event("update_test_data", %{"value" => "{"}, socket)

    assert socket.assigns.test_errors == ["Invalid JSON Syntax"]
  end
end
