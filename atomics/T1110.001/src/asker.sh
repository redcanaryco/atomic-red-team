#!/bin/sh
WORD=`tail -1 /tmp/workingfile`
sed -i '$d' /tmp/workingfile
echo $WORD