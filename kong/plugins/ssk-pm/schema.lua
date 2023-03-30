local typedefs = require "kong.db.schema.typedefs"

local PLUGIN_NAME = "ssk-pm"

local type_pattern = { type = "string" }
local type_pattern_name = { type = "string" }

local type_path_array = {
        type = "array",
        elements = { type = "string" }
}

local type_pattern_name_array = {
        type = "array",
        elements = type_pattern_name
}

local type_pattern_array = {
        type = "array",
        elements = type_pattern
}

local type_pattern_info = {
        type = "record",
        fields = {
                { name = { type = "string" }},
                { patterns = type_pattern_array },
	}
}
local type_pattern_info_array = {
        type = "array",
        elements = type_pattern_info,
}

local type_param_info = {
        type = "record",
        fields = {
                { ["in"] = { type = "string" }},
                { key = { type = "string" }},
                { patterns = type_pattern_name_array },
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
		{ patterns = type_pattern_info_array },
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
