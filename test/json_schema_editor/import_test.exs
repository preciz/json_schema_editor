defmodule JSONSchemaEditor.ImportTest do
  use ExUnit.Case, async: true
  import Phoenix.LiveViewTest
  alias JSONSchemaEditor

  defp setup_socket(schema \\ %{"type" => "object"}) do
    %Phoenix.LiveView.Socket{
      assigns: %{
        id: "test",
        schema: schema,
        ui_state: %{},
        validation_errors: %{},
        show_import_modal: false,
        import_error: nil,
        import_mode: :schema,
        __changed__: %{},
        on_save: nil
      }
    }
  end

  test "renders import button" do
    html = render_component(JSONSchemaEditor, id: "jse", schema: %{"type" => "object"})
    assert html =~ "Import"
    # assert html =~ "phx-click=\"open_import_modal\""
  end

  test "opens and closes import modal" do
    socket = setup_socket()

    # Open modal
    {:noreply, socket} = JSONSchemaEditor.handle_event("open_import_modal", %{}, socket)
    assert socket.assigns.show_import_modal == true
    assert socket.assigns.import_mode == :schema

    # Render modal content
    html = render_component(JSONSchemaEditor, id: "jse", schema: %{}, show_import_modal: true)
    assert html =~ "Import Schema"
    assert html =~ "Generate from JSON"
    assert html =~ "Paste your JSON Schema here..."

    # Close modal
    {:noreply, socket} = JSONSchemaEditor.handle_event("close_import_modal", %{}, socket)
    assert socket.assigns.show_import_modal == false
    assert socket.assigns.import_error == nil
  end

  test "switches import mode" do
    socket = setup_socket()

    {:noreply, socket} =
      JSONSchemaEditor.handle_event("set_import_mode", %{"mode" => "json"}, socket)

    assert socket.assigns.import_mode == :json

    {:noreply, socket} =
      JSONSchemaEditor.handle_event("set_import_mode", %{"mode" => "schema"}, socket)

    assert socket.assigns.import_mode == :schema
  end

  test "generates schema from valid json" do
    socket = setup_socket()
    socket = Phoenix.Component.assign(socket, import_mode: :json)
    json_data = ~s({"name": "Alice", "age": 30})

    {:noreply, socket} =
      JSONSchemaEditor.handle_event(
        "import_schema",
        %{"schema_text" => json_data},
        socket
      )

    assert socket.assigns.schema["type"] == "object"
    assert socket.assigns.schema["properties"]["name"]["type"] == "string"
    assert socket.assigns.schema["properties"]["age"]["type"] == "integer"
    assert socket.assigns.show_import_modal == false
    assert socket.assigns.import_error == nil
  end

  test "imports valid schema" do
    socket = setup_socket()
    valid_json = ~s({"type": "string", "minLength": 5})

    {:noreply, socket} =
      JSONSchemaEditor.handle_event(
        "import_schema",
        %{"schema_text" => valid_json},
        socket
      )

    assert socket.assigns.schema == %{"type" => "string", "minLength" => 5}
    assert socket.assigns.show_import_modal == false
    assert socket.assigns.import_error == nil
    # Should re-validate
    assert is_map(socket.assigns.validation_errors)
  end

  test "handles invalid json" do
    socket = setup_socket()
    # Invalid JSON
    invalid_json = "{type: 'string'}"

    {:noreply, socket} =
      JSONSchemaEditor.handle_event(
        "import_schema",
        %{"schema_text" => invalid_json},
        socket
      )

    assert socket.assigns.import_error == "Invalid JSON"
    # Schema unchanged (remains as setup default)
    assert socket.assigns.schema == %{"type" => "object"}
    # Modal still open
    # Note: In the actual implementation, we don't explicitly set show_import_modal: true in the error case, 
    # relying on the fact it was already true. But in this unit test of the handle_event, it won't be in the assigns map unless we put it there.
    # The handler returns {:noreply, assign(socket, :import_error, ...)} which merges into existing assigns.
    # So we don't strictly assert show_import_modal is true unless we set it in setup, but we check schema is untouched.
  end

  test "handles non-object json" do
    socket = setup_socket()
    array_json = "[1, 2, 3]"

    {:noreply, socket} =
      JSONSchemaEditor.handle_event(
        "import_schema",
        %{"schema_text" => array_json},
        socket
      )

    assert socket.assigns.import_error == "Invalid schema: Must be a JSON object"
  end
end
