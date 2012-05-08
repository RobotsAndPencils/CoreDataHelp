//
//  NSIncrementalStore+CDHAdditions.m
//  CoreDataHelp
//
//  Created by Andrew Crawford on 5/8/12.
//  Copyright (c) 2012 Andrew Crawford. All rights reserved.
//

#import "NSIncrementalStore+CDHAdditions.h"
#import "DCACacheable.h"
@implementation NSIncrementalStore (CDHAdditions)
-(NSArray*) portForeignObjects:(NSArray*) foreign toContext:(NSManagedObjectContext*) context{
    NSMutableArray *resultArr = [[NSMutableArray alloc] init];
    for(NSManagedObject<DCACacheable> *o in foreign) {
        [resultArr addObject:[context objectWithID:[self newObjectIDForEntity:o.entity referenceObject:o]]];
    }
    return resultArr;

}

- (NSIncrementalStoreNode *)inceptionNodeForObjectID:(NSManagedObjectID *)oid {
    NSManagedObject *cachedObj = [self referenceObjectForObjectID:oid];
    NSMutableDictionary *cachedValues = [[NSMutableDictionary alloc] init];
    for (NSString *keyName in cachedObj.entity.attributesByName.allKeys) {
        if ([cachedObj valueForKey:keyName]) [cachedValues setObject:[cachedObj valueForKey:keyName] forKey:keyName];
    }
    return [[NSIncrementalStoreNode alloc] initWithObjectID:oid withValues:cachedValues version:1];
}
@end
