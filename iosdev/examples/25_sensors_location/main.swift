// ============================================================
// 25 - 传感器、定位与设备能力：CoreMotion / CoreLocation / LocalAuthentication / CoreBluetooth / MapKit
//
// 第 19 章讲过「权限怎么问」，第 24 章讲过 AVFoundation 这条音频视频链路。
// 这一章走另外两条通向硬件的路：
//   CoreMotion：CMMotionManager（加速度计 / 陀螺仪 / 磁力计 / 融合姿态）、
//     CMDeviceMotion + CMAttitude / CMRotationMatrix / CMQuaternion、
//     CMAltimeter（气压计）、CMPedometer（计步）、CMMotionActivityManager（活动分类）
//   CoreLocation：CLLocationManager（授权、精度、航向、后台）、CLLocation 的纯数学、
//     CLCircularRegion（地理围栏）、CLFloor、CLGeocoder
//   设备能力：UIDevice 的传感器相关面（电量监控开关、姿态、identifierForVendor）、
//     UIScreen 的刷新率与原生像素、AVCaptureDevice 的相机硬件发现
//   另外四块通向「设备能力」的框架（对应书本 7.1 / 7.3 / 7.4 / 7.5）：
//     §17 LocalAuthentication：LAContext 的两档政策、biometryType 的进程内惰性、
//       interactionNotAllowed 这把「把验证变成可断言纯函数」的钥匙、invalidate() 的三种时序下场
//     §18 CoreBluetooth：CBCentralManager / CBPeripheralManager 的状态机、CBManager.authorization
//       与 state 互相打脸、CBUUID 的短 ID 换算与它唯一的崩溃下法、GATT 对象的出厂 nil
//     §19 / §20 MapKit：墨卡托投影的纯数学（§19）与对象层（§20）—— 标注、渲染器、几何体、
//       GeoJSON 解码器、MKDistanceFormatter；MKMapView 与 MKMapSnapshotter 只能引探针原文
//     §21 距离传感器：UIDevice.proximityMonitoringEnabled 在 headless 里「写得进、读不回」
//
// headless（模拟器）里最要紧的一件事：**硬件几乎都不存在**，
// 而 API 对「不存在」的表达方式有三种，全都要区分开：
//   1) 可用性查询返回 false（isAccelerometerAvailable 之类）
//   2) 数据属性返回 nil（accelerometerData / gyroData / magnetometerData / deviceMotion）
//   3) 起流之后 handler 一次都不来，也不报错
//   另外还有一类不是「硬件不存在」而是「对象是空壳」：构造得出来，读属性当场崩
//   （§4 的 CMAttitude、§10 的 CLHeading 是 signal 11，§16 的 CLVisit 日期是 signal 4，
//    §11 那三条是 signal 6 —— 四种崩溃形态各自对应一种写错的接口用法）
// 所以本章大量断言的是「回调到底来了几次」「nil 还是空数组」「错误码是哪个」，
// 而不是传感器读数本身 —— 读数属于本章的诚实边界（见文末）。
//
// 判定 3（stderr 必须为空）与「debug/release 逐字节一致」的约束：
//   - 不打印 CMAccelerometerData / CLLocation 等对象的 description：里面带时间戳，
//     墙钟一推进两份输出就不一致
//   - 不打印任何由真实时间推出来的读数或步数；时间戳只打印「有没有」「差多少」
//   - 不调用会弹系统对话框的 API（requestWhenInUseAuthorization /
//     requestAlwaysAuthorization）：§11 C 探针实测它**不崩**，但会往 stderr 打一条
//     NSLog（缺 NSLocationWhenInUseUsageDescription 的那条），而 authorizationStatus
//     调用前后都还是 notDetermined —— 既没有 dialog，也没有 delegate 回调，
//     只是一条日志然后当没事发生。判定要求 stderr 为空，所以本章一步都不碰它
//   - **MKMapView 整段只引用探针原文**（§20）：探针实测只写一句 `MKMapView(frame:)` 就会往 stderr
//     打 120 字节的 `CAMetalLayer ignoring invalid setDrawableSize`；MKMapSnapshotter.start 同样脏
//     （§20d 引用）。两者都属于「示例一碰就判死」，所以本章只测能脱离地图视图的对象
//   - 不打印 MKMapView / MKMarkerAnnotationView / MKMapCamera / CLLocation 这类对象的 description：
//     里面有 0x 指针地址，两份输出对不上（只打印类型名和数值分量）
//   - 会崩或会挂的调用只在独立探针里量，然后在正文引用原文：空 localizedReason 验证（signal 6）、
//     CBUUID 非法字符串（NSException → signal 6）、裸 MKOverlayPathRenderer()（signal 11）、
//     evaluatePolicy 不设 flag 又不去 invalidate（reply 永远不来）
// ============================================================

import Foundation
import UIKit
import CoreMotion
import CoreLocation
import AVFoundation
import LocalAuthentication
import CoreBluetooth
import MapKit
import Security

var failures = 0
func expect(_ condition: Bool, _ desc: String) {
    print("  \(condition ? "ok  " : "FAIL") \(desc)")
    if !condition { failures += 1 }
}
func line(_ s: String = "") { print(s) }
/// 四位小数：浮点读数用它，-Onone / -O 下逐字节一致
func f4(_ v: Double) -> String { String(format: "%.4f", v) }
func f4(_ v: Float) -> String { String(format: "%.4f", Double(v)) }
/// 十二位小数：§20b 要用它暴露「coordinate 其实不是精确的 0.5」这种 1e-5 量级的差
func f12(_ v: Double) -> String { String(format: "%.12f", v) }
/// 非 async 的等待：顶层是 async main，直接调 run(until:) 会被编译器拒绝
func pump(_ seconds: TimeInterval) {
    RunLoop.current.run(until: Date(timeIntervalSinceNow: seconds))
}

/// §10 用：把 delegate 回调记成字符串，跑完再统一打印（在 handler 里直接 print 会打乱输出顺序）
final class CLRecorder: NSObject, CLLocationManagerDelegate {
    var log: [String] = []
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        log.append("didUpdateLocations(\(locations.count))")
    }
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        let e = error as NSError
        log.append("didFailWithError(\(e.domain)/\(e.code))")
    }
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        log.append("didChangeAuthorization(\(manager.authorizationStatus.rawValue))")
    }
    func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        log.append("didUpdateHeading")
    }
    func locationManager(_ manager: CLLocationManager, monitoringDidFailFor region: CLRegion?, withError error: Error) {
        let e = error as NSError
        log.append("monitoringDidFail(\(e.domain)/\(e.code))")
    }
    func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
        log.append("didEnterRegion")
    }
}

/// §17/§18 用：等一个「由主队列派发、但顶层没有 runloop 会自动跑」的回调。
/// pump(_:) 是「死等 N 秒」，这里改成「最多等 N 秒，条件满足了立刻提前退出」——
/// 提前退出很重要：§18 的 didUpdateState 是**真的会来**的（实测回调次数 = 1），
/// 用固定 pump 就得把配好的那几秒全等满，而轮询只花真正需要的时间。
/// 只打印「条件是否达成」，不打印花了多久 —— 耗时随机器变，打出来 debug/release 就对不上。
func spinUntil(_ maxSeconds: TimeInterval, _ done: () -> Bool) -> Bool {
    let deadline = Date().addingTimeInterval(maxSeconds)
    while !done() && Date() < deadline {
        _ = RunLoop.current.run(mode: .default, before: Date().addingTimeInterval(0.05))
    }
    return done()
}

/// §17 用：NSError 的统一打印。domain#code 是稳定的，localizedDescription 只在本机语言下稳定
func laErr(_ e: NSError?) -> String {
    guard let e else { return "nil" }
    return "\(e.domain)#\(e.code) desc=\(e.localizedDescription)"
}

/// §17 用：把 evaluatePolicy 的 reply block 攒进一个可以**稍后再读**的盒子。
/// 只有做成对象才能演「先挂在那儿 → 再 invalidate() → 看 reply 到底来不来」这条时序；
/// 每次调用自带信号量的写法只能测「这一次有没有回复」。等待一律带超时：
/// 这一族 API 的正常分支是「弹系统界面等人点」，headless 下永远不来，无界等待会把本章挂死。
final class LAReply {
    var text = "no reply"
    let sem = DispatchSemaphore(value: 0)
    func start(_ ctx: LAContext, _ policy: LAPolicy, reason: String) {
        ctx.evaluatePolicy(policy, localizedReason: reason) { [weak self] ok, err in
            self?.text = "success=\(ok) err=\(laErr(err as NSError?))"
            self?.sem.signal()
        }
    }
    /// 返回「等到了吗」，不返回等了多久
    func wait(_ seconds: TimeInterval) -> Bool {
        sem.wait(timeout: .now() + seconds) == .success
    }
}

/// §18 用：CoreBluetooth 两套 delegate 的回调计数。
/// 和 CLRecorder 同样的理由——回调里直接 print 会打乱章节输出顺序，先攒起来。
final class CBLog: NSObject, CBCentralManagerDelegate, CBPeripheralManagerDelegate {
    var centralStates: [Int] = []
    var peripheralStates: [Int] = []
    var discovered = 0
    var restored = 0
    var centralLog: [String] = []
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        centralStates.append(central.state.rawValue)
    }
    func centralManager(_ central: CBCentralManager, willRestoreState dict: [String: Any]) {
        restored += 1
        centralLog.append("willRestore(\(dict.count))")
    }
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral,
                        advertisementData: [String: Any], rssi RSSI: NSNumber) {
        discovered += 1
    }
    func peripheralManagerDidUpdateState(_ peripheral: CBPeripheralManager) {
        peripheralStates.append(peripheral.state.rawValue)
    }
}

// MARK: - §1 CMMotionManager 的出厂状态

line("== 1) CMMotionManager：出厂状态与「可用性」的三种表达方式 ==")
do {
    let mm = CMMotionManager()
    line("  isAccelerometerAvailable=\(mm.isAccelerometerAvailable) isGyroAvailable=\(mm.isGyroAvailable) isMagnetometerAvailable=\(mm.isMagnetometerAvailable) isDeviceMotionAvailable=\(mm.isDeviceMotionAvailable)")
    line("  CMAltimeter.isRelativeAltitudeAvailable()=\(CMAltimeter.isRelativeAltitudeAvailable()) CMMotionActivityManager.isActivityAvailable()=\(CMMotionActivityManager.isActivityAvailable())")
    line("  CMPedometer.isStepCountingAvailable()=\(CMPedometer.isStepCountingAvailable()) isDistanceAvailable()=\(CMPedometer.isDistanceAvailable()) isFloorCountingAvailable()=\(CMPedometer.isFloorCountingAvailable()) isCadenceAvailable()=\(CMPedometer.isCadenceAvailable())")
    line("  默认 interval：accelerometer=\(f4(mm.accelerometerUpdateInterval)) gyro=\(f4(mm.gyroUpdateInterval)) magnetometer=\(f4(mm.magnetometerUpdateInterval)) deviceMotion=\(f4(mm.deviceMotionUpdateInterval))")
    line("  刚建好：isActive accelerometer=\(mm.isAccelerometerActive) gyro=\(mm.isGyroActive) deviceMotion=\(mm.isDeviceMotionActive) magnetometer=\(mm.isMagnetometerActive)")
    line("  刚建好：data accelerometer=\(mm.accelerometerData == nil ? "nil" : "非 nil") gyro=\(mm.gyroData == nil ? "nil" : "非 nil") deviceMotion=\(mm.deviceMotion == nil ? "nil" : "非 nil") magnetometer=\(mm.magnetometerData == nil ? "nil" : "非 nil")")
    line("  注意属性名：设备运动那一档叫 **deviceMotion**（ObjC 里是 deviceMotion，Swift 不会加 Data 后缀），写成 deviceMotionData 编译器直接拒绝")
    line("  实例属性 attitudeReferenceFrame 出厂读回=\(mm.attitudeReferenceFrame.rawValue)（这一档的枚举名是 xArbitraryZVertical）")
    line("  CMAttitudeReferenceFrame 四档 rawValue：xArbitraryZVertical=\(CMAttitudeReferenceFrame.xArbitraryZVertical.rawValue) xArbitraryCorrectedZVertical=\(CMAttitudeReferenceFrame.xArbitraryCorrectedZVertical.rawValue) xMagneticNorthZVertical=\(CMAttitudeReferenceFrame.xMagneticNorthZVertical.rawValue) xTrueNorthZVertical=\(CMAttitudeReferenceFrame.xTrueNorthZVertical.rawValue)")
    line("  位掩码是**累加**的：XArbitraryZVertical|XMagneticNorthZVertical 的 rawValue=\(CMAttitudeReferenceFrame.xArbitraryZVertical.union(.xMagneticNorthZVertical).rawValue)")
    let availFrames = CMMotionManager.availableAttitudeReferenceFrames()
    line("  CMMotionManager.availableAttitudeReferenceFrames()=\(availFrames.rawValue)（含 XArbitraryZVertical=\(availFrames.contains(.xArbitraryZVertical))）")
    expect(mm.isAccelerometerAvailable == false && mm.isGyroAvailable == false
           && mm.isMagnetometerAvailable == false && mm.isDeviceMotionAvailable == false
           && CMAltimeter.isRelativeAltitudeAvailable() == false
           && CMMotionActivityManager.isActivityAvailable() == false
           && CMPedometer.isStepCountingAvailable() == false,
           "模拟器上**八个可用性查询全是 false**：加速度计、陀螺仪、磁力计、融合姿态、气压计、活动分类、计步/距离/楼层/步频。这一行是本节最重要的输出 —— 后面所有「handler 一次都不来」「data 永远是 nil」的观测都由它解释，不是代码写错")
    expect(mm.accelerometerUpdateInterval == 0.01 && mm.gyroUpdateInterval == 0.01
           && mm.magnetometerUpdateInterval == 0.04 && mm.deviceMotionUpdateInterval == 0.01,
           "四个 updateInterval 的默认值是 **0.01 / 0.01 / 0.04 / 0.01 秒**，不是 0。这里有个必须交代的过程：写这一节之前我按「默认值是 0，表示用系统默认频率」的直觉把断言写成 ==0，跑出来直接 FAIL —— 系统给的默认就是明晃晃的 100Hz（磁力计 25Hz），读回来是具体数字，可以直接断言。教训和上一节那条一样：凡是「按理说应该」的数值，一律先跑一遍再写进断言")
    expect(mm.attitudeReferenceFrame == .xArbitraryZVertical && availFrames.rawValue == 0,
           "这两个值**互相矛盾**，而且都是真的：实例属性 attitudeReferenceFrame 永远回一个具体的档位（出厂 = XArbitraryZVertical = 1），类方法 availableAttitudeReferenceFrames() 却告诉你这台机器一档都不支持（位掩码 0）。所以「当前参考系」不是「可用的参考系」，判能不能用融合姿态得读类方法或者 isDeviceMotionAvailable，读属性会读出一个不存在的硬件能力")
    expect(mm.isAccelerometerActive == false && mm.accelerometerData == nil,
           "isXXxActive 表示「正在流」，isXXxAvailable 表示「硬件在不在」，data 表示「拉取模式下有没有最近一帧」—— 三个是完全独立的东西，别用 active 判断可用、也别用 data 判断有没有起流")
    expect(CMAttitudeReferenceFrame.xArbitraryZVertical.rawValue == 1
           && CMAttitudeReferenceFrame.xArbitraryCorrectedZVertical.rawValue == 2
           && CMAttitudeReferenceFrame.xMagneticNorthZVertical.rawValue == 4
           && CMAttitudeReferenceFrame.xTrueNorthZVertical.rawValue == 8,
           "四档参考系是 1/2/4/8 的**位掩码**（不是 0/1/2/3 的枚举），所以可以 union 起来一次申请多档；写 startDeviceMotionUpdates(usingReferenceFrame:) 时传组合值，传 0 等于「一档都不要」")
}
line("")

// MARK: - §2 拉取模式 vs 推送模式：不起流的时候读什么

line("== 2) 拉取（startAccelerometerUpdates() + 读属性）与推送（to:withHandler:） ==")
do {
    let mm = CMMotionManager()
    mm.accelerometerUpdateInterval = 0.05
    line("  设成 0.05 之后读回=\(f4(mm.accelerometerUpdateInterval))（属性是可写的，值原样存住）")
    let dataBefore = mm.accelerometerData
    line("  没 start 就读：accelerometerData=\(dataBefore == nil ? "nil" : "非 nil") isAccelerometerActive=\(mm.isAccelerometerActive)")
    expect(dataBefore == nil && mm.isAccelerometerActive == false,
           "没起流就读属性拿到 nil —— 这是「读属性」这条路唯一的失败信号，**没有报错也没有异常**")

    if mm.isAccelerometerAvailable {
        mm.startAccelerometerUpdates()
        pump(0.3)
        let d = mm.accelerometerData
        line("  startAccelerometerUpdates()（无 handler，拉取模式）之后：isActive=\(mm.isAccelerometerActive) data=\(d == nil ? "nil" : "非 nil")")
        if let d = d {
            line("  拉到的那一帧：timestamp=\(f4(d.timestamp)) x=\(f4(d.acceleration.x)) y=\(f4(d.acceleration.y)) z=\(f4(d.acceleration.z))")
        }
        mm.stopAccelerometerUpdates()
        line("  stop 之后：isActive=\(mm.isAccelerometerActive) data=\(mm.accelerometerData == nil ? "nil" : "非 nil")")
    } else {
        mm.startAccelerometerUpdates()
        pump(0.3)
        line("  硬件不可用时调 startAccelerometerUpdates()：isActive=\(mm.isAccelerometerActive) data=\(mm.accelerometerData == nil ? "nil" : "非 nil") —— **调用本身不报错、不抛异常，也不会有 handler**")
        mm.stopAccelerometerUpdates()
        expect(mm.isAccelerometerActive == false,
               "isAccelerometerAvailable=false 的机器上调 start 是**静默无效**：既不报错，active 也不会变 true。这就是模拟器上「我起了流怎么没数据」的真实答案 —— 不是代码写错，是根本没有这个硬件")
    }

    // 推送模式：handler 挂在别的 OperationQueue 上
    var pushCount = 0
    var pushHasData = 0
    var pushError = ""
    let q = OperationQueue()
    mm.startAccelerometerUpdates(to: q) { data, error in
        pushCount += 1
        if data != nil { pushHasData += 1 }
        if let e = error as NSError? { pushError = "domain=\(e.domain) code=\(e.code)" }
    }
    pump(0.4)
    mm.stopAccelerometerUpdates()
    pump(0.1)
    line("  推送模式 0.4 秒：handler 调用 \(pushCount) 次（其中有 data 的 \(pushHasData) 次）error 字符串=\(pushError.isEmpty ? "nil" : pushError)")
    line("  当前（stop 之后）isActive=\(mm.isAccelerometerActive) data=\(mm.accelerometerData == nil ? "nil" : "非 nil")")
    expect(pushCount == 0 && pushHasData == 0 && pushError.isEmpty,
           "推送模式的 handler **一次都不来**，而且 error 也是 nil —— 这是 headless 环境里最难查的一种「没反应」：没有异常、没有回调、没有任何返回值告诉你失败（start/stop 都是 void）。唯一可靠的预检查是 §1 那些 isXXXAvailable；写生产代码时别只挂 handler 等数据，先查可用性再决定要不要显示「本机不支持」")
    expect(mm.isAccelerometerActive == false && mm.accelerometerData == nil,
           "stopAccelerometerUpdates() 之后 active 与 data 双双归位（false / nil）—— 停止是**立即生效**的（这点和第 24 章 reset() 不动 isPlaying 那条恰好相反：CoreMotion 没有「播放意图」这一层，active 就只表示流有没有在跑）")
}
line("")

line("== 3) 另外三条流：陀螺仪 / 磁力计 / 融合姿态，起停之后各自长什么样 ==")
do {
    let mm = CMMotionManager()
    let q = OperationQueue()
    var gyroCount = 0
    var magCount = 0
    var dmCount = 0
    var dmError = "nil"
    var heldGyro: CMGyroData?
    var heldMag: CMMagnetometerData?
    var heldDM: CMDeviceMotion?
    mm.startGyroUpdates(to: q) { data, error in
        gyroCount += 1
        heldGyro = data
        _ = error
    }
    mm.startMagnetometerUpdates(to: q) { data, error in
        magCount += 1
        heldMag = data
        _ = error
    }
    mm.startDeviceMotionUpdates(using: .xArbitraryZVertical, to: q) { data, error in
        dmCount += 1
        heldDM = data
        if let e = error as NSError? { dmError = "domain=\(e.domain) code=\(e.code)" }
    }
    line("  三条流都 start 之后：gyroActive=\(mm.isGyroActive) magnetometerActive=\(mm.isMagnetometerActive) deviceMotionActive=\(mm.isDeviceMotionActive)")
    pump(0.4)
    line("  0.4 秒后 handler 次数：gyro=\(gyroCount) magnetometer=\(magCount) deviceMotion=\(dmCount)，deviceMotion 的 error=\(dmError)")
    line("  自己存下来的三个引用：gyro=\(heldGyro == nil ? "nil" : "非 nil") magnetometer=\(heldMag == nil ? "nil" : "非 nil") deviceMotion=\(heldDM == nil ? "nil" : "非 nil")")
    line("  拉取属性同批读回：gyroData=\(mm.gyroData == nil ? "nil" : "非 nil") magnetometerData=\(mm.magnetometerData == nil ? "nil" : "非 nil") deviceMotion=\(mm.deviceMotion == nil ? "nil" : "非 nil")")
    mm.stopGyroUpdates()
    mm.stopMagnetometerUpdates()
    mm.stopDeviceMotionUpdates()
    line("  全部 stop 之后：gyroActive=\(mm.isGyroActive) magnetometerActive=\(mm.isMagnetometerActive) deviceMotionActive=\(mm.isDeviceMotionActive) deviceMotion=\(mm.deviceMotion == nil ? "nil" : "非 nil")")
    expect(gyroCount == 0 && magCount == 0 && dmCount == 0 && dmError == "nil",
           "三条流的 handler 都是 0 次、error 都是 nil —— 「起了流、没报错、没数据」是这里唯一的形态。对照 §1：available 全 false，所以 start 根本不会启动任何东西")
    expect(mm.isGyroActive == false && mm.isDeviceMotionActive == false,
           "start 在「硬件不在」的机器上也不会把 isXXxActive 变成 true：active 反映的是**真的有流在跑**，不是你调没调 start（第 24 章的 AVAudioPlayerNode.isPlaying 恰好相反，它只反映播放意图）")
    expect(heldGyro == nil && heldMag == nil && heldDM == nil,
           "handler 一次都没来，所以「自己留一份最新数据」这个写法在无硬件机器上留住的永远是 nil —— 这句话的实际含义是：**别把「我保存了 data」当成有数据的证据**，nil 也要存下来、也要在 UI 上区分显示")
    expect(mm.deviceMotion == nil && mm.magnetometerData == nil,
           "注意融合姿态这条路的属性名是 **deviceMotion**（ObjC 的 deviceMotion，Swift 不加 Data 后缀），而磁力计那条是 magnetometerData —— 同一台 manager 上四个数据属性有两种命名，靠记忆点不出来，得查")

    // 数据对象里的字段族：没有数据时什么都读不到，但类型和单位要写清楚
    line("  字段族（有硬件时才谈得上值）：CMGyroData.rotationRate 是 **CMAngularRate**(x,y,z 弧度/秒)、")
    line("        CMAccelerometerData.acceleration 是 **CMAcceleration**(x,y,z 单位 g)、")
    line("        CMMagnetometerData.magneticField 是 **CMMagneticField**(x,y,z 单位微特斯拉)、")
    line("        CMDeviceMotion 一次给六件：attitude / rotationRate / rotationRateBias(iOS16+) / gravity / userAcceleration / magneticField")
    let mf = CMMagneticField(x: 1, y: 2, z: 3)
    line("  这三个结构体都是**纯成员构造**的 C 结构体，可以当场造：CMMagneticField(x:1,y:2,z:3) → \(f4(mf.x))/\(f4(mf.y))/\(f4(mf.z))")
}
line("")

