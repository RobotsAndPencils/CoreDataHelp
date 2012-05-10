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
@implementation CoreDataStack {
    NSManagedObjectModel *managedObjectModel;
    NSManagedObjectContext *managedObjectContext;
    NSManagedObjectContext *privateManagedObjectContext;
    NSPersistentStoreCoordinator *persistentStoreCoordinator;
    
}

+ (CoreDataStack*) inMemoryStack {
    CoreDataStack *stack = [[CoreDataStack alloc] init];
    stack->managedObjectModel = [NSManagedObjectModel defaultModel];
    if (stack->managedObjectModel.entities.count==0) {
        NSLog(@"Warning:  There are no entities in your model.  This means that the runtime environment cannot find your .xcdatamodeld file.  Check that it is added to the target, or if this is a unit test, check that you are compiling with DCA_UNITTEST enabled.");
    }
    stack->persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:stack->managedObjectModel];
    NSError *err = nil;
    [stack->persistentStoreCoordinator addPersistentStoreWithType:NSInMemoryStoreType configuration:nil URL:nil options:nil error:&err];
    stack->managedObjectContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
    [stack->managedObjectContext setPersistentStoreCoordinator:stack->persistentStoreCoordinator];
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
    [stack->persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeUrl options:nil error:&err];
    stack->managedObjectContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
    [stack->managedObjectContext setPersistentStoreCoordinator:stack->persistentStoreCoordinator];
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
    stack->managedObjectContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
    stack->managedObjectContext.persistentStoreCoordinator = stack->persistentStoreCoordinator;
    NSError *err = nil;
    [autoInstallableIncrementalStore performSelector:@selector(installInCoordinator:) withObject:stack->persistentStoreCoordinator];

    if (!stack->persistentStoreCoordinator) {
        NSLog(@"err %@",err);
        abort();
    }
    return stack;
}

+ (CoreDataStack*) cachingStack {
    CoreDataStack *stack = [[CoreDataStack alloc] init];
    stack->managedObjectModel = [NSManagedObjectModel defaultModel];
    stack->persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:stack->managedObjectModel];
    stack->managedObjectContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
    stack->managedObjectContext.persistentStoreCoordinator = stack->persistentStoreCoordinator;
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
    stack->persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:stack->managedObjectModel];
    NSError *err = nil;
    [stack->persistentStoreCoordinator addPersistentStoreWithType:NSInMemoryStoreType configuration:nil URL:nil options:nil error:&err];
    stack->managedObjectContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
    [stack->managedObjectContext setPersistentStoreCoordinator:stack->persistentStoreCoordinator];
    if (!stack->persistentStoreCoordinator) {
        NSLog(@"err %@",err);
        abort();
    }
    return stack;
}

- (NSManagedObjectContext*) poc {
    if (!privateManagedObjectContext) {
        privateManagedObjectContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:(NSPrivateQueueConcurrencyType)];
        privateManagedObjectContext.persistentStoreCoordinator = persistentStoreCoordinator;
    }
    return privateManagedObjectContext;
}

- (NSManagedObjectContext*) currentMoc {
    if (dispatch_get_current_queue()==dispatch_get_main_queue()) return managedObjectContext;
    else return privateManagedObjectContext;
}

- (void) backgroundOperation:(void (^)()) block {
    [[self poc] performBlock:block];
}

- (id)objectOnCurrentThread:(NSManagedObject *)obj {
    NSManagedObjectContext *correctContext = [self currentMoc];
    if (obj.managedObjectContext ==correctContext) return obj;
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

- (id)insertNewObjectOfClass:(Class)c {
    return [NSEntityDescription insertNewObjectForEntityForName:NSStringFromClass(c) inManagedObjectContext:managedObjectContext];
}
- (NSPersistentStore *)persistentStore {
    return [persistentStoreCoordinator.persistentStores objectAtIndex:0];
}

- (id)executeFetchRequest:(id)fetchRequest err:(NSError *__autoreleasing *)err {
    NSAssert(err,@"Did not pass in an error object.");
    NSAssert(managedObjectContext,@"No moc?");
    NSArray *results =  [[self currentMoc] executeFetchRequest:fetchRequest error:err];
    for (NSManagedObject *result in results) {
        NSAssert(result.managedObjectContext==[self currentMoc],@"Bad object returned while executing request %@, this will cause future errors",fetchRequest);
        
    }
    return results;

}
- (BOOL) save:(NSError *__autoreleasing*) error {
    [[self poc] save:error];
    return [managedObjectContext save:error];
}

- (void)queryServed:(NSFetchRequest *)fetchRequest {
    NSAssert([fetchRequest class]==[DCAFetchRequest class],@"Didn't serve a DCA fetch request, this might not be supported?");
    [((DCACacheIncrementalStore*) [self persistentStore]) queryServed:(DCAFetchRequest*) fetchRequest];
}

- (DCAFetchRequest*)portFetchRequest:(DCAFetchRequest*)fetchRequest {
    DCAFetchRequest *retFetchRequest = [[DCAFetchRequest alloc] initWithEntityName:fetchRequest.entityName];
    retFetchRequest.sortDescriptors = fetchRequest.sortDescriptors;
    //todo: filters
    return retFetchRequest;
}



@end
