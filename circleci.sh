#!/bin/bash

KERNELNAME=DesertEagle
KERNELVERSION=test
DEVICES=whyred,tulip,wayne
TOOLCHAIN=clang

export KBUILD_BUILD_USER=builder
export KBUILD_BUILD_HOST=deagle

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
. $DIR/tools.sh

if [ $TOOLCHAIN == "clang" ]; then
	git clone --depth=1 https://github.com/NusantaraDevs/clang.git -b dev/11.0 clang
	START=$(date +"%s")
	sendmsg_intro $KERNELVERSION $TOOLCHAIN

	for i in ${DEVICES//,/ }
	do
		BUILDDATE=$(date +"%y%m%d-%H%M")
		build_clang "deserteagle_${i}_defconfig"
        	ZIPNAME="${KERNELNAME}-${i}-${KERNELVERSION}-${BUILDDATE}.zip"
        	zipper ${i} $ZIPNAME
		sendmsg_file $ZIPNAME
		build_clean
		#build newcam blob
		build_clang "deserteagle_${i}_newcam_defconfig"
		ZIPNAME="${KERNELNAME}-${i}-newcam-${KERNELVERSION}-${BUILDDATE}.zip"
		zipper ${i} $ZIPNAME
		sendmsg_file $ZIPNAME
		build_clean
	done

	END=$(date +"%s")
	sendmsg_finish $START $END
else
	exit 1
fi
