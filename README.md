# README

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

These plugins are **not compatible** with DB-less mode.

---

# Install and Get Start

## Requirements

If you need help with KONG installation, see the documentation on [Install and Run KONG](https://docs.konghq.com/gateway/2.8.x/install-and-run/).

### Related KONG

If you already have KONG installed, please skip this.

- KONG(>=2.8.2)
- postgresql
- Lua ≥ 5.1
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

## Install Plugins in Kong Gateway

```bash
git clone https://github.com/cybersecuritycloud/sasanka.git
cd sasanka
luarocks install rocks/${PLUGIN_NAME}${VERSIONS}.all.rock
```

---

# Usage

Replace `SERVICE_NAME|SERVICE_ID`with the `id` or `name` of the service that this plugin configuration will target.

Or if you want to set plugins of the route, replace `SERVICE_NAME|SERVICE_ID`with the `ROUTE_NAME|ROUTE_ID` of the route that this plugin configuration will target.

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
| config.params[i].in | string | Defines the item to apply detection to. ["param_req_query", "param_req_path", "param_req_body"].Select one of ["param_req_query", "param_req_path", "param_req_body"], oruse "*" or null to apply all params. | - | nil |
| config.params[i].key | string | Define the parameter key to apply detection.If "*" or null, all parameter keys are applied. | - | nil |
| config.params[i].patterns | array of string elements | Define the pattern to be applied among the patterns defined in config.patterns. | - | nil |

### ssk-safehost

Check the configured host against the actual upstream host.

Enable on Service

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

Enable on Service

```bash
curl -i -X POST http://localhost:8001/services/SERVICE_NAME|SERVICE_ID/plugins \
		-H "Content-Type: application/json" \
    -d '{"name"= "ssk-cors", 
		"config": {"block": true, 
		"modify_response_header": true, 
		"allow_origins": ["*"],
		"allow_methods": ["OPTIONS", "GET", "PUT"],
		"allow_headers": ["*"],
		"expose_headers": ["*"],
		"allow_credentials": false,
		"max_age": 3600}
		}'
```

**Config Parameters**

| key | type | description | required | default value |
| --- | --- | --- | --- | --- |
| config.block | boolean | enable cors block | true |  |
| config.modify_response_header | boolean | Sets whether to modify the response header when a detection or block is made. | - | nil |
| config.allow_origins | array of string elements | Defines which origins are allowed."*" or null, ALL ARE NOT ALLOWED.If modify_response_header is true, add Access-Control-Allow-Origin: configuration value to the Header. | - | nil |
| config.allow_methods | array of string elements | Defines which methods are allowed." *" allows all.If modify_response_header is true, add the Access-Control-Allow-Headers: setting to the Header. | - | nil |
| config.allow_headers | array of string elements | Defines which headers are allowed." *" allows all.If modify_response_header is true, add Access-Control-Allow-Headers: configuration value to the Header. | - | nil |
| config.expose_headers | array of string elements | If modify_response_header is true, add Access-Control-Expose-Headers: configuration value to Header. | - | nil |
| config.allow_credentials | boolean | If modify_response_header is true, add Access-Control-Allow-Credentials: configuration value to the Header. | - | nil |
| config.max_age | integer | If modify_response_header is true, add the Access-Control-Max-Age: setting value to the Header. | - | nil |

### ssk-detecthandling

Change Response to set value when detected by ssk-* Plugin.

Enable on Service

```bash
curl -i -X POST http://localhost:8001/services/SERVICE_NAME|SERVICE_ID/plugins \
    -H "Content-Type: application/json"\
		-d '{"name": "ssk-detecthandling", 
			"config": {"headers": [{"key": "x-gateway", "value": "sasanka-kong-gateway"}], 
			"status": "441", 
			"body": "detected by sasanka"}}'
```

| key | type | description | required | default value |
| --- | --- | --- | --- | --- |
| config.status | integer | Sets the response status when detected. | true | nil |
| config.headers | array of table elements | Sets the response headers in key-value format when detected. | true | nil |
| config.body | string | Sets the response body when detected. | true | nil |

### ssk-std-logger

Standard output of what is detected when detected by the ssk-* Plugins.

Enable on Service

```bash
curl -i -X POST http://localhost:8001/services/SERVICE_NAME|SERVICE_ID/plugins \
    -d "name=ssk-std-logger" \
    -d "config.std=out"
```

| key | type | description | required | default value |
| --- | --- | --- | --- | --- |
| config.std | string | out or err | required |  |

### Log Rule Id

The detection logs output from ssk-std-logger are managed by the following rule IDs.

| id | detect by |
| --- | --- |
| 1201 | ssk-cors |
| 1202 | ssk-safehost |
| 1401 | ssk-pm |

---

# Quick Start

### requirements

- Kong
    - Need to `kong restart` after adding `ssk-detecthandling,ssk-safehost,ssk-pm,ssk-cors,ssk-std-logger` to plugins in kong.conf
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
