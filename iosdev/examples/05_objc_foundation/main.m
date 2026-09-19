// ============================================================
// 05 - Foundation 值类型与集合（Objective-C 篇）
//   NSString / NSNumber / NSValue / NSNull / NSArray / NSDictionary / NSSet
//   / NSData / NSCalendar / NSJSONSerialization
//
// Foundation 是跨 Apple 平台通用的：这里的每一个类，在 macOS 上一字不差。
// iOS 上你还会天天遇到 UserDefaults、plist、Codable（第 18 章），底下都是这套。
// 本章只讲 OC 特有的坑；Swift 侧的桥接差异见第 06 章。
//
// 纯 OC，clang 编译；输出用 printf（不用 NSLog，保持 stderr 为空）。
// ============================================================

#import <Foundation/Foundation.h>

static int gFailures = 0;
static void expect(BOOL condition, NSString *desc) {
    printf("  %s %s\n", condition ? "ok  " : "FAIL", [desc UTF8String]);
    if (!condition) { gFailures += 1; }
}
static void line(NSString *s) { printf("%s\n", [s UTF8String]); }

int main(void) {
    @autoreleasepool {

        // ---------------------------------------------------------- 1) NSString
        // NSString 内部是 UTF-16，所以 length 是「UTF-16 码元个数」，不是用户看到的
        // 字符个数。带 emoji 或组合音标时两者会差很多。
        line(@"== NSString 与 Unicode ==");
        NSString *precomposed = @"café";          // é 是一个码位
        NSString *decomposed  = @"cafe\u0301";    // e + 组合重音符
        line([NSString stringWithFormat:@"  precomposed length=%lu", (unsigned long)precomposed.length]);
        line([NSString stringWithFormat:@"  decomposed  length=%lu", (unsigned long)decomposed.length]);
        expect(precomposed.length == 4, @"预组合 é 只占一个 UTF-16 码元");
        expect(decomposed.length == 5, @"分解写法占两个码元（e + U+0301）");
        expect([precomposed isEqualToString:decomposed] == NO, @"两种写法直接比较不相等");
        NSString *canonA = [precomposed precomposedStringWithCanonicalMapping];
        NSString *canonB = [decomposed  precomposedStringWithCanonicalMapping];
        expect([canonA isEqualToString:canonB], @"规范化之后两者相等");

        NSString *emoji = @"👍🏽";                   // thumbs-up + 肤色修饰符
        line([NSString stringWithFormat:@"  emoji length=%lu", (unsigned long)emoji.length]);
        expect(emoji.length == 4, @"emoji 的 length 也是 UTF-16 码元数（代理对 + 修饰符）");

        // ------------------------------------------------------- 2) 拼接与查找
        line(@"");
        line(@"== 拼接、切分、查找 ==");
        NSString *joined = [@[@"Swift", @"Objective-C", @"Cocoa"] componentsJoinedByString:@" / "];
        expect([joined isEqualToString:@"Swift / Objective-C / Cocoa"], @"数组拼成字符串");
        NSArray<NSString *> *parts = [joined componentsSeparatedByString:@" / "];
        expect(parts.count == 3 && [parts[1] isEqualToString:@"Objective-C"], @"按分隔符切回 3 段");
        NSRange found = [joined rangeOfString:@"Cocoa"];
        expect(found.location == 22, @"rangeOfString 给的是 UTF-16 偏移");
        NSRange missing = [joined rangeOfString:@"Windows"];
        expect(missing.location == NSNotFound, @"找不到时 location 是 NSNotFound（不是 -1）");
        expect(missing.length == 0, @"找不到时 length 是 0");

        NSMutableString *buf = [NSMutableString stringWithString:@"Cocoa"];
        [buf appendString:@" / UIKit"];
        [buf insertString:@"iOS " atIndex:0];
        expect([buf isEqualToString:@"iOS Cocoa / UIKit"], @"NSMutableString 就地改");

        // -------------------------------------------------- 3) 对象化的标量
        line(@"");
        line(@"== NSNumber / NSValue / NSNull ==");
        NSNumber *n1 = @42, *n2 = @42.0;
        expect([n1 isEqualToNumber:n2], @"NSNumber 按数值比较，42 与 42.0 相等");
        expect(strcmp(n1.objCType, n2.objCType) != 0, @"但 objCType 不同（整数 vs 浮点编码）");
        expect([n1 intValue] == 42 && [n2 doubleValue] == 42.0, @"取值时按类型取");
        // 小整数 NSNumber 是 tagged pointer，指针比较不可靠 —— 永远用 isEqual:
        expect([@1 isEqual:@1], @"小整数 NSNumber 相等（但别用 == 比指针）");

        NSValue *range = [NSValue valueWithRange:NSMakeRange(3, 7)];
        expect(range.rangeValue.length == 7, @"NSValue 可包任意 C 结构体");
        NSArray *withHole = @[@"a", [NSNull null], @"c"];
        expect(withHole.count == 3 && withHole[1] == [NSNull null],
               @"NSNull 是集合里的空位，且是单例（可比指针）");

        // ------------------------------------------------------- 4) NSArray
        line(@"");
        line(@"== NSArray / NSMutableArray ==");
        NSArray<NSString *> *langs = @[@"Swift", @"Objective-C", @"C"];
        expect(langs.count == 3, @"字面量数组 3 个元素");
        expect([langs.firstObject isEqualToString:@"Swift"], @"firstObject 取第一个");
        expect([langs indexOfObject:@"C"] == 2, @"indexOfObject 返回下标");
        expect([langs indexOfObject:@"Rust"] == NSNotFound, @"找不到返回 NSNotFound");
        NSMutableArray<NSString *> *mutable = [langs mutableCopy];
        [mutable addObject:@"C++"];
        [mutable removeObjectAtIndex:0];
        expect(mutable.count == 3 && [mutable[0] isEqualToString:@"Objective-C"], @"可变数组增删");
        NSArray *sorted = [mutable sortedArrayUsingComparator:^NSComparisonResult(NSString *x, NSString *y) {
            return [x compare:y];
        }];
        line([NSString stringWithFormat:@"  sorted = %@", [sorted componentsJoinedByString:@", "]]);
        expect([sorted[0] isEqualToString:@"C"], @"排序后 C 在最前");
        expect([langs isEqualToArray:langs], @"isEqualToArray 逐元素比较");

        // -------------------------------------------------- 5) NSDictionary / NSSet
        line(@"");
        line(@"== NSDictionary / NSSet ==");
        NSDictionary<NSString *, NSNumber *> *ages = @{@"Ada": @36, @"Grace": @45, @"Alan": @41};
        expect([ages[@"Grace"] intValue] == 45, @"下标取值");
        expect(ages[@"Nobody"] == nil, @"不存在的 key 取到 nil（不是异常）");
        // 坑：allKeys 顺序未定义，想稳定输出必须自己排序。
        NSArray<NSString *> *sortedKeys = [ages.allKeys sortedArrayUsingSelector:@selector(compare:)];
        NSMutableArray<NSString *> *pairs = [NSMutableArray array];
        for (NSString *k in sortedKeys) { [pairs addObject:[NSString stringWithFormat:@"%@=%@", k, ages[k]]]; }
        line([NSString stringWithFormat:@"  ages = %@", [pairs componentsJoinedByString:@" "]]);
        expect([sortedKeys[0] isEqualToString:@"Ada"], @"排序后第一个 key 是 Ada");
        NSMutableDictionary<NSString *, id> *settings = [@{@"theme": @"dark"} mutableCopy];
        settings[@"theme"] = @"light";     // 已存在的 key → 改值
        settings[@"autoSave"] = @YES;      // 新 key → 新增
        [settings removeObjectForKey:@"notThere"];   // 不存在 → 静默无副作用
        expect(settings.count == 2 && [settings[@"theme"] isEqualToString:@"light"], @"可变字典改值+新增");

        NSSet<NSString *> *tags = [NSSet setWithObjects:@"iOS", @"UIKit", @"iOS", nil];
        expect(tags.count == 2, @"NSSet 自动去重");
        NSCountedSet *counter = [NSCountedSet set];
        [counter addObject:@"a"]; [counter addObject:@"a"]; [counter addObject:@"b"];
        expect([counter countForObject:@"a"] == 2 && counter.count == 2, @"NSCountedSet 记录出现次数");

        // ------------------------------------------------------ 6) NSData
        line(@"");
        line(@"== NSData ==");
        NSData *data = [@"Cocoa" dataUsingEncoding:NSUTF8StringEncoding];
        expect(data.length == 5, @"NSData 按字节计长度");
        NSString *back = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        expect([back isEqualToString:@"Cocoa"], @"按 UTF-8 解回字符串");
        // 坑：编码不匹配时返回 nil，不抛异常。
        const uint8_t bad[] = { 0xFF, 0xFE, 0x41 };
        NSString *badString = [[NSString alloc] initWithData:[NSData dataWithBytes:bad length:sizeof(bad)]
                                                    encoding:NSUTF8StringEncoding];
        expect(badString == nil, @"非法 UTF-8 解码返回 nil");
        NSMutableData *growing = [NSMutableData data];
        [growing appendData:data];
        [growing appendBytes:"!" length:1];
        expect(growing.length == 6 && memcmp(growing.bytes, "Cocoa!", 6) == 0, @"NSMutableData 追加字节");

        // --------------------------------------------- 7) 日期：固定时区
        line(@"");
        line(@"== NSDate / NSCalendar ==");
        // NSDate 就是一个时间点（内部以 2001-01-01 参考日期存储），常用 1970 纪元 API。
        NSDate *epoch = [NSDate dateWithTimeIntervalSince1970:1700000000];
        expect(epoch.timeIntervalSince1970 == 1700000000, @"NSDate 就是一个时间戳");
        NSCalendar *utc = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
        utc.timeZone = [NSTimeZone timeZoneForSecondsFromGMT:0];
        NSDateComponents *c = [utc components:NSCalendarUnitYear | NSCalendarUnitMonth
                                    | NSCalendarUnitDay | NSCalendarUnitHour fromDate:epoch];
        line([NSString stringWithFormat:@"  UTC = %04ld-%02ld-%02ld %02ld:00",
              (long)c.year, (long)c.month, (long)c.day, (long)c.hour]);
        expect(c.year == 2023 && c.month == 11 && c.hour == 22, @"UTC 下是 2023-11 22 点");
        NSCalendar *beijing = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
        beijing.timeZone = [NSTimeZone timeZoneForSecondsFromGMT:8 * 3600];
        NSDateComponents *cb = [beijing components:NSCalendarUnitDay | NSCalendarUnitHour fromDate:epoch];
        expect(cb.hour == 6 && cb.day == 15, @"东八区跨到 15 号早上 6 点");

        NSDateFormatter *fmt = [[NSDateFormatter alloc] init];
        fmt.locale = [NSLocale localeWithLocaleIdentifier:@"en_US_POSIX"];  // 机器读写必须钉死
        fmt.timeZone = [NSTimeZone timeZoneForSecondsFromGMT:0];
        fmt.dateFormat = @"yyyy-MM-dd HH:mm";
        expect([[fmt stringFromDate:epoch] isEqualToString:@"2023-11-14 22:13"], @"en_US_POSIX 输出稳定");

        // ------------------------------------------------- 8) JSON 序列化
        line(@"");
        line(@"== NSJSONSerialization ==");
        NSDictionary *payload = @{@"name": @"iOS", @"version": @18, @"tags": @[@"ui", @"mobile"]};
        NSError *err = nil;
        NSData *json = [NSJSONSerialization dataWithJSONObject:payload
                                                      options:NSJSONWritingSortedKeys error:&err];
        NSString *jsonText = [[NSString alloc] initWithData:json encoding:NSUTF8StringEncoding];
        line([NSString stringWithFormat:@"  json = %@", jsonText]);
        expect(err == nil, @"序列化没有出错");
        expect([jsonText isEqualToString:@"{\"name\":\"iOS\",\"tags\":[\"ui\",\"mobile\"],\"version\":18}"],
               @"加 SortedKeys 后输出稳定（可 diff/缓存）");
        id parsed = [NSJSONSerialization JSONObjectWithData:json options:0 error:&err];
        expect([parsed isKindOfClass:[NSDictionary class]], @"解析回来是 NSDictionary");
        expect([parsed[@"name"] isEqualToString:@"iOS"] && [parsed[@"version"] intValue] == 18, @"解析取值正确");
        expect([parsed[@"tags"] count] == 2, @"数组解析成 NSArray");

        line(@"");
        if (gFailures == 0) { line(@"全部断言通过。"); }
        else { line([NSString stringWithFormat:@"有 %d 条断言失败。", gFailures]); }
        printf("==== 05 结束 ====\n");
    }
    return gFailures == 0 ? 0 : 1;
}
