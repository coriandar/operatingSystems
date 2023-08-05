#!/bin/bash

# Lab2: Shell Scripting
# Group55: Tony Yee, Jamie Lee


if [ $# -ne 2 ]; then
	echo "Usage: ./extract.sh <filename> <directory>"
	echo "Error: Please entre 2 arguments exactly."
	exit 255
fi

# Variables to store arguements
file=$1
dir=$2

if [ ! -f $file ]; then
	echo "Error: File <$file> does not exist."
	exit 255

elif [ -f $file ]; then
	if [ ! -d $dir ]; then
		mkdir -p $dir
		echo "Directory <$dir> was created."
	fi
	grep -i "special" $file | cat >> "$dir/special.txt"
fi

exit 0



# a) Display an appropriate error message and terminate if the number of arguments is not exactly 2.

# b) If the file (specified in argument 1) does not exist, then display an appropriate error message and terminate.

# c) Otherwise, saved all the lines in that file that contains the word “special” in a file called special.txt in the directory specified as argument 2. If this directory does not exist in the current directory, then create it

# d) If the file special.txt already exists in the directory specified, then those lines of text extracted from argument 1 should be appended to special.txt.


#Creating a new directory if the directory name specified in argument 2 doesn't exist.
# if file exists, then check if dir exists

#Appending the lines of text extracted from argument 1 to special.txt in specified directory
# only run if the file exists

