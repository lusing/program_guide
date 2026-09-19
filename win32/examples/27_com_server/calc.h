// calc.h — 宿主与 COM 服务器共享的接口定义（教学版：无 IDL 直接写）
#pragma once
#include <windows.h>
#include <unknwn.h>

// IID_ICalc = {1DBE71E1-2CA9-417E-AF41-2A2101510601}
static const IID IID_ICalc =
    { 0x1DBE71E1, 0x2CA9, 0x417E,
      { 0xAF, 0x41, 0x2A, 0x21, 0x01, 0x51, 0x06, 0x01 } };
// CLSID_Calc = {6B92FBEE-1E6D-4010-9AC0-5783E288F9C1}
static const CLSID CLSID_Calc =
    { 0x6B92FBEE, 0x1E6D, 0x4010,
      { 0x9A, 0xC0, 0x57, 0x83, 0xE2, 0x88, 0xF9, 0xC1 } };

// COM 接口 = 纯虚类 + IUnknown 头三个方法。vtable 布局即二进制契约。
interface ICalc : public IUnknown {
    virtual HRESULT STDMETHODCALLTYPE Add(int a, int b, int* result) = 0;
    virtual HRESULT STDMETHODCALLTYPE Sub(int a, int b, int* result) = 0;
};
