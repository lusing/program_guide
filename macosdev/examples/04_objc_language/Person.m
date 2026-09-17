#import "Person.h"

static NSString *const MXRenameErrorDomain = @"MXRenameErrorDomain";

@implementation Person

- (instancetype)initWithName:(NSString *)name age:(NSInteger)age {
    self = [super init];
    if (self == nil) {
        return nil;
    }
    _name = [name copy];
    _age = age;
    return self;
}

- (NSString *)greeting {
    return [NSString stringWithFormat:@"你好，我是%@，%ld 岁", self.name, (long)self.age];
}

- (BOOL)renameTo:(NSString *)newName error:(NSError **)error {
    if (newName.length == 0) {
        if (error != NULL) {
            *error = [NSError errorWithDomain:MXRenameErrorDomain
                                         code:1001
                                     userInfo:@{NSLocalizedDescriptionKey: @"名字不能为空"}];
        }
        return NO;
    }
    self.name = newName;
    return YES;
}

- (NSInteger)lengthOfName {
    return self.name.length;
}

- (NSRange)ageRange {
    return NSMakeRange(self.age, 1);
}

- (NSString *)description {
    return [NSString stringWithFormat:@"<Person %@ age=%ld>", self.name, (long)self.age];
}

// MARK: - Speaker

- (NSString *)speakTimes:(NSInteger)times {
    NSMutableString *out = [NSMutableString string];
    for (NSInteger i = 0; i < times; i++) {
        [out appendString:[self greeting]];
        if (i + 1 < times) {
            [out appendString:@" / "];
        }
    }
    return out;
}

@end
