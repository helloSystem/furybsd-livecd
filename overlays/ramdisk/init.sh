#!/rescue/sh

PATH="/rescue"

if [ "`ps -o command 1 | tail -n 1 | ( read c o; echo ${o} )`" = "-s" ]; then
	echo "==> Running in single-user mode"
	SINGLE_USER="true"
fi

if [ "$SINGLE_USER" = "true" ]; then
	echo "Starting interactive shell before doing anything ..."
	sh
fi

echo "==> Remount rootfs as read-write"
mount -u -w /

echo "==> Make mountpoints"
mkdir -p /cdrom
mkdir -p /live

echo "Waiting for FURYBSD media to initialize"
while : ; do
    [ -e "/dev/iso9660/FURYBSD" ] && echo "found /dev/iso9660/FURYBSD" && break
    sleep 1
done

echo "==> Mount /cdrom"
mount_cd9660 /dev/iso9660/FURYBSD /cdrom
echo "==> Mount /live"
mdmfs -P -F /cdrom/data/system.uzip -o ro md.uzip /live

if [ "$SINGLE_USER" = "true" ]; then
	echo -n "Enter memdisk size used for read-write access in the live system: "
	read MEMDISK_SIZE
else
	MEMDISK_SIZE="1024"
fi

echo "==> Mount swap-based memdisk"
mdmfs -s "${MEMDISK_SIZE}m" md /memdisk || exit 1
mount -t unionfs /memdisk /live

echo "==> Change into /live"
mount -t devfs devfs /live/dev
chroot /livecd /usr/local/bin/furybsd-init-helper

if [ "$SINGLE_USER" = "true" ]; then
	echo "Starting interactive shell after chroot ..."
	sh
fi

kenv init_shell="/rescue/sh"
exit 0
