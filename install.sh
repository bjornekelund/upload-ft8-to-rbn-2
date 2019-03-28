#! /bin/sh

DIR=/media/mmcblk0p1/apps/sdr_transceiver_ft8

$DIR/stop.sh

chmod +x *.sh upload-to-rbn

cp temp.sh ~

cp upload-to-rbn $DIR

# Back up original decode-ft8.sh 
test -e $DIR/decode-ft8.sh.orig || cp $DIR/decode-ft8.sh $DIR/decode-ft8.sh.orig
cp decode-ft8.sh $DIR

# Set FT8 receiver to run at boot
cp $DIR/start.sh /media/mmcblk0p1

lbu commit -d
