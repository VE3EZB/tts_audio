#!/bin/bash
#
# tts-audio.sh - allstar Text to Speech
#
#  by w0anm
#
#  This scripts converts a text  file  to a  u-law audio file (ul).
#

# Now uses HTTP post method. Complete file is sent in
# one pass.
 
# To use this script you must register with voicerss
# and receive a key. See the TTS howto at hamvoip.org
# for details.

# File has one required parameter - the text file
# name to process. Example -
#
# tts_audio somefile.txt


#######################
# $Id: tts_audio.sh 6 2016-03-07 15:29:59Z w0anm $

# ---------------
# Copyright (C) 2015, 2016 Christopher Kovacs, W0ANM
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program. If not, see http://www.gnu.org/licenses/.
# ---------------
#


# check for configuration file (/usr/local/etc/tts.conf) and source it. 
# if not preset or unable to get key error out.

if [ -f /usr/local/etc/tts.conf ] ; then
    source /usr/local/etc/tts.conf
else
    echo "Error! Missing TTS Configuration file (/usr/local/etc/tts.conf)"  
    echo "Aborting..." 
    exit 1
fi

if [ -z "$tts_key" ] ; then
    echo "TTS key is not configured."  
    echo "This key must be added to /usr/local/etc/tts.conf file"
    echo "for more information on access to this servce" 
    echo "see the TTS howto at hamvoip.org"
    echo
    exit 1
fi


# variables
TMPDIR=/tmp/tts
PID=$$

## Functions Start

help() {
    echo 
    echo "tts_audio <filename>"
    echo 
    echo "For example:"
    echo "    tts_audio.sh /tmp/hello.txt"
    echo
    echo "This will convert the text to an audio file called /tmp/hello.ul"
    echo "Which can be played using Allstar localplay or playback commands"
    echo
}

cleanup () {
    # clean up the mp3, temp, and wave files
    rm -f ${TMPDIR}/tts*.mp3
    rm -f ${TMPDIR}/audio*.*
}

main() {

    inputline=`cat $FILE`
    # echo $inputline

    # tts_ values are config in the tts.conf file
    curl -s --data "key=${tts_key}&r=${tts_r}&src=${inputline}&hl=${tts_hl}&f=${tts_f}" http://api.voicerss.org/  > ${TMPDIR}/tts.mp3

    if [ ! -f ${TMPDIR}/tts.mp3 ] ; then
         echo "ERROR, access issues with api.voicerss.org; check internet access and retry." 2>&1
         cleanup
         exit 1
 
    fi

    # now convert the file to a ulaw
    lame --decode ${TMPDIR}/tts.mp3 ${TMPDIR}/audio.wav &> /dev/null 2>&1
    if [ ! -f ${TMPDIR}/audio.wav ] ; then
        echo "Failed to convert mp3 file to wav audio file (lame decode failure)" 2>&1
        echo "Aborting..." 2>&1
        cleanup
        exit 1
    fi

    sox -V ${TMPDIR}/audio.wav -r 8000 -c 1 -t ul ${TMPDIR}/audio${PID}.ul &> /dev/null 2>&1
    if [ ! -f ${TMPDIR}/audio${PID}.ul ] ; then
        echo "Failed to convert wav file to u-law audio file (sox failure)" 2>&1
        echo "Aborting..." 2>&1
        cleanup
        exit 
    fi

    mv ${TMPDIR}/audio${PID}.ul ${FILE%.txt}.ul
    cleanup
}

# end of functions...

#####################################################################
# main 

if [ ! -d $TMPDIR ] ; then
    mkdir -p $TMPDIR
fi

if [ -z $1 ] ; then
    echo -e "\nNo file argument supplied" 2>&1
    help
    exit 1
else
    FILE=$1
fi

if [ ! -f "$FILE" ] ; then
    echo 
    echo "Error, unable to find file: $FILE" 2>&1
    echo
    exit 1
fi

# call main function.
main

exit 0

