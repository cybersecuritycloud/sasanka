# README(OSS publish)

# Overview

Kong plugins to add WAF functionality to the Gateway to further improve the security of Kong Gateway.

Five plugins are provided as OSS, and users can choose to add the necessary functions.

---

# Features

| Plugin Name | Function | Description |
| --- | --- | --- |
| ssk-pm | Pattern Match | Detection is performed by matching against the pattern rules that have been read. |
| ssk-safehost | Host Check | Detection is performed by matching the set Host with the actual upstream Host. |
| ssk-cors | CORS Check | Detection is performed by matching the header related CORS set config. |
| ssk-detecthandling | Detect Handling | Set the response status, header, and body when detection is performed. |
| ssk-std-logger | Output Detect Log | Logs to standard output or standard error output when detection is performed. |
| ssk-ua-filter | Filter by Any User-Agent | You can set any user-agent to block. And can block no-user-agent request. |
| ssk-libinjection | Detect Using Libinjection | Using libinjection, it can detect attack by SQL syntax not regex. |
| ssk-clickjacking | Prevent Clickjacking | Prevent clicjacking attack. |
| ssk-saferedirect | Strict Redirection | Strict host to redirect by whitelist. |
| ssk-strictparameter | Strict and Validate Parameters | Validating params like JSON Schema and it can also restrict value to prevent MassAssignment for example. |
| ssk-telemetry | Output Telemetry |  |

These plugins are **not compatible** with DB-less mode.

You can select these of above you need and set as plugin of Kong.

---

# Install and Get Start

## Requirements

