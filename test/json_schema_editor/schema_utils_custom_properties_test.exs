defmodule JSONSchemaEditor.SchemaUtilsCustomPropertiesTest do
  use ExUnit.Case
  alias JSONSchemaEditor.SchemaUtils

  describe "clean_custom_property/2" do
    test "removes specific custom property from top level" do
      schema = %{
        "type" => "object",
        "x-custom" => "value",
        "properties" => %{
          "foo" => %{"type" => "string"}
        }
      }

      cleaned = SchemaUtils.clean_custom_property(schema, "x-custom")

      assert cleaned == %{
               "type" => "object",
               "properties" => %{
                 "foo" => %{"type" => "string"}
               }
             }
    end

    test "removes specific custom property recursively" do
      schema = %{
        "type" => "object",
        "x-custom" => "top",
        "properties" => %{
          "foo" => %{
            "type" => "string",
            "x-custom" => "nested"
          },
          "bar" => %{
            "type" => "array",
            "items" => %{
              "type" => "number",
              "x-custom" => "array-item"
            }
          }
        }
      }

      cleaned = SchemaUtils.clean_custom_property(schema, "x-custom")

      assert cleaned == %{
               "type" => "object",
               "properties" => %{
                 "foo" => %{"type" => "string"},
                 "bar" => %{
                   "type" => "array",
                   "items" => %{"type" => "number"}
                 }
               }
             }
    end

    test "does not remove other custom properties" do
      schema = %{
        "type" => "object",
        "x-custom" => "value",
        "x-other" => "keep me"
      }

      cleaned = SchemaUtils.clean_custom_property(schema, "x-custom")

      assert cleaned == %{
               "type" => "object",
               "x-other" => "keep me"
             }
    end
  end

  describe "clean_all_custom_properties/1" do
    test "removes all properties starting with x-" do
      schema = %{
        "type" => "object",
        "x-one" => 1,
        "x-two" => 2,
        "properties" => %{
          "foo" => %{
            "type" => "string",
            "x-three" => 3
          }
        }
      }

      cleaned = SchemaUtils.clean_all_custom_properties(schema)

      assert cleaned == %{
               "type" => "object",
               "properties" => %{
                 "foo" => %{"type" => "string"}
               }
             }
    end

    test "handles lists properly" do
      schema = %{
        "type" => "array",
        "items" => [
          %{"type" => "string", "x-ignore" => true},
          %{"type" => "number", "x-ignore" => true}
        ]
      }

      cleaned = SchemaUtils.clean_all_custom_properties(schema)

      assert cleaned == %{
               "type" => "array",
               "items" => [
                 %{"type" => "string"},
                 %{"type" => "number"}
               ]
             }
    end
  end
end
