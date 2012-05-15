//
//  LightweightCachingIncrementalStore.m
//  CoreDataHelp
//
//  Created by Drew Crawford on 3/25/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "DCACacheFirstIncrementalStore.h"
#import "DCACacheIncrementalStore.h"
#import "CoreDataStack.h"
#import "CoreDataHelp.h"
#import "NSIncrementalStore+CDHAdditions.h"
@implementation DCACacheFirstIncrementalStore {

    
    
}
@synthesize defaultCachingPolicy;
@synthesize cacheStack;
+ (NSString *)storeType {
    NSLog(@"This is an abstract class.  You must override the store type.");
    abort();
}
+ (NSString*) storeUUID {
    NSLog(@"This is an abstract class.  You must override the store UUID.");
    abort();
}

- (id)initWithPersistentStoreCoordinator:(NSPersistentStoreCoordinator *)root configurationName:(NSString *)name URL:(NSURL *)url options:(NSDictionary *)options {
    if (self = [super initWithPersistentStoreCoordinator:root configurationName:name URL:url options:options]) {
        cacheStack = [CoreDataStack cachingStack];
        defaultCachingPolicy = [DCACachingPolicy defaultCachingPolicy];
        
    }
    return self;
}

- (BOOL)loadMetadata:(NSError *__autoreleasing *)error {
    [self setMetadata:[NSDictionary dictionaryWithObjectsAndKeys:[[self class] storeType],NSStoreTypeKey,[[self class] storeUUID],NSStoreUUIDKey, nil]];
    return YES;
}

-(id)executeRequest:(NSPersistentStoreRequest *)request withContext:(NSManagedObjectContext *)context error:(NSError *__autoreleasing *)error {
    NSAssert(error,@"Must pass in an error.");
    NSAssert([request isKindOfClass:[NSFetchRequest class]],@"Only fetch requests currently supported.");
    NSFetchRequest *fRequest = (NSFetchRequest*) request;
    id result = [cacheStack executeFetchRequest:(NSFetchRequest*) request err:error];
    if (result) return [self portForeignObjects:result toContext:context];
    
    result = [self dcaExecuteRequest:request withContext:context error:error];
    if (![result isEqual:cacheIsCorrectNow]) {
        NSLog(@"DCACacheFirstIncrementalStoreSubclass reports cache is not correct; failing upstream");
        WORK_AROUND_RDAR_10732696(*error);
        return nil;
    }
    if (![cacheStack save:error]) {
        return nil;
    }
    [cacheStack queryServed:(NSFetchRequest*) request];
    result = [cacheStack executeFetchRequest:(NSFetchRequest*) request err:error];
    if (result) {
        *error = nil; //clear out any previous error, such as Cache too old
        
        return [self portForeignObjects:result toContext:context];
    }
    return nil;
}

- (NSIncrementalStoreNode *)newValuesForObjectWithID:(NSManagedObjectID *)objectID withContext:(NSManagedObjectContext *)context error:(NSError *__autoreleasing *)error {
    return [self inceptionNodeForObjectID:objectID];
    
}

+ (NSPersistentStore *)installInCoordinator:(NSPersistentStoreCoordinator *)coordinator {
    [NSPersistentStoreCoordinator registerStoreClass:[self class] forStoreType:[[self class] storeType]];
    NSError *err =nil;
    NSPersistentStore *store =  [coordinator addPersistentStoreWithType:[[self class] storeType] configuration:nil URL:nil options:nil error:&err];
    if (!store) {
        NSLog(@"err %@",err);
        abort();
    }
    return store;
}
- (id)dcaExecuteRequest:(NSPersistentStoreRequest *)request withContext:(NSManagedObjectContext *)context error:(NSError *__autoreleasing *)error {
    NSLog(@"Not implemented in this abstract class.");
    abort();
}

- (NSArray *)objectsMatchingCacheable:(NSManagedObject<DCACacheable> *)cacheable {
    return [((DCACacheIncrementalStore*)self.cacheStack.persistentStore) objectsMatchingCacheable:cacheable];
}
@end
