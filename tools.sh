#!/bin/bash

build_clang(){
	echo  "Building $1 kernel with clang"

	make O=out ARCH=arm64 $1
	PATH="$(pwd)/clang/bin:${PATH}" \
	make -j$(nproc --all) O=out \
                      	ARCH=arm64 \
			CC=clang \
                      	CLANG_TRIPLE=aarch64-linux-gnu- \
                      	CROSS_COMPILE=$(pwd)/gcc/bin/aarch64-linux-android- \
                      	CROSS_COMPILE_ARM32=$(pwd)/gcc32/bin/arm-linux-androideabi-
}

build_clean(){
	rm -rf $(pwd)/out
}

sendmsg_intro(){
	curl -s -X POST https://api.telegram.org/bot${BOT_TOKEN}/sendMessage \
		-d parse_mode=HTML \
		-d chat_id=${CHANNEL} \
		-d text="<b>🔥 Building Karamel Now ...!</b>
		<b>+ Version:</b> <code>$1</code>
		<b>+ Compiler:</b> <code>$2</code>
		<b>+ Branch:</b> <code>$(git rev-parse --abbrev-ref HEAD)</code>
		<b>+ Commit:</b> <code>$(git log --pretty=format:'%h : %s' -1)</code>"
}

sendmsg_finish(){
	DIFF=$(( $2 - $1 ))
	curl -s -X POST https://api.telegram.org/bot${BOT_TOKEN}/sendMessage \
                -d chat_id=${CHANNEL} \
                -d parse_mode=HTML \
                -d text="💥 Build completed in $((DIFF / 60)) minutes $((DIFF % 60)) seconds"
}

sendmsg_error(){
	curl -s -X POST https://api.telegram.org/bot${BOT_TOKEN}/sendMessage \
		-d text="⛔ Build failed with errors..." \
		-d chat_id=${CHANNEL} \
		-d parse_mode=HTML
	exit 1
}

sendmsg_file(){
	file=$(pwd)/$1
	curl -F chat_id="${CHANNEL}" \
             	-F caption="sha1sum : $(sha1sum ${file} | awk '{ print $1 }')" \
                -F document=@"${file}" \
                 https://api.telegram.org/bot${BOT_TOKEN}/sendDocument
}

zipper(){
	git clone --depth=1 https://github.com/DDEAGLE/AnyKernel3 -b release anykernel

	if [ -f $(pwd)/out/arch/arm64/boot/Image.gz-dtb ]; then
		cp $(pwd)/out/arch/arm64/boot/Image.gz-dtb $(pwd)/anykernel
		cd anykernel
		zip -r ../$2 *
		cd ..
		rm -rf anykernel
	else
		sendmsg_error
	fi
}
