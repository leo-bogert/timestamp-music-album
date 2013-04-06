timestamp-music-album
=====================

A shell script which will create a file "Timestamp.txt" for each passed folder or restore the atime of the folder to the one stored in an existing "Timestamp.txt". The Timestamp.txt will contain the oldest timestamp of all audio files in that folder among atime, btime, ctime and mtime. Currently it searches for FLAC and MP3.
