defmodule JSONSchemaEditor.SchemaUtilsPropertyTest do
  use ExUnit.Case, async: true
  use ExUnitProperties

  alias JSONSchemaEditor.SchemaUtils

  property "get_in_path retrieves value set by put_in_path (maps)" do
    check all(
            data <- map_of(string(:printable), simple_term()),
            path <- uniq_list_of(string(:printable)),
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
            map <- map_of(string(:printable), term()),
            base <- string(:printable)
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

  property "cast_value handles garbage strings gracefully" do
    check all(str <- string(:printable)) do
      # Should return 0 for min/max fields on error, or nil
      # Just asserting it doesn't raise

      _ = SchemaUtils.cast_value("integer", str)
      _ = SchemaUtils.cast_value("number", str)
      _ = SchemaUtils.cast_value("minLength", str)
      _ = SchemaUtils.cast_value("boolean", str)
      assert true
    end
  end

  defp simple_term do
    one_of([integer(), boolean(), string(:printable)])
  end
end
