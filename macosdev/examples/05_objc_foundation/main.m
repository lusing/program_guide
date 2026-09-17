// ============================================================
// 05 - Foundation 值类型与集合（Objective-C）
//   NSString / NSNumber / NSValue / NSNull / NSArray / NSDictionary / NSSet
//   / NSData / NSCalendar / NSJSONSerialization
//
// 编译：
//   clang -fobjc-arc -fmodules -Wall -Wextra -isysroot $(xcrun --show-sdk-path) \
//         -target x86_64-apple-macos12.0 main.m -o 05_objc_foundation \
//         -framework Foundation
// 运行：
//   ./05_objc_foundation
//
// 本章不碰任何界面代码 —— 这正是 Cocoa 的分层：AppKit 只管窗口和视图，
// 数据那一层完全是 Foundation 的事。写命令行工具、写 App、写 XCTest
// 用的是同一套类型。
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
        // NSString 内部是 UTF-16，所以 length 是「UTF-16 码元个数」，
        // 不是用户看到的字符个数。带 emoji 或组合音标时两者会差很多。
        NSString *plain = @"cafe";
        NSString *precomposed = @"café";                 // é 是一个码位
        NSString *decomposed = @"cafe\u0301";            // e + 组合重音符
        line(@"== NSString 与 Unicode ==");
        line([NSString stringWithFormat:@"  plain      length=%lu", (unsigned long)plain.length]);
        line([NSString stringWithFormat:@"  precomposed length=%lu", (unsigned long)precomposed.length]);
        line([NSString stringWithFormat:@"  decomposed length=%lu", (unsigned long)decomposed.length]);
        expect(plain.length == 4, @"纯 ASCII 时 length 等于字符数");
        expect(precomposed.length == 4, @"预组合 é 只占一个 UTF-16 码元");
        expect(decomposed.length == 5, @"分解写法占两个码元（e + U+0301）");

        // 直接比较不相等，但先做一次规范化就相等了 —— 读文件、读网络数据时常见
        expect([precomposed isEqualToString:decomposed] == NO, @"两种写法直接比较不相等");
        NSString *canonA = [precomposed precomposedStringWithCanonicalMapping];
        NSString *canonB = [decomposed precomposedStringWithCanonicalMapping];
        expect([canonA isEqualToString:canonB], @"规范化之后两者相等");
        expect([canonA isEqualToString:precomposed], @"规范化结果与预组合写法一致");

        NSString *emoji = @"👍🏽";                        //  thumbs-up + 肤色修饰符
        line([NSString stringWithFormat:@"  emoji length=%lu", (unsigned long)emoji.length]);
        expect(emoji.length == 4, @"emoji 的 length 也是 UTF-16 码元数（代理对 + 修饰符）");

        // ------------------------------------------------------- 2) 拼接与查找
        NSString *joined = [@[ @"Swift", @"Objective-C", @"Cocoa" ] componentsJoinedByString:@" / "];
        line(@"");
        line(@"== 拼接、切分、查找 ==");
        line([NSString stringWithFormat:@"  joined = %@", joined]);
        expect([joined isEqualToString:@"Swift / Objective-C / Cocoa"], @"数组拼成字符串");

        NSArray<NSString *> *parts = [joined componentsSeparatedByString:@" / "];
        expect(parts.count == 3, @"按分隔符切回 3 段");
        expect([parts[1] isEqualToString:@"Objective-C"], @"第二段是 Objective-C");

        NSRange found = [joined rangeOfString:@"Cocoa"];
        expect(found.location == 22, @"rangeOfString 给出的是 UTF-16 偏移");
        expect([joined substringWithRange:found].length == 5, @"用 NSRange 可以取回子串");

        NSRange missing = [joined rangeOfString:@"Windows"];
        expect(missing.location == NSNotFound, @"找不到时 location 是 NSNotFound");
        // 坑：NSNotFound 是 NSUIntegerMax，不是 -1。写成 int 接收会得到 -1，
        // 但写成 unsigned 又和 0 比较时容易搞反，判断一定要用 NSNotFound。
        expect(missing.length == 0, @"找不到时 length 是 0");

        NSMutableString *buf = [NSMutableString stringWithString:@"Cocoa"];
        [buf appendString:@" / AppKit"];
        [buf insertString:@"macOS " atIndex:0];
        expect([buf isEqualToString:@"macOS Cocoa / AppKit"], @"NSMutableString 就地改");

        // -------------------------------------------------- 3) 对象化的标量
        line(@"");
        line(@"== NSNumber / NSValue / NSNull ==");
        NSNumber *n1 = @42;
        NSNumber *n2 = @42.0;
        NSNumber *n3 = @YES;
        line([NSString stringWithFormat:@"  %@ %@ %@", n1, n2, n3]);
        // 坑：NSNumber 的 isEqual: / isEqualToNumber: 是**按数值**比较的，
        // 所以 @42 和 @42.0 相等。想知道类型差别只能看 objCType。
        expect([n1 isEqualToNumber:n2], @"NSNumber 按数值比较，42 与 42.0 相等");
        expect(strcmp(n1.objCType, n2.objCType) != 0, @"但 objCType 不同（整数编码 vs 浮点编码）");
        expect([n1 intValue] == 42 && [n2 doubleValue] == 42.0, @"取值时按类型取");

        // 同一个值可能被塔吉（tagged pointer）复用，指针比较不可靠 —— 永远用 isEqual:
        NSNumber *a = @1; NSNumber *b = @1;
        expect([a isEqual:b], @"小整数 NSNumber 相等（但别用 == 比指针）");

        NSValue *range = [NSValue valueWithRange:NSMakeRange(3, 7)];
        expect(range.rangeValue.length == 7, @"NSValue 可以包任意 C 结构体");
        NSValue *point = [NSValue valueWithPoint:NSMakePoint(12, 34)];
        expect(point.pointValue.x == 12, @"NSValue 装 NSPoint 也能取回");

        // 集合里不能放 nil，占位符就是 NSNull
        NSArray *withHole = @[ @"a", [NSNull null], @"c" ];
        expect(withHole.count == 3, @"NSNull 是集合里的「空位」");
        expect(withHole[1] == [NSNull null], @"NSNull 是单例，可以直接比指针");
        expect([withHole[1] isEqual:@"x"] == NO, @"NSNull 不等于任何字符串");

        // ------------------------------------------------------- 4) NSArray
        line(@"");
        line(@"== NSArray / NSMutableArray ==");
        NSArray<NSString *> *langs = @[ @"Swift", @"Objective-C", @"C" ];
        line([NSString stringWithFormat:@"  count=%lu first=%@", (unsigned long)langs.count, langs.firstObject]);
        expect(langs.count == 3, @"字面量数组有 3 个元素");
        expect([langs.firstObject isEqualToString:@"Swift"], @"firstObject 取第一个");
        expect(langs.lastObject.length == 1, @"lastObject 取最后一个");
        expect([langs objectAtIndex:0] == langs[0], @"下标语法就是 objectAtIndex:");

        // 坑：下标越界是运行时异常，不是返回 nil
        expect([langs containsObject:@"C"], @"containsObject 用 isEqual: 判断");
        expect([langs indexOfObject:@"C"] == 2, @"indexOfObject 返回下标");
        expect([langs indexOfObject:@"Rust"] == NSNotFound, @"找不到返回 NSNotFound");

        NSMutableArray<NSString *> *mutable = [langs mutableCopy];
        [mutable addObject:@"C++"];
        [mutable removeObjectAtIndex:0];
        expect(mutable.count == 3, @"可变数组增删后仍是 3 个");
        expect([mutable[0] isEqualToString:@"Objective-C"], @"删掉的是第一个元素");

        NSArray<NSString *> *sorted = [mutable sortedArrayUsingComparator:^NSComparisonResult(NSString *x, NSString *y) {
            return [x compare:y];
        }];
        line([NSString stringWithFormat:@"  sorted = %@", [sorted componentsJoinedByString:@", "]]);
        expect([sorted[0] isEqualToString:@"C"], @"按 compare: 排序后 C 在最前");
        expect([langs isEqualToArray:langs], @"isEqualToArray 做逐元素比较");
        expect([langs isEqual:langs], @"isEqual: 对数组同样是逐元素比较");

        // -------------------------------------------------- 5) NSDictionary
        line(@"");
        line(@"== NSDictionary / NSSet ==");
        NSDictionary<NSString *, NSNumber *> *ages = @{ @"Ada": @36, @"Grace": @45, @"Alan": @41 };
        expect(ages.count == 3, @"字面量字典有 3 项");
        expect([ages[@"Grace"] intValue] == 45, @"下标取值");
        expect(ages[@"Nobody"] == nil, @"不存在的 key 取到 nil（不是异常）");

        // 坑：NSDictionary 的 allKeys **顺序未定义**，依赖它输出就会每次都不一样。
        // 想打印得稳定，必须自己排序。这是本教程反复出现的一条规则。
        NSArray<NSString *> *sortedKeys = [ages.allKeys sortedArrayUsingSelector:@selector(compare:)];
        NSMutableArray<NSString *> *pairs = [NSMutableArray array];
        for (NSString *k in sortedKeys) {
            [pairs addObject:[NSString stringWithFormat:@"%@=%@", k, ages[k]]];
        }
        line([NSString stringWithFormat:@"  ages = %@", [pairs componentsJoinedByString:@" "]]);
        expect(sortedKeys.count == 3, @"排序后仍是 3 个 key");
        expect([sortedKeys[0] isEqualToString:@"Ada"], @"排序后第一个 key 是 Ada");

        NSMutableDictionary<NSString *, id> *settings = [@{ @"theme": @"dark", @"fontSize": @13 } mutableCopy];
        settings[@"theme"] = @"light";
        settings[@"autoSave"] = @YES;
        expect(settings.count == 3, @"可变字典改值 + 新增");
        expect([settings[@"theme"] isEqualToString:@"light"], @"已存在的 key 是改值");
        // removeObjectForKey: 对不存在的 key 不做任何事，也不报错
        [settings removeObjectForKey:@"notThere"];
        expect(settings.count == 3, @"删除不存在的 key 无副作用");

        NSSet<NSString *> *tags = [NSSet setWithObjects:@"macOS", @"AppKit", @"macOS", nil];
        expect(tags.count == 2, @"NSSet 自动去重");
        expect([tags containsObject:@"AppKit"], @"containsObject 是哈希查找，比数组快");

        NSCountedSet *counter = [NSCountedSet set];
        [counter addObject:@"a"]; [counter addObject:@"a"]; [counter addObject:@"b"];
        expect([counter countForObject:@"a"] == 2, @"NSCountedSet 记录出现次数");
        expect(counter.count == 2, @"去重后的元素数是 2");

        // ------------------------------------------------------ 6) NSData
        line(@"");
        line(@"== NSData ==");
        const char *raw = "Cocoa";
        NSData *data = [NSData dataWithBytes:raw length:strlen(raw)];
        expect(data.length == 5, @"NSData 按字节计长度");
        NSString *back = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        expect([back isEqualToString:@"Cocoa"], @"按 UTF-8 解回字符串");

        // 坑：initWithData:encoding: 编码不匹配时返回 nil，而不是抛异常。
        // 传一段不是合法 UTF-8 的字节进去看看。
        const uint8_t bad[] = { 0xFF, 0xFE, 0x41 };
        NSData *badData = [NSData dataWithBytes:bad length:sizeof(bad)];
        NSString *badString = [[NSString alloc] initWithData:badData encoding:NSUTF8StringEncoding];
        expect(badString == nil, @"非法 UTF-8 解码返回 nil");

        NSMutableData *growing = [NSMutableData data];
        [growing appendData:data];
        [growing appendBytes:"!" length:1];
        expect(growing.length == 6, @"NSMutableData 追加字节");
        expect(memcmp(growing.bytes, "Cocoa!", 6) == 0, @"字节内容正确");

        // --------------------------------------------- 7) 日期：固定时区
        line(@"");
        line(@"== NSDate / NSCalendar ==");
        // 坑：日期的输出几乎一定依赖「当前时区」和「当前 locale」。
        // 想让输出可复现，就必须显式指定日历、时区、locale 三件套。
        NSDate *epoch = [NSDate dateWithTimeIntervalSince1970:1700000000];
        expect(epoch.timeIntervalSince1970 == 1700000000, @"NSDate 就是一个时间戳");

        NSCalendar *gregorian = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
        gregorian.timeZone = [NSTimeZone timeZoneForSecondsFromGMT:0];
        NSDateComponents *c = [gregorian components:NSCalendarUnitYear | NSCalendarUnitMonth
                                          | NSCalendarUnitDay | NSCalendarUnitHour
                                          fromDate:epoch];
        line([NSString stringWithFormat:@"  UTC = %04ld-%02ld-%02ld %02ld:00",
              (long)c.year, (long)c.month, (long)c.day, (long)c.hour]);
        expect(c.year == 2023, @"UTC 下是 2023 年");
        expect(c.month == 11, @"UTC 下是 11 月");
        expect(c.hour == 22, @"UTC 下是 22 点");

        // 同一个时刻，换到东八区就是第二天早上 6 点
        NSCalendar *beijing = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
        beijing.timeZone = [NSTimeZone timeZoneForSecondsFromGMT:8 * 3600];
        NSDateComponents *cb = [beijing components:NSCalendarUnitDay | NSCalendarUnitHour fromDate:epoch];
        line([NSString stringWithFormat:@"  GMT+8 = day %ld, hour %ld", (long)cb.day, (long)cb.hour]);
        expect(cb.hour == 6, @"东八区是早上 6 点");
        expect(cb.day == 15, @"东八区已经跨到 15 号");

        NSDateFormatter *fmt = [[NSDateFormatter alloc] init];
        fmt.locale = [NSLocale localeWithLocaleIdentifier:@"en_US_POSIX"];
        fmt.timeZone = [NSTimeZone timeZoneForSecondsFromGMT:0];
        fmt.dateFormat = @"yyyy-MM-dd HH:mm";
        line([NSString stringWithFormat:@"  formatted = %@", [fmt stringFromDate:epoch]]);
        // 坑：不设 locale 时，用户在 24 小时制地区以外会看到 "下午10:00" 之类的写法，
        // 写到文件里再读回来就解析不了。称手的做法是固定写 en_US_POSIX。

        // ------------------------------------------------- 8) JSON 序列化
        line(@"");
        line(@"== NSJSONSerialization ==");
        NSDictionary *payload = @{ @"name": @"Cocoa", @"version": @2, @"tags": @[ @"ui", @"mac" ] };
        NSError *err = nil;
        NSData *json = [NSJSONSerialization dataWithJSONObject:payload
                                                      options:NSJSONWritingSortedKeys
                                                        error:&err];
        expect(err == nil, @"序列化没有出错");
        NSString *jsonText = [[NSString alloc] initWithData:json encoding:NSUTF8StringEncoding];
        line([NSString stringWithFormat:@"  json = %@", jsonText]);
        // 坑：不加 NSJSONWritingSortedKeys，字典的 key 顺序未定义 ——
        // 写测试、做 diff、算 checksum 都会随机失败。
        expect([jsonText isEqualToString:@"{\"name\":\"Cocoa\",\"tags\":[\"ui\",\"mac\"],\"version\":2}"],
               @"加 SortedKeys 后输出稳定");

        NSData *unsorted = [NSJSONSerialization dataWithJSONObject:payload options:0 error:&err];
        NSString *unsortedText = [[NSString alloc] initWithData:unsorted encoding:NSUTF8StringEncoding];
        expect(unsortedText.length == jsonText.length, @"两种写法长度相同（只有键顺序可能不同）");

        id parsed = [NSJSONSerialization JSONObjectWithData:json options:0 error:&err];
        expect([parsed isKindOfClass:[NSDictionary class]], @"解析回来是 NSDictionary");
        expect([parsed[@"name"] isEqualToString:@"Cocoa"], @"解析后取值正确");
        expect([parsed[@"version"] intValue] == 2, @"数字解析成 NSNumber");
        expect([parsed[@"tags"] count] == 2, @"数组解析成 NSArray");

        // JSON 里没有真正的「整数/浮点」之分，也没有 Date
        NSNumber *asDouble = parsed[@"version"];
        expect(strcmp(asDouble.objCType, "q") == 0 || strcmp(asDouble.objCType, "d") == 0,
               @"数字统一变成 NSNumber，具体编码由实现决定");

        printf("==== 05 结束 ====\n");
    }
    return gFailures == 0 ? 0 : 1;
}
