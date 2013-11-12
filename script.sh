#!/bin/bash
SCRIPT_VERSION='0.1.0'
UPLOAD_URL='http://google.com'
REPO_URL='https://raw.github.com/benchmarky/bench_test/master/'
usage () {
	echo "Usage: bash $0 [ -h ] -e email@example.com -p SuperHosting.com -c BigServer-x2 -t all [ -a ] [ -q ]" 
	echo -e "\t-e - email"
	echo -e "\t-h - show this help"
	echo -e "\t-p - provider"
	echo -e "\t-c - tariff"
	echo -e "\t-t - which tests to run (comma-separated list (disk,unixbench,bandwidth) or all"
	echo -e "\t-a - don't public results"
	echo -e "\t-q - show less messages"
}


# Some variables
LOGFILE=$PWD/script.log
WORKDIR=$PWD
TMPDIR=$PWD/tmpdir
SHOWLOG=$PWD/stdout.log
# default values
TESTS='all'
ANONYOMOUS='false'
QUIETLY='false'

EMAIL='null'
PROVIDER='null'
TARIFF='null'

while getopts "he:p:t:c:aq" opt; do
	case "$opt" in
	h)
		usage
		exit 0
		;;
	e)	EMAIL=$OPTARG
		;;	
	p)	PROVIDER=$OPTARG
		;;	
	c)	TARIFF=$OPTARG
		;;	
	t)	TESTS=$OPTARG
		;;	
	a)	ANONYOMOUS='yes'
		;;
	q)	QUIETLY='yes'
		;;
	esac
done

# Validate parameters
if [ $EMAIL = 'null' -o $PROVIDER = 'null' -o $TARIFF = 'null' ]; then
	usage
	exit 0
fi
if [ $QUIETLY = 'false' ]; then
	SHOWLOG=$LOGFILE
fi

# Here we would like to go to background
if test -t 1 ; then
	echo "Right now script will switch to the background,
so you can disconnect from terminal and 
go drink a cup of tea while it is running.
Or please look at the log output. 
You can disconnect from log by Ctrl+C anytime."
	rm -f $SHOWLOG $LOGFILE
	touch $SHOWLOG
	nohup bash $0 $@ >> $SHOWLOG 2>&1 &
	tail -F $SHOWLOG -n 25
	exit 0
fi
sleep 20
# Parse required tests
NEED_DISK='null'
NEED_BANDWIDTH='null'
NEED_UNIXBENCH='null'

if [ $TESTS = 'all' ]; then
	NEED_DISK='yes'
	NEED_BANDWIDTH='yes'
	NEED_UNIXBENCH='yes'
else 
	for TEST in `echo $TESTS | sed 's/,/ /g'`;do
		case $TEST in
			disk) 
				NEED_DISK='yes'
				;;
			unixbench) 
				NEED_UNIXBENCH='yes'
				;;
			bandwidth) 
				NEED_BANDWIDTH='yes'
				;;
		esac
	done
fi

# Prepare environment
echo "Creating directory $TMPDIR"
rm -rf $TMPDIR
mkdir -p $TMPDIR 
if [ ! -d $TMPDIR ];then
	echo "Can't create directory $TMPDIR" && exit 1
fi
cd $TMPDIR
# touch log file
#touch $LOGFILE
DATE=`date`
echo "==DATE==" >>$LOGFILE
echo $DATE  >> $LOGFILE
echo "==VERSION==" >>$LOGFILE
echo "VERSION: ${SCRIPT_VERSION}" >>$LOGFILE
echo "==PARAMETERS==" >>$LOGFILE
echo "EMAIL: ${EMAIL}" >>$LOGFILE
echo "PROVIDER: ${PROVIDER}" >>$LOGFILE
echo "TARIFF: ${TARIFF}" >>$LOGFILE
echo "TESTS: ${TESTS}" >>$LOGFILE
echo "ANONYOMOUS: ${ANONYOMOUS}" >>$LOGFILE

# We can test bandwidth without additional packages
# For test unixbench and disk we need them
function requires() {
  if [ `$1 >/dev/null; echo $?` -ne 0 ]; then
    TO_INSTALL="$TO_INSTALL $2"
  fi 
}
function apt_requires() {
	installed=`dpkg -s $1 2>/dev/null| grep -c 'install ok installed'`
	if [ $installed = 0 ]; then
			TO_INSTALL="$TO_INSTALL $1"
	fi
}
# args: [name] [target dir] [filename] [url]
function require_download() {
  if ! [ -e "`pwd`/$2" ]; then
    echo "Downloading $1..."
    echo "Downloading $1..." >>$LOGFILE
    wget --no-check-certificate -q --no-check-certificate -O - $3 | tar -xzf -
  fi
}

