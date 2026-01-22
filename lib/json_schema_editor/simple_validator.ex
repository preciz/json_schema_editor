defmodule JSONSchemaEditor.SimpleValidator do
  @moduledoc """
  A lightweight JSON Schema validator implementation for the editor's Test Lab.
  Supports the subset of features available in the editor.
  """

  def validate(schema, data) do
    compiled_schema = compile_schema(schema)
    do_validate(compiled_schema, data, [])
  end

  defp compile_schema(schema) when is_map(schema) do
    schema
    |> Map.new(fn {k, v} -> {k, compile_schema(v)} end)
    |> maybe_compile_pattern()
  end

  defp compile_schema(list) when is_list(list) do
    Enum.map(list, &compile_schema/1)
  end

  defp compile_schema(val), do: val

  defp maybe_compile_pattern(schema) do
    case schema["pattern"] do
      pattern when is_binary(pattern) ->
        case Regex.compile(pattern) do
          {:ok, regex} -> Map.put(schema, "pattern", regex)
          _ -> schema
        end

      _ ->
        schema
    end
  end

  defp do_validate(schema, data, path) when is_map(schema) do
    # 1. Type validation
    type_errors = validate_type(schema["type"], data, path)

    if type_errors != [] do
      type_errors
    else
      # 2. Constraint validation (only if type matches)
      Enum.concat([
        validate_const(schema, data, path),
        validate_enum(schema, data, path),
        validate_string_constraints(schema, data, path),
        validate_number_constraints(schema, data, path),
        validate_array_constraints(schema, data, path),
        validate_object_constraints(schema, data, path),
        validate_composition(schema, data, path),
        validate_conditional(schema, data, path),
        validate_negation(schema, data, path)
      ])
    end
  end

  # --- Type Validation ---
  # No type specified = any type allowed (unless other constraints fail)
  defp validate_type(nil, _, _), do: []

  defp validate_type(expected_type, data, path) do
    matches? =
      case expected_type do
        "string" -> is_binary(data)
        "number" -> is_number(data)
        "integer" -> is_integer(data)
        "boolean" -> is_boolean(data)
        "object" -> is_map(data)
        "array" -> is_list(data)
        "null" -> is_nil(data)
        _ -> true
      end

    if matches?,
      do: [],
      else: [{format_path(path), "Expected #{expected_type}, got #{type_of(data)}"}]
  end

  # --- Generic Constraints ---
  defp validate_const(%{"const" => const}, data, path) do
    if data == const,
      do: [],
      else: [{format_path(path), "Must match const value: #{inspect(const)}"}]
  end

  defp validate_const(_, _, _), do: []

  defp validate_enum(%{"enum" => enum_vals}, data, path) when is_list(enum_vals) do
    if data in enum_vals,
      do: [],
      else: [{format_path(path), "Must be one of: #{Enum.join(enum_vals, ", ")}"}]
  end

  defp validate_enum(_, _, _), do: []

  # --- String Constraints ---
  defp validate_string_constraints(schema, data, path) when is_binary(data) do
    len = String.length(data)
    errors = []

    errors =
      if min = schema["minLength"] do
        if len < min,
          do: [{format_path(path), "String length must be >= #{min}"}] ++ errors,
          else: errors
      else
        errors
      end

    errors =
      if max = schema["maxLength"] do
        if len > max,
          do: [{format_path(path), "String length must be <= #{max}"}] ++ errors,
          else: errors
      else
        errors
      end

    if pattern = schema["pattern"] do
      cond do
        is_struct(pattern, Regex) ->
          if Regex.match?(pattern, data),
            do: errors,
            else: [{format_path(path), "Must match pattern: #{pattern.source}"}] ++ errors

        is_binary(pattern) ->
          case Regex.compile(pattern) do
            {:ok, regex} ->
              if Regex.match?(regex, data),
                do: errors,
                else: [{format_path(path), "Must match pattern: #{pattern}"}] ++ errors

            _ ->
              errors
          end

        true ->
          errors
      end
    else
      errors
    end
  end

  defp validate_string_constraints(_, _, _), do: []

  # --- Number/Integer Constraints ---
  defp validate_number_constraints(schema, data, path) when is_number(data) do
    errors = []

    errors =
      if min = schema["minimum"] do
        if data < min, do: [{format_path(path), "Must be >= #{min}"}] ++ errors, else: errors
      else
        errors
      end

    errors =
      if max = schema["maximum"] do
        if data > max, do: [{format_path(path), "Must be <= #{max}"}] ++ errors, else: errors
      else
        errors
      end

    if mult = schema["multipleOf"] do
      # Simple check using remainder (might need adjustment for floats)
      rem =
        if is_integer(data) and is_integer(mult) do
          Integer.mod(data, mult)
        else
          # Float modulo logic approximation
          val = data / mult
          abs(val - trunc(val))
        end

      if (is_integer(rem) and rem != 0) or (is_float(rem) and rem > 0.000001) do
        [{format_path(path), "Must be multiple of #{mult}"}] ++ errors
      else
        errors
      end
    else
      errors
    end
  end

  defp validate_number_constraints(_, _, _), do: []

  # --- Array Constraints ---
  defp validate_array_constraints(schema, data, path) when is_list(data) do
    errors = []
    len = length(data)

    errors =
      if min = schema["minItems"] do
        if len < min,
          do: [{format_path(path), "Array length must be >= #{min}"}] ++ errors,
          else: errors
      else
        errors
      end

    errors =
      if max = schema["maxItems"] do
        if len > max,
          do: [{format_path(path), "Array length must be <= #{max}"}] ++ errors,
          else: errors
      else
        errors
      end

    errors =
      if schema["uniqueItems"] == true do
        if Enum.uniq(data) != data,
          do: [{format_path(path), "Items must be unique"}] ++ errors,
          else: errors
      else
        errors
      end

    # Items validation
    item_errors =
      if items_schema = schema["items"] do
        data
        |> Enum.with_index()
        |> Enum.flat_map(fn {item, idx} ->
          do_validate(items_schema, item, path ++ [idx])
        end)
      else
        []
      end

    # Contains validation (Draft 07)
    contains_errors =
      if contains_schema = schema["contains"] do
        # At least one item must match
        match_found =
          Enum.any?(data, fn item ->
            do_validate(contains_schema, item, []) == []
          end)

        if match_found,
          do: [],
          else: [
            {format_path(path), "Array must contain at least one item matching 'contains' schema"}
          ]
      else
        []
      end

    errors ++ item_errors ++ contains_errors
  end

  defp validate_array_constraints(_, _, _), do: []

  # --- Object Constraints ---
  defp validate_object_constraints(schema, data, path) when is_map(data) do
    errors = []
    keys = Map.keys(data)
    len = length(keys)

    errors =
      if min = schema["minProperties"] do
        if len < min,
          do: [{format_path(path), "Object must have >= #{min} properties"}] ++ errors,
          else: errors
      else
        errors
      end

    errors =
      if max = schema["maxProperties"] do
        if len > max,
          do: [{format_path(path), "Object must have <= #{max} properties"}] ++ errors,
          else: errors
      else
        errors
      end

    # Required
    req_errors =
      case schema["required"] do
        reqs when is_list(reqs) ->
          reqs
          |> Enum.filter(fn r -> not Map.has_key?(data, r) end)
          |> Enum.map(fn r -> {format_path(path), "Missing required property: #{r}"} end)

        _ ->
          []
      end

    # Properties
    prop_schemas = schema["properties"] || %{}

    prop_errors =
      data
      |> Enum.flat_map(fn {key, val} ->
        if prop_schema = prop_schemas[key] do
          do_validate(prop_schema, val, path ++ [key])
        else
          # Additional properties check
          if schema["additionalProperties"] == false do
            [{format_path(path), "Property not allowed: #{key}"}]
          else
            []
          end
        end
      end)

    errors ++ req_errors ++ prop_errors
  end

  defp validate_object_constraints(_, _, _), do: []

  # --- Composition (anyOf, oneOf, allOf) ---
  defp validate_composition(schema, data, path) do
    errors = []

    # anyOf: at least one must match
    errors =
      if branches = schema["anyOf"] do
        matches = Enum.any?(branches, fn b -> do_validate(b, data, []) == [] end)

        if matches,
          do: errors,
          else: [{format_path(path), "Must match at least one schema in anyOf"}] ++ errors
      else
        errors
      end

    # allOf: all must match
    errors =
      if branches = schema["allOf"] do
        failures = Enum.filter(branches, fn b -> do_validate(b, data, []) != [] end)

        if failures == [],
          do: errors,
          else: [{format_path(path), "Must match all schemas in allOf"}] ++ errors
      else
        errors
      end

    # oneOf: exactly one must match
    errors =
      if branches = schema["oneOf"] do
        match_count = Enum.count(branches, fn b -> do_validate(b, data, []) == [] end)

        if match_count == 1,
          do: errors,
          else:
            [
              {format_path(path),
               "Must match exactly one schema in oneOf (matched #{match_count})"}
            ] ++ errors
      else
        errors
      end

    errors
  end

  # --- Conditional (if/then/else) ---
  defp validate_conditional(schema, data, path) do
    if if_schema = schema["if"] do
      if_valid? = do_validate(if_schema, data, []) == []

      if if_valid? do
        if then_schema = schema["then"] do
          do_validate(then_schema, data, path)
        else
          []
        end
      else
        if else_schema = schema["else"] do
          do_validate(else_schema, data, path)
        else
          []
        end
      end
    else
      []
    end
  end

  # --- Negation (not) ---
  defp validate_negation(schema, data, path) do
    if not_schema = schema["not"] do
      if do_validate(not_schema, data, []) == [] do
        [{format_path(path), "Must not match the 'not' schema"}]
      else
        []
      end
    else
      []
    end
  end

  # --- Helpers ---
  defp type_of(v) when is_binary(v), do: "string"
  defp type_of(v) when is_integer(v), do: "integer"
  defp type_of(v) when is_float(v), do: "number"
  defp type_of(v) when is_boolean(v), do: "boolean"
  defp type_of(v) when is_map(v), do: "object"
  defp type_of(v) when is_list(v), do: "array"
  defp type_of(nil), do: "null"
  defp type_of(_), do: "unknown"

  defp format_path([]), do: "(root)"

  defp format_path(path) do
    path
    |> Enum.map(fn
      i when is_integer(i) -> "[#{i}]"
      k -> ".#{k}"
    end)
    |> Enum.join("")
    |> String.trim_leading(".")
  end
end
