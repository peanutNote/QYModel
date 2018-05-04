//
//  QYAnalysis.m
//  QYModel
//
//  Created by qianye on 2018/5/4.
//  Copyright © 2018年 qianye. All rights reserved.
//

#import "QYAnalysis.h"

id scan(NSScanner *scanner, id obj);

id getDefaultValue(NSString *isFunc) {
    if ([isFunc isEqualToString:_is_string]) {
        return NSString.new;
    } else if ([isFunc isEqualToString:_is_number]) {
        return @0;
    } else if ([isFunc isEqualToString:_is_dictionary]) {
        return NSDictionary.new;
    } else if ([isFunc isEqualToString:_is_array]) {
        return NSArray.new;
    } else if ([isFunc containsString:@":"]) {
        NSRange range = [isFunc rangeOfString:@":"];
        NSString *clsString = [isFunc substringFromIndex:range.location + 1];
        Class defCls = NSClassFromString(clsString);
        if (defCls) {
            return [defCls new];
        }
    }
    return nil;
}

BOOL checkType(id obj, NSString *isFunc) {
    NSString *funcString = isFunc;
    Class funcParam = nil;
    if ([funcString containsString:@":"]) {
        NSRange range = [isFunc rangeOfString:@":"];
        funcString = [isFunc substringToIndex:range.location + 1];
        funcParam = NSClassFromString([isFunc substringFromIndex:range.location + 1]);
    }
    SEL checkMethod = NSSelectorFromString(funcString);
    BOOL returnValue = NO;
    if ([obj respondsToSelector:checkMethod]) {
        NSMethodSignature *signature = [obj methodSignatureForSelector:checkMethod];
        NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:signature];
        [invocation setSelector:checkMethod];
        if (funcParam) {
            [invocation setArgument:&funcParam atIndex:2];
        }
        const char *returnType = signature.methodReturnType;
        NSUInteger length = [signature methodReturnLength];
        void *buffer = (void *)malloc(length);
        [invocation invokeWithTarget:obj];
        [invocation getReturnValue:buffer];
        if(!strcmp(returnType, @encode(BOOL))) {
            returnValue = *((BOOL*)buffer);
        }
        free(buffer);
    }
    return returnValue;
}

id scan(NSScanner *scanner, id obj) {
    id value = obj;
    NSString *singleKey = nil;
    while (!scanner.isAtEnd) {
        BOOL state = NO;
        while ([scanner scanString:@"[" intoString:NULL]) {
            state = YES;
            NSString *arrayIndex = nil;
            [scanner scanUpToString:@"]" intoString: &arrayIndex];
            if ([value isKindOfClass:NSArray.class] && arrayIndex.integerValue < [value count]) {
                value = value[arrayIndex.integerValue];
            } else {
                return nil;
            }
            [scanner scanString:@"]" intoString:NULL];
        }
        if ([scanner scanString:@"." intoString:&singleKey]) {
            if ([scanner scanUpToCharactersFromSet:[NSCharacterSet characterSetWithCharactersInString:@"[."] intoString:&singleKey]) {
                state = YES;
                if ([value isKindOfClass:NSDictionary.class]) {
                    value = value[singleKey];
                } else {
                    return nil;
                }
            }
        }
        if ([scanner scanUpToCharactersFromSet:[NSCharacterSet characterSetWithCharactersInString:@"[."] intoString:&singleKey]) {
            state = YES;
            if ([value isKindOfClass:NSDictionary.class]) {
                value = [value objectForKey:singleKey];
            } else {
                return nil;
            }
        }
        if (!state) {
            return nil;
        }
    }
    return value;
}

id getHandleValue(id scanObj, NSString *isFunc) {
    if (scanObj) {
        if (checkType(scanObj, isFunc)) {
            return scanObj;
        } else {
            if ([isFunc isEqualToString:_is_string] && [scanObj isKindOfClass:NSNumber.class]) {
                return [scanObj stringValue];
            } else if ([isFunc isEqualToString:_is_number] && [scanObj isKindOfClass:NSString.class]) {
                if ([scanObj isEqualToString:@"true"]) {
                    return @(true);
                } else if ([scanObj isEqualToString:@"false"]) {
                    return @(false);
                } else {
                    NSNumberFormatter *numberFormatter = [[NSNumberFormatter alloc] init];
                    [numberFormatter setNumberStyle:NSNumberFormatterDecimalStyle];
                    return [numberFormatter numberFromString:scanObj];
                }
            }
        }
    }
    return nil;
}

#pragma mark - Dictionary

__attribute__((overloadable)) id GetValueFromDict(NSDictionary *dict, NSString *key, NSString *isFunc) {
    return GetValueFromDict(dict, key, isFunc, getDefaultValue(isFunc));
}

__attribute__((overloadable)) id GetValueFromDict(NSDictionary *dict, NSString *key, NSString *isFunc, id defaultValue) {
    if ([dict _is_dictionary]) {
        id scanObj;
        if ([key containsString:@"."] || [key containsString:@"["]) {
            NSScanner *scanner = [NSScanner scannerWithString:key];
            scanObj = getHandleValue(scan(scanner, dict), isFunc);
        } else {
            scanObj = getHandleValue(dict[key], isFunc);
        }
        return scanObj ? : defaultValue;
    }
    return defaultValue;
}

#pragma mark - Array

__attribute__((overloadable)) id GetValueFromArray(NSArray *array, NSString *key, NSString *isFunc) {
    return GetValueFromArray(array, key, isFunc, getDefaultValue(isFunc));
}

__attribute__((overloadable)) id GetValueFromArray(NSArray *array, NSString *key, NSString *isFunc, id defaultValue) {
    if ([array _is_array]) {
        id scanObj;
        if ([key hasPrefix:@"["]) {
            NSScanner *scanner = [NSScanner scannerWithString:key];
            scanObj = getHandleValue(scan(scanner, array), isFunc);
        } else {
            scanObj = nil;
        }
        return scanObj ? : defaultValue;
    }
    return defaultValue;
}

#pragma mark - check

__attribute__((overloadable)) NSString* CheckString(NSString *string, BOOL isLength, id defaultValue) {
    if ([string _is_string]) {
        if (isLength) {
            if (string.length) {
                return string;
            }
        } else {
            return string;
        }
    }
    return defaultValue;
}
__attribute__((overloadable)) NSString* CheckString(NSString *string, BOOL isLength) {
    return CheckString(string, isLength, NSString.new);
}

__attribute__((overloadable)) NSArray* CheckArray(NSArray *array, BOOL isCount, id defaultValue) {
    if ([array _is_array]) {
        if (isCount) {
            if (array.count) {
                return array;
            }
        } else {
            return array;
        }
    }
    return defaultValue;
}
__attribute__((overloadable)) NSArray* CheckArray(NSArray *array, BOOL isCount) {
    return CheckArray(array, isCount, NSArray.new);
}

__attribute__((overloadable)) NSDictionary* CheckDictionary(NSDictionary *dict, BOOL isCount, id defaultValue) {
    if ([dict _is_dictionary]) {
        if (isCount) {
            if (dict.count) {
                return dict;
            }
        } else {
            return dict;
        }
    }
    return defaultValue;
}
__attribute__((overloadable)) NSDictionary* CheckDictionary(NSDictionary *dict, BOOL isCount) {
    return CheckDictionary(dict, isCount, NSDictionary.new);
}
