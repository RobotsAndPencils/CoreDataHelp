//
//  CoreDataHelpError.m
//  CoreDataHelp
//
//  Created by Drew Crawford on 3/25/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "CoreDataHelpError.h"

@implementation CoreDataHelpError
+ (NSError *)errorWithCode:(CDHErrorCode)code format:(NSString *)format, ... {
    va_list args;
    va_start(args,format);
    NSString *errorStr = [[NSString alloc] initWithFormat:format arguments:args];
    va_end(args);
    return [NSError errorWithDomain:(NSString*) CDHErrorDomain code:code userInfo:[NSDictionary dictionaryWithObject:errorStr forKey:@"errorString"]];
}
@end
