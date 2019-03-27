#! /bin/sh

DIR=/media/mmcblk0p1/apps/sdr_transceiver_ft8

$DIR/stop.sh
cp $DIR/decode-ft8.sh.orig $DIR/decode-ft8.sh
lbu commit -d
$DIR/start.sh

