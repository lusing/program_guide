#import "NSString+Extras.h"

@implementation NSString (MXExtras)

- (NSString *)mx_reversedString {
    NSUInteger length = self.length;
    NSMutableString *out = [NSMutableString stringWithCapacity:length];
    while (length > 0) {
        length -= 1;
        [out appendFormat:@"%C", [self characterAtIndex:length]];
    }
    return out;
}

@end
