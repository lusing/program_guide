# 21 · 图像显示：TImage 与 TPicture

TImage 是"图片位"控件；它肚子里干活的是 **TPicture**——一个按文件扩展名
分发格式的容器（bmp/png/jpg 的类全在 Graphics 单元里，不用引第三方）。
本章三件事：加载与保存、程序生成图片、显示模式的四个开关。

## 1. TPicture：按扩展名分发

```pascal
Img.Picture.LoadFromFile('x.png');    // 扩展名 → TPortableNetworkGraphic
Img.Picture.LoadFromFile('x.bmp');    // → TBitmap
Img.Picture.SaveToFile('y.png');      // 按目标扩展名选编码器
Img.Picture.Clear;                    // 清空（Width 归 0）
```

分发表由 `TPicture.RegisterFileFormat` 注册，LCL 出厂就带 bmp/png/jpg
（`TBitmap` / `TPortableNetworkGraphic` / `TJPEGImage` 都在 Graphics 单元声明）。
尺寸问 Picture 不问控件：

```pascal
Img.Picture.Width / Img.Picture.Height    // 图片本体的尺寸
Img.Width / Img.Height                    // 控件框的尺寸（两者可以无关）
```

## 2. 程序生成图片：直接画进图形对象

TPortableNetworkGraphic 家族（TFPImageBitmap 一脉）自带 Canvas——不用
先建 TBitmap 再转：

```pascal
Png := TPortableNetworkGraphic.Create;
Png.SetSize(120, 90);
Png.Canvas.Brush.Color := clSkyBlue;
Png.Canvas.FillRect(0, 0, 120, 90);
Png.Canvas.Brush.Color := clYellow;
Png.Canvas.Ellipse(20, 15, 100, 75);
Png.SaveToFile('test_gen.png');
```

**验证手法（selftest 用的）**：保存→TPicture 加载→`Picture.Bitmap.Canvas.Pixels[x,y]`
逐点比对——椭圆中心必须 clYellow、背景角必须 clSkyBlue。位图离屏可查，
像素级断言比"看起来对"硬得多（22 章/27 章同款手法）。

## 3. 实测：SaveToFile 的格式由对象类型决定

拿 PNG 对象存成 `.bmp` 后缀会发生什么？21 工程做了实验——**文件里仍是
PNG 字节**（前 8 字节魔数 `89 50 4E 47`，断言在 selftest 里）：

```pascal
Png.SaveToFile('mini.bmp');     // 实测：得到的还是 PNG（TGraphic.SaveToFile 认对象）
Img.Picture.SaveToFile('x.bmp'); // 这条才按扩展名转格式（TPicture 层做分发）
```

一句话：**格式分发是 TPicture 的职责，不是 TGraphic 的**。想转格式走
`Picture.LoadFromFile + Picture.SaveToFile`，别指望改后缀名。

## 4. 显示模式四开关

图片和控件框尺寸不一致时怎么贴？四个布尔开关（叠加生效）：

| 开关 | 语义 |
|---|---|
| （全关） | 原尺寸贴左上角 |
| `Stretch := True` | 拉伸到控件框（比例可能变形） |
| `Stretch + Proportional` | 先保比例缩放再贴（不变形，可能留边） |
| `Center := True` | 在框内居中（常与上面组合） |
| `AutoSize := True` | 反过来：控件框跟随图片尺寸 |

```pascal
Img.Proportional := True;    // 看图软件的标准配置
Img.Stretch := True;         // 与 Proportional 同开 = 保比缩放
```

坑：AutoSize 与 Stretch/Proportional 是打架的（一个改框、一个改图）——
同时开会得到随实现漂移的行为，选一个。

## 5. 画进哪张画布：Img.Canvas 会丢

想用 TImage 当画布，画对了地方才留得住：

```pascal
Img.Canvas.Line(...)                        // ✗ 下次重绘冲掉（27 章无效区机制）
Img.Picture.Bitmap.Canvas.Line(...)         // ✔ 画进位图本体
Img.Invalidate;                             //    画完叫一声重绘
```

原因：TImage 的屏幕绘制就是把 `Picture.Bitmap` 贴上去——画在贴的过程之外
（Img.Canvas）等于画在放映幕布上。自绘控件（34 章）会系统讲这套无效区/
重绘模型；这里先记住"数据画进 Picture，重绘只是回放"。

## 6. Transparent 与 PNG alpha

`Img.Transparent := True` 让控件的绘制走透明通道。PNG 自带 alpha 时
`TPortableNetworkGraphic` 保留透明度，贴到非矩形区域（图标、贴纸）没问题；
BMP 的透明要靠 `Bitmap.TransparentColor` 指定色键（老技术，新代码直接用
PNG）。

## 7. 示例与验证

```powershell
pwsh -File build.ps1 -Example 21_image
```

按钮：生成 PNG（程序画图）→ 加载 → 循环切四种显示模式。selftest 覆盖：
生成→保存→加载→像素往返一致、二次加载幂等、Clear 归零、`.bmp` 后缀里
PNG 魔数实证、四开关回环、AutoSize 状态、Transparent 回环。
（selftest 在示例目录里建临时文件，退出前删。）

## 8. 坑位清单（实测）

1. `TGraphic.SaveToFile` **认对象不认后缀**——PNG 对象存 .bmp 名还是 PNG
   字节；格式转换走 TPicture。
2. `Img.Canvas` 上画的东西会被重绘冲掉——画进 `Picture.Bitmap.Canvas`。
3. AutoSize 与 Stretch/Proportional 别同开（一个改框一个改图）。
4. 图片尺寸问 `Picture.Width`；控件框问 `Img.Width`——教程示例里两个都
   打在标签上，肉眼可分。
5. PNG/JPEG 类在 **Graphics 单元**里（TPortableNetworkGraphic/TJPEGImage），
   不需要 `uses Jpeg` 之类（那是 Delphi 的旧地图）。

---
上一章：[20 多页容器](20-tab-pages.md) ｜ 下一章：[22 TFrame 与界面复用](22-frames.md) ｜ 返回：[README](../README.md)
