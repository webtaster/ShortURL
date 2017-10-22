#!/bin/bash

# Quick Bash script to implement a very simple short linking service.
# This is intended to aid understanding of short links, not as a 
# production service.
#
# Creates a short link (URL) that redirects to the given (usually much longer)
# URL.  Redirects are stored in a .htaccess file under the local Apache server.
#
# Usage: shorturl.sh <long URL>
#

# Base DNS name for short links.  Replace with your chosen domain name
BASEURL=jrt.dtdns.net

# .htaccess file in which redirect URLs will be stored. Replace with the
# path to your .htaccess file.
HTACCESS="/var/www/jrt.dtdns.net/.htaccess"

# Random increment range
INTERVAL=7


# Check argument, print usage if necessary
if [[ -z $1 ]]
then
   echo "Usage: shorturl.sh <target URL>" >&2
   exit 2
fi

# Check URL for validity
if [[ -z $(egrep -i ^https*:// <<< $1) ]]
then
   echo "Target URL appears to be malformed.  It must include http or https"
   exit 3
fi
target=$1

# Check existance of $HTACCESS file
if [[ ! -f $HTACCESS ]]
then
   echo "$HTACCESS does not exist, will be created"
   touch $HTACCESS
fi



# Obtain the id of the previously created link
lastid=$(egrep '^# [0-9]+' $HTACCESS | tail -1 | cut -d" " -f2)

# No previous link.  Start afresh.
if [[ -z $lastid ]]
then 
   echo "Unable to get id for last record from $HTACCESS.  Starting again from zero"
   lastid=0
fi

#echo lastid is $lastid


# Increment the last ID with a small number to get the new ID.
# $RANDOM introduces a little obscurity.  The 2 ensures that links are 
# seperated by at least one id number.
id=$(( $lastid + 2 + $RANDOM %$INTERVAL ))

#echo id is $id

#
# Convert the ID number to base 62.  Minimises link length.
# The sed ensures that numbers presented to bc do not include
# a leading zero (which bc would interpret as octal, and fail).
#
BASE62=($(echo {0..9} {a..z} {A..Z}))

link=$(
for i in $(bc <<< "obase=62; $id" | sed 's/ 0/ /g'); do
    echo -n ${BASE62[$i]}
done)

# Add redirect into .htaccess
echo "# $id" >> $HTACCESS
echo "RedirectMatch 301 /${link}$ $target" >> $HTACCESS


echo $BASEURL/$link

