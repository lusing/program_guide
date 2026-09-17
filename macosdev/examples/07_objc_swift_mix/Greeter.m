#import "Greeter.h"

@implementation Greeter {
    NSMutableArray<NSString *> *_names;
}

- (instancetype)init {
    if ((self = [super init])) {
        _name = @"";
        _names = [NSMutableArray array];
    }
    return self;
}

- (NSString *)greet:(NSString *)who {
    return [NSString stringWithFormat:@"%@ says hello to %@", self.name, who];
}

- (BOOL)loadNamesFrom:(NSString *)text error:(NSError **)error {
    NSArray<NSString *> *parts = [text componentsSeparatedByString:@","];
    if (parts.count == 0) {
        if (error) {
            *error = [NSError errorWithDomain:@"Greeter"
                                         code:1
                                     userInfo:@{ NSLocalizedDescriptionKey: @"空输入" }];
        }
        return NO;
    }
    [_names removeAllObjects];
    for (NSString *p in parts) {
        [_names addObject:[p stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]]];
    }
    return YES;
}

- (NSArray<NSString *> *)names {
    return [_names copy];
}

- (void)forEachName:(void (^)(NSString *, NSUInteger))block {
    [_names enumerateObjectsUsingBlock:^(NSString *obj, NSUInteger idx, BOOL *stop) {
        block(obj, idx);
    }];
}

@end

@implementation LegacyNote

// 故意写成方法而不是 @property：这样 Swift 侧导入的是 func text() -> String!，
// 一眼就能看出「没加 nullability 注解」长什么样。
- (NSString *)text {
    return @"来自 OC 的老字符串";
}

@end
