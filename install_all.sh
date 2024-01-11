dir="rocks"
subdirs=$(ls -d "$dir"/* )
PLUGINS_str=$(echo "${subdirs//$dir\//}" | tr '\n' ' ')
PLUGINS_str="${PLUGINS_str//\//}"
PLUGINS_str="${PLUGINS_str/ssk-core/}"
IFS=" " read -r -a PLUGINS < <(echo "$PLUGINS_str")

for PLG in "${PLUGINS[@]}"; do
	sudo luarocks install $dir/$PLG
done