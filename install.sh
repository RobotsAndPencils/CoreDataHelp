#!/bin/bash
GIT_URL=git@github.com:drewcrawford/CoreDataHelp.git
PROJECT_NAME=CoreDataHelp.xcodeproj
PACKAGE_NAME=CoreDataHelp
TARGET_NAME=$PACKAGE_NAME
STATIC_LIB=lib${PACKAGE_NAME}.a
PATH_TO_PACKAGE=ext/"$PACKAGE_NAME"/
PATH_TO_PROJECT=ext/"$PATH_TO_PACKAGE"/"$PROJECT_NAME"

hash xsplice.rb 2>&- || { echo >&2 "I require xsplice.rb but it's not installed.  Grab it from https://github.com/drewcrawford/xsplice"; exit 1; }
mkdir ext
git submodule add "$GIT_URL" ext/"$PACKAGE_NAME"
git submodule init
echo "To which xcodeproject should I install this package?"
read INSTALL_XCODEPROJ

echo "To which target should I install this package?"
read INSTALL_TARGET
xsplice.rb addproj --xcodeproj="$INSTALL_XCODEPROJ" --addproj=$PATH_TO_PROJECT
xcodebuild clean
xsplice.rb adddep --xcodeproj="$INSTALL_XCODEPROJ" --target="$INSTALL_TARGET" --foreignxcodeproj="$PROJECT_NAME" --foreigntarget="$TARGET_NAME"
xcodebuild clean

#setup fake framework build settings
xsplice.rb setsettingarray --xcodeproj="$INSTALL_XCODEPROJ" --target="$INSTALL_TARGET" --setting_name="OTHER_LDFLAGS" --setting_value="-ObjC"

#autoconfig
xsplice.rb autoconfig --xcodeproj="$INSTALL_XCODEPROJ"

#link
#xsplice.rb linkstaticlib --xcodeproj="$PROJECT_NAME" --staticlib=${STATIC_LIB} --target="$TARGET_NAME"

#copy headers
mkdir ext/Headers
HEADER_DIR=ext/Headers/CoreDataHelp
mkdir $HEADER_DIR
cp "$PATH_TO_PACKAGE"/CoreDataHelp/CoreDataHelp.h $HEADER_DIR/

