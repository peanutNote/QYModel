//
//  NSObject+QYModelCheckType.h
//  QYModel
//
//  Created by qianye on 2017/12/6.
//  Copyright © 2017年 chemanman. All rights reserved.
//

#import <Foundation/Foundation.h>

#define _index_t_key(index) [NSString stringWithFormat:@"[%d]", index]
#define _is_class(cls)  [NSString stringWithFormat:@"_is_class:%@", NSStringFromClass(cls)]

extern NSString *const _is_string;
extern NSString *const _is_number;
extern NSString *const _is_array;
extern NSString *const _is_dictionary;
extern NSString *const _get_integer;
extern NSString *const _get_bool;
extern NSString *const _get_float;

@interface NSObject (QYModelCheckType)

- (BOOL)_is_class:(Class)cls;
- (BOOL)_is_string;
- (BOOL)_is_number;
- (BOOL)_is_array;
- (BOOL)_is_dictionary;

- (BOOL)_checkAvialData;
- (BOOL)_get_integer;
- (BOOL)_get_bool;
- (BOOL)_get_float;

@end
