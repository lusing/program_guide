// 20 实战项目：实体层（客房 + 入住记录）
namespace HotelApp;

public class Room
{
    public string Number { get; set; } = "";      // 房号，如 301
    public string Type { get; set; } = "";        // 单人间/双人间/豪华套房
    public decimal Price { get; set; }            // 每晚价格
    public bool Occupied { get; set; }            // 住客是否在住
}

public class StayRecord
{
    public long Id { get; set; }
    public string RoomNumber { get; set; } = "";
    public string GuestName { get; set; } = "";
    public string Phone { get; set; } = "";
    public DateTime CheckIn { get; set; }
    public DateTime CheckOut { get; set; }        // 尚在住 = 未结账：以 CheckedOut=false 区分
    public bool CheckedOut { get; set; }
    public int Nights => (int)Math.Max(1, Math.Ceiling((CheckOut - CheckIn).TotalDays));
    public decimal Bill(int nights) => nights * RoomPrice;
    public decimal RoomPrice { get; set; }

    public string Status => CheckedOut ? $"已退（{Nights} 晚 ￥{Bill(Nights)}）" : "在住";
}
