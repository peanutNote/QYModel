//
//  QYModel.m
//  QYModel
//
//  Created by qianye on 2018/5/4.
//  Copyright © 2018年 qianye. All rights reserved.
//

#import "QYModel.h"
#import <objc/runtime.h>
#import <objc/message.h>
#import <UIKit/UIKit.h>

@interface QYModelProperty : NSObject

@property (nonatomic, copy) NSString *name;

@property (nonatomic, copy) NSString *type;

@property (nonatomic, copy) NSString *protocol;

@property (nonatomic, assign) SEL getterMethod;

@property (nonatomic, assign) SEL setterMethod;

@property (nonatomic, assign) BOOL isAssignNilWhenNull;

@property (nonatomic, assign) BOOL isObject;

@property (nonatomic, assign) BOOL isCamelCase;

- (BOOL)isPropertyRootClass:(id)value;
- (NSString *)getCamelCaseName;

@end

@implementation QYModelProperty

- (BOOL)isPropertyRootClass:(id)value {
    if ([_type isEqualToString:@"NSMutableString"]) {
        return [value isKindOfClass:class_getSuperclass(NSMutableString.class)];
    } else if ([_type isEqualToString:@"NSMutableArray"]) {
        return [value isKindOfClass:class_getSuperclass(NSMutableArray.class)];
    } else if ([_type isEqualToString:@"NSMutableDictionary"]) {
        return [value isKindOfClass:class_getSuperclass(NSMutableDictionary.class)];
    } else {
        return [value isKindOfClass:NSClassFromString(_type)];
    }
}

- (NSString *)getCamelCaseName {
    NSMutableString *result = [NSMutableString stringWithString:_name];
    NSRange range;
    
    range = [result rangeOfCharacterFromSet:[NSCharacterSet uppercaseLetterCharacterSet]];
    while (range.location != NSNotFound) {
        NSString *lower = [result substringWithRange:range].lowercaseString;
        [result replaceCharactersInRange:range withString:[NSString stringWithFormat:@"_%@", lower]];
        range = [result rangeOfCharacterFromSet:[NSCharacterSet uppercaseLetterCharacterSet]];
    }
    
    range = [result rangeOfCharacterFromSet:[NSCharacterSet decimalDigitCharacterSet]];
    while (range.location != NSNotFound) {
        NSRange end = [result rangeOfString:@"\\D" options:NSRegularExpressionSearch range:NSMakeRange(range.location, result.length - range.location)];
        if (end.location == NSNotFound) {
            end = NSMakeRange(result.length, 1);
        }
        NSRange replaceRange = NSMakeRange(range.location, end.location - range.location);
        NSString *digits = [result substringWithRange:replaceRange];
        [result replaceCharactersInRange:replaceRange withString:[NSString stringWithFormat:@"_%@", digits]];
        range = [result rangeOfCharacterFromSet:[NSCharacterSet decimalDigitCharacterSet] options:0 range:NSMakeRange(end.location + 1, result.length - end.location - 1)];
    }
    return result;
}

@end

#define QYDictionaryNotCorrect() \
    @throw [NSException exceptionWithName:NSInternalInconsistencyException \
                                    reason:[NSString stringWithFormat:@"dictionary类型不匹配"] \
                                userInfo:nil]

static const char * kClassPropertiesKey;
static const char * kMapperObjectKey;
static const char * kmapperForCamelCase;

@implementation QYModel

+ (NSDictionary *)keyMapper {
    return nil;
}

- (instancetype)init {
    if (self = [super init]) {
        [self setup];
    }
    return self;
}

