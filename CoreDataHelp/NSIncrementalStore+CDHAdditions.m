//
//  NSIncrementalStore+CDHAdditions.m
//  CoreDataHelp
//
//  Created by Andrew Crawford on 5/8/12.
//  Copyright (c) 2012 Andrew Crawford. All rights reserved.
//

#import "NSIncrementalStore+CDHAdditions.h"
#import "DCACacheable.h"
#import "CoreDataStack.h"
@implementation NSIncrementalStore (CDHAdditions)
-(NSArray*) portForeignObjects:(NSArray*) foreign toContext:(NSManagedObjectContext*) context{
    NSMutableArray *resultArr = [[NSMutableArray alloc] init];
    for(NSManagedObject<DCACacheable> *o in foreign) {
        [resultArr addObject:[context objectWithID:[self newObjectIDForEntity:o.entity referenceObject:o.objectID]]];
    }
    return resultArr;

}

- (NSIncrementalStoreNode *)inceptionNodeForObjectID:(NSManagedObjectID *)oid withInceptionStack:(CoreDataStack*) stack {
    NSManagedObjectID *cachedObjectID = [self referenceObjectForObjectID:oid];
    
    NSMutableDictionary *cachedValues = [[NSMutableDictionary alloc] init];
    [stack beginRogueThread];
        NSManagedObject *cachedObj = [stack objectOnCurrentThreadFromID:cachedObjectID];
        for (NSString *keyName in cachedObj.entity.attributesByName.allKeys) {
            if ([cachedObj valueForKey:keyName]) [cachedValues setObject:[cachedObj valueForKey:keyName] forKey:keyName];
        }
    
    //we should really clean this up... but it is infinitely faster if we don't.
    //[stack endRogueThread];
    
    return [[NSIncrementalStoreNode alloc] initWithObjectID:oid withValues:cachedValues version:1];
}
@end
