//
//  NSManagedObject+DCAAdditions.m
//  CoreDataHelp
//
//  Created by Drew Crawford on 3/25/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "NSManagedObject+DCAAdditions.h"

@implementation NSManagedObject (DCAAdditions)
+ (DCAFetchRequest *)dcaFetchRequest {
    return [DCAFetchRequest fetchRequestWithEntityClass:[self class]];
}
+ (NSString *)entityName {
    return NSStringFromClass([self class]);
}

@end
