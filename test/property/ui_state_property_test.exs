defmodule JSONSchemaEditor.UIStatePropertyTest do
  use ExUnit.Case, async: true
  use ExUnitProperties

  alias JSONSchemaEditor.UIState

  property "get_ordered_keys returns all and only keys from properties" do
    check all(
            ui_state <-
              map_of(
                string(:alphanumeric, min_length: 1, max_length: 10),
                list_of(string(:alphanumeric, min_length: 1, max_length: 10), max_length: 10),
                max_length: 10
              ),
            path <- list_of(string(:alphanumeric, min_length: 1, max_length: 10), max_length: 5),
            properties <-
              map_of(string(:alphanumeric, min_length: 1, max_length: 10), integer(),
                min_length: 1,
                max_length: 20
              )
          ) do
      ordered_keys = UIState.get_ordered_keys(ui_state, path, properties)

      assert Enum.sort(ordered_keys) == Enum.sort(Map.keys(properties))
    end
  end

  property "add_property appends the new key to the order" do
    check all(
            ui_state <-
              map_of(
                string(:alphanumeric, min_length: 1, max_length: 10),
                list_of(string(:alphanumeric, min_length: 1, max_length: 10), max_length: 10),
                max_length: 10
              ),
            path <- list_of(string(:alphanumeric, min_length: 1, max_length: 10), max_length: 5),
            properties <-
              map_of(string(:alphanumeric, min_length: 1, max_length: 10), integer(),
                max_length: 20
              ),
            new_key <- string(:alphanumeric, min_length: 1, max_length: 10)
          ) do
      # Ensure new_key is not already in properties to avoid confusion
      properties = Map.delete(properties, new_key)

      new_ui_state = UIState.add_property(ui_state, path, properties, new_key)
      new_properties = Map.put(properties, new_key, %{"type" => "string"})

      ordered_keys = UIState.get_ordered_keys(new_ui_state, path, new_properties)

      assert List.last(ordered_keys) == new_key
    end
  end

  property "remove_property removes the key from the order" do
    check all(
            ui_state <-
              map_of(
                string(:alphanumeric, min_length: 1, max_length: 10),
                list_of(string(:alphanumeric, min_length: 1, max_length: 10), max_length: 10),
                max_length: 10
              ),
            path <- list_of(string(:alphanumeric, min_length: 1, max_length: 10), max_length: 5),
            properties <-
              map_of(string(:alphanumeric, min_length: 1, max_length: 10), integer(),
                min_length: 1,
                max_length: 20
              ),
            key_to_remove <- member_of(Map.keys(properties))
          ) do
      new_ui_state = UIState.remove_property(ui_state, path, key_to_remove)
      new_properties = Map.delete(properties, key_to_remove)

      ordered_keys = UIState.get_ordered_keys(new_ui_state, path, new_properties)

      refute key_to_remove in ordered_keys
    end
  end

  property "rename_property preserves the position of the key" do
    check all(
            ui_state <-
              map_of(
                string(:alphanumeric, min_length: 1, max_length: 10),
                list_of(string(:alphanumeric, min_length: 1, max_length: 10), max_length: 10),
                max_length: 10
              ),
            path <- list_of(string(:alphanumeric, min_length: 1, max_length: 10), max_length: 5),
            properties <-
              map_of(string(:alphanumeric, min_length: 1, max_length: 10), integer(),
                min_length: 1,
                max_length: 20
              ),
            old_key <- member_of(Map.keys(properties)),
            new_key <- string(:alphanumeric, min_length: 1, max_length: 10)
          ) do
      # Avoid collision with existing keys
      new_key = if Map.has_key?(properties, new_key), do: new_key <> "_new", else: new_key

      original_order = UIState.get_ordered_keys(ui_state, path, properties)
      old_index = Enum.find_index(original_order, &(&1 == old_key))

      new_ui_state = UIState.rename_property(ui_state, path, properties, old_key, new_key)
      new_properties = properties |> Map.delete(old_key) |> Map.put(new_key, properties[old_key])

      new_order = UIState.get_ordered_keys(new_ui_state, path, new_properties)
      new_index = Enum.find_index(new_order, &(&1 == new_key))

      assert old_index == new_index
      assert length(original_order) == length(new_order)
    end
  end
end
