defmodule JSONSchemaEditor.Validator do
  @moduledoc false

  @min_max_pairs [
    {"minLength", "maxLength"},
    {"minimum", "maximum"},
    {"minItems", "maxItems"},
    {"minContains", "maxContains"},
    {"minProperties", "maxProperties"}
  ]

  def validate_schema(schema, path \\ []) do
    node_errors = validate_node(schema)

    base_errors = Map.new(node_errors, fn {field, msg} -> {{path, field}, msg} end)

    child_errors =
      schema
      |> Enum.reduce(%{}, fn
        {"properties", props}, acc when is_map(props) ->
          Enum.reduce(props, acc, fn {k, v}, a ->
            Map.merge(a, validate_schema(v, path ++ ["properties", k]))
          end)

        {key, val}, acc when key in ~w(items contains) and is_map(val) ->
          Map.merge(acc, validate_schema(val, path ++ [key]))

        {key, list}, acc when key in ~w(anyOf oneOf allOf) and is_list(list) ->
          list
          |> Enum.with_index()
          |> Enum.reduce(acc, fn {branch, idx}, a ->
            Map.merge(a, validate_schema(branch, path ++ [key, idx]))
          end)

        _, acc ->
          acc
      end)

    Map.merge(base_errors, child_errors)
  end

  defp validate_node(node) do
    %{}
    |> check_min_max(node)
    |> check_positive(node, "multipleOf")
    |> check_unique_enum(node)
    |> check_format_type(node)
  end

  defp check_min_max(errors, node) do
    Enum.reduce(@min_max_pairs, errors, fn {min, max}, acc ->
      min_val = node[min]
      max_val = node[max]

      if min_val && max_val && min_val > max_val,
        do: Map.put(acc, min, "Must be ≤ #{max}"),
        else: acc
    end)
  end

  defp check_positive(errors, node, key) do
    if (val = node[key]) && val <= 0, do: Map.put(errors, key, "Must be > 0"), else: errors
  end

  defp check_unique_enum(errors, %{"enum" => enum}) when is_list(enum) do
    if length(Enum.uniq(enum)) != length(enum),
      do: Map.put(errors, "enum", "Values must be unique"),
      else: errors
  end

  defp check_unique_enum(errors, _), do: errors

  defp check_format_type(errors, %{"format" => _, "type" => type}) when type != "string",
    do: Map.put(errors, "format", "Only valid for strings")

  defp check_format_type(errors, _), do: errors
end
