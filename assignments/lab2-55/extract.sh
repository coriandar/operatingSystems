#!/bin/bash

# Lab2: Assignment
# Group55: Jamie Lee, Tony Yee


# Checks if arguments is exactly 2
if [ $# -ne 2 ]; then
	echo "Usage: ./extract.sh <filename> <directory>"
	echo "Error: Please entre 2 arguments exactly."
	exit 255
fi

# Variables to store arguements
file=$1
dir=$2

# Checks if file exists
if [ ! -f $file ]; then
	echo "Error: File <$file> does not exist."
	exit 255

elif [ -f $file ]; then
	# Make directory if does not exist.
	if [ ! -d $dir ]; then
		mkdir -p $dir
		echo "Directory <$dir> was created."
	fi
	# Extract all lines with "special", ignore-case.
	# Append to special.txt file, create file if it doesn't exist
	# special.txt located in directory specified arg 2.
	grep -i "special" $file | cat >> "$dir/special.txt"
fi

exit 0