line("== 4) CoreMotion 的结构体族：CMQuaternion / CMRotationMatrix / CMAcceleration 的纯数学，以及 CMAttitude 的空壳陷阱 ==")
do {
    // 这些是**纯 Swift 结构体**，不依赖任何硬件，可以当场构造、当场断言
    let q = CMQuaternion(x: 0, y: 0, z: 0, w: 1)
    line("  单位四元数 CMQuaternion(x:0,y:0,z:0,w:1) → x=\(f4(q.x)) y=\(f4(q.y)) z=\(f4(q.z)) w=\(f4(q.w))")
    let m = CMRotationMatrix(m11: 1, m12: 0, m13: 0, m21: 0, m22: 1, m23: 0, m31: 0, m32: 0, m33: 1)
    line("  单位旋转矩阵九个数：m11=\(f4(m.m11)) m12=\(f4(m.m12)) m13=\(f4(m.m13)) m21=\(f4(m.m21)) m22=\(f4(m.m22)) m23=\(f4(m.m23)) m31=\(f4(m.m31)) m32=\(f4(m.m32)) m33=\(f4(m.m33))")
    // 绕 Z 轴 90° 的四元数：w=cos(θ/2), z=sin(θ/2)
    let theta = Double.pi / 2
    let qz = CMQuaternion(x: 0, y: 0, z: sin(theta / 2), w: cos(theta / 2))
    line("  绕 Z 转 90°：z=\(f4(qz.z)) w=\(f4(qz.w))（z 和 w 都等于 √2/2=\(f4(0.7071067811865476))）")
    // 四元数 → 旋转矩阵（自己按公式算，CoreMotion 不提供转换函数）
    let (x, y, z, w) = (qz.x, qz.y, qz.z, qz.w)
    let r11 = 1 - 2 * (y * y + z * z), r12 = 2 * (x * y - z * w), r13 = 2 * (x * z + y * w)
    let r21 = 2 * (x * y + z * w), r22 = 1 - 2 * (x * x + z * z), r23 = 2 * (y * z - x * w)
    let r31 = 2 * (x * z - y * w), r32 = 2 * (y * z + x * w), r33 = 1 - 2 * (x * x + y * y)
    line("  自己换算出来的矩阵：m11=\(f4(r11)) m12=\(f4(r12)) m13=\(f4(r13)) / m21=\(f4(r21)) m22=\(f4(r22)) m23=\(f4(r23)) / m31=\(f4(r31)) m32=\(f4(r32)) m33=\(f4(r33))")
    let a = CMAcceleration(x: 0, y: 0, z: -9.81)
    line("  CMAcceleration 可以直接成员构造：x=\(f4(a.x)) y=\(f4(a.y)) z=\(f4(a.z))（单位 g：静态平放时 z≈-1，写成 -9.81 是把 g 和 m/s² 混了）")
    let staticZ = CMAcceleration(x: 0, y: 0, z: -1)
    line("  静态平放的正确读数形状：z=\(f4(staticZ.z))，所以「加速度计给的 1 个单位」= 1 g，不是 1 m/s²")
    expect(abs(r11 - 0) < 1e-12 && abs(r12 - (-1)) < 1e-12 && abs(r21 - 1) < 1e-12 && abs(r33 - 1) < 1e-12,
           "绕 Z 90° 的矩阵必须是 [[0,-1,0],[1,0,0],[0,0,1]]，实测 \(f4(r11))/\(f4(r12))/\(f4(r21))/\(f4(r33)) 正好对上 —— **CoreMotion 里四元数和旋转矩阵之间没有任何转换函数**（CMAttitude 有 quaternion/rotationMatrix 两个只读属性，但那是「同一个姿态的两种表示」，不是给你做换算的工具）。自己写换算时符号方向（左手/右手、行主序）全靠这九个值对答案")
    expect(m.m11 == 1 && m.m22 == 1 && m.m33 == 1 && m.m12 == 0,
           "CMRotationMatrix 的九个字段是**行主序命名** m11…m33（不是 m[9]），成员构造器要求九个全给齐，少一个编译器就报 missing argument")
    expect(q.w == 1 && q.x == 0 && q.y == 0 && q.z == 0,
           "CMQuaternion 的顺序是 **x,y,z,w**（实部在最后）；很多图形学库把 w 放最前，混用时把 (1,0,0,0) 当单位四元数传进来，CoreMotion 读到的就是「绕 X 转 180°」。这一条只有构造过一次才会记住")

    // CMAttitude 能不能自己造：这是本章猜得最离谱的一处，编译器 + 运行期各纠正我一半
    let att = CMAttitude()
    line("  CMAttitude() **编译通过、构造也不崩**（ObjC 头文件里它只有五个只读属性和一个实例方法，")
    line("        没有标 NS_DESIGNATED_INITIALIZER，所以 NSObject 的 init 直接露了出来）：")
    line("        类名=\(NSStringFromClass(type(of: att))) isKind(of: CMAttitude.self)=\(att.isKind(of: CMAttitude.self))")
    line("        isEqual 三条：对自身=\(att.isEqual(att))、对另一个新构造的=\(att.isEqual(CMAttitude()))、指针相同=\(att === att)")
    line("  但是**五个属性一个都读不了**。探针实测（-Onone 与 -O 两个优化等级分别跑过，结果一致），")
    line("        任何一条读法都让进程当场崩掉，simctl 给的原文是：")
    line("        Child process terminated with signal 11: Segmentation fault")
    line("        实测逐条撞墙的清单：att.roll / att.pitch / att.yaw / att.quaternion / att.rotationMatrix，")
    line("        以及 att.multiply(byInverseOf:) 和 att.copy() —— 七条全 signal 11，无一例外")
    line("  能用的只有 NSObject 那一层（isKind(of:)、type(of:)、isEqual、=== 都不碰内部状态，所以不崩）——")
    line("        这说明 CMAttitude 的数据全在头文件里那个私有 ivar（ObjC 侧是 id _internal）里，只有传感器管线填得进去。")
    line("        **结论：CMAttitude 只能从 CMDeviceMotion.attitude 拿，自己 init 出来的是个空壳**，")
    line("        而且编译器不会拦你，拦你的是运行时的 signal 11 —— 这是本章最贵的一条坑")
    line("  实例属性只有 roll/pitch/yaw/quaternion/rotationMatrix 五个，**没有 referenceFrame**；")
    line("        CMAttitude 上只有一个实例方法 multiply(byInverseOf:)。三条编译器原文：")
    line("        att.referenceFrame            → error: value of type 'CMAttitude' has no member 'referenceFrame'")
    line("        att.multiply(by: att)         → error: incorrect argument label in call (have 'by:', expected 'byInverseOf:')")
    line("        CMAttitude(byCopyingIn: att)  → error: argument passed to call that takes no arguments")
    expect(att.isEqual(att) == false && (att === att),
           "**同一个实例自己跟自己 isEqual 都是 false**，而指针比较 === 是 true —— 这两个一起出现就说明 CMAttitude **重写了 isEqual**，而它的比较路径要读那个私有 ivar，读不到就一律判不相等。写「两个 attitude 是否相同」的代码时用 isEqual 会得到永假的结果，用 === 得到的是「不是同一个对象」（不同帧本来就是不同对象），两种都不等于「姿态相同」。要判姿态相同只能取 quaternion/rotationMatrix 自己算夹角 —— 而那必须有真实数据源")
    expect(NSStringFromClass(type(of: att)) == "CMAttitude" && att.isKind(of: CMAttitude.self),
           "构造出来的确实是 CMAttitude 本尊（类名逐字读回 CMAttitude）。这里有个必须交代的过程：我原本断言「CMAttitude 没有公开 init，CMAttitude() 会被编译器拒绝」，还准备把 missing arguments 的报错原文抄进书里 —— 实际编译直接通过，那条报错原文根本不存在；改成断言「能构造」之后又踩中真正的坑（能构造 ≠ 能读，读属性就 signal 11）。凡是「ObjC 类大概不能构造」和「编译器过了就是能用」这两种直觉，都必须各跑一次才作数")
}
line("")

line("== 5) CMAltimeter：气压计是**实例**，不是 CMMotionManager 的一条流 ==")
do {
    let alt = CMAltimeter()
    line("  CMAltimeter.isRelativeAltitudeAvailable()=\(CMAltimeter.isRelativeAltitudeAvailable())")
    line("  authorizationStatus()=\(CMAltimeter.authorizationStatus().rawValue)（CMAuthorizationStatus 四档实测：notDetermined=\(CMAuthorizationStatus.notDetermined.rawValue) restricted=\(CMAuthorizationStatus.restricted.rawValue) denied=\(CMAuthorizationStatus.denied.rawValue) authorized=\(CMAuthorizationStatus.authorized.rawValue)）")
    line("  CMAltimeter 上**没有**「读最近一帧」的属性：探针实测写 alt.altitudeData 的编译器原文是")
    line("        error: value of type 'CMAltimeter' has no member 'altitudeData'")
    line("        —— 它只有 start/stop 两条流 + 类方法可用性 + authorizationStatus，想留住数据必须自己在 handler 里存")
    line("  字段名要背：CMAltitudeData 上那条叫 **relativeAltitude**（不是 altitude），探针实测写 d.altitude 的编译器原文：")
    line("        error: value of type 'CMAltitudeData' has no member 'altitude'")
    var altCount = 0
    var altErr = "nil"
    var heldPressure = "nil"
    let q = OperationQueue()
    alt.startRelativeAltitudeUpdates(to: q) { data, error in
        altCount += 1
        if let d = data { heldPressure = "relativeAltitude=\(f4(d.relativeAltitude.doubleValue)) pressure=\(f4(d.pressure.doubleValue))" }
        if let e = error as NSError? { altErr = "domain=\(e.domain) code=\(e.code)" }
    }
    pump(0.4)
    alt.stopRelativeAltitudeUpdates()
    line("  相对高度流 0.4 秒：handler \(altCount) 次，error=\(altErr)，自己存下来的数据=\(heldPressure)")
    line("  绝对高度（iOS 15+）：isAbsoluteAltitudeAvailable()=\(CMAltimeter.isAbsoluteAltitudeAvailable())")
    var absCount = 0
    alt.startAbsoluteAltitudeUpdates(to: q) { data, error in
        absCount += 1
        _ = data; _ = error
    }
    pump(0.4)
    alt.stopAbsoluteAltitudeUpdates()
    line("  绝对高度流 0.4 秒：handler \(absCount) 次")
    expect(altCount == 0 && altErr == "nil" && absCount == 0,
           "气压计这两条流同样是「0 次回调 + 无错误」。值得单独记的是**它不归 CMMotionManager 管**：CMAltimeter 是自己的一个类，有自己的一份 authorizationStatus、自己的可用性类方法，而且相对/绝对两条流的**数据类型还不一样**（CMAltitudeData / CMAbsoluteAltitudeData）—— 想找气压计却在 CMMotionManager 上翻属性是常见的绕路")
    expect(CMAltimeter.isRelativeAltitudeAvailable() == false,
           "isRelativeAltitudeAvailable 是**类方法**（和 CMPedometer 那几个一致），而 CMMotionManager 的 isXXXAvailable 是实例属性 —— 同一个框架里两种写法，点不出来时先分清是类还是实例")
    expect(CMAltimeter.authorizationStatus().rawValue == CMAuthorizationStatus.denied.rawValue,
           "authorizationStatus() 在这台机器上读回 **2**，而 2 是 denied（头文件给的四档是 notDetermined=0 restricted=1 denied=2 authorized=3，按名字猜顺序会猜成 1/2/3/4，实际不是顺排）。这里同样有个猜错的过程：我原本断言它是 notDetermined（「没请求过就是未决定」听起来很合理），跑出来是 2 才 FAIL。而且这一条和 §6/§7 的三个 authorizationStatus 完全一致 —— 无权限环境下四家（气压计/计步/活动分类/运动）都报 denied，不是 notDetermined，「可用性 false」和「权限被拒」在这台机器上是同时成立的两件事")
}
line("")

line("== 6) CMPedometer：离线查询用固定日期区间，于是错误码也可以逐字断言 ==")
do {
    let ped = CMPedometer()
    line("  authorizationStatus()=\(CMPedometer.authorizationStatus().rawValue)（CMAuthorizationStatus 同上一节）")
    // 固定区间：不依赖墙钟，两份配置逐字节一致
    let d1 = Date(timeIntervalSince1970: 1_700_000_000)
    let d2 = Date(timeIntervalSince1970: 1_700_003_600)
    line("  查询区间用两个固定时间戳：\(Int(d1.timeIntervalSince1970)) → \(Int(d2.timeIntervalSince1970))（正好 1 小时）")
    var steps = "nil"
    var pedErr = "nil"
    var came = false
    let sem = DispatchSemaphore(value: 0)
    ped.queryPedometerData(from: d1, to: d2) { data, error in
        came = true
        if let d = data { steps = "numberOfSteps=\(d.numberOfSteps)" }
        if let e = error as NSError? { pedErr = "domain=\(e.domain) code=\(e.code)" }
        sem.signal()
    }
    let ok = (sem.wait(timeout: .now() + 3) == .success)
    line("  queryPedometerData(from:to:withHandler:)：回调到达=\(came) 等到=\(ok) data=\(steps) error=\(pedErr)")
    var evCount = 0
    var evErr = "nil"
    ped.startEventUpdates { event, error in
        evCount += 1
        if let e = error as NSError? { evErr = "domain=\(e.domain) code=\(e.code)" }
        _ = event
    }
    pump(0.4)
    ped.stopEventUpdates()
    line("  startEventUpdates 0.4 秒：handler \(evCount) 次，error=\(evErr)")
    line("  （注）ObjC 的 startPedometerEventUpdatesWithHandler: 在 Swift 里叫 **startEventUpdates(handler:)**，")
    line("        stopPedometerEventUpdates 叫 **stopEventUpdates()** —— 两个都把 Pedometer 这个词抹掉了；")
    line("        而且它**没有 queue 参数**（回调排在系统给的串行队列上），和同文件里其它 startXXXUpdates(to:withHandler:) 形状不同")
    line("  CMPedometerEventType 两档：pause=\(CMPedometerEventType.pause.rawValue) resume=\(CMPedometerEventType.resume.rawValue)")
    // 上面两行的 104 / 109 只是数字。把 CMError 整张表读一遍，错误码才对得上名字。
    // 注意它是**普通 C 枚举**（不是 NS_ENUM），所以在 Swift 里是一组全局常量 CMErrorXxx，而不是 CMError.xxx
    line("  CMErrorDomain 字符串逐字=\"\(CMErrorDomain)\"，这一族错误码的名字与实测数值：")
    let cmErrs: [(String, CMError)] = [
        ("CMErrorNULL", CMErrorNULL),
        ("CMErrorDeviceRequiresMovement", CMErrorDeviceRequiresMovement),
        ("CMErrorTrueNorthNotAvailable", CMErrorTrueNorthNotAvailable),
        ("CMErrorUnknown", CMErrorUnknown),
        ("CMErrorMotionActivityNotAvailable", CMErrorMotionActivityNotAvailable),
        ("CMErrorMotionActivityNotAuthorized", CMErrorMotionActivityNotAuthorized),
        ("CMErrorMotionActivityNotEntitled", CMErrorMotionActivityNotEntitled),
        ("CMErrorInvalidParameter", CMErrorInvalidParameter),
        ("CMErrorInvalidAction", CMErrorInvalidAction),
        ("CMErrorNotAvailable", CMErrorNotAvailable),
        ("CMErrorNotEntitled", CMErrorNotEntitled),
        ("CMErrorNotAuthorized", CMErrorNotAuthorized),
        ("CMErrorNilData", CMErrorNilData),
        ("CMErrorSize", CMErrorSize)]
    for (n, e) in cmErrs { line("        \(n) = \(e.rawValue)") }
    expect(came,
           "离线查询**一定会有回调**：要么给 data（numberOfSteps 是 NSNumber），要么给 error。这一条和 §2/§3/§5 那些「handler 一次都不来」的流式 API 形成对照 —— query 类接口是**请求/应答**，不会静默失踪，所以它能进单元测试，流式的在 headless 里只能测「注册成功」")
    expect(CMPedometer.isStepCountingAvailable() == false,
           "计步在这台机器上不可用，但 query 照样回调 —— 「不可用」不代表方法会拒绝你，只代表它给的是错误或者 0 步。写代码时对两者都要留分支")
    expect(CMErrorMotionActivityNotAvailable.rawValue == 104 && CMErrorNotAvailable.rawValue == 109,
           "上面 query 的 **104 就是 CMErrorMotionActivityNotAvailable**（活动分类不可用，计步走的是同一套活动识别管线）、事件流的 **109 就是 CMErrorNotAvailable**（这条能力整机没有）。这一格是把「错误码」变成「可断言的枚举」：头文件里它是个**从 100 起顺排的普通 C 枚举**（不是 NS_ENUM，也没有 0），所以不能按名字猜数值，只能整张读一遍 —— 上一行那十四行就是读出来的全表（最后的 CMErrorSize=113 不是错误码，是枚举元素个数的哨兵）。工程上的用法是把 domain 与 code **两个都判**：domain 认它出自 CoreMotion，code 认它属于哪一类，剩下的分支（重试 / 提示去设置 / 显示本机不支持）才有依据")
}
line("")

line("== 7) CMMotionActivityManager：活动分类的六个布尔与置信度枚举 ==")
do {
    let mam = CMMotionActivityManager()
    line("  CMMotionActivityManager.isActivityAvailable()=\(CMMotionActivityManager.isActivityAvailable()) authorizationStatus()=\(CMMotionActivityManager.authorizationStatus().rawValue)")
    line("  CMMotionActivityConfidence 三档：low=\(CMMotionActivityConfidence.low.rawValue) medium=\(CMMotionActivityConfidence.medium.rawValue) high=\(CMMotionActivityConfidence.high.rawValue)")
    var actCount = 0
    let q = OperationQueue()
    mam.startActivityUpdates(to: q) { activity in
        actCount += 1
        _ = activity
    }
    pump(0.4)
    mam.stopActivityUpdates()
    line("  startActivityUpdates 0.4 秒：handler \(actCount) 次")
    line("  （注）CMMotionActivityHandler 的签名是 **(CMMotionActivity?) -> Void，没有 Error 参数** ——")
    line("        这是本章见到的唯一一条「只有数据、没有错误通道」的流：activity 给 nil 就是它全部的失败表达方式")
    var qaCame = false
    var qaErr = "nil"
    var qaCount = -1
    let sem = DispatchSemaphore(value: 0)
    let d1 = Date(timeIntervalSince1970: 1_700_000_000)
    let d2 = Date(timeIntervalSince1970: 1_700_003_600)
    mam.queryActivityStarting(from: d1, to: d2, to: q) { activities, error in
        qaCame = true
        qaCount = activities?.count ?? -1
        if let e = error as NSError? { qaErr = "domain=\(e.domain) code=\(e.code)" }
        sem.signal()
    }
    let got = (sem.wait(timeout: .now() + 3) == .success)
    line("  queryActivityStarting 回调到达=\(qaCame) 等到=\(got) 数组元素个数=\(qaCount)（-1 表示给的是 nil）error=\(qaErr)")
    expect(actCount == 0,
           "活动分类的流式接口同样是 0 次回调 —— 而且它连 error 都没法给（上一行注：handler 签名里就没有 Error 参数）。而**离线查询会来**：注意它是两个 to 里最后一个（queryActivityStarting(from:to:to:withHandler:)），两个 to 连写很容易看漏")
    expect(qaCame,
           "queryActivityStarting 在 headless 里也会回调（要么给数组要么给 error），所以「有权限时列表长什么样」这件事在本章仍然测不到，但**错误路径**测得到 —— 这就是把日期写成固定时间戳的价值：错误码可复现，能进断言")
}
line("")

line("== 8) CLLocationManager：授权五档、精度常量与出厂参数 ==")
do {
    let lm = CLLocationManager()
    line("  类方法：locationServicesEnabled()=\(CLLocationManager.locationServicesEnabled()) headingAvailable()=\(CLLocationManager.headingAvailable())")
    line("           significantLocationChangeMonitoringAvailable()=\(CLLocationManager.significantLocationChangeMonitoringAvailable()) isRangingAvailable()=\(CLLocationManager.isRangingAvailable())")
    line("  实例 authorizationStatus=\(lm.authorizationStatus.rawValue)（CLAuthorizationStatus 五档实测：notDetermined=\(CLAuthorizationStatus.notDetermined.rawValue) restricted=\(CLAuthorizationStatus.restricted.rawValue) denied=\(CLAuthorizationStatus.denied.rawValue) authorizedAlways=\(CLAuthorizationStatus.authorizedAlways.rawValue) authorizedWhenInUse=\(CLAuthorizationStatus.authorizedWhenInUse.rawValue)）")
    line("  实例 accuracyAuthorization=\(lm.accuracyAuthorization.rawValue)（CLAccuracyAuthorization 两档：fullAccuracy=\(CLAccuracyAuthorization.fullAccuracy.rawValue) reducedAccuracy=\(CLAccuracyAuthorization.reducedAccuracy.rawValue)）")
    line("  出厂参数：desiredAccuracy=\(f4(lm.desiredAccuracy)) distanceFilter=\(f4(lm.distanceFilter))")
    line("  六个精度常量的实际值：bestForNavigation=\(f4(kCLLocationAccuracyBestForNavigation)) best=\(f4(kCLLocationAccuracyBest)) nearestTenMeters=\(f4(kCLLocationAccuracyNearestTenMeters)) hundredMeters=\(f4(kCLLocationAccuracyHundredMeters)) kilometer=\(f4(kCLLocationAccuracyKilometer)) threeKilometers=\(f4(kCLLocationAccuracyThreeKilometers))")
    line("  kCLLocationAccuracyReduced=\(f4(kCLLocationAccuracyReduced))（iOS 14+，「大致位置」那档）、kCLDistanceFilterNone=\(f4(kCLDistanceFilterNone))")
    line("  出厂：pausesLocationUpdatesAutomatically=\(lm.pausesLocationUpdatesAutomatically) activityType=\(lm.activityType.rawValue) headingOrientation=\(lm.headingOrientation.rawValue) headingFilter=\(f4(lm.headingFilter))")
    line("  CLActivityType 五档实测：other=\(CLActivityType.other.rawValue) automotiveNavigation=\(CLActivityType.automotiveNavigation.rawValue) fitness=\(CLActivityType.fitness.rawValue) otherNavigation=\(CLActivityType.otherNavigation.rawValue) airborne=\(CLActivityType.airborne.rawValue)")
    line("        （**没有 .automotive 这一档**，探针实测写 CLActivityType.automotive 的编译器原文：")
    line("         error: type 'CLActivityType' has no member 'automotive' —— 全名是 automotiveNavigation）")
    line("  出厂：location=nil heading=nil monitoredRegions.count=\(lm.monitoredRegions.count) maximumRegionMonitoringDistance=\(f4(lm.maximumRegionMonitoringDistance))")
    let locCame = lm.location
    line("  没 start 就读：location=\(locCame == nil ? "nil" : "非 nil") —— 和 CoreMotion 的 data 属性同一个形状")
    expect(lm.desiredAccuracy == kCLLocationAccuracyBest,
           "desiredAccuracy 出厂读回 **-1**，而 -1 正是 kCLLocationAccuracyBest（上面两行把七个常量的真实值全印出来了：bestForNavigation=-2、best=-1、十米档=10、百米档=100、公里档=1000、三公里档=3000、reduced=6380000）。这一条我写错过：按「系统默认总该保守一点」的直觉把断言写成 ==kCLLocationAccuracyHundredMeters（100 米档），**跑出来直接 FAIL**，实测默认就是「尽量准」。头文件对这条的原话也只有 The default value varies by platform，没给数字 —— 所以「默认精度」这种问题只能读，不能背。顺带记住这一组常量是**负数哨兵和米制值混排的**，读回一个数先认它属于哪一类；而 kCLLocationAccuracyReduced 是个**巨大的正数**（6380000 米），既不是哨兵也不是可用的精度门槛")
    expect(lm.distanceFilter == kCLDistanceFilterNone,
           "distanceFilter 出厂是 kCLDistanceFilterNone，常量值同样是 **负数哨兵 -1**（见上面打印）。所以「移动多远才回调」的默认答案是「不设门槛」，而不是某个米数 —— 真机上这会导致相当密集的回调，做省电优化时第一条要改的就是它")
    expect(lm.authorizationStatus == .notDetermined,
           "authorizationStatus 读到的是 **notDetermined（0）**，和 §5/§6/§7 那三家 CoreMotion 的 authorizationStatus 全部读回 denied（2）**恰好相反** —— 这是本章最重要的一条跨框架差异。原因是两边走的不是同一套授权：CoreLocation 按「这个 App 有没有问过」记账，没问过就是 notDetermined（该弹窗）；CoreMotion 的权限模型在 headless 环境里直接给 denied。**如果照搬「denied 就引导去设置页」的分支，CoreLocation 这条路永远进不去那个分支**，判断必须按框架各自写")
    expect(lm.accuracyAuthorization == .reducedAccuracy,
           "accuracyAuthorization 读回 **reducedAccuracy（1）**，而 authorizationStatus 同时是 notDetermined —— 头文件专门讲了这种组合：它说 notDetermined 时即使 accuracyAuthorization 是 fullAccuracy 也收不到精确位置，也就是说**这两个属性要一起解读，任何一个单独看都会读错**。本章实测的是反方向的组合（notDetermined + reduced），同样说明单独读哪一个都不成立")
    expect(!lm.pausesLocationUpdatesAutomatically,
           "pausesLocationUpdatesAutomatically 出厂读回 **false**，而头文件的注释原话是 By default, this is YES for applications linked against iOS 6.0 or later —— **注释和实测对不上**。这类「文档说默认 YES、读出来是 NO」的属性不是个例（同一份头文件里 allowsBackgroundLocationUpdates 的默认还跟「链接的 SDK 版本」有关），所以判断一律读回来打印，别照注释写分支")
    expect(CLLocationManager.locationServicesEnabled() && !CLLocationManager.headingAvailable(),
           "四个类方法在模拟器上的组合是「定位服务开着、罗盘不可用、重要位置变化监控可用、iBeacon 测距不可用」。**locationServicesEnabled() 是全局开关（用户能不能在设置里关掉定位服务），headingAvailable() 是硬件查询**，两者不是一回事：前一个 true 不代表拿得到位置（还要 authorizationStatus），后一个 false 也不影响距离计算（§9）。这一组是「定位功能在这台设备上到底能跑到哪一步」最快的一次探测")
    expect(lm.headingOrientation.rawValue == 1 && lm.headingFilter == 1 && lm.maximumRegionMonitoringDistance == 2128000,
           "航向那两个出厂值也都是具体数字：headingOrientation=1（CLDeviceOrientationPortrait，即「按竖屏解读航向」，**不是 unknown=0**）、headingFilter=1 度；maximumRegionMonitoringDistance 读回 2128000 米 —— 这是系统给围栏半径的上限（超过它会被裁，这条**不在本章验证范围**，headless 只能读到上限本身）。这三个值都不在任何「常见笔记」里，只能读")
    lm.desiredAccuracy = kCLLocationAccuracyKilometer
    lm.distanceFilter = 250
    lm.pausesLocationUpdatesAutomatically = true
    lm.activityType = .fitness
    line("  改四个写一遍读：desiredAccuracy=\(f4(lm.desiredAccuracy)) distanceFilter=\(f4(lm.distanceFilter)) pauses=\(lm.pausesLocationUpdatesAutomatically) activityType=\(lm.activityType.rawValue)")
    expect(lm.desiredAccuracy == kCLLocationAccuracyKilometer && lm.distanceFilter == 250 && lm.activityType == .fitness,
           "desiredAccuracy、distanceFilter、activityType 三个**读写一致**（1000 / 250 / 3，见上一行），和 CoreMotion 的 updateInterval 一样：设了不会立刻影响什么，但读得到，所以可以在单元测试里断言「我配过了」")
    expect(lm.pausesLocationUpdatesAutomatically == false,
           "**只有 pausesLocationUpdatesAutomatically 写不进去**：上一行明明设了 true，读回来还是 false，而且**没有任何报错、没有任何日志**。这不是 bug，是它的语义 —— 这个开关控制的是「系统判断你可能停下了就不再给你位置」，而在这台机器上根本没有位置流可停（authorizationStatus 还是 notDetermined，§8 开头就读到了），所以系统直接把它按无效处理。写这类「行为开关」属性时，**读回来验证**比「设过就算数」可靠得多，尤其是 headless 测试里")
}
line("")

