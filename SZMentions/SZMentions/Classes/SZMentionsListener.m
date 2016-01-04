//
//  SZMentionsListener.m
//  SZMentions
//
//  Created by Steve Zweier on 12/17/15.
//  Copyright © 2015 Steven Zweier. All rights reserved.
//

#import "SZMentionsListener.h"
#import "SZMention.h"
#import "SZAttribute.h"

@interface SZMentionsListener ()

/**
 @brief Mutable array list of mentions managed by listener, accessible via the
 public mentions property.
 */
@property (nonatomic, strong) NSMutableArray *mutableMentions;

/**
 @brief Range of mention currently being edited.
 */
@property (nonatomic, assign) NSRange currentMentionRange;

/**
 @brief Whether or not we are currently editing a mention.
 */
@property (nonatomic, assign) BOOL editingMention;

@end

@implementation SZMentionsListener

#pragma mark - Initialization

- (instancetype)init
{
    self = [super init];
    
    if (self) {
        _trigger = @"@";
        _mutableMentions = @[].mutableCopy;
        _defaultTextAttributes = @[[self _defaultColor]];
        _mentionTextAttributes = @[[self _mentionColor]];
    }
    
    return self;
}

- (void)setTextView:(UITextView *)textView
{
    _textView = textView;
    [_textView setDelegate:self];
}

- (BOOL)resetEmptyTextView:(UITextView *)textView
                      text:(NSString *)text
                     range:(NSRange)range
{
    self.mutableMentions = @[].mutableCopy;
    NSMutableAttributedString *mutableAttributedString = [textView.attributedText mutableCopy];
    [[mutableAttributedString mutableString] replaceCharactersInRange:range withString:text];
    
    [self _applyAttributes:self.defaultTextAttributes
                     range:NSMakeRange(range.location, text.length)
   mutableAttributedString:mutableAttributedString];
    
    [textView setAttributedText:mutableAttributedString];
    
    if ([self.delegate respondsToSelector:
         @selector(textField:shouldChangeCharactersInRange:replacementString:)]) {
        [self.delegate textView:textView
        shouldChangeTextInRange:range
                replacementText:text];
    }
    
    [self textViewDidChange:textView];
    [[NSNotificationCenter defaultCenter] postNotificationName:UITextViewTextDidChangeNotification object:textView];
    
    return NO;
}

#pragma mark - Textview delegate

- (BOOL)textView:(UITextView *)textView
shouldChangeTextInRange:(NSRange)range
 replacementText:(NSString *)text
{
    NSAssert([textView.delegate isEqual:self], @"Textview delegate must be set equal to %@", self);
    
    if (textView.text.length == 0) {
        return [self resetEmptyTextView:textView text:text range:range];
    }
    
    [self _showHideMentionsListForTextView:textView text:text];
    
    self.editingMention = NO;
    SZMention *editedMention = [self _mentionBeingEditedForRange:range];
    
    if (editedMention) {
        self.editingMention = YES;
        [self.mutableMentions removeObject:editedMention];
    }
    
    NSArray *mentionsAfterTextEntry = [self _mentionsAfterTextEntryForRange:range];
    
    [self _adjustMentions:mentionsAfterTextEntry range:range text:text];
    
    if (self.editingMention) {
        return [self _handleEditingMention:editedMention
                                  textView:textView
                                     range:range
                                      text:text];
    }
    
    if ([self _needsToChangeToDefaultColorForTextView:textView range:range]) {
        return [self _forceDefaultColorForTextView:textView
                                             range:range
                                              text:text];
    }
    
    if ([self.delegate respondsToSelector:
         @selector(textField:shouldChangeCharactersInRange:replacementString:)]) {
        return [self.delegate textView:textView
               shouldChangeTextInRange:range
                       replacementText:text];
    }
    
    return YES;
}

- (BOOL)textView:(UITextView *)textView
shouldInteractWithTextAttachment:(NSTextAttachment *)textAttachment
         inRange:(NSRange)characterRange
{
    if ([self.delegate respondsToSelector:
         @selector(textView:shouldInteractWithTextAttachment:inRange:)]) {
        return [self.delegate textView:textView
      shouldInteractWithTextAttachment:textAttachment
                               inRange:characterRange];
    }
    
    return YES;
}

- (BOOL)textView:(UITextView *)textView
shouldInteractWithURL:(NSURL *)URL
         inRange:(NSRange)characterRange
{
    if ([self.delegate respondsToSelector:
         @selector(textView:shouldInteractWithURL:inRange:)]) {
        return [self.delegate textView:textView
                 shouldInteractWithURL:URL
                               inRange:characterRange];
    }
    
    return YES;
}

- (void)textViewDidBeginEditing:(UITextView *)textView
{
    if ([self.delegate respondsToSelector:@selector(textViewDidBeginEditing:)]) {
        [self.delegate textViewDidBeginEditing:textView];
    }
}