- (NSString *)description {
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    for (QYModelProperty *property in [self getPropertys]) {
        if ([self respondsToSelector:property.getterMethod]) {
            NSMethodSignature *signature = [self methodSignatureForSelector:property.getterMethod];
            NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:signature];
            [invocation setSelector:property.getterMethod];
            const char *returnType = signature.methodReturnType;
            //声明返回值变量
            id __unsafe_unretained returnValue;
            //如果没有返回值
            if(!strcmp(returnType, @encode(void))){
                returnValue = @"";
            } else if(!strcmp(returnType, @encode(id))) {
                [invocation invokeWithTarget:self];
                [invocation getReturnValue:&returnValue];
            } else {
                //如果返回值为普通类型NSInteger  BOOL
                NSUInteger length = [signature methodReturnLength];
                void *buffer = (void *)malloc(length);
                [invocation invokeWithTarget:self];
                [invocation getReturnValue:buffer];
                if(!strcmp(returnType, @encode(BOOL))) {
                    returnValue = [NSNumber numberWithBool:*((BOOL*)buffer)];
                } else if( !strcmp(returnType, @encode(NSInteger)) ){
                    returnValue = [NSNumber numberWithInteger:*((NSInteger*)buffer)];
                } else if( !strcmp(returnType, @encode(int)) ){
                    returnValue = [NSNumber numberWithInt:*((int*)buffer)];
                } else if( !strcmp(returnType, @encode(CGFloat)) ){
                    returnValue = [NSNumber numberWithFloat:*((CGFloat*)buffer)];
                } else if( !strcmp(returnType, @encode(double)) ){
                    returnValue = [NSNumber numberWithDouble:*((double*)buffer)];
                } else {
                    returnValue = [NSValue valueWithBytes:buffer objCType:returnType];
                }
                free(buffer);
            }
            [dict setObject:returnValue ? : @"" forKey:property.name];
        }
    }
    return dict.description;
}

/**
 初始化配置，绑定自定义映射及Model属性信息
 */
- (void)setup {
    NSDictionary *mapper = [self.class keyMapper];
    if ( mapper && !objc_getAssociatedObject(self.class, &kMapperObjectKey) ) {
        objc_setAssociatedObject(
                                 self.class,
                                 &kMapperObjectKey,
                                 mapper,
                                 OBJC_ASSOCIATION_RETAIN // This is atomic
                                 );
    }
    
    if (!objc_getAssociatedObject(self.class, &kClassPropertiesKey)) {
        [self inspectProperties];
    }
}

- (instancetype)initWithDictionary:(NSDictionary *)dictionary {
    self = [self init];
    if ([dictionary isKindOfClass:NSDictionary.class]) {
        [self importDictionary:dictionary withKeyMapper:self.getKeyMapper];
    } else {
        [self setDefaultValue];
    }
    return self;
}

/**
 确定映射关系以及赋值方式
 
 @param dict 需要解析的json
 @param keyMapper 映射关系字典
 */
- (void)importDictionary:(NSDictionary*)dict withKeyMapper:(NSDictionary *)keyMapper {
    for (QYModelProperty *property in self.getPropertys) {
        NSString *jsonKeyPath;
        if (keyMapper) {
            jsonKeyPath = [keyMapper objectForKey:property.name] ? : property.name;
        } else {
            jsonKeyPath = property.isCamelCase ? [property getCamelCaseName] : property.name;
        }
        id jsonValue = GetValueFromDict(dict, jsonKeyPath, _is_class(NSObject.class), nil);
        if (jsonValue) {
            if (property.isObject) {
                [self assginObjectProperty:property withJsonValue:jsonValue];
            } else {
                [self assginProperty:property withJsonValue:jsonValue];
            }
        } else {
            if (!property.isAssignNilWhenNull && property.isObject) {
                [self assginObjectProperty:property withJsonValue:nil];
            }
        }
    }
}

/**
 给Model对象属性赋值
 
 @param property Model属性信息
 @param jsonValue 对应json中的数据
 */
