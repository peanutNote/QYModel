#  QYModel使用说明

### QYModelDefine
* _index_t_key : 宏定义，用作QYDataAnalysis中解析数组传入index用，如：_index_t_key(1)，转化为@"[1]"
* _is_class : 宏定义，用作QYDataAnalysis中解析数据判断是否为某个类，如：_is_class(@"UILabel")，表示判断是否为UILabel对象

### QYDataAnalysis

1、从字典中取值

```objc
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
```

2、从数组取值

```objc
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
```

3、检测字符串

```objc
/**
 检测字符串
 @param string     字符串对象，如果不是数组返回默认值
 @param isLength    BOOL值，YES字符串必须有长度，NO不检查
 @param defaultValue    上述条件不满足时返回的默认值
*/
__attribute__((overloadable)) NSString* CheckString(NSString *string, BOOL isLength, id defaultValue);
/// 同上，默认值是@""
__attribute__((overloadable)) NSString* CheckString(NSString *string, BOOL isLength);
```

4、检测数组

```objc
/**
 检测数组
 @param array     数组对象，如果不是数组返回默认值
 @param isCount    BOOL值，YES数组必须有元素，NO不检查
 @param defaultValue    上述条件不满足时返回的默认值
*/
__attribute__((overloadable)) NSArray* CheckArray(NSArray *array, BOOL isCount, id defaultValue);
/// 同上，默认值是@[]
__attribute__((overloadable)) NSArray* CheckArray(NSArray *array, BOOL isCount);
```

5、检测字典

```objc
/**
 检测字典
 @param dict     字典对象，如果不是数组返回默认值
 @param isCount    BOOL值，YES字典必须有元素，NO不检查
 @param defaultValue    上述条件不满足时返回的默认值
*/
__attribute__((overloadable)) NSDictionary* CheckDictionary(NSDictionary *dict, BOOL isCount, id defaultValue);
/// 同上，默认值是@{}
__attribute__((overloadable)) NSDictionary* CheckDictionary(NSDictionary *dict, BOOL isCount);
```

### NSObject+QYModelCheckType
辅助QYDataAnalysis类入参：isFunc

### QYModel
数据模型解析基类，使用方法：创建一个继承自QYModel的模型类，添加与json中key名字相同的属性，使用`- (instancetype)initWithDictionary:(NSDictionary *)dictionary`方法创建对象即可

* 当属姓名与json中key不一样时，可以在模型类中重写：

```objc
/**
 重新确定映射关系，健值对书写为 json中key : model中属性名，其中json中key支持多级取值如：@"info.name[0][1]"
*/
- (NSDictionary *)QYKeyMapper;
```

* 当模型数据在不同的json中时，可以使用`- (instancetype)initWithDictionarys:(NSDictionary *)dictionary, ... NS_REQUIRES_NIL_TERMINATION`传入多个json
* 当有非常特殊的参数需要单独处理时，可以在模型类中重写初始化方法：

```objc
// 单个json解析
- (instancetype)initWithDictionary:(NSDictionary *)dictionary {
    if (self = [super initWithDictionary:dictionary]) {
        // do after custom analysis
    }
    return self;
}

// 多个json解析
- (instancetype)initWithDictionarys:(NSDictionary *)dictionary, ... {
    NSMutableDictionary *multiDictionary = [NSMutableDictionary dictionary];
    QYModelCombinationDict(multiDictionary);
    if (self = [super initWithDictionary:multiDictionary]) {
        // do after custom analysis
    }
    return self;
}
```

* 将模型转变成对应字典：`- (NSDictionary *)toDictionary`
* 初始化Model各属性字段默认值：`- (void)setDefaultValue`
