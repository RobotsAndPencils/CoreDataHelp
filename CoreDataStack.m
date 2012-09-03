//
//  CoreDataStack.m
//  CoreDataHelp
//
//  Created by Drew Crawford on 3/25/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "CoreDataStack.h"
#import <CoreData/CoreData.h>
#import "NSIncrementalStoreAutoInstall.h"
#import "NSManagedObjectModel+CDHAdditions.h"
#import "DCACacheIncrementalStore.h"
#import "DCAFetchRequestModel.h"
#import "NSManagedObject+DCAAdditions.h"
#import "DCACacheable.h"
#import "NSThreadWrapper.h"
//#define THREADING_DEBUG

@implementation CoreDataStack {
    NSManagedObjectModel *managedObjectModel;
    NSManagedObjectContext *managedObjectContext;
    NSPersistentStoreCoordinator *persistentStoreCoordinator;
    
    NSMutableDictionary *managedObjectContexts;
    //we store some NSNumbers in here that indicate whether an NSManagedObjectContext should be cleaned up or not
    NSMutableDictionary *threadRetainCounts;
    
    dispatch_queue_t preferredQueue;
    
    
    
    
    
}


-(void) mergeRequired:(NSNotification*) notification {
        NSManagedObjectContext *sourceContext = [notification object];
        //this method can receive changes from other stacks, and those changes must be ignored and not synchronized.
        if (![[managedObjectContexts allValues] containsObject:sourceContext]) return; 
    @synchronized(self) {

        for (NSThreadWrapper *key  in [managedObjectContexts allKeys]) {
            NSManagedObjectContext *context = [managedObjectContexts objectForKey:key];
            if (context==sourceContext) continue;
            if (context==managedObjectContext) {
#ifdef THREADING_DEBUG
                NSLog(@"Merging changes from %@ onto %@",sourceContext,context);
#endif
                if ([NSThread currentThread]==[NSThread mainThread]) {
                    [managedObjectContext mergeChangesFromContextDidSaveNotification:notification];
                }
                else {
                    dispatch_sync(dispatch_get_main_queue(), ^{
                        [managedObjectContext mergeChangesFromContextDidSaveNotification:notification];
                    });
                }
                continue;
            }
            NSLog(@"WARNING: cannot merge changes from %@ onto %@, your threads may be out of sync...",sourceContext,context);
        }
    }

}



-(void) installManagedObjectContexts {
    
    managedObjectContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
    managedObjectContext.persistentStoreCoordinator = persistentStoreCoordinator;
    managedObjectContexts = [NSMutableDictionary dictionaryWithObject:managedObjectContext forKey:[[NSThreadWrapper alloc] initWithNSThread:[NSThread mainThread]]];
    threadRetainCounts = [NSMutableDictionary dictionaryWithObject:[NSNumber numberWithInt:1] forKey:[[NSThreadWrapper alloc] initWithNSThread:[NSThread mainThread]]];
    preferredQueue = dispatch_queue_create("com.a.b", 0);
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(mergeRequired:) name:NSManagedObjectContextDidSaveNotification object:nil];
    
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    dispatch_release(preferredQueue);
}

+ (CoreDataStack*) inMemoryStack {
    CoreDataStack *stack = [[CoreDataStack alloc] init];
    stack->managedObjectModel = [NSManagedObjectModel defaultModel];
    if (stack->managedObjectModel.entities.count==0) {
        NSLog(@"Warning:  There are no entities in your model.  This means that the runtime environment cannot find your .xcdatamodeld file.  Check that it is added to the target, or if this is a unit test, check that you are compiling with DCA_UNITTEST enabled.");
    }
    stack->persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:stack->managedObjectModel];
    NSError *err = nil;
    NSPersistentStore *store = [stack->persistentStoreCoordinator addPersistentStoreWithType:NSInMemoryStoreType configuration:nil URL:nil options:nil error:&err];
    NSAssert(store,@"No store seems to have been created, reason: %@",err);
    [stack installManagedObjectContexts];
    if (!stack->persistentStoreCoordinator) {
        NSLog(@"err %@",err);
        abort();
    }
    return stack;
}