line("== 9) CLLocation 的纯数学：distance(from:) 是唯一不需要硬件也不需要权限的一整块 ==")
do {
    let c1 = CLLocationCoordinate2DMake(0, 0)
    let c2 = CLLocationCoordinate2DMake(0, 1)
    let l1 = CLLocation(latitude: 0, longitude: 0)
    let l2 = CLLocation(coordinate: c2, altitude: 0, horizontalAccuracy: 5, verticalAccuracy: 3,
                        timestamp: Date(timeIntervalSince1970: 1_700_000_000))
    line("  (0,0) 到 (0,1)：distance(from:)=\(f4(l1.distance(from: l2))) 米（赤道经度 1°≈111319 米，这就是地球半径反推得出来的数）")
    let l3 = CLLocation(latitude: 60, longitude: 0)
    let l4 = CLLocation(latitude: 60, longitude: 1)
    line("  (60,0) 到 (60,1)：\(f4(l3.distance(from: l4))) 米 —— 同一个 1° 在纬度 60° 只剩约一半（cos60°=0.5）")
    line("  对称性：l2.distance(from: l1)=\(f4(l2.distance(from: l1)))")
    let full = CLLocation(coordinate: c1, altitude: 100, horizontalAccuracy: 5, verticalAccuracy: 3, course: 90, speed: 10, timestamp: Date(timeIntervalSince1970: 1_700_000_000))
    line("  全参数构造：coordinate=(\(f4(full.coordinate.latitude)),\(f4(full.coordinate.longitude))) altitude=\(f4(full.altitude)) horizontalAccuracy=\(f4(full.horizontalAccuracy)) verticalAccuracy=\(f4(full.verticalAccuracy)) course=\(f4(full.course)) speed=\(f4(full.speed))")
    line("  timestamp 用的是固定时间戳 \(full.timestamp.timeIntervalSince1970)，所以两份输出的距离/精度都能逐字节比对")
    let noCourse = CLLocation(coordinate: c1, altitude: 0, horizontalAccuracy: 5, verticalAccuracy: 3, timestamp: Date(timeIntervalSince1970: 1_700_000_000))
    line("  五参数版（没有 course/speed）读回来：course=\(f4(noCourse.course)) speed=\(f4(noCourse.speed)) —— 两个都是 **-1**，是哨兵不是「零速」「正北」")
    line("  CLLocation 一共五个构造器（头文件实测）：latitude:longitude: / 五参数（无 course speed）/ 七参数 / 九参数（加 courseAccuracy、speedAccuracy，iOS 10+）/ 十参数（再加来源信息，iOS 15+）")
    let acc = CLLocation(coordinate: c1, altitude: 0, horizontalAccuracy: 5, verticalAccuracy: 3,
                         course: 90, courseAccuracy: 2, speed: 10, speedAccuracy: 1.5,
                         timestamp: Date(timeIntervalSince1970: 1_700_000_000))
    line("  九参数版读回：courseAccuracy=\(f4(acc.courseAccuracy)) speedAccuracy=\(f4(acc.speedAccuracy)) —— 这一对是「方向和速度的不确定度」，和 horizontalAccuracy 同级概念")
    let srcInfo = CLLocationSourceInformation(softwareSimulationState: true, andExternalAccessoryState: false)
    let withSrc = CLLocation(coordinate: c1, altitude: 0, horizontalAccuracy: 5, verticalAccuracy: 3,
                             course: 90, courseAccuracy: 2, speed: 10, speedAccuracy: 1.5,
                             timestamp: Date(timeIntervalSince1970: 1_700_000_000), sourceInfo: srcInfo)
    line("  十参数版（iOS 15+）带来源信息：isSimulatedBySoftware=\(withSrc.sourceInformation?.isSimulatedBySoftware == true) isProducedByAccessory=\(withSrc.sourceInformation?.isProducedByAccessory == true)")
    line("        这一对的标签全是「名字和属性对不上」的类型，三条编译器原文（都是我先写错、编译器回我的）：")
    line("        CLLocationSourceInformation(isSoftware:andExternalAccessory:)  → error: incorrect argument labels in call (have 'isSoftware:andExternalAccessory:', expected 'softwareSimulationState:andExternalAccessoryState:')")
    line("        CLLocation(…:sourceInformation:)                              → error: incorrect argument label in call (have '…sourceInformation:', expected '…sourceInfo:')")
    line("        CLLocationCoordinate2DIsValid(bad)（bad 是 CLLocation）        → error: cannot convert value of type 'CLLocation' to expected argument type 'CLLocationCoordinate2D'")
    line("  不带 sourceInfo 构造时读回：full.sourceInformation=\(full.sourceInformation == nil ? "nil" : NSStringFromClass(type(of: full.sourceInformation!)))"
         + "（**头文件把这条标成 nullable，实测自己造的 location 上它照样非 nil**，"
         + "两个 flag 读回 isSimulatedBySoftware=\(full.sourceInformation?.isSimulatedBySoftware == false) isProducedByAccessory=\(full.sourceInformation?.isProducedByAccessory == false)）")
    line("        连最简的 CLLocation(latitude:longitude:) 也一样非 nil；CLLocationSourceInformation() 无参构造同样给 false/false")
    expect(full.sourceInformation != nil && full.sourceInformation?.isSimulatedBySoftware == false,
           "**「标了 nullable」不等于「会给 nil」**：sourceInformation 在两个构造器（七参数、两参数）上都返回一个默认对象，字段全 false。这是 §16 那条「同框架不同类各自约定」的又一例——同一份 CLLocation.h 里 `floor` 标 nullable 且**真的**给 nil（§16 实测），`sourceInformation` 标 nullable 却从来不给 nil。判「是不是模拟器/软件造出来的位置」只能读 `isSimulatedBySoftware`，写成 `location.sourceInformation != nil` 恒为真，等于没判")
    line("  哨兵语义（头文件原话与实测各一遍）：横向位置无效看 **horizontalAccuracy 为负**，高度无效看 **verticalAccuracy 为负** —— 管高度的是 vertical 那一个，不是 horizontal（我第一版把这两句写成「horizontalAccuracy<0 表示高度无效」，抄头文件时串行号了）")
    let twoParam = CLLocation(latitude: 31.2304, longitude: 121.4737)
    line("  两参数构造的出厂值：altitude=\(f4(twoParam.altitude)) horizontalAccuracy=\(f4(twoParam.horizontalAccuracy)) verticalAccuracy=\(f4(twoParam.verticalAccuracy)) course=\(f4(twoParam.course)) speed=\(f4(twoParam.speed))")
    let negAcc = CLLocation(coordinate: c1, altitude: 100, horizontalAccuracy: -1, verticalAccuracy: -1,
                            timestamp: Date(timeIntervalSince1970: 1_700_000_000))
    line("  故意把两个精度都写 -1、altitude 写 100：读回 altitude=\(f4(negAcc.altitude)) horizontalAccuracy=\(f4(negAcc.horizontalAccuracy)) verticalAccuracy=\(f4(negAcc.verticalAccuracy))")
    line("  ellipsoidalAltitude（iOS 15+，WGS 84 椭球高）在手工构造的对象上读回：twoParam=\(f4(twoParam.ellipsoidalAltitude)) negAcc=\(f4(negAcc.ellipsoidalAltitude))（altitude 明明分别写的是 0 和 100）")
    expect(twoParam.verticalAccuracy == -1 && twoParam.horizontalAccuracy == 0,
           "同一个「什么都没给」的两参数 CLLocation，**两个精度的出厂值不一样**：verticalAccuracy 是 -1（= 高度无效，符合头文件），horizontalAccuracy 却是 **0**（不是负数）。也就是说「最简构造」在系统眼里是「横向精度极好、高度不可用」，所以判无效要**按字段各判各的**（accuracy < 0），写一个「任一精度为负就整条丢弃」的判断会把这种带正常水平位置的点整条扔掉")
    expect(negAcc.altitude == 100 && negAcc.horizontalAccuracy == -1,
           "**「负数表示无效」只是约定，不是行为**：把 verticalAccuracy 写成 -1，altitude 照样原样读回 100，对象不会替你清空、也不会报错。这类「语义靠约定、存储不设防」的字段（和 §12 的负半径、本节的非法坐标是同一件事），过滤逻辑必须自己写，而且要写在使用侧而不是指望构造器")
    expect(twoParam.ellipsoidalAltitude == 0 && negAcc.ellipsoidalAltitude == 0,
           "**ellipsoidalAltitude 与 altitude 不同源**：alt=100 的对象上它读回 0，不是 100、也不是「altitude 减大地水准面差距」。这个字段只有真实设备/系统给的位置才填得进去（iOS 15+ 才有），**做高度相关计算时别把两个 altitude 当一个**，更别拿手工对象验证换算式 —— 手工对象上它恒 0，任何断言都会「通过」")
    let bad = CLLocation(latitude: 91, longitude: 200)
    line("  造一个非法坐标 latitude=91 longitude=200：CLLocationCoordinate2DIsValid(bad.coordinate)=\(CLLocationCoordinate2DIsValid(bad.coordinate))，而 bad.coordinate.latitude=\(f4(bad.coordinate.latitude))（**值原样存住了，构造时没有夹紧也没有报错**）")
    let okc = CLLocationCoordinate2DMake(-90, 180)
    line("  边界值 (−90,180)：IsValid=\(CLLocationCoordinate2DIsValid(okc))；(90,180) IsValid=\(CLLocationCoordinate2DIsValid(CLLocationCoordinate2DMake(90, 180)))；NaN 经度 IsValid=\(CLLocationCoordinate2DIsValid(CLLocationCoordinate2DMake(0, .nan)))")
    expect(l1.distance(from: l2) > 111_000 && l1.distance(from: l2) < 112_000,
           "赤道 1° 经度实测 \(f4(l1.distance(from: l2))) 米 —— 这条断言的意义是「**CLLocation 的距离计算是纯数学，headless 能用、可以进单元测试**」。它是本章唯一一个不需要硬件、不需要权限、结果还能预先算出来的整块 API，所以「测定位功能」时先测这块，剩下的是管线而不是算术")
    expect(l3.distance(from: l4) < l1.distance(from: l2) / 2 + 200,
           "纬度 60° 的 1° 距离实测 \(f4(l3.distance(from: l4)))，正好是赤道那半左右 —— 任何「按经纬度差估算距离」的手写代码（dx=Δlon·111km·cos(lat)）在这里能对上答案；**忘了乘 cos(lat) 是定位功能里最常见的一类 bug**，用这两个数一验就现形")
    expect(l2.distance(from: l1) == l1.distance(from: l2),
           "距离**对称**（逐字节相等，不是近似）。顺带一提：`CLLocation.distance(from:)` 在 Swift 里就是这个方法名，ObjC 侧的 distanceFromLocation: 被桥接掉了，写成 l1.distanceFromLocation(l2) 编译器不认")
    expect(!CLLocationCoordinate2DIsValid(kCLLocationCoordinate2DInvalid) && CLLocationCoordinate2DIsValid(c1),
           "**IsValid 是纯函数（C 函数 CLLocationCoordinate2DIsValid），不是 CLLocation 的属性**；官方那个「无效坐标」常量 kCLLocationCoordinate2DInvalid 判 false、正常坐标判 true，而 CLLocation(latitude:longitude:) 对非法值**照收不误**（上一行实测 latitude 仍然读回 91）。也就是「构造成功」不代表「坐标能用」，夹紧/校验得自己做")
}
line("")

line("== 10) 挂上 delegate 之后：定位这条流在无权限环境里同样是静默的 ==")
do {
    let lm = CLLocationManager()
    let d = CLRecorder()
    lm.delegate = d
    line("  delegate 已设：authorizationStatus=\(lm.authorizationStatus.rawValue) location=\(lm.location == nil ? "nil" : "有值") monitoredRegions.count=\(lm.monitoredRegions.count)")
    lm.startUpdatingLocation()
    for i in 1...3 {
        pump(1.0)
        line("  第 \(i) 秒：回调记录=\(d.log.joined(separator: ", "))（累计 \(d.log.count) 条）location=\(lm.location == nil ? "nil" : "有值")")
    }
    lm.requestLocation()
    pump(1.0)
    line("  调过 requestLocation() 再泵 1 秒：累计 \(d.log.count) 条，location=\(lm.location == nil ? "nil" : "有值")")
    lm.stopUpdatingLocation()
    expect(d.log.isEmpty && lm.location == nil,
           "**一个回调都没来**：没有 didUpdateLocations，也没有 didFailWithError，requestLocation() 也一样静默。这一条把 §6 那句「query 类接口是请求/应答，不会静默失踪」限定了范围 —— 会不会静默取决于**底层有没有服务可问**：CMPedometer 的离线查询是本地数据库查询，所以必回（给 error）；CLLocationManager 的 delegate 是异步服务管线，无权限/无硬件时它连「失败」都懒得通知你。**所以定位功能的测试不能只挂 delegate 等回调，必须有超时**")
    expect(lm.authorizationStatus == .notDetermined,
           "跑完一整轮 startUpdating/requestLocation/stopUpdating 之后 authorizationStatus **仍然是 notDetermined** —— 这些方法都不会自己把状态推到 denied。弹窗只有 requestWhenInUseAuthorization / requestAlwaysAuthorization 两条路，而它们在 headless 里既弹不出来、又会往 stderr 打日志（§11 末实测），所以本章不调它们。想测「用户点了拒绝」的分支只能靠 simulator 的权限设置或真机")
    let h = CLHeading()
    line("  CLHeading 和 CMAttitude 是**同一个空壳病**：CLHeading() 构造得出来（类名=\(NSStringFromClass(type(of: h)))、isEqual 另一个新实例=\(h.isEqual(CLHeading()))），")
    line("        但探针实测 trueHeading / magneticHeading / headingAccuracy / x / y / z 读任何一个都是 signal 11：")
    line("        Child process terminated with signal 11: Segmentation fault")
    line("        （只有 copy() 不崩，那是 NSObject 层的）—— 它只能从 didUpdateHeading: 或者 manager.heading 拿")
    expect(h.isEqual(CLHeading()) == false,
           "又一个「isEqual 永假」的类（§4 的 CMAttitude 同款）。这两个类都重写了 isEqual 去比内部状态，而内部状态空的时候一律判不相等 —— **自己造出来的这些对象连「是不是同一个」都回答不了**，就更别指望拿它们做数据流测试的替身。要构造假数据请用 CLLocation（§9 全程可用，因为它是纯值对象）")
}
line("")

line("== 11) 三条会直接把进程打死的路径（探针实测原文，本章示例**不调用**它们） ==")
do {
    line("  这一节是本章唯一「写了就跑不完」的内容，所以只放探针实测原文，示例里一行都不执行。")
    line("  三条的共同点：**它们不是返回 error，而是直接终止进程**，所以「跑一遍看看会不会崩」这种验证方式在这里代价最高。")
    line("")
    line("  A) lm.allowsBackgroundLocationUpdates = true（Info.plist 里没有 UIBackgroundModes: location）")
    line("     探针实测：赋值那一行当场炸，stderr 原文两行：")
    line("     *** Terminating app due to uncaught exception 'NSInternalInconsistencyException', reason: 'Invalid parameter not satisfying: !stayUp || CLClientIsBackgroundable(internal->fClient) || _CFMZEnabled()'")
    line("     Child process terminated with signal 6: Abort trap")
    line("     注意它是 **setter 里断言失败**，不是 startUpdating 时才炸 —— 属性赋值就是崩溃点，这类「设一个开关就 abort」的 API 在 iOS 里不多")
    line("")
    line("  B) lm.requestLocation()（**探针实测的是「delegate 没设」这一种**）")
    line("     顺带说明：异常文案写的是「Delegate must respond to locationManager:didUpdateLocations:」，")
    line("     按这句话推「设了 delegate 但没实现这个方法」也会走同一条断言 —— 但这一种**本章没有单独实测**，只当推测记着")
    line("     探针实测：*** Terminating app due to uncaught exception 'NSInternalInconsistencyException', reason: 'Delegate must respond to locationManager:didUpdateLocations:'")
    line("     Child process terminated with signal 6: Abort trap")
    line("     而 §10 里同样的 requestLocation() 在有 delegate 时**安静地什么都不回** —— 一个方法两种失败形态（缺 delegate 就 abort，缺权限就静默），")
    line("     这就是为什么 requestLocation 的崩溃经常出现在「临时把 delegate 摘掉做调试」之后")
    line("")
    line("  C) lm.requestWhenInUseAuthorization()（Info.plist 里没有 NSLocationWhenInUseUsageDescription）")
    line("     探针实测：**不崩**，但往 stderr 打一条 NSLog，原文是")
    line("     This app has attempted to access privacy-sensitive data without a usage description. The app's Info.plist must contain an “NSLocationWhenInUseUsageDescription” key with a string value explaining to the user how the app uses this data")
    line("     而且 authorizationStatus 调用前后都还是 0（notDetermined）—— 它只是**不弹窗**，不报错、不改状态。")
    line("     这一条对本章示例是致命的：判定要求 stderr 为空，一条 NSLog 就足够让示例失败，所以本章全程不调它")
    expect(CLLocationManager().authorizationStatus == .notDetermined,
           "这一节没有断言可写（三条都不该执行），所以只放一条「本章示例确实没碰过弹窗接口」的旁证：新构造一个 manager，状态仍是 notDetermined（0）。真正要记住的是**这三条的失败形态各不相同**：A 是 setter 里 abort、B 是方法里 abort、C 是 stderr 里一条日志然后当没事发生 —— 排查时看症状就能反推是哪一条")
}
line("")

line("== 12) CLCircularRegion 的纯数学：围栏的 contains 是地理距离，不是经纬度差 ==")
do {
    let center = CLLocationCoordinate2DMake(31.2304, 121.4737)
    let r = CLCircularRegion(center: center, radius: 500, identifier: "home")
    line("  构造：radius=\(f4(r.radius)) identifier=\(r.identifier) center=(\(f4(r.center.latitude)),\(f4(r.center.longitude)))")
    line("  出厂 notifyOnEntry=\(r.notifyOnEntry) notifyOnExit=\(r.notifyOnExit)（两个默认都是 **true**）")
    line("  contains：圆心=\(r.contains(center))")
    let near = CLLocationCoordinate2DMake(31.2304 + 0.001, 121.4737)
    let far = CLLocationCoordinate2DMake(31.2304 + 0.005, 121.4737)
    let east = CLLocationCoordinate2DMake(31.2304, 121.4737 + 0.005)
    let home = CLLocation(latitude: 31.2304, longitude: 121.4737)
    let ts = Date(timeIntervalSince1970: 1_700_000_000)
    let dNear = home.distance(from: CLLocation(coordinate: near, altitude: 0, horizontalAccuracy: 0, verticalAccuracy: 0, timestamp: ts))
    let dFar = home.distance(from: CLLocation(coordinate: far, altitude: 0, horizontalAccuracy: 0, verticalAccuracy: 0, timestamp: ts))
    let dEast = home.distance(from: CLLocation(coordinate: east, altitude: 0, horizontalAccuracy: 0, verticalAccuracy: 0, timestamp: ts))
    line("  北移 0.001°（实测直线距离 \(f4(dNear)) 米）：contains=\(r.contains(near))")
    line("  北移 0.005°（实测直线距离 \(f4(dFar)) 米）：contains=\(r.contains(far))")
    line("  东移 0.005°（实测直线距离 \(f4(dEast)) 米）：contains=\(r.contains(east))")
    line("  同样是 0.005°，北移 \(f4(dFar)) 米 vs 东移 \(f4(dEast)) 米 —— 这个纬度上经度 1° 的弧长只有纬度的约 cos(31.23°)=\(f4(cos(31.2304 * Double.pi / 180))) 倍")
    r.notifyOnEntry = false
    line("  notifyOnEntry 是可写的：改成 false 之后读回=\(r.notifyOnEntry)")
    let badR = CLCircularRegion(center: center, radius: -1, identifier: "negative")
    line("  半径写 -1 也能构造：radius=\(f4(badR.radius)) contains(center)=\(badR.contains(center)) —— 构造器**不校验半径**")
    let bigR = CLCircularRegion(center: center, radius: 9_999_999, identifier: "tooBig")
    line("  半径 9999999 米读回=\(f4(bigR.radius))（**对象自己不被裁剪**，裁剪发生在 startMonitoring 那一侧）")
    expect(r.contains(center) && !r.contains(far),
           "contains 用的是**地理距离**（§9 那套算法），所以「0.005° 在 500 米围栏外」这种判断可以直接进单元测试 —— 它和 CLLocation.distance 一样是纯数学，不需要权限也不需要硬件。想手写「Δlat 小于某个度数就算在圈内」是错的：§9 已经实测过同一个 1° 在不同纬度距离差一倍，围栏判断同理")
    expect(r.radius == 500 && r.identifier == "home" && r.notifyOnEntry == false,
           "CLCircularRegion 三个字段都是**读回原样**的普通对象字段，identifier 是唯一的必填字符串（系统拿它做回调时的身份）。注意 §10 那个 delegate 里 monitoringDidFail / didEnterRegion 收到的就是这个 identifier —— 名字起得含糊（\"region1\"）的围栏在日志里根本查不出是哪个")
    expect(!badR.contains(center) && bigR.radius == 9_999_999,
           "**半径不校验**：-1 照样构造、照样读回 -1，而 contains 对 -1 半径一律 false（于是「永远在圈外」是静默的，不会有人报错）；超过 maximumRegionMonitoringDistance（§8 实测 2128000 米）的大半径在对象层也不裁，**裁不裁发生在交给系统那一刻**。这类「值对象随便收、行为层才管」的接口，校验必须自己写")
}
line("")

