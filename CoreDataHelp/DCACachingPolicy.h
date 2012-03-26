//
//  DCACachingPolicy.h
//  CoreDataHelp
//
//  Created by Drew Crawford on 3/25/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface DCACachingPolicy : NSObject

//this is a placeholder typedef
typedef BOOL(^isResultAcceptable)(NSDate *arbitraryDate);

+(DCACachingPolicy*) defaultCachingPolicy;


@property (copy) isResultAcceptable cachingPolicy;

@end