+ (CoreDataStack*) onDiskStack {
#ifdef DCA_UNITTEST 
    return [CoreDataStack inMemoryStack];
#endif
    CoreDataStack *stack = [[CoreDataStack alloc] init];
    stack->managedObjectModel = [NSManagedObjectModel defaultModel];
    if (stack->managedObjectModel.entities.count==0) {
        NSLog(@"Warning:  There are no entities in your model.  This means that the runtime environment cannot find your .xcdatamodeld file.  Check that it is added to the target, or if this is a unit test, check that you are compiling with DCA_UNITTEST enabled.");
    }
    stack->persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:stack->managedObjectModel];
    NSError *err = nil;
    NSString *bundle_id = [[NSBundle mainBundle]objectForInfoDictionaryKey:@"CFBundleIdentifier"];
    NSURL *storeUrl = [NSURL fileURLWithPath:[[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject] stringByAppendingPathComponent:bundle_id]];
    NSPersistentStore *store = [stack->persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeUrl options:nil error:&err];
    NSAssert(store,@"No store seems to have been created, reason: %@",err);
    [stack installManagedObjectContexts];
    if (!stack->persistentStoreCoordinator) {
        NSLog(@"err %@",err);
        abort();
    }
    return stack;
}

+ (CoreDataStack*) incrementalStoreStack:(Class) autoInstallableIncrementalStore {
    CoreDataStack *stack = [[CoreDataStack alloc] init];
    stack->managedObjectModel = [NSManagedObjectModel defaultModel];
    stack->persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:stack->managedObjectModel];
    [stack installManagedObjectContexts];
    NSError *err = nil;
    [autoInstallableIncrementalStore performSelector:@selector(installInCoordinator:) withObject:stack->persistentStoreCoordinator];

    if (!stack->persistentStoreCoordinator) {
        NSLog(@"err %@",err);
        abort();
    }
    return stack;
}

+ (CoreDataStack*) incrementalStoreStackWithClass:(Class) nsIncrementalStoreClass model:(NSManagedObjectModel*) model configuration:(NSString*) configuration url:(NSURL*) url options:(NSDictionary*) options caching:(BOOL) caching{
    CoreDataStack *stack = [[CoreDataStack alloc] init];
    stack->managedObjectModel = model;
    stack->persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:stack->managedObjectModel];

    [stack installManagedObjectContexts];
    NSError *err = nil;
    [NSPersistentStoreCoordinator registerStoreClass:nsIncrementalStoreClass forStoreType:NSStringFromClass(nsIncrementalStoreClass)];
    [stack->persistentStoreCoordinator addPersistentStoreWithType:NSStringFromClass(nsIncrementalStoreClass) configuration:configuration URL:url options:options error:&err];
    
    if (stack->persistentStoreCoordinator.persistentStores.count==0) {
        NSLog(@"Error: %@",err);
        abort();
    }
    return stack;
    
}

+ (CoreDataStack*) cachingStack {
    CoreDataStack *stack = [[CoreDataStack alloc] init];
    stack->managedObjectModel = [NSManagedObjectModel defaultModel];
    stack->persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:stack->managedObjectModel];
    [stack installManagedObjectContexts];
    NSError *err = nil;

    [DCACacheIncrementalStore installInCoordinator:stack->persistentStoreCoordinator];
    if (!stack->persistentStoreCoordinator) {
        NSLog(@"err %@",err);
        abort();
    }
    return stack;

}

+ (CoreDataStack*) inMemoryStack_caching {
    CoreDataStack *stack = [[CoreDataStack alloc] init];
    stack->managedObjectModel = [NSManagedObjectModel cachingModel];
    if (stack->managedObjectModel.entities.count==0) {
        NSLog(@"Warning:  There are no entities in your model.  This means that the runtime environment cannot find your .xcdatamodeld file.  Check that it is added to the target, or if this is a unit test, check that you are compiling with DCA_UNITTEST enabled.");
    }
    NSEntityDescription *sampleObject = stack->managedObjectModel.entities.lastObject;
    
    NSAssert([sampleObject.attributesByName objectForKey:INTERNAL_CACHING_KEY],@"For some reason, an object is not cacheable as expected: %@",sampleObject);
    
    stack->persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:stack->managedObjectModel];
    NSError *err = nil;
    NSPersistentStore *store = [stack->persistentStoreCoordinator addPersistentStoreWithType:NSInMemoryStoreType configuration:nil URL:nil options:nil error:&err];
    NSAssert(store,@"No store seems to have been created, reason: %@",err);

    [stack installManagedObjectContexts];
    if (!stack->persistentStoreCoordinator) {
        NSLog(@"err %@",err);
        abort();
    }
    return stack;
}

