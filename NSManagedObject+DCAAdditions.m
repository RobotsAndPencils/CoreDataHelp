//
//  NSManagedObject+DCAAdditions.m
//  CoreDataHelp
//
//  Created by Drew Crawford on 3/25/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "NSManagedObject+DCAAdditions.h"
#import "NSManagedObjectModel+CDHAdditions.h"

@implementation NSManagedObject (DCAAdditions)
+ (DCAFetchRequest *)dcaFetchRequest {
    return [DCAFetchRequest fetchRequestWithEntityClass:[self class]];
}
+ (NSString *)entityName {
    return NSStringFromClass([self class]);
}


+ (id)prototype {
    NSEntityDescription *poorDescription = [[[NSManagedObjectModel defaultModel] entitiesByName] objectForKey:NSStringFromClass([self class])];
    NSAssert(poorDescription,@"No such model %@",NSStringFromClass([self class]));
    
    return [[NSManagedObject alloc] initWithEntity:poorDescription insertIntoManagedObjectContext:nil];
}

@end
