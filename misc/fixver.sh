#! /bin/sh
#
#  Shell script to adjust the version numbers and dates in allegro.h,
#  dllver.rc, readme._tx, allegro._tx, makefile.ver, allegro-config.in,
#  allegro-config.qnx, modules.lst and allegro.spec .
#
#  Note: if you pass "datestamp" as the only argument, then the version
#  digits will remain unchanged and the comment will be set to the date.
#  This is in particular useful for making CVS snapshots.


if [ $# -lt 3 -o $# -gt 4 ]; then
   if [ $# -eq 1 -a $1 == "datestamp" ]; then
      ver=`grep "version=[0-9]" misc/allegro-config.in`
      major_num=`echo $ver | sed -e "s/version=\([0-9]\).*/\1/" -`
      sub_num=`echo $ver | sed -e "s/version=[0-9].\([0-9]\).*/\1/" -`
      wip_num=`echo $ver | sed -e "s/version=[0-9].[0-9].\([0-9]\).*/\1/" -`
      $0 $major_num $sub_num $wip_num `date '+%Y%m%d'`
      exit 0
   else
      echo "Usage: fixver major_num sub_num wip_num [comment]" 1>&2
      echo "   or: fixver datestamp" 1>&2
      echo "Example: fixver 3 9 1 WIP" 1>&2
      exit 1
   fi
fi

# get the version and date strings in a nice format
if [ $# -eq 3 ]; then
   verstr="$1.$2.$3"
else
   verstr="$1.$2.$3 ($4)"
fi

year=$(date +%Y)
month=$(date +%m)
day=$(date +%d)
datestr="$(date +%b) $day, $year"

# patch allegro/base.h
echo "s/\#define ALLEGRO_VERSION .*/\#define ALLEGRO_VERSION          $1/" > fixver.sed
echo "s/\#define ALLEGRO_SUB_VERSION .*/\#define ALLEGRO_SUB_VERSION      $2/" >> fixver.sed
echo "s/\#define ALLEGRO_WIP_VERSION .*/\#define ALLEGRO_WIP_VERSION      $3/" >> fixver.sed
echo "s/\#define ALLEGRO_VERSION_STR .*/\#define ALLEGRO_VERSION_STR      \"$verstr\"/" >> fixver.sed
echo "s/\#define ALLEGRO_DATE_STR .*/\#define ALLEGRO_DATE_STR         \"$year\"/" >> fixver.sed
echo "s/\#define ALLEGRO_DATE .*/\#define ALLEGRO_DATE             $year$month$day    \/\* yyyymmdd \*\//" >> fixver.sed

echo "Patching include/allegro/base.h..."
cp include/allegro/base.h fixver.tmp
sed -f fixver.sed fixver.tmp > include/allegro/base.h

echo "Patching src/win/dllver.rc..."
cat > src/win/dllver.rc << END_OF_DLLVER
// Windows resource file for the version info sheet
// generated by misc/fixver.sh

#include <windows.h>


1 VERSIONINFO 
FILEVERSION $1, $2, $3, 0
PRODUCTVERSION $1, $2, $3, 0
FILEOS VOS__WINDOWS32
FILETYPE VFT_DLL
{
   BLOCK "StringFileInfo"
   {
      BLOCK "040904E4"
      {
         VALUE "Comments", "Please see AUTHORS for a list of contributors\000"
         VALUE "CompanyName", "Allegro Developers\000\000"
         VALUE "FileDescription", "Allegro\000"
         VALUE "FileVersion", "$verstr\000"
         VALUE "InternalName", "ALLEG$1$2\000"
         VALUE "LegalCopyright", "Copyright � 1994-$year Allegro Developers\000\000"
         VALUE "OriginalFilename", "ALLEG$1$2.DLL\000"
         VALUE "ProductName", "Allegro\000"
         VALUE "ProductVersion", "$verstr\000"
      }
   }

   BLOCK "VarFileInfo"
   {
      VALUE "Translation", 0x0809, 1252
   }
}

END_OF_DLLVER

# patch readme._tx
echo "s/\\_\/__\/     Version .*/\\_\/__\/     Version $verstr/" > fixver.sed
echo "s/By Shawn Hargreaves, .*\./By Shawn Hargreaves, $datestr\./" >> fixver.sed

echo "Patching readme._tx..."
cp docs/src/readme._tx fixver.tmp
sed -f fixver.sed fixver.tmp > docs/src/readme._tx

# patch allegro._tx
echo "s/@manh=\"version [^\"]*\"/@manh=\"version $verstr\"/" >> fixver.sed

echo "Patching docs/src/allegro._tx..."
cp docs/src/allegro._tx fixver.tmp
sed -f fixver.sed fixver.tmp > docs/src/allegro._tx

# patch makefile.ver
echo "s/LIBRARY_VERSION = .*/LIBRARY_VERSION = $1$2/" > fixver.sed
echo "s/shared_version = .*/shared_version = $1.$2.$3/" >> fixver.sed
echo "s/shared_major_minor = .*/shared_major_minor = $1.$2/" >> fixver.sed

echo "Patching makefile.ver..."
cp makefile.ver fixver.tmp
sed -f fixver.sed fixver.tmp > makefile.ver

# patch allegro-config.in, allegro-config.qnx
echo "s/version=[0-9].*/version=$1.$2.$3/" >> fixver.sed

echo "Patching misc/allegro-config.in..."
cp misc/allegro-config.in fixver.tmp
sed -f fixver.sed fixver.tmp > misc/allegro-config.in

echo "Patching misc/allegro-config-qnx.sh..."
cp misc/allegro-config-qnx.sh fixver.tmp
sed -f fixver.sed fixver.tmp > misc/allegro-config-qnx.sh

# patch the spec file
echo "Patching misc/allegro.spec..."
cp misc/allegro.spec fixver.tmp
sed -e "s/^Version: .*/Version: $1.$2.$3/" fixver.tmp > misc/allegro.spec

# patch the OSX package readme
echo "Patching misc/pkgreadme._tx..."
cp misc/pkgreadme._tx fixver.tmp
sed -f fixver.sed fixver.tmp > misc/pkgreadme._tx

# clean up after ourselves
rm fixver.sed fixver.tmp

echo "Done!"
