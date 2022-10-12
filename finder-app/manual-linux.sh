#!/bin/bash
# Script outline to install and build kernel.
# Author: Siddhant Jajoo.

set -e
set -u

OUTDIR=/tmp/aeld
KERNEL_REPO=git://git.kernel.org/pub/scm/linux/kernel/git/stable/linux-stable.git
KERNEL_VERSION=v5.1.10
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

    # TODO: Add your kernel build steps here
    make ARCH=${ARCH} CROSS_COMPILE=${CROSS_COMPILE} mrproper
    make ARCH=${ARCH} CROSS_COMPILE=${CROSS_COMPILE} defconfig
    make -j4 ARCH=${ARCH} CROSS_COMPILE=${CROSS_COMPILE} all
    #make ARCH=${ARCH} CROSS_COMPILE=${CROSS_COMPILE} modules
    make ARCH=${ARCH} CROSS_COMPILE=${CROSS_COMPILE} dtbs
    # DONE
fi

echo "Adding the Image in outdir"
cp -a "${OUTDIR}/linux-stable/arch/${ARCH}/boot/Image" "$OUTDIR"

echo "Creating the staging directory for the root filesystem"
cd "$OUTDIR"
if [ -d "${OUTDIR}/rootfs" ]
then
	echo "Deleting rootfs directory at ${OUTDIR}/rootfs and starting over"
    sudo rm  -rf ${OUTDIR}/rootfs
fi

# TODO: Create necessary base directories
cd "$OUTDIR"
mkdir ${OUTDIR}/rootfs
cd ${OUTDIR}/rootfs
mkdir bin dev etc home lib lib64 proc sbin sys tmp usr va var
mkdir usr/bin usr/lib usr/sbin
mkdir -p var/log
cd ${OUTDIR}/rootfs
sudo chown -R root:root *
# DONE


export PATH=${PATH}:/home/cohi4881/install-lnx/gcc-arm-10.2-2020.11-x86_64-aarch64-none-linux-gnu/bin
cd "$OUTDIR"
if [ ! -d "${OUTDIR}/busybox" ]
then
    git clone git://busybox.net/busybox.git
    cd busybox
    git checkout ${BUSYBOX_VERSION}
    # TODO:  Configure busybox
    echo "CONFIG BUSYBOX"
    #try to make it so that sudo doesn't ignore the path
    sudo env "PATH=$PATH" make ARCH=${ARCH} CROSS_COMPILE=aarch64-none-linux-gnu- distclean
    sudo env "PATH=$PATH" make ARCH=${ARCH} CROSS_COMPILE=aarch64-none-linux-gnu- defconfig
    #DONE
else
    cd busybox
fi

# TODO: Make and install busybox
echo "MAKE BUSYBOX"
#try to make it so that sudo doesn't ignore the path
sudo env "PATH=$PATH" make CONFIG_PREFIX=${OUTDIR}/rootfs ARCH=${ARCH} CROSS_COMPILE=aarch64-none-linux-gnu- install
cd ${OUTDIR}/rootfs
#DONE

echo "Library dependencies"
${CROSS_COMPILE}readelf -a bin/busybox | grep "program interpreter"
${CROSS_COMPILE}readelf -a bin/busybox | grep "Shared library"

# TODO: Add library dependencies to rootfs
SYSROOT=$(${CROSS_COMPILE}gcc -print-sysroot)
echo $SYSROOT
cd ${OUTDIR}/rootfs
sudo chown -R root:root *
sudo cp -a $SYSROOT/lib/ld-linux-aarch64.so.1 lib
sudo cp -a $SYSROOT/lib64/ld-2.31.so lib64
sudo cp -a $SYSROOT/lib64/libc.so.6 lib64
sudo cp -a $SYSROOT/lib64/libc-2.31.so lib64
sudo cp -a $SYSROOT/lib64/libresolv.so.2 lib64
sudo cp -a $SYSROOT/lib64/libresolv-2.31.so lib64
sudo cp -a $SYSROOT/lib64/libm.so.6 lib64
sudo cp -a $SYSROOT/lib64/libm-2.31.so lib64
# DONE

# TODO: Make device nodes
sudo mknod -m 666 dev/null c 1 3
sudo mknod -m 666 dev/console c 5 1
# DONE

# TODO: Adding Modules to the rootfs
#sudo make ARCH=${ARCH} CROSS_COMPILE=${CROSS_COMPILE}  INSTALL_MOD_PATH=${OUTDIR}/rootfs modules_install
# DONE

# TODO: Clean and build the writer utility
cd ${FINDER_APP_DIR}
make clean
make CROSS_COMPILE=${CROSS_COMPILE}
# DONE

# TODO: Copy the finder related scripts and executables to the /home directory
# on the target rootfs
cd ${FINDER_APP_DIR}
sudo cp -a ${FINDER_APP_DIR}/. ${OUTDIR}/rootfs/home/
sudo rm ${OUTDIR}/rootfs/home/conf
sudo mkdir ${OUTDIR}/rootfs/home/conf
sudo cp -a ${FINDER_APP_DIR}/../conf/username.txt ${OUTDIR}/rootfs/home/conf/username.txt
# DONE

# TODO: Chown the root directory
cd ${OUTDIR}/rootfs
sudo chown -R root:root *
# DONE

# TODO: Create initramfs.cpio.gz
#sudo find . | cpio --owner root:root -ovH newc | gzip > ${OUTDIR}/initramfs.cpio.gz
find -print0 | cpio -0oH newc | gzip -9 > ${OUTDIR}/initramfs.cpio.gz

# DONE
