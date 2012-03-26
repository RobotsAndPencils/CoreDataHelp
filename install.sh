#!/bin/bash
GIT_URL=git@github.com:drewcrawford/CoreDataHelp.git
PROJECT_NAME=CoreDataHelp.xcodeproj
PACKAGE_NAME=CoreDataHelp
TARGET_NAME=$PACKAGE_NAME
STATIC_LIB=lib${PACKAGE_NAME}.a
PATH_TO_PROJECT=ext/"$PACKAGE_NAME"/"$PROJECT_NAME"
hash xsplice.rb 2>&- || { echo >&2 "I require xsplice.rb but it's not installed.  Grab it from https://github.com/drewcrawford/xsplice"; exit 1; }

echo "To which xcodeproject should I install this package?"
read INSTALL_XCODEPROJ
#INSTALL_XCODEPROJ="_iOS/GreenRoutine.xcodeproj"
INSTALL_XCODEPROJ_DIR=`dirname "${INSTALL_XCODEPROJ}"`
echo "To which target should I install this package?"
read INSTALL_TARGET
#INSTALL_TARGET="GreenRoutine"

mkdir "$INSTALL_XCODEPROJ_DIR"/ext
git submodule add "$GIT_URL" "$INSTALL_XCODEPROJ_DIR"/ext/"$PACKAGE_NAME"
git submodule init



xsplice.rb addproj --xcodeproj="$INSTALL_XCODEPROJ" --addproj=$PATH_TO_PROJECT
pushd "$INSTALL_XCODEPROJ_DIR" && xcodebuild clean && popd
xsplice.rb adddep --xcodeproj="$INSTALL_XCODEPROJ" --target="$INSTALL_TARGET" --foreignxcodeproj="$PROJECT_NAME" --foreigntarget="$TARGET_NAME"
pushd "$INSTALL_XCODEPROJ_DIR" && xcodebuild clean && popd

#setup fake framework build settings
xsplice.rb setsettingarray --xcodeproj="$INSTALL_XCODEPROJ" --target="$INSTALL_TARGET" --setting_name="OTHER_LDFLAGS" --setting_value="-ObjC"

#autoconfig
xsplice.rb autoconfig --xcodeproj="$INSTALL_XCODEPROJ"

#force a reload
killall 'Xcode'; open "$INSTALL_XCODEPROJ" && sleep 10 && killall 'Xcode'


#link
echo "linking to ${STATIC_LIB}"
xsplice.rb linkstaticlib --xcodeproj="$INSTALL_XCODEPROJ" --staticlib=${STATIC_LIB} --target="$INSTALL_TARGET"
killall 'Xcode'; open "$INSTALL_XCODEPROJ" && sleep 10 && killall 'Xcode'
