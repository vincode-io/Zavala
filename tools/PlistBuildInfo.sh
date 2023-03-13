#!/bin/sh

git_commit_hash=$(git log -1 --format="%h")
git_branch=$(git symbolic-ref --short -q HEAD)
git_tag=$(git describe --tags --exact-match 2>/dev/null)
build_time=$(date)

info_plist="${BUILT_PRODUCTS_DIR}/${EXECUTABLE_FOLDER_PATH}/BuildInfo.plist"
rm -f "${info_plist}"
/usr/libexec/PlistBuddy -c "${info_plist}"
/usr/libexec/PlistBuddy -c "Add :BuildTime string '${build_time}'" "${info_plist}"
/usr/libexec/PlistBuddy -c "Add :GitBranch string '${git_branch}'" "${info_plist}"
/usr/libexec/PlistBuddy -c "Add :GitTag string '${git_tag}'" "${info_plist}"
/usr/libexec/PlistBuddy -c "Add :GitCommitHash string '${git_commit_hash}'" "${info_plist}"

codesign --force --sign "${EXPANDED_CODE_SIGN_IDENTITY}" --preserve-metadata=identifier,entitlements --timestamp=none "${info_plist}"