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

/*we're doing a bit of a cheat here.  Rather than collapse the objects down to an NSManagedObjectID and use that as the reference,
 we're using an NSManagedObject* on the main thread as the reference.  This works because the main thread never goes out of scope.
 We wouldn't normally do this, but this inceptionNode stuff has the biggest overhead in the whole library and this cuts out 90+% of it.*/

-(NSArray*) portForeignObjects:(NSArray*) foreign toContext:(NSManagedObjectContext*) context withInceptionStack:(CoreDataStack*) stack{
    NSMutableArray *resultArr = [[NSMutableArray alloc] init];
    for(NSManagedObject<DCACacheable> *o in foreign) {
        NSManagedObject *objectOnMainThread = [stack objectOnMainThread:o];
        NSEntityDescription *entity = self.persistentStoreCoordinator.managedObjectModel.entitiesByName[objectOnMainThread.entity.name];
        NSManagedObject *object = [context objectWithID:[self newObjectIDForEntity:entity referenceObject:objectOnMainThread]];
    }
    return resultArr;

}

- (NSIncrementalStoreNode *)inceptionNodeForObjectID:(NSManagedObjectID *)oid withInceptionStack:(CoreDataStack*) stack {
    NSManagedObjectID *cachedObjectID = [self referenceObjectForObjectID:oid];
    
    NSMutableDictionary *cachedValues = [[NSMutableDictionary alloc] init];
    //[stack beginRogueThread];
    NSManagedObject *cachedObj = (NSManagedObject*) cachedObjectID;
        for (NSString *keyName in cachedObj.entity.attributesByName.allKeys) {
            if ([cachedObj valueForKey:keyName]) [cachedValues setObject:[cachedObj valueForKey:keyName] forKey:keyName];
        }
    
    //we should really clean this up... but it is infinitely faster if we don't.
    //[stack endRogueThread];
    
    return [[NSIncrementalStoreNode alloc] initWithObjectID:oid withValues:cachedValues version:1];
}
@end
