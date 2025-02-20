local typedefs = require "kong.db.schema.typedefs"

local PLUGIN_NAME = "ssk-cors"
local type_string = { type = "string" }
local type_string_array = {
        type = "array",
        elements = type_string
}

local schema = {
  name = PLUGIN_NAME,
  fields = {
    -- the 'fields' array is the top-level entry with fields defined by Kong
    { consumer = typedefs.no_consumer },  -- this plugin cannot be configured on a consumer (typical for auth plugins)
    { protocols = typedefs.protocols_http },
    { config = {
        -- The 'config' record is the custom part of the plugin schema
        type = "record",
        fields = {
                { ["tags"] = type_string_array },
                { block = {type = "boolean"}},
                { modify_response_header = {type = "boolean"}},
                { allow_origins = type_string_array },
                { allow_methods = type_string_array },
                { allow_headers = type_string_array },
                { expose_headers = type_string_array },
                { allow_credentials = {type = "boolean"}},
                { max_age = {type = "integer"}},
        },
        entity_checks = {
          -- add some validation rules across fields
        },
      },
    },
  },
}

return schema