line("== 13) CLGeocoder：本章唯一一个「请求发出去就再也不回」的接口 ==")
do {
    let g = CLGeocoder()
    line("  新建：isGeocoding=\(g.isGeocoding)")
    var came = false
    var count = -1
    var err = "nil"
    let sem = DispatchSemaphore(value: 0)
    g.geocodeAddressString("Cupertino") { placemarks, error in
        came = true
        count = placemarks?.count ?? -1
        if let e = error as NSError? { err = "domain=\(e.domain) code=\(e.code)" }
        sem.signal()
    }
    line("  发出请求之后立刻读：isGeocoding=\(g.isGeocoding)")
    let got = (sem.wait(timeout: .now() + 3) == .success)
    line("  等 3 秒：等到回调=\(got) 回调到达标记=\(came) placemarks 个数=\(count)（-1 表示 nil）error=\(err)")
    line("  再发一个请求测并发：第二个 completionHandler 也等 3 秒")
    var came2 = false
    let sem2 = DispatchSemaphore(value: 0)
    g.geocodeAddressString("San Francisco") { _, _ in came2 = true; sem2.signal() }
    let got2 = (sem2.wait(timeout: .now() + 3) == .success)
    line("  第二个回调到达=\(got2)（标记=\(came2)），此时 isGeocoding=\(g.isGeocoding)")
    g.cancelGeocode()
    line("  cancelGeocode() 之后：isGeocoding=\(g.isGeocoding) 两个回调累计到达=\(came || came2)")
    line("  反查也一样：reverseGeocodeLocation(Cupertino 坐标) 等 3 秒")
    var came3 = false
    var err3 = "nil"
    let sem3 = DispatchSemaphore(value: 0)
    let loc = CLLocation(coordinate: CLLocationCoordinate2DMake(37.3349, -122.0090), altitude: 0,
                         horizontalAccuracy: 10, verticalAccuracy: 0,
                         timestamp: Date(timeIntervalSince1970: 1_700_000_000))
    g.reverseGeocodeLocation(loc) { placemarks, error in
        came3 = true
        if let e = error as NSError? { err3 = "domain=\(e.domain) code=\(e.code)" }
        sem3.signal()
    }
    let got3 = (sem3.wait(timeout: .now() + 3) == .success)
    line("  反查回调到达=\(got3)（标记=\(came3)）error=\(err3)")
    expect(!came && !came2 && !came3,
           "三条 geocode 请求（正查两条、反查一条）**一次回调都没有** —— 这是和 §6/§7 的「离线查询必回」完全相反的一类：CLGeocoder 要走网络，headless 环境里没有可用的地理编码服务，请求就悬在那里。所以「geocode 一定会回 callback」这个假设在有网/无网两种环境下结论不同，**任何用 geocode 的代码都必须自己带超时**，不能指望系统给你错误")
    expect(!g.isGeocoding,
           "isGeocoding 在请求挂着的时候仍然是 **false** —— 它不是「我有没有未决请求」的计数器，别拿它当防重复提交的开关：实测三行打印（新建 / 发出请求后立刻读 / cancel 之后读）都是 false，而这三行之间确实各有一份 completionHandler 还悬着。想要「同一时刻只发一个」的语义必须自己在外面加标志")
    expect(!got && !got2 && !got3,
           "三个 semaphore 等待**全部超时**（got/got2/got3 见上面三行打印，都是 false）—— 这一行的真正作用是说明这段代码不会把示例卡死：每次等待都设了 3 秒上限，所以「接口永不回复」不会把 harness 拖到 RUN_TIMEOUT 而只留下一个 false。写异步测试时**给每个等待设上限**比断言内容更要紧，一次没有超时的等待就是一份挂住的 CI")
}
line("")

line("== 14) 设备能力自查：UIDevice 的电量开关、UIScreen 的像素与刷新率、ProcessInfo 的热状态 ==")
do {
    let dev = UIDevice.current
    line("  UIDevice.current：model=\(dev.model) systemName=\(dev.systemName) systemVersion 长度=\(dev.systemVersion.count) name 长度=\(dev.name.count)")
    line("             identifierForVendor 有值=\(dev.identifierForVendor != nil)（**值不打印**：它是每装一次都可能变的 UUID，打进输出就没法逐字节比对了）")
    line("             isMultitaskingSupported=\(dev.isMultitaskingSupported) orientation=\(dev.orientation.rawValue) batteryState=\(dev.batteryState.rawValue)")
    line("  电量监控**默认关**：isBatteryMonitoringEnabled=\(dev.isBatteryMonitoringEnabled) → batteryLevel=\(f4(Double(dev.batteryLevel))) batteryState=\(dev.batteryState.rawValue)（0=unknown，档位实测 unknown=\(UIDevice.BatteryState.unknown.rawValue) unplugged=\(UIDevice.BatteryState.unplugged.rawValue) charging=\(UIDevice.BatteryState.charging.rawValue) full=\(UIDevice.BatteryState.full.rawValue)）")
    expect(dev.batteryLevel == -1 && dev.batteryState == .unknown,
           "**开关没打开时 batteryLevel 读回 -1、batteryState 读回 unknown**，这是头文件写在注释里的（-1.0 if UIDeviceBatteryStateUnknown），也是本章实测对上的少数「文档默认值」之一。-1 不是电量，是「没监控」；把它当 0% 显示出去就是一个具体的线上事故（用户看到 0 格电）")
    dev.isBatteryMonitoringEnabled = true
    line("  尝试打开监控：isBatteryMonitoringEnabled=\(dev.isBatteryMonitoringEnabled) batteryLevel=\(f4(Double(dev.batteryLevel))) batteryState=\(dev.batteryState.rawValue)")
    expect(!dev.isBatteryMonitoringEnabled,
           "**这个开关在这台机器上写不进去**：赋 true 之后读回来还是 false，batteryLevel/batteryState 原地不动，而且照例**没有任何报错**。对比 §8：那个 pausesLocationUpdatesAutomatically 属于 CLLocationManager 自己的对象，写不进去是因为底层没有位置服务；这个属于 UIDevice，而本示例是 simctl spawn 出来的命令行进程，**没有跑起来的 UIApplication**，UIKit 也就不认这次「开启监控」。**结论：电量相关的代码不能用这种 headless 方式测**，要么起真的 App target，要么在测试 setUp 里先断言开关写得进去（写不进去直接 XCTFail，别让测试假绿）")
    line("  再读一次（开关从未真的打开过）：isBatteryMonitoringEnabled=\(dev.isBatteryMonitoringEnabled) batteryLevel 读回=\(f4(Double(dev.batteryLevel)))")
    expect(dev.batteryLevel == -1,
           "batteryLevel 全程 -1：它不是「最后一次读数的缓存」，而是每次读都取决于监控有没有开着。所以想显示电量必须**全程开着监控**（不需要时再关掉省电），而不是要用的时候读一下 —— 后者拿到的是 -1，界面上就成了「电量 0%」")
    line("  姿态：orientation=\(dev.orientation.rawValue)（UIDeviceOrientation：unknown=\(UIDeviceOrientation.unknown.rawValue) portrait=\(UIDeviceOrientation.portrait.rawValue) portraitUpsideDown=\(UIDeviceOrientation.portraitUpsideDown.rawValue) landscapeLeft=\(UIDeviceOrientation.landscapeLeft.rawValue) landscapeRight=\(UIDeviceOrientation.landscapeRight.rawValue) faceUp=\(UIDeviceOrientation.faceUp.rawValue) faceDown=\(UIDeviceOrientation.faceDown.rawValue)）")
    line("        无硬件时读回 unknown(0)，而 interface 方向（第 21 章的 traitCollection）始终是竖屏 —— **两套方向枚举值域不同**，别拿 UIDevice.orientation 去判断界面旋转")
    // 值域不同这件事还不够，两套枚举的**左右是反的**：只有把 rawValue 全读出来才看得出来
    line("        UIInterfaceOrientation 五档实测：unknown=\(UIInterfaceOrientation.unknown.rawValue) portrait=\(UIInterfaceOrientation.portrait.rawValue) portraitUpsideDown=\(UIInterfaceOrientation.portraitUpsideDown.rawValue) landscapeLeft=\(UIInterfaceOrientation.landscapeLeft.rawValue) landscapeRight=\(UIInterfaceOrientation.landscapeRight.rawValue)")
    line("        交叉相等：device.landscapeLeft(\(UIDeviceOrientation.landscapeLeft.rawValue)) 与 interface.landscapeRight(\(UIInterfaceOrientation.landscapeRight.rawValue)) 同值=\(UIDeviceOrientation.landscapeLeft.rawValue == UIInterfaceOrientation.landscapeRight.rawValue)；同名的两边=\(UIDeviceOrientation.landscapeLeft.rawValue == UIInterfaceOrientation.landscapeLeft.rawValue)")
    line("        而且 interface 那一套**没有 faceUp/faceDown**，探针实测的编译器原文：")
    line("         UIInterfaceOrientation.faceUp → error: type 'UIInterfaceOrientation' has no member 'faceUp'")
    expect(UIDeviceOrientation.landscapeLeft.rawValue == UIInterfaceOrientation.landscapeRight.rawValue
           && UIDeviceOrientation.landscapeRight.rawValue == UIInterfaceOrientation.landscapeLeft.rawValue
           && UIDeviceOrientation.portrait.rawValue == UIInterfaceOrientation.portrait.rawValue,
           "**两套方向枚举的左右是反的**：device 的 landscapeLeft 与 interface 的 landscapeRight 同为 3，device 的 landscapeRight 与 interface 的 landscapeLeft 同为 4（见上一行打印），而 portrait 两边都是 1 —— 「竖屏」恰好是最不容易出错的那一档。原因在物理侧：UIDeviceOrientation 说的是**设备背部朝哪个方向**，UIInterfaceOrientation 说的是**界面正过来时朝哪个方向**，设备向左横躺时界面得向右转正。写「转屏时存一下方向、下次恢复」的代码如果在这两套值之间直接赋 rawValue，横屏会被存成反向的横屏，第 21 章的布局就会整个左右颠倒。加上 faceUp/faceDown 只在前者存在（上一行的编译器原文），**任何 `rawValue` 传递都要先过一层映射函数**")
    // 头文件在 orientation 那一行写着 `this will return UIDeviceOrientationUnknown unless device
    // orientation notifications are being generated`，所以把开关真的打开再读一次（见 §14 文末）
    let g0 = dev.isGeneratingDeviceOrientationNotifications
    dev.beginGeneratingDeviceOrientationNotifications()
    let g1 = dev.isGeneratingDeviceOrientationNotifications
    pump(0.4)
    let g2 = dev.isGeneratingDeviceOrientationNotifications
    let o2 = dev.orientation.rawValue
    dev.endGeneratingDeviceOrientationNotifications()
    let g3 = dev.isGeneratingDeviceOrientationNotifications
    line("        方向通知开关四读：出厂=\(g0) begin 之后=\(g1) 泵 0.4 秒=\(g2) end 之后=\(g3)；收尾那次 orientation=\(dev.orientation.rawValue)（泵完那次=\(o2)）")
    expect(!g0 && g1 && g2 && !g3 && o2 == 0,
           "**同一个 UIDevice 上两个开关的命运恰好相反**：上一节那个电量监控开关在这台机器上写不进去，而方向通知开关**写得进去**（begin 之后 false→true，泵完还在，end 之后回到 false，四读见上一行）。但 orientation 全程是 unknown(0) —— 头文件那句 `unless device orientation notifications are being generated` 说的是**必要条件**，不是充分条件：开了开关只是让 UIKit 去订阅 HID 的转屏事件，而这个命令行进程既没有窗口也没有旋转硬件。**所以「属性读回 unknown」有两种成因（没开开关 / 开了但没数据源），要判断得先把开关状态一起读出来**，这一条正是 §1 那组「active / available / data 三个独立量」在 UIKit 侧的翻版")
    let scr = UIScreen.main
    line("  UIScreen.main：bounds=\(Int(scr.bounds.width))x\(Int(scr.bounds.height)) scale=\(f4(Double(scr.scale))) nativeScale=\(f4(Double(scr.nativeScale))) maximumFramesPerSecond=\(scr.maximumFramesPerSecond)")
    line("        brightness=\(f4(Double(scr.brightness))) traitCollection.displayScale=\(f4(Double(scr.traitCollection.displayScale))) UIScreen.screens.count=\(UIScreen.screens.count)")
    line("        两个「听起来该有」的属性在 iOS 上其实点不出来，两条编译器原文都是我刚撞的：")
    line("         scr.isMirrored               → error: value of type 'UIScreen' has no member 'isMirrored'")
    line("         scr.alternateFramesPerSecond → error: value of type 'UIScreen' has no member 'alternateFramesPerSecond'")
    line("        （mirrored* 那一组和 alternateFramesPerSecond 都是 **tvOS 侧**的 API，iOS 头文件里根本没有；")
    line("         「备选刷新率」在 iOS 上只能靠 maximumFramesPerSecond 一个数，ProMotion 的 120 就藏在这里）")
    expect(scr.scale == scr.nativeScale || scr.nativeScale > scr.scale,
           "scale 与 nativeScale 是两个不同的量（前者是「当前渲染的倍率」，后者是「面板物理倍率」），缩放渲染时 nativeScale 更大。这一行断言只锁住两者的大小关系，具体数值留给设备 —— 但**做截图/图像处理时读错这两个之一就是模糊或超大数据量的来源**，值得单独记")
    expect(scr.maximumFramesPerSecond >= 60,
           "maximumFramesPerSecond 在这台机器上是 \(scr.maximumFramesPerSecond)：ProMotion 的机器会读回 120。**这是本章唯一一个用来决定动画代码的硬件数值**（第 23 章的 CADisplayLink 每帧间隔就是它的倒数），所以判「要不要按高刷优化」应该读它，而不是写死 60")
    let pi = ProcessInfo.processInfo
    line("  ProcessInfo：thermalState=\(pi.thermalState.rawValue)（nominal=\(ProcessInfo.ThermalState.nominal.rawValue) fair=\(ProcessInfo.ThermalState.fair.rawValue) serious=\(ProcessInfo.ThermalState.serious.rawValue) critical=\(ProcessInfo.ThermalState.critical.rawValue)）isLowPowerModeEnabled=\(pi.isLowPowerModeEnabled)")
    line("        processorCount=\(pi.processorCount) activeProcessorCount=\(pi.activeProcessorCount) isiOSAppOnMac=\(pi.isiOSAppOnMac)")
    line("        operatingSystemVersion=\(pi.operatingSystemVersion.majorVersion).\(pi.operatingSystemVersion.minorVersion)（processIdentifier、processName、globallyUniqueString 三个都随进程变，**一个都不能打印**，否则 debug/release 两份输出必然不同）")
    line("        physicalMemory 大于 2GB=\(pi.physicalMemory > 2_000_000_000)（值本身不打印，跨机器不同）")
    expect(pi.thermalState == .nominal && pi.activeProcessorCount <= pi.processorCount,
           "thermalState 出厂是 nominal(0)，也就是「不烫、不降频」。**这是传感器章节和性能唯一直接相关的一条**：thermalState 到 serious/critical 时系统会降 CPU/GPU 频率并且 CoreMotion 的采样率也可能被砍，所以做连续采集的代码要在 NSProcessInfoThermalStateDidChangeNotification 里准备降级路径，而不是假设帧率恒定")
}
line("")

line("== 15) AVCaptureDevice：相机/麦克风硬件存在性，AVFoundation 的第 24 章没讲的半边 ==")
do {
    let back = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back)
    let front = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front)
    let anyVideo = AVCaptureDevice.default(for: .video)
    let mic = AVCaptureDevice.default(for: .audio)
    line("  AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back)=\(back == nil ? "nil" : "有设备")")
    line("             同上 .front=\(front == nil ? "nil" : "有设备")  AVCaptureDevice.default(for: .video)=\(anyVideo == nil ? "nil" : "有设备")  for: .audio=\(mic == nil ? "nil" : "有设备")")
    let disc = AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInWideAngleCamera, .builtInDualCamera, .builtInTrueDepthCamera], mediaType: .video, position: .unspecified)
    line("  DiscoverySession（三种机型都写上）找到 \(disc.devices.count) 台；单写宽角：\(AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInWideAngleCamera], mediaType: .video, position: .back).devices.count) 台")
    line("  授权：AVCaptureDevice.authorizationStatus(for: .video)=\(AVCaptureDevice.authorizationStatus(for: .video).rawValue)（AVAuthorizationStatus：notDetermined=\(AVAuthorizationStatus.notDetermined.rawValue) restricted=\(AVAuthorizationStatus.restricted.rawValue) denied=\(AVAuthorizationStatus.denied.rawValue) authorized=\(AVAuthorizationStatus.authorized.rawValue)）")
    expect(back == nil && front == nil && anyVideo == nil,
           "模拟器上**三个相机查询全回 nil**。这是本章第三种「硬件不存在」的表达（§1 的 false、§2 的 0 次回调、这里是 nil），也是**最容易被误用的一种**：default(...) 返回可选值，很多人直接 `if let` 进去就完事，nil 分支既不报错也不提示，用户在界面上只看到一个黑框。写相机功能的第一行应该是这个 nil 判断")
    expect(disc.devices.isEmpty,
           "DiscoverySession 是 iOS 10+ 的**推荐写法**（旧的 AVCaptureDevice.devices(for:) 早就废弃了），它返回空数组而不是 nil —— 也就是说「一台都没有」在这里是**空集合**，不是可选值。同一个问题（有没有相机）在 AVFoundation 里有两种回答形状：default 给 nil、DiscoverySession 给 []，**两种都要判**，只判一种的代码在半途迁移 API 之后就会漏")
    expect(AVCaptureDevice.authorizationStatus(for: .video) == .denied,
           "相机权限读回 **denied（2）**，和 §5/§6/§7 的 CoreMotion 一样是 denied，而 §8 的 CoreLocation 是 **notDetermined（0）** —— 三个框架两种答案，**没有一个统一的「这台机器上我到底有没有权限」查询**。逐个框架查是唯一的写法，而且三套枚举名字像、值域不同：AVFoundation 用 AVAuthorizationStatus（四档 0/1/2/3）、CoreLocation 用 CLAuthorizationStatus（五档，多了 authorizedAlways=3 / authorizedWhenInUse=4）、CoreMotion 用 CMAuthorizationStatus（四档，但顺序是 notDetermined=0 restricted=1 denied=2 authorized=3）。**写「=2 就是拒绝」这种硬编码数字的代码会在换框架时静默读错档**，一律用枚举名比较")
}
line("")

line("== 16) CLFloor 与 CLVisit：同一个「空壳」病的三种长相，以及第四种崩溃形态 signal 4 ==")
do {
    let loc = CLLocation(latitude: 31.2304, longitude: 121.4737)
    line("  手工构造的 CLLocation 上读 floor（头文件标注 nullable）：\(String(describing: loc.floor)) —— 读 nil 本身**不崩**")
    let f = CLFloor()
    let fc = f.copy()
    line("  CLFloor()：level=\(f.level)（0 档 = 头文件注释里的「ground」）")
    line("             copy() 可用=\(fc is CLFloor) copy 出来的 level=\((fc as? CLFloor)?.level ?? -999)")
    line("             isEqual：对自身=\(f.isEqual(f)) 对另一个新构造的=\(f.isEqual(CLFloor())) 对 copy=\(f.isEqual(fc))")
    line("             hash 是否相等=\(f.hash == CLFloor().hash)")
    let v = CLVisit()
    let vc = v.copy()
    line("  CLVisit()：class=\(NSStringFromClass(type(of: v))) isKind(of:)=\(v.isKind(of: CLVisit.self))")
    line("             coordinate=(\(f4(v.coordinate.latitude)),\(f4(v.coordinate.longitude))) horizontalAccuracy=\(f4(v.horizontalAccuracy))")
    line("             copy() 可用=\(vc is CLVisit) isEqual：对自身=\(v.isEqual(v)) 对另一个新构造的=\(v.isEqual(CLVisit()))")
    line("             arrivalDate / departureDate：**两个都不点，一点就崩**（探针原文在下面）")
    line("        探针实测（同一进程里只读一个日期属性）：")
    line("          let v = CLVisit(); print(v.arrivalDate)   → Child process terminated with signal 4: Illegal instruction")
    line("          let v = CLVisit(); print(v.departureDate)  → Child process terminated with signal 4: Illegal instruction")
    line("        这是本章**第四种**崩溃形态：§11 的两条是 signal 6（NSException 走 abort），§4/§10 的空壳属性是 signal 11（越界解引用），这里是 **signal 4 / Illegal instruction**。")
    line("        为什么会是 4 而不是 11，我这里只能给**推断**：ObjC 头文件在 NS_ASSUME_NONNULL_BEGIN 里把 arrivalDate 标成非可选 NSDate，")
    line("        底层没有数据时桥接层无法返回 nil，于是打陷阱指令。**实测到的只有两件事**：读它必崩、崩法是 signal 4 且 stderr 一个字都没有。")
    line("        （「没有日志」本身就是有用的线索：NSException 那两条会先打一大段 reason，裸 trap 什么都不打）")
    expect(loc.floor == nil,
           "**location.floor 在手工构造的 CLLocation 上是 nil**，而且是「老老实实的 nil」：读它不崩、`String(describing:)` 也能打。对比 §4 的 CMAttitude 和上面的 CLVisit 日期 —— 同样是「没有数据」，CLLocation 用可选值表达，CLVisit 用陷阱表达。**这个区别决定了你能不能在单元测试里自己造对象**：CLLocation 全程可测（§9），CLVisit 只能来自系统的 visit 查询")
    expect(f.level == 0 && (fc as? CLFloor)?.level == 0 && v.coordinate.latitude == 0 && v.horizontalAccuracy == 0,
           "CLFloor 和 CLVisit 是本章**唯一两个「构造出来就能读到值」的空壳对象**：level 读回 0（头文件原话 Floor 0 will always represent the floor designated as \"ground\"，所以 0 不是「未知」而是「地面层」，这就是为什么「读回 0」不能当成「没有楼层信息」），CLVisit 的 coordinate 读回 (0,0)、horizontalAccuracy 读回 0（这里 0 才真的是「没有精度信息」，和 §9 的 course/speed 用 -1 当哨兵不一样）。**同一框架里「0 是什么意思」完全按类各自约定，没有统一约定**")
    expect(f.isEqual(f) && !f.isEqual(CLFloor()) && !f.isEqual(fc) && v.isEqual(v) && !v.isEqual(CLVisit()),
           "这一条推翻了我写这一节之前的假设。我原本按 §4/§10 的样把 CLFloor、CLVisit 也写成「isEqual 对自身都 false」，跑出来是 **true** —— 也就是说这两个类**没有重写 isEqual**（纯指针语义：对自身 true，对内容相同的另一个实例 false，对自己 copy() 出来的副本也 false），而 CMAttitude（§4）、CLHeading（§10）重写并且对自身判 false。**CoreMotion 与 CoreLocation 这四个同前缀的类在「怎么算相等」上是两种答案**，没有任何一致性可依。")
    expect(f.hash != CLFloor().hash && v.hash != CLVisit().hash,
           "顺带把上一行坐实：两个 level 都是 0 的 CLFloor、两个字段都一样的 CLVisit，**hash 也不相等**（和指针语义一致）。拿这类对象做 Set 去重、当字典键、或者用 == 判断「楼层变了没」，都会得到「永远在变、永远是新元素」。头文件那句 It is not intended to match any numbering that might actually be used in the building 说的是另一层问题（楼层编号跨建筑本身不可比），**两者叠起来，CLFloor 只能当一次性数据用**")
    expect(!v.isEqual(vc) && (vc is CLVisit),
           "**「copy 之后再比」这条路在这两个类上必然判不等**（v.isEqual(vc)=false，见上面打印）—— 这是很典型的一个坑：NSObject 的 copy 语义约定「副本内容相同」，可 isEqual 用的是指针，于是 copy 一份存档、再拿原件来比，永远不等。**想造假的 visit 数据只能自己定义一个 struct**，别指望拿 CLVisit 当替身")
    line("  这三条 get-only 与「没有指定构造器」的编译器原文（都是我刚撞的）：")
    line("     f.level = 3            → error: cannot assign to property: 'level' is a get-only property")
    line("     v.arrivalDate = Date() → error: cannot assign to property: 'arrivalDate' is a get-only property")
    line("     CLFloor(level: 3)      → error: argument passed to call that takes no arguments")
    line("     （最后一条最容易误判：错误是「call takes no arguments」，也就是 CLFloor 只有无参 init，**编译器不会提示你「你传了个多余的 level」**，")
    line("      看到这条 error 很容易去找拼写，其实要找的是「根本没有这个构造器」—— 想要带楼层的位置只能从系统拿，或者自己包一层 struct）")
}
line("")

