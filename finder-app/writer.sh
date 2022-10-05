#!/bin/sh

#Accepts the following arguments: the first argument is a full path to a file (including filename) on the filesystem, referred to below as writefile; the second argument is a text string which will be written within this file, referred to below as writestr

writefile=$1
writestr=$2


#Exits with value 1 error and print statements if any of the arguments above were not specified

if [ $# != 2 ]
then
	echo "Needs two params, for example 'writer.sh /tmp/aesd/assignment1 linux'"
	exit 1
fi


#Creates a new file with name and path writefile with content writestr, overwriting any existing file and creating the path if it doesn’t exist. Exits with value 1 and error print statement if the file could not be created.

mkdir -p $(dirname $writefile)

echo $writestr > $writefile

if [ ! -f $writefile ]
then
	echo "File could not be created"
	exit 1
fi
