using System.IO;
using System.Text.Json;

namespace NotepadPlus.Services;

/// <summary>最近文件列表的 JSON 持久化（%APPDATA%\WpfNotepadPlus\recent.json）。</summary>
public static class RecentFilesService
{
    private static readonly string StorePath = Path.Combine(
        Environment.GetFolderPath(Environment.SpecialFolder.ApplicationData),
        "WpfNotepadPlus", "recent.json");

    public static List<string> Load()
    {
        try
        {
            if (!File.Exists(StorePath)) return [];
            return JsonSerializer.Deserialize<List<string>>(File.ReadAllText(StorePath)) ?? [];
        }
        catch
        {
            return [];   // 配置文件坏了就当没有，不影响主流程
        }
    }

    public static void Save(IReadOnlyList<string> items)
    {
        try
        {
            Directory.CreateDirectory(Path.GetDirectoryName(StorePath)!);
            File.WriteAllText(StorePath,
                JsonSerializer.Serialize(items, new JsonSerializerOptions { WriteIndented = true }));
        }
        catch
        {
            // 持久化失败只影响下次启动的列表，不值得打断用户
        }
    }
}
