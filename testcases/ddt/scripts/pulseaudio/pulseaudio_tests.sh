
start_pulse_audio()
{
	LOGFILE=$1
	shift
	pulseaudio $* 2> $LOGFILE &
	echo $! > $LOGFILE.pid
}

kill_pulse_audio()
{
	LOGFILE=$1
	[ -f $LOGFILE.pid ] && kill $(cat $LOGFILE.pid) || killall pulseaudio
}

get_sink_name()
{
	pacmd list-sinks | grep -e 'name:' | cut -d'<' -f2 | tr '>' ' ' | grep $1 
}

get_sound_device()
{
	DEV="sound0"
	case $SOC in
		j7*|am65*)
			DEV="sound_0"
			;;
	esac
	echo $DEV
}


test_no_period_wakeup()
{
	WAVFILE="/usr/share/sounds/alsa/Rear_Right.wav"
	LOGFILE=$(mktemp)
	DEV=${1:-$(get_sound_device)}
	start_pulse_audio $LOGFILE --log-time --log-level=3
	sleep 1
	SINK=$(get_sink_name $DEV)
	truncate -s 0 $LOGFILE
	paplay $WAVFILE --device $SINK
	kill_pulse_audio $LOGFILE 
	grep "ALSA period wakeups disabled" $LOGFILE 
	RET=$?
	rm $LOGFILE $LOGFILE.pid
	return $RET
}
