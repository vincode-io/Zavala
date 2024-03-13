#!/bin/sh

export ARCHIVE_PATH="../build/zavala.xcarchive"
export EXPORT_PATH="../build/zavala.export"

xcodebuild -project "../Zavala.xcodeproj" -scheme Zavala -archivePath "$ARCHIVE_PATH" archive

xcodebuild -exportArchive -exportOptionsPlist "exportOptions.plist" -archivePath "$ARCHIVE_PATH" -exportPath "$EXPORT_PATH" 

sudo cp -Rf $EXPORT_PATH/Zavala.app /Applications
rm -rf $ARCHIVE_PATH
rm -rf $EXPORT_PATH