// MARK: - §17 LocalAuthentication

line("== 17) LocalAuthentication：指纹/面容/密码这道门（book 7.1），外加一条进程内惰性属性 ==")
do {
    // **顺序不能挪**：biometryType 是进程内惰性填的，本章第一次 new LAContext 必须发生在这一行
    let ctx = LAContext()
    line("  刚 new 出来就读 biometryType=\(ctx.biometryType.rawValue)")
    line("        （LABiometryType 是 1<<n 的位标：none=\(LABiometryType.none.rawValue) touchID=\(LABiometryType.touchID.rawValue) faceID=\(LABiometryType.faceID.rawValue)）")
    if #available(iOS 17.0, *) {
        line("        iOS 17 才有第四档 opticID raw=\(LABiometryType.opticID.rawValue)（本章部署目标钉 15.0，不写 #available 编译器直接拒绝，见下面原文）")
        line("          error: 'opticID' is only available in iOS 17.0 or newer")
    }
    var eDoc: NSError?
    let canDoc = ctx.canEvaluatePolicy(.deviceOwnerAuthentication, error: &eDoc)
    var eBio: NSError?
    let canBio = ctx.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &eBio)
    line("  canEvaluatePolicy(.deviceOwnerAuthentication)=\(canDoc) error=\(laErr(eDoc))")
    line("             同上 .deviceOwnerAuthenticationWithBiometrics=\(canBio) error=\(laErr(eBio))")
    line("  调过 canEvaluate 之后：同一实例 biometryType=\(ctx.biometryType.rawValue)；另一台从没调过的新实例=\(LAContext().biometryType.rawValue)")
    line("  LAPolicy raw：deviceOwnerAuthenticationWithBiometrics=\(LAPolicy.deviceOwnerAuthenticationWithBiometrics.rawValue) deviceOwnerAuthentication=\(LAPolicy.deviceOwnerAuthentication.rawValue)（**没有 0 这一档**）")
    if #available(iOS 18.0, *) {
        line("        iOS 18 又加了两档：deviceOwnerAuthenticationWithCompanion=\(LAPolicy.deviceOwnerAuthenticationWithCompanion.rawValue) …OrCompanion=\(LAPolicy.deviceOwnerAuthenticationWithBiometricsOrCompanion.rawValue)")
    }
    line("  LAErrorDomain=\(LAErrorDomain)")
    line("  错误码：authenticationFailed=\(LAError.authenticationFailed.rawValue) userCancel=\(LAError.userCancel.rawValue) userFallback=\(LAError.userFallback.rawValue) systemCancel=\(LAError.systemCancel.rawValue) passcodeNotSet=\(LAError.passcodeNotSet.rawValue)")
    line("        biometryNotAvailable=\(LAError.biometryNotAvailable.rawValue) biometryNotEnrolled=\(LAError.biometryNotEnrolled.rawValue) biometryLockout=\(LAError.biometryLockout.rawValue) appCancel=\(LAError.appCancel.rawValue) invalidContext=\(LAError.invalidContext.rawValue) notInteractive=\(LAError.notInteractive.rawValue)")
    line("  LATouchIDAuthenticationMaximumAllowableReuseDuration=\(LATouchIDAuthenticationMaximumAllowableReuseDuration)（头文件：超过这个reuse窗口就必须重新验证）")
    expect(canDoc && eDoc == nil && !canBio && eBio?.code == LAError.biometryNotEnrolled.rawValue,
           "**两档政策的答复是「一台能做、另一台不能」，而且报错的是最容易被当成 bug 的那一类**：模拟器上面朝设备的验证（deviceOwnerAuthentication，也就是含密码的那一档）canEvaluate 返回 **true 且 error 为 nil**，而纯生物特征那一档返回 **false，error=\(LAErrorDomain)#-7「Biometry is not enrolled.」**。这里的要点不是「模拟器没指纹」，而是**这个 -7 在真机上也照样会出现**：用户没录入面容/指纹时它就是 -7，录入过但当前被锁定是 -8（biometryLockout），硬件坏了才是 -6（biometryNotAvailable）。**三个码指向三种完全不同的用户提示**，只写「验证不可用，已跳过」的 App 等于把「请你先去设置里录入面容」这句该说的话咽掉了")
    expect(ctx.biometryType == .faceID && LAContext().biometryType == .faceID,
           "**biometryType 是「进程内惰性」的，不是「实例内惰性」**：本章第一个 LAContext 刚 new 出来读是 \(LABiometryType.none)（值=0），**只是调了一次 canEvaluatePolicy**，同一个实例读回 faceID(2)，而且**另一台从没被调用过的新实例也读回 2**。也就是说这个值挂在进程的首次查询上，不在对象上。这解释了真机上一类极难复现的 bug：App 启动时先建一个 LAContext、立刻读 biometryType 来决定「要不要显示指纹登录按钮」，拿到的是 none，按钮就不显示了 —— 而只要在此之前任何代码（包括 SDK 内部）调过 canEvaluatePolicy，它又会变成 faceID。**正确写法是先 canEvaluatePolicy 再读 biometryType**，或者干脆把按钮显示与否交给「验证成功之后」再决定")
    line("  出厂：localizedFallbackTitle=\(String(describing: ctx.localizedFallbackTitle)) localizedCancelTitle=\(String(describing: ctx.localizedCancelTitle)) interactionNotAllowed=\(ctx.interactionNotAllowed) touchIDAuthenticationAllowableReuseDuration=\(f4(ctx.touchIDAuthenticationAllowableReuseDuration))")
    line("        evaluatedPolicyDomainState=\(String(describing: ctx.evaluatedPolicyDomainState?.count)) isCredentialSet(.applicationPassword)=\(ctx.isCredentialSet(.applicationPassword)) isCredentialSet(.smartCardPIN)=\(ctx.isCredentialSet(.smartCardPIN))")
    line("        LACredentialType raw：applicationPassword=\(LACredentialType.applicationPassword.rawValue) smartCardPIN=\(LACredentialType.smartCardPIN.rawValue)（**第二档是负数**）")
    ctx.localizedFallbackTitle = "用密码"
    ctx.interactionNotAllowed = true
    ctx.touchIDAuthenticationAllowableReuseDuration = 5
    let fbBack = ctx.localizedFallbackTitle
    let inaBack = ctx.interactionNotAllowed
    let reuseBack = ctx.touchIDAuthenticationAllowableReuseDuration
    line("  写三个属性之后读回：fallbackTitle=\(fbBack ?? "<nil>") interactionNotAllowed=\(inaBack) reuse=\(f4(reuseBack))")
    line("  setCredential(Data(\"pw\".utf8), type: .applicationPassword) 返回=\(ctx.setCredential(Data("pw".utf8), type: .applicationPassword)) → 再读 isCredentialSet=\(ctx.isCredentialSet(.applicationPassword))")
    line("  setCredential(nil, type: .applicationPassword) 返回=\(ctx.setCredential(nil, type: .applicationPassword)) → 再读 isCredentialSet=\(ctx.isCredentialSet(.applicationPassword))")
    ctx.invalidate()
    var eDead: NSError?
    let canDead = ctx.canEvaluatePolicy(.deviceOwnerAuthentication, error: &eDead)
    let fbDead = ctx.localizedFallbackTitle
    let inaDead = ctx.interactionNotAllowed
    let reuseDead = ctx.touchIDAuthenticationAllowableReuseDuration
    line("  invalidate() 之后，**同一实例**再 canEvaluate=\(canDead) error=\(laErr(eDead))")
    line("  invalidate() 之后三个属性还读得到吗：fallbackTitle=\(fbDead ?? "<nil>") interactionNotAllowed=\(inaDead) reuse=\(f4(reuseDead))")
    expect(fbBack == "用密码" && inaBack && reuseBack == 5,
           "三个属性写得进去、当场也读得回来（**这一条我先写错才改对**：断言原本放在下面 invalidate() 之后，跑出来直接 FAIL —— 实测 invalidate() 会把三个属性**全部退回出厂值**（上面那行：fallbackTitle 变回 nil、interactionNotAllowed 变回 false、reuse 变回 0.0000），所以先把三个读回的 value 拷进局部变量、再断言拷贝值）。其中 localizedFallbackTitle 出厂是 **nil 而不是空串**（类型是 String?）：nil 表示「用系统默认那句『输入密码』」。这里有个只在真机上才咬人的规矩 —— **头文件写明：一旦这档政策在本次进程里被「用过」（开始验证），再改这个标题就无效了**，所以标题必须在 evaluatePolicy 之前设；而 interactionNotAllowed 和 reuse duration 没有这个限制，它们是每次调用现读的")
    expect(ctx.setCredential(Data("pw".utf8), type: .applicationPassword) == false && ctx.isCredentialSet(.applicationPassword) == false,
           "**setCredential 在这台机器上返回 false，且不产生任何 error**（这个方法压根没有 throws，只有一个 Bool 返回值），之后 isCredentialSet 依然 false。这一对 API（iOS 11+）的用途是「App 自己记住一份凭据，让 LAContext 在验证时带上」，headless 里没有 Keychain/安全 enclave 支撑所以必然失败。**要点在返回值**：它是 Bool 而不是 Error?，写代码时很容易 `ctx.setCredential(...)` 一句带过、把返回值丢掉，于是凭据从来没存上而程序毫无察觉 —— 这类「只有 Bool 的 API」必须显式判断，`@discardableResult` 不在这里，编译器也不会警告")
    expect(canDead == false && eDead?.code == LAError.invalidContext.rawValue,
           "**invalidate() 之后这个 LAContext 就废了**：再 canEvaluatePolicy 返回 false，错误是 invalidContext(-10)「Authentication failure.」。头文件那句 It is not necessary to call this method 特别容易读漏 —— 它说的是「释放对象不必手动调」，**不是**「调了没用」。实际语义是主动作废：正在跑的验证会被打断（见下面 §17 最后那条时序），作废之后的实例不会再恢复。**所以一个 LAContext 只该服务一次验证**，别把它做成常驻单例复用；App 从后台被拉回时如果用户已取消过一次，正是要新建实例的那个时刻")
    let c1 = LAContext()
    c1.interactionNotAllowed = true
    let r1 = LAReply(); r1.start(c1, .deviceOwnerAuthentication, reason: "探针")
    line("  interactionNotAllowed=true + deviceOwnerAuthentication：5 秒内有回复=\(r1.wait(5)) → \(r1.text)")
    let c2 = LAContext()
    c2.interactionNotAllowed = true
    let r2 = LAReply(); r2.start(c2, .deviceOwnerAuthenticationWithBiometrics, reason: "探针")
    line("  interactionNotAllowed=true + biometrics：5 秒内有回复=\(r2.wait(5)) → \(r2.text)")
    let c3 = LAContext()
    let r3 = LAReply(); r3.start(c3, .deviceOwnerAuthentication, reason: "探针")
    line("  不设 flag（出厂 false）：等 2 秒有回复=\(r3.wait(2)) 内容=\(r3.text)")
    c3.invalidate()
    line("  对同一个挂着的调用 invalidate()，再等 2 秒：有回复=\(r3.wait(2)) → \(r3.text)")
    let c4 = LAContext()
    c4.interactionNotAllowed = true
    c4.invalidate()
    let r4 = LAReply(); r4.start(c4, .deviceOwnerAuthentication, reason: "探针")
    line("  **先 invalidate 再 evaluate**：5 秒内有回复=\(r4.wait(5)) → \(r4.text)")
    expect(r1.text.contains("#\(LAError.notInteractive.rawValue)") && r2.text.contains("#\(LAError.biometryNotEnrolled.rawValue)"),
           "**interactionNotAllowed=true 是本章最有用的一个开关**：它把「需要用户在场」的验证变成一次**同步的错误答复**，两档政策的回复分别是 notInteractive(-1004) 和 biometryNotEnrolled(-7)，两次调用都在 5 秒超时之内真的回了 reply block（上面「有回复=true」）。-1004 是 LAError 里唯一的四位数，头文件给的理由是 User interaction is not allowed —— 意思是「我把界面挡住不了你，所以这次验证我不会成功」。它的价值有两层：一是**自动化测试/CI 里靠它把 LA 变成可断言的纯函数**（本章就是这么测的），二是线上代码里凡是 App 在后台、在 extension 里、在还没 root ViewController 的启动早期调验证，拿到的都是这个码 —— **看到 -1004 该改的是调用时机，不是重试验证**")
    expect(r3.wait(0) == false || r3.text == "no reply" || r3.text.contains("#\(LAError.appCancel.rawValue)"),
           "不设 flag 的那次调用**在 2 秒内没有任何回复**（上面第一行「有回复=false」），而 invalidate() 之后 reply block 才终于跑了一次，给出 appCancel(-9)「Authentication canceled.」。这两行连起来是本章关于异步 API 最重要的一条结论：**evaluatePolicy 的 reply 不是「一定会来」，而是「要么等来界面结果，要么等来取消」**。所以「在 reply 里恢复 UI 状态」「在 reply 里释放信号量/结束 loading 动画」的写法在用户压根没看到界面、或者进程被系统回收时永远等不到执行 —— **任何靠 reply 收尾的逻辑都必须自己带超时**。invalidate() 就是那个手动的收尾按钮")
    line("        两条只能靠探针复现的崩溃/挂死，本章**不执行**，原文如下：")
    line("          ctx.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: \"\") { _, _ in }")
    line("            → *** Terminating app due to uncaught exception 'NSInvalidArgumentException',")
    line("              reason: 'Non-empty localizedReason must be provided.'")
    line("            → Child process terminated with signal 6: Abort trap")
    line("          （不设 interactionNotAllowed 且不去 invalidate：reply block 一次都不执行，进程挂在那儿）")
    line("        localizedReason 是 **non-optional 的 String**，编译器不会帮你拦，空串照样传得进去，")
    line("        崩在运行时且 reason 只说 Non-empty localizedReason must be provided —— 这条约束来自系统要求「弹窗必须告诉用户为什么要验证」，")
    line("        所以传空串不是「显示得丑一点」，而是直接被拒。写一个封装 LA 的工具函数时，第一个断言应该是这个字符串非空")
    var secErr: Unmanaged<CFError>?
    let ac = SecAccessControlCreateWithFlags(kCFAllocatorDefault,
                                             kSecAttrAccessibleWhenPasscodeSetThisDeviceOnly,
                                             [.userPresence, .privateKeyUsage], &secErr)
    line("  与 Keychain 的联动：SecAccessControlCreateWithFlags(.userPresence) 返回非 nil=\(ac != nil) CFError=\(secErr == nil ? "nil" : "非 nil")")
    line("        LAAccessControlOperation raw：createItem=\(LAAccessControlOperation.createItem.rawValue) useItem=\(LAAccessControlOperation.useItem.rawValue) createKey=\(LAAccessControlOperation.createKey.rawValue)")
    line("                          useKeySign=\(LAAccessControlOperation.useKeySign.rawValue) useKeyDecrypt=\(LAAccessControlOperation.useKeyDecrypt.rawValue) useKeyKeyExchange=\(LAAccessControlOperation.useKeyKeyExchange.rawValue)")
    expect(ac != nil && secErr == nil,
           "**.userPresence 这一档访问控制对象在模拟器上造得出来**（返回非 nil、CFError 为空）。这是 book 7.1 之后 iOS 10 起的正统做法：密钥的「用之前要生物特征/密码」不是写在 App 代码里的 if，而是写进 SecAccessControl 让 Secure Enclave 强制。注意造得出来 ≠ 能用：真正取用这份密钥要走 LAContext.evaluateAccessControl(_:operation:localizedReason:reply:)，那个 API **必须有界面**，headless 下和上面一样不会回 reply，所以本章只证明「对象能构造」，不声称「密钥真的被保护住了」（见文末诚实边界）")
}
line("")

// MARK: - §18 CoreBluetooth

line("== 18) CoreBluetooth：没有蓝牙硬件时，CBCentralManager 到底在等什么（book 7.4） ==")
do {
    line("  CBManagerState raw：unknown=\(CBManagerState.unknown.rawValue) resetting=\(CBManagerState.resetting.rawValue) unsupported=\(CBManagerState.unsupported.rawValue) unauthorized=\(CBManagerState.unauthorized.rawValue) poweredOff=\(CBManagerState.poweredOff.rawValue) poweredOn=\(CBManagerState.poweredOn.rawValue)")
    line("  CBManagerAuthorization raw：notDetermined=\(CBManagerAuthorization.notDetermined.rawValue) restricted=\(CBManagerAuthorization.restricted.rawValue) denied=\(CBManagerAuthorization.denied.rawValue) allowedAlways=\(CBManagerAuthorization.allowedAlways.rawValue)")
    line("  CBErrorDomain=\(CBErrorDomain) CBATTErrorDomain=\(CBATTErrorDomain)")
    line("  CBError：unknown=\(CBError.unknown.rawValue) invalidParameters=\(CBError.invalidParameters.rawValue) notConnected=\(CBError.notConnected.rawValue) operationCancelled=\(CBError.operationCancelled.rawValue) connectionTimeout=\(CBError.connectionTimeout.rawValue) peripheralDisconnected=\(CBError.peripheralDisconnected.rawValue)")
    line("        uuidNotAllowed=\(CBError.uuidNotAllowed.rawValue) alreadyAdvertising=\(CBError.alreadyAdvertising.rawValue) unknownDevice=\(CBError.unknownDevice.rawValue) operationNotSupported=\(CBError.operationNotSupported.rawValue) encryptionTimedOut=\(CBError.encryptionTimedOut.rawValue) tooManyLEPairedDevices=\(CBError.tooManyLEPairedDevices.rawValue)")
    line("  CBATTError：success=\(CBATTError.success.rawValue) invalidHandle=\(CBATTError.invalidHandle.rawValue) readNotPermitted=\(CBATTError.readNotPermitted.rawValue) attributeNotFound=\(CBATTError.attributeNotFound.rawValue) insufficientEncryption=\(CBATTError.insufficientEncryption.rawValue) insufficientResources=\(CBATTError.insufficientResources.rawValue)")
    line("        两段错误域、码值还互相重叠（CBError.unknown=0 与 CBATTError.success=0），**只看 code 判不出是连接层错误还是 ATT 属性层错误**，必须连 domain 一起判")
    let bare = CBCentralManager()
    line("  CBCentralManager()（**不给 delegate**）刚建：state=\(bare.state.rawValue) isScanning=\(bare.isScanning)")
    let bareMoved = spinUntil(3) { bare.state != .unknown }
    line("  泵满 3 秒之后：离开 unknown 了吗=\(bareMoved) 现在 state=\(bare.state.rawValue)")
    let log = CBLog()
    let c = CBCentralManager(delegate: log, queue: nil, options: [CBCentralManagerOptionShowPowerAlertKey: false])
    line("  带 delegate/options 构造：刚建 state=\(c.state.rawValue) didUpdateState 次数=\(log.centralStates.count)")
    let moved = spinUntil(6) { c.state != .unknown }
    line("  轮询到 state 离开 unknown=\(moved)：state=\(c.state.rawValue) didUpdateState 次数=\(log.centralStates.count) 记录的 rawValue 序列=\(log.centralStates)")
    line("  CBManager.authorization（**类属性**，不属于任何实例）=\(CBManager.authorization.rawValue)")
    c.scanForPeripherals(withServices: nil, options: nil)
    line("  在非 poweredOn 状态上调 scanForPeripherals(withServices: nil)：**没崩**，isScanning=\(c.isScanning)")
    c.stopScan()
    line("  stopScan 之后 isScanning=\(c.isScanning)")
    line("  retrievePeripherals(withIdentifiers: [随机 UUID])=\(c.retrievePeripherals(withIdentifiers: [UUID()]).count) 个")
    line("  retrieveConnectedPeripherals(withServices: [180D])=\(c.retrieveConnectedPeripherals(withServices: [CBUUID(string: "180D")]).count) 个")
    line("  didDiscover 次数=\(log.discovered) willRestoreState 次数=\(log.restored)")
    let pm = CBPeripheralManager(delegate: log, queue: nil, options: [CBPeripheralManagerOptionShowPowerAlertKey: false])
    let pmMoved = spinUntil(6) { log.peripheralStates.isEmpty == false }
    line("  CBPeripheralManager：等到回调=\(pmMoved) state=\(pm.state.rawValue) didUpdateState 次数=\(log.peripheralStates.count) isAdvertising=\(pm.isAdvertising)")
    expect(bareMoved && bare.state == .unsupported && moved && c.state == .unsupported && log.centralStates == [CBManagerState.unsupported.rawValue],
           "**这一节最该记住的一条：state 是「系统异步填进来的缓存」，不是「读一下就有的属性」—— 刚建出来的 manager 无论有没有 delegate 都读回 unknown(0)**。这里我先写错过一条断言：原话是「无 delegate 的实例永远停在 unknown(0)」，跑出来 **FAIL** —— 上面那行显示不给 delegate 的那个 bare 实例泵满 3 秒后**照样走到了 unsupported(2)**。正确的分工是：系统自己会把蓝牙栈的状态查询排进队列、查完写回 state 属性；**delegate 只决定你收不收得到「写回了」这次通知，不决定状态机走不走**。于是两件事同时成立：一，「if manager.state == .poweredOn { scan() }」写在刚 new 的实例上永远不成立（这不是 bug，是必然）；二，没有 delegate 的实例并不是卡死，只是**你永远不知道它什么时候好**，只能轮询，而轮询在后台被系统唤醒时会漏掉整个窗口。第二个要点是那个终点值 **unsupported(2)**：模拟器没有蓝牙硬件，所以这里的正确答案是「这台设备不支持」，**而不是 poweredOff(4)（硬件在、只是关了）**，也不是 unauthorized(3)（权限被拒）。这三种「用不了」在 API 里是三个不同的枚举值，界面上该给的话术完全不同（装不了 / 请打开蓝牙 / 请到设置里授权），把它们合并成一个「蓝牙不可用」是 CoreBluetooth 最常见的产品级 bug")
    expect(CBManager.authorization == .allowedAlways && c.state == .unsupported,
           "**授权说 allowedAlways(3)，状态说 unsupported(2) —— 这两句互相打脸，而且两句都「没错」**。CBManager.authorization 是个类属性（写的是 `CBManager.authorization`，不属于某个 manager），它回答的是「系统给不给这个进程用蓝牙」，而 simctl spawn 出来的命令行工具不是常规 App，Info.plist 里那套 NSBluetoothAlwaysUsageDescription 检查根本没走，于是读到 allowedAlways。**这不代表真机上的 App 就有权限**，只代表这个测量环境测不出权限问题。**教训是别把一个框架的「可以」当成另一层的「可以」**：CoreBluetooth 有两道门（授权 + 硬件/开关），必须两道都读，只看 authorization 的代码在真机上会卡在 poweredOff 或 unauthorized 上，而且复现不了")
    expect(c.isScanning == false && log.discovered == 0,
           "**在不支持的适配器上调 scanForPeripherals 不抛异常、不回调 didFail、也不打日志，只是 isScanning 保持 false**（retrievePeripherals / retrieveConnectedPeripherals 同样安静地返回空数组，见上面几行，数量都是 0）。CoreBluetooth 对「现在不能扫」的表达是**静默无操作**，这和 §1 的 CoreMotion（available 返回 false，有明确的问法）、§15 的 AVFoundation（返回 nil）都不一样 —— CoreBluetooth 压根不问你支不支持，只让你调、然后什么都不发生。**所以扫描的发起方必须自己把「已经 poweredOn」当作前置条件检查**，并且别指望返回值告诉你成功与否：scanForPeripherals 的返回类型是 Void，没有任何失败通道")
    expect(pm.state == .unsupported && log.peripheralStates.count == 1 && pm.isAdvertising == false,
           "CBPeripheralManager（**当外设**那一侧，book 7.4 里「让别的设备来连我」）和中心侧完全同构：state 也是等回调才离开 unknown，模拟器上同样落到 unsupported(1 次回调)，isAdvertising 出厂 false。**两套 delegate 我合在同一个 CBLog 对象上**（它同时实现 CBCentralManagerDelegate 和 CBPeripheralManagerDelegate），实测两个 manager 各自只回调了一次 didUpdateState —— 这个计数是本章能给出的关于「状态回调会不会重复派发」的证据：一次，不是每次读属性都回调")
    line("  三条常量/开关的实际含义：CBCentralManagerOptionShowPowerAlertKey=\(CBCentralManagerOptionShowPowerAlertKey)（设 false 就是不让系统弹「打开蓝牙」那个框，本章传的就是 false）")
    line("        CBPeripheralManagerOptionShowPowerAlertKey=\(CBPeripheralManagerOptionShowPowerAlertKey) CBConnectPeripheralOptionNotifyOnDisconnectionKey=\(CBConnectPeripheralOptionNotifyOnDisconnectionKey)")
    line("  广播包字段键名：LocalName=\(CBAdvertisementDataLocalNameKey) ManufacturerData=\(CBAdvertisementDataManufacturerDataKey) IsConnectable=\(CBAdvertisementDataIsConnectable) ServiceUUIDs=\(CBAdvertisementDataServiceUUIDsKey)")
    line("        注意键名的裸字符串是 kCBAdvData… 而 Swift 常量名是 CBAdvertisementData…，**两者不一致**，写死字符串的字典键在这两个前缀之间最容易打错")
}
line("")

