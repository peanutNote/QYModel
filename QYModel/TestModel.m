//
//  TestModel.m
//  QYModel
//
//  Created by qianye on 2018/4/10.
//  Copyright © 2018年 qianye. All rights reserved.
//

#import "TestModel.h"

@implementation TestModel

+ (NSDictionary *)keyMapper {
    return @{
             @"testId" : @"id",
             @"array" : @"infos[0].array"
             };
}

@end
