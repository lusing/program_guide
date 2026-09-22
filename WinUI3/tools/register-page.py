#!/usr/bin/env python3
"""Register an existing gallery page into the project's four wiring points.

Usage: python register-page.py <project-dir> <PageClass> <nav-label> <nav-tag>

Edits (idempotent, fails loudly if a marker is missing):
  1. <Project>.vcxproj   : ClInclude / ClCompile / Midl / Page entries
  2. pch.h               : #include "<Page>.xaml.h"
  3. MainWindow.xaml     : NavigationViewItem under the marker comment
  4. MainWindow.xaml.cpp : NavigateTo branch before the marker comment
"""
import io
import re
import sys


def main() -> int:
    if len(sys.argv) != 5:
        print(__doc__)
        return 2
    proj_dir, page, label, tag = sys.argv[1:5]

    vcxproj = None
    import glob
    import os
    for f in glob.glob(os.path.join(proj_dir, "*.vcxproj")):
        vcxproj = f
        break
    if not vcxproj:
        print(f"no .vcxproj under {proj_dir}")
        return 1

    def edit(path, reps):
        s = io.open(path, encoding="utf-8").read()
        orig = s
        for old, new in reps:
            if new in s:
                continue  # already registered (idempotent)
            if old not in s:
                print(f"marker not found in {path}:\n  {old}")
                return False
            s = s.replace(old, new, 1)
        if s != orig:
            io.open(path, "w", encoding="utf-8", newline="\n").write(s)
        return True

    ns = re.search(r"<RootNamespace>([^<]+)</RootNamespace>",
                   io.open(vcxproj, encoding="utf-8").read()).group(1)

    if not edit(vcxproj, [
        (f'    <ClInclude Include="pch.h" />',
         f'    <ClInclude Include="pch.h" />\n    <ClInclude Include="{page}.xaml.h" />'),
        (f'    <ClCompile Include="App.xaml.cpp" />',
         f'    <ClCompile Include="App.xaml.cpp" />\n    <ClCompile Include="{page}.xaml.cpp" />'),
        (f'    <Midl Include="App.idl" />',
         f'    <Midl Include="App.idl" />\n    <Midl Include="{page}.idl" />'),
        (f'    <Page Include="MainWindow.xaml" />',
         f'    <Page Include="MainWindow.xaml" />\n    <Page Include="{page}.xaml" />'),
    ]):
        return 1

    pch = os.path.join(proj_dir, "pch.h")
    s = io.open(pch, encoding="utf-8").read()
    inc = f'#include "{page}.xaml.h"'
    if inc not in s:
        anchor = f'#include "{ns}.'
        # append after the last #include "<Something>.xaml.h" line
        lines = s.splitlines(keepends=True)
        last = max(i for i, l in enumerate(lines) if re.match(r'#include "\w+\.xaml\.h"', l))
        lines.insert(last + 1, inc + "\n")
        io.open(pch, "w", encoding="utf-8", newline="\n").write("".join(lines))

    mw_xaml = os.path.join(proj_dir, "MainWindow.xaml")
    if not edit(mw_xaml, [
        ("            <!-- 每章任务在此追加一个导航项 -->",
         f'            <NavigationViewItem Content="{label}" Tag="{tag}"/>\n'
         f'            <!-- 每章任务在此追加一个导航项 -->'),
    ]):
        return 1

    mw_cpp = os.path.join(proj_dir, "MainWindow.xaml.cpp")
    if not edit(mw_cpp, [
        ("        // 每章任务追加分支",
         f'        if (tag == L"{tag}") ContentFrame().Navigate(xaml_typename<{ns}::{page}>());\n'
         f"        // 每章任务追加分支"),
    ]):
        return 1

    print(f"registered {page} (nav '{label}', tag '{tag}') in {proj_dir}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
