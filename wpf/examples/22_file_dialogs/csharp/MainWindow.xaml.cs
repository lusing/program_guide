using System.IO;
using System.Windows;
using Microsoft.Win32;

namespace FileDialogDemo;

public partial class MainWindow : Window
{
    public MainWindow()
    {
        InitializeComponent();
    }

    private void OpenFile_Click(object sender, RoutedEventArgs e)
    {
        var dialog = new OpenFileDialog
        {
            Filter = "文本文件|*.txt|所有文件|*.*",
            InitialDirectory = Environment.GetFolderPath(Environment.SpecialFolder.MyDocuments)
        };

        if (dialog.ShowDialog() == true)
        {
            PathBox.Text = dialog.FileName;
            MessageBox.Show($"已选择: {dialog.FileName}", "Open File");
        }
    }

    private void SaveFile_Click(object sender, RoutedEventArgs e)
    {
        var dialog = new SaveFileDialog
        {
            Filter = "文本文件|*.txt|所有文件|*.*",
            FileName = "newfile.txt",
            InitialDirectory = Environment.GetFolderPath(Environment.SpecialFolder.MyDocuments)
        };

        if (dialog.ShowDialog() == true)
        {
            PathBox.Text = dialog.FileName;
            File.WriteAllText(dialog.FileName, "Hello from WPF!\r\n");
            MessageBox.Show($"已保存: {dialog.FileName}", "Save File");
        }
    }
}
