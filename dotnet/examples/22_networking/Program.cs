using System.Buffers.Binary;
using System.Net;
using System.Net.Sockets;
using System.Text;

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

// ---------- WOL 魔术包：6×FF + 16×MAC，只构造不广播 ----------
static byte[] BuildMagicPacket(string mac)
{
    var macBytes = mac.Split('-').Select(h => (byte)Convert.ToInt32(h, 16)).ToArray();
    return [.. Enumerable.Repeat((byte)0xFF, 6),
            .. Enumerable.Repeat(macBytes, 16).SelectMany(x => x)];
}

var wol = BuildMagicPacket("1A-2B-3C-4D-5E-6F");
Console.WriteLine($"wol-packet: {wol.Length} bytes, starts {Convert.ToHexString(wol[..10])}...");
