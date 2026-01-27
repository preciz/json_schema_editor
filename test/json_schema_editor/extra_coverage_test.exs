defmodule JSONSchemaEditor.ExtraCoverageTest do
  use ExUnit.Case, async: true
  alias JSONSchemaEditor

  defp setup_socket(assigns) do
    %Phoenix.LiveView.Socket{
      assigns:
        Map.merge(
          %{
            id: "test",
            schema: %{"$schema" => "https://json-schema.org/draft-07/schema"},
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
            on_change: nil,
            header_class: nil,
            toolbar_class: nil,
            class: nil,
            active_tab: :editor,
            types: ~w(string number integer boolean object array null),
            logic_types: ~w(anyOf oneOf allOf),
            formats: ~w(email),
            myself: %Phoenix.LiveComponent.CID{cid: 1}
          },
          assigns
        )
    }
  end

  describe "JSONSchemaEditor on_change callback" do
    test "calls on_change when schema is modified and valid" do
      parent = self()
      on_change = fn schema -> send(parent, {:schema_changed, schema}) end

      socket = setup_socket(%{on_change: on_change, schema: %{"type" => "string"}})
      path_json = JSON.encode!([])

      # Trigger a change (change type to number)
      {:noreply, _socket} =
        JSONSchemaEditor.handle_event(
          "change_type",
          %{"path" => path_json, "type" => "number"},
          socket
        )

      # Note: $schema might be lost if change_type replaces the root object entirely or if not merged back.
      # Based on failure, we got %{"type" => "number"}.
      assert_receive {:schema_changed, %{"type" => "number"}}
    end

    test "does NOT call on_change when schema is invalid" do
      parent = self()
      on_change = fn schema -> send(parent, {:schema_changed, schema}) end

      # Start with valid schema (maxLength: 5)
      schema = %{"type" => "string", "maxLength" => 5}
      socket = setup_socket(%{on_change: on_change, schema: schema})
      path_json = JSON.encode!([])

      # Update minLength to 10 (invalid because > maxLength 5)
      {:noreply, _socket} =
        JSONSchemaEditor.handle_event(
          "update_constraint",
          %{"path" => path_json, "field" => "minLength", "value" => "10"},
          socket
        )

      # Should NOT receive message because validation_errors will be present
      refute_receive {:schema_changed, _}
    end

    test "calls on_change on undo/redo" do
      parent = self()
      on_change = fn schema -> send(parent, {:schema_changed, schema}) end

      history = [%{"type" => "string"}]
      future = [%{"type" => "boolean"}]

      socket =
        setup_socket(%{
          on_change: on_change,
          schema: %{"type" => "number"},
          history: history,
          future: future
        })

      # Undo
      {:noreply, socket_undo} = JSONSchemaEditor.handle_event("undo", %{}, socket)
      assert_receive {:schema_changed, %{"type" => "string"}}

      # Redo
      {:noreply, _socket_redo} = JSONSchemaEditor.handle_event("redo", %{}, socket_undo)
      assert_receive {:schema_changed, %{"type" => "number"}}

      # Note: redo from "string" (restored by undo) goes back to "number" (which was current before undo)
      # Wait, undo moves current to future, pops history.
      # Redo moves current to history, pops future.
      # Initial: current=number, history=[string], future=[boolean]
      # Undo -> current=string, history=[], future=[number, boolean]
      # Redo -> current=number, history=[string], future=[boolean]
    end
  end

  describe "JSONSchemaEditor.JSONEditor on_change callback" do
    alias JSONSchemaEditor.JSONEditor

    defp setup_editor_socket(assigns) do
      %Phoenix.LiveView.Socket{
        assigns:
          Map.merge(
            %{
              id: "editor",
              json: %{},
              schema: nil,
              on_save: nil,
              on_change: nil,
              collapsed_nodes: MapSet.new(),
              expanded_editor: nil,
              class: nil,
              header_class: nil,
              toolbar_class: nil,
              active_tab: :editor,
              validation_errors: [],
              myself: %Phoenix.LiveComponent.CID{cid: 1},
              __changed__: %{}
            },
            assigns
          )
      }
    end

    test "calls on_change when data is updated" do
      parent = self()
      on_change = fn json -> send(parent, {:json_changed, json}) end

      socket = setup_editor_socket(%{on_change: on_change, json: %{"a" => 1}})
      path_json = JSON.encode!(["a"])

      {:noreply, _socket} =
        JSONEditor.handle_event(
          "update_value",
          %{"path" => path_json, "value" => "2", "type" => "number"},
          socket
        )

      assert_receive {:json_changed, %{"a" => 2}}
    end

    test "does NOT call on_change when data is invalid against schema" do
      parent = self()
      on_change = fn json -> send(parent, {:json_changed, json}) end

      schema = %{"type" => "object", "properties" => %{"a" => %{"type" => "string"}}}
      # Initial valid state
      socket =
        setup_editor_socket(%{on_change: on_change, json: %{"a" => "valid"}, schema: schema})

      path_json = JSON.encode!(["a"])

      # Update to invalid type (number)
      {:noreply, _socket} =
        JSONEditor.handle_event(
          "update_value",
          %{"path" => path_json, "value" => "123", "type" => "number"},
          socket
        )

      refute_receive {:json_changed, _}
    end
  end
end
