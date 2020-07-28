#!/bin/sh

set -e

free_mem() {
    free | awk '/Mem/ {printf "%d GB/%d GB\n", $4/1024/1024, $2/1024/1024.0}'
}

volume() {
    printf "%s(%s)" $(amixer get -D pulse Master | awk -F'[][]' 'END {print $2," ",$4}')
}

record() {
    echo $(slop -f "%x %y %w %h %g %i") | {
        # each piped command run in subshell
        read -r X Y W H G ID
        local file="$HOME/Videos/screenrecord-$(date -I).$(date +%s).mp4"
        echo -n "$file" | xclip -selection clipboard
        notify-send "$file" "Copied Filename.\nWriting to $file ..."
        ffmpeg -f x11grab -s "$W"x"$H" -i :0.0+$X,$Y -f alsa -i pulse "$file"
    }
}
recordStop() {
    local pid=$(ps aux | awk '/[ ]+ffmpeg.*screenrecord-.*.mp4/ { print $2 }')
    if [ -z $pid ] ; then
        echo
    else
        printf "\tStop Recording   \tkill -15 $pid"
    fi
}

screenshot() {
    mkdir -p ~/Pictures
    local file="screenshot-$(date -I)-$(date +%T).png"
    {
        maim -s | tee "$HOME/Pictures/$file" | xclip -selection clipboard -t image/png
    } && notify-send "$file" "Copied to clipboard.\nSaved to $HOME/Pictures"
}

terminal() {
    alacritty
}

browser() {
    firefox
}

filebrowser(){
   "$0" alacritty -e ranger
}

gedit() {
    alacritty -e vim "$0" ||
    scite "$@" ||
    exit 1
}

networkIP() {
    notify-send "Your Public IP" "$(curl ifconfig.me)"
}

showdate() {
    xsetroot -name "$(date +"%Y-%b-%d %k:%M")"
    echo "$(date) 中文效果"
}

if [ ! -z $1 ]
then
    "$@"
    exit 0
fi

# format: Name <Tab> CMD
# format: <Tab> <Submenu> CMD
# name format: IMG:./icons/web.png string
# cmd format: shell command
cat <<EOF | xmenu | sh &
$(showdate)

Applications	rofi -show drun -dpi 192
FileBrowser	"$0" filebrowser

Terminal (st)	st
Terminal (alacritty)	alacritty

Setting
	Edit this Menu   	"$0" gedit "$0"
	Bluetooth	"$0" browser
	Network	"$0" terminal

Volume: $(volume)
	Mute    	amixer -D pulse sset Master 0%
	20%	amixer -D pulse sset Master 20%
	40%	amixer -D pulse sset Master 40%
	60%	amixer -D pulse sset Master 60%
	80%	amixer -D pulse sset Master 80%
	100%	amixer -D pulse sset Master 100%
	More	/usr/bin/pavucontrol
Memory: $(free_mem)
	Relase Memory   	sync; echo 3 > /proc/sys/vm/drop_caches
Network: $(ip -br a | grep wlp5s0 | awk '{print $3,"    "}')
	Gateway: $(ip route | grep default | awk '{print $3,"    "}')
	What is my public IP?	"$0" networkIP
VPN: (off)

Screenshot	"$0" screenshot
ScreenRecord	"$0" record
$(recordStop)

Suspend	systemctl suspend; i3lock
Power Menu
	Shutdown   	poweroff
	Reboot	reboot
	Logout	kill -9 -1
EOF


# vim: set list ts=25 sw=25 noexpandtab :