line("== 18b) CBUUID 与特征定义：短 ID 的换算、OptionSet 位值、构造 GATT 服务 ==")
do {
    let short = CBUUID(string: "180D")
    let full = CBUUID(string: "0000180D-0000-1000-8000-00805F9B34FB")
    line("  CBUUID(string: \"180D\").uuidString=\(short.uuidString) data.count=\(short.data.count)")
    line("  CBUUID(string: 全写).uuidString=\(full.uuidString) data.count=\(full.data.count)")
    line("  两者 ==(Equatable)=\(short == full) hash 相等=\(short.hash == full.hash) description=\(short.description)")
    line("  小写输入造出来的 uuidString=\(CBUUID(string: "180d").uuidString) 四位新 ID 2B37 的 data.count=\(CBUUID(string: "2B37").data.count)")
    line("  CBUUID(data: 全写的 data).uuidString=\(CBUUID(data: full.data).uuidString) 与全写相等=\(CBUUID(data: full.data) == full)")
    let props: CBCharacteristicProperties = [.read, .notify]
    line("  CBCharacteristicProperties 位值：broadcast=\(CBCharacteristicProperties.broadcast.rawValue) read=\(CBCharacteristicProperties.read.rawValue) writeWithoutResponse=\(CBCharacteristicProperties.writeWithoutResponse.rawValue) write=\(CBCharacteristicProperties.write.rawValue) notify=\(CBCharacteristicProperties.notify.rawValue) indicate=\(CBCharacteristicProperties.indicate.rawValue)")
    line("  [.read, .notify] 的 rawValue=\(props.rawValue) 含 write=\(props.contains(.write)) 空集 rawValue=\(CBCharacteristicProperties().rawValue)")
    line("  描述符的固定 UUID 常量：CBUUIDCharacteristicExtendedPropertiesString=\(CBUUIDCharacteristicExtendedPropertiesString) CBUUIDClientCharacteristicConfigurationString=\(CBUUIDClientCharacteristicConfigurationString)")
    let svc = CBMutableService(type: short, primary: true)
    line("  CBMutableService(type:primary:)：uuid=\(svc.uuid.uuidString) isPrimary=\(svc.isPrimary) characteristics=\(svc.characteristics?.count ?? -1)（-1 表示 nil）")
    let ch = CBMutableCharacteristic(type: CBUUID(string: "2A37"), properties: [.read], value: nil, permissions: .readEncryptionRequired)
    line("  CBMutableCharacteristic：uuid=\(ch.uuid.uuidString) properties raw=\(ch.properties.rawValue) value=\(ch.value == nil ? "nil" : "有数据") service=\(ch.service == nil ? "nil（还没加进任何 CBService）" : "已挂上")")
    line("  CBAttributePermissions raw：readable=\(CBAttributePermissions.readable.rawValue) writeable=\(CBAttributePermissions.writeable.rawValue) readEncryptionRequired=\(CBAttributePermissions.readEncryptionRequired.rawValue) writeEncryptionRequired=\(CBAttributePermissions.writeEncryptionRequired.rawValue)")
    expect(short == full && short.data.count == 2 && full.data.count == 16 && short.hash == full.hash,
           "**同一个蓝牙服务的两种写法是相等的，但内部表示完全不同**：16 位简写 \"180D\" 存成 2 个字节，128 位全写存成 16 个字节，== 与 hash 都判等（description 还会打出人类可读的 **Heart Rate**）。这是 BLE 编程里一个纯约定：0x0000–0xFFFF 的短 ID 隐含在基址 0000xxxx-0000-1000-8000-00805F9B34FB 里，**CoreBluetooth 替你做这个展开**。它带来的坑是「过滤条件对不上」：如果你把服务的 128 位 UUID 传进 scanForPeripherals(withServices:)，而设备广播的是 16 位简写（绝大多数标准服务都这样），只要两者确实展开成同一个 UUID 就能匹配 —— 但**自定义服务用非标准 128 位时，简写写法会直接被拒**（见下面那条崩溃）。反过来讲，判等设备/服务一律用 == 是安全的，别拿 data.count 或 uuidString 自己拼字符串比较")
    expect(CBUUID(string: "180d").uuidString == "180D" && CBUUID(data: full.data) == full,
           "uuidString **总是大写**返回，且 CBUUID(data:) 与 CBUUID(string:) 互为往返。**别把 CBUUID 当字符串存**：小写、带花括号、半截 128 位这几种写法在字符串比较下都不相等，而在 CBUUID 眼里有的合法有的直接崩（下面那组探针原文）。存档时存 uuidString，读取时一律 CBUUID(string:) 规范化，比较时交给 ==")
    expect(props.rawValue == 18 && !props.contains(.write) && CBCharacteristicProperties().rawValue == 0,
           "特征属性是**位标（OptionSet）**，read(2)|notify(16)=18，而**空集是 0，不是「什么都没有的那一档」**：CBMutableCharacteristic(properties: [], …) 造得出来，但它是一个谁都不能读谁都不能写的死特征。这里有一处只能靠背的换算：**write=8 而 writeWithoutResponse=4**（数值顺序和名字顺序相反），写 `properties.rawValue == 4` 表示「可写」的代码是把无响应写当成了普通写。**永远用 OptionSet 字面量 `[.writeWithoutResponse]`，不要写数字**；indicate(32) 与 notify(16) 的区别（要不要 ACK）在 headless 里没有任何可测信号，只能靠读文档")
    expect(svc.characteristics == nil && ch.value == nil && ch.service == nil,
           "**CBMutableService.characteristics 出厂是 nil 而不是空数组**（上面打印 nil），CBMutableCharacteristic 的 value 出厂也是 nil，permissions 用的是**另一套**位标 CBAttributePermissions（readEncryptionRequired=4，注意它和 CBCharacteristicProperties.writeWithoutResponse=4 **数值相同、含义无关**）。这三条叠起来的意思是：GATT 服务表必须自己组装并**整体赋值**（svc.characteristics = [ch]），而且组装时没有任何一处 API 会校验「properties 里有 read 而 permissions 里没 readable」这种自相矛盾的配置 —— **对不上时系统在真正被访问时才报错**，本地构造阶段一声不响")
    line("  CBPeer / CBAttribute 的构造边界（编译器与头文件原文）：")
    line("    CBPeer()            → 头文件标 NS_UNAVAILABLE；这个类只能由系统给你，不能自己造")
    line("    CBPeer 只有一个可见属性 identifier（类型 UUID），**值是进程相关的，本章一个都不打印**")
    line("  CBUUID 非法输入的唯一下场是崩溃（探针原文，本章**不执行**）：")
    line("    CBUUID(string: \"zz\")                              → NSInternalInconsistencyException,")
    line("      reason: 'String zz does not represent a valid UUID' → signal 6: Abort trap")
    line("    CBUUID(string: \"\") / \"180\" / \"0000180D-0000-1000-8000\" / \"{…34FB}\"  → 全部同样的崩法")
    line("    （reason 里会把原串原样打回去：'String <你传的> does not represent a valid UUID'）")
    expect(true,
           "**CBUUID(string:) 是 CoreBluetooth 里唯一一个「传错就当场 abort」的入口**，合法形状只有三种：4 位 hex、32 位 hex、标准 8-4-4-4-12 全写（大小写都行）。空串、奇数长度 hex、半截的 128 位、带花括号全都崩，而且**它是 ObjC 层的 NSException，不是 Swift 可捕获的 error，也不是返回 nil** —— 你从函数签名 `init(string: String)` 上看不出任何危险。所以凡是从数据库、配置文件、用户输入里拿出来的 UUID 字符串，进 CBUUID 之前必须自己校验形状（长度 4/32/36），否则一个脏数据就是闪退，而不是一个可以提示的错误")
}
line("")

// MARK: - §19 MapKit 的纯数学

line("== 19) MapKit 第一半：墨卡托投影的纯数学（book 7.5）—— 本章唯一不依赖网络也不依赖硬件的地图代码 ==")
do {
    let world = MKMapRect.world
    let origin = MKMapPoint(CLLocationCoordinate2DMake(0, 0))
    line("  MKMapRect.world：origin=(\(f4(world.origin.x)),\(f4(world.origin.y))) size=\(f4(world.size.width))x\(f4(world.size.height)) 正方=\(world.size.width == world.size.height) isEmpty=\(world.isEmpty) isNull=\(world.isNull) maxX=\(f4(world.maxX)) midX=\(f4(world.midX))")
    line("  MKMapRect.null：isNull=\(MKMapRect.null.isNull) isEmpty=\(MKMapRect.null.isEmpty) width=\(f4(MKMapRect.null.width)) 与 world 相交=\(MKMapRect.null.intersects(world))")
    line("  MKMapPoint(经纬度)：(0,0)=(\(f4(origin.x)),\(f4(origin.y))) 反读 8 位=\(String(format: "%.8f", origin.coordinate.latitude))")
    line("        (90,0).y=\(f4(MKMapPoint(CLLocationCoordinate2DMake(90, 0)).y)) (-90,0).y=\(f4(MKMapPoint(CLLocationCoordinate2DMake(-90, 0)).y))")
    line("        (0,180).x=\(f4(MKMapPoint(CLLocationCoordinate2DMake(0, 180)).x)) (0,-180).x=\(f4(MKMapPoint(CLLocationCoordinate2DMake(0, -180)).x))")
    let bj = MKMapPoint(CLLocationCoordinate2DMake(39.9042, 116.4074))
    let sh = MKMapPoint(CLLocationCoordinate2DMake(31.2304, 121.4737))
    let dmp = bj.distance(to: sh)
    let dcl = CLLocation(latitude: 39.9042, longitude: 116.4074).distance(from: CLLocation(latitude: 31.2304, longitude: 121.4737))
    line("  北京=(\(f4(bj.x)),\(f4(bj.y))) 上海=(\(f4(sh.x)),\(f4(sh.y)))")
    line("  北京→上海：MKMapPoint.distance(to:)=\(f4(dmp)) 米；CLLocation.distance(from:)（§9 的测地线）=\(f4(dcl)) 米；两者之差=\(f4(dmp - dcl)) 米")
    line("  MKMetersPerMapPointAtLatitude（**这个 C 函数在 Swift 里独独没改名**，其余全被换成了 init/属性/方法）：0°=\(f4(MKMetersPerMapPointAtLatitude(0.0))) 45°=\(f4(MKMetersPerMapPointAtLatitude(45.0))) 60°=\(f4(MKMetersPerMapPointAtLatitude(60.0))) 84°=\(f4(MKMetersPerMapPointAtLatitude(84.0))) 85°=\(f4(MKMetersPerMapPointAtLatitude(85.0)))")
    for lat in [85.0, 85.0001, 85.05, 85.0511, 86.0, 89.0, 90.0] {
        let mp = MKMapPoint(CLLocationCoordinate2DMake(lat, 0))
        line("        lat=\(String(format: "%.4f", lat)) → y=\(f4(mp.y)) 反读 lat=\(String(format: "%.4f", mp.coordinate.latitude)) metersPerMapPoint=\(f4(MKMetersPerMapPointAtLatitude(lat))) isFinite=\(MKMetersPerMapPointAtLatitude(lat).isFinite)")
    }
    line("        负侧：lat=-85 → y=\(f4(MKMapPoint(CLLocationCoordinate2DMake(-85.0, 0)).y)) mPerPt=\(f4(MKMetersPerMapPointAtLatitude(-85.0)))；lat=-90 → y=\(f4(MKMapPoint(CLLocationCoordinate2DMake(-90.0, 0)).y)) mPerPt=\(f4(MKMetersPerMapPointAtLatitude(-90.0)))")
    line("  反读世界边缘：MKMapPoint(x:0,y:0).coordinate.latitude=\(String(format: "%.8f", MKMapPoint(x: 0, y: 0).coordinate.latitude))，MKMapPoint(x:0,y=world.maxY) 的=\(String(format: "%.8f", MKMapPoint(x: 0, y: world.maxY).coordinate.latitude))")
    line("  经度越界：lon=190 → x=\(String(format: "%.8f", MKMapPoint(CLLocationCoordinate2DMake(0, 190)).x))；lon=-190 → x=\(String(format: "%.8f", MKMapPoint(CLLocationCoordinate2DMake(0, -190)).x))；反读那个点的经度=\(String(format: "%.8f", MKMapPoint(CLLocationCoordinate2DMake(0, 190)).coordinate.longitude))")
    expect(origin.x == world.size.width / 2 && origin.y == world.size.height / 2 && world.size.width == world.size.height && world.maxX == world.size.width,
           "**world 是一个 268435456x268435456 的正方形，(0,0) 经纬度落在正中心**，maxX/midX 这些派生属性都是普通算式。MapKit 的「地图坐标」就是这么一套**与屏幕无关、与世界宽度绑定的浮点平面**：2^28 个格子摊满整个赤道周长，所以格子本身没有物理意义，**必须靠 MKMetersPerMapPointAtLatitude 才能换算成米**（下面那条）。另外这里有个必须交代的过程：我原本想用 `MKMapPoint == MKMapPoint` 写这条断言，**编译器直接拒绝**（MKMapPoint 不 conform Equatable，原文在本节末尾的编译器清单里），只能逐分量比 —— 结构体「看着该能比」不等于真能比")
    expect(dmp > dcl && dmp - dcl > 300 && dmp - dcl < 500,
           "**同一个「北京到上海」，两条 API 给出两个数**：MKMapPoint.distance(to:) = \(f4(dmp)) 米，CLLocation.distance(from:) = \(f4(dcl)) 米，差 \(f4(dmp - dcl)) 米（约 0.04%）。差的来源不是精度抖动而是**投影**：MapKit 算的是墨卡托平面直线，墨卡托在高纬被纵向拉伸，两点跨纬度时平面距离必然大于椭球面距离；CLLocation 走大地测量线。**406 米听着不大，但「两个都叫 distance 的 API 结果不同」这件事本身值得进 code review 检查表**：同一份需求里算里程用 CLLocation、算覆盖半径用 MKMapPoint，两套数对账时必然打架，且没人觉得自己写错了")
    expect(MKMapPoint(CLLocationCoordinate2DMake(86, 0)).y == MKMapPoint(CLLocationCoordinate2DMake(90, 0)).y
           && MKMapPoint(CLLocationCoordinate2DMake(85.0, 0)).y == MKMapPoint(CLLocationCoordinate2DMake(85.0511, 0)).y
           && abs(MKMapPoint(CLLocationCoordinate2DMake(85.05, 0)).coordinate.latitude - 85.0) < 0.0001,
           "**MapKit 把纬度夹在 ±85.0，而墨卡托的数学极限是 ±85.05112878 —— 两个数不一样，而且分方向**：lat=85.0001、85.05、85.0511、86、90 造出来的 MKMapPoint，**y 全部等于 lat=85.0 那一格的 439674.4025**（上面七行打印的 y 一模一样，断言用的是 bit 级相等），拿它反读经纬度得到 **85.0000** 而不是 90。反过来读世界顶部那一格才拿到真正的投影极限 85.05112878。**工程后果有两条**：一是「把任意纬度画到地图上」时 85.1°N 和 90°N 落在同一个点，二是**存 MKMapPoint 再还原经纬度是有损的**（90° 存进去出来变 85°）。§9 已经证明 CLLocationCoordinate2DIsValid 对 (95,116) 判 false，但 MKMapPoint 的构造**不校验、不报错、不打日志**，合法性得自己把关")
    expect(MKMetersPerMapPointAtLatitude(0.0) > MKMetersPerMapPointAtLatitude(45.0)
           && MKMetersPerMapPointAtLatitude(45.0) > MKMetersPerMapPointAtLatitude(60.0)
           && MKMetersPerMapPointAtLatitude(60.0) > MKMetersPerMapPointAtLatitude(84.0)
           && MKMetersPerMapPointAtLatitude(84.0) < MKMetersPerMapPointAtLatitude(85.0),
           "**「一个地图点等于多少米」必须问这个函数，不能按 111km/度 自己算**：实测 0°=\(f4(MKMetersPerMapPointAtLatitude(0.0)))、45°=\(f4(MKMetersPerMapPointAtLatitude(45.0)))、60°=\(f4(MKMetersPerMapPointAtLatitude(60.0))) 米/点，**趋势**是随纬度按 cos 缩小（0.1483·cos45°≈0.1049、·cos60°≈0.0742），但**别把它当精确的 cos 倍数** —— §20b 那里实测赤道/北京两档比例尺之比 \(f4(MKMetersPerMapPointAtLatitude(0) / MKMetersPerMapPointAtLatitude(39.9042)))，而 1/cos(39.9042)=\(f4(1.0 / cos(39.9042 * .pi / 180)))，差 0.4%。也就是说**地图点是「角度格子」而不是「米格」**，画一个 500 米的圆必须在当前纬度下问这个函数换算；自己写死系数的代码搬到奥斯陆会画出两倍大的圆，而写了 `* cos(lat)` 近似的代码会在中高纬积累出几百米的偏差")
    expect(MKMetersPerMapPointAtLatitude(86.0).isFinite == false
           && MKMetersPerMapPointAtLatitude(89.0).isFinite == false
           && MKMetersPerMapPointAtLatitude(90.0).isFinite
           && MKMetersPerMapPointAtLatitude(-90.0).isFinite
           && MKMetersPerMapPointAtLatitude(90.0) != MKMetersPerMapPointAtLatitude(-90.0),
           "**过了 85° 之后这个函数给 inf，而到了 ±90° 又变回有限值、两侧还不对称**：实测 86°=inf、89°=inf、+90°=\(f4(MKMetersPerMapPointAtLatitude(90.0)))、-90°=\(f4(MKMetersPerMapPointAtLatitude(-90.0)))（见上面 isFinite 那一列）。**机理我给不出结论，这里只报实测**：唯一能确定的是它在 85° 以上不再单调，84° 的返回值甚至比 85° 小。可执行的结论只有一条：**拿它当乘数/除数之前先判 .isFinite**，否则极地航线、科考、世界地图缩放到顶时，一个 inf 会顺着乘法把 boundingMapRect 变成 inf，再往下传就是「数据在、图上什么都没有」的空白地图 —— 不崩，所以最难查")
    expect(MKMapPoint(CLLocationCoordinate2DMake(0, 190)).x == MKMapPoint(CLLocationCoordinate2DMake(0, -190)).x
           && MKMapPoint(CLLocationCoordinate2DMake(0, 190)).x < 0,
           "**经度越界既不夹紧也不绕回整圈，而是落到世界外一格，并且 +190 与 -190 得到同一个 x=-1.0**（上面打印的两个数完全相同），反读该点的经度得到 179.99999866。**两个明显不同的非法输入映射到同一个地图点**，意味着拿 MKMapPoint 当缓存键、去重依据、或者 diff 基准的代码会把两条不同数据判成同一条。结论和上一节呼应：**进 MapKit 之前自己过一遍 CLLocationCoordinate2DIsValid（§9），MapKit 不会替你做**")
}
line("")

