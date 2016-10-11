#!/bin/bash
# 
# Validate that everything builds as expected using CocoaPods.
#

bundle exec pod spec lint BNRCoreDataStack.podspec --verbose
