defmodule JSONSchemaEditor.SchemaGeneratorTest do
  use ExUnit.Case, async: true
  alias JSONSchemaEditor.SchemaGenerator

  test "generates string schema" do
    assert SchemaGenerator.generate("hello") == %{"type" => "string"}
  end

  test "generates integer schema" do
    assert SchemaGenerator.generate(42) == %{"type" => "integer"}
  end

  test "generates number schema" do
    assert SchemaGenerator.generate(3.14) == %{"type" => "number"}
  end

  test "generates boolean schema" do
    assert SchemaGenerator.generate(true) == %{"type" => "boolean"}
  end

  test "generates null/unknown as string" do
    assert SchemaGenerator.generate(nil) == %{"type" => "string"}
  end

  test "generates object schema" do
    data = %{"name" => "John", "age" => 30}
    schema = SchemaGenerator.generate(data)

    assert schema["type"] == "object"
    assert schema["properties"]["name"] == %{"type" => "string"}
    assert schema["properties"]["age"] == %{"type" => "integer"}
    assert "name" in schema["required"]
    assert "age" in schema["required"]
  end

  test "generates nested object schema" do
    data = %{"user" => %{"id" => 1}}
    schema = SchemaGenerator.generate(data)

    assert schema["type"] == "object"
    assert schema["properties"]["user"]["type"] == "object"
    assert schema["properties"]["user"]["properties"]["id"] == %{"type" => "integer"}
  end

  test "generates array schema (empty)" do
    assert SchemaGenerator.generate([]) == %{"type" => "array", "items" => %{"type" => "string"}}
  end

  test "generates array schema (with items)" do
    data = ["a", "b"]
    schema = SchemaGenerator.generate(data)

    assert schema["type"] == "array"
    assert schema["items"] == %{"type" => "string"}
  end

  test "generates complex array schema" do
    data = [%{"id" => 1}]
    schema = SchemaGenerator.generate(data)

    assert schema["type"] == "array"
    assert schema["items"]["type"] == "object"
    assert schema["items"]["properties"]["id"]["type"] == "integer"
  end
end
