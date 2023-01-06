#!/bin/bash

# First version was based on this tutorial: https://www.howtogeek.com/441534/how-to-use-the-chroot-command-on-linux/
# deps: sudo apt install git

# Get arguments
chr=$1

# Halt on first error
set -e

# Create directories
mkdir $chr
mkdir $chr/{root,bin,lib,lib64,dev,usr,etc}
mkdir $chr/usr/share
mkdir $chr/usr/lib
mkdir -p $chr/etc/ssl

# Create devices
sudo mknod $chr/dev/null c 1 3
sudo chmod 666 $chr/dev/null

# Create DNS config, bad idea?
echo 'nameserver 1.1.1.1' > $chr/etc/resolv.conf

# Copy certificates, bad idea?
cp -r /etc/ssl/certs $chr/etc/ssl

# Cd into the chroot's directory (to make cp work with relative path)
cd $chr

# Copy git resources, related binaries and their dependencies
cp -r /usr/share/git-core $chr/usr/share
cp -r /usr/lib/git-core $chr/usr/lib

# TODO: this only copies dependencies of top level binaries
#	we should look for binaries recursively
for bin in $(ls /usr/lib/git-core); do
	# Only include dynamically linked binaries, otherwise ldd fails
	if [[ $(file /usr/lib/git-core/$bin) == *"dynamically linked"* ]]; then
		list="$(ldd /usr/lib/git-core/$bin | egrep -o '/lib.*\.[0-9]+')"
		for i in $list; do cp -v --parents "$i" .; done
	fi
done

# Copy main binaries and their dependencies
needed_bins="bash touch ls rm mkdir tee git"
for b in $needed_bins; do
	cp -v /bin/$b ./bin
	list="$(ldd /bin/$b | egrep -o '/lib.*\.[0-9]+')"
	for i in $list; do cp -v --parents "$i" .; done
done

sudo chroot . /bin/bash
