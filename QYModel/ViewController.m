//
//  ViewController.m
//  QYModel
//
//  Created by qianye on 2018/5/4.
//  Copyright © 2018年 qianye. All rights reserved.
//

#import "ViewController.h"
#import "TestModel.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    NSDictionary *testDict = @{
                               @"id" : @1234,
                               @"name" : @"text",
                               @"infos" : @[@{@"array" : @"1"}],
                               @"inners" : @[@{
                                                 @"title" : @"github",
                                                 @"source_t" : @"https://github.com/peanutNote"
                                                 }]
                               };
    TestModel *testModel = [[TestModel alloc] initWithDictionary:testDict];
    NSLog(@"testModel : %@", testModel);
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
