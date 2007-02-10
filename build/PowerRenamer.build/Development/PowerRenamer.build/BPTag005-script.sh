#!/bin/sh
if [ "$BUILD_STYLE" = 'Deployment' ] ; then
helpdir="$OBJROOT/$TARGET_NAME.app/Contents/Resources/$TARGET_NAME Help/"
mkdir -p "$helpdir"
manual_path='/Users/tkurita/Factories/Websites/scriptfactory folder/scriptfactory/ScriptGallery/FinderScripts/PowerRenamer/manual/index.html'
sitetears_path='/Users/tkurita/Factories/Perl factory/ProjectsX/SiteTears/SiteTears.pl'
perl "$sitetears_path" "$manual_path" "$helpdir/index.html"
open -a '/Developer/Documentation/Apple Help/Apple Help Indexing Tool.app' "$helpdir"
fi
