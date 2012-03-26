//
//  DCACachingPolicy.m
//  CoreDataHelp
//
//  Created by Drew Crawford on 3/25/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "DCACachingPolicy.h"

@implementation DCACachingPolicy
@synthesize  cachingPolicy;

+ (DCACachingPolicy *)defaultCachingPolicy {
    DCACachingPolicy *policy = [[DCACachingPolicy alloc] init];
    policy.cachingPolicy = ^(NSDate *arbitraryDate) {
        if ([arbitraryDate isEqualToDate:[NSDate distantPast]]) return NO;
        return YES;
    };
    return policy;
}
@end
