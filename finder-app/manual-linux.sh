#!/bin/bash
# Script outline to install and build kernel.
# Author: Siddhant Jajoo.

set -e
set -u

OUTDIR=/tmp/aeld
KERNEL_REPO=git://git.kernel.org/pub/scm/linux/kernel/git/stable/linux-stable.git
KERNEL_VERSION=v5.15.163
BUSYBOX_VERSION=1_33_1
FINDER_APP_DIR=$(realpath $(dirname $0))
ARCH=arm64
CROSS_COMPILE=aarch64-none-linux-gnu-

if [ $# -lt 1 ]
then
	echo "Using default directory ${OUTDIR} for output"
else
	OUTDIR=$1
	echo "Using passed directory ${OUTDIR} for output"
fi

mkdir -p ${OUTDIR}

cd "$OUTDIR"
if [ ! -d "${OUTDIR}/linux-stable" ]; then
    #Clone only if the repository does not exist.
	echo "CLONING GIT LINUX STABLE VERSION ${KERNEL_VERSION} IN ${OUTDIR}"
	git clone ${KERNEL_REPO} --depth 1 --single-branch --branch ${KERNEL_VERSION}
fi
if [ ! -e ${OUTDIR}/linux-stable/arch/${ARCH}/boot/Image ]; then
    cd linux-stable
    echo "Checking out version ${KERNEL_VERSION}"
    git checkout ${KERNEL_VERSION}

	# Fix for:
	# scripts/dtc/dtc-parser.tab.o:(.bss+0x20): multiple definition of `yylloc';
	# scripts/dtc/dtc-lexer.lex.o:(.bss+0x0): first defined here
	sed -i 's/YYLTYPE yylloc;/extern YYLTYPE yylloc;/g' scripts/dtc/dtc-lexer.l

    # TODO: Add your kernel build steps here
	# clean
	echo "Cleaning kernel build mrproper"
	make ARCH=arm64 CROSS_COMPILE=${CROSS_COMPILE} mrproper
	# defconfig "virt" is default no arg
	echo "Setting up default config for target virt(default)"
	make ARCH=arm64 CROSS_COMPILE=${CROSS_COMPILE} defconfig
	# build the kernel 
	echo "Building kernel..."
	make -j4 ARCH=arm64 CROSS_COMPILE=${CROSS_COMPILE} all
	# Build kernel mods
	echo "Building kernel modules..."
	make ARCH=arm64 CROSS_COMPILE=${CROSS_COMPILE} modules
	# Build device tree
	echo "Bulding device tree..."
	make ARCH=arm64 CROSS_COMPILE=${CROSS_COMPILE} dtbs
fi

echo "Adding the Image in outdir"
cd $OUTDIR
cp -a linux-stable/arch/arm64/boot/Image ./

echo "Creating the staging directory for the root filesystem"
if [ -d "${OUTDIR}/rootfs" ]
then
	echo "Deleting rootfs directory at ${OUTDIR}/rootfs and starting over"
    sudo rm  -rf ${OUTDIR}/rootfs
fi

# TODO: Create necessary base directories
#######################################################################
ROOTFS_DIR=${OUTDIR}/rootfs

# Create the empty rootfs staging
mkdir ${ROOTFS_DIR}

# Create the Filesystem Hierarchy Standard (HFS) dirs
cd rootfs
mkdir bin dev etc home lib lib64 proc sbin sys tmp usr var
mkdir usr/bin usr/lib usr/sbin
mkdir -p /var/log

#######################################################################

cd "$OUTDIR"
if [ ! -d "${OUTDIR}/busybox" ]
then
git clone git://busybox.net/busybox.git
    cd busybox
    git checkout ${BUSYBOX_VERSION}
    # TODO:  Configure busybox
	make distclean
	make defconfig
else
    cd busybox
fi


# TODO: Make and install busybox
echo -e "Make and install busybox"
sudo env "PATH=$PATH" make ARCH=arm CROSS_COMPILE=${CROSS_COMPILE} CONFIG_PREFIX=${ROOTFS_DIR} install

echo "Copying busybox library dependencies to rootfs"
cd ${ROOTFS_DIR}

# Cross-compile sysroot dir
CCSYSROOT=$(${CROSS_COMPILE}gcc -print-sysroot)

# Show dependencies
${CROSS_COMPILE}readelf -a bin/busybox | grep "program interpreter"
${CROSS_COMPILE}readelf -a bin/busybox | grep "Shared library"

# Interpreter / LIBS dependecies
REQ_INTRP=$(${CROSS_COMPILE}readelf -a bin/busybox | grep "program interpreter" | awk '{ gsub(/\[|\]/,"",$NF); print $NF}')
REQ_LIBS=$(${CROSS_COMPILE}readelf -a bin/busybox | grep "Shared library" | awk '{ gsub(/\[|\]/,"",$NF); print $NF}')

# TODO: Add library dependencies to rootfs
for intrp in $REQ_INTRP
do
    echo "intrp: $intrp"
	intrp=$(basename ${intrp})
	LIB_SRC=$(find ${CCSYSROOT} -name $intrp)
	LIB_TGT=$(realpath --no-symlinks --relative-to=$CCSYSROOT $LIB_SRC)
	
	echo "Copy $LIB_SRC to $LIB_TGT"
	cp -a $LIB_SRC $LIB_TGT
	
    if [ -L $LIB_TGT ]; then
		LNK_SRC=$(readlink -f $LIB_SRC)
	    LNK_TGT=$(realpath --relative-to=$CCSYSROOT $LIB_SRC)
		echo "Copy link: $LNK_SRC to $LNK_TGT"
		cp -a $LNK_SRC $LNK_TGT
    fi
done


for lib in $REQ_LIBS
do
    lib=$(basename ${lib})
	LIB_SRC=$(find ${CCSYSROOT} -name $lib)
	LIB_TGT=$(realpath --no-symlinks --relative-to=$CCSYSROOT $LIB_SRC)
	echo "Copy $LIB_SRC to $LIB_TGT"
	cp -a $LIB_SRC $LIB_TGT

	LNKTGT=$(realpath --relative-to=$CCSYSROOT $LIB_SRC)
	
    # If src is link, copy link target locally
    if [ -L $LIB_TGT ]; then
		LNK_SRC=$(readlink -f $LIB_SRC)
	    LNK_TGT=$(realpath --relative-to=$CCSYSROOT $LIB_SRC)
		echo "Copy link: $LNK_SRC to $LNK_TGT"
		cp -a $LNK_SRC $LNK_TGT
    fi
done
cd ${ROOTFS_DIR}

# TODO: Make device nodes
echo -e "Creating device nodes"
sudo mknod -m 666 dev/null c 1 3
sudo mknod -m 666 dev/char0 c 5 2

# TODO: Clean and build the writer utility
echo -e "Cleaning and building writer utility"
cd ${FINDER_APP_DIR}
make CROSS_COMPILE=${CROSS_COMPILE} clean
make CROSS_COMPILE=${CROSS_COMPILE}

# TODO: Copy the finder related scripts and executables to the /home directory
# on the target rootfs
# Copy your finder.sh, conf/username.txt and (modified as described in step 1 above)
# finder-test.sh scripts from Assignment 2 into the outdir/rootfs/home directory 
cp -a $FINDER_APP_DIR/writer $ROOTFS_DIR/home/
echo -e "Copy finder app dir to rootfs/home"
cp -a $FINDER_APP_DIR/finder.sh $ROOTFS_DIR/home/
mkdir $ROOTFS_DIR/home/conf
cp -a $FINDER_APP_DIR/conf/username.txt $ROOTFS_DIR/home/conf/
cp -a $FINDER_APP_DIR/finder-test.sh $ROOTFS_DIR/home/
cp -a $FINDER_APP_DIR/autorun-qemu.sh $ROOTFS_DIR/home/

# TODO: Chown the root directory
echo -e "Chaning owner of rootfs dir to root"
sudo chown -R root:root ${ROOTFS_DIR}

# TODO: Create initramfs.cpio.gz
cd $ROOTFS_DIR
find . | cpio -H newc -ov --owner root:root > ../initramfs.cpio
cd ..
gzip -f initramfs.cpio

