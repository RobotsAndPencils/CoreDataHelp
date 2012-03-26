//
//  DCAFetchRequest.h
//  CoreDataHelp
//
//  Created by Drew Crawford on 3/25/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <CoreData/CoreData.h>

@interface DCAFetchRequest : NSFetchRequest
+ (DCAFetchRequest*) fetchRequestWithEntityClass:(Class) entityClass;
@end
