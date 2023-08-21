# Prerequirements:
#   Kong has been installed
#   Service has been initialized
#   Kong restarted after modified kong.conf rewrite plugins


SERVICENAME=$1

if test ${#SERVICENAME} -eq 0 ; then
    echo "input YOUR_SERVICE_NAME_OR_ID in arg1"
fi


# config module
echo -e "\n\nConfigure ssk-pm\n"
curl -i -X POST http://localhost:8001/services/${SERVICENAME}/plugins \
    -H "Content-Type: application/json" \
    -d '{"name": "ssk-pm", "config": { "patterns" : [] } }'


# config module
# You should set manually your host(FQDN) on ssk-safehost.
# echo -e "\n\nConfigure ssk-safehost\n"
# curl -i -X POST http://localhost:8001/services/${SERVICENAME}/plugins \
#     -d "name=ssk-safehost"


# config module
echo -e "\n\nConfigure ssk-cors\n"
curl -i -X POST http://localhost:8001/services/${SERVICENAME}/plugins \
     -d "name=ssk-cors" \
    -d '{"name": "ssk-cors", 
		"config": {"block": true, 
		"modify_response_header": true, 
		"allow_origins": ["*"],
		"allow_methods": ["*"],
		"allow_headers": ["*"],
		"expose_headers": ["*"],
		"allow_credentials": false,
		"max_age": 3600}
		}'


# config module
echo -e "\n\nConfigure ssk-detecthandling\n"
curl -i -X POST http://localhost:8001/services/${SERVICENAME}/plugins \
    -H "Content-Type: application/json" \
	-d '{"name": "ssk-detecthandling", 
    "config": {"headers": [{"key": "x-gateway", "value": "sasanka-kong-gateway"}], 
    "status": 441, 
    "body": "detected "}}'


# config module
# you can check the detected log in error.log
echo -e "\n\nConfigure ssk-std-logger\n"
curl -i -X POST http://localhost:8001/services/${SERVICENAME}/plugins \
    -d "name=ssk-std-logger" \
    -d "config.std=err"


# config module
echo -e "\n\nConfigure ssk-ua-filter\n"
curl -i -X POST http://localhost:8001/services/${SERVICENAME}/plugins \
    -d "name=ssk-ua-filter" \
    -d "config.block_no_useragent=true"


# config module
echo -e "\n\nConfigure ssk-libinjection\n"
curl -i -X POST http://localhost:8001/services/${SERVICENAME}/plugins \
    -H "Content-Type: application/json" \
    -d '{"name": "ssk-libinjection", "config": { "params" : [{"in": "param_req_body"}] } }'


# config module
echo -e "\n\nConfigure ssk-click-jacking\n"
curl -i -X POST http://localhost:8001/services/${SERVICENAME}/plugins \
    -d "name=ssk-clickjacking" \
    -d "config.policy=DENY"


# config module
# You should set config of ssk-strictparameter manually.
# echo -e "\n\nConfigure ssk-strictparameter\n"
# curl -i -X POST http://localhost:8001/services/${SERVICENAME}/plugins \
#     -H "Content-Type: application/json" \
#     -d '{"name": "ssk-strictparameter", "config": { "params" : [{"in": "param_req_body", "key": "", "type": "", "min": 0, "max": 18}] } }'


# config module



echo "start to build CoreRuleSet"

wget https://github.com/coreruleset/coreruleset/archive/v3.3.4.tar.gz
tar -xvzf v3.3.4.tar.gz 

sudo apt-get update -y
sudo apt-get install -y libregexp-assemble-perl

pushd coreruleset-3.3.4/util/regexp-assemble
mkdir build

files=(regexp-932100.txt regexp-932105.txt regexp-932106.txt regexp-932110.txt regexp-932115.txt regexp-932150.txt regexp-934100.txt)
for f in ${files[@]}
do
        echo "loading $f"
        cat $f| python3 regexp-cmdline.py unix | ./regexp-assemble.pl > build/${f}
        echo "saved build/$f"
done

bfiles=(933131 941130 941160 942120 942130 942140 942150 942170 942180 942190 942200 942210 942240 942280 942300 942310 942320 942330 942340 942350 942360 942370 942380 942390 942400 942410 942470 942480)
for bf in ${bfiles[@]}
do
    bfile="regexp-$bf.data"
    echo "loading $bfile"
    ./regexp-assemble.pl $bfile > build/$bfile
    echo "saved build/$bfile"
done

bv2files=(942260)
for bf in ${bv2files[@]}
do
    bfile="regexp-$bf.data"
    echo "loading $bfile"
    ./regexp-assemble-v2.pl $bfile > build/$bfile
    echo "saved build/$bfile"
done

echo "finished to build CoreRuleSet"
popd

python3 tools/quickstart.py --service $SERVICENAME


echo "
====================
Finished QuickStart

You can start sasanka Plugin by quickstart settings
====================
"

