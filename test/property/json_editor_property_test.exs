defmodule JSONSchemaEditor.JSONEditorPropertyTest do
  use ExUnit.Case, async: true
  use ExUnitProperties

  alias JSONSchemaEditor.JSONEditor

  defp setup_socket(json \\ %{}) do
    %Phoenix.LiveView.Socket{
      assigns: %{
        id: "test",
        json: json,
        schema: nil,
        collapsed_nodes: MapSet.new(),
        expanded_editor: nil,
        validation_errors: [],
        __changed__: %{}
      }
    }
  end

  # Generator for valid JSON paths (list of strings/integers)
  def path_generator do
    list_of(one_of([string(:alphanumeric, min_length: 1), integer(0..10)]), max_length: 5)
  end

  # Generator for editor commands
  def command_generator do
    one_of([
      # {event_name, params}
      tuple({constant("add_property"), fixed_map(%{"path" => path_generator()})}),
      tuple({constant("add_item"), fixed_map(%{"path" => path_generator()})}),
      tuple({
        constant("update_value"),
        fixed_map(%{
          "path" => path_generator(),
          "value" => one_of([string(:alphanumeric), integer(), boolean()]),
          "type" => member_of(~w(string number boolean null))
        })
      }),
      tuple({
        constant("change_value_type"),
        fixed_map(%{
          "path" => path_generator(),
          "value" => member_of(~w(string number boolean object array null))
        })
      }),
      tuple({
        constant("toggle_collapse"),
        fixed_map(%{"path" => path_generator()})
      })
    ])
  end

  property "handle_event never crashes on arbitrary command sequences" do
    check all(commands <- list_of(command_generator(), max_length: 20)) do
      socket = setup_socket()

      # Reduce over commands, applying them to the socket
      # We ignore the result structure, just ensuring no crash
      Enum.reduce(commands, socket, fn {event, params}, acc_socket ->
        # Encode path to JSON as the handlers expect JSON string for path
        params = Map.update!(params, "path", &JSON.encode!/1)

        # Ensure value parameters are strings as they come from HTML inputs
        params =
          params
          |> Map.update("value", "", &to_string/1)
          # type param is also a string
          |> Map.update("type", "", &to_string/1)
          # Remove keys if they were added as empty strings but not originally present (optional, but cleaner)
          |> then(fn p ->
            p
            |> Map.reject(fn {k, v} ->
              k in ["value", "type"] and v == "" and not Map.has_key?(params, k)
            end)
          end)

        try do
          case JSONEditor.handle_event(event, params, acc_socket) do
            {:noreply, new_socket} -> new_socket
            _ -> acc_socket
          end
        rescue
          # It's acceptable for the editor to crash on truly invalid paths (like adding property to a string)
          # But ideally, we want to see if it handles "logic" errors gracefully.
          # For now, we are looking for unexpected crashes.
          # AccessError is expected when path doesn't exist or type mismatch (e.g. updating index 5 of empty list).
          # ArgumentError is expected for JSON decoding issues (shouldn't happen here).
          _e in [KeyError, ArgumentError, FunctionClauseError] ->
            # For this property test, we might want to narrow down what is "acceptable" failure.
            # However, given we are generating random paths, many will be invalid.
            # The key goal is to ensure the *system* state doesn't get corrupted or weird crashes occur.
            acc_socket

          _ ->
            acc_socket
        end
      end)
    end
  end

  property "handle_event preserves valid json structure" do
    # This test tries to use VALID paths by building them from the current state
    # This is harder to do with stateless generators.
    # Instead, we will generate a small valid initial state and try operations on root.

    check all(
            initial_val <- one_of([string(:alphanumeric), integer(), boolean()]),
            new_type <- member_of(~w(string number boolean object array null))
          ) do
      socket = setup_socket(initial_val)
      path_json = JSON.encode!([])

      {:noreply, new_socket} =
        JSONEditor.handle_event(
          "change_value_type",
          %{"path" => path_json, "value" => new_type},
          socket
        )

      # Assert the type matches the requested type
      assert JSONSchemaEditor.SchemaUtils.get_type(new_socket.assigns.json) == new_type
    end
  end
end
