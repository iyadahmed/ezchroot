#!/bin/bash

# Based on this tutorial: https://www.baeldung.com/linux/bash-expand-relative-path

chr=$1
mkdir $chr
mkdir -p $chr/{bin,lib,lib64}
cd $chr

needed_bins="bash touch ls rm"

for b in $needed_bins; do
	cp -v /bin/$b ./bin
	list="$(ldd /bin/$b | egrep -o '/lib.*\.[0-9]')"
	for i in $list; do cp -v --parents "$i" .; done
done

sudo chroot . /bin/bash
