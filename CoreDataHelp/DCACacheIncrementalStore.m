//
//  DCAManagedObjectContextIncrementalStore.m
//  CoreDataHelp
//
//  Created by Drew Crawford on 3/25/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "DCACacheIncrementalStore.h"
#import <CoreData/CoreData.h>
#import "CoreDataHelp.h"
#import "CoreDataHelpError.h"
#import "CoreDataStack.h"
#import "DCAFetchRequestModel.h"
#import "NSManagedObject+DCAAdditions.h"
#import "DCACacheable.h"
@implementation DCACacheIncrementalStore {
    CoreDataStack *dataSource;
}
+ (NSString*) storeUUID {
    return @"DCACacheIncrementalStoreUUID";
}
+ (NSString*) storeType {
    return @"DCACacheIncrementalStore";
}

- (id)initWithPersistentStoreCoordinator:(NSPersistentStoreCoordinator *)root configurationName:(NSString *)name URL:(NSURL *)url options:(NSDictionary *)options {
    if (self = [super initWithPersistentStoreCoordinator:root configurationName:name URL:url options:options]) {
        dataSource = [CoreDataStack inMemoryStack_caching];
    }
    return self;
}

- (BOOL)loadMetadata:(NSError *__autoreleasing *)error {
    NSDictionary *metadata = [NSDictionary dictionaryWithObjectsAndKeys:[DCACacheIncrementalStore storeType],NSStoreTypeKey,[DCACacheIncrementalStore storeUUID],NSStoreUUIDKey, nil];
        [self setMetadata:metadata];
    return YES;
}

+(NSPersistentStore*) installInCoordinator:(NSPersistentStoreCoordinator*) coordinator {
    [NSPersistentStoreCoordinator registerStoreClass:[self class] forStoreType:[DCACacheIncrementalStore storeType]];
    NSError *err = nil;
    NSPersistentStore *store = [coordinator addPersistentStoreWithType:[DCACacheIncrementalStore storeType] configuration:nil URL:nil options:nil error:&err];
    if (!store) {
        NSLog(@"err %@",err);
        abort();
    }
    return store;
}
- (id) executeSaveRequest:(NSSaveChangesRequest*) request withContext:(NSManagedObjectContext*) context error:(NSError *__autoreleasing *) error {
    NSAssert(request.deletedObjects.count==0,@"Delete not supported.");
    NSAssert(request.updatedObjects.count==0,@"Updated objects not supported.");
    for(NSManagedObject *object in request.insertedObjects) {
        NSManagedObject *cachedObj = [dataSource insertNewObjectOfClass:[object class]];
        //loop over properties
        for(NSString *attributeKey in cachedObj.entity.attributesByName.allKeys) {
            [cachedObj setValue:[object valueForKey:attributeKey] forKey:attributeKey];
        }
        NSAssert(cachedObj.entity.relationshipsByName.count==0,@"Relationship caching not currently supported.");
        
    }
    if (![dataSource save:error]) return nil;
    return [NSArray array];
}
- (id)executeRequest:(NSPersistentStoreRequest *)request withContext:(NSManagedObjectContext *)context error:(NSError *__autoreleasing *)error {
    NSAssert(error,@"An error value is required.");
    if ([request isKindOfClass:[NSSaveChangesRequest class]]) {
        return [self executeSaveRequest:(NSSaveChangesRequest*) request withContext:context error:error];
    }
    NSFetchRequest *fRequest = [dataSource portFetchRequest:(DCAFetchRequest*) request];
    id result = [dataSource executeFetchRequest:(NSFetchRequest*) fRequest err:error];
    NSFetchRequest *inceptionRequest = [DCAFetchRequest fetchRequestWithEntityClass:[DCAFetchRequestModel class]];
    NSArray *previousRequest = [dataSource executeFetchRequest:inceptionRequest err:error];
    if (!previousRequest) {
        WORK_AROUND_RDAR_10732696(*error);
        return nil;
    }
    NSDate *arbitraryDate = nil;
    if (previousRequest.count==0) arbitraryDate = [NSDate distantPast];
    else arbitraryDate = [NSDate date]; 
#warning that wasn't right at all
    if ([DCACachingPolicy defaultCachingPolicy].cachingPolicy(arbitraryDate)) return result;
    else {
        *error = [CoreDataHelpError errorWithCode:CDHErrorCacheTooOld format:@"Cache is too old"];
        WORK_AROUND_RDAR_10732696(*error);
        return nil;
    }
    
}

- (NSArray *)obtainPermanentIDsForObjects:(NSArray *)array error:(NSError *__autoreleasing *)error {
    NSMutableArray *idArray = [[NSMutableArray alloc] initWithCapacity:array.count];
    for (NSManagedObject <DCACacheable>  *object in array) {
        [idArray addObject: [self newObjectIDForEntity:[object entity] referenceObject:[object uniqueID]]];
        
    }
    return idArray;
}
- (void)queryServed:(DCAFetchRequest *)fetchRequest {
    DCAFetchRequestModel *model = [dataSource insertNewObjectOfClass:[DCAFetchRequestModel class]];
    model.fetchRequest = (DCAFetchRequest*) fetchRequest;
    NSError *err = nil;
    [dataSource save:&err];
    
    NSAssert(!err,@"Err was %@",err);
}

@end
