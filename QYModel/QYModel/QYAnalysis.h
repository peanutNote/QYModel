//
//  QYAnalysis.h
//  QYModel
//
//  Created by qianye on 2018/5/4.
//  Copyright © 2018年 qianye. All rights reserved.
//

#import "NSObject+QYModelCheckType.h"

/**
 从字典中取值
 
 @param dict 取值字典
 @param key 取值的key，支持多层级如：@"info.name[0][1]"
 @param isFunc 类型校验
 @param defaultValue 默认值
 @return 返回正确类型的值，否则返回默认值
 */
__attribute__((overloadable)) id GetValueFromDict(NSDictionary *dict, NSString *key, NSString *isFunc, id defaultValue);
/// 同上，根据isFunc返回对应默认值
__attribute__((overloadable)) id GetValueFromDict(NSDictionary *dict, NSString *key, NSString *isFunc);

/**
 从数组取值
 
 @param array 取值数组
 @param key 取值的key，支持多层级如：@"[0][1].name"
 @param isFunc 类型校验
 @param defaultValue 默认值
 @return 返回正确类型的值，否则返回默认值
 */
__attribute__((overloadable)) id GetValueFromArray(NSArray *array, NSString *key, NSString *isFunc, id defaultValue);
/// 同上，根据isFunc返回对应默认值
__attribute__((overloadable)) id GetValueFromArray(NSArray *array, NSString *key, NSString *isFunc);

/**
 检测字符串
 
 @param string     字符串对象，如果不是字符返回默认值
 @param isLength    BOOL值，YES字符串必须有长度，NO不检查
 @param defaultValue    上述条件不满足时返回的默认值
 */
__attribute__((overloadable)) NSString* CheckString(NSString *string, BOOL isLength, id defaultValue);
/// 同上，默认值是@""
__attribute__((overloadable)) NSString* CheckString(NSString *string, BOOL isLength);

/**
 检测数组
 
 @param array     数组对象，如果不是数组返回默认值
 @param isCount    BOOL值，YES数组必须有元素，NO不检查
 @param defaultValue    上述条件不满足时返回的默认值
 */
__attribute__((overloadable)) NSArray* CheckArray(NSArray *array, BOOL isCount, id defaultValue);
/// 同上，默认值是@[]
__attribute__((overloadable)) NSArray* CheckArray(NSArray *array, BOOL isCount);

/**
 检测字典
 
 @param dict     字典对象，如果不是字典返回默认值
 @param isCount    BOOL值，YES字典必须有元素，NO不检查
 @param defaultValue    上述条件不满足时返回的默认值
 */
__attribute__((overloadable)) NSDictionary* CheckDictionary(NSDictionary *dict, BOOL isCount, id defaultValue);
/// 同上，默认值是@{}
__attribute__((overloadable)) NSDictionary* CheckDictionary(NSDictionary *dict, BOOL isCount);
