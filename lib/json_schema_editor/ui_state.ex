defmodule JSONSchemaEditor.UIState do
  @moduledoc """
  Helper module for managing the ephemeral UI state of the editor,
  such as property ordering, expansion states, etc.
  """

  @doc """
  Calculates the list of property keys to display for a given node,
  respecting any stored custom order in the UI state.
  """
  def get_ordered_keys(ui_state, path, properties) do
    path_str = JSON.encode!(path)
    key = order_key(path_str)
    stored_order = Map.get(ui_state, key)

    if stored_order do
      # 1. Filter stored keys that still exist in the actual properties
      valid_stored = Enum.filter(stored_order, &Map.has_key?(properties, &1))

      # 2. Find any new keys in properties that aren't in the stored order
      missing = Map.keys(properties) -- valid_stored

      # 3. Return stored keys followed by any new keys (alphabetized)
      valid_stored ++ Enum.sort(missing)
    else
      # Default to simple alphabetical sort
      Enum.sort(Map.keys(properties))
    end
  end

  @doc """
  Updates the UI state to track a newly added property key at the end of the list.
  """
  def add_property(ui_state, path, properties, new_key) do
    path_str = if is_binary(path), do: path, else: JSON.encode!(path)
    key = order_key(path_str)

    # If we don't have an order yet, start with the current sorted keys
    current_order = Map.get(ui_state, key) || Enum.sort(Map.keys(properties))

    Map.put(ui_state, key, current_order ++ [new_key])
  end

  @doc """
  Updates the UI state to remove a deleted property key.
  """
  def remove_property(ui_state, path, key_to_remove) do
    path_str = if is_binary(path), do: path, else: JSON.encode!(path)
    key = order_key(path_str)

    if Map.has_key?(ui_state, key) do
      Map.update!(ui_state, key, &List.delete(&1, key_to_remove))
    else
      ui_state
    end
  end

  @doc """
  Updates the UI state to rename a property key in-place, preserving its position.
  """
  def rename_property(ui_state, path, properties, old_key, new_key) do
    path_str = if is_binary(path), do: path, else: JSON.encode!(path)
    key = order_key(path_str)

    # Only create/update order if we actually need to (i.e. if we are tracking order)
    # OR if we want to ensure stability even if we weren't tracking it before.
    # To be safe and stable, we'll initialize the order if it's missing.

    current_order = Map.get(ui_state, key) || Enum.sort(Map.keys(properties))

    new_order =
      Enum.map(current_order, fn k ->
        if k == old_key, do: new_key, else: k
      end)

    Map.put(ui_state, key, new_order)
  end

  defp order_key(path_str), do: "property_order:#{path_str}"
end
