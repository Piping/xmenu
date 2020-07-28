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
        ffmpeg -f x11grab -s "$W"x"$H" -i :0.0+$X,$Y -f alsa -i pulse ~/Videos/video-$(date -I).$(date +%s).mp4
    }
}

screenshot() {
    mkdir -p ~/Pictures
    local file="screenshot-$(date -I)-$(date +%T).png"
    maim -s | tee "$HOME/Pictures/$file" | xclip -selection clipboard -t image/png
    notify-send "$file" "Copied to clipboard.\nSaved to $HOME/Pictures"
}

terminal() {
    alacritty
}

browser() {
    firefox
}

gedit() {
    st -e vim "$0" ||
    scite "$@" ||
    exit 1
}

if [ ! -z $1 ]
then
    "$@"
    exit 0
fi

# IMG:./icons/web.png
cat <<EOF | xmenu | sh &
$(date)

Applications	rofi -show drun -dpi 192

Terminal (st)	st
Terminal (alacritty)	alacritty

Setting
	Edit this Menu	"$0" gedit "$0"
	Bluetooth	"$0" browser
	Network	"$0" terminal

Volume: $(volume)
	Mute    	amixer -D pulse sset Master 0%
	20%     	amixer -D pulse sset Master 20%
	40%     	amixer -D pulse sset Master 40%
	60%     	amixer -D pulse sset Master 60%
	80%     	amixer -D pulse sset Master 80%
	100%    	amixer -D pulse sset Master 100%
	More    	/usr/bin/pavucontrol
Memory: $(free_mem)
	Relase Memory   	sync; echo 3 > /proc/sys/vm/drop_caches
Network: $(ip -br a | grep wlp5s0 | awk '{print $3,"    "}')
	Gateway: $(ip route | grep default | awk '{print $3,"    "}')

Screenshot	"$0" screenshot
RecordSelection	"$0" record

Shutdown	poweroff
Reboot	reboot
Suspend	systemctl suspend; i3lock
Logout	kill -9 -1
EOF

# vim: set list ts=25 sw=25 noexpandtab :
