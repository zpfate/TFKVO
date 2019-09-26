//
//  ViewController.m
//  TF_KVODemo
//
//  Created by Twisted Fate on 2018/11/29.
//  Copyright © 2018 TwistedFate. All rights reserved.
//

#import "ViewController.h"
#import "Person.h"
#import "NSObject+TFKVO.h"
#import "Student.h"
@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    
    NSString *name = @"keyValue";
    
    NSLog(@"upper = %@",[name uppercaseString]);
    NSLog(@"ca = %@", [name capitalizedString]);
    
    Person *p = [[Person alloc] init];
    Student *s = [[Student alloc] init];

    
//    [p tf_addObserver:self forKeyPath:@"name" observerBlock:^(NSString * _Nonnull oldValue, NSString * _Nonnull newValue) {
//        
//        NSLog(@"person new = %@, old == %@", newValue, oldValue);
//    }];
    
    
    [s tf_addObserver:self forKeyPath:@"age" observerBlock:^(NSString * _Nonnull oldValue, NSString * _Nonnull newValue) {
        NSLog(@"student new = %@, old == %@", newValue, oldValue);
        
    }];
    
    p.name = @"草薙京";
    
    s.age = 100;


    [self test:1];
}

- (void)test:(id)testId {
    NSLog(@"%@", testId);
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context {

}

@end
