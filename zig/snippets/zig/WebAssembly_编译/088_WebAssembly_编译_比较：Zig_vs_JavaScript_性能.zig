const std = @import("std");

export fn sum_array(arr: [*]const i32, len: usize) i32 {
    var sum: i32 = 0;
    for (0..len) |i| {
        sum += arr[i];
    }
    return sum;
}

export fn find_max(arr: [*]const i32, len: usize) i32 {
    if (len == 0) return 0;
    var max = arr[0];
    for (1..len) |i| {
        if (arr[i] > max) max = arr[i];
    }
    return max;
}
