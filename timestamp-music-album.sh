#!/bin/bash
if ! source "lib-bash-leo.sh" ; then
	echo 'lib-bash-leo.sh is missing in PATH!'
	exit 1
fi

# We use globs to search for various audio file types, not all might exist so we need failing globs to work.
shopt -u failglob
shopt -s globstar

make_stat_timestamp_comparable() {
	if [ "$#" -ne 1 ] ; then
		die "Invalid parameter count: $#"
	fi

	if [ "$(date --date="$1" '+%F %T.%N %z')" != "$1" ] ; then
		die "The date command is unable to parse timestamps of the stat command!"
	fi

	date --date="$1" '+%s%N'
}

set_file_atime_from_stat() {
	if [ "$#" -ne 2 ] ; then
		die "Invalid parameter count: $#"
	fi

	local file="$1"
	local timestamp="$2"
	
	touch --time=a --date="$timestamp" "$file"

	local actual_timestamp
	actual_timestamp="$(stat --format='%x' "$file")"

	if [ "$actual_timestamp" != "$timestamp" ] ; then
		die "touch did not work!"
	fi
}

get_oldest_timestamp_of_file() {
	local timestamps
	timestamps=( 	"$(stat --format='%w' "$1")"
					"$(stat --format='%x' "$1")"
					"$(stat --format='%y' "$1")"
					"$(stat --format='%z' "$1")" )

	local oldest=0

	# The birth-time is not yet implemented for some filesystems
	if [ "${timestamps[0]}" = '-' ] ; then
		timestamps=( "${timestamps[@]:1}" )
	fi

	for ((i=0; i < ${#timestamps[@]}; ++i)) ; do
		timestamp="${timestamps[$i]}"
		timestamp_oldest="${timestamps[$oldest]}"

		timestamp="$(make_stat_timestamp_comparable "$timestamp")"
		timestamp_oldest="$(make_stat_timestamp_comparable "$timestamp_oldest")"

		if [ "$timestamp" -lt "$timestamp_oldest" ] ; then
			oldest="$i"
		fi
	done

	stdout "${timestamps[$oldest]}"
}

get_oldest_audio_file_timestamp() {
	local files
	files=( "$1"/**/*.[fF][lL][aA][cC] )
	files+=( "$1"/**/*.[mM][pP]3 )
	files+=( "$1"/**/*.[mM]4[aA] )
	files+=( "$1"/**/*.[aA][pP][eE] )

	if (( ${#files[@]} == 0 )) ; then
		die "No audio files found in: $1"
	fi

	local oldest=0

	for ((i=0; i < ${#files[@]}; ++i)) ; do
		timestamp="$(get_oldest_timestamp_of_file "${files[$i]}")"
		timestamp_oldest="$(get_oldest_timestamp_of_file "${files[$oldest]}")"

		timestamp="$(make_stat_timestamp_comparable "$timestamp")"
		timestamp_oldest="$(make_stat_timestamp_comparable "$timestamp_oldest")"

		if [ "$timestamp" -lt "$timestamp_oldest" ] ; then
			oldest="$i"
		fi
	done

	get_oldest_timestamp_of_file "${files[$oldest]}"
}

main() {
	if [ "$#" -lt 1 ] ; then
		die "Syntax: $0 PATH_OF_ALBUM* "
	fi

	local timestamp_file_header='These audio files were created on: '

	for album; do
		album="$(remove_trailing_slash_on_path "$album")"
		local timestamp_file="$album/Timestamp.txt"
		local timestamp

		if ! [ -e "$timestamp_file" ] ; then
			stdout "No Timestamp.txt found, storing it: $album"

			timestamp="$(get_oldest_audio_file_timestamp "$album")"
			stdout "$timestamp_file_header$timestamp" > "$timestamp_file"
		else
			timestamp="$(<"$timestamp_file")"
			if [[ "$timestamp" != "$timestamp_file_header"* ]] ; then
				die "$timestamp_file is in invalid format!"
			fi
			timestamp="${timestamp#$timestamp_file_header}"
		fi

		stdout "Setting atime to Timestamp.txt value for: $album"
		set_file_atime_from_stat "$album" "$timestamp"
	done
}

main "$@"