- (void)assginObjectProperty:(QYModelProperty *)property withJsonValue:(id)jsonValue {
    id finallValue = jsonValue;
    if ([property isPropertyRootClass:jsonValue]) {
        // 类型匹配(包括父类)
        if ([jsonValue isKindOfClass:[NSArray class]]) {
            finallValue = [self assginToArrayWithProperty:property value:jsonValue];
        } else if ([jsonValue isKindOfClass:[NSString class]]) {
            if ([property.type isEqualToString:@"NSMutableString"]) {
                finallValue = [[NSMutableString alloc] initWithString:jsonValue];
            } else {
                finallValue = jsonValue;
            }
        } else if ([jsonValue isKindOfClass:[NSDictionary class]]) {
            if ([property.type isEqualToString:@"NSMutableDictionary"]) {
                finallValue = [[NSMutableDictionary alloc] initWithDictionary:jsonValue];
            }
        }
    } else {
        // 类型不匹配
        if ([property.type isEqualToString:@"NSString"]) {
            if ([jsonValue isKindOfClass:[NSNumber class]]) {
                finallValue = [jsonValue stringValue];
            } else {
                finallValue = NSString.new;
            }
        } else if ([property.type isEqualToString:@"NSMutableString"]) {
            if ([jsonValue isKindOfClass:[NSNumber class]]) {
                finallValue = [[jsonValue stringValue] mutableCopy];
            } else {
                finallValue = NSMutableString.new;
            }
        } else if ([property.type isEqualToString:@"NSNumber"]) {
            if ([jsonValue isKindOfClass:[NSString class]]) {
                NSNumberFormatter *numberFormatter = [[NSNumberFormatter alloc] init];
                [numberFormatter setNumberStyle:NSNumberFormatterDecimalStyle];
                finallValue = [numberFormatter numberFromString:jsonValue] ? : @0;
            } else {
                finallValue = @0;
            }
        } else if ([property.type isEqualToString:@"NSArray"]) {
            finallValue = NSArray.new;
        } else if ([property.type isEqualToString:@"NSMutableArray"]) {
            finallValue = NSMutableArray.new;
        } else if ([property.type isEqualToString:@"NSDictionary"]) {
            finallValue = NSDictionary.new;
        } else if ([property.type isEqualToString:@"NSMutableDictionary"]) {
            finallValue = NSMutableDictionary.new;
        } else {
            // 自定义类型
            Class propertyClass = NSClassFromString(property.type);
            if (propertyClass) {
                if ([jsonValue isKindOfClass:[NSDictionary class]]) {
                    finallValue = [[propertyClass alloc] initWithDictionary:jsonValue];
                } else {
                    finallValue = nil;
                }
            } else {
                finallValue = nil;
            }
        }
    }
    objc_msgSendObject(self, property.setterMethod, finallValue);
}

/**
 给Model对象数组且需要解析数组内容的数据赋值
 
 @param property Model属性信息
 @param value 对应json中的数据
 @return 解析后的数据
 */
- (id)assginToArrayWithProperty:(QYModelProperty *)property value:(id)value {
    if (property.protocol) {
        Class propertyClass = NSClassFromString(property.protocol);
        if (propertyClass) {
            NSMutableArray *tempArray = NSMutableArray.new;
            for (NSDictionary *dict in value) {
                id subValue = [[propertyClass alloc] initWithDictionary:dict];
                [tempArray addObject:subValue];
            }
            if ([property.type isEqualToString:@"NSArray"]) {
                return tempArray.copy;
            } else {
                return tempArray;
            }
        }
    }
    return value;
}

/**
 给Model对象基本数据类型赋值，type判断参考：https://developer.apple.com/library/content/documentation/Cocoa/Conceptual/ObjCRuntimeGuide/Articles/ocrtTypeEncodings.html
 
 @param property Model属性信息
 @param jsonValue 对应json中的数据
 */
- (void)assginProperty:(QYModelProperty *)property withJsonValue:(id)jsonValue {
    if ([property.type isEqualToString:@"i"]) { // int类型
        objc_msgSendInt(self, property.setterMethod, [jsonValue intValue]);
    } else if ([property.type isEqualToString:@"q"]) { // NSInteger类型
        objc_msgSendInteger(self, property.setterMethod, [jsonValue integerValue]);
    } else if ([property.type isEqualToString:@"f"]) { // float类型
        objc_msgSendFloat(self, property.setterMethod, [jsonValue floatValue]);
    } else if ([property.type isEqualToString:@"d"]) { // double类型
        objc_msgSendDouble(self, property.setterMethod, [jsonValue doubleValue]);
    } else if ([property.type isEqualToString:@"B"]) { // BOOL类型
        objc_msgSendBOOL(self, property.setterMethod, [jsonValue boolValue]);
    }
}

