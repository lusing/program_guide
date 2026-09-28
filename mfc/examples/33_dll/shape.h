// shape.h：MFC 扩展 DLL 导出类的共享声明。
// DLL 侧编译带 /D_AFXEXT（build.ps1 对 *.dll.cpp 自动加），AFX_EXT_CLASS = dllexport；
// exe 侧不带 _AFXEXT，同一个宏展开成 dllimport —— 一份声明两边用。
#pragma once
#include <afxwin.h>

// 抽象基类也整体导出：虚表和 RTTI 必须跨模块可见，
// 否则 exe 里 delete 基类指针、dynamic_cast 都会出事
class AFX_EXT_CLASS CShape : public CObject {
public:
    virtual void Draw(CDC* pDC, const CRect& rc) const = 0;
    virtual CString Describe() const = 0;
};

class AFX_EXT_CLASS CRectShape : public CShape {
public:
    CRectShape() = default;
    CRectShape(COLORREF clr) : m_clr(clr) {}
    void Draw(CDC* pDC, const CRect& rc) const override;
    CString Describe() const override;
    COLORREF m_clr = RGB(46, 108, 183);
};

class AFX_EXT_CLASS CEllipseShape : public CShape {
public:
    CEllipseShape() = default;
    CEllipseShape(COLORREF clr) : m_clr(clr) {}
    void Draw(CDC* pDC, const CRect& rc) const override;
    CString Describe() const override;
    COLORREF m_clr = RGB(191, 72, 63);
};
