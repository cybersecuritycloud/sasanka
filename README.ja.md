# README.ja

# 概要

Kong Gatewayの更なるセキュリティ向上のためWAFとしての機能をGatewayに追加するためのKongプラグイン。

5つのプラグインをOSSで提供し、ユーザーの選択により必要な機能を追加することが可能。

---

# 機能

| Plugin Name | Function | Description |
| --- | --- | --- |
| ssk-pm | Pattern Match | 読み込んだパターンルールに対してのマッチを行い検知する。 |
| ssk-safehost | Host Check | セットされたHostと実際のHostを照合、検知する。 |
| ssk-cors | CORS Check | 設定に基づきCORS関連HeaderのOrigin等をチェックし、検知する。 |
| ssk-detecthandling | Detect Handling | 検知が行われた場合のresponse status,header, bodyを設定する。 |
| ssk-std-logger | Output Detect Log | 検知が行われた場合のログを標準出力or標準エラー出力する。 |

このPlugin はDB-lessモードでは**動作しません**。

---

# インストールと始め方

## Requirements

Kongのインストールは[こちら](https://docs.konghq.com/gateway/2.8.x/install-and-run/)を確認してください。

### Related KONG

- KONG(=3.1.0)
- postgresql
- Lua ≥ 5.1
- luarocks

- pcre2
    - pcre2は必須ではありませんが、パフォーマンス向上のためインストールを推奨します。
    
    [http://openresty.org/misc/re/bench/](http://openresty.org/misc/re/bench/)
    

以下を参考にインストールしてください。

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

# 使用方法

`SERVICE_NAME|SERVICE_ID` は、Pluginを設定する対象のサービス名, idと置き換えてください。

Routeに設定する場合は、`SERVICE_NAME|SERVICE_ID`を`ROUTE_NAME|ROUTE_ID`に読み替えてください。

### ssk-pm

設定で読み込んだパターンに対してパターンマッチを行う。

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
| config.patterns | array of table elements | 設定するパターンとその名前を定義します。 | - | table |
| config.patterns[i].name | string | 設定するパターンの名前を定義します。 | - | nil |
| config.patterns[i].patterns | array of string elements | パターンを配列で設定します。 | - | nil |
| config.params | array of table elements | 設定したパターンの適用場所を定義します。 | - | table |
| config.params[i].in | string | 検知をかける項目を定義します。[”param_req_query”, “param_req_path”, “param_req_body”]の中から選択するか、”*” or nullだと全てのparamが適用されます。 | - | nil |
| config.params[i].key | string | 検知をかけるparameter keyを定義します。”*”か null だと全てのparameter keyが適用されます。 | - | nil |
| config.params[i].patterns | array of string elements | config.patternsで定義したpatternのうち、適用するパターンを定義します。 | - | nil |

### ssk-safehost

設定したhostと実際のupstreamのhostを照合する。

Enable on Service

```bash
curl -i -X POST http://localhost:8001/services/SERVICE_NAME|SERVICE_ID/plugins \
    -d "name=ssk-safehost" \
    -d "config.host_check=a.com"
```

| key | type | description | required | default value |
| --- | --- | --- | --- | --- |
| config.host_check | string | upstreamのhost名を設定します。デフォルトではport:80が設定されますが、upstreamのportが80以外の場合は、portも含めて設定が必要です。 | true | nil |

### ssk-cors

CORSに関する検知を行う。

modify_response_header=true の際、検知した時のresponse headerが修正される。

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
| config.block | boolean | 検知が行われた場合に、requestをブロックするか設定します。 | true |  |
| config.modify_response_header | boolean | 検知、ブロックが行われた場合にresponse headerを修正するか設定します。 | - | nil |
| config.allow_origins | array of string elements | 許可するoriginを定義します。”*” or null の場合は全て許可しません。modify_response_header is true の場合、Headerに Access-Control-Allow-Origin: 設定値 を追加します。 | - | nil |
| config.allow_methods | array of string elements | 許可するmethodを定義します。”*”は全て許可します。modify_response_header is true の場合、Headerに Access-Control-Allow-Headers: 設定値 を追加します。 | - | nil |
| config.allow_headers | array of string elements | 許可するheaderを定義します。”*”は全て許可します。modify_response_header is true の場合、Headerに Access-Control-Allow-Headers: 設定値 を追加します。 | - | nil |
| config.expose_headers | array of string elements | modify_response_header is true の場合、Headerに Access-Control-Expose-Headers: 設定値 を追加します。 | - | nil |
| config.allow_credentials | boolean | modify_response_header is true の場合、Headerに Access-Control-Allow-Credentials: 設定値 を追加します。 | - | nil |
| config.max_age | integer | modify_response_header is true の場合、Headerに Access-Control-Max-Age: 設定値 を追加します。 | - | nil |

### ssk-detecthandling

ssk-* Pluginで検知された場合にResponseを設定値に変更する。

Enable on Service

```bash
curl -i -X POST http://localhost:8001/services/SERVICE_NAME|SERVICE_ID/plugins \
    -H "Content-Type: application/json"\
		-d '{"name": "ssk-detecthandling", \
			"config": {"headers": [{"key": "x-gateway", "value": "sasanka-kong-gateway"}], \
			"status": "441", \
			"body": "detected by sasanka"}}'
```

| key | type | description | required | default value |
| --- | --- | --- | --- | --- |
| config.status | integer | 検知した際のresponse statusを設定します。 | true | nil |
| config.headers | array of table elements | 検知した際のresponse headersをkey-value形式で設定します。 | true | nil |
| config.body | string | 検知した際のresponse body を設定します。 | true | nil |

### ssk-std-logger

ssk-* Pluginで検知された場合に検知した内容を標準出力する。

Enable on Service

```bash
curl -i -X POST http://localhost:8001/services/SERVICE_NAME|SERVICE_ID/plugins \
    -d "name=ssk-std-logger" \
    -d "config.std=out"
```

| key | type | description | required | default value |
| --- | --- | --- | --- | --- |
| config.std | string | 検知ログの出力先を設定します。out or err を設定でき、標準出力または標準エラー出力で設定します。 | true | - |

### Log Rule Id

ssk-std-loggerから出力された検知ログは以下のルールIDで管理されます。

| id | detect by |
| --- | --- |
| 1201 | ssk-cors |
| 1202 | ssk-safehost |
| 1401 | ssk-pm |

---

# クイックスタート

### requirements

- Kong
    - `ssk-detecthandling,ssk-safehost,ssk-pm,ssk-cors,ssk-std-logger` をkong.confに追加してから `kong restart` を行う必要があります。
- python3 (>=3.6)

```bash
./quickstart.sh YOUR_SERVICE_NAME_OR_ID
```

---

# 著作者

株式会社サイバーセキュリティクラウド

[https://www.cscloud.co.jp/](https://www.cscloud.co.jp/)

---