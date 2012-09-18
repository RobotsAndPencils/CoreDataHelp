//
//  DCAFetchRequestModel.h
//  CoreDataHelp
//
//  Created by Drew Crawford on 3/26/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <CoreData/CoreData.h>
#import "DCAFetchRequest.h"
@interface DCAFetchRequestModel : NSManagedObject
@property (nonatomic, strong) DCAFetchRequest *fetchRequest;

@end
