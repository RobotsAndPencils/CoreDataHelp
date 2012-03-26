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

- (id)insertNewObjectOfClass:(Class)c {
    return [NSEntityDescription insertNewObjectForEntityForName:NSStringFromClass(c) inManagedObjectContext:managedObjectContext];
}
- (NSPersistentStore *)persistentStore {
    return [persistentStoreCoordinator.persistentStores objectAtIndex:0];
}

- (id)executeFetchRequest:(id)fetchRequest err:(NSError *__autoreleasing *)err {
    NSAssert(err,@"Did not pass in an error object.");
    NSAssert(managedObjectContext,@"No moc?");
    return [managedObjectContext executeFetchRequest:fetchRequest error:err];

}
- (BOOL) save:(NSError *__autoreleasing*) error {
    return [managedObjectContext save:error];
}

- (void)queryServed:(NSFetchRequest *)fetchRequest {
    NSAssert([fetchRequest class]==[DCAFetchRequest class],@"Didn't serve a DCA fetch request, this might not be supported?");
    [((DCACacheIncrementalStore*) [self persistentStore]) queryServed:(DCAFetchRequest*) fetchRequest];
}

- (DCAFetchRequest*)portFetchRequest:(DCAFetchRequest*)fetchRequest {
    DCAFetchRequest *retFetchRequest = [[DCAFetchRequest alloc] initWithEntityName:fetchRequest.entityName];
    //todo: filters, sorts
    return retFetchRequest;
}

@end
