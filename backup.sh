#!/bin/bash

if [ ${EUID} != 0 ]; then
    echo "E: Execution not possible, are you root?"
    exit 3
fi

# data
SRCS=("/boot" "/etc" "/home" "/opt" "/root" "/var")

# master boot records (relative to "/dev/")
MBRS=("sda" "sda1")

# partition tables (relative to "/dev/")
PTS=("sda")

# destination of all backups (master boot records will be saved relative into "mbrs" and partition tables relative into "pts")
DEST="/media/backup/"

LOG="/var/log/backup.log"
PACKAGES_FILE="/var/packages.txt"

# the full path to the backup script
SCRIPT="/opt/backup/backup.sh"

# script
case $1 in
backup)
    echo "Deleting old log ..."
    echo -e "\n\nDeleting old log ..." > $LOG

    echo "Creating package list ..."
    echo -e "\n\nCreating package list ..." >> $LOG
    # dpkg --get-selections | awk "!/deinstall|purge|hold/ {print $1}" > $PACKAGES_FILE
    dpkg -l > $PACKAGES_FILE

    for SRC in  "${SRCS[@]}"
    do
        echo "Backuping \"$SRC\" ..."
        echo -e "\n\nBackuping \"$SRC\" ..." >> $LOG

        mkdir -p "$DEST/$SRC" >> $LOG
        rsync -vru --delete "$SRC" "$DEST" >> $LOG
    done

    for MBR in "${MBRS[@]}"
    do
        echo "Backuping master boot record of \"$MBR\" ..."
        echo -e "\n\nBackuping master boot record of \"$MBR\" ..." >> $LOG

        mkdir -p "$DEST/mbrs" >> $LOG
        dd if="/dev/$MBR" of="$DEST/mbrs/$MBR.mbr" bs=512 count=1
    done

    for PT in  "${PTS[@]}"
    do
        echo "Backuping partition table of \"$PT\" ..."
        echo -e "\n\nBackuping partition table of \"$PT\" ..." >> $LOG

        mkdir -p "$DEST/pts" >> $LOG
        sfdisk -d "/dev/$PT" > "$DEST/pts/$PT.pt" >> $LOG
    done

    echo "Backuping package list ..."
    echo -e "\n\nBackuping package list ..." >> $LOG
    cp $PACKAGES_FILE $DEST

    echo "Backuping log ..."
    echo -e "\n\nBackuping log ..." >> $LOG
    cp $LOG $DEST
    ;;
recover-data)
    echo "Deleting old log ..."
    echo -e "\n\nDeleting old log ..." > $LOG

    for SRC in "${SRCS[@]}"
    do
        echo "Recovering \"$SRC\" ..."
        echo -e "Recovering \"$SRC\" ..." >> $LOG

        mkdir -p "$DEST/$SRC" >> $LOG
        rsync -vr --delete --exclude "$LOG" "$DEST/$SRC" "$SRC" >> $LOG
    done
    ;;
recover-packages)
    echo "Not supported yet!"
#    echo "Recovering packages ..."
#    echo -e "\n\nRecovering packages ..." >> $LOG

#    xargs -a $PACKAGES_FILE apt-get -qv install >> $LOG
    ;;
force-recover)
    for MBR in "${MBRS[@]}"
    do
        echo "Recovering master boot record of \"$MBR\" wieder her ..."
        echo -e echo "\n\nRecovering master boot record of \"$MBR\" wieder her ..." >> $LOG

        dd if="$DEST/mbrs/$MBR.mbr" of="/dev/$MBR" bs=512 count=1
    done

    for PT in  "${PTS[@]}"
    do
        echo "Recovering partition table of \"$PT\" ..."
        echo -e "\n\nRecovering partition table of \"$PT\" ..." >> $LOG

        sfdisk "/dev/$PT" < "$DEST/pts/$PT.pt" >> $LOG
    done

    $SCRIPT recover-packages
    $SCRIPT recover-data
    ;;
*)
    echo "Use \"$SCRIPT <backup|recover-data|recover-packages|force-recover>\"!"
    ;;
esac