line("== 19b) MKMapRect 的集合运算，以及两个「反直觉的矩形」 ==")
do {
    let bj = MKMapPoint(CLLocationCoordinate2DMake(39.9042, 116.4074))
    let r1 = MKMapRect(x: bj.x, y: bj.y, width: 1000, height: 1000)
    let r2 = MKMapRect(x: bj.x + 500, y: bj.y + 500, width: 1000, height: 1000)
    let uni = r1.union(r2)
    line("  r1 原点=(\(f4(r1.origin.x)),\(f4(r1.origin.y))) 尺寸 1000x1000；r2 向右下各偏移 500")
    line("  union origin=(\(f4(uni.origin.x)),\(f4(uni.origin.y))) size=\(f4(uni.size.width))x\(f4(uni.size.height))")
    line("  intersection 宽=\(f4(r1.intersection(r2).size.width)) intersects=\(r1.intersects(r2)) contains(内点)=\(r1.contains(MKMapPoint(x: bj.x + 10, y: bj.y + 10))) contains(r2)=\(r1.contains(r2))")
    line("  insetBy(dx:10,dy:20)=\(f4(r1.insetBy(dx: 10, dy: 20).size.width))x\(f4(r1.insetBy(dx: 10, dy: 20).size.height)) offsetBy(dx:5,dy:5).origin.x=\(f4(r1.offsetBy(dx: 5, dy: 5).origin.x))")
    let zero = MKMapRect(x: 0, y: 0, width: 0, height: 0)
    let neg = MKMapRect(x: 100, y: 100, width: -50, height: -50)
    line("  零尺寸 rect：isEmpty=\(zero.isEmpty) isNull=\(zero.isNull)")
    line("  负宽高 rect(origin 100,100 宽高 -50)：width=\(f4(neg.width)) maxX=\(f4(neg.maxX)) midX=\(f4(neg.midX))")
    line("        isEmpty=\(neg.isEmpty) isNull=\(neg.isNull) intersects(自身)=\(neg.intersects(neg)) contains(自己的 origin)=\(neg.contains(MKMapPoint(x: 100, y: 100)))")
    let inf = MKMapRect(x: 0, y: 0, width: .infinity, height: .infinity)
    line("  无限大 rect：isNull=\(inf.isNull) isEmpty=\(inf.isEmpty) width.isFinite=\(inf.size.width.isFinite) spans180thMeridian=\(inf.spans180thMeridian)")
    let wide = MKMapRect(x: -100, y: 0, width: MKMapRect.world.size.width + 200, height: 100)
    line("  比 world 还宽的 rect：spans180thMeridian=\(wide.spans180thMeridian) remainder.origin.x=\(f4(wide.remainder.origin.x)) remainder.width=\(f4(wide.remainder.size.width))；普通 rect 的 spans180thMeridian=\(r1.spans180thMeridian)")
    expect(zero.isEmpty && !zero.isNull && !neg.isEmpty && !neg.isNull,
           "**isEmpty 只对「宽高都是 0」为 true，对负宽高是 false**：MKMapRect 没有「非法矩形」这一档（isNull 只对 MKMapRect.null 成立）。所以 `if rect.isEmpty { return }` 这种防御写法挡不住负尺寸 —— 而负尺寸太好造了：`MKMapRect(x: a.x, y: b.y, width: b.x - a.x, height: a.y - b.y)` 里 min/max 写反就是一个负矩形，**编译器一声不响**")
    expect(!neg.intersects(neg) && !neg.contains(MKMapPoint(x: 100, y: 100)),
           "**负宽高矩形连自己都不相交、也不包含自己的原点**（实测 intersects(自身)=false、contains(origin)=false，而它的 origin 就摆在那儿；maxX=50 比 origin.x=100 小，见上面打印）。这是本节最狠的一个坑：`rect.intersects(mapView.visibleMapRect)` 是「这个覆盖物要不要画」的标准裁剪判断，负矩形在这里被判成「与什么都无关」，于是**数据在图层里、地图上看不见、也没有任何错误**。凡是外部数据（数据库、GeoJSON、服务端）来的 rect，构造完第一件事是断言 width>=0 && height>=0")
    expect(inf.isNull == false && inf.isEmpty == false && inf.spans180thMeridian && wide.spans180thMeridian && !wide.remainder.isNull,
           "**无限宽矩形在 MKMapRect 里是合法的（isNull=false、isEmpty=false）**；`spans180thMeridian` 表达的是「这个矩形横向超出了世界边界」，也就是跨过 180° 经线的信号，配套的 `remainder` 把它收回世界内（上面那个比 world 宽 200 的矩形，remainder 宽=\(f4(wide.remainder.size.width))、origin.x=\(f4(wide.remainder.origin.x))）。**这是 MapKit 处理日期变更线的唯一机制**：画跨 180° 的东西（太平洋航线、跨经度围栏）拿到的矩形 spans180thMeridian=true，直接用会被裁掉，必须先取 remainder 再分段画。注意普通矩形（r1）该标志是 false，**别把它当「矩形有效」的判断**")
    line("  本节撞到的编译器原文（这些都是我以为存在、实际已被 Swift 改名或删掉的东西）：")
    line("    MKMapPointForCoordinate(coord)        → error: 'MKMapPointForCoordinate' has been replaced by 'MKMapPoint.init(_:)'")
    line("      （note: 'MKMapPointForCoordinate' was obsoleted in Swift 3）")
    line("    MKCoordinateForMapPoint(mp)           → error: has been replaced by property 'MKMapPoint.coordinate'")
    line("    MKCoordinateRegionMakeWithDistance(c, lat, lon) → error: has been replaced by 'MKCoordinateRegion.init(center:latitudinalMeters:longitudinalMeters:)'")
    line("    MKMetersBetweenMapPoints(a, b)        → 换成 a.distance(to: b)")
    line("    MKMapRectWorld / MKMapRectNull        → 换成 MKMapRect.world / MKMapRect.null")
    line("    mp1 == mp2                            → error: referencing operator function '==' on 'Equatable' requires that 'MKMapPoint' conform to 'Equatable'")
    line("    （**只有 MKMetersPerMapPointAtLatitude 保留着 C 函数原名**，整个 MapKit 就它没被改，写的时候最容易漏掉 _AtLatitude 那截）")
}
line("")

line("== 19c) MKCoordinateRegion：米与度之间的换算，以及它对非法输入的全程沉默 ==")
do {
    let r399 = MKCoordinateRegion(center: CLLocationCoordinate2DMake(39.9042, 116.4074),
                                  latitudinalMeters: 2000, longitudinalMeters: 2000)
    let req = MKCoordinateRegion(center: CLLocationCoordinate2DMake(0, 0),
                                 latitudinalMeters: 2000, longitudinalMeters: 2000)
    line("  MKCoordinateRegion(center:latitudinalMeters:longitudinalMeters:) 中心 39.9°N：latDelta=\(f4(r399.span.latitudeDelta)) lonDelta=\(f4(r399.span.longitudeDelta))")
    line("        同样 2000 米在赤道：latDelta=\(f4(req.span.latitudeDelta)) lonDelta=\(f4(req.span.longitudeDelta))")
    line("  region 只有 center+span 两个字段：中心 lat=\(f4(r399.center.latitude)) span=\(f4(r399.span.latitudeDelta))x\(f4(r399.span.longitudeDelta))")
    let bad = MKCoordinateRegion(center: CLLocationCoordinate2DMake(95, 0),
                                 span: MKCoordinateSpan(latitudeDelta: 1, longitudeDelta: 1))
    line("  用 lat=95 造 region：中心照收=\(f4(bad.center.latitude)) span latDelta=\(f4(bad.span.latitudeDelta))（**构造不报错、不夹紧、不打日志**）")
    let negSpan = MKCoordinateRegion(center: CLLocationCoordinate2DMake(31.2304, 121.4737),
                                     span: MKCoordinateSpan(latitudeDelta: -1, longitudeDelta: 1))
    let zeroSpan = MKCoordinateRegion(center: CLLocationCoordinate2DMake(0, 0),
                                      span: MKCoordinateSpan(latitudeDelta: 0, longitudeDelta: 0))
    line("  负 latitudeDelta 读回=\(f4(negSpan.span.latitudeDelta))（同样不夹紧）；零 span 读回=\(f4(zeroSpan.span.latitudeDelta))x\(f4(zeroSpan.span.longitudeDelta))")
    expect(abs(r399.span.latitudeDelta - req.span.latitudeDelta) < 0.0005 && r399.span.longitudeDelta > req.span.longitudeDelta,
           "**同样 2000 米，纬度张角几乎不随位置变（赤道 \(f4(req.span.latitudeDelta)) vs 39.9°N \(f4(r399.span.latitudeDelta))），经度张角却差出一截**（\(f4(r399.span.longitudeDelta)) vs \(f4(req.span.longitudeDelta))，比值就是 1/cos(39.9°)）。因为 **region 不是圆，是球面上的矩形**，度和米之间没有全局换算系数。写「以当前位置为中心 2 公里视野」应当用这个 latitudinalMeters/longitudinalMeters 构造器（它替你按纬度算好了），而不是手填 span；手填 span 的代码搬到高纬度城市，视野会莫名地变大变小")
    expect(bad.center.latitude == 95 && negSpan.span.latitudeDelta == -1 && zeroSpan.span.latitudeDelta == 0,
           "**MKCoordinateRegion / MKCoordinateSpan 是纯 struct，构造时不做任何校验**：lat=95 照收、负 delta 照收、零 delta 照收，读回来就是原值（对照 19 节 MKMapPoint 会夹到 85.0 —— **同一个框架里两种完全不同的处理方式**）。所以 region 的合法性没人代劳：喂给 MKMapView.setRegion、MKMapSnapshotter.Options.region、MKCoordinateRegion 之间转换之前，得自己过 §9 的 CLLocationCoordinate2DIsValid 并判 span>0。**这类 struct 的「构造成功」不代表「值能用」**，MapKit 的静默失败基本都从这里开始")
}
line("")

// MARK: - §20 MapKit 的对象、视图与解码器

line("== 20) MapKit 的对象、标注视图与渲染器（MKMapView 那段只能引探针原文：一碰它就脏 stderr） ==")
do {
    let ann = MKPointAnnotation()
    ann.coordinate = CLLocationCoordinate2DMake(31.2304, 121.4737)
    ann.title = "外滩"
    ann.subtitle = "副标题"
    line("  MKPointAnnotation：title=\(ann.title ?? "<nil>") subtitle=\(ann.subtitle ?? "<nil>") coord=(\(f4(ann.coordinate.latitude)),\(f4(ann.coordinate.longitude)))")
    let pl = MKPlacemark(coordinate: CLLocationCoordinate2DMake(39.9042, 116.4074))
    let item = MKMapItem(placemark: pl)
    item.name = "探针"
    line("  MKPlacemark(coordinate:)：lat=\(f4(pl.coordinate.latitude)) locality=\(String(describing: pl.locality)) thoroughfare=\(String(describing: pl.thoroughfare)) postalCode=\(String(describing: pl.postalCode)) administrativeArea=\(String(describing: pl.administrativeArea)) country=\(String(describing: pl.country))")
    line("  MKMapItem(placemark:)：name=\(item.name ?? "<nil>") isCurrentLocation=\(item.isCurrentLocation) placemark lat=\(f4(item.placemark.coordinate.latitude))")
    let cur = MKMapItem.forCurrentLocation()
    line("  MKMapItem.forCurrentLocation()：isCurrentLocation=\(cur.isCurrentLocation) coord=(\(f4(cur.placemark.coordinate.latitude)),\(f4(cur.placemark.coordinate.longitude)))（**没定位也是 (0,0)，不是 nil**）")
    // 标注视图与渲染器都能脱离 MKMapView 单独构造，所以下面这些是本章实测；
    // MKMapView 本身一被构造就往 stderr 写一条 Metal 日志（原文见后面探针段），而 harness 判定 3 要求 stderr 为空，
    // 因此本章**不执行** MKMapView，只引用探针 p25mv2 的实测原文。
    let mkv = MKMarkerAnnotationView()
    let glyphBefore = mkv.glyphText
    mkv.glyphText = "P"
    let glyphBack = mkv.glyphText
    let av = MKAnnotationView(frame: CGRect(x: 0, y: 0, width: 20, height: 20))
    line("  MKMarkerAnnotationView()（**不挂到任何 MKMapView 上**）：frame=\(f4(Double(mkv.frame.width)))x\(f4(Double(mkv.frame.height))) glyphText 出厂=\(glyphBefore ?? "<nil>")（写过之后=\(glyphBack ?? "<nil>")）canShowCallout=\(mkv.canShowCallout) markerTintColor 非 nil=\(mkv.markerTintColor != nil) glyphImage 非 nil=\(mkv.glyphImage != nil)")
    line("  MKAnnotationView(frame: 20x20)：canShowCallout=\(av.canShowCallout) isEnabled=\(av.isEnabled) isDraggable=\(av.isDraggable)（**MKMarkerAnnotationView 的父类**，出厂同样不带气泡）")
    let poly20 = MKPolyline(coordinates: [CLLocationCoordinate2DMake(0, 0), CLLocationCoordinate2DMake(0, 1)], count: 2)
    let circ20 = MKCircle(center: CLLocationCoordinate2DMake(39.9042, 116.4074), radius: 1000)
    let pr = MKPolylineRenderer(polyline: poly20)
    let cr = MKCircleRenderer(circle: circ20)
    let prLine0 = pr.lineWidth
    let prAlpha0 = pr.alpha
    let prStrokeNil0 = pr.strokeColor == nil
    let crLine0 = cr.lineWidth
    let crStrokeNil0 = cr.strokeColor == nil
    let crFillNil0 = cr.fillColor == nil
    line("  MKPolylineRenderer(polyline:)：overlay 同一对象=\(pr.overlay === poly20) lineWidth=\(f4(prLine0)) alpha=\(f4(prAlpha0)) strokeColor 非 nil=\(!prStrokeNil0)")
    line("  MKCircleRenderer(circle:)：overlay 同一对象=\(cr.overlay === circ20) lineWidth=\(f4(crLine0)) strokeColor 非 nil=\(!crStrokeNil0) fillColor 非 nil=\(!crFillNil0)")
    cr.lineWidth = 4
    pr.strokeColor = UIColor.systemBlue
    line("  写值之后再读：cr.lineWidth=\(f4(cr.lineWidth)) pr.strokeColor 非 nil=\(pr.strokeColor != nil)")
    line("  下面这段 MKMapView 的数是探针 p25mv2 在模拟器上实测的**原文**，本章**不执行**这些代码：")
    line("    2026-09-29 08:33:17.482 p25mv2[6378:3865740] CAMetalLayer ignoring invalid setDrawableSize width=0.000000 height=0.000000")
    line("          ↑ 这就是不执行的原因：只写一句 `MKMapView(frame:)`、后面什么都不做，stderr 就已经有 120 字节；")
    line("            再加上 selectAnnotation 那一步涨到 227 字节。harness 判定 3 要求 stderr 为空，所以整个 MKMapView 面只能以探针原文进书。")
    line("    MKMapView(frame: 320x480) 出厂：zoomEnabled=true scrollEnabled=true rotateEnabled=true pitchEnabled=true showsCompass=true showsScale=false showsUserLocation=false")
    line("      mapType 出厂=0")
    line("      region 出厂 center=(35.7738,103.1836) span=65.5061x55.5469")
    line("      camera 出厂：center lat=35.7738 distance=13995915.9651 heading=-0.0000 pitch=0.0000")
    line("      annotations=0 overlays=0 selectedAnnotations=0 visibleMapRect 宽=41418752.0000 subviews 数=5")
    line("    setRegion(animated:false) 之后：center lat=39.9042 span latDelta=0.0269 visibleMapRect 宽=17439.5398")
    line("    convert=(160.0000,240.0000) 反算=(39.9042,116.4074)")
    line("    同一坐标再 convert 一次（幂等检查）=(160.0000,240.0000)")
    line("    region 左上角 convert=(0.0000,-0.0236)")
    line("    addAnnotation 之后 annotations=1 选中前=false 选中后=true selectedAnnotations 数=1 view(for:) 类型=MKMarkerAnnotationView 非 nil=true")
    line("    deselectAnnotation 之后仍在选中集=false 数=0")
    line("    addOverlay(MKCircle 北京 radius=1000) 之后 overlays=1 renderer 类型=nil MKOverlayLevel.aboveRoads raw=0")
    line("    removeOverlay/removeAnnotation 之后 overlays=0 annotations=0")
    line("    强制布局之后 subviews 数=5；泵 0.6 秒 runloop 之后再数=4")
    line("  一条只能靠探针复现的崩溃，本章**不执行**：")
    line("    MKOverlayPathRenderer()  → Child process terminated with signal 11: Segmentation fault")
    line("    （同一份探针里 MKPolylineRenderer(polyline:)、MKCircleRenderer(circle:) 都正常，差别只在**有没有喂给它一个 overlay**）")
    expect(mkv.frame.width == 28 && mkv.frame.height == 28 && glyphBefore == nil && glyphBack == "P" && !mkv.canShowCallout && mkv.markerTintColor == nil && !av.canShowCallout && av.isEnabled && !av.isDraggable,
           "**标注视图可以完全脱离地图单独造出来测**：`MKMarkerAnnotationView()` 出厂 frame 是 **28x28**（不是 .zero，系统给了默认尺寸）、glyphText 出厂 nil 且写得进读得出、canShowCallout 出厂 **false**、markerTintColor 出厂 nil；父类 MKAnnotationView 出厂 isEnabled=true、isDraggable=false。**canShowCallout 这一条是新手「点标注没气泡」的标准答案**：它默认关着，得显式设 true；而上面 MKMapView 探针里 `view(for:)` 拿到的正是同一个 MKMarkerAnnotationView 类型，说明「地图给你的 view」和「你自己造的 view」是同一套类，可以单测。反过来说，凡是**带指针地址的 description 一个字都不能打印**（形如 `Optional(<MKMarkerAnnotationView: 0x…; frame = (0 0; 28 28); hidden = YES; …>)`），一打 debug/release 就对不上，这是本章把 MKMapView 整段挪出示例的第二个原因")
    expect(pr.overlay === poly20 && cr.overlay === circ20 && prLine0 == 0 && prStrokeNil0 && crLine0 == 0 && crStrokeNil0 && crFillNil0 && prAlpha0 == 1 && cr.lineWidth == 4 && pr.strokeColor != nil,
           "**渲染器出厂是「完全不可见」的一套值**：刚造出来 lineWidth=0、strokeColor=nil、fillColor=nil、alpha=1（上面两行打印的就是这套 0 和「非 nil=false」）—— 也就是说 `MKCircleRenderer(circle:)` 造出来之后如果只设半径不设颜色，**它在地图上是一片透明**，而这正是探针里 `renderer(for:)` 那行的另一半解释：没实现 delegate 的 `mapView(_:rendererFor:)` 时地图连这样一个全透明渲染器都不会给你，直接返回 nil。**两段合起来是 MapKit 覆盖物的头号「看不见」成因**：一层是忘实现回调（返回 nil），一层是实现了但没设颜色/线宽（返回一个透明对象）。另外 `overlay` 属性是**同一对象引用**（`===` 成立），所以渲染器不是副本，改它就改地图上那一笔；而**裸 `MKOverlayPathRenderer()` 会段错误**（上面原文），基类只能当父类用，必须走带 overlay 的子类构造器")
    expect(true,
           "**MKMapView 探针段说明了三件事，第一件就是本章为什么不能执行它**：① 只构造 `MKMapView(frame:)` 就往 stderr 打 CAMetalLayer 那 120 字节日志，headless 示例碰不得（harness 判定 3），所以这段只能引用；② **出厂七个开关是 5 开 2 关，关掉的正好是「要流量/要权限」那两个** —— showsScale=false、showsUserLocation=false，后者一旦设 true，§5–§8 那条定位链路就被启动，等于**别处需要 Info.plist 权限声明才能做的事，这里一个属性就能触发**；四个交互开关全开则是产品坑：内嵌在列表里的小地图若留着 isScrollEnabled=true，用户滑列表时手指一碰地图就变成拖地图，这是每个用 MapKit 的 App 都挨过的投诉；③ **出厂视野不是零值而是「整个中国」**（region 中心 (35.7738,103.1836)、span 65.5x55.5、visibleMapRect 宽 41418752.0000）—— App 一打开地图就是满屏中国，不是谁配了参数，是 MKMapView 的默认 region")
    expect(true,
           "**setRegion(animated:false) 之后 region、camera、visibleMapRect 三者立刻同步**（探针：中心立刻变北京、visibleMapRect 从 41418752.0000 收到 17439.5398）。**三个量描述同一件事的三种坐标系**：region 用经纬度、visibleMapRect 用地图点、camera 用「中心+距离+朝向+俯仰」，代码里最好只用一个、其余按需换算（换算就是 19 节那套函数）。同一份探针里 convert 的三行是本章关于 MapKit 测试策略最值钱的一组数：北京中心被投到 (160.0000,240.0000)，也就是 320x480 那块 frame 的正中央，**再 convert 一次结果逐位不变**（幂等），反算回去精确闭合到 (39.9042,116.4074)；而 region 左上角落在 (0.0000,**-0.0236**) —— y 是**负的**，因为 setRegion 把纬度跨度按 frame 高度铺满时经度方向更宽，左上角那一点被挤到屏幕外。**结论：经纬度↔视图点这一对完全不依赖网络和硬件，可以在单元测试里全量覆盖，不需要真机也不需要模拟定位**（探针能测，只是不能进本章示例）")
    expect(true,
           "**状态机在 headless 里是跑得动的**（探针：addAnnotation 后计数 0→1、selectAnnotation 真的把它放进 selectedAnnotations、deselect 后从集合里消失、`view(for:)` 返回真实 MKMarkerAnnotationView、addOverlay 后 overlays=1、remove 之后全部归零）。**唯一跑不动的是「画出来」这件事**。这一节还有一行我在探针里撞到的反直觉数：强制布局之后 subviews 数=5，**再泵 0.6 秒 runloop 变成 4** —— 地图视图的子视图树由它自己管理，会随内部图层增减。所以任何「数 subviews」「按索引取子视图」的断言在 MKMapView 上都是脆的，别写；要判状态就判 annotations / overlays / selectedAnnotations 这三个数组")
}
line("")

line("== 20b) MKGeometry：折线/多边形/圆、coordinate 属性真值，以及 iOS 上点不动的七条写法 ==")
do {
    let tri = MKPolygon(coordinates: [CLLocationCoordinate2DMake(0, 0), CLLocationCoordinate2DMake(0, 1),
                                      CLLocationCoordinate2DMake(1, 1)], count: 3)
    line("  MKPolygon 三角形：pointCount=\(tri.pointCount) coordinate=(\(f12(tri.coordinate.latitude)),\(f12(tri.coordinate.longitude))) boundingMapRect.origin=(\(f4(tri.boundingMapRect.origin.x)),\(f4(tri.boundingMapRect.origin.y))) size=\(f4(tri.boundingMapRect.size.width))x\(f4(tri.boundingMapRect.size.height)) interiorPolygons=\(String(describing: tri.interiorPolygons))")
    let triPts = tri.points()
    line("        tri.points() 拿到的三个顶点（反投影回经纬度）：")
    for i in 0..<tri.pointCount {
        let c = triPts[Int(i)].coordinate
        line("          \(i)：MKMapPoint(\(f4(triPts[Int(i)].x)),\(f4(triPts[Int(i)].y))) → (\(f12(c.latitude)),\(f12(c.longitude)))")
    }
    line("        三点的**质心**应是 (\(f12((0.0 + 0.0 + 1.0) / 3)),\(f12((0.0 + 1.0 + 1.0) / 3)))，**经纬度算术中点**是 (0.500000000000,0.500000000000)")
    let poly = MKPolyline(coordinates: [CLLocationCoordinate2DMake(0, 0), CLLocationCoordinate2DMake(0, 1)], count: 2)
    line("  MKPolyline 赤道 1°：pointCount=\(poly.pointCount) boundingMapRect 宽=\(f4(poly.boundingMapRect.size.width))")
    let circ = MKCircle(center: CLLocationCoordinate2DMake(0, 0), radius: 1000)
    let circBJ = MKCircle(center: CLLocationCoordinate2DMake(39.9042, 116.4074), radius: 1000)
    line("  MKCircle(radius:1000) 放在赤道：radius=\(f4(circ.radius)) boundingMapRect 宽=\(f4(circ.boundingMapRect.size.width)) 高=\(f4(circ.boundingMapRect.size.height))")
    line("        同一个半径放在北京 (39.9042,116.4074)：宽=\(f4(circBJ.boundingMapRect.size.width)) 高=\(f4(circBJ.boundingMapRect.size.height)) 宽之比=\(f4(circBJ.boundingMapRect.size.width / circ.boundingMapRect.size.width))")
    let impliedEQ = 2000.0 / circ.boundingMapRect.size.width
    let impliedBJ = 2000.0 / circBJ.boundingMapRect.size.width
    let mppEQ = MKMetersPerMapPointAtLatitude(0)
    let mppBJ = MKMetersPerMapPointAtLatitude(39.9042)
    line("        拿 2r/宽 反推「米/点」：赤道 \(f12(impliedEQ)) 北京 \(f12(impliedBJ))")
    line("        MKMetersPerMapPointAtLatitude 直算：赤道 \(f12(mppEQ)) 北京 \(f12(mppBJ))（**逐位相同**，见下面那条）")
    line("        1/cos(39.9042)=\(f12(1.0 / cos(39.9042 * .pi / 180))) 而两档米/点之比=\(f12(mppEQ / mppBJ))（**并不相等**，比例尺不是干净的 cos 倍数）")
    line("        （对比 world 宽=\(f4(MKMapRect.world.size.width))）")
    let multi = MKMultiPolygon([tri])
    line("  MKMultiPolygon(_:)：polygons.count=\(multi.polygons.count) boundingMapRect 宽=\(f4(multi.boundingMapRect.size.width))")
    let geo = MKGeodesicPolyline(coordinates: [CLLocationCoordinate2DMake(0, 0), CLLocationCoordinate2DMake(60, 1)], count: 2)
    line("  MKGeodesicPolyline (0,0)→(60,1)：pointCount=\(geo.pointCount) boundingMapRect 宽=\(f4(geo.boundingMapRect.size.width))（普通 MKPolyline 同样两端点是 \(poly.pointCount) 个点）")
    line("  iOS 上**点不出来**的五个（都是 macOS 侧 API，每条编译器原文都是我刚撞的）：")
    line("    tri.area             → error: value of type 'MKPolygon' has no member 'area'")
    line("    tri.perimeter        → error: value of type 'MKPolygon' has no member 'perimeter'")
    line("    poly.length          → error: value of type 'MKPolyline' has no member 'length'")
    line("    tri.coordinate(at: 0) → error: cannot call value of non-function type 'CLLocationCoordinate2D'")
    line("    circ.contains(pt)    → error: value of type 'MKCircle' has no member 'contains'")
    line("  另外两条也是编译器原文，属于「明明有 C 函数、Swift 里点不动」：")
    line("    tri.coordinates(buf)   → error: value of type 'MKPolygon' has no member 'coordinates'（**MKPolygon 继承 MKShape，不是 MKMultiPoint**，所以没有那对按索引取经纬度的方法）")
    line("    MKCoordinateForMapPoint(p) → error: 'MKCoordinateForMapPoint' has been replaced by property 'MKMapPoint.coordinate'")
    line("      （note: 'MKCoordinateForMapPoint' was obsoleted in Swift 3 —— 网上大量教程还在写这个函数名，照着抄直接编不过）")
    expect(tri.pointCount == 3 && poly.pointCount == 2 && geo.pointCount > 6000 && tri.interiorPolygons == nil,
           "**几何对象只是「点的集合 + 一个外接矩形」，本身不含曲线信息**：MKPolygon 存 3 个点、MKPolyline 存 2 个点，而 **MKGeodesicPolyline 把同样的两个端点自己插值成 \(geo.pointCount) 个点**（大圆弧在墨卡托上不是直线，系统预先切成上万段）。这条的实用价值很直接：**geodesic 画跨洋航线是对的，但它是折线、段数上万**，拿它做动画或者叠几十个，CPU 就是被这些顶点拖死的；而 `interiorPolygons`（带洞的多边形）出厂是 **nil 而不是空数组**，判「有没有洞」只能判 nil")
    expect(tri.boundingMapRect.size.width > 700_000 && tri.boundingMapRect.size.width < 800_000
           && circ.boundingMapRect.size.width > 13_000 && circ.boundingMapRect.size.width < 13_600
           && circBJ.boundingMapRect.size.width > 17_000 && circBJ.boundingMapRect.size.width < 17_600
           && circ.boundingMapRect.size.width == circ.boundingMapRect.size.height
           && multi.boundingMapRect.size.width == tri.boundingMapRect.size.width
           && impliedEQ == mppEQ && impliedBJ == mppBJ,
           "**boundingMapRect 用的是 19 节那套「地图点」单位，可以直接算比例，而且比例是精确的**：赤道上 1° 经度=745654.0444 个点，乘 0.1483 米/点得到 110km 量级（和「1°≈111km」对得上）；radius=1000 米的圆在赤道的**外接框宽 13487.1067 个点、在北京是 17509.2359 个点**，宽之比 1.2982（同一个圆换纬度会变大 —— 圆在墨卡托上按比例尺放大）。上面两行反推的「米/点」与 MKMetersPerMapPointAtLatitude 直算的结果**逐位相等**，这不是巧合：说明**外接框就是拿中心纬度那一档比例尺一次换算出来的**，圆内各处纬度不同并不参与计算 —— 所以「圆的包围盒」在跨纬度很大的圆（比如半径 2000 公里）上会偏小，**别把它当精确的东西用于面积**。而 **MKMultiPolygon 的 boundingMapRect 就是成员矩形的并**（上面第三个条件是逐位相等）。意义在于：**「这个覆盖物该在什么缩放级别出现」可以自己算，不用问 MKMapView，更不用等网络** —— 这是 MapKit 里除纯数学之外第二块完全离线可测的面")
    expect(abs(tri.coordinate.latitude - 0.5) < 0.0001 && tri.coordinate.longitude == 0.5
           && abs(tri.coordinate.latitude - (0.0 + 0.0 + 1.0) / 3) > 0.1,
           "**有两个「coordinate」，长得一样意思不同，而且这个值还不是精确的 0.5**：`tri.coordinate`（上面打印 \(f12(tri.coordinate.latitude))）是 MKShape 上的**属性**，返回的是**外接矩形的中心**，不是顶点、也不是质心（本例三点的质心是 (0.333333333333,0.666666666667)，首点是 (0,0)）。**我写这一节之前一直以为它是「第一个点的坐标」，后来以为是「经纬度的算术中点 (0.5,0.5)」，两条都被实测否掉**：纬度是 0.500019039676 —— 因为它是先在**地图点**坐标系里把 boundingMapRect 取中（134217728.0 ~ 133472036.096137 的中点），再反投影回纬度，墨卡托是非线性的，所以反算出来必然偏离算术中点 1.9e-5 度（约 2 米）。**结论有两层**：一，拿 `shape.coordinate` 当标注锚点在不规则多边形上会把标注放歪，而且放歪的量不是零，**别指望它是整数**；二，浮点断言必须带容差（本章这条就是 `abs(... - 0.5) < 0.0001`，我原来写 `== 0.5` 直接 FAIL）。iOS 上要拿顶点只能靠 `tri.points()`（返回 `UnsafeMutablePointer<MKMapPoint>`）配 `pointCount`，再逐个 `.coordinate` 反投影（上面那三行就是这么打的）；**`coordinate(at:)` 只有 macOS 有**，iOS 上报 `cannot call value of non-function type 'CLLocationCoordinate2D'`，因为这里 coordinate 是属性、不能当方法调")
}
line("")

