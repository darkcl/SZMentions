//
//  SZAttribute.h
//  SZMentions
//
//  Created by Steve Zweier on 12/19/15.
//  Copyright © 2015 Steven Zweier. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SZAttribute : NSObject

/**
 @brief Name of the attribute to set on a string
 */
@property (nonatomic, strong) NSString *attributeName;

/**
 @brief Value of the attribute to set on a string
 */
@property (nonatomic, strong) NSObject *attributeValue;

@end