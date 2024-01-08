local typedefs = require "kong.db.schema.typedefs"

local PLUGIN_NAME = "ssk-libinjection"

local type_tag_array = {
        type = "array",
        elements = { type = "string" }
}

local type_path_array = {
        type = "array",
        elements = { type = "string" }
}

local type_param_info = {
        type = "record",
        fields = {
                { ["in"] = { type = "string", default = "param_req_*", }},
                { key = { type = "string", default = "*", }},
		{ sql = { type = "boolean", default = true, }},
		{ xss = { type = "boolean", default = true, }},
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
		{ tags = type_tag_array },
		{ paths = type_path_array },
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
