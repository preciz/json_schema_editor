defmodule JSONSchemaEditor.Validator do
  @moduledoc """
  Logic for validating the consistency of JSON Schema constraints.
  """

  @doc """
  Validates a node and returns a map of errors.
  Errors are keyed by field name.
  """
  def validate_node(node) do
    %{}
    |> check_min_max(node, "minLength", "maxLength")
    |> check_min_max(node, "minimum", "maximum")
    |> check_min_max(node, "minItems", "maxItems")
    |> check_min_max(node, "minProperties", "maxProperties")
    |> check_positive(node, "multipleOf")
    |> check_unique_enum(node)
  end

  defp check_min_max(errors, node, min_key, max_key) do
    min = Map.get(node, min_key)
    max = Map.get(node, max_key)

    if not is_nil(min) and not is_nil(max) and min > max do
      Map.put(errors, min_key, "Must be ≤ #{max_key}")
    else
      errors
    end
  end

  defp check_positive(errors, node, key) do
    val = Map.get(node, key)

    if not is_nil(val) and val <= 0 do
      Map.put(errors, key, "Must be > 0")
    else
      errors
    end
  end

  defp check_unique_enum(errors, node) do
    enum = Map.get(node, "enum")

    if is_list(enum) and length(Enum.uniq(enum)) != length(enum) do
      Map.put(errors, "enum", "Values must be unique")
    else
      errors
    end
  end

  @doc """
  Recursively validates the entire schema and returns a map of errors
  indexed by path_json and field.
  """
  def validate_schema(schema, path \\ []) do
    node_errors = validate_node(schema)
    path_json = JSON.encode!(path)

    base_errors =
      Enum.into(node_errors, %{}, fn {field, msg} ->
        {"#{path_json}:#{field}", msg}
      end)

    # Recurse into properties
    prop_errors =
      case Map.get(schema, "properties") do
        props when is_map(props) ->
          Enum.reduce(props, %{}, fn {key, val}, acc ->
            Map.merge(acc, validate_schema(val, path ++ ["properties", key]))
          end)

        _ ->
          %{}
      end

    # Recurse into items
    item_errors =
      case Map.get(schema, "items") do
        item when is_map(item) ->
          validate_schema(item, path ++ ["items"])

        _ ->
          %{}
      end

    # Recurse into logic branches
    logic_errors =
      Enum.reduce(["anyOf", "oneOf", "allOf"], %{}, fn key, acc ->
        case Map.get(schema, key) do
          branches when is_list(branches) ->
            branch_errors =
              branches
              |> Enum.with_index()
              |> Enum.reduce(%{}, fn {branch, idx}, b_acc ->
                Map.merge(b_acc, validate_schema(branch, path ++ [key, idx]))
              end)

            Map.merge(acc, branch_errors)

          _ ->
            acc
        end
      end)

    base_errors
    |> Map.merge(prop_errors)
    |> Map.merge(item_errors)
    |> Map.merge(logic_errors)
  end
end
