#!/bin/sh
###############################################################################
#                                                                             #
# builds an osm map for garmin devices                                        #
#                                                                             #
# @version: 1.11                                                              #
# @author: Steiner Patrick <patrick@helmsdeep.at>                             #
# @date: 08.03.2010 14:55                                                     #
# License: GPL                                                                #
# http://www.fsf.org/licenses/gpl.htmlfree for all                            #
#                                                                             #
###############################################################################

# ./osm-build_map.sh -c austria -t outdoor

# read the config from a seperate file
if [ -r conf/machine.conf ]; then
	. conf/machine.conf
else
	echo "ERROR: no machine config file found."
	exit -1
fi

# osm data directory
OSMDATADIR="$OSMGARMINDIR/osm-data"

# osm data download script
OSMDATASCRIPT="$OSMDATADIR/osm-get_data.sh"

# tmp build patch
OSMDATATMP="$OSMGARMINDIR/osm-data-tmp"

# cache directory
OSMDATACACHE="$OSMGARMINDIR/osm-data-cache"

# current date
CDATE=`date "+%G%m%d"`

###############################################################################

CWD=`pwd`

# check for core applications
function check_apps()
{
	# java
	if [ ! -x /usr/bin/java ]; then
		echo "ERROR: java not found."
		exit -1
	fi

	# mkgmap splitter
	if [ ! -f $SPLITTERBIN ]; then
		echo "ERROR: mkgmap splitter not found."
		exit -1
	fi

	# mkgmap
	if [ ! -f $MKGMAPBIN ]; then
		echo "ERROR: mkgmap not found."
		exit -1
	fi
}

# build core directories
function build_directories()
{
	# std map std dirs
	if [ ! -d $STDMAPDIR ]; then
		mkdir $STDMAPDIR
	fi

	if [ ! -d $STDMAPDIR/dist ]; then
		mkdir $STDMAPDIR/dist
	fi

	if [ ! -d $STDMAPDIR/build ]; then
		mkdir $STDMAPDIR/build
	fi

	if [ ! -d $OSMDATACACHE ]; then
		mkdir $OSMDATACACHE
	fi

	if [ ! -d $OSMDATATMP ]; then
		mkdir $OSMDATATMP
	fi
}

# split osm data
function split_map()
{
	echo "Spliting map ("$OSMDATA")..."
	cd $OSMDATATMP
	rm -rf *.gz *.list *.args
	java -Xmx${UMEM}M -jar $SPLITTERBIN --mapid=63240345 --max-nodes=1000000 --cache=$OSMDATACACHE $OSMDATA
}

# build garmin img files
function build_map()
{
	echo "Building map..."
	rm -f $STDMAPDIR/build/*.img
	rm -f $STDMAPDIR/build/*.tdb
	cd $STDMAPDIR/build

	# check if TYP file exists
	if [ -f ../styles/$MAPTYPE.TYP ]; then
		TYPFILE="../styles/$MAPTYPE.TYP"
	else
		echo "INFO: TYP file not found"
		TYPFILE=""
	fi

	# check if options file is available
	if [ -f ../options.args.$COUNTRY ];then
		echo "INFO: using options.args.$COUNTRY"
		java -Xmx${UMEM}M -jar $MKGMAPBIN --max-jobs -c ../options.args.$COUNTRY $OSMDATATMP/*.osm.gz $TYPFILE
	else
		echo "INFO: options.args.$COUNTRY not found"
		java -Xmx${UMEM}M -jar $MKGMAPBIN --max-jobs --gmapsupp $OSMDATATMP/*.osm.gz $TYPFILE
	fi
}

# build a single garmin img file for the device
function build_device_file()
{
	echo "Building device file..."
	cd $STDMAPDIR/build

	if [ ! -d $STDMAPDIR/dist/$CDATE ]; then
		mkdir $STDMAPDIR/dist/$CDATE
	fi

	if [ ! -d $STDMAPDIR/dist/$CDATE/$MAPTYPE ]; then
		mkdir $STDMAPDIR/dist/$CDATE/$MAPTYPE
	fi

	cp gmapsupp.img $STDMAPDIR/dist/$CDATE/$MAPTYPE/gmapsupp_$COUNTRY.img
}

# updates osm data
function update_osm_data()
{
	echo "Updating OpenStreetMap data"
	cd $OSMDATADIR
	`$OSMDATASCRIPT $1`
}

function usage()
{
	cat << EOF
usage: $0 options country

OPTIONS:
	-c	Define the country
	-d	Download osm data
	-t	Select the map type
	-h	Show this message

EOF
}

echo "Starting build process at: `date`"

while getopts ht:dc: OPTION
do
	case $OPTION in
	c)
		COUNTRY=$OPTARG
		;;
	d)
		DLData="YES"
		;;
	t)
		MAPTYPE=$OPTARG
		;;
	h)
		usage
		exit 0
		;;
	\?)
		usage >&2
		exit 1
		;;
	esac
done

if [ -z "$COUNTRY" ]; then
	echo "Using default country (austria)"
	COUNTRY="austria"
else
	echo "Using country ($COUNTRY)"
fi

if [ "$DLData" = "YES" ]; then
		update_osm_data $COUNTRY
fi

if [ -z "$MAPTYPE" ]; then
	echo "Using default map type"
	MAPTYPE="std"
else
	if [ ! -d "osm-map-$MAPTYPE" ]; then
		echo "ERROR: Invalid map type ($MAPTYPE)"
		exit -1
	else
		echo "Using map type ($MAPTYPE)"
	fi
fi

STDMAPDIR="$OSMGARMINDIR/osm-map-$MAPTYPE"
OSMDATA="$OSMDATADIR/$COUNTRY.osm"

if [ ! -f "$OSMDATA" ]; then
	echo "INFO: No OSM Data file found staring download"
	update_osm_data $COUNTRY
fi

build_directories
check_apps
split_map
build_map
build_device_file

echo "Build process finished at: `date`"

cd $PWD

# vim:ts=4:sw=4: