#import "Person.h"

// 自定义错误域：NSError 的 domain 是一个反向 DNS 风格的字符串常量。
static NSString *const MXRenameErrorDomain = @"MXRenameErrorDomain";

@implementation Person

// 指定初始化器的标准四步：调 super 的 init → 判空 → 赋值 ivar → 返回 self。
- (instancetype)initWithName:(NSString *)name age:(NSInteger)age {
    self = [super init];
    if (self == nil) {
        return nil;                 // super 初始化失败，必须原样返回 nil
    }
    _name = [name copy];            // 在 init 里直接写 ivar（_name），不走 setter
    _age = age;
    return self;
}

- (NSString *)greeting {
    // %@ 打印对象（走 description），%ld 打印 NSInteger（要强转 long）。
    return [NSString stringWithFormat:@"你好，我是%@，%ld 岁", self.name, (long)self.age];
}

- (BOOL)renameTo:(NSString *)newName error:(NSError **)error {
    if (newName.length == 0) {
        if (error != NULL) {        // 调用方可能传 NULL，不想要 error
            *error = [NSError errorWithDomain:MXRenameErrorDomain
                                         code:1001
                                     userInfo:@{NSLocalizedDescriptionKey: @"名字不能为空"}];
        }
        return NO;
    }
    self.name = newName;            // 走 setter（这里是点语法 = setName:）
    return YES;
}

// readonly 属性的 getter 要自己实现。
- (NSInteger)lengthOfName {
    return self.name.length;
}

- (NSInteger)doubleAge {
    return self.age * 2;
}

- (NSRange)ageRange {
    return NSMakeRange(self.age, 1);
}

// 重写 description，让 %@ / NSLog 打印出有用的东西，而不是 <Person: 0x…>。
- (NSString *)description {
    return [NSString stringWithFormat:@"<Person %@ age=%ld>", self.name, (long)self.age];
}

#pragma mark - Speaker

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

// @optional 的方法，这里选择实现。调用方仍应先 respondsToSelector: 再调。
- (NSString *)whisper {
    return [NSString stringWithFormat:@"（%@ 小声说）", self.name];
}

@end
