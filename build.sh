#!/bin/sh
set -e

if [ "$DMD" = "" ]; then
	if [ ! "$DC" = "" ]; then # backwards compatibility with DC
		DMD=$DC
	else
		command -v gdmd >/dev/null 2>&1 && DMD=gdmd || true
		command -v ldmd2 >/dev/null 2>&1 && DMD=ldmd2 || true
		command -v dmd >/dev/null 2>&1 && DMD=dmd || true
	fi
fi

if [ "$DMD" = "" ]; then
	echo >&2 "Failed to detect D compiler. Use DMD=... to set a dmd compatible binary manually."
	exit 1
fi

# link against libcurl
LIBS=`pkg-config --libs libcurl 2>/dev/null || echo "-lcurl"`

# fix for modern GCC versions with --as-needed by default
if [ "$DMD" = "dmd" ]; then
	if [ `uname` = "Linux" ]; then
		LIBS="-l:libphobos2.a $LIBS"
	else
		LIBS="-lphobos2 $LIBS"
	fi
elif [ "$DMD" = "ldmd2" ]; then
	LIBS="-lphobos2-ldc $LIBS"
fi

# adjust linker flags for dmd command line
LIBS=`echo "$LIBS" | sed 's/^-L/-L-L/; s/ -L/ -L-L/g; s/^-l/-L-l/; s/ -l/ -L-l/g'`

echo Generating version file...
GITVER=$(git describe) || GITVER=unknown
echo "module dub.version_;" > source/dub/version_.d
echo "enum dubVersion = \"$GITVER\";" >> source/dub/version_.d
echo "enum initialCompilerBinary = \"$DMD\";" >> source/dub/version_.d


echo Running $DMD...
$DMD -ofbin/dub-data-hack -w -version=DubUseCurl -Isource $* $LIBS @build-files.txt
echo DUB has been built as bin/dub.
echo
echo You may want to run
echo sudo ln -s $(pwd)/bin/dub-data-hack /usr/local/bin
echo now.
