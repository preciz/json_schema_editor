defmodule JSONSchemaEditor.SchemaUtilsPropertyTest do
  use ExUnit.Case, async: true
  use ExUnitProperties

  alias JSONSchemaEditor.SchemaUtils

  property "get_in_path retrieves value set by put_in_path (maps)" do
    check all(
            data <-
              map_of(string(:alphanumeric, min_length: 1, max_length: 10), simple_term(),
                min_length: 1,
                max_length: 10
              ),
            path <-
              uniq_list_of(string(:alphanumeric, min_length: 1, max_length: 10),
                min_length: 1,
                max_length: 5
              ),
            value <- simple_term()
          ) do
      # We start with some data, but put_in_path might overwrite parts of it.
      # The key invariant is: after putting V at P, getting P returns V.

      updated_data = SchemaUtils.put_in_path(data, path, value)
      retrieved_value = SchemaUtils.get_in_path(updated_data, path)

      assert retrieved_value == value
    end
  end

  property "generate_unique_key returns a key not present in map" do
    check all(
            map <-
              map_of(string(:alphanumeric, min_length: 1, max_length: 10), integer(),
                min_length: 1,
                max_length: 20
              ),
            base <- string(:alphanumeric, min_length: 1, max_length: 10)
          ) do
      new_key = SchemaUtils.generate_unique_key(map, base)
      refute Map.has_key?(map, new_key)
      assert String.starts_with?(new_key, base)
    end
  end

  property "cast_value handles numeric strings robustly" do
    check all(val <- integer()) do
      str = Integer.to_string(val)
      assert SchemaUtils.cast_value("integer", str) == val
      assert SchemaUtils.cast_value("minLength", str) == val
    end

    check all(val <- float()) do
      str = Float.to_string(val)
      assert SchemaUtils.cast_value("number", str) == val
    end
  end

  property "cast_value always returns nil for null type" do
    check all(val <- simple_term()) do
      assert SchemaUtils.cast_value("null", val) == nil
    end
  end

  property "cast_value handles garbage strings gracefully" do
    check all(str <- string(:printable, min_length: 1, max_length: 20)) do
      # Should return 0 for min/max fields on error, or nil
      # Just asserting it doesn't raise

      _ = SchemaUtils.cast_value("integer", str)
      _ = SchemaUtils.cast_value("number", str)
      _ = SchemaUtils.cast_value("minLength", str)
      _ = SchemaUtils.cast_value("boolean", str)
      assert true
    end
  end

  property "update_in_path handles list indices and padding" do
    check all(
            initial_list <- list_of(simple_term(), max_length: 10),
            index <- integer(0..20),
            new_value <- simple_term()
          ) do
      path = [index]
      updated_list = SchemaUtils.update_in_path(initial_list, path, fn _ -> new_value end)

      assert is_list(updated_list)
      assert length(updated_list) >= index + 1
      assert Enum.at(updated_list, index) == new_value

      # Check padding if we went beyond original length
      if index > length(initial_list) do
        # Indices between old_len and index-1 should be nil
        for i <- length(initial_list)..(index - 1) do
          assert Enum.at(updated_list, i) == nil
        end
      end
    end
  end

  property "cast_type always returns value of requested type" do
    check all(
            val <- any_json_value(),
            target_type <- member_of(~w(string number integer boolean object array null))
          ) do
      casted = SchemaUtils.cast_type(val, target_type)

      case target_type do
        "string" -> assert is_binary(casted)
        "number" -> assert is_number(casted)
        "integer" -> assert is_integer(casted)
        "boolean" -> assert is_boolean(casted)
        "object" -> assert is_map(casted)
        "array" -> assert is_list(casted)
        "null" -> assert is_nil(casted)
      end
    end
  end

  property "get_type correctly identifies types" do
    check all(val <- any_json_value()) do
      type = SchemaUtils.get_type(val)

      assert type in ~w(string number boolean array object null)

      case val do
        v when is_binary(v) -> assert type == "string"
        v when is_boolean(v) -> assert type == "boolean"
        # Integers are numbers
        v when is_integer(v) -> assert type == "number"
        v when is_float(v) -> assert type == "number"
        v when is_list(v) -> assert type == "array"
        v when is_map(v) -> assert type == "object"
        nil -> assert type == "null"
        _ -> :ok
      end
    end
  end

  defp simple_term do
    one_of([integer(), boolean(), string(:alphanumeric, min_length: 1, max_length: 10)])
  end

  defp any_json_value do
    one_of([
      integer(),
      float(),
      boolean(),
      string(:printable),
      constant(nil),
      list_of(boolean(), max_length: 3),
      map_of(string(:alphanumeric, max_length: 5), boolean(), max_length: 3)
    ])
  end
end
