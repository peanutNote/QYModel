//
//  NSObject+QYModelCheckType.m
//  QYModel
//
//  Created by qianye on 2017/12/6.
//  Copyright © 2017年 chemanman. All rights reserved.
//

#import "NSObject+QYModelCheckType.h"

NSString *const _is_string = @"_is_string";
NSString *const _is_number = @"_is_number";
NSString *const _is_array = @"_is_array";
NSString *const _is_dictionary = @"_is_dictionary";
NSString *const _get_integer = @"_get_integer";
NSString *const _get_bool = @"_get_bool";
NSString *const _get_float = @"_get_float";

@implementation NSObject (QYModelCheckType)

- (BOOL)_is_class:(Class)cls {
    return [self isKindOfClass:cls];
}

- (BOOL)_is_string {
    return [self isKindOfClass:NSString.class] || [self isKindOfClass:NSMutableString.class];
}

- (BOOL)_is_number {
    return [self isKindOfClass:NSNumber.class];
}

- (BOOL)_is_array {
    return [self isKindOfClass:NSArray.class] || [self isKindOfClass:NSMutableArray.class];
}

- (BOOL)_is_dictionary {
    return [self isKindOfClass:NSDictionary.class] || [self isKindOfClass:NSMutableDictionary.class];
}

- (BOOL)_checkAvialData {
    if (self._is_string || self._is_number) {
        return YES;
    }
    return NO;
}

- (BOOL)_get_integer {
    if (self._is_string || self._is_number) {
        return YES;
    }
    return NO;
}

- (BOOL)_get_bool {
    if (self._is_string || self._is_number) {
        return YES;
    }
    return NO;
}

- (BOOL)_get_float {
    if (self._is_string || self._is_number) {
        return YES;
    }
    return NO;
}

@end