- (void) beginRogueThread {
    NSNumber *retainCount = [threadRetainCounts objectForKey:[NSThreadWrapper currentWrapper]];
    if (retainCount) {
        [threadRetainCounts setObject:[NSNumber numberWithInt:retainCount.intValue + 1] forKey:[NSThreadWrapper currentWrapper]];
        return; //do not create new context!
    }
    [threadRetainCounts setObject:[NSNumber numberWithInt:1] forKey:[NSThreadWrapper currentWrapper]];
    NSManagedObjectContext *context = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
    context.persistentStoreCoordinator = persistentStoreCoordinator;
    [managedObjectContexts setObject:context forKey:[NSThreadWrapper currentWrapper]];
#ifdef THREADING_DEBUG
    NSLog(@"Beginning rogue thread %@ with moc %@ on stack %@",[NSThreadWrapper currentWrapper],context,self);
#endif
}
- (void) endRogueThread {
    NSError *err = nil;
    if (![self save:&err]) {
        NSLog(@"Unable to end a rogue thread.");
        abort();
    }
    //can we remove the context?
    NSNumber *retainCount = [threadRetainCounts objectForKey:[NSThreadWrapper currentWrapper]];
    NSAssert(retainCount,@"Not sure why we don't have a retainCount for this thread, did it begin?");
    if (retainCount.intValue > 1) {
        [threadRetainCounts setObject:[NSNumber numberWithInt:retainCount.intValue - 1] forKey:[NSThreadWrapper currentWrapper]];
        return; //do not clean up!
    }
    [threadRetainCounts removeObjectForKey:[NSThreadWrapper currentWrapper]];

    NSManagedObjectContext *context = [managedObjectContexts objectForKey:[NSThreadWrapper currentWrapper]];
    [context reset];
    NSAssert(context,@"You seem to be ending a rogue thread that I am unaware of...");
    [managedObjectContexts removeObjectForKey:[NSThreadWrapper currentWrapper]];
#ifdef THREADING_DEBUG
    NSLog(@"Ending rogue thread %@ with moc %@ on stack %@",[NSThreadWrapper currentWrapper],context,self);
#endif

}

- (NSManagedObjectContext*) currentMoc {
    NSManagedObjectContext *context = [managedObjectContexts objectForKey:[NSThreadWrapper currentWrapper]];
    if (context) return context;
    NSLog(@"You're trying to use the CoreDataStack %@ on a thread (%@) for which it is not authorized.  To fix this, use backgroundOperation[Sync] (recommended), or alternatively wrap your code with [coreDataStack beginRogueThread] and [coreDataStack endRogueThread]",self,[NSThreadWrapper currentWrapper]);
    abort();
}

- (void) backgroundOperation:(void (^)()) block {
    dispatch_async(preferredQueue, ^{
        [[NSThread currentThread] setName:@"com.coreDataHelp.backgroundOperation"];
        [self beginRogueThread];
        block();
        [self endRogueThread];
    });
}
- (void) backgroundOperationSync:(void (^)()) block {
    dispatch_sync(preferredQueue, ^{
        [[NSThread currentThread] setName:@"com.coreDataHelp.backgroundOperationSync"];

        [self beginRogueThread];
        block();
        [self endRogueThread];
    });
}
- (NSArray*) objectsOnCurrentThread:(NSArray*) objects {
    NSMutableArray *newThread = [NSMutableArray arrayWithCapacity:objects.count];
    for(NSManagedObject *obj in objects) {
        [newThread addObject:[self objectOnCurrentThread:obj]];
    }
    return [NSArray arrayWithArray:newThread];
}
- (NSArray*) objectsOnMainThread:(NSArray*) objects {
    NSMutableArray *newThread = [NSMutableArray arrayWithCapacity:objects.count];
    for(NSManagedObject *obj in objects) {
        [newThread addObject:[self objectOnMainThread:obj]];
    }
    return [NSArray arrayWithArray:newThread];
}


