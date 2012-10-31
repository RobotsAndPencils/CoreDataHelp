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

- (void)fault:(BOOL)areYouPositiveThereAreNoChanges {
    assert(areYouPositiveThereAreNoChanges);
    [self.managedObjectContext refreshObject:self mergeChanges:!areYouPositiveThereAreNoChanges];
    NSAssert(self.isFault, @"Didn't turn into fault?");
}


+ (id)prototype {
    NSEntityDescription *poorDescription = [[[NSManagedObjectModel defaultModel] entitiesByName] objectForKey:NSStringFromClass([self class])];
    NSAssert(poorDescription,@"No such model %@",NSStringFromClass([self class]));
    
    return [[NSManagedObject alloc] initWithEntity:poorDescription insertIntoManagedObjectContext:nil];
}

- (void)assertThreading {
    if (!self.managedObjectContext) {
        NSLog(@"WARNING:  This is odd.  The object you're asserting is either being accessed in violation of the thread rules, or is a prototype.  We cannot tell which. %@",self);
        
    }
}

@end
