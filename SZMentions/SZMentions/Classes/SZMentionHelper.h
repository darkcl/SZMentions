//
//  SZMentionHelper.h
//  SZMentions
//
//  Created by Steve Zweier on 2/1/16.
//  Copyright © 2016 Steven Zweier. All rights reserved.
//

#import <UIKit/UIKit.h>

@class SZMention;

@interface SZMentionHelper : NSObject

/**
 @brief Determines what mentions exist after a given range
 @param range: the range where text was changed
 @param mentionsList: the list of current mentions
 @return NSArray <SZMention *>: list of mentions that exist after the provided range
 */
+ (NSArray<SZMention *> *)_mentionsAfterTextEntryForRange:(NSRange)range inMentions:(NSArray *)mentionsList;

/**
 @brief adjusts the positioning of mentions that exist after the range where text was edited
 @param range: the range where text was changed
 @param text: the text that was changed
 @param mentions: the list of current mentions
 */
+ (void)_adjustMentionsInRange:(NSRange)range text:(NSString *)text mentions:(NSArray *)mentions;

/**
 @brief Determines whether or not a mention exists at a specific location
 @param index: the location to check
 @param mentions: the list of current mentions
 @return BOOL: Whether or not a mention exists at a specific location
 */
+ (BOOL)_mentionExistsAtIndex:(NSInteger)index mentions:(NSArray *)mentions;

/**
 @brief Determine whether or not we need to change the color back to default attributes
 @param range: the current selection in the text view
 @param textView: the mentions text view
 @param mentions: the list of current mentions
 @return BOOL: whether or not we need to change back to default attributes
 */
+ (BOOL)_needsToChangeToDefaultColorForRange:(NSRange)range textView:(UITextView *)textView mentions:(NSArray *)mentions;

/**
 @brief Uses the text being entered into the view to determine whether or not we should hide the mentions list
 @param text: the text being entered
 @return BOOL: whether or not we should hide the mentions list.
 */
+ (BOOL)_shouldHideMentionsForText:(NSString *)text;

@end
