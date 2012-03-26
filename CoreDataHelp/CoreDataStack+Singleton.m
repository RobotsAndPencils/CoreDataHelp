//
//  CoreDataStack+Singleton.m
//  mindfulmeals
//
//  Created by Bion Oren on 3/26/12.
//  Copyright (c) 2012 DrewCrawfordApps. All rights reserved.
//

#import "CoreDataStack+Singleton.h"

@implementation CoreDataStack (Singleton)

-(id)getOrCreateFromClass:(Class)type withInit:(modelInitBlock)block {
    DCAFetchRequest *request = [type performSelector:@selector(dcaFetchRequest)];
    NSError *err = nil;
    NSArray *ret = [self executeFetchRequest:request err:&err];
    if(ret.count > 0) {
        NSAssert(ret.count == 1, @"So much for a singleton pattern...");
        return [ret objectAtIndex:0];
    }
    return block([self insertNewObjectOfClass:type]);
}

@end