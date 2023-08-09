GIT_DIR=$(cd $(dirname $0); pwd)
# prepare
sudo apt install -y autoconf luajit=2.1.* libluajit-5.1
sudo apt install -y swig
git clone https://github.com/libinjection/libinjection ${GIT_DIR}/libinjection

# version of Mar 30, 2023
cd ${GIT_DIR}/libinjection/
git checkout c1831ca56351c351744acdff6bf3cca250ae1df7

# build
autoconf
./autogen.sh
./configure
make

# build .so for lua
sed -i "s/luajit-2\.0/luajit-2\.1/g" ./lua/Makefile
cp ./src/version.h ./lua/version.h
make -C lua

###  If you failed to make and saw below error message,
### 	/usr/bin/ld: cannot find -lluajit-5.1
###  confirm ldconfig 
### 	ldconfig -p | grep luajit
###  and create symbolic link from luajit-*.so.?.? to luajit-*.so, refer to the following
### 	sudo ln -s  /usr/lib/x86_64-linux-gnu/libluajit-5.1.so.2.1.0  /usr/lib/x86_64-linux-gnu/libluajit-5.1.so

# copy .so 
sudo cp ./lua/libinjection.so /usr/local/kong/lib/
