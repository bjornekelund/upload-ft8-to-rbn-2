#!/usr/bin/perl
#
# For Redpitaya & Pavel Demin FT8 receiver & SM7IUN RBN Upload add-on.
#
# Quick and dirty telnet server offering a DX Cluster like telnet feed on 
# port 7373. Requires perl to be installed (apk add perl).
#
# Gather decodes from FT8 log file /dev/shm/decodes-yymmdd-hhmm.txt file of format.
# 190216 114645  34.7   6 -0.28  7075924 SM7IUN        JO65
#
# Tails /dev/shm/decode-ft8.log to determine when above file is ready for decoding.
#
# Derivative work based on script by Andy K1RA.

# v1.0.0 - 2019-03-29 SM7IUN

# Usage: 
# ./dxc.pl YOURCALL YOURGRID
# ./dxc.pl SM7IUN JO65MR

use strict;
use warnings;

use IO::Socket;

# check for YOUR CALL SIGN
if(!defined($ARGV[0]) || (!($ARGV[0] =~ /\w\d+\w/))) {
    die "Enter a valid call sign\n"; 
}
my $mycall = uc($ARGV[0]);

# check for YOUR GRID SQUARE (6 digit)
if(!defined($ARGV[1]) || (!($ARGV[1] =~ /\w\w\d\d\w\w/))) {
    die "Enter a valid 6 digit grid\n";
} 
my $mygrid = uc($ARGV[1]);

# DXCluster spot line header
my $prompt = "DX de ".$mycall."-#:";

# holds one single log file line
my $line;

# FT8 fields from FT8 decoder log file
my $msg;
my $date;
my $gmt;
my $x;
my $snr;
my $dt;
my $freq;
my $ft8msg;
my $call;
my $grid;

# decode current and last times
my $time;
my $ltime;

my $decodes;
my $yr;
my $mo;
my $dy;
my $hr;
my $mn;

# lookup table to determine base FT8 frequency used to calculate Hz offset
my %basefrq = (
    "1840" => 1840000,
    "1841" => 1840000,
    "1842" => 1840000,
    "1843" => 1840000,
    "3573" => 3573000,
    "3574" => 3573000,
    "3575" => 3573000,
    "3576" => 3573000,
    "5357" => 5357000,
    "5358" => 5357000,
    "5359" => 5357000,
    "5360" => 5357000,
    "7074" => 7074000,
    "7075" => 7074000,
    "7076" => 7074000,
    "7077" => 7074000,
    "10136" => 10136000,
    "10137" => 10136000,
    "10138" => 10136000,
    "10139" => 10136000,
    "14074" => 14074000,
    "14075" => 14074000,
    "14076" => 14074000,
    "14077" => 14074000,
    "18100" => 18100000,
    "18101" => 18100000,
    "18102" => 18100000,
    "18103" => 18100000,
    "21074" => 21074000,
    "21075" => 21074000,
    "21076" => 21074000,
    "21077" => 21074000,
    "24915" => 24915000,
    "24916" => 24915000,
    "24917" => 24915000,
    "24918" => 24915000,
    "28074" => 28074000,
    "28075" => 28074000,
    "28076" => 28074000,
    "28077" => 28074000,
    "50313" => 50313000,
    "50314" => 50313000,
    "50315" => 50313000,
    "50316" => 50313000
);

# used for calculating signal in Hz from base band FT8 frequency
my $base;
my $ebase;
my $hz;

# fork and sockets
my $pid;
my $main_sock;
my $new_sock;

$| = 1;

$SIG{CHLD} = sub {wait ()};

# Telnet on port 7373
$main_sock = new IO::Socket::INET (LocalPort => 7373,
                                    Listen    => 5,
                                    Proto     => 'tcp',
                                    ReuseAddr => 1,
                                 );
die "Socket could not be created. Reason: $!\n" unless ($main_sock);

