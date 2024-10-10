#!/bin/env bash

echo "========================================"
echo "Part I: ALSA"

if [ -e '/proc/asound/version' ]; then
	cat '/proc/asound/version'
	echo
fi

for (( i=0; i<100; i++ )); do
	if [ -d "/proc/asound/card${i}" ]; then
		cname="$( cat "/proc/asound/card${i}/id" )"
		echo "Card ${i} (${cname}):"

		firstDevice='true'
		for t in 'p' 'c'; do
			case "$t" in
				p) typeString='Playback' ;;
				c) typeString='Recording' ;;
			esac

			for (( j=0; j<100; j++ )); do
				if [ -d "/proc/asound/card${i}/pcm${j}${t}" ]; then
					if [ "$firstDevice" = 'true' ]; then
						firstDevice='false'
					else
						echo
					fi

					dname=''
					if [ -e "/proc/asound/card${i}/pcm${j}${t}/info" ]; then
						dname="$( grep -E '^name: ' "/proc/asound/card${i}/pcm${j}${t}/info" 2>/dev/null | cut -d ' ' -f 2- )"
					fi
					if [ -n "$dname" ]; then
						echo "  * ${typeString} Device ${j} (${dname}):"
					else
						echo "  * ${typeString} Device ${j}:"
					fi

					firstSubDevice='true'
					for (( k=0; k<100; k++ )); do
						if [ -e "/proc/asound/card${i}/pcm${j}${t}/sub${k}/hw_params" ]; then
							if [ "$firstSubDevice" = 'true' ]; then
								firstSubDevice='false'
							else
								echo
							fi

							echo "    - Subdevice ${k} (hw:${cname},${j},${k}):"
							ownerPID="$( grep -E '^owner_pid' "/proc/asound/card${i}/pcm${j}${t}/sub${k}/status" 2>/dev/null | tr -cd '0-9' )"
							if [ -n "$ownerPID" ]; then
								tgid="$( grep -F 'Tgid:' "/proc/${ownerPID}/status" 2>/dev/null | tr -cd '0-9' )"
								if [ -n "$tgid" ]; then
									ownerPID="$tgid"
								fi
								ownerName="$( cat "/proc/${ownerPID}/comm" 2>/dev/null )"
								echo "      used by: ${ownerName} (PID ${ownerPID})"
							fi
							while read line; do
								echo "      $line"
							done < "/proc/asound/card${i}/pcm${j}${t}/sub${k}/hw_params"
						fi
					done
				fi
			done
		done
		echo
	fi
done

echo "========================================"
echo "Part II: jack processes"
ps ax | grep jack | grep -v grep

if ps ax | grep jack | grep -v grep | grep -q dbus; then
	echo "========================================"
	echo "Part III: jack-dbus config"
	jack_control status && jack_control dg && jack_control dp && jack_control ep
fi
