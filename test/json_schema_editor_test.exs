defmodule JSONSchemaEditorTest do
  use ExUnit.Case, async: true
  alias JSONSchemaEditor

  test "update/2 initializes schema" do
    assigns = %{id: "test", schema: %{"type" => "object"}}
    {:ok, socket} = JSONSchemaEditor.update(assigns, %Phoenix.LiveView.Socket{})
    assert socket.assigns.schema == %{"type" => "object"}
  end
end
