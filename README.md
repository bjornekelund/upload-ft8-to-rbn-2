# upload-ft8-to-rbn-2
A set of scripts and utilities for uploading FT8 decodes 
from a [Red Pitaya 122.88-16](https://www.redpitaya.com/) based, 
[multi-band FT8 receiver](https://github.com/pavel-demin/stemlab-sdr-notes) 
to the [Reverse Beacon Network](http://www.reversebeacon.net) via 
[RBN Aggregator](http://www.reversebeacon.net/pages/Aggregator+34). 
Although grid is set in the script, call sign and grid associated 
with the spots are determined by the settings in RBN Aggregator. 
Based on the [upload-to-rbn](https://github.com/bjornekelund/upload-to-rbn) 
utility. Additional information [here](https://sm7iun.ekelund.nu/redpitaya/ft8skimmer). 

Contains a shell script (`temp.sh`) which is installed in the home
folder to check the operating temperature of the Zynq 7020 SoC. 

Also contains a quick-and-dirty server in perl offering a DX 
Cluster like stream of spots via telnet on port 7373. 
(Requires perl to be installed).

