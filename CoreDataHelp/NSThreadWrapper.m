//
//  DispatchQueueWrapper.m
//  CoreDataHelp
//
//  Created by Andrew Crawford on 5/20/12.
//  Copyright (c) 2012 Andrew Crawford. All rights reserved.
//

#import "NSThreadWrapper.h"

@implementation NSThreadWrapper

@synthesize thread;

- (NSUInteger)hash {
    return (NSUInteger) thread;
}

- (BOOL)isEqual:(NSThreadWrapper*)other {
    return thread==other.thread;
}

- (id)initWithNSThread:(NSThread*)q {
    if (self = [super init]) {
        self.thread = q;
    }
    return self;
}
- (NSString *)description {
    return [NSString stringWithFormat:@"ThreadWrapper wrapping %x",thread];
}

- (id)copyWithZone:(NSZone *)zone {
    NSThreadWrapper *dcopy = [[NSThreadWrapper allocWithZone:zone] initWithNSThread:self.thread];
    return dcopy;
}


+ (NSThreadWrapper *)currentWrapper {
    return [[NSThreadWrapper alloc] initWithNSThread:[NSThread currentThread]];
}
@end
