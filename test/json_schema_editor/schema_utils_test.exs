defmodule JSONSchemaEditor.SchemaUtilsTest do
  use ExUnit.Case, async: true
  alias JSONSchemaEditor.SchemaUtils

  test "get_in_path/2" do
    data = %{"a" => %{"b" => 1}}
    assert SchemaUtils.get_in_path(data, ["a", "b"]) == 1
    assert SchemaUtils.get_in_path(data, ["a"]) == %{"b" => 1}
    assert SchemaUtils.get_in_path(data, []) == data
    assert SchemaUtils.get_in_path(data, ["c"]) == nil
    assert SchemaUtils.get_in_path(nil, ["a"]) == nil
  end

  test "put_in_path/3" do
    data = %{"a" => %{"b" => 1}}
    assert SchemaUtils.put_in_path(data, ["a", "b"], 2) == %{"a" => %{"b" => 2}}
    assert SchemaUtils.put_in_path(data, ["a", "c"], 3) == %{"a" => %{"b" => 1, "c" => 3}}
    assert SchemaUtils.put_in_path(nil, ["a", "b"], 1) == %{"a" => %{"b" => 1}}
    assert SchemaUtils.put_in_path(data, [], %{"new" => "root"}) == %{"new" => "root"}
  end

  test "update_in_path/3" do
    data = %{"a" => %{"b" => 1}}

    assert SchemaUtils.update_in_path(data, ["a", "b"], fn x -> x + 1 end) == %{
             "a" => %{"b" => 2}
           }

    assert SchemaUtils.update_in_path(data, ["a", "c"], fn _ -> 10 end) == %{
             "a" => %{"b" => 1, "c" => 10}
           }
  end

  test "generate_unique_key/3" do
    map = %{"field" => 1, "field_1" => 2}
    assert SchemaUtils.generate_unique_key(map, "other") == "other"
    assert SchemaUtils.generate_unique_key(map, "field") == "field_2"
    assert SchemaUtils.generate_unique_key(%{}, "test") == "test"
  end
end
