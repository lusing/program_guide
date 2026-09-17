#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
XIB 静态一致性检查（编译之前跑）

Interface Builder 是「图形化编辑器」，它不会告诉你 Swift/ObjC 源码里有没有那个类、
有没有那个属性；等你运行时才拿到的线索只有一句崩溃日志。本机的 ibtool 只负责把
XIB 编译成 nib，**它同样不做跨语言校验** —— 所以这一步只能我们自己补：

    - XIB 里出现的 customClass 必须在同一示例的源码里有定义
    - customModule 必须等于该示例的模块名（被 swiftc 用 -module-name 指定）
    - <outlet property="X"> 的宿主必须有 customClass，且源码里必须有 X 这个属性
    - <action selector="foo:" target="ID"> 的目标类源码里必须有 foo: 这个方法
    - destination / target 引用的 id 必须在文档里存在（悬空连线）

任何一条不成立就退出码 1，两个入口（run-all.sh / build.ps1）都在编译前调用它。
"""
import os
import re
import sys
import glob
import xml.etree.ElementTree as ET

EXAMPLES = sys.argv[1] if len(sys.argv) > 1 else os.path.join(os.path.dirname(__file__), "..", "examples")

SOURCE_EXT = (".swift", ".m", ".h")

# Interface Builder 自带的占位类，不需要（也不能）在源码里定义
PLACEHOLDER_CLASSES = ("FirstResponder",)


def read_sources(example_dir):
    text = []
    for ext in SOURCE_EXT:
        for path in sorted(glob.glob(os.path.join(example_dir, "*" + ext))):
            with open(path, "r", encoding="utf-8") as fh:
                text.append(fh.read())
    return "\n".join(text)


def has_class(src, cls):
    """源码里有没有定义这个类（Swift 用 class/struct/actor/enum，ObjC 用 @interface/@implementation）"""
    if re.search(r"\b(class|struct|actor|enum)\s+" + re.escape(cls) + r"\b", src):
        return True
    if re.search(r"@(interface|implementation)\s+" + re.escape(cls) + r"\s*[:({]", src):
        return True
    if re.search(r"@(interface|implementation)\s+" + re.escape(cls) + r"\s*$", src, re.M):
        return True
    return False


def has_property(src, prop):
    if re.search(r"@IBOutlet\s+(weak\s+)?var\s+" + re.escape(prop) + r"\b", src):
        return True
    if re.search(r"\bvar\s+" + re.escape(prop) + r"\s*:", src):
        return True
    if re.search(r"@IBOutlet\s+.*\b" + re.escape(prop) + r"\s*;\s*$", src, re.M):
        return True
    if re.search(r"@property\s*\([^)]*\)\s*.*\b" + re.escape(prop) + r"\s*;", src):
        return True
    return False


def has_method(src, sel):
    if re.search(r"@IBAction\s+func\s+" + re.escape(sel) + r"\b", src):
        return True
    if re.search(r"\bfunc\s+" + re.escape(sel) + r"\s*\(", src):
        return True
    if re.search(r"[-+]\s*\([^)]*\)\s*" + re.escape(sel) + r"\s*:", src):
        return True
    return False


def module_of(example_name):
    """NN_topic -> topic，与 run-all.sh / build.ps1 里 swiftc -module-name 的值一致"""
    return example_name.split("_", 1)[1] if "_" in example_name else example_name


def check_xib(xib_path, example_name, src, problems):
    try:
        tree = ET.parse(xib_path)
    except ET.ParseError as exc:
        problems.append("%s: XML 解析失败：%s" % (xib_path, exc))
        return
    root = tree.getroot()
    if root.get("targetRuntime") != "MacOSX.Cocoa":
        problems.append("%s: targetRuntime 不是 MacOSX.Cocoa（%s）" % (xib_path, root.get("targetRuntime")))

    objects = {}
    for obj in root.iter():
        oid = obj.get("id")
        if oid:
            objects[oid] = obj

    expected_module = module_of(example_name)

    for obj in root.iter():
        custom = obj.get("customClass")
        # 1) 自定义类必须存在；系统类（NS*/WK* 等）跳过
        if custom and not custom.startswith(("NS", "WK", "CA", "CG")) and custom not in PLACEHOLDER_CLASSES:
            if not has_class(src, custom):
                problems.append("%s: customClass=%s 在源码里没有定义" % (xib_path, custom))
            mod = obj.get("customModule")
            if mod is None:
                problems.append(
                    "%s: customClass=%s 缺少 customModule（应写成 %s，否则运行时解析不到 Swift 类）"
                    % (xib_path, custom, expected_module)
                )
            elif mod != expected_module:
                problems.append(
                    "%s: customModule=%s 与模块名不符（应为 %s）" % (xib_path, mod, expected_module)
                )

    # 2) 连线检查
    for owner in root.iter():
        conns = owner.find("connections")
        if conns is None:
            continue
        owner_id = owner.get("id")
        owner_label = owner.get("userLabel") or owner.get("customClass") or owner_id
        owner_class = owner.get("customClass")
        for conn in conns:
            cid = conn.get("id") or "?"
            if conn.tag == "outlet":
                prop = conn.get("property")
                dest = conn.get("destination")
                if dest is not None and dest not in objects:
                    problems.append("%s: outlet %s 指向不存在的 id %s" % (xib_path, prop, dest))
                if owner_class is None:
                    problems.append(
                        "%s: outlet %s 挂在非自定义对象 %s 上（IB 不会允许，说明这条连线连错了宿主）"
                        % (xib_path, prop, owner_label)
                    )
                elif owner_class.startswith(("NS", "WK", "CA", "CG")):
                    problems.append(
                        "%s: outlet %s 挂在系统类 %s 上（这类连线只有在 .m/.h 里才是合法的）"
                        % (xib_path, prop, owner_class)
                    )
                elif prop is not None and not has_property(src, prop):
                    problems.append(
                        "%s: outlet %s 在 %s 里没有对应的属性（源码里找不到 @IBOutlet var %s）"
                        % (xib_path, prop, owner_class, prop)
                    )
            elif conn.tag == "action":
                sel = conn.get("selector") or ""
                dest = conn.get("destination")
                if dest is not None and dest not in objects:
                    problems.append("%s: action %s 的 destination id %s 不存在" % (xib_path, sel, dest))
                target = objects.get(dest) if dest is not None else None
                target_class = target.get("customClass") if target is not None else None
                base = sel.rstrip(":")
                if not sel.endswith(":") and not base:
                    problems.append("%s: action %s 的 selector 写法不对" % (xib_path, sel))
                if target_class is None:
                    # 目标是 First Responder 之类的情况，运行时才解析
                    continue
                if not has_method(src, base):
                    problems.append(
                        "%s: action %s 的目标类 %s 里找不到对应方法（需要 %s(%s...)）"
                        % (xib_path, sel, target_class, base, "sender" if sel.endswith(":") else "")
                    )


def main():
    problems = []
    examples_root = os.path.abspath(EXAMPLES)
    example_dirs = sorted(glob.glob(os.path.join(examples_root, "[0-9][0-9]_*")))
    xib_total = 0
    for d in example_dirs:
        name = os.path.basename(d)
        xibs = sorted(glob.glob(os.path.join(d, "*.xib")))
        if not xibs:
            continue
        src = read_sources(d)
        for xib in xibs:
            xib_total += 1
            check_xib(xib, name, src, problems)

    if problems:
        print("XIB 一致性检查：%d 个 xib，发现 %d 个问题" % (xib_total, len(problems)))
        for p in problems:
            print("  " + p)
        return 1
    print("XIB 一致性检查通过：%d 个 xib，类/模块名/连线全部对得上源码" % xib_total)
    return 0


if __name__ == "__main__":
    sys.exit(main())
