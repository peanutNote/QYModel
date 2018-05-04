//
//  TestModel.h
//  QYModel
//
//  Created by qianye on 2018/4/10.
//  Copyright © 2018年 qianye. All rights reserved.
//

#import "QYModel.h"

@protocol InnerModel
@end

@interface TestModel : QYModel

@property (copy, nonatomic) NSNumber *testId;

@property (copy, nonatomic) NSString *name;

@property (copy, nonatomic) NSString *array;

@property (copy, nonatomic) NSNumber<Ignore> *selected;

@property (copy, nonatomic) NSArray<InnerModel> *inners;

@end
