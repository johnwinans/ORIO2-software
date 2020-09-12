#!/bin/bash

cd `dirname $0`
while true
do
	../tank/tank
	sleep 1			# I'd be a fool NOT to do this here.
done
