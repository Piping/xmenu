#!/bin/sh

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
	Bluetooth   	firefox
	Network     	firefox

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

Screenshot	maim -s | tee ~/Pictures/screenshot-$(date -I).png
RecordSelection	"$0" record

Shutdown		poweroff
Reboot			reboot
EOF

# vim: set list ts=25 sw=25 noexpandtab :
