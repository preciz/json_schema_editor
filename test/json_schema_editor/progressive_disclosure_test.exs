defmodule JSONSchemaEditor.ProgressiveDisclosureTest do
  use ExUnit.Case, async: true
  import Phoenix.LiveViewTest
  alias JSONSchemaEditor

  test "highlights constraints icon when data is present" do
    scenarios = [
      {%{"type" => "string", "minLength" => 5}, "jse-btn-toggle-constraints.*jse-has-data"},
      {%{"type" => "string", "enum" => ["a", "b"]}, "jse-btn-toggle-constraints.*jse-has-data"},
      {%{"type" => "number", "minimum" => 10}, "jse-btn-toggle-constraints.*jse-has-data"},
      {%{"type" => "object", "required" => ["foo"]}, "jse-btn-toggle-constraints.*jse-has-data"},
      {%{"type" => "object", "additionalProperties" => false},
       "jse-btn-toggle-constraints.*jse-has-data"},
      {%{"type" => "array", "uniqueItems" => true}, "jse-btn-toggle-constraints.*jse-has-data"},
      # Should NOT have jse-has-data (this is a bit weak as regex)
      {%{"type" => "string"}, "jse-btn-toggle-constraints"}
    ]

    for {schema, pattern} <- scenarios do
      html = render_component(JSONSchemaEditor, id: "jse", schema: schema)

      if String.contains?(pattern, "jse-has-data") do
        assert html =~ ~r/#{pattern}/
      else
        refute html =~ ~r/jse-btn-toggle-constraints.*jse-has-data/
      end
    end
  end

  test "highlights logic icon when data is present" do
    scenarios = [
      {%{"type" => "string", "if" => %{"type" => "string"}},
       "jse-btn-toggle-logic.*jse-has-data"},
      {%{"type" => "string", "not" => %{"type" => "number"}},
       "jse-btn-toggle-logic.*jse-has-data"},
      # Should NOT have jse-has-data
      {%{"type" => "string"}, "jse-btn-toggle-logic"}
    ]

    for {schema, pattern} <- scenarios do
      html = render_component(JSONSchemaEditor, id: "jse", schema: schema)

      if String.contains?(pattern, "jse-has-data") do
        assert html =~ ~r/#{pattern}/
      else
        refute html =~ ~r/jse-btn-toggle-logic.*jse-has-data/
      end
    end
  end

  test "auto-expands node when toggling constraints/logic/description" do
    # Helper to setup a minimal socket similar to what's in json_schema_editor_test.exs
    socket = %Phoenix.LiveView.Socket{
      assigns: %{
        id: "test",
        schema: %{"type" => "object"},
        ui_state: %{},
        validation_errors: %{},
        history: [],
        future: [],
        __changed__: %{}
      }
    }

    path = JSON.encode!([])

    # 1. Start with collapsed node
    socket = put_in(socket.assigns.ui_state["collapsed_node:#{path}"], true)

    # 2. Toggle constraints ON
    {:noreply, socket} =
      JSONSchemaEditor.handle_event(
        "toggle_ui",
        %{"path" => path, "type" => "expanded_constraints"},
        socket
      )

    assert socket.assigns.ui_state["expanded_constraints:#{path}"] == true
    assert socket.assigns.ui_state["collapsed_node:#{path}"] == false

    # 3. Collapse node again
    socket = put_in(socket.assigns.ui_state["collapsed_node:#{path}"], true)

    # 4. Toggle logic ON
    {:noreply, socket} =
      JSONSchemaEditor.handle_event(
        "toggle_ui",
        %{"path" => path, "type" => "expanded_logic"},
        socket
      )

    assert socket.assigns.ui_state["expanded_logic:#{path}"] == true
    assert socket.assigns.ui_state["collapsed_node:#{path}"] == false

    # 5. Collapse node again
    socket = put_in(socket.assigns.ui_state["collapsed_node:#{path}"], true)

    # 6. Toggle description ON
    {:noreply, socket} =
      JSONSchemaEditor.handle_event(
        "toggle_ui",
        %{"path" => path, "type" => "expanded_description"},
        socket
      )

    assert socket.assigns.ui_state["expanded_description:#{path}"] == true
    assert socket.assigns.ui_state["collapsed_node:#{path}"] == false
  end
end
