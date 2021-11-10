#!/bin/bash
clear

fun_bar () {
comando[0]="$1"
comando[1]="$2"
 (
[[ -e $HOME/fim ]] && rm $HOME/fim
${comando[0]} -y > /dev/null 2>&1
${comando[1]} -y > /dev/null 2>&1
touch $HOME/fim
 ) > /dev/null 2>&1 &
 tput civis
echo -ne "  \033[1;33mHOLD \033[1;37m- \033[1;33m["
while true; do
   for((i=0; i<18; i++)); do
   echo -ne "\033[1;31m#"
   sleep 0.1s
   done
   [[ -e $HOME/fim ]] && rm $HOME/fim && break
   echo -e "\033[1;33m]"
   sleep 1s
   tput cuu1
   tput dl1
   echo -ne "  \033[1;33mHOLD \033[1;37m- \033[1;33m["
done
echo -e "\033[1;33m]\033[1;37m -\033[1;32m OK !\033[1;37m"
tput cnorm
}
                   
echo -e "\033[1;31m════════════════════════════════════════════════════\033[0m"
tput setaf 7 ; tput setab 4 ; tput bold ; printf '%40s%s%-12s\n' "Welcome to DARKS Manager" ; tput sgr0
echo -e "\033[1;31m════════════════════════════════════════════════════\033[0m"
echo ""
echo -e "             \033[1;31mATTENTION! \033[1;33mTHIS SCRIPT WILL!\033[0m"
echo ""
echo -e "\033[1;32m• \033[1;32mTIP! \033[1;33mULTILIZE THE DARK THEME IN YOUR TERMINAL TO\033[0m"
echo -e "\033[1;33m  A BETTER EXPERIENCE AND VISUALIZATION OF THE SAME!\033[0m"
echo ""
echo -e "\033[1;33m • \033[1;32m By=  🔥⚡️⚡️ Sithum Batrow 🇱🇰 ⚡️⚡️🔥 \033[1;33m • \033[1;31m"
echo ""

red='\033[0;31m'
green='\033[0;32m'
yellow='\033[0;33m'
plain='\033[0m'

cur_dir=$(pwd)

# check root
[[ $EUID -ne 0 ]] && echo -e "${red}Mistake：${plain}!! Must use root user runs this script !！\n" && exit 1

# check os
if [[ -f /etc/redhat-release ]]; then
    release="centos"
elif cat /etc/issue | grep -Eqi "debian"; then
    release="debian"
elif cat /etc/issue | grep -Eqi "ubuntu"; then
    release="ubuntu"
elif cat /etc/issue | grep -Eqi "centos|red hat|redhat"; then
    release="centos"
elif cat /proc/version | grep -Eqi "debian"; then
    release="debian"
elif cat /proc/version | grep -Eqi "ubuntu"; then
    release="ubuntu"
elif cat /proc/version | grep -Eqi "centos|red hat|redhat"; then
    release="centos"
else
    echo -e "${red}The system version is not detected, please contact the script author!${plain}\n" && exit 1
fi

arch=$(arch)

if [[ $arch == "x86_64" || $arch == "x64" || $arch == "amd64" ]]; then
  arch="amd64"
elif [[ $arch == "aarch64" || $arch == "arm64" ]]; then
  arch="arm64"
else
  arch="amd64"
  echo -e "${red}Failed to detect the architecture, use the default architecture: ${arch}${plain}"
fi

echo "Architecture: ${arch}"

if [ $(getconf WORD_BIT) != '32' ] && [ $(getconf LONG_BIT) != '64' ] ; then
    echo "This software does not support 32-bit systems(x86)，Please use a 64-bit system (x86_64), if the detection is wrong, please contact the author"
    exit -1
fi

os_version=""

# os version
if [[ -f /etc/os-release ]]; then
    os_version=$(awk -F'[= ."]' '/VERSION_ID/{print $3}' /etc/os-release)
fi
if [[ -z "$os_version" && -f /etc/lsb-release ]]; then
    os_version=$(awk -F'[= ."]+' '/DISTRIB_RELEASE/{print $2}' /etc/lsb-release)
fi

if [[ x"${release}" == x"centos" ]]; then
    if [[ ${os_version} -le 6 ]]; then
        echo -e "${red}Please use CentOS 7 or higher version system! ${plain}\n" && exit 1
    fi
elif [[ x"${release}" == x"ubuntu" ]]; then
    if [[ ${os_version} -lt 16 ]]; then
        echo -e "${red}Please use Ubuntu 16 or higher version system! ${plain}\n" && exit 1
    fi
elif [[ x"${release}" == x"debian" ]]; then
    if [[ ${os_version} -lt 8 ]]; then
        echo -e "${red}Please use Debian 8 or higher version system! ${plain}\n" && exit 1
    fi
fi

install_base() {
    if [[ x"${release}" == x"centos" ]]; then
        yum install wget curl tar -y > /dev/null 2>&1
    else
        apt install wget curl tar -y > /dev/null 2>&1
    fi
}
fun_bar 'install_base'

install_Dark-V2ay-Manager() {
    systemctl stop dark-v2ray
    cd /usr/local/

    if  [ $# == 0 ] ;then
        last_version=$(curl -Ls "https://api.github.com/repos/sbatrow/DarkV2ray-Manager-Bot/releases/latest" | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')
        if [[ ! -n "$last_version" ]]; then
            echo -e "${red}Failed to detect the dark-v2ray  version, it may be beyond the Github API limit, please try again later, or manually specify the dark-v2ray version to install${plain}"
            exit 1
        fi
        echo -e "The latest version of dark-v2ray detected:${last_version}，start installation"
        wget -N --no-check-certificate -O /usr/local/dark-v2ray-linux-${arch}.tar.gz https://github.com/sbatrow/DarkV2ray-Manager-Bot/releases/download/${last_version}/dark-v2ray-linux-${arch}.tar.gz > /dev/null 2>&1
        if [[ $? -ne 0 ]]; then
            echo -e "${red}Download dark-v2ray failed, please make sure your server can download Github files${plain}"
            exit 1
        fi
    else
        last_version=$1
        url="https://github.com/sbatrow/DarkV2ray-Manager-Bot/releases/download/${last_version}/dark-v2ray-linux-${arch}.tar.gz"
        echo -e "start installation dark-v2ray v$1"
        wget -N --no-check-certificate -O /usr/local/dark-v2ray-linux-${arch}.tar.gz ${url} > /dev/null 2>&1
        if [[ $? -ne 0 ]]; then
            echo -e "${red}Download dark-v2ray v$1 failed, please make sure this version exists${plain}"
            exit 1
        fi
    fi

    if [[ -e /usr/local/dark-v2ray/ ]]; then
        rm /usr/local/dark-v2ray/ -rf
    fi

    after_h() {
    tar zxvf dark-v2ray-linux-${arch}.tar.gz > /dev/null 2>&1
    rm dark-v2ray-linux-${arch}.tar.gz -f > /dev/null 2>&1
    cd dark-v2ray > /dev/null 2>&1
    chmod +x dark-v2ray bin/xray-linux-${arch} > /dev/null 2>&1
    cp -f dark-v2ray.service /etc/systemd/system/ > /dev/null 2>&1
    wget --no-check-certificate -O /usr/bin/dark-v2ray https://raw.githubusercontent.com/sbatrow/DarkV2ray-Manager-Bot/main/dark-v2ray.sh > /dev/null 2>&1
    chmod +x /usr/bin/dark-v2ray > /dev/null 2>&1
    systemctl daemon-reload > /dev/null 2>&1
    systemctl enable dark-v2ray > /dev/null 2>&1
    systemctl start dark-v2ray > /dev/null 2>&1
    
    }
    fun_bar 'after_h'
    
    
clear
    echo -e "\033[1;31m \033[1;33mMAIN COMMAND: \033[1;32mdark-v2ray\033[0m"
    echo 'ZWNobyAgIlwwMzNbMTszM20gTU9SRSBJTkZPUk1BVElPTiAo4LeA4LeQ4Lap4LeSIOC3gOC3kuC3g+C3iuC2reC2uykgXDAzM1sxOzMxbShcMDMzWzE7MzZtVEVMRUdSQU1cMDMzWzE7MzFtKTogXDAzM1sxOzM3bUBzaWJhdHJvdyDwn5Sl4pqh77iP4pqh77iPIFNpdGh1bSBCYXRyb3cg8J+HsfCfh7Ag4pqh77iP4pqh77iP8J+UpVwwMzNbMG0i' | base64 -d | sh
}


echo -e "${green}start installation${plain}"
install_base
install_Dark-V2ay-Manager $1