TO_INSTALL=""
if [ `which apt-get >/dev/null 2>&1; echo $?` -ne 0 ]; then
  PACKAGE_MANAGER='yum'

  requires 'yum list installed kernel-devel' 'kernel-devel'
  requires 'yum list installed libaio-devel' 'libaio-devel'
  requires 'yum list installed gcc-c++' 'gcc-c++'
  requires 'perl -MTime::HiRes -e 1' 'perl-Time-HiRes'
  requires 'yum list installed curl' 'curl'
  requires 'yum list installed make' 'make'
  requires 'yum list installed traceroute' 'traceroute'
  requires 'yum list installed gcc' 'gcc'
else
  PACKAGE_MANAGER='apt-get'
  MANAGER_OPTS='--fix-missing'
  UPDATE='apt-get update'

  apt_requires 'build-essential'
  apt_requires 'libaio-dev'
  apt_requires 'perl'
  apt_requires 'curl'
  apt_requires 'make'
  apt_requires 'traceroute'
fi

if [ "`whoami`" != "root" ]; then
  SUDO='sudo'
fi

if [ "$TO_INSTALL" != '' ]; then
  echo "==PACKAGES=="
  echo "Using $PACKAGE_MANAGER to install $TO_INSTALL"
  echo "Using $PACKAGE_MANAGER to install $TO_INSTALL" >>$LOGFILE
  if [ "$UPDATE" != '' ]; then
	echo "Doing package update"
	$SUDO $UPDATE
  fi 
  $SUDO $PACKAGE_MANAGER install -y $TO_INSTALL $MANAGER_OPTS
fi

# Prepare required tests
FIO_VERSION=2.1.2
FIO_DIR=fio-$FIO_VERSION
UNIX_BENCH_VERSION=5.1.3
UNIX_BENCH_DIR=UnixBench-$UNIX_BENCH_VERSION

echo "==TESTSVERSIONS==" >>$LOGFILE
echo "FIO_VERSION: ${FIO_VERSION}" >>$LOGFILE
echo "FIO_DIR: ${FIO_DIR}" >>$LOGFILE
echo "UNIX_BENCH_VERSION: ${UNIX_BENCH_VERSION}" >>$LOGFILE
echo "UNIX_BENCH_DIR: ${UNIX_BENCH_DIR}" >>$LOGFILE

if [ $NEED_DISK = 'yes' ]; then
	require_download FIO fio-$FIO_DIR ${REPO_URL}fio-${FIO_VERSION}.tar.gz

fi
if [ $NEED_UNIXBENCH = 'yes' ]; then
	require_download UnixBench $UNIX_BENCH_DIR ${REPO_URL}UnixBench$UNIX_BENCH_VERSION-patched.tgz
	mv -f UnixBench $UNIX_BENCH_DIR 2>/dev/null
fi 


# Running benchmarks

# Check server information
echo "Collecting server information"
echo "==SERVERINFO==" >>$LOGFILE
echo "ISSUE.NET: ">>$LOGFILE
cat /etc/issue.net >>$LOGFILE
echo "PROCINFO: " >>$LOGFILE
cat /proc/cpuinfo >>$LOGFILE
echo "DISKS: " >> $LOGFILE
df >> $LOGFILE
if [ -f /sys/block/sda/device/model ]; then
	cat /sys/block/sda/device/model >> $LOGFILE

fi
if [ -f /sys/block/sda/device/vendor ]; then
	cat /sys/block/sda/device/vendor >> $LOGFILE
fi
echo "MEMORY: " >> $LOGFILE
free >> $LOGFILE

