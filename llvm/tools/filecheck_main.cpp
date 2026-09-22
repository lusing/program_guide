// ============================================================
// FileCheck 的最小驱动（macOS/MacPorts 专用补丁，非教程内容）
//
// 背景：MacPorts 的 llvm-2x 端口**只装了 libLLVMFileCheck.a 和
// llvm/FileCheck/FileCheck.h，没有 FileCheck 可执行文件**（port contents
// llvm-23 里搜不到 bin/FileCheck）。第 21 章的回归测试没有它跑不起来。
//
// 于是自己写个 20 行的 main，链上官方那份实现——语义与真的 FileCheck
// 完全一致（同一个库、同一个解析器），不是拿别的实现糊弄过去。
//
// 支持的开关只做了本教程用得到的两个：
//   FileCheck <check-file> --input-file <input>
// 其余开关一律忽略（真 FileCheck 的完整开关表在这份驱动里没必要复刻）。
//
// 构建：见 run-all.sh 里的 build_filecheck()（llvm-config 取旗标，
//       额外链 FileCheck 组件）。
// ============================================================

#include "llvm/FileCheck/FileCheck.h"
#include "llvm/Support/MemoryBuffer.h"
#include "llvm/Support/SourceMgr.h"
#include "llvm/Support/raw_ostream.h"

#include <cstdio>

using namespace llvm;

int main(int argc, const char **argv) {
  StringRef CheckFile, InputFile;

  for (int i = 1; i < argc; ++i) {
    StringRef A(argv[i]);
    if (A == "--input-file" || A == "-input-file") {
      if (i + 1 >= argc) {
        errs() << "FileCheck: --input-file 缺少参数\n";
        return 2;
      }
      InputFile = argv[++i];
    } else if (A.starts_with("--input-file=")) {
      InputFile = A.substr(A.find('=') + 1);
    } else if (A.starts_with("-") && A != "-") {
      // 教程用不到的开关：忽略（真 FileCheck 会认，这里没必要复刻整张表）
    } else if (CheckFile.empty()) {
      CheckFile = A;
    }
  }

  if (CheckFile.empty()) {
    errs() << "用法: FileCheck <check-file> --input-file <input>\n";
    return 2;
  }
  if (InputFile.empty())
    InputFile = "-";

  ErrorOr<std::unique_ptr<MemoryBuffer>> CB = MemoryBuffer::getFileOrSTDIN(CheckFile);
  if (!CB) {
    errs() << "FileCheck: 打不开断言文件 " << CheckFile << "\n";
    return 2;
  }
  ErrorOr<std::unique_ptr<MemoryBuffer>> IB = MemoryBuffer::getFileOrSTDIN(InputFile);
  if (!IB) {
    errs() << "FileCheck: 打不开输入文件 " << InputFile << "\n";
    return 2;
  }

  FileCheckRequest Req;
  Req.CheckPrefixes.push_back("CHECK");
  FileCheck FC(Req);

  SourceMgr SM;
  if (FC.readCheckFile(SM, (*CB)->getBuffer()))
    return 2;

  SmallVector<char, 4096> Canon;
  StringRef Buf = FC.CanonicalizeFile(**IB, Canon);
  if (!FC.checkInput(SM, Buf))
    return 1; // checkInput 返回 false = 断言不成立
  return 0;
}
