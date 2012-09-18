//
//  NSIncrementalStoreAutoInstall.h
//  CoreDataHelp
//
//  Created by Drew Crawford on 3/25/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
@protocol NSIncrementalStoreAutoInstall <NSObject>
+ (NSPersistentStore*) installInCoordinator:(NSPersistentStoreCoordinator*) coordinator;
@end
