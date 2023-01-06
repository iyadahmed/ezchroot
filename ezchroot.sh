#!/bin/bash

# First version was based on this tutorial: https://www.howtogeek.com/441534/how-to-use-the-chroot-command-on-linux/

# Helper functions
is_dynamically_linked() {
	binary_filepath=$1
	[[ $(file $binary_filepath) == *"dynamically linked"* ]]
}

# Copies the dependencies (listed by "ldd") of a binary to an assumed chroot rootfs
# (a directory containing /lib, etc...)
copy_deps() {
	binary_filepath=$1
	dst=$2
	# Note: there's a space at the end of the regex expression
	#	to avoid including the hex addresses that follow the filepaths in ldd's output
	deps="$(ldd $binary_filepath | egrep -o '/lib.*so.* ')"
	for d in $deps; do
		cp -v --parents "$d" $dst;
	done
}

# Copies a set of binaries from a directory and their dependencies to an assumed chroot rootfs
copy_deps_of_binaries_from_dir_rec() {
	src_dir=$1
	dst=$2
	# Using variables in regex pattern: https://stackoverflow.com/a/18148101/8094047
	# Using du to list files recursively: https://linuxhandbook.com/list-files-recursively/
	for bin_filepath in $(du -a $src_dir | egrep -o "${src_dir}.*"); do
		# Only include dynamically linked binaries, otherwise ldd fails
		if is_dynamically_linked $bin_filepath; then
			copy_deps $bin_filepath $dst
		fi
	done
}

# Get arguments
chr=$1

# Halt on first error
set -e

# Create directories
mkdir $chr
mkdir $chr/{root,bin,lib,lib64,dev,usr,etc}
#mkdir $chr/usr/share
mkdir $chr/usr/lib
#mkdir -p $chr/etc/ssl

# Create devices
#sudo mknod $chr/dev/null c 1 3
#sudo chmod 666 $chr/dev/null

# Create DNS config
#echo 'nameserver 1.1.1.1' > $chr/etc/resolv.conf

# Copy certificates
#cp -r /etc/ssl/certs $chr/etc/ssl

# Cd into the chroot's rootfs
cd $chr

# Copy gcc resources and libs
# Note: GCC worked but it needs to be supplied "-B /usr/lib/gcc/x86.../11"
#	under chroot to work
#	also it needs files from /usr/lib
#	we can just copy the entire thing
#	but that defies the entire concept of a "minimal" chroot
#	the solution should be to compile and install your application to the chroot
#	via "--prefix" or "-DCAMKE_INSTALL_PREFIX" or similar

#cp -r /usr/share/gcc $chr/usr/share
#cp -r /usr/lib/gcc $chr/usr/lib
#copy_deps_of_binaries_from_dir_rec /usr/lib/gcc .

# Copy git resources, related binaries and their dependencies
#cp -r /usr/share/git-core $chr/usr/share
#cp -r /usr/lib/git-core $chr/usr/lib
#copy_deps_of_binaries_from_dir_rec /usr/lib/git-core .

# Copy main binaries and their dependencies
bins="bash touch ls rm mkdir"
for b in $bins; do
	cp -v /bin/$b ./bin
	copy_deps /bin/$b .
done

sudo chroot . /bin/bash
