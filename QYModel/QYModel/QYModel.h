//
//  QYModel.h
//  QYModel
//
//  Created by qianye on 2018/5/4.
//  Copyright © 2018年 qianye. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "QYAnalysis.h"

#define _index_t_key(index) [NSString stringWithFormat:@"[%d]", index]
#define _is_class(cls)  [NSString stringWithFormat:@"_is_class:%@", NSStringFromClass(cls)]

#pragma mark - Property Protocols
/**
 * 模型解析时会忽略该属性
 */
@protocol Ignore
@end

/**
 * 当Model中的属性名在json中不存在时ignore，否则会取默认值已确保数据安全
 */
@protocol NilWhenNull
@end

/**
 标记该属性名相对json中的key是否采用了驼峰命名方式，此优先级低于keyMapper中的映射关系
 */
@protocol CamelCase
@end

@interface NSObject (QYModelPropertyCompatibility) <Ignore, NilWhenNull, CamelCase>

@end


@interface QYModel : NSObject

/**
 重新确定映射关系，健值对书写为 json中key : model中属性名，其中json中key支持多级取值如：@"info.name[0][1]"
 */
+ (NSDictionary *)keyMapper;

/**
 CCModel唯一创建方法
 
 @param dictionary json数据
 */
- (instancetype)initWithDictionary:(NSDictionary *)dictionary;

@end


/// CCModel 扩展
@interface QYModel (QYModelExtensionMethods)

#define QYModelCombinationDict(completeDict) {va_list firstList; va_start(firstList, dictionary); \
        if(dictionary) { [completeDict addEntriesFromDictionary:dictionary]; \
            NSDictionary *arg; while ((arg = va_arg(firstList, NSDictionary *))) { \
                [completeDict addEntriesFromDictionary:arg]; } \
            va_end(firstList); }}

/// 将模型转变成对应字典
- (NSDictionary *)toDictionary;

/**
 CCModel创建扩展方法
 
 @param dictionary 支持传多个json
 */
- (instancetype)initWithDictionarys:(NSDictionary *)dictionary, ... NS_REQUIRES_NIL_TERMINATION;

/**
 初始化Model各属性字段默认值
 */
- (void)setDefaultValue;

/**
 属性名带下划线自动转成驼峰形式
 */
+ (NSDictionary *)mapperForCamelCase;

@end
