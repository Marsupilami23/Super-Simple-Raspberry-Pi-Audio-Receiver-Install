#!/bin/bash

#The bluetooth device can appear as a number of things.
#Change the line '+ Class = 0x200414' below to one of the following classes;
# 0x200418 - Headphones
# 0x200414 - Loudspeaker (default)
# 0x200420 - Car Audio
# 0x200434 - Car audio, Loudspeaker
# 0x200438 - Car Audio, Headphones
#
# All of the above classes show the headphone icon on iOS when connected.
# If you wish to not have that icon then use one of the following;
# 0x20041C - Headphones, Portable Audio / Portable Audio
# 0x20043C - Headphones, Portable Audio, Car audio / Portable Audio, Car audio


read -p "Bluetooth device name: " BT_NAME

#--------------------------------------------------------------------
function tst {
    echo "===> Executing: $*"
    if ! $*; then
        echo "Exiting script due to error from: $*"
        exit 1
    fi	
}
#--------------------------------------------------------------------



mkdir /home/pi/pyScripts
tst cp usr/local/bin/volume-watcher.py /usr/local/bin/volume-watcher.py
tst chmod +x /usr/local/bin/volume-watcher.py
tst cp lib/systemd/system/volume-watcher.service /lib/systemd/system/volume-watcher.service
tst systemctl enable volume-watcher
tst cd `dirname $0`

echo "PRETTY_HOSTNAME=$BT_NAME" >> /tmp/machine-info
tst sudo cp /tmp/machine-info /etc

tst sudo cp init.d/pulseaudio /etc/init.d
tst sudo chmod +x /etc/init.d/pulseaudio
tst sudo update-rc.d pulseaudio defaults

tst sudo cp init.d/bluetooth /etc/init.d
tst sudo chmod +x /etc/init.d/bluetooth
tst sudo update-rc.d bluetooth defaults

tst sudo cp init.d/bluetooth-agent /etc/init.d
tst sudo chmod +x /etc/init.d/bluetooth-agent
tst sudo update-rc.d bluetooth-agent defaults

tst sudo cp usr/local/bin/bluez-udev /usr/local/bin
tst sudo chmod 755 /usr/local/bin/bluez-udev

tst sudo cp usr/local/bin/simple-agent.autotrust /usr/local/bin
tst sudo chmod 755 /usr/local/bin/simple-agent.autotrust

tst sudo cp usr/local/bin/say.sh /usr/local/bin
tst sudo chmod 755 /usr/local/bin/say.sh

tst sudo cp usr/local/bin/bluezutils.py /usr/local/bin

tst sudo cp etc/pulse/daemon.conf /etc/pulse

sudo patch /boot/config.txt << EOT
@@ -54,3 +54,6 @@
 
 # Enable audio (loads snd_bcm2835)
 dtparam=audio=on
+
+# High Quality audio patch
+audio_pwm_mode=2
EOT

if [ -f /etc/udev/rules.d/99-com.rules ]; then

sudo patch /etc/udev/rules.d/99-com.rules << EOT
***************
*** 1 ****
--- 1,2 ----
  SUBSYSTEM=="input", GROUP="input", MODE="0660"
+ KERNEL=="input[0-9]*", RUN+="/usr/local/bin/bluez-udev"
EOT

else

tst sudo touch /etc/udev/rules.d/99-com.rules
tst sudo chmod 666 /etc/udev/rules.d/99-com.rules
sudo cat  << EOT > /etc/udev/rules.d/99-input.rules
SUBSYSTEM=="input", GROUP="input", MODE="0660"
KERNEL=="input[0-9]*", RUN+="/usr/local/bin/bluez-udev"
EOT

fi

tst sudo chmod 644 /etc/udev/rules.d/99-com.rules

sudo patch /etc/bluetooth/main.conf << EOT
***************
*** 7,8 ****
--- 7,9 ----
  #Name = %h-%d
+ Name = ${BT_NAME}

***************
*** 11,12 ****
--- 12,14 ----
  #Class = 0x000100
+ Class = 0x200414

***************
*** 15,17 ****
  # 0 = disable timer, i.e. stay discoverable forever
! #DiscoverableTimeout = 0

--- 17,19 ----
  # 0 = disable timer, i.e. stay discoverable forever
! DiscoverableTimeout = 0
EOT

sudo patch /etc/pulse/system.pa << EOT
***************
*** 23,25 ****
  .ifexists module-udev-detect.so
! load-module module-udev-detect
  .else
--- 23,26 ----
  .ifexists module-udev-detect.so
! #load-module module-udev-detect
! load-module module-udev-detect tsched=0
  .else
***************
*** 57 ****
--- 58,63 ----
  load-module module-position-event-sounds
+
+ ### Automatically load driver modules for Bluetooth hardware
+ .ifexists module-bluetooth-discover.so
+     load-module module-bluetooth-discover
+ .endif
EOT


#sudo service bluetooth start &
#sudo service pulseaudio start &
#sudo service bluetooth-agent start &
# BT FIX
mkdir /etc/pulsebackup
cp /etc/pulse/* /etc/pulsebackup/
cd ~
git clone --branch v6.0 https://github.com/pulseaudio/pulseaudio
apt-get install libtool
apt-get install intltool
apt-get install libsndfile-dev
apt-get install libcap-dev
apt-get install libjson0-dev
apt-get install libasound2-dev
apt-get install libavahi-client-dev
apt-get install libbluetooth-dev
apt-get install libglib2.0-dev
apt-get install liborc-0.4-dev
apt-get install libsamplerate0-dev
apt-get install libsbc-dev
apt-get install libspeexdsp-dev
apt-get install libssl-dev
apt-get install libtdb-dev
apt-get install libbluetooth-dev
apt-get install intltool -y
cd ~
git clone https://github.com/json-c/json-c.git
cd json-c
sh autogen.sh
./configure 
make
make install
cd ~
apt install autoconf autogen automake build-essential libasound2-dev libflac-dev libogg-dev libtool libvorbis-dev pkg-config python -y
git clone git://github.com/erikd/libsndfile.git
cd libsndfile
./autogen.sh
./configure --enable-werror
make
sudo make install
cd ~
cd pulseaudio
./bootstrap.sh
make
make install
ldconfig
cp /etc/pulsebackup/* /etc/pulse
sed -i "s/DAEMON=.*/DAEMON=/usr/local/bin/pulseaudio/" /etc/init.d/pulseaudio

sleep 5

echo "Done! You should reboot now"
