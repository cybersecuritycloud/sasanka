local typedefs = require "kong.db.schema.typedefs"

local PLUGIN_NAME = "ssk-saferedirect"

local type_string_array = {
        type = "array",
        elements = { type = "string" }
}

local type_param_info = {
        type = "record",
        fields = {
                { ["in"] = { type = "string", default = "param_req_*", }},
                { key = { type = "string", default = "*", }},
                { prefix = { type = "string" }},
        }
}
local type_param_info_array = {
        type = "array",
        elements = type_param_info,
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
                { params = type_param_info_array },
        },
        entity_checks = {
          -- add some validation rules across fields
        },
      },
    },
  },
}

return schema
