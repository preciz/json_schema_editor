defmodule JSONSchemaEditor.ContainsTest do
  use ExUnit.Case, async: true
  alias JSONSchemaEditor
  alias JSONSchemaEditor.Validator

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

  test "handle_event add_contains" do
    socket = setup_socket(%{"type" => "array"})
    path_json = JSON.encode!([])

    {:noreply, socket} =
      JSONSchemaEditor.handle_event(
        "add_child",
        %{"path" => path_json, "key" => "contains"},
        socket
      )

    assert Map.has_key?(socket.assigns.schema, "contains")
    assert socket.assigns.schema["contains"] == %{"type" => "string"}
  end

  test "handle_event remove_contains" do
    socket = setup_socket(%{"type" => "array", "contains" => %{"type" => "string"}})
    path_json = JSON.encode!([])

    {:noreply, socket} =
      JSONSchemaEditor.handle_event(
        "remove_child",
        %{"path" => path_json, "key" => "contains"},
        socket
      )

    refute Map.has_key?(socket.assigns.schema, "contains")
  end

  test "validation minContains and maxContains" do
    schema = %{
      "type" => "array",
      "minContains" => 5,
      "maxContains" => 3
    }

    errors = Validator.validate_schema(schema)
    assert errors["[]:minContains"] == "Must be ≤ maxContains"

    schema = %{
      "type" => "array",
      "minContains" => 0,
      "maxContains" => 3
    }

    errors = Validator.validate_schema(schema)
    assert errors == %{}
  end

  test "recursive validation in contains" do
    schema = %{
      "type" => "array",
      "contains" => %{
        "type" => "number",
        "minimum" => 10,
        "maximum" => 5
      }
    }

    errors = Validator.validate_schema(schema)
    assert errors["[\"contains\"]:minimum"] == "Must be ≤ maximum"
  end
end
