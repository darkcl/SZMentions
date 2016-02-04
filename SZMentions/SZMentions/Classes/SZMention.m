//
//  SZMention.m
//  SZMentions
//
//  Created by Steve Zweier on 12/17/15.
//  Copyright © 2015 Steven Zweier. All rights reserved.
//

#import "SZMention.h"

@implementation SZMention

- (instancetype)initWithRange:(NSRange)range object:(NSObject *)object
{
    self = [super init];

    if (self) {
        self.range = range;
        self.object = object;
    }

    return self;
}

@end