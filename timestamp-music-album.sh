#!/bin/bash
if ! source "lib-bash-leo.sh" ; then
	echo 'lib-bash-leo.sh is missing in PATH!'
	exit 1
fi


main() {
	if [ "$#" -lt 1 ] ; then
		die "Syntax: $0 PATH_OF_ALBUM* "
	fi
	
	for album; do
		album="$(remove_trailing_slash_on_path "$album")"
		local timestamp_file="$album/Timestamp.txt"
		
		if ! [ -e "$timestamp_file" ] ; then
			stdout "No timestamp found, storing it: $album"
			touch -a --reference="$album" "$timestamp_file"
			stat --printf="These audio files were created on: %x" "$album" > "$timestamp_file"
		else
			stdout "Restoring timestamp for: $album"
			touch -a --reference="$timestamp_file" "$album"
		fi
	done
}

main "$@"
