function build_distro()
{
	sudo rm -rf $DISTRO_DIR/$DISTRO
	mkdir -p $DISTRO_DIR/$DISTRO

	sudo qemu-debootstrap --arch=arm64 $DISTRO $DISTRO_DIR/$DISTRO

	pushd $DISTRO_DIR/$DISTRO
# following lines must not be started with space or tab.
sudo env DISTRO=$DISTRO chroot . /bin/bash << "EOT"
adduser --gecos linaro --disabled-login linaro
echo "linaro:linaro" | chpasswd
usermod -a -G sudo linaro
adduser --gecos admin --disabled-login admin
echo "admin:admin" | chpasswd
usermod -a -G sudo admin

apt install -y software-properties-common
add-apt-repository "deb http://ports.ubuntu.com/ubuntu-ports ${DISTRO}-updates main"
add-apt-repository "deb http://ports.ubuntu.com/ubuntu-ports ${DISTRO}-security main"
add-apt-repository universe
apt update

DEBIAN_FRONTEND=noninteractive apt install -y \
irqbalance kexec-tools busybox i2c-tools \
efivar grub-efi-arm64 initramfs-tools overlayroot \
net-tools openssh-server libnss-mdns ethtool ifupdown \
build-essential docker docker.io flex bison libssl-dev \
pciutils usbutils binutils bsdmainutils mmc-utils \
parted gdisk vim sysstat minicom atop u-boot-tools tree \
memtester rng-tools psmisc gawk automake pkg-config bc \
rsync lsof cmake dnsutils python3-dev nginx python3-pip \
acpid curl dnsutils linux-tools-generic libgflags-dev \
expect libgoogle-glog-dev libboost-all-dev libev4 \
libev-dev libncurses5-dev libncurses5 libncurses-dev \
libtinfo5 telnet python3-flask python3-psutil python3-numpy \
python3-serial fdisk dkms

apt upgrade -y

apt clean

echo -e "127.0.0.1       sophon\n" >> /etc/hosts
echo -e "sophon\n" > /etc/hostname
echo -e "LC_ALL=C.UTF-8\n" > /etc/default/locale

ln -s /sbin/init /init

exit
EOT
# the end
	sudo rm -f $DISTRO_DIR/distro_$DISTRO.tgz
	sudo tar -czf $DISTRO_DIR/distro_$DISTRO.tgz *
	popd
}

mkdir $PWD/distro
export DISTRO_DIR=$PWD/distro
export DISTRO=jammy
build_distro
