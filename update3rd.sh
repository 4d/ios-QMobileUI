#!/bin/bash
# checkout
carthage checkout --no-use-binaries

# Remove Reactivate extension from Moya

## Sources
rm -Rf Carthage/Checkouts/Reactive*
rm -Rf Carthage/Checkouts/Rx*

## Build artifact
rm -Rf Carthage/Build/Reactive*
rm -Rf Carthage/Build/Rx*

## Build scheme
rm -Rf Carthage/Checkouts/Moya/Moya.xcodeproj/xcshareddata/xcschemes/Reactive*
rm -Rf Carthage/Checkouts/Moya/Moya.xcodeproj/xcshareddata/xcschemes/Rx*

## In Cartfile (mandatory or carthage will try to compile or resolve dependencies)
sed -i '' '/Reactive/d' Cartfile.resolved
sed -i '' '/Rx/d' Cartfile.resolved

sed -i '' '/Reactive/d' Carthage/Checkouts/Moya/Cartfile.resolved
sed -i '' '/Rx/d' Carthage/Checkouts/Moya/Cartfile.resolved

sed -i '' '/Reactive/d' Carthage/Checkouts/Moya/Cartfile
sed -i '' '/Rx/d' Carthage/Checkouts/Moya/Cartfile

# build
carthage build --platform iOS # --cache-builds
