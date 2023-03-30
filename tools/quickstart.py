import requests
import argparse
import re
import sys
import glob
import json
import os



parser = argparse.ArgumentParser()
parser.add_argument("--dir", "-d", type=str, default='coreruleset-3.3.4')
parser.add_argument("--out", "-o", type=str, help="output pattern json path", default="tools/crs_patterns.json")
parser.add_argument("--yml", "-y", type=str, help="output pattern yaml path", default="tools/crs_patterns.yml")
parser.add_argument("--service", "-s", type=str, help="SERVICE NAME OR ID", required=True)
parser.add_argument("--adminhost", "-ah", type=str, help="Admin host", default="localhost")
parser.add_argument("--adminport", "-ap", type=str, help="Admin Port", default="8001")
parser.add_argument("--mode", "-m", type=str, help="Admin Port", default="")
args = parser.parse_args()


yaml_cnv = True
try: 
    import yaml
except ImportError:
    print("you need to install pyyaml refer below or manually convert json to yaml")
    print('\n  pip install pyyaml \n')
    yaml_cnv = False

def out_plugins_format(patterns:dict, outpath:str, outyaml:str) -> None:
    
    patterns.pop("all")
    json.dump(patterns, open(outpath, "w", encoding="utf-8"), ensure_ascii=False, indent=2)
    print(f"saved {outpath}")
    if yaml_cnv:
        yaml.dump(patterns, open(outyaml, "w", encoding="utf-8"), default_flow_style=False)
        print(f"saved {outyaml}")
    return


def read_core_rule_set(crsdir, id_rules) -> dict:
    patterns, rule_patterns = load_regex_assembly(crsdir, id_rules)
    summerized = {
                "all": patterns
            }
    summerized.update(rule_patterns)
    return summerized

def is_regex_line(line) -> bool:
    if line.startswith("#") or len(line) == 0 or re.search("##!", line):
        return False
    return True

def load_regex_assembly(crsdir, id_rules):
    patter_list = list()
    rule_patterns = dict()
    build_dir = crsdir + "/util/regexp-assemble/build/"
    regex_dir = crsdir + "/util/regexp-assemble/"
    loaded = set()

    def match_rules(baseid:str, id_rules:dict) -> str:
        if baseid in id_rules:
            return id_rules[baseid]
        for i in range(1, len(baseid)):
            mid = baseid[:-i]
            for rl, rid in id_rules.items():
                mir = rid[:-i]
                if mid == mir:
                    return rid


    def load_dir(_dir_path):
        if is_debug():
            print(f"{_dir_path} path exist", os.path.exists(_dir_path))
        for df in glob.glob(_dir_path+"*.data"):
            basename = os.path.basename(df)
            baseid = re.search("[0-9]+", basename).group()
            if not re.search("[0-9]+.data", basename) or basename in loaded:
                continue
            loaded.add(basename)
            rule_name = match_rules(baseid, id_rules)
            if rule_name not in rule_patterns:
                rule_patterns[rule_name] = list()
            with open(df, 'r', encoding='utf-8') as f:
                _read = f.read()
                for l in _read.split('\n'):
                    if is_regex_line(l):
                        patter_list.append(l)
                        rule_patterns[rule_name].append(l)
        return 
    load_dir(build_dir)
    load_dir(regex_dir)

    return patter_list, rule_patterns


def get_secrule(line) -> str or None:
    secrule = None
    if re.search("SecRule", line):
        secrule = re.sub("SecRule ", "", line)
        secrule = re.sub('".+', '', secrule)
        secrule = secrule.strip()
    return secrule

def get_secid(line) -> str or None:
    secid = None
    line = line.strip()
    if re.match('"id:[0-9]+', line):
        secid = re.search("[0-9]+", line).group()
    return secid


def need_build(line) -> bool:
    return bool(re.search("\./regexp-assemble(-v2)?\.pl", line))



def load_rules_conf(crsdir) -> dict:
    id_rules = dict()
    nbuild = list()
    for conf in glob.glob(crsdir+"/rules/*.conf"):
        with open(conf, 'r', encoding='utf-8') as f:
            _read = f.read()
            current_rule = str()
            for l in _read.split('\n'):
                if get_secrule(l):
                    current_rule = get_secrule(l)
                if get_secid(l):
                    id_rules[current_rule] = get_secid(l)
                    _id = get_secid(l)
                if need_build(l):
                    nfile = re.sub("\./regexp-assemble(-v2)?\.pl (<)?", "", l)
                    nfile = re.sub("#", "", nfile)
                    nfile = nfile.strip()
                    if re.search("\.txt", nfile):
                        continue
                    if nfile in nbuild:
                        continue
                    nbuild.append(nfile)

    file_nums = [re.search("[0-9]+", f).group() for f in nbuild]
    file_nums.sort()
    return id_rules

def is_debug():
    return bool(args.mode == "debug")
    


def get_plugin_id(plugin_name):
    r = requests.request("GET", "http://"+args.adminhost+":"+args.adminport+"/services/"+args.service+"/plugins/")
    parsed = json.loads(r.text)
    for conf in parsed["data"]:
        if conf["name"] == plugin_name:
            return conf["id"]
    return None


def put_config(plugin_name, pl_config):
    header = {"Content-Type": "application/json"}
    data = {
        "name": plugin_name,
        "config": pl_config
    }
    plugin_id = get_plugin_id(plugin_name)
    r = requests.request("PUT", "http://"+args.adminhost+":"+args.adminport+"/services/"+args.service+"/plugins/"+plugin_id, headers=header, data=json.dumps(data))
    parsed = json.loads( r.text )

    if is_debug():
        print("\033[91mdata: \033[0m", data)
        print("\033[91mresponse: \033[0m", r.text)

    if "name" in parsed and parsed["name"] in ["schema violation"]:
        raise NotImplementedError("Configure error.\nPlease Check your config file.")
    return


def set_safehost_default_settings():
    # get service host
    r = requests.request("GET", "http://"+args.adminhost+":"+args.adminport+"/services/"+args.service)
    parsed = json.loads(r.text)
    tgt_host = parsed["host"]
    port = parsed["port"]
    if port not in ["80"]:
        tgt_host = tgt_host+":"+str(port)
    
    config = {"host_check": tgt_host} 
    put_config("ssk-safehost", config)

    return


def set_patterns_default_settings(patterns):
    
    confing_patterns = [{"name": name, "patterns": pat} for name, pat in patterns.items()]
    patterkeys = [name for name in patterns.keys()]
    config = {
        "patterns": confing_patterns,
        "params": [
            {"in": "*", "key": "*", "patterns": patterkeys}
        ]
    }
    put_config("ssk-pm", config)
    return




def main():
    
    id_rules = load_rules_conf(args.dir)
    sumpatterns = read_core_rule_set(args.dir, id_rules)
    allpatter = sumpatterns["all"]
    out_plugins_format(sumpatterns, args.out, args.yml)

    set_safehost_default_settings()
    set_patterns_default_settings(sumpatterns)



#


if __name__ == "__main__":
    main()

