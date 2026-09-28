using System.Buffers.Binary;
using System.Net;
using System.Net.NetworkInformation;
using System.Net.Sockets;
using System.Text;

// ---------- System.Net 地基：IPAddress / IPEndPoint / Dns / Ping ----------
var v4 = IPAddress.Parse("192.168.1.10");
var v6Mapped = IPAddress.Parse("::ffff:192.168.1.10").MapToIPv4();
Console.WriteLine($"ipaddress: {v4} family={v4.AddressFamily}；IPv6 映射地址 MapToIPv4 → {v6Mapped}");
var demoEp = new IPEndPoint(v4, 8080);
Console.WriteLine($"ipendpoint: {demoEp} = IP 定主机 + 端口定进程（套接字的编程抽象）");
var hostEntry = await Dns.GetHostEntryAsync("localhost");
Console.WriteLine($"dns: localhost → {hostEntry.HostName} [{string.Join(", ", hostEntry.AddressList.Select(a => a.ToString()))}]");
try
{
    using var ping = new Ping();
    var reply = await ping.SendPingAsync(IPAddress.Loopback, timeout: 500);
    Console.WriteLine($"ping: 127.0.0.1 → {reply.Status}，往返 {reply.RoundtripTime}ms");
}
catch (Exception ex)
{
    Console.WriteLine($"ping: 本机环境不允许（{ex.GetType().Name}）——Unix 上发裸 ICMP 常要特权");
}

// ---------- TCP：长度前缀分帧的回显 ----------
// 端口 0 = 让系统分配空闲端口（示例、测试的标准做法）
var listener = new TcpListener(IPAddress.Loopback, port: 0);
listener.Start();
var port = ((IPEndPoint)listener.LocalEndpoint).Port;

var echoServer = Task.Run(async () =>
{
    using var conn = await listener.AcceptTcpClientAsync();
    using var stream = conn.GetStream();
    var len = new byte[4];
    var body = new byte[64];
    while (true)
    {
        try { await stream.ReadExactlyAsync(len); }
        catch (EndOfStreamException) { break; }                    // 对端关闭，正常收场
        int size = BinaryPrimitives.ReadInt32BigEndian(len);       // 网络字节序（大端）
        await stream.ReadExactlyAsync(body.AsMemory(0, size));
        await stream.WriteAsync(len);                              // 分帧原样回显
        await stream.WriteAsync(body.AsMemory(0, size));
    }
});

using var client = new TcpClient();
await client.ConnectAsync(IPAddress.Loopback, port);
using var cs = client.GetStream();
var lenBuf = new byte[4];
foreach (var msg in new[] { "hello", "socket" })
{
    var payload = Encoding.UTF8.GetBytes(msg);
    var frame = new byte[4 + payload.Length];
    BinaryPrimitives.WriteInt32BigEndian(frame.AsSpan(0, 4), payload.Length);
    payload.CopyTo(frame, 4);
    await cs.WriteAsync(frame);
    await cs.ReadExactlyAsync(lenBuf);
    var echoLen = BinaryPrimitives.ReadInt32BigEndian(lenBuf);
    var echo = new byte[echoLen];
    await cs.ReadExactlyAsync(echo);
    Console.WriteLine($"tcp-echo: {Encoding.UTF8.GetString(echo)}");
}

client.Close();                       // 触发服务端 EndOfStream，结束 echo 循环
await echoServer;
listener.Stop();

// ---------- UDP：数据报一收一发 ----------
using var receiver = new UdpClient(new IPEndPoint(IPAddress.Loopback, 0));
var udpPort = ((IPEndPoint)receiver.Client.LocalEndPoint!).Port;
using var sender = new UdpClient();
sender.Connect(IPAddress.Loopback, udpPort);
await sender.SendAsync(Encoding.UTF8.GetBytes("datagram") );
var res = await receiver.ReceiveAsync();
Console.WriteLine($"udp-echo: {Encoding.UTF8.GetString(res.Buffer)}");

// ---------- UDP 组播：只发给「入了组」的成员 ----------
var group = IPAddress.Parse("239.1.2.3");           // 组播段 224.0.0.0 ~ 239.255.255.255（224.0.0.x 保留）
using var mcastMember = new UdpClient(new IPEndPoint(IPAddress.Any, 0));
var mcastPort = ((IPEndPoint)mcastMember.Client.LocalEndPoint!).Port;
mcastMember.JoinMulticastGroup(group);
using var mcastSender = new UdpClient();
await mcastSender.SendAsync(Encoding.UTF8.GetBytes($"hello {group}"), new IPEndPoint(group, mcastPort));
var mres = await mcastMember.ReceiveAsync();
Console.WriteLine($"udp-multicast: {Encoding.UTF8.GetString(mres.Buffer)} ← 加入 {group} 组的成员都收得到");
mcastMember.DropMulticastGroup(group);              // 离组要还：进程退出操作系统会回收，但显式 Drop 是礼貌

// ---------- WOL 魔术包：6×FF + 16×MAC，只构造不广播 ----------
static byte[] BuildMagicPacket(string mac)
{
    var macBytes = mac.Split('-').Select(h => (byte)Convert.ToInt32(h, 16)).ToArray();
    return [.. Enumerable.Repeat((byte)0xFF, 6),
            .. Enumerable.Repeat(macBytes, 16).SelectMany(x => x)];
}

