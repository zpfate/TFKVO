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
    
//    [p tf_addObserver:self forKeyPath:@"name"];
    
    p.name = @"草薙京";
    NSLog(@"class = %@", p.class);
    
}


@end
