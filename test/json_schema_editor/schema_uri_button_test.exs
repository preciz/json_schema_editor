defmodule JSONSchemaEditor.SchemaUriButtonTest do
  use ExUnit.Case, async: true
  import Phoenix.LiveViewTest
  alias JSONSchemaEditor

  defp setup_socket(schema \\ %{}) do
    %Phoenix.LiveView.Socket{
      assigns: %{
        id: "test",
        schema: schema,
        ui_state: %{},
        validation_errors: %{},
        history: [],
        future: [],
        myself: %Phoenix.LiveComponent.CID{cid: 1},
        __changed__: %{},
        test_data_str: "{}",
        test_errors: []
      }
    }
  end

  test "handle_event set_default_schema updates the schema" do
    socket = setup_socket(%{"$schema" => ""})
    {:noreply, new_socket} = JSONSchemaEditor.handle_event("set_default_schema", %{}, socket)

    assert new_socket.assigns.schema["$schema"] == "https://json-schema.org/draft-07/schema"
  end

  test "button is rendered when schema uri is empty string" do
    html = render_component(JSONSchemaEditor, id: "jse", schema: %{"$schema" => ""})
    assert html =~ "Default"
    assert html =~ "set_default_schema"
  end

  test "button is NOT rendered when schema uri is present" do
    html = render_component(JSONSchemaEditor, id: "jse", schema: %{"$schema" => "something"})
    refute html =~ ">Default</button>"
    refute html =~ "set_default_schema"
  end
end