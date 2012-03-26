//
//  DCAManagedObjectContextIncrementalStore.h
//  CoreDataHelp
//
//  Created by Drew Crawford on 3/25/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <CoreData/CoreData.h>
#import "NSIncrementalStoreAutoInstall.h"
#import "DCAFetchRequest.h"
/**This class is a custom store that caches in memory.*/
@interface DCACacheIncrementalStore : NSIncrementalStore <NSIncrementalStoreAutoInstall>
- (void) queryServed:(DCAFetchRequest*) fetchRequest;
@end
