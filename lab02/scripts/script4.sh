#! /bin/bash

if [ $# -ne 1 ]; then
  echo "Usage: script3.sh parm1 parm2"
  echo "Please enter 1 arguments exactly"
  exit 255
fi

if [ ! -e $1 ]; then
	echo "File named $1 does not exist"
	exit 255
fi

echo "File named $1 exists"

