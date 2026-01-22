defmodule JSONSchemaEditor.HistoryTest do
  use ExUnit.Case, async: true
  import Phoenix.LiveViewTest
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
        on_save: nil
      }
    }
  end

  test "renders undo/redo buttons" do
    html = render_component(JSONSchemaEditor, id: "jse", schema: %{"type" => "object"})
    assert html =~ "Undo"
    assert html =~ "Redo"
  end

  test "push_history/1 updates history and clears future" do
    # This is indirectly tested via event handlers, as push_history is private
    socket = setup_socket(%{"type" => "string"})
    path_json = JSON.encode!([])

    # Perform an action (e.g., change type)
    {:noreply, socket} =
      JSONSchemaEditor.handle_event(
        "change_type",
        %{"path" => path_json, "type" => "number"},
        socket
      )

    assert socket.assigns.schema["type"] == "number"
    assert length(socket.assigns.history) == 1
    assert hd(socket.assigns.history) == %{"type" => "string"}
    assert socket.assigns.future == []
  end

  test "undo/redo cycle" do
    socket = setup_socket(%{"type" => "string"})
    path_json = JSON.encode!([])

    # 1. Change to number
    {:noreply, socket} =
      JSONSchemaEditor.handle_event(
        "change_type",
        %{"path" => path_json, "type" => "number"},
        socket
      )

    assert socket.assigns.schema["type"] == "number"
    assert length(socket.assigns.history) == 1

    # 2. Undo
    {:noreply, socket} = JSONSchemaEditor.handle_event("undo", %{}, socket)
    assert socket.assigns.schema["type"] == "string"
    assert length(socket.assigns.history) == 0
    assert length(socket.assigns.future) == 1
    assert hd(socket.assigns.future) == %{"type" => "number"}

    # 3. Redo
    {:noreply, socket} = JSONSchemaEditor.handle_event("redo", %{}, socket)
    assert socket.assigns.schema["type"] == "number"
    assert length(socket.assigns.history) == 1
    assert length(socket.assigns.future) == 0

    # 4. Undo again
    {:noreply, socket} = JSONSchemaEditor.handle_event("undo", %{}, socket)
    assert socket.assigns.schema["type"] == "string"
  end

  test "new action clears future stack" do
    socket = setup_socket(%{"type" => "string"})
    path_json = JSON.encode!([])

    # 1. Change to number
    {:noreply, socket} =
      JSONSchemaEditor.handle_event(
        "change_type",
        %{"path" => path_json, "type" => "number"},
        socket
      )

    # 2. Undo (back to string)
    {:noreply, socket} = JSONSchemaEditor.handle_event("undo", %{}, socket)
    assert socket.assigns.future != []

    # 3. Change to boolean (should clear future)
    {:noreply, socket} =
      JSONSchemaEditor.handle_event(
        "change_type",
        %{"path" => path_json, "type" => "boolean"},
        socket
      )

    assert socket.assigns.schema["type"] == "boolean"
    assert socket.assigns.future == []
    # History should contain "string" (from step 2)
    assert length(socket.assigns.history) == 1
    assert hd(socket.assigns.history) == %{"type" => "string"}
  end

  test "undo/redo does nothing when stack empty" do
    socket = setup_socket(%{"type" => "string"})

    # Undo on empty history
    {:noreply, new_socket} = JSONSchemaEditor.handle_event("undo", %{}, socket)
    assert new_socket.assigns.schema == socket.assigns.schema

    # Redo on empty future
    {:noreply, new_socket} = JSONSchemaEditor.handle_event("redo", %{}, new_socket)
    assert new_socket.assigns.schema == socket.assigns.schema
  end

  test "multiple history steps" do
    socket = setup_socket(%{"type" => "string"})
    path_json = JSON.encode!([])

    # string -> number
    {:noreply, socket} =
      JSONSchemaEditor.handle_event(
        "change_type",
        %{"path" => path_json, "type" => "number"},
        socket
      )

    # number -> boolean
    {:noreply, socket} =
      JSONSchemaEditor.handle_event(
        "change_type",
        %{"path" => path_json, "type" => "boolean"},
        socket
      )

    assert length(socket.assigns.history) == 2

    # Undo boolean -> number
    {:noreply, socket} = JSONSchemaEditor.handle_event("undo", %{}, socket)
    assert socket.assigns.schema["type"] == "number"

    # Undo number -> string
    {:noreply, socket} = JSONSchemaEditor.handle_event("undo", %{}, socket)
    assert socket.assigns.schema["type"] == "string"
  end

  test "history limit of 50 items" do
    socket = setup_socket(%{"v" => 0})
    path_json = JSON.encode!([])

    # Add 60 items to history
    socket =
      Enum.reduce(1..60, socket, fn i, acc ->
        {:noreply, next} =
          JSONSchemaEditor.handle_event(
            "change_title",
            %{"path" => path_json, "value" => "#{i}"},
            acc
          )

        next
      end)

    assert length(socket.assigns.history) == 50
    # The oldest items should be dropped.
    # The first item in history should be the 59th version (since 60th is current)
    assert hd(socket.assigns.history)["title"] == "59"
  end
end