- (void)textViewDidChange:(UITextView *)textView
{
    if ([self.delegate respondsToSelector:@selector(textViewDidChange:)]) {
        [self.delegate textViewDidChange:textView];
    }
}

- (void)textViewDidChangeSelection:(UITextView *)textView
{
    if (!self.editingMention) {
        [self _adjustTextView:textView text:@"" range:textView.selectedRange];
        
        if ([self.delegate respondsToSelector:@selector(textViewDidChangeSelection:)]) {
            [self.delegate textViewDidChangeSelection:textView];
        }
    }
}

- (void)textViewDidEndEditing:(UITextView *)textView
{
    if ([self.delegate respondsToSelector:@selector(textViewDidEndEditing:)]) {
        [self.delegate textViewDidEndEditing:textView];
    }
}

- (BOOL)textViewShouldBeginEditing:(UITextView *)textView
{
    if ([self.delegate respondsToSelector:@selector(textViewShouldBeginEditing:)]) {
        [self.delegate textViewShouldBeginEditing:textView];
    }
    
    return YES;
}

- (BOOL)textViewShouldEndEditing:(UITextView *)textView
{
    if ([self.delegate respondsToSelector:@selector(textViewShouldEndEditing:)]) {
        return [self.delegate textViewShouldEndEditing:textView];
    }
    
    return YES;
}

#pragma mark - Public methods

- (NSArray *)mentions
{
    return self.mutableMentions.copy;
}

- (void)addMention:(NSObject<SZCreateMentionProtocol> *)mention
{
    NSMutableAttributedString *mutableAttributedString = [self.textView.attributedText mutableCopy];
    [[mutableAttributedString mutableString] replaceCharactersInRange:self.currentMentionRange
                                                           withString:mention.szMentionName];
    
    self.currentMentionRange = NSMakeRange(self.currentMentionRange.location, mention.szMentionName.length);
    
    [self _applyAttributes:self.mentionTextAttributes
                     range:NSMakeRange(self.currentMentionRange.location, self.currentMentionRange.length)
   mutableAttributedString:mutableAttributedString];
    
    [self _applyAttributes:self.defaultTextAttributes
                     range:NSMakeRange(self.currentMentionRange.location + self.currentMentionRange.length - 1, 0)
   mutableAttributedString:mutableAttributedString];
    
    [self.textView setAttributedText:mutableAttributedString];
    
    SZMention *szmention = [[SZMention alloc] init];
    [szmention setRange:self.currentMentionRange];
    [szmention setObject:mention];
    
    [self.mentionsManager hideMentionsList];
    [self.mutableMentions addObject:szmention];
}

#pragma mark - Private helpers

- (void)_applyAttributes:(NSArray *)attributes
                   range:(NSRange)range
 mutableAttributedString:(NSMutableAttributedString *)mutableAttributedString
{
    for (SZAttribute *attribute in attributes) {
        [mutableAttributedString addAttribute:attribute.attributeName
                                        value:attribute.attributeValue
                                        range:range];
    }
}

- (SZAttribute *)_defaultColor
{
    SZAttribute *defaultColor = [[SZAttribute alloc] init];
    [defaultColor setAttributeName:NSForegroundColorAttributeName];
    [defaultColor setAttributeValue:[UIColor greenColor]];
    
    return defaultColor;
}

- (SZAttribute *)_mentionColor
{
    SZAttribute *mentionColor = [[SZAttribute alloc] init];
    [mentionColor setAttributeName:NSForegroundColorAttributeName];
    [mentionColor setAttributeValue:[UIColor blueColor]];
    
    return mentionColor;
}

- (void)_adjustTextView:(UITextView *)textView
                   text:(NSString *)text
                  range:(NSRange)range
{
    NSString *substring = [textView.text substringToIndex:range.location];
    BOOL mentionEnabled = NO;
    
    if ([substring rangeOfString:self.trigger
                         options:NSBackwardsSearch].location != NSNotFound) {
        NSUInteger location = [substring rangeOfString:self.trigger
                                               options:NSBackwardsSearch].location;
        mentionEnabled = location == 0;
        
        if (location > 0) {
            NSRange substringRange =
            NSMakeRange([substring rangeOfString:self.trigger
                                         options:NSBackwardsSearch].location - 1, 1);
            mentionEnabled = [[substring substringWithRange:substringRange]
                              isEqualToString:@" "];
        }
    }
    
    NSArray *strings = [substring componentsSeparatedByString:@" "];
    
    if ([[strings lastObject] rangeOfString:self.trigger].location != NSNotFound) {
        if (mentionEnabled) {
            self.currentMentionRange = [textView.text rangeOfString:[strings lastObject]
                                                            options:NSBackwardsSearch];
            NSString *mentionString = [[strings lastObject] stringByAppendingString:text];
            NSString *filterString = [mentionString stringByReplacingOccurrencesOfString:self.trigger
                                                                              withString:@""];
            
            if (filterString.length) {
                [self.mentionsManager showMentionsListWithString:filterString];
            }
        } else {
            [self.mentionsManager hideMentionsList];
        }
    } else {
        [self.mentionsManager hideMentionsList];
    }
}

