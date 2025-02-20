local typedefs = require "kong.db.schema.typedefs"

local PLUGIN_NAME = "ssk-magika"

local type_string_array = {
        type = "array",
        elements = { type = "string" },
}

local type_param_info = {
  type = "record",
  fields = {
          { ["in"] = { type = "string", default = "param_req_*", }},
          { ["key"] = { type = "string", default = "*", }},
  }
}
local type_param_info_array = {
  type = "array",
  elements = type_param_info,
}

local schema = {
  name = PLUGIN_NAME,
  fields = {
    { protocols = typedefs.protocols_http },
    { config = {
        type = "record",
        fields = {
                { ["tags"] = type_string_array },
                { ["allows"] = type_string_array },
                { ["denys"] = type_string_array },
                { ["params"] = type_param_info_array },
        },
        entity_checks = {
        },
      },
    },
  },
}

return schema
