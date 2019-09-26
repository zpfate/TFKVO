//
//  NSObject+TFKVO.h
//  TF_KVODemo
//
//  Created by Twisted Fate on 2018/11/29.
//  Copyright © 2018 TwistedFate. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef void(^TF_ObserverBlock)(NSString *oldValue, NSString *newValue);

@interface NSObject (TFKVO)

- (void)tf_addObserver:(NSObject *)observer
            forKeyPath:(NSString *)keyPath
         observerBlock:(TF_ObserverBlock)observerBlock;

- (void)tf_removeObserver:(NSObject *)observer keyPath:(NSString *)keyPath;
@end

NS_ASSUME_NONNULL_END