- (id) object:(NSManagedObject*) obj onContext:(NSManagedObjectContext*) correctContext {
    if ([self currentMoc] ==correctContext) return obj;
    NSAssert(!obj.isInserted,@"(Not supported because Drew is lazy, file a bug, read the CD concurrency guide.)  The fix is trivial: just view the problem as a context-free poset whose elements are nonsingular bijections.");
    NSAssert(!obj.isUpdated,@"(Potentially dangerous operation, escalate to Drew to discuss, read the CD concurrency guide).  The fix is trivial: Just view the problem as a dihedral group whose relements are rgular residue classes.");
    NSAssert(!obj.isDeleted,@"(Potentially dangerous operation, escalate to Drew to discuss, read the CD concurrency guide.).  The fix is trivial: Just biject it to a continuous complexity class whose elements are structure-preserving semigroups.");
    NSManagedObjectID *oid = [obj objectID];
    NSError *err = nil;
    NSManagedObject *result = [correctContext existingObjectWithID:oid error:&err];
    if (!result) {
        NSLog(@"Error while moving an object between threads: %@",err);
        NSLog(@"Object is %@",obj);
        NSLog(@"Object comes from context %@ with pc %@",obj.managedObjectContext,obj.managedObjectContext.persistentStoreCoordinator);
        NSLog(@"Attemping to move to context %@ with pc %@",correctContext,correctContext.persistentStoreCoordinator);
        abort();
    }
    return result;
}
- (id)objectOnCurrentThread:(NSManagedObject *)obj {
    return [self object:obj onContext:[self currentMoc]];
}

- (id) objectOnMainThread:(NSManagedObject*) obj {
    return [self object:obj onContext:managedObjectContext];
}

- (id)objectOnCurrentThreadFromID:(NSManagedObjectID *)objectID {
    return [[self currentMoc] objectWithID:objectID];
}



- (id)insertNewObjectOfClass:(Class)c {
    return [NSEntityDescription insertNewObjectForEntityForName:NSStringFromClass(c) inManagedObjectContext:[self currentMoc]];
}
- (void) delete:(NSManagedObject*)obj {
    
    [[self currentMoc] deleteObject:obj];
}
- (NSPersistentStore *)persistentStore {
    return [persistentStoreCoordinator.persistentStores objectAtIndex:0];
}



- (id)executeFetchRequest:(id)fetchRequest err:(NSError *__autoreleasing *)err {
    NSAssert(err,@"Did not pass in an error object.");
    NSAssert([self currentMoc],@"No moc?");
    NSArray *results =  [[self currentMoc] executeFetchRequest:fetchRequest error:err];
    for (NSManagedObject *result in results) {
        NSAssert(result.managedObjectContext==[self currentMoc],@"Bad object returned while executing request %@, this will cause future errors",fetchRequest);
        
    }
    return results;

}
- (BOOL) save:(NSError *__autoreleasing*) error {
#ifdef THREADING_DEBUG
    NSLog(@"Saving %@... %d inserts, %d updates, %d deletes",[self currentMoc],[self currentMoc].insertedObjects.count,[self currentMoc].updatedObjects.count,[self currentMoc].deletedObjects.count);
#endif
    if ([self currentMoc].hasChanges) {
        return [[self currentMoc] save:error];
    }
    return YES;
}

- (void)queryServed:(NSFetchRequest *)fetchRequest {
    NSAssert([fetchRequest class]==[DCAFetchRequest class],@"Didn't serve a DCA fetch request, this might not be supported?");
    [((DCACacheIncrementalStore*) [self persistentStore]) queryServed:(DCAFetchRequest*) fetchRequest];
}

- (DCAFetchRequest*)portFetchRequest:(DCAFetchRequest*)fetchRequest {
    DCAFetchRequest *retFetchRequest = [[DCAFetchRequest alloc] initWithEntityName:fetchRequest.entityName];
    retFetchRequest.sortDescriptors = fetchRequest.sortDescriptors;
    if (fetchRequest.predicate) {
        NSAssert([fetchRequest.predicate class]==[NSComparisonPredicate class],@"Non-comparison predicate");
        NSComparisonPredicate *comparisonPredicate = (NSComparisonPredicate*) fetchRequest.predicate;
        NSAssert(comparisonPredicate.leftExpression.keyPath,@"This fetch request might port incorrectly; file a bug.");
        NSAssert(comparisonPredicate.rightExpression.constantValue,@"This fetch request might port incorrectly; file a bug.");
        NSAssert(![comparisonPredicate.rightExpression.constantValue isKindOfClass:[NSManagedObject class]],@"This fetch request might not port correctly; file a bug.");
        retFetchRequest.predicate = fetchRequest.predicate;
    }
    retFetchRequest.cachingPolicy = fetchRequest.cachingPolicy;
    return retFetchRequest;
}



@end
