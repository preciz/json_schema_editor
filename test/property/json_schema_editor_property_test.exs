defmodule JSONSchemaEditor.PropertyTest do
  use ExUnit.Case, async: true
  use ExUnitProperties

  alias JSONSchemaEditor.{SchemaGenerator, SimpleValidator}

  # Generator for JSON-compatible data
  def json_data do
    tree(simple_json_data(), fn complex ->
      one_of([
        list_of(complex),
        map_of(string(:printable), complex)
      ])
    end)
  end

  def simple_json_data do
    one_of([
      string(:printable),
      integer(),
      float(),
      boolean(),
      constant(nil)
    ])
  end

  property "generated schema always validates the source data" do
    check all(data <- json_data()) do
      # 1. Generate schema from data
      schema = SchemaGenerator.generate(data)

      # 2. Validate original data against generated schema
      # Ideally, the generator should create a schema that matches the data exactly or loosely enough
      errors = SimpleValidator.validate(schema, data)

      assert errors == [],
             "Generated schema failed to validate source data.\nData: #{inspect(data)}\nSchema: #{inspect(schema)}\nErrors: #{inspect(errors)}"
    end
  end

  property "validator never crashes on random schema/data combinations" do
    # This just ensures robustness against crashes, not correctness of validation logic
    # We generate somewhat structure-like maps for schemas

    check all(
            schema <- map_of(string(:printable), simple_json_data()),
            data <- json_data()
          ) do
      try do
        SimpleValidator.validate(schema, data)
        assert true
      rescue
        _ -> flunk("Validator crashed on inputs")
      end
    end
  end
end
