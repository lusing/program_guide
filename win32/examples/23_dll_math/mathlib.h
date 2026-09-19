// mathlib.h — 同一个头同时服务导出方与导入方
#pragma once

#ifdef MATHLIB_EXPORTS            // DLL 工程定义它 → 我是导出方
#  define MATHLIB_API __declspec(dllexport)
#else                             // 使用方不定义 → 我是导入方
#  define MATHLIB_API __declspec(dllimport)
#endif

extern "C" MATHLIB_API int Math_Add(int a, int b);
extern "C" MATHLIB_API int Math_Mul(int a, int b);
extern "C" MATHLIB_API const wchar_t* Math_Version(void);
