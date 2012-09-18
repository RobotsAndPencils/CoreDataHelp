//
//  CoreDataStack+Singleton.h
//  mindfulmeals
//
//  Created by Bion Oren on 3/26/12.
//  Copyright (c) 2012 DrewCrawfordApps. All rights reserved.
//

#import <CoreDataHelp/CoreDataHelp.h>

typedef id (^modelInitBlock)(id model);

@interface CoreDataStack (Singleton)

-(id)getOrCreateFromClass:(Class)type withInit:(modelInitBlock)block;

@end