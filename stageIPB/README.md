# Old documentation used to build the stage

## Network configurations and hotspot setup: stageIPB0
For the _ipb-net_ just pick this fixed ip address **192.168.1.200**, you can do
this chaging stuff on this config file:
**`/etc/dhcpcd.conf`**

```sh
interface eth0
    static ip_address=192.168.1.200/24
```

Remember to `sudo service dhcpcd restart` after editing that file

For the hotspot setup just follow this guide [Setting up a Raspberry Pi as a Wireless Access Point](https://www.raspberrypi.org/documentation/configuration/wireless/access-point-routed.md)

Using the following naming convention:
`etc/hostapd/hostapd.conf`

```sh
interface=wlan0
driver=nl80211
ssid=rpi_ipb_car # pay attention to this
hw_mode=g
channel=7
wmm_enabled=0
macaddr_acl=0
auth_algs=1
ignore_broadcast_ssid=0
wpa=2
wpa_passphrase=ipbcar2019
wpa_key_mgmt=WPA-PSK
wpa_pairwise=TKIP
rsn_pairwise=CCMP
```

## Install docker and download image: stageIPB1

### Docker

Get docker and install it

```
curl -fsSL https://get.docker.com -o get-docker.sh
chmod +x get-docker.sh
sh get-docker.sh
usermod -aG docker pi

# Get signing keys to verify the new packages, otherwise they will not install
apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 04EE7237B7D453EC 648ACFD622F3D138
# Add the Buster backport repository to apt sources.list
echo 'deb http://httpredir.debian.org/debian buster-backports main contrib non-free' | tee -a /etc/apt/sources.list.d/debian-backports.list

apt update

```

Copy scripts and service

```
install -m 600 files/download-frozen-image-v2.sh  "${ROOTFS_DIR}/home/pi/download-frozen-image-v2.sh"

install -m 644 files/ipbcar_docker.service "${ROOTFS_DIR}/lib/systemd/system/ipbcar_docker.service"
install -m 600 files/ipbcar_docker.sh "${ROOTFS_DIR}/home/pi/ipbcar_docker.sh"

```

Restart service daemon and enable our service

```
systemctl daemon-reload
systemctl enable ipbcar_docker.service
```

Download docker image (it will be loaded at startup)

```
cd /home/pi 
bash download-frozen-image-v2.sh docker_image prbonn/pi_ros:latest
echo 'load the image with: docker load -i docker_image.tar'
```

## GPS Emlid Reach Setup: stageIPB2

Emlid Reach 2 GPS: The Emlid Reach 2 GPS is connected via USB to the laptop and
the communication is done via the serial port. The laptop must be configured
that the serial port is created at '/dev/gps-emlid'. This can be done by setting
up a persistent name for the device:

### Setup udev rules

When the linux kernel mounts a device, it gives it a certain name such as
/dev/ttyUSB0 or /dev/ttyUSB1 etc. However, when connect multiple devices it
becomes difficult to identify which device is what. Also the kernel does not
give the device the same name each time it is plugged in. It is therefore nice
to have descriptive _persistent name_ for each device. For example, the gps sensor
can be mounted as '/dev/gps-emlid' each time it is connected. We can achieve it
in the following way:

1. Connect just the GPS to the computer. We connect only one device at a time to
   avoid potential ambiguity.

2. Find out the device name with which it is mounted. To do this, just see what
   was mounted in the '/dev' folder after you plugged in the gps.

3. Find out that the serial number is correct with the one of the device. The serial number is normally
   printed on the hardware or given in the product manual. </br>
   `udevadm info -a -n /dev/ttyUSB{*} | grep '{serial}' | head -n1`.

4. Create a rules file such as `99-serial.rules` in the /etc/udev/rules.d
   folder and put the following line there: </br>
   `SUBSYSTEM=="tty", ATTRS{idVendor}=="1546", ATTRS{idProduct}=="01a7", ATTRS{serial}=="xxxxx", SYMLINK+="gps-evk7p"` </br>
   (Note: Replace the attribute values corresponding to the device you are plugging
   in. Add this line for each new device you would like to use with a persistent
   name.)

[Information source](http://hintshop.ludvig.co.nz/show/persistent-names-usb-serial-devices/)

### GPS Clock Synchronization

Time synchronization is something that affects many robotic systems. With more computers and sensors, keeping everything synchronized becomes increasingly important. Trying to look through log files where all of the times are skewed is not fun and makes processing difficult. Merging sensor data together with GPS can also be disastrous if the times are offset. Further complicating time synchronization on robots is that they are often not connected to the internet so utilizing public time servers will not work.

_Chrony_ is a tool used for time synchronization capable for fetching GPS and PPS signals in order to make clock adjustments. In this guide we will take a look how to use it and configure it with the GPS.

### Why Raspberry Pi?

The reason why we use the Raspberry Pi as Master clock and synchronize it with an extra cheap GPS ([Raspberry Pi+ GPS](Architecture%3ASensors#raspberry-pi+-gps)) is that we want to set up a stratum-1 NTP server capable of adjusting all the sensors clock connected to the network.
We cannot directly set up the stratum-1 NTP server with Emlid GPS ([Emlid Reach RS2](Architecture%3ASensors#emlid-reach-rs2)), because it needs the pulse per second (PPS) output which cannot be easily extracted from it.


### Install GPS-PPS related software

```shell
sudo apt install pps-tools
sudo apt-get install gpsd-clients python-gps
sudo apt-get install minicom picocom
sudo apt-get install chrony
```

### Disable login-shell but enable serial port

For more information about this, please visit the [Configuring The GPIO Serial Port On Raspbian Jessie and Stretch Including Pi 3 and 4](https://spellfoundry.com/2016/05/29/configuring-gpio-serial-port-raspbian-jessie-including-pi-3-4/)

ssh into the raspberry pi and do the following

```shell
sudo raspi-config
```

and then

- **5 Interfacing options**
- _Would you like a login shell to be accessible over serial?_
  - **NO**
- _Would you like the serial port hardware to be enabled?_
  - **YES**

This should be the output

```shell
 ┌──────────────────────────────────────────────────────────┐
 │                                                          │
 │ The serial login shell is disabled                       │
 │ The serial interface is enabled                          │
 │                                                          │
 │                                                          │
 │                                                          │
 │                                                          │
 │                                                          │
 │                                                          │
 │                                                          │
 │                                                          │
 │                                                          │
 │                                                          │
 │                                                          │
 │                                                          │
 │                                                          │
 │                          <Ok>                            │
 │                                                          │
 └──────────────────────────────────────────────────────────┘
```

### Pick the high-speed UART for the GPS

Long story short, read this [configuration-uart](https://www.raspberrypi.org/documentation/configuration/uart.md)

By default, the UART transmit and receive pins are on GPIO 14 and GPIO 15 respectively, which are pins 8 and 10 on the GPIO header.

#### UARTs and Device Tree

`disable-bt` disables the Bluetooth device and restores UART0/ttyAMA0 to
GPIOs 14 and 15. It is also necessary to disable the system service that
initialises the modem so it doesn't use the UART: `sudo systemctl disable hciuart`.

There are other UART-specific overlays in the folder. Refer to
`/boot/overlays/README` for details on Device Tree Overlays, or run `dtoverlay -h overlay-name` for descriptions and usage information.

Add a line to the `/boot/config.txt` file to
enable Device Tree Overlays. Note that the `-overlay.dts` part of the filename
is removed.

**In short** just do

```
sudo systemctl disable hciuart
sudo echo "dtoverlay=disable-bt" >> /boot/config.txt
```

### Add PPS-GPIO overlay

- Open `/boot/config.txt` and add on a new line:

  ```bash
  dtoverlay=pps-gpio,gpiopin=18
  ```

[Optional] If you **NOT** using the custom made firmware by nacho, you will also need to
load the pps-gpio kernel module by "hand". The one that nacho did has the
pps-gpio driver built-in the kernel.

- Open `/etc/modules` and add on a new line.

  ```bash
  pps-gpio
  ```

- Verify that PPS is working and interrupting the kernel

  ```bash
  sudo ppstest /dev/pps0
  source 0 - assert 1571941416.627467541, sequence: 398 - clear  0.000000000, sequence: 0
  source 0 - assert 1571941417.627480745, sequence: 399 - clear  0.000000000, sequence: 0
  ```

  You should see incoming msgs like `source 0 - assert 1571941417.627480745, sequence: 399 - clear 0.000000000, sequence: 0` with an increasing number on
  the `sequence`. Make sure that this msgs appears roughly at the same rate that
  the `TIMEPULSE` LED blinks on the GPS-HAT

Save, close & reboot.


### Install GPSD

We've followed the instructions from here [Getting GPS to work on Raspberry Pi 3 Model B
](https://wiki.dragino.com/index.php?title=Getting_GPS_to_work_on_Raspberry_Pi_3_Model_B)

Note if you're using the Raspbian Jessie or later release you'll need to disable
a systemd service that gpsd installs. This service has systemd listen on a
local socket and run gpsd when clients connect to it, however it will also
interfere with other gpsd instances that are manually run (like in this guide).
You will need to disable the gpsd systemd service by running the following
commands:

```bash
sudo systemctl stop gpsd.socket
sudo systemctl disable gpsd.socket
```

After disabling the gpsd systemd service above you're ready to try running gpsd
manually.

#### Test gpsd

GPSD needs to be started up, using the following command:

```bash
sudo gpsd /dev/ttyAMA0 -F /var/run/gpsd.sock
```

Now GPS doesn’t work indoors – as it needs a clear view of the sky so
for this I’ve placed the PI on the window sill. Next I ssh into the pi and run
cgps. There is a simple GPS client which you can run to test everything is
working:

```bash
cgps -s
```

The -s flag is there to tell the command not to write raw data to the screen as
well as the processed data.

It may take a few seconds for data to come through, but you should see a screen
like this:

```bash
┌───────────────────────────────────────────┐┌─────────────────────────────────┐
│    Time:       2019-10-28T16:47:20.000Z   ││PRN:   Elev:  Azim:  SNR:  Used: │
│    Latitude:    50.72711000 N             ││   5    62    233    48      Y   │
│    Longitude:    7.08669116 E             ││   7    37    061    31      Y   │
│    Altitude:   78.000 m                   ││   8    08    054    27      Y   │
│    Speed:      0.01 kph                   ││  13    53    288    36      Y   │
│    Heading:    0.0 deg (true)             ││  15    19    290    49      Y   │
│    Climb:      0.00 m/min                 ││  21    10    329    20      Y   │
│    Status:     3D DIFF FIX (7 secs)       ││  27    06    021    28      Y   │
│    Longitude Err:   +/- 1 m               ││  28    36    144    33      Y   │
│    Latitude Err:    +/- 1 m               ││  30    71    074    42      Y   │
│    Altitude Err:    +/- 1 m               ││  65    48    316    25      Y   │
│    Course Err:      n/a                   ││  71    29    132    35      Y   │
│    Speed Err:       +/- 10 kph            ││  72    82    116    17      Y   │
│    Time offset:     0.966                 ││  73    45    044    31      Y   │
│    Grid Square:     JO30nr                ││                                 │
└───────────────────────────────────────────┘└─────────────────────────────────┘
```

If this setup is working then throw this in here **`/etc/default/gpsd`**:

```bash
# Default settings for the gpsd init script and the hotplug wrapper.

# Start the gpsd daemon automatically at boot time
START_DAEMON="true"

# Use USB hotplugging to add new USB devices automatically to the daemon
USBAUTO="false"

# Devices gpsd should collect to at boot time.
# They need to be read/writeable, either by user gpsd or the group dialout.
DEVICES="/dev/ttyAMA0 /dev/pps0"

# Other options you want to pass to gpsd
GPSD_OPTIONS="/var/run/gpsd.sock"

# Other options you want to pass to gpsd
#
# -n    don't wait for client to connect; poll GPS immediately
GPSD_OPTIONS="-n"
```

And lastly enable the `gpsd` service and reboot

```bash
sudo systemctl enable gpsd
```

### Chrony

We will be using **`chrony`** to synchronize the Raspberry Pi clock with the one from the
`GPS`.

Chrony is based on NTP but performs better when not connected to the internet, has smoother clock adjustments, and is easier to get GPS signals into.
The reason for using Chrony to synchronize the Raspberry Pi clock with the GPS time is that we will use PTP to synchronize all sensors with Raspberry Pi.
In order to synchronize all sensors to the uniform GPS time, we then need to first synchronize Raspberry Pi with GPS time using Chrony.

The last 2 lines allow any NTP clients to access the NTP server and to appear synchronised to NTP clients, even when it is not.

Add this 4 lines to the end of **`/etc/chrony/chrony.conf`**:

```bash
refclock PPS /dev/pps0 lock NMEA
refclock SHM 0 offset 0.5 delay 0.2 refid NMEA noselect
allow
local
```

And then do `sudo systemctl restart chronyd`

If the setup was successful, you should get something similar to this output
when running `chronyc sources -v`:

```bash
pi@ipbcar:~ $ chronyc sources -v
210 Number of sources = 6

  .-- Source mode  '^' = server, '=' = peer, '#' = local clock.
 / .- Source state '*' = current synced, '+' = combined , '-' = not combined,
| /   '?' = unreachable, 'x' = time may be in error, '~' = time too variable.
||                                                 .- xxxx [ yyyy ] +/- zzzz
||      Reachability register (octal) -.           |  xxxx = adjusted offset,
||      Log2(Polling interval) --.      |          |  yyyy = measured offset,
||                                \     |          |  zzzz = estimated error.
||                                 |    |           \
MS Name/IP address         Stratum Poll Reach LastRx Last sample
===============================================================================
#? PPS0                          0   4     0     -     +0ns[   +0ns] +/-    0ns
#? NMEA                          0   4     0     -     +0ns[   +0ns] +/-    0ns
^? 1d.ncomputers.org             2   6     1     1  -2078us[-2078us] +/-   36ms
^? monkey.spod.net               2   6     1     1   -612us[ -612us] +/-   20ms
^? spacys.de                     2   6     1     1  -2140us[-2140us] +/-   40ms
^? cluster003.linocomm.net       2   6     1     1   -853us[ -853us] +/-   16ms
pi@ipbcar:~ $
```

You can now use chronyc to provide a more detailed view using the command:

```bash
sudo chronyc tracking.
```

This will confirm that NMEA is being used as the reference and will list the
time difference between the reference and the system clock. To avoid clock
jitter that can cause lots of software problems, chrony slowly changes the
system clock until it matches the reference. However, this makes for a very slow
synchronisation.

## Install PPT: StageIPB3

* Install `linuxptp`
* Copy ptp config: `install -m 600 files/ptp4l.conf  "${ROOTFS_DIR}/etc/linuxptp/ptp4l.conf"`
* Enable and start `ptp4l`:
```
systemctl enable ptp4l
systemctl start ptp4l
```