var wol = BuildMagicPacket("1A-2B-3C-4D-5E-6F");
Console.WriteLine($"wol-packet: {wol.Length} bytes, starts {Convert.ToHexString(wol[..10])}...");

// ---------- HTTP 客户端：HttpClient 是应用层的正门 ----------
static int FreePort()
{
    var probe = new TcpListener(IPAddress.Loopback, 0);   // 借端口 0 要一个空闲端口
    probe.Start();
    var p = ((IPEndPoint)probe.LocalEndpoint).Port;
    probe.Stop();
    return p;
}

var httpPort = FreePort();
var httpd = new HttpListener();                          // 本地起一个最小 HTTP 服务器当靶子（真实服务用 16 章的 Kestrel）
httpd.Prefixes.Add($"http://127.0.0.1:{httpPort}/");
httpd.Start();
var httpServer = Task.Run(async () =>
{
    for (var n = 0; n < 2; n++)                          // 接两个请求：GetStringAsync 一个、SendAsync 一个
    {
        var ctx = await httpd.GetContextAsync();
        var payload = Encoding.UTF8.GetBytes($"hello over HTTP ({ctx.Request.HttpMethod} {ctx.Request.Url!.PathAndQuery})");
        ctx.Response.Headers["X-Teaching"] = "22-networking";
        ctx.Response.ContentType = "text/plain; charset=utf-8";
        ctx.Response.ContentLength64 = payload.Length;
        await ctx.Response.OutputStream.WriteAsync(payload);
    }
});
using var http = new HttpClient();                       // HttpClient 要当单例复用（坑位清单第 8 条）
var page = await http.GetStringAsync($"http://127.0.0.1:{httpPort}/");
Console.WriteLine($"http-get: {page}");
var req = new HttpRequestMessage(HttpMethod.Get, $"http://127.0.0.1:{httpPort}/again");
req.Headers.TryAddWithoutValidation("X-Client", "demo");
using var resp = await http.SendAsync(req);
Console.WriteLine($"http-send: {(int)resp.StatusCode} {resp.StatusCode}，X-Teaching={resp.Headers.GetValues("X-Teaching").FirstOrDefault()}");
await httpServer;
httpd.Stop();

// ---------- POP3：手写文本协议客户端（对端是本地假服务器） ----------
// POP3 在 .NET 里没有现成客户端类——教材第 7 章就是教你在 TcpClient 上手写，这里如法炮制
var mailbox = new[]
{
    (from: "alice@example.com", subject: "周报提醒"),
    (from: "bob@example.com", subject: "Re: 服务器迁移"),
};
var pop3Listener = new TcpListener(IPAddress.Loopback, 0);
pop3Listener.Start();
var pop3Port = ((IPEndPoint)pop3Listener.LocalEndpoint).Port;
var pop3Server = Task.Run(async () =>
{
    using var conn = await pop3Listener.AcceptTcpClientAsync();
    using var rs = conn.GetStream();
    using var rr = new StreamReader(rs);                 // 默认 UTF-8 无 BOM
    using var rw = new StreamWriter(rs) { AutoFlush = true, NewLine = "\r\n" };   // 文本协议用 \r\n
    await rw.WriteLineAsync("+OK 假 POP3 服务器就绪");
    for (string? line; (line = await rr.ReadLineAsync()) is not null && line != "QUIT"; )
    {
        if (line.StartsWith("USER") || line.StartsWith("PASS"))
            await rw.WriteLineAsync("+OK");
        else if (line.StartsWith("STAT"))
            await rw.WriteLineAsync($"+OK {mailbox.Length} 封邮件");
        else if (line.StartsWith("RETR"))
        {
            var i = int.Parse(line[5..]) - 1;
            await rw.WriteLineAsync($"+OK 第 {i + 1} 封的内容");
            await rw.WriteLineAsync($"From: {mailbox[i].from}  Subject: {mailbox[i].subject}");
            await rw.WriteLineAsync(".");                // 多行响应以单独一行点号结束——POP3 的分帧约定
        }
        else
            await rw.WriteLineAsync("-ERR 未知命令");
    }
    await rw.WriteLineAsync("+OK bye");
});

using var pop3 = new TcpClient();
await pop3.ConnectAsync(IPAddress.Loopback, pop3Port);
using var pr = new StreamReader(pop3.GetStream());
using var pw = new StreamWriter(pop3.GetStream()) { AutoFlush = true, NewLine = "\r\n" };
Console.WriteLine($"pop3: 服务器说「{await pr.ReadLineAsync()}」");
await pw.WriteLineAsync("USER alice"); Console.WriteLine($"pop3: USER → {await pr.ReadLineAsync()}");
await pw.WriteLineAsync("PASS ***");   Console.WriteLine($"pop3: PASS → {await pr.ReadLineAsync()}");
await pw.WriteLineAsync("STAT");       Console.WriteLine($"pop3: STAT → {await pr.ReadLineAsync()}");
await pw.WriteLineAsync("RETR 1");     Console.WriteLine($"pop3: RETR → {await pr.ReadLineAsync()}");
for (var l = await pr.ReadLineAsync(); l is not null && l != "."; l = await pr.ReadLineAsync())
    Console.WriteLine($"pop3:   {l}");
await pw.WriteLineAsync("QUIT");       Console.WriteLine($"pop3: QUIT → {await pr.ReadLineAsync()}");
await pop3Server;
pop3Listener.Stop();
