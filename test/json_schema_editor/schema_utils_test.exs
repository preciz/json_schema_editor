defmodule JSONSchemaEditor.SchemaUtilsTest do
  use ExUnit.Case, async: true
  alias JSONSchemaEditor.SchemaUtils

  describe "get_in_path/2" do
    test "retrieves value at path" do
      data = %{"a" => %{"b" => 1}}
      assert SchemaUtils.get_in_path(data, ["a", "b"]) == 1
      assert SchemaUtils.get_in_path(data, ["a", "c"]) == nil
      assert SchemaUtils.get_in_path(data, ["x"]) == nil
      assert SchemaUtils.get_in_path("not a map", ["any"]) == nil
    end

    test "retrieves value from list at index" do
      data = %{"list" => [%{"a" => 1}, %{"b" => 2}]}
      assert SchemaUtils.get_in_path(data, ["list", 0]) == %{"a" => 1}
      assert SchemaUtils.get_in_path(data, ["list", 1, "b"]) == 2
      assert SchemaUtils.get_in_path(data, ["list", 2]) == nil
    end
  end

  describe "put_in_path/3" do
    test "puts value at path" do
      data = %{"a" => %{"b" => 1}}
      assert SchemaUtils.put_in_path(data, ["a", "b"], 2) == %{"a" => %{"b" => 2}}
      assert SchemaUtils.put_in_path(data, ["a", "c"], 3) == %{"a" => %{"b" => 1, "c" => 3}}
      assert SchemaUtils.put_in_path(nil, ["a", "b"], 1) == %{"a" => %{"b" => 1}}
      assert SchemaUtils.put_in_path(data, [], %{"new" => "root"}) == %{"new" => "root"}
    end

    test "puts value in list at index" do
      data = %{"list" => ["a", "b"]}
      assert SchemaUtils.put_in_path(data, ["list", 1], "c") == %{"list" => ["a", "c"]}

      # Appending
      assert SchemaUtils.put_in_path(data, ["list", 2], "d") == %{"list" => ["a", "b", "d"]}

      # Padding
      assert SchemaUtils.put_in_path(data, ["list", 4], "e") == %{
               "list" => ["a", "b", nil, nil, "e"]
             }

      # Creating list from nil
      assert SchemaUtils.put_in_path(nil, [0], "item") == ["item"]
    end
  end

  describe "update_in_path/3" do
    test "updates value at path with function" do
      data = %{"a" => %{"b" => 1}}

      assert SchemaUtils.update_in_path(data, ["a", "b"], fn x -> x + 1 end) == %{
               "a" => %{"b" => 2}
             }

      assert SchemaUtils.update_in_path(data, ["a", "c"], fn _ -> 10 end) == %{
               "a" => %{"b" => 1, "c" => 10}
             }
    end

    test "supports binary path" do
      data = %{"a" => 1}
      assert SchemaUtils.update_in_path(data, "[\"a\"]", fn _ -> 2 end) == %{"a" => 2}
    end
  end

  describe "generate_unique_key/3" do
    test "generates unique key avoiding collisions" do
      map = %{"field" => 1, "field_1" => 2}
      assert SchemaUtils.generate_unique_key(map, "other") == "other"
      assert SchemaUtils.generate_unique_key(map, "field") == "field_2"
      assert SchemaUtils.generate_unique_key(%{}, "test") == "test"
    end
  end

  describe "cast_value/2" do
    test "casts to null" do
      assert SchemaUtils.cast_value("null", "anything") == nil
      assert SchemaUtils.cast_value("null", 123) == nil
    end

    test "casts integer" do
      assert SchemaUtils.cast_value("integer", "123") == 123
      assert SchemaUtils.cast_value("integer", "abc") == 0
    end

    test "casts minLength/maxLength/etc" do
      assert SchemaUtils.cast_value("minLength", "5") == 5
      assert SchemaUtils.cast_value("minLength", "abc") == nil
      assert SchemaUtils.cast_value("maxLength", "abc") == nil
      assert SchemaUtils.cast_value("minItems", "abc") == nil
      assert SchemaUtils.cast_value("maxItems", "abc") == nil
      assert SchemaUtils.cast_value("minProperties", "abc") == nil
      assert SchemaUtils.cast_value("maxProperties", "abc") == nil
    end

    test "casts float" do
      assert SchemaUtils.cast_value("number", "12.3") == 12.3
      assert SchemaUtils.cast_value("number", "abc") == 0.0
      assert SchemaUtils.cast_value("minimum", "1.5") == 1.5
      assert SchemaUtils.cast_value("maximum", "abc") == nil
      assert SchemaUtils.cast_value("multipleOf", "abc") == nil
    end

    test "casts boolean" do
      assert SchemaUtils.cast_value("boolean", "true") == true
      assert SchemaUtils.cast_value("boolean", "false") == false
      assert SchemaUtils.cast_value("uniqueItems", "true") == true
    end

    test "passes through unknown fields" do
      assert SchemaUtils.cast_value("other", "val") == "val"
    end
  end

  describe "cast_type/2" do
    test "casts scalar types correctly" do
      assert SchemaUtils.cast_type("123", "string") == "123"
      assert SchemaUtils.cast_type("123", "number") == 123
      assert SchemaUtils.cast_type("123.45", "number") == 123.45
      assert SchemaUtils.cast_type("true", "boolean") == true
      assert SchemaUtils.cast_type("false", "boolean") == false
      assert SchemaUtils.cast_type("not-bool", "boolean") == false
      assert SchemaUtils.cast_type(nil, "null") == nil
    end

    test "casts complex types to scalars by resetting" do
      # Maps
      assert SchemaUtils.cast_type(%{"a" => 1}, "string") == ""
      assert SchemaUtils.cast_type(%{"a" => 1}, "number") == 0
      assert SchemaUtils.cast_type(%{"a" => 1}, "integer") == 0
      assert SchemaUtils.cast_type(%{"a" => 1}, "boolean") == false

      # Lists
      assert SchemaUtils.cast_type([1, 2], "string") == ""
      assert SchemaUtils.cast_type([1, 2], "number") == 0
      assert SchemaUtils.cast_type([1, 2], "integer") == 0
      assert SchemaUtils.cast_type([1, 2], "boolean") == false
    end

    test "casts scalars to complex types" do
      assert SchemaUtils.cast_type("any", "object") == %{}
      assert SchemaUtils.cast_type("any", "array") == []
    end

    test "passes through unknown types" do
      assert SchemaUtils.cast_type("val", "unknown") == "val"
    end
  end

  describe "get_type/1" do
    test "returns correct type" do
      assert SchemaUtils.get_type("s") == "string"
      assert SchemaUtils.get_type(1) == "number"
      assert SchemaUtils.get_type(1.1) == "number"
      assert SchemaUtils.get_type(true) == "boolean"
      assert SchemaUtils.get_type([]) == "array"
      assert SchemaUtils.get_type(%{}) == "object"
      assert SchemaUtils.get_type(nil) == "null"
      assert SchemaUtils.get_type(:atom) == "string"
    end
  end
end
