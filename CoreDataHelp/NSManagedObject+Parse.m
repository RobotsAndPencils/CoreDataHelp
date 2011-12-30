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
- (NSString*) coreDataID {
    return [[[self objectID] URIRepresentation] description];

}
- (PFObject*) _getServerPFObject {
    PFQuery *query = [PFQuery queryWithClassName:NSStringFromClass([self class])];
    [query whereKey:@"coreDataID" equalTo:self.coreDataID];
    NSArray *resultArray = [query findObjects];
    NSAssert(resultArray.count<=1, @"Too many results: %@", resultArray);
    if (resultArray.count==0) return nil;
    return [resultArray objectAtIndex:0];
}
- (void) _setPropertiesOn:(PFObject*) p {
    NSDictionary *myDict =  [[self entity] attributesByName];
    for (id key in [myDict allKeys]) {
        id val = [self valueForKey:key];
        if (!val) val = [NSNull null]; //pfobject doens't like null
        if ([val isKindOfClass:[UIImage class]]) {
            NSData *imageData = UIImageJPEGRepresentation(val, 0.8);
            PFFile *file = [PFFile fileWithName:@"key.jpg" data:imageData];
            [file save];
            val = file;
        }
        NSLog(@"%@=%@",key,val);

        [p setObject:val forKey:key];
    }
    myDict = [[self entity] relationshipsByName];
    for (id key in [myDict allKeys]) {
        NSMutableString *valRef = [NSMutableString string];
        NSManagedObject *remote = [self valueForKey:key];
        if ([remote isKindOfClass:[NSSet class]]) {
            NSSet *remote_s = (NSSet*) remote;
            for (NSManagedObject *obj in remote_s) {
                [valRef appendFormat:@"%@,",obj.coreDataID];
            }
        }
        else [valRef appendFormat:@"%@",remote.coreDataID];
        NSLog(@"%@=%@",key,valRef);
        [p setObject:valRef forKey:key];
    }
    [p setObject:self.coreDataID forKey:@"coreDataID"];

}
- (PFObject*) _createNewObject {
    PFObject *newObj = [PFObject objectWithClassName:NSStringFromClass([self class])];
    [self _setPropertiesOn:newObj];
    return newObj;
}

- (void) sync {
    [CoreDataHelp write];
    NSLog(@"Syncing %@",self);
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
