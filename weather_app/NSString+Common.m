//
//  NSString+Common.m
//  weather_app
//
//  Created by Justin on 3/16/19.
//  Copyright © 2019 Justin. All rights reserved.
//

#import "NSString+Common.h"

@implementation NSString(Common)
- (NSString *)sentenceCapitalizedString {
    if (![self length]) {
        return [NSString string];
    }
    NSString *uppercase = [[self substringToIndex:1] uppercaseString];
    NSString *lowercase = [[self substringFromIndex:1] lowercaseString];
    return [uppercase stringByAppendingString:lowercase];
}

@end
