defmodule JSONSchemaEditor.Validator do
  @moduledoc false

  defp validate_node(node) do
    %{}
    |> check_min_max(node, [
      {"minLength", "maxLength"},
      {"minimum", "maximum"},
      {"minItems", "maxItems"},
      {"minContains", "maxContains"},
      {"minProperties", "maxProperties"}
    ])
    |> check_positive(node, "multipleOf")
    |> check_unique_enum(node)
    |> check_format_type(node)
  end

  defp check_format_type(errors, node) do
    if Map.has_key?(node, "format") and Map.get(node, "type") != "string" do
      Map.put(errors, "format", "Only valid for strings")
    else
      errors
    end
  end

  defp check_min_max(errors, node, keys) do
    Enum.reduce(keys, errors, fn {min_key, max_key}, acc ->
      min = Map.get(node, min_key)
      max = Map.get(node, max_key)

      if not is_nil(min) and not is_nil(max) and min > max do
        Map.put(acc, min_key, "Must be ≤ #{max_key}")
      else
        acc
      end
    end)
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
    path_json = JSON.encode!(path)

    base_errors =
      validate_node(schema)
      |> Enum.into(%{}, fn {field, msg} -> {"#{path_json}:#{field}", msg} end)

    # Recurse into properties
    prop_errors =
      case Map.get(schema, "properties") do
        props when is_map(props) ->
          Enum.reduce(props, %{}, fn {k, v}, acc ->
            Map.merge(acc, validate_schema(v, path ++ ["properties", k]))
          end)

        _ ->
          %{}
      end

    # Recurse into other sub-schemas (items, contains, logic branches)
    other_errors =
      [{"items", nil}, {"contains", nil}]
      |> Enum.concat(Enum.map(["anyOf", "oneOf", "allOf"], fn k -> {k, :list} end))
      |> Enum.reduce(%{}, fn
        {key, :list}, acc ->
          case Map.get(schema, key) do
            branches when is_list(branches) ->
              branches
              |> Enum.with_index()
              |> Enum.reduce(acc, fn {branch, idx}, b_acc ->
                Map.merge(b_acc, validate_schema(branch, path ++ [key, idx]))
              end)

            _ ->
              acc
          end

        {key, _}, acc ->
          case Map.get(schema, key) do
            sub when is_map(sub) -> Map.merge(acc, validate_schema(sub, path ++ [key]))
            _ -> acc
          end
      end)

    base_errors |> Map.merge(prop_errors) |> Map.merge(other_errors)
  end
end
