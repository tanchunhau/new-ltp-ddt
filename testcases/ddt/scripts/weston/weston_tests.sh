#! /bin/sh

source "common.sh"

############################# Functions #######################################
usage()
{
	cat <<-EOF >&2
	usage: ./${0##*/} -t TEST_TYPE
	-t TEST_TYPE		Test Type. Possible Values are:
	      1 : weston is running
	      2 : weston is using DRM
	      3 : weston can run a simple EGL app
	EOF
	exit 0
}

simple_egl_test()
{
	if which simple-egl-readpixels ; then
		simple-egl-readpixels -n 10
		return $?
	fi

	if which weston-simple-egl ; then
		weston-simple-egl  &
		PID=$!
		sleep 3
		kill $PID
		return $?
	fi
}

################################ CLI Params ####################################
# Please use getopts
while getopts  :t:h arg
do case $arg in
        t)      TYPE="$OPTARG";;
        h)      usage;;
        :)      die "$0: Must supply an argument to -$OPTARG.";;
        \?)     die "Invalid Option -$OPTARG ";;
esac
done

[ -z "$TYPE" ] && die "you must provide a test type"

case "$TYPE" in
	1)
		weston-info
		;;
	2)
		weston-info | grep -w "interface: 'wl_drm', version:"
		;;
	3)
		simple_egl_test
		;;
	*) die "$TYPE is not a valid test type"
esac
