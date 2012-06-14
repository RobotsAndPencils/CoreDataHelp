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
        
        //on iOS 5.0, we can get into an infinite loop if we try and install one coordinator while installing another coordinator.
        //this was fixed in iOS 5.1
        
        //there are specific cases where version checking is warranted, and this is one of them.  Don't take this code as best practice.
        //http://stackoverflow.com/questions/3339722/check-iphone-ios-version
        
        NSString *reqSysVer = @"5.1";
        NSString *currSysVer = [UIDevice currentDevice].systemVersion;
        if ([currSysVer compare:reqSysVer options:NSNumericSearch] != NSOrderedAscending) {
            NSLog(@"Detected version %@ as bug-free.  If you see a hang around here, complain to Drew",currSysVer);
            cacheStack = [CoreDataStack cachingStack];
        }
        else {
            NSLog(@"Your OS is buggy.  Working around...");
            dispatch_async(dispatch_queue_create(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                cacheStack = [CoreDataStack cachingStack];
            });
        }
        
        
        
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
    //NSFetchRequest *fRequest = (NSFetchRequest*) request; 
    __block id result = nil;
    [cacheStack backgroundOperationSync:^{
        result = [cacheStack executeFetchRequest:(NSFetchRequest*) request err:error];
        if (result) result = [self portForeignObjects:result toContext:context withInceptionStack:cacheStack];
    }];
    if (result) return result;
    
    result = [self dcaExecuteRequest:request withContext:context error:error];
    if (![result isEqual:cacheIsCorrectNow]) {
        NSLog(@"DCACacheFirstIncrementalStoreSubclass reports cache is not correct; failing upstream");
        WORK_AROUND_RDAR_10732696(*error);
        return nil;
    }
    
    [cacheStack backgroundOperationSync:^{
        [cacheStack queryServed:(NSFetchRequest*) request];
        result = [cacheStack executeFetchRequest:(NSFetchRequest*) request err:error];
        if (result) {
            *error = nil; //clear out any previous error, such as Cache too old
            result =  [self portForeignObjects:result toContext:context withInceptionStack:cacheStack];
        }
    }];

    if (result) return result;
    
    return nil;
}

- (NSIncrementalStoreNode *)newValuesForObjectWithID:(NSManagedObjectID *)objectID withContext:(NSManagedObjectContext *)context error:(NSError *__autoreleasing *)error {
    return [self inceptionNodeForObjectID:objectID withInceptionStack:cacheStack];
    
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

- (BOOL)multipleObjectsMatchingCacheable:(NSManagedObject<DCACacheable> *)cacheable {
    return [((DCACacheIncrementalStore*)self.cacheStack.persistentStore) multipleObjectsMatchingCacheable:cacheable];
}
@end
