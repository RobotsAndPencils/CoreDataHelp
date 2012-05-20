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
#import "NSIncrementalStore+CDHAdditions.h"
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
    
    ///////////////////////////////////////////////////////////////////////
    [dataSource beginRogueThread];
    for(NSManagedObject<DCACacheable> *object in request.insertedObjects) {
        NSManagedObject *cachedObj = [dataSource insertNewObjectOfClass:[object class]];
        //loop over properties
        for(NSString *attributeKey in object.entity.attributesByName.allKeys) {
            [cachedObj setValue:[object valueForKey:attributeKey] forKey:attributeKey];
        }
        
        [cachedObj setValue:[object uniqueID] forKey:INTERNAL_CACHING_KEY];
        NSAssert(cachedObj.entity.relationshipsByName.count==0,@"Relationship caching not currently supported.");
        
    }
    [dataSource endRogueThread];
    //////////////////////////////////////////////////////////////////////////
    return [NSArray array];
}
- (DCACachingPolicy*) effectivePolicy:(DCAFetchRequest*) any {
    if (any.cachingPolicy) return any.cachingPolicy;
    return [DCACachingPolicy defaultCachingPolicy];
}
- (id)executeRequest:(NSPersistentStoreRequest *)request withContext:(NSManagedObjectContext *)context error:(NSError *__autoreleasing *)error {
    NSAssert(error,@"An error value is required.");
    if ([request isKindOfClass:[NSSaveChangesRequest class]]) {
        return [self executeSaveRequest:(NSSaveChangesRequest*) request withContext:context error:error];
    }
    NSFetchRequest *fRequest = [dataSource portFetchRequest:(DCAFetchRequest*) request];
    NSFetchRequest *inceptionRequest = [DCAFetchRequest fetchRequestWithEntityClass:[DCAFetchRequestModel class]];
    inceptionRequest.predicate = [NSPredicate predicateWithFormat:@"fetchRequest == %@",fRequest];
    
    __block id ultimate_result = nil;
    [dataSource backgroundOperationSync:^{
        
        //oddly, we must try to fetch the query first, before verifying that it's been served.
        //there's a bug inside [NSFetchRequest isEqual:] such that fetch requests with a entityName (only)
        //cannot be compared to fetch requests with an entity.  This line ensures that an entity exists.
        id result = [dataSource executeFetchRequest:(NSFetchRequest*) fRequest err:error];

        
        NSArray *previousRequest = [dataSource executeFetchRequest:inceptionRequest err:error];
        if (!previousRequest) {
            WORK_AROUND_RDAR_10732696(*error);
            ultimate_result = nil;
            return;
        }
        NSDate *arbitraryDate = nil;
        if (previousRequest.count==0) arbitraryDate = [NSDate distantPast];
        else arbitraryDate = [NSDate date]; 
#warning that wasn't right at all //___INTELLIGENCE_DAMPENING_CORE_WHEATLEY
        if ([self effectivePolicy:fRequest].cachingPolicy(arbitraryDate)){
            if (result) result = [self portForeignObjects:result toContext:context];
            if (result) ultimate_result = result;
            return;
        }
        else {
            *error = [CoreDataHelpError errorWithCode:CDHErrorCacheTooOld format:@"Cache is too old"];
            WORK_AROUND_RDAR_10732696(*error);
            ultimate_result = nil;
            return;
        }
    }];
    
    return ultimate_result;
    
}

- (NSArray *)obtainPermanentIDsForObjects:(NSArray *)array error:(NSError *__autoreleasing *)error {
    NSMutableArray *idArray = [[NSMutableArray alloc] initWithCapacity:array.count];
    for (NSManagedObject <DCACacheable>  *object in array) {
        [idArray addObject: [self newObjectIDForEntity:[object entity] referenceObject:[object uniqueID]]];
        
    }
    return idArray;
}

- (BOOL) multipleObjectsMatchingCacheable:(NSManagedObject<DCACacheable>*) cacheable {
    //NSAssert([DCAFetchRequest fetchRequestWithEntityClass:[cacheable class]].entity,@"Can't get a fetch request for %@",NSStringFromClass([DCAFetchRequest class]));
    __block int count = -1;
    [dataSource backgroundOperationSync:^{
        DCAFetchRequest *fetchRequest = [DCAFetchRequest fetchRequestWithEntityClass:[cacheable class]];
        
        NSString *format = [NSString stringWithFormat:@"%@ == %%@",INTERNAL_CACHING_KEY];
        fetchRequest.predicate = [NSPredicate predicateWithFormat:format,cacheable.uniqueID];
        fetchRequest.cachingPolicy = [DCACachingPolicy cachingPolicyWithBlock:^BOOL(NSDate *arbitraryDate) {
            return YES;
        }];
        NSError *err = nil;
        NSArray *arr = [dataSource executeFetchRequest:fetchRequest err:&err];
        if (!arr) {
            NSLog(@"error: %@",err);
        }
        count = arr.count;
    }];
    return count;
}

- (NSIncrementalStoreNode *)newValuesForObjectWithID:(NSManagedObjectID *)objectID withContext:(NSManagedObjectContext *)context error:(NSError *__autoreleasing *)error {
    return [self inceptionNodeForObjectID:objectID withInceptionStack:dataSource];
}
- (void)queryServed:(DCAFetchRequest *)fetchRequest {
    [dataSource backgroundOperationSync:^{

        
        
        DCAFetchRequestModel *model = [dataSource insertNewObjectOfClass:[DCAFetchRequestModel class]];
        model.fetchRequest = (DCAFetchRequest*) fetchRequest;
        NSError *err = nil;
        NSAssert(!err,@"Err was %@",err);
    }];
    
}

@end