- (void)_showHideMentionsListForTextView:(UITextView *)textView text:(NSString *)text
{
    if ([text isEqualToString:@" "] ||
        (text.length && [[text substringFromIndex:text.length - 1] isEqualToString:@" "])) {
        [self.mentionsManager hideMentionsList];
    }
}

- (SZMention *)_mentionBeingEditedForRange:(NSRange)range
{
    SZMention *editedMention;
    
    for (SZMention *mention in self.mentions) {
        NSRange currentMentionRange = mention.range;
        
        if (NSIntersectionRange(range, currentMentionRange).length > 0 ||
            (range.length == 0 &&
             range.location > currentMentionRange.location &&
             range.location < currentMentionRange.length + currentMentionRange.location)) {
                editedMention = mention;
                break;
            }
    }
    
    return editedMention;
}

- (NSArray *)_mentionsAfterTextEntryForRange:(NSRange)range
{
    NSMutableArray *mentionsAfterTextEntry = @[].mutableCopy;
    
    for (SZMention *mention in self.mentions) {
        NSRange currentMentionRange = mention.range;
        
        if (range.location + range.length <= currentMentionRange.location) {
            [mentionsAfterTextEntry addObject:mention];
        }
    }
    
    return mentionsAfterTextEntry.copy;
}

- (void)_adjustMentions:(NSArray *)mentions range:(NSRange)range text:(NSString *)text
{
    for (SZMention *mention in mentions) {
        [mention setRange:NSMakeRange(mention.range.location +
                                      ((range.length > 0 ? range.length : 1) *
                                       (text.length ? 1 : -1)),
                                      mention.range.length)];
    }
}

- (BOOL)_handleEditingMention:(SZMention *)mention
                     textView:(UITextView *)textView
                        range:(NSRange)range
                         text:(NSString *)text
{
    NSMutableAttributedString *mutableAttributedString = [textView.attributedText mutableCopy];
    
    [self _applyAttributes:self.mentionTextAttributes
                     range:mention.range
   mutableAttributedString:mutableAttributedString];
    
    [self _applyAttributes:self.defaultTextAttributes
                     range:mention.range
   mutableAttributedString:mutableAttributedString];
    
    [[mutableAttributedString mutableString] replaceCharactersInRange:range withString:text];
    [textView setAttributedText:mutableAttributedString];
    [textView setSelectedRange:NSMakeRange(range.location + text.length, 0)];
    
    if ([self.delegate respondsToSelector:@selector(textField:shouldChangeCharactersInRange:replacementString:)])
        [self.delegate textView:textView shouldChangeTextInRange:range replacementText:text];
    
    return NO;
}

- (BOOL)_forceDefaultColorForTextView:(UITextView *)textView
                                range:(NSRange)range
                                 text:(NSString *)text
{
    NSMutableAttributedString *mutableAttributedString = [textView.attributedText mutableCopy];
    [[mutableAttributedString mutableString] replaceCharactersInRange:range
                                                           withString:text];
    
    [self _applyAttributes:self.defaultTextAttributes
                     range:NSMakeRange(range.location, text.length)
   mutableAttributedString:mutableAttributedString];
    
    [textView setAttributedText:mutableAttributedString];
    
    if (range.length > 0)
        [textView setSelectedRange:NSMakeRange(range.location, 0)];
    else
        [textView setSelectedRange:NSMakeRange(range.location + text.length, 0)];
    
    return NO;
}

- (BOOL)_isMentionAtIndex:(NSInteger)index textView:(UITextView *)textView
{
    if (index < 0 || textView.attributedText.length <= index) {
        return NO;
    }
    
    return [[textView.attributedText
             attribute:[self.mentionTextAttributes[0] attributeName]
             atIndex:index effectiveRange:0]
            isEqual:[self.mentionTextAttributes[0] attributeValue]];
}

- (BOOL)_needsToChangeToDefaultColorForTextView:(UITextView *)textView range:(NSRange)range
{
    BOOL isAheadOfMention =
    (range.location > 0 &&
     [self _isMentionAtIndex:range.location - 1
                    textView:textView]);
    BOOL isAtStartOfTextViewAndIsTouchingMention =
    (range.location == 0 &&
     textView.text.length > 0 &&
     [self _isMentionAtIndex:range.location + 1
                    textView:textView]);
    
    return (isAheadOfMention || isAtStartOfTextViewAndIsTouchingMention);
}

@end