/// 参考：https://stackoverflow.com/questions/2573805/using-objc-msgsend-to-call-a-objective-c-function-with-named-arguments/2573949#2573949
void (*objc_msgSendInt)(id self, SEL _cmd, int) = (void*)objc_msgSend;
void (*objc_msgSendInteger)(id self, SEL _cmd, NSInteger) = (void*)objc_msgSend;
void (*objc_msgSendFloat)(id self, SEL _cmd, float) = (void*)objc_msgSend;
void (*objc_msgSendDouble)(id self, SEL _cmd, double) = (void*)objc_msgSend;
void (*objc_msgSendBOOL)(id self, SEL _cmd, BOOL) = (void*)objc_msgSend;
void (*objc_msgSendObject)(id self, SEL _cmd, id) = (void*)objc_msgSend;

- (BOOL)checkPropertyType:(QYModelProperty *)property value:(id)value {
    if ([value isKindOfClass:NSClassFromString(property.type)]) {
        return YES;
    } else {
        if ([value isKindOfClass:[NSArray class]]) {
            if ([property.type isEqualToString:@"NSMutableArray"]) {
                return YES;
            }
        }
    }
    return NO;
}

/**
 解析Model中的属性信息，并绑定包含属性信息的数组
 */
- (void)inspectProperties {
    unsigned int propertyCount;
    NSString* propertyType = nil;
    NSMutableArray *propertyArray = NSMutableArray.new;

    objc_property_t *properties = class_copyPropertyList([self class], &propertyCount);
    for (unsigned int i = 0; i < propertyCount; i++ ) {
        QYModelProperty *p = [[QYModelProperty alloc] init];
        
        objc_property_t property = properties[i];
        const char *propertyName = property_getName(property);
        p.name = @(propertyName);
        
        const char *attrs = property_getAttributes(property);
        NSString *propertyAttributes = @(attrs);
        NSArray *attributeItems = [propertyAttributes componentsSeparatedByString:@","];
        
        // 忽略read-only属性
        if ([attributeItems containsObject:@"R"]) {
            continue;
        }
        
        //check for 64b BOOLs
        if ([propertyAttributes hasPrefix:@"Tc,"]) {
            //mask BOOLs as structs so they can have custom converters
        }
        
        NSScanner *scanner = [NSScanner scannerWithString: propertyAttributes];
        [scanner scanUpToString:@"T" intoString: &propertyType];
        [scanner scanString:@"T" intoString:&propertyType];
        if ([scanner scanString:@"@\"" intoString: &propertyType]) {
            [scanner scanUpToCharactersFromSet:[NSCharacterSet characterSetWithCharactersInString:@"\"<"] intoString:&propertyType];
            p.type = propertyType;
            p.isObject = YES;
            while ([scanner scanString:@"<" intoString:NULL]) {
                NSString* protocolName = nil;
                [scanner scanUpToString:@">" intoString: &protocolName];
                if ([protocolName isEqualToString:@"Ignore"]) {
                    p = nil;
                } else if ([protocolName isEqualToString:@"NilWhenNull"]) {
                    p.isAssignNilWhenNull = YES;
                } else if ([protocolName isEqualToString:@"CamelCase"]) {
                    p.isCamelCase = YES;
                } else {
                    p.protocol = protocolName;
                }
                [scanner scanString:@">" intoString:NULL];
            }
        } else if ([scanner scanString:@"{" intoString: &propertyType]) {
            [scanner scanCharactersFromSet:[NSCharacterSet alphanumericCharacterSet]
                                intoString:&propertyType];
            // 结构体
            p = nil;
        } else {
            [scanner scanUpToCharactersFromSet:[NSCharacterSet characterSetWithCharactersInString:@","]
                                    intoString:&propertyType];
            // 基本数据类型
            p.type = propertyType;
        }
        if (p) {
            // 创建getter方法
            SEL getter = NSSelectorFromString(p.name);
            if ([self respondsToSelector:getter])
                p.getterMethod = getter;
            
            // 创建setter方法
            NSString *firstStr = [[p.name substringToIndex:1] uppercaseString];
            NSString *endStr = [p.name substringFromIndex:1];
            NSString *setterMethod = [NSString stringWithFormat:@"set%@%@:",firstStr,endStr];
            SEL setter = NSSelectorFromString(setterMethod);
            if ([self respondsToSelector:setter]) {
                p.setterMethod = setter;
            }
            // 确定驼峰命名形式
            p.isCamelCase = [objc_getAssociatedObject(self.class, &kmapperForCamelCase) boolValue];
            [propertyArray addObject:p];
        }
    }
    free(properties);
    objc_setAssociatedObject(self.class, &kClassPropertiesKey, [propertyArray copy], OBJC_ASSOCIATION_RETAIN);
}