line("== 20c) MKGeoJSONDecoder：三种「是合法 JSON 但不是合法 GeoJSON」的不同下场 ==")
do {
    let dec = MKGeoJSONDecoder()
    do {
        let objs = try dec.decode(Data(#"{"type":"Point","coordinates":[116.4074,39.9042]}"#.utf8))
        line("  Point：对象数=\(objs.count) 类型=\(String(describing: type(of: objs[0])))")
        if let pa = objs[0] as? MKPointAnnotation {
            line("        可直接当标注用：(\(f4(pa.coordinate.latitude)),\(f4(pa.coordinate.longitude))) title=\(String(describing: pa.title))")
        }
    } catch { let e = error as NSError; line("  Point 意外抛错：\(e.domain)#\(e.code)") }
    do {
        let objs = try dec.decode(Data(#"{"type":"FeatureCollection","features":[{"type":"Feature","geometry":{"type":"Point","coordinates":[0,1]},"properties":{"k":"v"}}]}"#.utf8))
        line("  FeatureCollection：对象数=\(objs.count) 类型=\(String(describing: type(of: objs[0])))")
        if let feat = objs[0] as? MKGeoJSONFeature {
            line("        feature.geometry 数=\(feat.geometry.count) properties=\(feat.properties.map { String(decoding: $0, as: UTF8.self) } ?? "nil") identifier=\(String(describing: feat.identifier))")
        }
    } catch { let e = error as NSError; line("  FeatureCollection 抛错：\(e.domain)#\(e.code)") }
    do {
        let objs = try dec.decode(Data("{}".utf8))
        line("  解码 {}：不抛错，对象数=\(objs.count)")
    } catch { let e = error as NSError; line("  解码 {} 抛错：\(e.domain)#\(e.code) desc=\(e.localizedDescription)") }
    do {
        _ = try dec.decode(Data(#"{"type":"Polygon","coordinates":[[[0,0],[0,1],[1,1]]]}"#.utf8))
        line("  **首尾不闭合**的 Polygon：不抛错")
    } catch { let e = error as NSError; line("  不闭合 Polygon 抛错：\(e.domain)#\(e.code)") }
    do {
        _ = try dec.decode(Data(#"{"type":"LineString","coordinates":[[0,0],[1,1]]}"#.utf8))
        line("  LineString：不抛错")
    } catch { let e = error as NSError; line("  LineString 抛错：\(e.domain)#\(e.code)") }
    do {
        _ = try dec.decode(Data("not json".utf8))
        line("  非 JSON 文本：不抛错")
    } catch { let e = error as NSError; line("  非 JSON 文本抛错：\(e.domain)#\(e.code) desc=\(e.localizedDescription)") }
    line("  MKErrorDomain=\(MKErrorDomain) MKError.Code：unknown=\(MKError.Code.unknown.rawValue) serverFailure=\(MKError.Code.serverFailure.rawValue) loadingThrottled=\(MKError.Code.loadingThrottled.rawValue) placemarkNotFound=\(MKError.Code.placemarkNotFound.rawValue) directionsNotFound=\(MKError.Code.directionsNotFound.rawValue) decodingFailed=\(MKError.Code.decodingFailed.rawValue)")
    expect(MKError.Code.decodingFailed.rawValue == 6 && MKError.Code.placemarkNotFound.rawValue == 4
           && MKError.Code.directionsNotFound.rawValue == 5,
           "**MKError 的码表里没有「坐标非法」这一档**，和本地解析有关的只有 decodingFailed=6，其余四档（serverFailure/loadingThrottled/placemarkNotFound/directionsNotFound）全是**网络服务**的错误。这和 19 节「region 不校验」彼此印证：**MapKit 的错误码是为在线服务设计的，不是为本地数据设计的**，所以你从本地 GeoJSON 里读出一个坏坐标，框架一个错都不会报")
    expect(true,
           "本节**没有**把解码结果写成断言，而是把每一条的真实下场原样打在上面，因为三条结果各不相同：`{}` 抛 **MKErrorDomain#6**（decodingFailed，GeoJSON 语义层）；`not json` 抛 **NSCocoaErrorDomain#3840**（JSON 语法本身就不对，Foundation 层）；而**首尾不闭合的 Polygon 和 LineString 都不抛错**。三行连起来就是要点：**同一个 decode 方法有两层失败，判错必须连 domain 一起看**；而语义层的检查远比人想的松 —— GeoJSON 规范要求 Polygon 环必须闭合，MKGeoJSONDecoder **不检查**，画出来的是一个自己接回去的图形，**和按规范渲染的服务端结果差一块**。**「解码没报错」绝不等于「数据是对的」**，跨端一致性得自己校验")
    do {
        _ = try dec.decode(Data(#"{"type":"MultiPoint","coordinates":[[0,0]]}"#.utf8))
        line("  MultiPoint：不抛错（但注意规范里 MultiPoint 是允许的，MK 的解码结果类型要自己 as 出来）")
    } catch { let e = error as NSError; line("  MultiPoint 抛错：\(e.domain)#\(e.code)") }
}
line("")

line("== 20d) MKDistanceFormatter 与 MKMapSnapshotter.Options：一个反直觉的取整，一个不能跑的渲染 ==")
do {
    let df = MKDistanceFormatter()
    line("  出厂 units=\(df.units.rawValue)（default=\(MKDistanceFormatter.Units.default.rawValue) metric=\(MKDistanceFormatter.Units.metric.rawValue) imperial=\(MKDistanceFormatter.Units.imperial.rawValue)）unitStyle=\(df.unitStyle.rawValue)（default=\(MKDistanceFormatter.DistanceUnitStyle.default.rawValue) abbreviated=\(MKDistanceFormatter.DistanceUnitStyle.abbreviated.rawValue) full=\(MKDistanceFormatter.DistanceUnitStyle.full.rawValue)）")
    line("  default 样式：1500=\(df.string(fromDistance: 1500)) 0=\(df.string(fromDistance: 0)) 999=\(df.string(fromDistance: 999)) 100000=\(df.string(fromDistance: 100000)) 0.3=\(df.string(fromDistance: 0.3))")
    let abbrev = MKDistanceFormatter()
    abbrev.unitStyle = .abbreviated
    let full = MKDistanceFormatter()
    full.unitStyle = .full
    line("  abbreviated：1500=\(abbrev.string(fromDistance: 1500)) 999=\(abbrev.string(fromDistance: 999)) 0.3=\(abbrev.string(fromDistance: 0.3))")
    line("  full      ：1500=\(full.string(fromDistance: 1500)) 999=\(full.string(fromDistance: 999)) 0.3=\(full.string(fromDistance: 0.3)) -5=\(full.string(fromDistance: -5))")
    let imp = MKDistanceFormatter()
    imp.units = .imperial
    line("  imperial  ：1500=\(imp.string(fromDistance: 1500)) 999=\(imp.string(fromDistance: 999))")
    let s1500 = df.string(fromDistance: 1500)
    line("  反解：distance(from: 上面那串)=\(f4(df.distance(from: s1500))) distance(from: \"abc\")=\(f4(df.distance(from: "abc")))（头文件原话：解析不了返回负数）")
    line("  NSFormatter 那套：string(for: 1500 as Any)=\(df.string(for: 1500 as Any) ?? "nil") string(for: \"abc\" as Any)=\(df.string(for: "abc" as Any) ?? "nil")")
    line("  locale 出厂有值=\(df.locale != nil)（**对象本身不打印**：跟系统地区设置走，换机器输出就不同）")
    let opts = MKMapSnapshotter.Options()
    line("  MKMapSnapshotter.Options 出厂：size=\(f4(Double(opts.size.width)))x\(f4(Double(opts.size.height))) region 中心 lat=\(f4(opts.region.center.latitude)) mapRect 宽=\(f4(opts.mapRect.size.width)) camera 中心 lat=\(f4(opts.camera.centerCoordinate.latitude))")
    line("  两条「以为有、实际没有」的编译器原文：")
    line("    df.valueFormatter → error: value of type 'MKDistanceFormatter' has no member 'valueFormatter'")
    line("    opts.quality      → error: value of type 'MKMapSnapshotter.Options' has no member 'quality'")
    line("    （**Options.camera 是非可选的**，出厂就给你一个 MKMapCamera 对象；它的 description 里有指针地址，所以只打数值分量）")
    expect(df.units == MKDistanceFormatter.Units.default && MKDistanceFormatter.Units.metric.rawValue == 1 && MKDistanceFormatter.Units.imperial.rawValue == 2,
           "**MKDistanceFormatter 出厂 units 是 default(0)，而 default 的意思是「按 locale 自动选」**，metric=1、imperial=2 才是显式指定。这一档最容易写错：`df.units = .metric` 之后 App 对海外用户也只说公里。**距离单位是产品口径**，运动/出行类通常让 locale 决定，物流测量类才写死")
    expect(df.string(fromDistance: 999) == "1.0公里" && df.string(fromDistance: 0.3) == "0米"
           && abbrev.string(fromDistance: 999) == "1.0公里" && full.string(fromDistance: -5) == "-5米",
           "**本节最反直觉的实测：999 米被打印成「1.0公里」，0.3 米被打印成「0米」**，三种 unitStyle 在中文 locale 下输出**完全一样**（对照上面 default/abbreviated/full 三行，一个字符都不差 —— 英文下才看得出 km 与 kilometers 的差别）。原因是**它先按单位取整、再选单位**：0.999 公里四舍五入成 1.0 就升到公里档。**后果是「不到 1 公里」这类文案不能靠它生成**，凡是「按显示的档位做判断」的代码都错；而且 -5 会原样打成「-5米」，**它不拒绝负数**。**精确控制显示得自己拿 CLLocationDistance 判断，只把「拼单位+本地化」这一步交给 formatter**")
    expect(df.distance(from: s1500) < 0 && df.distance(from: "abc") < 0
           && df.string(for: "abc" as Any) != nil,
           "**同一个对象对坏输入的两条路表达完全相反**：反解 `distance(from:)` 对解析不出来的字符串返回**负数**（实测两串都是 -1，头文件原话就是「返回负数」），而 NSFormatter 那套 `string(for:)` 传一个**字符串**（不是数字）却老实给你「0米」。**两条都不抛错、不打日志**。所以「格式化 → 存字符串 → 再解析回来」这条往返一旦中间被人改过文案，拿回来就是 -1 或 0，然后静默进数据库。**结论和上一节呼应：距离这类量只存数值，永远不要存格式化后的文字**")
    expect(opts.size.width == 256 && opts.mapRect.size.width < MKMapRect.world.size.width
           && abs(opts.camera.centerCoordinate.latitude - opts.region.center.latitude) < 0.001,
           "**Snapshotter.Options 出厂是 256x256，region/mapRect/camera 三者互相一致地指向 MKMapView 那个默认视野**（mapRect 宽 41418752.0000，**不是整个 world 的 268435456**，见上面打印；camera 中心纬度与 region 中心纬度相同）。真正出图的 `start(completionHandler:)` 在本章**不能调用**：探针实测它先往 stderr 打一条系统日志，而 harness 判定 3 要求 stderr 为空。探针两条原文：")
    line("    2026-09-29 07:55:25.588 p25mk[2713:3836325] CAMetalLayer ignoring invalid setDrawableSize width=0.000000 height=0.000000")
    line("    5 秒内 completionHandler 没回（有回复=false）；cancel() 之后 isLoading 读到 true；再泵 1 秒才回「有图=true err=nil」")
    line("    → 渲染最终能成，但它**既脏 stderr 又依赖 Metal/GPU 图层**，属本章诚实边界；静态地图快照请上真机或独立的 UI 测试里验")
}
line("")

line("== 21) 距离传感器（proximity，book 7.3）：一个「写了读不回来」的开关 ==")
do {
    let dev = UIDevice.current
    line("  出厂：isProximityMonitoringEnabled=\(dev.isProximityMonitoringEnabled) proximityState=\(dev.proximityState)")
    line("  通知名 UIDevice.proximityStateDidChangeNotification.rawValue=\(UIDevice.proximityStateDidChangeNotification.rawValue)")
    dev.isProximityMonitoringEnabled = true
    let on1 = dev.isProximityMonitoringEnabled
    let state1 = dev.proximityState
    pump(0.3)
    let on2 = dev.isProximityMonitoringEnabled
    line("  设 true 之后立刻读回 enabled=\(on1) proximityState=\(state1)；泵 0.3 秒再读 enabled=\(on2) proximityState=\(dev.proximityState)")
    dev.isProximityMonitoringEnabled = false
    line("  设 false 之后读回=\(dev.isProximityMonitoringEnabled)")
    line("  同一次读取里对照 §14 的电量开关：isBatteryMonitoringEnabled=\(dev.isBatteryMonitoringEnabled)")
    expect(on1 == false && on2 == false && state1 == false,
           "**proximity 开关「写 true、读回来是 false」**（上面 enabled 两读都是 false），而 §14 里那个电量监控开关**在同一台机器上写得进去** —— 两个同为 UIDevice 的布尔开关，命运恰好相反。原因是距离传感器的唯一用途是「贴脸熄屏」，**没有硬件时 UIKit 不把订阅建立起来**，于是属性回落到 false。**读不回来不是 API 坏了，而是在告诉你「订阅没建成」**。写通话类代码要记住：这个传感器**没有可用性查询**（UIDevice 压根不给 isProximityAvailable 之类），只能靠「设完再读回来」这个土办法判断")
    expect(dev.proximityState == false,
           "**proximityState 的 false 是「远离」而不是「未知」**（真机上贴住传感器才变 true）。这一条在真机上会咬人：**启动时读到 false 就按「没贴脸」点亮屏幕**，可监控没开时它永远停在 false，于是「贴着脸但屏幕亮着、还能被手指误触」这种 bug 在没有 UI 的测试环境里根本发现不了。正确写法是**开启监控 + 注册上面那个通知 + 只在通知里改状态**，别把出厂那次读取当成「用户没贴着手机」")
    line("  §21 和 §14 合起来是 UIDevice 上「开关」的完整图景：**同前缀、同类型（布尔开关），一台写得进一台写不进，而且都没有可用性查询** ——")
    line("     凡是「设完必须读回来才知道成没成」的属性，代码里就该显式读一次并准备降级路径")
}
line("")

line("== 本章的诚实边界 ==")
line("  1) 传感器读数本身全部没验：headless 模拟器上运动硬件不可用，")
line("     本章只能证明可用性查询、默认值、属性语义与错误表达方式。")
line("  2) 「用户点了允许」之后的分支一条都没验：弹窗接口不能调（§11 C 会往 stderr 打日志），")
line("     所以定位真的回数据、计步真的算出 stepCount、气压计真的给出 relativeAltitude —— 这些本章**没有**任何实测。")
line("     能测的只有出厂那一侧（notDetermined / denied / available=false / handler 0 次）。")
line("     要覆盖允许分支只能靠模拟器的隐私设置面板或真机，不是本 harness 能替你做的。")
line("  3) 机型差异没验：maximumFramesPerSecond、availableAttitudeReferenceFrames()、")
line("     DiscoverySession 找到的相机数在真机上是另一套值；本章所有数字只在 iOS 18.3.1 模拟器 x86_64 上成立。")
line("  4) 回调的线程语义没验：§2/§3/§5 只统计了 handler 来几次，")
line("     没有验证 handler 究竟跑在哪个线程/队列、也没有压 start→stop 之间的竞态和短间隔连续起停。")
line("     「UI 更新要不要切主线程」这类问题本章给不出证据。")
line("  5) 依赖系统服务的内容正确性没验：CLGeocoder 的 placemark 字段、CLVisit 的坐标与日期、")
line("     CLLocation 的 sourceInformation 在 headless 里要么不回、要么直接崩（§13/§16），")
line("     所以本章只讲它们的**存在与形状**，不讲字段值。")
line("  6) 时间与功耗：所有时间戳都用固定的 1_700_000_000 一类常量（否则 debug/release 无法逐字节比对），")
line("     真实经过时间、后台唤醒时长、lowPowerMode 对采样率的影响都没测；")
line("     thermalState 只读了出厂那一档 nominal，没有制造过热场景，采集对电池的实际消耗也没测。")
line("  7) 本章全是无界面调用：UIDevice.orientation 在真的跑起来的 App 里才会随转屏变化，")
line("     headless 下它恒为 unknown(0)，所以「方向监听」这条链路本章只能证明枚举值域，证明不了行为。")
line("  8) LocalAuthentication 只测了「验证注定失败」那一侧：§17 所有 success=true 的分支一个都没有 ——")
line("     用户真的按下面容、真的输了密码、真的走了 -8 锁定重试、evaluateAccessControl 保护密钥取用，")
line("     本章全部只能证明「它们会返回哪些码」，证明不了「码对应的界面长什么样、点了之后发生什么」。")
line("     biometryType 在模拟器上读回 faceID 也**不代表真机的表现**，只代表这台模拟器的 HID 配置。")
line("  9) CoreBluetooth 一行真实 BLE 流量都没有：§18 的适配器落到 unsupported(2)，所以扫描、广播、连接、")
line("     读写特征、订阅 notify 全链路都没跑过（discovered 计数是 0，因为压根没开始扫）。")
line("     CBManager.authorization 读到 allowedAlways(3) 是 **simctl spawn 出来的命令行进程**的产物，")
line("     不能用来推断「真机 App 不写 NSBluetoothAlwaysUsageDescription 也能用蓝牙」—— 恰恰相反。")
line(" 10) MapKit 没有任何渲染与网络证据：§20 连 MKMapView 都**没有执行**（探针实测一句 `MKMapView(frame:)`")
line("     就往 stderr 打 120 字节，判定 3 直接判死），那一节的七行开关、region/camera/visibleMapRect 同步、")
line("     convert 往返、标注增删选中、renderer(for:) 返回 nil、subviews 从 5 变 4 —— 全是**探针 p25mv2 的原文**，")
line("     本章示例里跑的是能脱离地图视图的对象（MKPointAnnotation / MKPlacemark / MKMapItem /")
line("     MKMarkerAnnotationView / MKPolylineRenderer / MKCircleRenderer / 几何体 / 解码器 / formatter）。")
line("     瓦片、覆盖物实际画出来是什么样、MKMapSnapshotter.start 出图（它同样脏 stderr，见 §20d 原文）、")
line("     MKDirections / MKLocalSearch / MKMapItem.search / MKGeocoder 这些**依赖在线服务**的接口，本章一个字都没测。")
line("     另外 §20d 那些「1.5公里」「0米」是**这台模拟器中文 locale** 下的产物，换英文系统是另一串字。")
line(" 11) 距离传感器只证到「写不进去」：§21 没收到过任何一次 proximityStateDidChange 通知，")
line("     「贴脸熄屏」这条链路的另一半（系统真的熄屏、App 真的收到通知）得在真机上用手捂着验。")
line(" 12) 权限文案与 Info.plist 本章一律绕不过去：LA 不需要 reason 之外的声明，但 §17 那条")
line("     「localizedReason 必须非空」是运行时崩溃而不是编译期约束；§18 的蓝牙、§20 的定位都")
line("     依赖 plist 声明，而 headless 进程压根不走那套检查 —— **本章所有「没报权限错」的输出都不能当成")
line("     「真机上也不用配」的证据**，这一条和 §2 之后每一节的性质相同。")
line("")
line("  一句话：这一章把「硬件不在、界面不在、网络不在时 API 怎么说话」讲透了 ——")
line("     CoreMotion/CoreLocation 之外，又补上了 LA 的界面依赖、CB 的适配器依赖、MapKit 的渲染与服务依赖。")
line("     凡是真要读数、真要出图、真要用户点确认的代码，都必须回真机验证再上线。")
line("")
line("==== 25 结束 ====")
exit(failures == 0 ? 0 : 1)
