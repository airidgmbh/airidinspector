//
//  ZipArchive.h
//  ZipArchive
//
//  Created by Serhii Mumriak on 12/1/15.
//  Copyright © 2015 smumryak. All rights reserved.
//

#import <Foundation/Foundation.h>

//! Project version number for ZipArchive.
FOUNDATION_EXPORT double ZipArchiveVersionNumber;

//! Project version string for ZipArchive.
FOUNDATION_EXPORT const unsigned char ZipArchiveVersionString[];

// In this header, you should import all the public headers of your framework using statements like #import <ZipArchive/SSZipArchive.h>

// NOTE: When ZipArchive is built as part of pods-free AirIDDriver , it is packaged as "ZipArchive".
// Then, when driver tests are compiled with pods, it sets `COCOAPODS` flag and Xcode expects to
// find `<SSZipArchive/SSZipCommon.h>` and fails. Therefore lines below are commented out.

//#if COCOAPODS
//#import <SSZipArchive/SSZipArchive.h>
//#else
#import <ZipArchive/SSZipArchive.h>
//#endif
