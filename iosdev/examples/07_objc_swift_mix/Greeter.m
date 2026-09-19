#import "Greeter.h"

@implementation Greeter {
    NSMutableArray<NSString *> *_names;
}

- (instancetype)initWithName:(NSString *)name {
    self = [super init];
    if (self) {
        _name = [name copy];
        _names = [NSMutableArray array];
    }
    return self;
}

- (NSString *)greet:(NSString *)who {
    return [NSString stringWithFormat:@"%@ 你好，%@", self.name, who];
}

- (NSArray<NSString *> *)names {
    return [_names copy];   // 对外暴露不可变副本
}

- (BOOL)loadNamesFrom:(NSString *)text error:(NSError **)error {
    if (text.length == 0) {
        if (error) {
            *error = [NSError errorWithDomain:@"GreeterErrorDomain" code:1
                                     userInfo:@{NSLocalizedDescriptionKey: @"空输入"}];
        }
        return NO;
    }
    [_names addObjectsFromArray:[text componentsSeparatedByString:@","]];
    return YES;
}

@end

