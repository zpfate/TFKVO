//
//  NSObject+TFKVO.m
//  TF_KVODemo
//
//  Created by Twisted Fate on 2018/11/29.
//  Copyright © 2018 TwistedFate. All rights reserved.
//

#import "NSObject+TFKVO.h"

#import <objc/runtime.h>
#import <objc/message.h>

static char TFKVOObserverObjectsKey;

// TFKVOObeserver
@interface TF_ObserverObject : NSObject

@property (nonatomic, weak) NSObject *observer;
@property (nonatomic, copy) NSString *keyPath;
@property (nonatomic, copy) TF_ObserverBlock observerBlock;

@end

@implementation TF_ObserverObject

- (instancetype)initWitObserver:(id)observer keyPath:(NSString *)keyPath observerBlock:(TF_ObserverBlock)block {
    
    if (self = [super init]) {
        _observer = observer;
        _keyPath = keyPath;
        _observerBlock = block;
    }
    return self;
}

@end


static NSString *const TFKVOClassPrefix = @"TF_KVOClassPrefix"; // 派生类的自定义前缀

@implementation NSObject (TFKVO)

- (void)tf_addObserver:(NSObject *)observer
            forKeyPath:(NSString *)keyPath
         observerBlock:(TF_ObserverBlock)observerBlock {
    
    // 取出对应的set方法
    SEL setter = NSSelectorFromString([self setMethodForKeyPath:keyPath]);
    Method setterMethod = class_getInstanceMethod([self class], setter);

    NSString *errMsg = [NSString stringWithFormat:@"监听对象没有实现属性%@的set方法", keyPath];
    NSAssert(setterMethod, errMsg);

    // 获取类和类名
    Class cls = object_getClass(self);
    NSString *clsName = NSStringFromClass(cls);
    
    if (![clsName hasPrefix:TFKVOClassPrefix]) {
        
        // 生成派生类
        cls = [self createKVOClassWithClsName:clsName];
        // 将self的isa指针指向cls
        object_setClass(self, cls);
    }
    
    // 给派生类添加set方法
    if (![self containsSelector:setter]) {
        const char *types = method_getTypeEncoding(setterMethod);
        class_addMethod(cls, setter, (IMP)kvo_setter, types);
    }
    
    TF_ObserverObject *object = [[TF_ObserverObject alloc] initWitObserver:observer keyPath:keyPath observerBlock:observerBlock];
    
    NSMutableArray *objects = objc_getAssociatedObject(self, &TFKVOObserverObjectsKey);
    if (!objects) {
        objects = [NSMutableArray array];
        objc_setAssociatedObject(self, &TFKVOObserverObjectsKey, objects, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    [objects addObject:object];
}


- (void)tf_removeObserver:(NSObject *)observer keyPath:(NSString *)keyPath {
    
    NSMutableArray *objects = objc_getAssociatedObject(self, &TFKVOObserverObjectsKey);
    for (TF_ObserverObject *object in objects) {
        if (object.observer == object && [object.keyPath isEqualToString:keyPath]) {
            [objects removeObject:object];
            return;
        }
    }
}

// 根据类名创建类
- (Class)createKVOClassWithClsName:(NSString *)clsName {
    
    NSString *kvoClsName = [TFKVOClassPrefix stringByAppendingString:clsName];
    Class cls = NSClassFromString(kvoClsName);
    if (cls) {
        // 已经存在派生类直接返回
        return cls;
    }
    
    // 不存在, 新建派生类
    Class selfClass = object_getClass(self);
    
    // 动态创建类   selfClass的子类 传nil创建一个基类
    Class kvoCls = objc_allocateClassPair(selfClass, kvoClsName.UTF8String, 0);
    
    // 获取类的class实例方法 并重写
    Method instanceMethod = class_getInstanceMethod(kvoCls, @selector(class));
    const char *types = method_getTypeEncoding(instanceMethod);
    class_addMethod(kvoCls, @selector(class), (IMP)kvo_class, types);

    // 将创建的派生类注册
    objc_registerClassPair(kvoCls);
    return kvoCls;
}

// 生成set方法字符串
- (NSString *)setMethodForKeyPath:(NSString *)keyPath {
    
    if (keyPath.length <= 0) {
        return nil;
    }
    // setXxxx
    NSString *firstLetter = [[keyPath substringToIndex:1] uppercaseString];;
    NSString *leftLetters = [keyPath substringFromIndex:1];
    return [NSString stringWithFormat:@"set%@%@:", firstLetter, leftLetters];
}

- (BOOL)containsSelector:(SEL)selector {
    
    Class class = object_getClass(self);
    unsigned int methodCount = 0;
    // 获取当前类的已有的方法
    Method *methodList = class_copyMethodList(class, &methodCount);
    for (unsigned int i = 0; i < methodCount; i++) {
        SEL methodSelector = method_getName(methodList[i]);
        if (methodSelector == selector) {
            free(methodList);
            return YES;
        }
    }
    free(methodList);
    return NO;
}

static Class kvo_class(id self, SEL _cmd) {
    // 指向父类
    return class_getSuperclass(object_getClass(self));
}


static void kvo_setter(id self, SEL _cmd, id newValue) {
    
    NSString *setterName = NSStringFromSelector(_cmd);
    NSString *getterName = [self getterNameWithSetterName:setterName];
    
    // 获取get实例方法
    SEL getter = NSSelectorFromString(getterName);
    Method getterMethod = class_getInstanceMethod([self class], getter);
    NSString *noGetterErrorMsg = [NSString stringWithFormat:@"需要监听的对象没有实现getter方法"];
    NSAssert(getterMethod, noGetterErrorMsg);
    
    // 获取旧值
    id oldValue = [self valueForKey:getterName];
    
    // 赋值新值
    
    // 构建objc_super的结构体
    struct objc_super superClass = {
        .receiver = self,
        .super_class = class_getSuperclass(object_getClass(self))
    };
    
    // 编译器报错
    // Build Setting Enable Strict Checking of objc_msgSend Calls改为NO
//    objc_msgSendSuper(&superClass, _cmd, newValue);
    
    // 发送消息set方法赋值
    void (*objc_msgSendSuperCasted)(void *, SEL, id) = (void *)objc_msgSendSuper;
    objc_msgSendSuperCasted(&superClass, _cmd, newValue);
    
    // 应该block回去
    NSMutableArray *objects = objc_getAssociatedObject(self, &TFKVOObserverObjectsKey);
    for (TF_ObserverObject *object in objects) {
        
        if ([object.keyPath isEqualToString:getterName]) {
            object.observerBlock(oldValue, newValue);
            break;
        }
    }
}

- (NSString *)getterNameWithSetterName:(NSString *)setterName {
    if (setterName.length <=0 || ![setterName hasPrefix:@"set"] || ![setterName hasSuffix:@":"]) {
        return nil;
    }
    NSRange range = NSMakeRange(3, setterName.length - 4);
    NSString *key = [setterName substringWithRange:range];
    NSString *firstLetter = [[key substringToIndex:1] lowercaseString];
    key = [key stringByReplacingCharactersInRange:NSMakeRange(0, 1) withString:firstLetter];
    return key;
}

@end