If you need help with KONG installation, see the documentation on [Install and Run KONG](https://docs.konghq.com/gateway/2.8.x/install-and-run/).

### Related KONG

If you already have KONG installed, please skip this.

- KONG(=2.8.2, 3.0.0, 3.3.0)
- postgreSQL
- Lua ≥ 5.1, 5.3
- luarocks

### Additional

- pcre2
    - This pcre2 is not necessary. Plugins can execute without pcre2 but we recommend install pcre2 for performance.
    
    [http://openresty.org/misc/re/bench/](http://openresty.org/misc/re/bench/)
    

To install, please refer to the following.

```bash
# install dependency
sudo apt-get install -y libpcre2-dev
sudo luarocks install lrexlib-pcre2 
```

- libinjection

## Install Plugins in Kong Gateway

Execute following.

```bash
git clone https://github.com/cybersecuritycloud/sasanka.git
cd sasanka
luarocks install release/${PLUGIN_NAME}${VERSIONS}.all.rock
```

And add your `kong.conf` ’s plugins item you want like following example.

```bash
plugins = bundled,ssk-detecthandling,ssk-safehost,ssk-pm,ssk-cors,ssk-std-logger,ssk-ua-filter,ssk-optimizer,ssk-libinjection,ssk-saferedirect,ssk-clickjacking,ssk-strictparameter,ssk-response-transform,ssk-telemetry
```

---

# Usage

Following example of enable plugin is assumed to enable on Service. 

So if you want to set plugins of the route, replace `SERVICE_NAME|SERVICE_ID`with the `ROUTE_NAME|ROUTE_ID` of the route that this plugin configuration will target.

And you should replace `SERVICE_NAME|SERVICE_ID`with the `id` or `name` of the service that this plugin configuration will target. 

Replace localhost and 8081 to your Kong AdminHost and Port each other.

### ssk-pm

Pattern matching is performed for patterns read in the settings.

Enable on Service

```bash
curl -i -X POST http://localhost:8001/services/SERVICE_NAME|SERVICE_ID/plugins \
    -H "Content-Type: application/json" \
    -d '{"name": "ssk-pm",  
		"config": { "patterns" : [ {"name": "example-pattern-key", "patterns" ["aa", "bb"] } ],
		"params": [ { "in": "param_req_query",  "key": "*", "patterns": ["example-pattern-key"] } ] } 
		}'
```

**Config Parameters**

| key | type | description | required | default value |
| --- | --- | --- | --- | --- |
| config.patterns | array of table elements | Define the pattern to be set and its name. | - | table |
| config.patterns[i].name | string | Defines the name of the pattern to be set. | - | nil |
| config.patterns[i].patterns | array of string elements | Set pattern rules as an array. | - | nil |
| config.params | array of table elements | Defines where the configured pattern will be applied. | - | table |
| config.params[i].in | string | Defines the item to apply detection to. ["param_req_query", "param_req_path", “param_req_header”, “param_req_cookie”,  "param_req_body", “param_req_*”, “param_res_header”, “param_res_*”].Select one of them or use "*" or null to apply all params. | - | nil |
| config.params[i].key | string | Define the parameter key to apply detection.If "*" or null, all parameter keys are applied. | - | nil |
| config.params[i].patterns | array of string elements | Define the pattern to be applied among the patterns defined in config.patterns. | - | nil |

### ssk-safehost

Check the configured host against the actual upstream host.

The host in this plugin means the value of host header. So it’s same as FQDN correctly.

Enable on Service Example

```bash
curl -i -X POST http://localhost:8001/services/SERVICE_NAME|SERVICE_ID/plugins \
    -d "name=ssk-safehost" \
    -d "config.host_check=a.com"
```

| key | type | description | required | default value |
| --- | --- | --- | --- | --- |
| config.host_check | string | Set the hostname of the upstream.By default, port:80 is set, but if the port is other than 80, the port must also be included. | true |  |

### ssk-cors

Detects related CORS.

When modify_response_header=true, the response header is modified when detected.

Enable on Service Example

```bash
curl -i -X POST http://localhost:8001/services/SERVICE_NAME|SERVICE_ID/plugins \
		-H "Content-Type: application/json" \
    -d '{
			"name": "ssk-cors", 
			"config": {
				"block": true, 
				"modify_response_header": true, 
				"allow_origins": ["*"],
				"allow_methods": ["OPTIONS", "GET", "PUT"],
				"allow_headers": ["*"],
				"expose_headers": ["*"],
				"allow_credentials": false,
				"max_age": 3600
				}
		}'
```

**Config Parameters**

| key | type | description | required | default value |
| --- | --- | --- | --- | --- |
| config.block | boolean | enable cors block | true |  |
| config.modify_response_header | boolean | Sets whether to modify the response header when a detection or block is made. | - | nil |
| config.allow_origins | array of string elements | Defines which origins are allowed."*"is ALL ARE ALLOWED. null is ALL ARE NOT ALLOWED.If modify_response_header is true, add Access-Control-Allow-Origin: configuration value to the Header. | - | nil |
| config.allow_methods | array of string elements | Defines which methods are allowed." *" allows all.If modify_response_header is true, add the Access-Control-Allow-Headers: setting to the Header. | - | nil |
| config.allow_headers | array of string elements | Defines which headers are allowed." *" allows all.If modify_response_header is true, add Access-Control-Allow-Headers: configuration value to the Header. | - | nil |
| config.expose_headers | array of string elements | If modify_response_header is true, add Access-Control-Expose-Headers: configuration value to Header. | - | nil |
| config.allow_credentials | boolean | If modify_response_header is true, add Access-Control-Allow-Credentials: configuration value to the Header. | - | nil |
| config.max_age | integer | If modify_response_header is true, add the Access-Control-Max-Age: setting value to the Header. | - | nil |

### ssk-detecthandling

Change Response to set value when detected by ssk-* Plugin.

Enable on Service Example

```bash
curl -i -X POST http://localhost:8001/services/SERVICE_NAME|SERVICE_ID/plugins \
    -H "Content-Type: application/json"\
		-d '{
				"name": "ssk-detecthandling", 
				"config": {
					"headers": [{"key": "x-gateway", "value": "sasanka-kong-gateway"}], 
					"status": "441", 
					"body": "detected by sasanka"
					}
				}'
```

| key | type | description | required | default value |
| --- | --- | --- | --- | --- |
| config.status | integer | Sets the response status when detected. | true |  |
| config.headers | array of table elements | Sets the response headers in key-value format when detected. | true |  |
| config.body | string | Sets the response body when detected. | true |  |

### ssk-std-logger

Standard output of what is detected when detected by the ssk-* Plugins.

Enable on Service Example

```bash
curl -i -X POST http://localhost:8001/services/SERVICE_NAME|SERVICE_ID/plugins \
    -d "name=ssk-std-logger" \
    -d "config.std=out" \
		-d "config.header=[ssk-detect]"
```

| key | type | description | required | default value |
| --- | --- | --- | --- | --- |
| config.std | string | Select out or err for where to output detected log. | true |  |
| config.header | string | You can set to specify log header. |  | [ssk-detect] |

### Log Rule Id

The detection logs output from ssk-std-logger are managed by the following rule IDs.

| Log Id | Detected by |
| --- | --- |
| 10 | ssk-pm |
| 20 | ssk-safehost |
| 30 | ssk-cors |
| 40 | ssk-ua-filter |
| 60 | ssk-libinjection |
| 70 | ssk-saferedirect |
| 80 | ssk-strictparamater |

### ssk-ua-filter

Manage User-Agent to block.

Enable on Service Example

```bash
curl -i -X POST http://localhost:8001/services/SERVICE_NAME|SERVICE_ID/plugins \
		-H "Content-Type: application/json" \
		-d '{
				"name": "ssk-ua-filter", 
				"config": {
					"block_useragents" : ["python/", "Powershell"], 
					"block_no_useragent" : true
					}
				}'
```

| key | type | description | required | default value |
| --- | --- | --- | --- | --- |
| config.block_useragents | array | Array of User-Agent to block.
The function searches for the first match | - |  |
| config.block_no_useragent | bool | Block if User-Agent is not set. | - | false |

### ssk-libinjection

Detect using libinjection.

What is libinjection? Libinjection is the library to detect SQLinjection. To detect SQLinjection, parsing SQL syntax and detect iregular pattern instead of regular expression. Comparing with way to detect between regular expression and libinjection, libinjection can detect faster and correctly.And different from regex,generally libinjection cause misdetection lesss because it understand SQL syntax.

You should execute install script to install required package for libinjection.

There is the install script on ./install_libinjection.sh.

Version of libinjection we’re using is as of Mar 30, 2023.

Enable on Service Example

```bash
curl -i -X POST http://localhost:8001/services/SERVICE_NAME|SERVICE_ID/plugins \
    -H "Content-Type: application/json" \
    -d '{
			"name": "ssk-libinjection",
			"config":{ 
				"params": [ 
					{ "in": "param_req_query" } 
					{ "in": "param_req_body",  "key": "var", "sql": true } 
					]
				} 
			}'
```

| key | type | description | required | default value |
| --- | --- | --- | --- | --- |
| config.params[i].in | string | Defines the item to apply detection to. ["param_req_query", "param_req_path", “param_req_header”, “param_req_cookie”,  "param_req_body", “param_req_*”, “param_res_header”, “param_res_*”].Select one of them or use "*" or null to apply all params. | - | nil |
| config.params[i].key | string | Define the parameter key to apply detection.If "*" or null, all parameter keys are applied. | - | nil |
| config.params[i].sql | bool | Parse SQL syntax | - | true |
| config.params[i].xss | bool | Parse XSS syntax | - | true |

### ssk-clickjacking

Prevent Clickjacking.

Clickjacking is an WEB attack in which a user is tricked into fake linke, fake button.

Enable on Service Example

```bash
curl -i -X POST http://localhost:8001/services/SERVICE_NAME|SERVICE_ID/plugins \
	-d "config.name=ssk-clickjacking" \
  -d "config.policy=DENY"
```

| key | type | description | required | default value |
| --- | --- | --- | --- | --- |
| config.policy | string | Select “DENY” or “SAMEORIGIN”. DENY don’t allows all rewriting iframe. | - | DENY |

### ssk-saferedirect

Restrict redirect to host. 

If prefix configured was match, allow redirect.

Enable on Service Example

```bash
curl -i -X POST http://localhost:8001/services/SERVICE_NAME|SERVICE_ID/plugins \
    -H "Content-Type: application/json" \
    -d '{
			"name": "ssk-saferedirect",
			"config": {
				"params": [ 
					{ "in": "param_req_body",  "key": "redirect", "prefix": "http://my-redirect/api/" } 
					]
				}
			}'
```

| key | type | description | required | default value |
| --- | --- | --- | --- | --- |
| config.params[].in | string | Defines the item to apply detection to. ["param_req_query", “param_req_body” ].Select one of them | - |  |
| config.params[].key | string | Define the parameter key to apply detection. “*” is NOT enable. |  |  |
| config.params[].prefix | string | Host to match prefix allow redirect. |  |  |

### ssk-strictparameter

Restrict specific param’s type or length or numeric value range.

Enable on Service Example

```bash
curl -i -X POST http://localhost:8001/services/SERVICE_NAME|SERVICE_ID/plugins \
    -H "Content-Type: application/json" \
    -d '{
			"name": "ssk-strictparameter",
			"config": {
				"params": [
		        { "in": "param_req_query", "key": "readonly", "type": "boolean" },
		        { "in": "param_req_query", "key": "created_at", "type": "date", "min": 10, "max": 10 },
		        { "in": "param_req_query", "key": "pagenum", "type": "int", "required": true, "max": 1000},
		        { "in": "param_req_query", "key": "session_id", "type": "uuid", "min": 36, "max": 36 },
		        { "in": "param_req_query", "key": "name", "type": "regex", "pattern" : "^user-[0-9]+$", "min": 8, "max": 12 }
				  ]
				}
			}'
```

| key | type | description | required | default value |
| --- | --- | --- | --- | --- |
| config.params[].in | string | Defines the item to apply detection to. ["param_req_query", "param_req_path", “param_req_body”, ].Select one of them | true |  |
| config.params[].key | string | Define the parameter key to apply detection. | true |  |
| config.params[].type | string | Host to match prefix allow redirect. | true |  |
| config.params[].required | bool | Is this key always required. | - | false |
| config.params[].pattern | string | Enable if type is regex. Set regex pattern. | - |  |
| config.params[].min | int | If type is int or float, numeric value minimum.Otherwise minimum length as string. | - |  |
| config.params[].max | int | If type is int or float, numeric value maximum.Otherwise maxmum length as string. | - |  |

### ssk-telemetry

Output telemetry measured by Kong.

Mention! This plugin only execute as global plugin, so it can’t be enable on service or route.

Enable on Global Example

```bash
curl -i -X POST http://localhost:8001/plugins \
    -H "Content-Type: application/json" \
    -d '{
				"name": "ssk-telemetry",
				"config": {
					"std": "out",
					"tag": ,
					"header": 
				}
		}'
```

| key | type | description | required | default value |
| --- | --- | --- | --- | --- |
| config.std | string |  | true | “out” |
| config.tag | string |  | - |  |
| config.header | string |  | - |  |

---

# Quick Start

### requirements

- Kong
    - Need to `kong restart` after adding selected plugin to plugins in kong.conf
- python3 (>=3.6)
- Core-Rule-Set (automated Install in quickstart.sh)

```bash
./quickstart.sh YOUR_SERVICE_NAME_OR_ID
```

---

# Author

CyberSecurityCloud.Inc

[https://www.cscloud.co.jp/](https://www.cscloud.co.jp/)

---

# License

```
   Copyright 2023 CyberSecurityCloud Inc.

   Licensed under the Apache License, Version 2.0 (the "License");
   you may not use this file except in compliance with the License.
   You may obtain a copy of the License at

       http://www.apache.org/licenses/LICENSE-2.0

   Unless required by applicable law or agreed to in writing, software
   distributed under the License is distributed on an "AS IS" BASIS,
   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
   See the License for the specific language governing permissions and
   limitations under the License.
```

[README.ja](https://www.notion.so/README-ja-5b15fb8e8b3a42bda74556c1f59ddb1e?pvs=21)

[OSS LICENSE](https://www.notion.so/OSS-LICENSE-b8af4f8cfdca480fb2edb97aaff151f9?pvs=21)