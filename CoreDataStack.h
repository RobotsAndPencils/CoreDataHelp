//
//  CoreDataStack.h
//  CoreDataHelp
//
//  Created by Drew Crawford on 3/25/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import <CoreDataHelp/DCAFetchRequest.h>
#import <CoreDataHelp/DCACacheable.h>
@class CaffeineOpaqueResult;

@interface CoreDataStack : NSObject
+ (CoreDataStack*) inMemoryStack;
+ (CoreDataStack*) onDiskStack;
+ (CoreDataStack*) incrementalStoreStack:(Class) autoInstallableIncrementalStore;
+ (CoreDataStack*) incrementalStoreStackWithClass:(Class) nsIncrementalStoreClass model:(NSManagedObjectModel*) model configuration:(NSURL*) configuration url:(NSURL*) url options:(NSDictionary*) options caching:(BOOL) caching;


- (id) executeFetchRequest:(NSFetchRequest*) fetchRequest err:(NSError * __autoreleasing *) err;
- (id) insertNewObjectOfClass:(Class) c;
- (BOOL) save:(NSError *__autoreleasing*) error;

- (void) delete:(NSManagedObject*)obj;

//threading functions

- (void) backgroundOperation:(void (^)()) block;
- (void) backgroundOperationSync:(void (^)()) block;
- (id) objectOnCurrentThread:(NSManagedObject*) o;
- (id) objectOnMainThread:(NSManagedObject*) obj;
- (NSArray*) objectsOnCurrentThread:(NSArray*) objects;
- (NSArray*) objectsOnMainThread:(NSArray*) objects;
- (id) objectOnCurrentThreadFromID:(NSManagedObjectID*) objectID;
- (void) beginRogueThread;
- (void) endRogueThread;
- (NSArray*) arrayWithOpaqueResult:(CaffeineOpaqueResult*) opaqueResult;
//internal use only!!!!!
- (NSPersistentStore*) persistentStore;
+ (CoreDataStack*) cachingStack;
+ (CoreDataStack*) inMemoryStack_caching;
- (void) queryServed:(NSFetchRequest*) fetchRequest;
- (DCAFetchRequest*) portFetchRequest:(DCAFetchRequest*) fetchRequest;
@end
