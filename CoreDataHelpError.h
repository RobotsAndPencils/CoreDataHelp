//
//  CoreDataHelpError.h
//  CoreDataHelp
//
//  Created by Drew Crawford on 3/25/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
static const NSString *CDHErrorDomain = @"com.dca.CoreDataHelp";

@interface CoreDataHelpError : NSObject
typedef enum  {
    CDHErrorCodeNotSupported,
    CDHErrorCodeHTTP,
    CDHErrorCacheTooOld
} CDHErrorCode;


+(NSError*) errorWithCode:(CDHErrorCode) code format:(NSString*) format, ... NS_FORMAT_FUNCTION(2, 3);

@end
