-- https://swagger.io/specification/#dataTypeFormat
local function match_type(t, p, target)
	local pm = require "kong.plugins.cscapisec.lib.patternmatcher"

	if t == 'integer' or t == 'int' then
		return pm.detect(target, "^([+-]?\\d+)$")
	end

	if t == 'number' then
		return pm.detect(target, "^[+-]?\\d+([.]\\d+([Ee][+-]\\d+)?)?$")
	end

	if t == 'string' then
		local full_date = '\\d{4}-\\d{2}-\\d{2}'
		local time_delta = '(Z|[+-]\\d{2}:\\d{2})'
		local full_time = '\\d{2}:\\d{2}:\\d{2}([.]\\d+)?' .. time_delta
		local date_time = full_date .. "T" .. full_time
		
		if p == 'date' then
			return pm.detect(target, "^".. full_date .. "$")
		end
		if p == 'date-time' then
			return pm.detect(target, "^".. date_time .. "$")
		end
		return true
	end

	if t == 'boolean' then
		return pm.detect(target, "^(true|false)$", true)   
	end

	return true
end

local function check_type(t, p, target)
	local from, to = match_type(t, p, target)
	if from == nil then
		return false
	end
	return true
end



local function test(expect, t, p, target)
	local result = check_type(t, p, target)
	if result == expect then
		print(t, p, target, " => ", result)
	else
		print(t, p, target, " => ", result, " (( expected" , expect, "))")
	end
end

local function testcase()
	print('===== integer ===')
	test(true,  'integer', '', 0) 
	test(true,  'integer', '', '0') 
	test(false, 'integer', '', 'some string') 
	test(true,  'integer', '', 42) 
	test(true,  'integer', '', '42') 
	test(true,  'integer', '', '56237842') 
	test(true,  'integer', '', '+43422')  
	test(false, 'integer', '', '5623.7842') 
	test(false, 'integer', '', '+43.422') 
	test(true,  'int', '', '+43422') 
	test(true,  'int', '', '-43422') 
	test(false, 'int', '', '434-22') 
	print('===== number ===')
	test(true,  'number', '', '42') 
	test(true,  'number', '', '56237842') 
	test(true,  'number', '', '43422') 
	test(true,  'number', '', '+43422') 
	test(true,  'number', '', '-43422') 
	test(true,  'number', '', '42.24352') 
	test(true,  'number', '', '56237842.111') 
	test(true,  'number', '', '43422.1') 
	test(true,  'number', '', '+43422.88853') 
	test(true,  'number', '', '-43422.2') 
	test(false, 'number', '', '+43422.88.853') 
	test(false, 'number', '', '-43422.2d') 
	print('===== string ===')
	test(true,  'string', '', '42') 
	test(true,  'string', '', '+43422.88853') 
	test(true,  'string', '', 'AAckvie(()33$df') 
	print('===== date ===')
	test(false, 'string', 'date', '4') 
	test(false, 'string', 'date', '421') 
	test(false, 'string', 'date', '12-08') 
	test(false, 'string', 'date', '19221208') 
	test(true,  'string', 'date', '1922-12-08') 
	test(true,  'string', 'date', '7292-42-99') 
	print('===== date-time ===') 
	test(false, 'string', 'date-time', '12-08') 
	test(false, 'string', 'date-time', '19221208') 
	test(false, 'string', 'date-time', '1922-12-08') 
	test(false, 'string', 'date-time', '1922-12-02T14:12:53.+05:308') 
	test(true,  'string', 'date-time', '1922-12-02T14:12:53Z')
	test(false, 'string', 'date-time', '1922-12-02T14:12:53D')
	test(false, 'string', 'date-time', '1922-12-02T14:12:53') 
	test(true,  'string', 'date-time', '1922-12-02T14:12:53+05:30') 
	test(true,  'string', 'date-time', '2006-04-13T14:12:53.4242+05:30') 
	test(false, 'string', 'date-time', '2006-04-13T14:12:53:4242+05:30') 

	print('===== boolean ===')
	--	test(true,  'boolean', '', true) 
	test(true,  'boolean', '', 'true') 
	test(true,  'boolean', '', 'True') 
	test(true,  'boolean', '', 'false') 
	test(false, 'boolean', '', 'Trues')
end

return {
	check_type = check_type,
	test = test,
}

