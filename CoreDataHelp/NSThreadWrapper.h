//
//  DispatchQueueWrapper.h
//  CoreDataHelp
//
//  Created by Andrew Crawford on 5/20/12.
//  Copyright (c) 2012 Andrew Crawford. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSThreadWrapper : NSObject <NSCopying>
@property (weak) NSThread *thread;
-(id) initWithNSThread:(NSThread*) q;
+(NSThreadWrapper*) currentWrapper;
@end