function download_benchmark () {
	echo "Downloading from $1 ($2)" >>$LOGFILE
	curl -L -s -w "%{speed_download}\n" -o /dev/null $2 >>$LOGFILE
} 
if [ $NEED_BANDWIDTH = 'yes' ]; then
	echo "Running bandwidth tests"
	echo "==BANDWIDTH==" >>$LOGFILE
	download_benchmark 'Cachefly' 'http://cachefly.cachefly.net/100mb.test'
	download_benchmark 'Linode, Atlanta, GA, USA' 'http://speedtest.atlanta.linode.com/100MB-atlanta.bin'
	download_benchmark 'Linode, Dallas, TX, USA' 'http://speedtest.newark.linode.com/100MB-newark.bin'
	download_benchmark 'Linode, Tokyo, JP' 'http://speedtest.tokyo.linode.com/100MB-tokyo.bin'
	download_benchmark 'Linode, London, UK' 'http://speedtest.london.linode.com/100MB-london.bin'
	download_benchmark 'OVH, Paris, France' 'http://proof.ovh.net/files/100Mio.dat'
	download_benchmark 'SmartDC, Rotterdam, Netherlands' 'http://mirror.i3d.net/100mb.bin'
	download_benchmark 'Host Europe, Germany' 'http://ftp.hosteurope.de/he/cdn/testdatei_100MB'
	download_benchmark 'Hetzner, Nuremberg, Germany' 'http://hetzner.de/100MB.iso'
	download_benchmark 'iiNet, Perth, WA, Australia' 'http://ftp.iinet.net.au/test100MB.dat'
	download_benchmark 'Leaseweb, Haarlem, NL, USA' 'http://mirror.leaseweb.com/speedtest/100mb.bin'
	download_benchmark 'Softlayer, Singapore' 'http://speedtest.sng01.softlayer.com/downloads/test100.zip'
	download_benchmark 'Softlayer, Seattle, WA, USA' 'http://speedtest.sea01.softlayer.com/downloads/test100.zip'
	download_benchmark 'Softlayer, San Jose, CA, USA' 'http://speedtest.sjc01.softlayer.com/downloads/test100.zip'
	download_benchmark 'Softlayer, Washington, DC, USA' 'http://speedtest.wdc01.softlayer.com/downloads/test100.zip'
	download_benchmark 'Yandex, Moscow, Russia' 'http://mirror.yandex.ru/kernel.org/linux/kernel/v3.x/linux-3.9.9.tar.gz'

fi

if [ $NEED_DISK = 'yes' ]; then
	echo "==DISK==" >>$LOGFILE
	# DD
	echo "Running dd tests"

	echo "dd 1Mx1k fdatasync: `dd if=/dev/zero of=ddtest.iso bs=1M count=1k conv=fdatasync 2>&1`" >> $LOGFILE
	echo "dd 64kx16k fdatasync: `dd if=/dev/zero of=ddtest.iso bs=64k count=16k conv=fdatasync 2>&1`" >> $LOGFILE
	echo "dd 1Mx1k dsync: `dd if=/dev/zero of=ddtest.iso bs=1M count=1k oflag=dsync 2>&1`" >> $LOGFILE
	echo "dd 64kx16k dsync: `dd if=/dev/zero of=ddtest.iso bs=64k count=16k oflag=dsync 2>&1`" >> $LOGFILE

	rm -f ddtest.iso

	echo "Compiling FIO"
	cd $FIO_DIR
	make >> $LOGFILE 2>&1
	echo "Downloading FIO configs"
	wget -q $REPO_URL/fio.conf.d/reads.ini
	wget -q $REPO_URL/fio.conf.d/writes.ini
	wget -q $REPO_URL/fio.conf.d/rw.ini
	echo "Running FIO"
	echo "FIO random reads:
	`./fio reads.ini 2>&1`
	Done" >> $LOGFILE

	echo "FIO random writes:
	`./fio writes.ini 2>&1`
	Done" >> $LOGFILE

	echo "FIO random rw:
	`./fio rw.ini 2>&1`
	Done" >> $LOGFILE
	cd ..
fi


if [ $NEED_UNIXBENCH = 'yes' ]; then
	echo "==UNIXBENCH==" >>$LOGFILE
	echo "Running UnixBench test"
	cd $UNIX_BENCH_DIR
	./Run -c 1 -c `grep -c processor /proc/cpuinfo` >> $LOGFILE 2>&1
	cd ..
fi

curl -s -F "upload=@${LOGFILE};type=text/plain" $UPLOAD_URL
rm -rf $TMPDIR

# DELETE PCAKAGES
if [ "$TO_INSTALL" != '' ]; then
  $SUDO $PACKAGE_MANAGER remove -y $TO_INSTALL $MANAGER_OPTS
fi

echo "
### FINISH ####
Script has done it's work.
Please press Ctrl+C to exit.
You will receive results by email.
Script created 2 files: stdout.log and script.log.
You can delete them with no mercy"

