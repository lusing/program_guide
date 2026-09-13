int n = 10;
string sign = n switch
{
    > 0 => "positive",
    < 0 => "negative",
    _ => "zero"
};

var nums = new[] {1, 2, 3, 4, 5};
int total = 0;
foreach (var x in nums)
{
    total += x;
}

Console.WriteLine($"n={n}, sign={sign}, total={total}");