/**
 获取自定义映射关系自定
 */
- (NSDictionary *)getKeyMapper {
    return objc_getAssociatedObject(self.class, &kMapperObjectKey);
}
/**
 获取包含属性信息的数组
 */
- (NSArray<QYModelProperty *> *)getPropertys {
    NSArray* classProperties = objc_getAssociatedObject(self.class, &kClassPropertiesKey);
    if (classProperties) return classProperties;
    [self setup];
    classProperties = objc_getAssociatedObject(self.class, &kClassPropertiesKey);
    return classProperties;
}

- (BOOL)checkValueClassForDictionary:(NSObject *)value {
    if (value == nil) {
        return NO;
    }
    if ([value isKindOfClass:[NSArray class]] || [value isKindOfClass:[NSMutableArray class]] || [value isKindOfClass:[NSNumber class]] || [value isKindOfClass:[NSDictionary class]] || [value isKindOfClass:[NSMutableDictionary class]] || [value isKindOfClass:[NSString class]] || [value isKindOfClass:[NSMutableString class]]) {
        return YES;
    }
    return NO;
}

@end

@implementation QYModel (QYModelExtensionMethods)

- (NSDictionary *)toDictionary {
    NSMutableDictionary *tempDict = [NSMutableDictionary dictionary];
    for (QYModelProperty *property in [self getPropertys]) {
        if ([self respondsToSelector:property.getterMethod]) {
            id value = [self valueForKey:property.name];
            if ([self checkValueClassForDictionary:value]) {
                [tempDict setObject:value forKey:property.name];
            } else if ([value isKindOfClass:QYModel.class]) {
                [tempDict setObject:[(QYModel *)value toDictionary] forKey:property.name];
            } else {
                if ([property.type isEqualToString:@"i"]) { // int类型
                    [tempDict setObject:@([(NSNumber *)value intValue]) forKey:property.name];
                } else if ([property.type isEqualToString:@"q"]) { // NSInteger类型
                    [tempDict setObject:@([(NSNumber *)value integerValue]) forKey:property.name];
                } else if ([property.type isEqualToString:@"f"]) { // float类型
                    [tempDict setObject:@([(NSNumber *)value floatValue]) forKey:property.name];
                } else if ([property.type isEqualToString:@"d"]) { // double类型
                    [tempDict setObject:@([(NSNumber *)value doubleValue]) forKey:property.name];
                } else if ([property.type isEqualToString:@"B"]) { // BOOL类型
                    [tempDict setObject:@([(NSNumber *)value boolValue]) forKey:property.name];
                } else {
                    [tempDict setObject:@"" forKey:property.name];
                }
            }
        }
    }
    return tempDict.copy;
}

- (void)setDefaultValue {
    [self importDictionary:@{} withKeyMapper:self.getKeyMapper];
}

- (instancetype)initWithDictionarys:(NSDictionary *)dictionary, ... NS_REQUIRES_NIL_TERMINATION {
    NSMutableDictionary *completeDict = [NSMutableDictionary dictionary];
    QYModelCombinationDict(completeDict);
    self = [self init];
    [self importDictionary:completeDict withKeyMapper:self.getKeyMapper];
    return self;
}

+ (NSDictionary *)mapperForCamelCase {
    objc_setAssociatedObject(self, &kmapperForCamelCase, @(YES), OBJC_ASSOCIATION_RETAIN);
    return nil;
}

@end
