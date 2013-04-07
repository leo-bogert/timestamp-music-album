timestamp-music-album
=====================

A shell script which will create a file "Timestamp.txt" for each passed folder if it does not exist there yet.
The Timestamp.txt will contain the oldest timestamp of all audio files in that folder among atime, btime, ctime and mtime. Currently it searches for *.FLAC, *.M4A and *.MP3.
The atime of each passed folder will be set to the value which Timestamp.txt contains.
