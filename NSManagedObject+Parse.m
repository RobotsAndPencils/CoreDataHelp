//
//  NSManagedObject+Parse.m
//  CarAccidentHelp
//
//  Created by Drew Crawford on 12/29/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "NSManagedObject+Parse.h"
#import <Parse/Parse.h>
#import "CoreDataHelp.h"
@implementation NSManagedObject (Parse)
- (PFObject*) _getServerPFObject {
    PFQuery *query = [PFQuery queryWithClassName:NSStringFromClass([self class])];
    NSString *coreDataID = [[[self objectID] URIRepresentation] description];
    [query whereKey:@"coreDataID" equalTo:coreDataID];
    NSArray *resultArray = [query findObjects];
    NSAssert(resultArray.count<=1, @"Too many results: %@", resultArray);
    if (resultArray.count==0) return nil;
    return [resultArray objectAtIndex:0];
}
- (void) _setPropertiesOn:(PFObject*) p {
    NSDictionary *myDict =  [[self entity] attributesByName];
    for (id key in [myDict allKeys]) {
        id val = [self valueForKey:key];
        [p setObject:val forKey:key];
    }
    NSString *coreDataID = [[[self objectID] URIRepresentation] description];
    [p setObject:coreDataID forKey:@"coreDataID"];

}
- (PFObject*) _createNewObject {
    PFObject *newObj = [PFObject objectWithClassName:NSStringFromClass([self class])];
    [self _setPropertiesOn:newObj];
    return newObj;
}

- (void) sync {
    PFObject *serverObj = [self _getServerPFObject];
    if (!serverObj) {
        serverObj = [self _createNewObject];
    }
    [self _setPropertiesOn:serverObj];
    [serverObj save];
}

+ (void) syncAll {
    NSArray *objs = [CoreDataHelp fetchAllObjectsWithClass:[self class] error:nil];
    for (id obj in objs) {
        [obj sync];
    }
}

@end
