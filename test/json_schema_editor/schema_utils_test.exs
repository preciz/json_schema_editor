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

    test "casts float" do
      assert SchemaUtils.cast_value("number", "12.3") == 12.3
      assert SchemaUtils.cast_value("number", "abc") == 0.0
    end

    test "casts boolean" do
      assert SchemaUtils.cast_value("boolean", "true") == true
      assert SchemaUtils.cast_value("boolean", "false") == false
    end
  end
end