while(1) {
    # Loop waiting for new inbound telnet connections
    while($new_sock = $main_sock->accept()) {
        print "New connection - ";
        print $new_sock->peerhost() . "\n";
        $pid = fork();
        die "Cannot fork: $!" unless defined($pid);

        if ($pid == 0) {
            # This is the child process
            print $new_sock $prompt ." FT8 Skimmer >\n\r";
          
            # if FT8 log is ready then open
            if(-e "/dev/shm/decode-ft8.log") {
                open(LOG, "tail -f /dev/shm/decode-ft8.log |");
                #print "Got it!\n";
            } else {
                # test for existence of log file and wait until we find it
                while(!-e "/dev/shm/decode-ft8.log") {
                    #print "Waiting 5...\n";
                    sleep 5;
                }
                open(LOG, "tail -f /dev/shm/decode-ft8.log |");
                #print "Got it!\n";
            }

            # Client loop forever
            while(1) {     
                # read in lines from FT8 decoder log file 
READ:
                while($line = <LOG>) {
                # check if we have completed a decode
                    if($line =~ /^Upl/) {

                    # derive time for previous minute to create decode TXT filename
                    ($x,$mn,$hr,$dy,$mo,$yr,$x,$x,$x) = gmtime(time-60);
              
                $mo = $mo + 1;
                $yr = $yr - 100;
              
#               print "$yr,$mo,$dy,$hr,$mn\n";
          
                $mn = sprintf("%02d", $mn);
                $hr = sprintf("%02d", $hr);
                $dy = sprintf("%02d", $dy);
                $mo = sprintf("%02d", $mo);
              
                # create the filename to read based on latest date/time stamp
                $decodes = "decodes_".$yr.$mo.$dy."_".$hr.$mn.".txt";
#               print "$decodes\n";
       
                if(!-e "/dev/shm/".$decodes) {
                   print "No decode file $decodes\n";            
                    next READ; 
                }
            
                # Open TXT file for the corresponding date/time
                open(TXT,  "< /dev/shm/".$decodes);        

                # loop thru all decodes
MSG:
                while($msg = <TXT>) {
#                  print $msg;

                    # check if this is a valid FT8 decode line beginning with 6 digit time stamp    
                    # 181216 014645  34.7   4 -0.98  7075924 SM7IUN         JO65

                    if(!($msg =~ /^\d{6}\s\d{6}/)) {
                        next MSG; 
                    }

                    # looks like a valid line split into variable fields
                    ($date, $gmt, $x, $snr, $x, $freq, $call, $grid)= split(" ", $msg);
                    #print "call=$call grid=$grid\n";

                    # if not a valid call, skip this msg
                    if(($call eq "") || (!($call =~ /\d/))) {
                        next MSG;
                    }

                    # clear grid if undefined
                    if($grid eq "") {$grid = "    ";}

                        # extract HHMM
                        $gmt =~ /^(\d\d\d\d)\d\d/;
                        $gmt = $1;
        
                        # get UNIX time since epoch  
                        $time = time();
        
                        # determine base frequency for this FT8 band decode    
                        $base = int($freq / 1000);
                        $ebase = $basefrq{$base} || ($base * 1000);

                        # make sure call has at least one number in it
                        if ($call =~ /\d/) {
#                           if(!defined($base)) {print "$call $base\n";}

                            $hz = $freq - $ebase;
                            
                            # send client a spot
                            # DX de SM7IUN-#:    14074.8 5Q0X       FT8  -3 dB 1234 Hz JO54           1737z
                            printf $new_sock "%-15s %8.1f  %-12s FT8 %3s dB %4s Hz %4s      %6sZ\n\r",
                                    $prompt,$ebase/1000,$call,$snr,$hz,$grid,$gmt;
                            }  
                        } # end while($msg = <MSG> - end of reading MSGs
                    } # end if($line =~ /^Done/ - end of a FT8 log decoder minute capture
                    die "Socket is closed" unless $new_sock->connected;           
                } # end while($line = <LOG> - end of FT8 decode LOG file
            } # end while(1) - loop client forever
        } # end if($pid == 0) - its the parent process, which goes back to accept()
   } # end while($new_sock - main wait for socket loop forever
} # end while (1)

