//
//  DCAFetchRequest.m
//  CoreDataHelp
//
//  Created by Drew Crawford on 3/25/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "DCAFetchRequest.h"

@implementation DCAFetchRequest
@synthesize cachingPolicy;
+ (DCAFetchRequest *)fetchRequestWithEntityName:(NSString *)entityName {
    return [[DCAFetchRequest alloc] initWithEntityName:entityName];
}
+ (DCAFetchRequest*) fetchRequestWithEntityClass:(Class) entityClass {
    return [[DCAFetchRequest alloc] initWithEntityName:NSStringFromClass(entityClass)];
}

@end
