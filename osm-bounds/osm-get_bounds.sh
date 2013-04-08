#!/bin/sh
###############################################################################
#                                                                             #
# download the world bounds file from navmaps.eu                              #
#                                                                             #
# @version: 1.00                                                              #
# @author: Steiner Patrick <patrick@helmsdeep.at>                             #
# @date: 11.11.2012 11:24                                                     #
# License: GPL                                                                #
# http://www.fsf.org/licenses/gpl.htmlfree for all                            #
#                                                                             #
###############################################################################

VERSION="20121118"

CWD=`pwd`

if [ ! -x /usr/bin/curl ]; then
	echo "ERROR: curl not found."
	exit -1
fi

rm -rf bounds && mkdir bounds

cd bounds/

curl -O http://www.navmaps.eu/wanmil/bounds_${VERSION}.zip

unzip bounds_${VERSION}.zip

cd $CWD