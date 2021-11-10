#!/bin/bash

red='\033[0;31m'
green='\033[0;32m'
yellow='\033[0;33m'
plain='\033[0m'

# check root
[[ $EUID -ne 0 ]] && echo -e "${red}mistake: ${plain} You must use the root user to run this script! \n" && exit 1

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
        echo -e "${red}Please use CentOS 7 or higher version system!${plain}\n" && exit 1
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

confirm() {
    if [[ $# > 1 ]]; then
        echo && read -p "$1 [default$2]: " temp
        if [[ x"${temp}" == x"" ]]; then
            temp=$2
        fi
    else
        read -p "$1 [y/n]: " temp
    fi
    if [[ x"${temp}" == x"y" || x"${temp}" == x"Y" ]]; then
        return 0
    else
        return 1
    fi
}

confirm_restart() {
    confirm "Whether to restart the panel, restarting the panel will also restart xray" "y"
    if [[ $? == 0 ]]; then
        restart
    else
        show_menu
    fi
}

before_show_menu() {
    echo && echo -n -e "${yellow}Press Enter to return to the main menu: ${plain}" && read temp
    show_menu
}

install() {
    bash <(curl -Ls https://raw.githubusercontent.com/sbatrow/DarkV2ray-Manager-Bot/master/install.sh)
    if [[ $? == 0 ]]; then
        if [[ $# == 0 ]]; then
            start
        else
            start 0
        fi
    fi
}

update() {
    confirm "This function will forcibly reinstall the current latest version, and the data will not be lost. Do you want to continue?" "n"
    if [[ $? != 0 ]]; then
        echo -e "${red}已取消${plain}"
        if [[ $# == 0 ]]; then
            before_show_menu
        fi
        return 0
    fi
    bash <(curl -Ls https://raw.githubusercontent.com/sbatrow/DarkV2ray-Manager-Bot/master/install.sh)
    if [[ $? == 0 ]]; then
        echo -e "${green}The update is complete and the panel has been automatically restarted${plain}"
        exit 0
    fi
}

uninstall() {
    confirm "Are you sure you want to uninstall the panel, xray will also uninstall?" "n"
    if [[ $? != 0 ]]; then
        if [[ $# == 0 ]]; then
            show_menu
        fi
        return 0
    fi
    systemctl stop dark-v2ray
    systemctl disable dark-v2ray
    rm /etc/systemd/system/dark-v2ray.service -f
    systemctl daemon-reload
    systemctl reset-failed
    rm /etc/dark-v2ray/ -rf
    rm /usr/local/dark-v2ray/ -rf

    echo ""
    echo -e "The uninstallation is successful. If you want to delete this script, exit the script and run ${green}rm /usr/bin/dark-v2ray -f${plain} Delete"
    echo ""

    if [[ $# == 0 ]]; then
        before_show_menu
    fi
}

reset_user() {
    confirm "Are you sure you want to reset the username and password to admin" "n"
    if [[ $? != 0 ]]; then
        if [[ $# == 0 ]]; then
            show_menu
        fi
        return 0
    fi
    /usr/local/dark-v2ray/dark-v2ray setting -username admin -password admin
    echo -e "Username and password have been reset to ${green}admin${plain}，Please restart the panel now"
    confirm_restart
}

reset_config() {
    confirm "Are you sure you want to reset all panel settings? Account data will not be lost, username and password will not be changed" "n"
    if [[ $? != 0 ]]; then
        if [[ $# == 0 ]]; then
            show_menu
        fi
        return 0
    fi
    /usr/local/dark-v2ray/dark-v2ray setting -reset
    echo -e "All panel settings have been reset to default values, now please restart the panel and use the default ${green}54321${plain} Port access panel"
    confirm_restart
}

set_port() {
    echo && echo -n -e "Enter port number[1-65535]: " && read port
    if [[ -z "${port}" ]]; then
        echo -e "${yellow}Cancelled${plain}"
        before_show_menu
    else
        /usr/local/dark-v2ray/dark-v2ray setting -port ${port}
        echo -e "After setting the port, please restart the panel and use the newly set port ${green}${port}${plain} Access panel"
        confirm_restart
    fi
}

start() {
    check_status
    if [[ $? == 0 ]]; then
        echo ""
        echo -e "${green}The panel is already running, no need to start again, if you need to restart, please select restart${plain}"
    else
        systemctl start dark-v2ray
        sleep 2
        check_status
        if [[ $? == 0 ]]; then
            echo -e "${green}dark-v2ray started successfully${plain}"
        else
            echo -e "${red}The panel failed to start. It may be because the start-up time exceeds two seconds. Please check the log information later.${plain}"
        fi
    fi

    if [[ $# == 0 ]]; then
        before_show_menu
    fi
}

stop() {
    check_status
    if [[ $? == 1 ]]; then
        echo ""
        echo -e "${green}The panel has stopped, no need to stop again${plain}"
    else
        systemctl stop dark-v2ray
        sleep 2
        check_status
        if [[ $? == 1 ]]; then
            echo -e "${green}dark-v2ray and xray stopped successfully${plain}"
        else
            echo -e "${red}The panel failed to stop. It may be because the stop time exceeds two seconds. Please check the log information later.${plain}"
        fi
    fi

    if [[ $# == 0 ]]; then
        before_show_menu
    fi
}

restart() {
    systemctl restart dark-v2ray
    sleep 2
    check_status
    if [[ $? == 0 ]]; then
        echo -e "${green}dark-v2ray and xray restart successfully${plain}"
    else
        echo -e "${red}Panel restart failed, it may be because the startup time exceeds two seconds, please check the log information later${plain}"
    fi
    if [[ $# == 0 ]]; then
        before_show_menu
    fi
}

status() {
    systemctl status dark-v2ray -l
    if [[ $# == 0 ]]; then
        before_show_menu
    fi
}

enable() {
    systemctl enable dark-v2ray
    if [[ $? == 0 ]]; then
        echo -e "${green}dark-v2ray is set to start successfully after booting${plain}"
    else
        echo -e "${red}dark-v2ray settings fail to start automatically after booting${plain}"
    fi

    if [[ $# == 0 ]]; then
        before_show_menu
    fi
}

disable() {
    systemctl disable dark-v2ray
    if [[ $? == 0 ]]; then
        echo -e "${green}dark-v2ray cancels the boot and self-start successfully${plain}"
    else
        echo -e "${red}dark-v2ray cancels the boot-up auto-start failure${plain}"
    fi

    if [[ $# == 0 ]]; then
        before_show_menu
    fi
}

show_log() {
    journalctl -u dark-v2ray.service -e --no-pager -f
    if [[ $# == 0 ]]; then
        before_show_menu
    fi
}

migrate_v2_ui() {
    /usr/local/dark-v2ray/dark-v2ray v2-ui

    before_show_menu
}

install_bbr() {
    # temporary workaround for installing bbr
    bash <(curl -L -s https://raw.githubusercontent.com/teddysun/across/master/bbr.sh)
    echo ""
    before_show_menu
}

update_shell() {
    wget -O /usr/bin/dark-v2ray -N --no-check-certificate https://github.com/sbatrow/DarkV2ray-Manager-Bot/raw/master/dark-v2ray.sh
    if [[ $? != 0 ]]; then
        echo ""
        echo -e "${red}Failed to download the script, please check whether the machine can connect to Github${plain}"
        before_show_menu
    else
        chmod +x /usr/bin/dark-v2ray
        echo -e "${green}The upgrade script is successful, please re-run the script${plain}" && exit 0
    fi
}

# 0: running, 1: not running, 2: not installed
check_status() {
    if [[ ! -f /etc/systemd/system/dark-v2ray.service ]]; then
        return 2
    fi
    temp=$(systemctl status dark-v2ray | grep Active | awk '{print $3}' | cut -d "(" -f2 | cut -d ")" -f1)
    if [[ x"${temp}" == x"running" ]]; then
        return 0
    else
        return 1
    fi
}

check_enabled() {
    temp=$(systemctl is-enabled dark-v2ray)
    if [[ x"${temp}" == x"enabled" ]]; then
        return 0
    else
        return 1;
    fi
}

check_uninstall() {
    check_status
    if [[ $? != 2 ]]; then
        echo ""
        echo -e "${red}The panel has been installed, please do not install repeatedly${plain}"
        if [[ $# == 0 ]]; then
            before_show_menu
        fi
        return 1
    else
        return 0
    fi
}

check_install() {
    check_status
    if [[ $? == 2 ]]; then
        echo ""
        echo -e "${red}Please install the panel first${plain}"
        if [[ $# == 0 ]]; then
            before_show_menu
        fi
        return 1
    else
        return 0
    fi
}

show_status() {
    check_status
    case $? in
        0)
            echo -e "Panel status: ${green}Already running${plain}"
            show_enable_status
            ;;
        1)
            echo -e "Panel status: ${yellow}Not running${plain}"
            show_enable_status
            ;;
        2)
            echo -e "Panel status: ${red}Not Installed${plain}"
    esac
    show_xray_status
}

show_enable_status() {
    check_enabled
    if [[ $? == 0 ]]; then
        echo -e "Whether to start automatically after booting: ${green}Yes${plain}"
    else
        echo -e "Whether to start automatically after booting: ${red}no${plain}"
    fi
}

check_xray_status() {
    count=$(ps -ef | grep "xray-linux" | grep -v "grep" | wc -l)
    if [[ count -ne 0 ]]; then
        return 0
    else
        return 1
    fi
}

show_xray_status() {
    check_xray_status
    if [[ $? == 0 ]]; then
        echo -e "xray state: ${green}run${plain}"
    else
        echo -e "xray state: ${red}Not running${plain}"
    fi
}

show_usage() {
    clear
    echo "Dark-V2ray-Manager management script usage method: "
    echo "------------------------------------------"
    echo "Dark-V2ray-Manager start        - Launch Dark-V2ray-Manager bot"
    echo "Dark-V2ray-Manager stop         - Stop Dark-V2ray-Manager bot"
    echo "Dark-V2ray-Manager restart      - Restart the Dark-V2ray-Manager bot"
    echo "Dark-V2ray-Manager update       - Update Dark-V2ray-Manager bot"
    echo "Dark-V2ray-Manager install      - Install the Dark-V2ray-Manager bot"
    echo "Dark-V2ray-Manager uninstall    - Uninstall the Dark-V2ray-Manager bot"
    echo "------------------------------------------"
}

show_menu() {
    clear
    echo -e "\033[0;34m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"
    echo -e "\E[44;1;37m               ♻️ DARKV2RAY MANAGER ♻️              \E[0m"
    echo -e "\033[0;34m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"
    echo -e "\033[0;34m  #BY:      🔥⚡️⚡️ Sithum Batrow 🇱🇰 ⚡️⚡️🔥       \033[0m"
    echo -e "\033[0;34m                     SRI LANKA                    \033[0m"
    echo -e "\033[0;34m                Telegram- @sibatrow               \033[0m"
    echo -e "\033[0;34m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"
    show_status
    echo -e "
  [\033[1;36m1\033[1;31m] \033[1;37m• \033[1;33mINSTALL BOT \033[1;31m           [\033[1;36m5\033[1;31m] \033[1;37m• \033[1;33mSTART BOT \033[1;31m
  [\033[1;36m2\033[1;31m] \033[1;37m• \033[1;33mUPDATE DARK-V2RAY \033[1;31m     [\033[1;36m6\033[1;31m] \033[1;37m• \033[1;33mSTOP BOT \033[1;31m
  [\033[1;36m3\033[1;31m] \033[1;37m• \033[1;33mRESTART \033[1;31m               [\033[1;36m0\033[1;31m] \033[1;37m• \033[1;33mEXIT SCRIPT \033[1;31m
  [\033[1;36m4\033[1;31m] \033[1;37m• \033[1;33mUNINSTALL \033[1;31m"
 
    echo && read -p "WHAT DO YOU WANT TO DO [0-6]:" num


    case "${num}" in
        0) exit 0
        ;;
        1) check_uninstall && install
        ;;
        2) check_install && update
        ;;
        3) check_install && restart
        ;;
	4) check_install && uninstall
        ;;
        5) check_install && start
	;;
        6) check_install && stop
        ;;
        *) echo -e "${red}Please enter the correct number [0-14]${plain}"
        ;;
    esac
}


if [[ $# > 0 ]]; then
    case $1 in
        "start") check_install 0 && start 0
        ;;
        "stop") check_install 0 && stop 0
        ;;
        "restart") check_install 0 && restart 0
        ;;
        "update") check_install 0 && update 0
        ;;
        "install") check_uninstall 0 && install 0
        ;;
        "uninstall") check_install 0 && uninstall 0
        ;;
        *) show_usage
    esac
else
    show_menu
fi
