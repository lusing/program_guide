// shape.dll.cpp：MFC 扩展 DLL（extension DLL）—— 文件名 *.dll.cpp 约定为 DLL 目标。
// 扩展 DLL 直接共享宿主的 MFC（/MD + _AFXDLL），能把整个 MFC 类扔过模块边界：
// 导出的 CShape 族在 exe 里 new/delete、放进 CObArray 都成立。
//
// 三件套缺一不可：
//   1. DllMain 里 AfxInitExtensionModule —— 把本模块的类表/资源挂进 MFC 运行时
//   2. new CDynLinkLibrary(state, TRUE) —— 类表并进应用，RUNTIME_CLASS 才能按名找到
//   3. AFX_EXT_CLASS 导出类 —— shape.h 一份声明两边编译
//
// 书1 第15章 例84：动态链接 MFC 扩展库
#include "shape.h"
#include <afxext.h>   // AFX_EXTENSION_MODULE / CDynLinkLibrary

static AFX_EXTENSION_MODULE g_shapeState(FALSE);

void CRectShape::Draw(CDC* pDC, const CRect& rc) const {
    CBrush brush(m_clr);
    CPen pen(PS_SOLID, 2, RGB(40, 40, 40));
    CGdiObject* oldBrush = pDC->SelectObject(&brush);
    CGdiObject* oldPen = pDC->SelectObject(&pen);
    pDC->Rectangle(rc);
    pDC->SelectObject(oldBrush);
    pDC->SelectObject(oldPen);
}

CString CRectShape::Describe() const {
    CString s;
    s.Format(_T("CRectShape（扩展 DLL 导出，颜色 %06XH）"), (unsigned)m_clr);
    return s;
}

void CEllipseShape::Draw(CDC* pDC, const CRect& rc) const {
    CBrush brush(m_clr);
    CPen pen(PS_SOLID, 2, RGB(40, 40, 40));
    CGdiObject* oldBrush = pDC->SelectObject(&brush);
    CGdiObject* oldPen = pDC->SelectObject(&pen);
    pDC->Ellipse(rc);
    pDC->SelectObject(oldBrush);
    pDC->SelectObject(oldPen);
}

CString CEllipseShape::Describe() const {
    CString s;
    s.Format(_T("CEllipseShape（扩展 DLL 导出，颜色 %06XH）"), (unsigned)m_clr);
    return s;
}

extern "C" BOOL APIENTRY DllMain(HINSTANCE hInstance, DWORD reason, LPVOID) {
    if (reason == DLL_PROCESS_ATTACH) {
        if (!AfxInitExtensionModule(g_shapeState, hInstance))
            return FALSE;
        // TRUE = 把类表挂到应用链上：exe 里 CRuntimeClass::CreateObject 能按名
        // 创建这里的类 —— 没这一步，扩展 DLL 就只是个普通 DLL
        new CDynLinkLibrary(g_shapeState, TRUE);
        OutputDebugStringW(L"[shape.dll] 扩展模块已挂接\n");
    } else if (reason == DLL_PROCESS_DETACH) {
        OutputDebugStringW(L"[shape.dll] 扩展模块卸载\n");
    }
    return TRUE;
}
