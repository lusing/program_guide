// Lean compiler output
// Module: Lean4Tutorial.Examples.PatternMatching.EquationCompiler
// Imports: public import Init public meta import Init
#include <lean/lean.h>
#if defined(__clang__)
#pragma clang diagnostic ignored "-Wunused-parameter"
#pragma clang diagnostic ignored "-Wunused-label"
#elif defined(__GNUC__) && !defined(__CLANG__)
#pragma GCC diagnostic ignored "-Wunused-parameter"
#pragma GCC diagnostic ignored "-Wunused-label"
#pragma GCC diagnostic ignored "-Wunused-but-set-variable"
#endif
#ifdef __cplusplus
extern "C" {
#endif
uint8_t lean_nat_dec_eq(lean_object*, lean_object*);
lean_object* lean_nat_sub(lean_object*, lean_object*);
lean_object* lean_nat_add(lean_object*, lean_object*);
lean_object* lean_nat_mul(lean_object*, lean_object*);
uint8_t lean_nat_dec_le(lean_object*, lean_object*);
lean_object* lean_nat_mod(lean_object*, lean_object*);
lean_object* l_List_appendTR___redArg(lean_object*, lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_factorial__match(lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_factorial__match___boxed(lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_factorial(lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_factorial___boxed(lean_object*);
static lean_once_cell_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_fac__0___closed__0_once = LEAN_ONCE_CELL_INITIALIZER;
static lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_fac__0___closed__0;
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_fac__0;
static lean_once_cell_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_fac__1___closed__0_once = LEAN_ONCE_CELL_INITIALIZER;
static lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_fac__1___closed__0;
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_fac__1;
static lean_once_cell_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_fac__5___closed__0_once = LEAN_ONCE_CELL_INITIALIZER;
static lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_fac__5___closed__0;
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_fac__5;
static lean_once_cell_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_fac__10___closed__0_once = LEAN_ONCE_CELL_INITIALIZER;
static lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_fac__10___closed__0;
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_fac__10;
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_fib(lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_fib___boxed(lean_object*);
static lean_once_cell_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_fib__0___closed__0_once = LEAN_ONCE_CELL_INITIALIZER;
static lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_fib__0___closed__0;
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_fib__0;
static lean_once_cell_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_fib__1___closed__0_once = LEAN_ONCE_CELL_INITIALIZER;
static lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_fib__1___closed__0;
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_fib__1;
static lean_once_cell_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_fib__2___closed__0_once = LEAN_ONCE_CELL_INITIALIZER;
static lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_fib__2___closed__0;
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_fib__2;
static lean_once_cell_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_fib__5___closed__0_once = LEAN_ONCE_CELL_INITIALIZER;
static lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_fib__5___closed__0;
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_fib__5;
static lean_once_cell_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_fib__10___closed__0_once = LEAN_ONCE_CELL_INITIALIZER;
static lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_fib__10___closed__0;
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_fib__10;
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_add(lean_object*, lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_add___boxed(lean_object*, lean_object*);
static lean_once_cell_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_add__3__4___closed__0_once = LEAN_ONCE_CELL_INITIALIZER;
static lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_add__3__4___closed__0;
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_add__3__4;
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_mul(lean_object*, lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_mul___boxed(lean_object*, lean_object*);
static lean_once_cell_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_mul__3__4___closed__0_once = LEAN_ONCE_CELL_INITIALIZER;
static lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_mul__3__4___closed__0;
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_mul__3__4;
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_power(lean_object*, lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_power___boxed(lean_object*, lean_object*);
static lean_once_cell_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_power__2__10___closed__0_once = LEAN_ONCE_CELL_INITIALIZER;
static lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_power__2__10___closed__0;
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_power__2__10;
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_length___redArg(lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_length___redArg___boxed(lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_length(lean_object*, lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_length___boxed(lean_object*, lean_object*);
static const lean_ctor_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_len__example___closed__0_value = {.m_header = {.m_rc = 0, .m_cs_sz = sizeof(lean_ctor_object) + sizeof(void*)*2 + 0, .m_other = 2, .m_tag = 1}, .m_objs = {((lean_object*)(((size_t)(5) << 1) | 1)),((lean_object*)(((size_t)(0) << 1) | 1))}};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_len__example___closed__0 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_len__example___closed__0_value;
static const lean_ctor_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_len__example___closed__1_value = {.m_header = {.m_rc = 0, .m_cs_sz = sizeof(lean_ctor_object) + sizeof(void*)*2 + 0, .m_other = 2, .m_tag = 1}, .m_objs = {((lean_object*)(((size_t)(4) << 1) | 1)),((lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_len__example___closed__0_value)}};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_len__example___closed__1 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_len__example___closed__1_value;
static const lean_ctor_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_len__example___closed__2_value = {.m_header = {.m_rc = 0, .m_cs_sz = sizeof(lean_ctor_object) + sizeof(void*)*2 + 0, .m_other = 2, .m_tag = 1}, .m_objs = {((lean_object*)(((size_t)(3) << 1) | 1)),((lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_len__example___closed__1_value)}};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_len__example___closed__2 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_len__example___closed__2_value;
static const lean_ctor_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_len__example___closed__3_value = {.m_header = {.m_rc = 0, .m_cs_sz = sizeof(lean_ctor_object) + sizeof(void*)*2 + 0, .m_other = 2, .m_tag = 1}, .m_objs = {((lean_object*)(((size_t)(2) << 1) | 1)),((lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_len__example___closed__2_value)}};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_len__example___closed__3 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_len__example___closed__3_value;
static const lean_ctor_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_len__example___closed__4_value = {.m_header = {.m_rc = 0, .m_cs_sz = sizeof(lean_ctor_object) + sizeof(void*)*2 + 0, .m_other = 2, .m_tag = 1}, .m_objs = {((lean_object*)(((size_t)(1) << 1) | 1)),((lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_len__example___closed__3_value)}};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_len__example___closed__4 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_len__example___closed__4_value;
static lean_once_cell_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_len__example___closed__5_once = LEAN_ONCE_CELL_INITIALIZER;
static lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_len__example___closed__5;
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_len__example;
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_append___redArg(lean_object*, lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_append___redArg___boxed(lean_object*, lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_append(lean_object*, lean_object*, lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_append___boxed(lean_object*, lean_object*, lean_object*);
static const lean_ctor_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_append__example___closed__0_value = {.m_header = {.m_rc = 0, .m_cs_sz = sizeof(lean_ctor_object) + sizeof(void*)*2 + 0, .m_other = 2, .m_tag = 1}, .m_objs = {((lean_object*)(((size_t)(2) << 1) | 1)),((lean_object*)(((size_t)(0) << 1) | 1))}};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_append__example___closed__0 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_append__example___closed__0_value;
static const lean_ctor_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_append__example___closed__1_value = {.m_header = {.m_rc = 0, .m_cs_sz = sizeof(lean_ctor_object) + sizeof(void*)*2 + 0, .m_other = 2, .m_tag = 1}, .m_objs = {((lean_object*)(((size_t)(1) << 1) | 1)),((lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_append__example___closed__0_value)}};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_append__example___closed__1 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_append__example___closed__1_value;
static lean_once_cell_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_append__example___closed__2_once = LEAN_ONCE_CELL_INITIALIZER;
static lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_append__example___closed__2;
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_append__example;
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_reverse___redArg(lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_reverse(lean_object*, lean_object*);
static const lean_ctor_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_reverse__example___closed__0_value = {.m_header = {.m_rc = 0, .m_cs_sz = sizeof(lean_ctor_object) + sizeof(void*)*2 + 0, .m_other = 2, .m_tag = 1}, .m_objs = {((lean_object*)(((size_t)(3) << 1) | 1)),((lean_object*)(((size_t)(0) << 1) | 1))}};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_reverse__example___closed__0 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_reverse__example___closed__0_value;
static const lean_ctor_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_reverse__example___closed__1_value = {.m_header = {.m_rc = 0, .m_cs_sz = sizeof(lean_ctor_object) + sizeof(void*)*2 + 0, .m_other = 2, .m_tag = 1}, .m_objs = {((lean_object*)(((size_t)(2) << 1) | 1)),((lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_reverse__example___closed__0_value)}};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_reverse__example___closed__1 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_reverse__example___closed__1_value;
static const lean_ctor_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_reverse__example___closed__2_value = {.m_header = {.m_rc = 0, .m_cs_sz = sizeof(lean_ctor_object) + sizeof(void*)*2 + 0, .m_other = 2, .m_tag = 1}, .m_objs = {((lean_object*)(((size_t)(1) << 1) | 1)),((lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_reverse__example___closed__1_value)}};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_reverse__example___closed__2 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_reverse__example___closed__2_value;
static lean_once_cell_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_reverse__example___closed__3_once = LEAN_ONCE_CELL_INITIALIZER;
static lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_reverse__example___closed__3;
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_reverse__example;
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_zip___redArg(lean_object*, lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_zip(lean_object*, lean_object*, lean_object*, lean_object*);
static const lean_string_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_zip__example___closed__0_value = {.m_header = {.m_rc = 0, .m_cs_sz = 0, .m_other = 0, .m_tag = 249}, .m_size = 2, .m_capacity = 2, .m_length = 1, .m_data = "a"};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_zip__example___closed__0 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_zip__example___closed__0_value;
static const lean_string_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_zip__example___closed__1_value = {.m_header = {.m_rc = 0, .m_cs_sz = 0, .m_other = 0, .m_tag = 249}, .m_size = 2, .m_capacity = 2, .m_length = 1, .m_data = "b"};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_zip__example___closed__1 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_zip__example___closed__1_value;
static const lean_string_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_zip__example___closed__2_value = {.m_header = {.m_rc = 0, .m_cs_sz = 0, .m_other = 0, .m_tag = 249}, .m_size = 2, .m_capacity = 2, .m_length = 1, .m_data = "c"};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_zip__example___closed__2 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_zip__example___closed__2_value;
static const lean_ctor_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_zip__example___closed__3_value = {.m_header = {.m_rc = 0, .m_cs_sz = sizeof(lean_ctor_object) + sizeof(void*)*2 + 0, .m_other = 2, .m_tag = 1}, .m_objs = {((lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_zip__example___closed__2_value),((lean_object*)(((size_t)(0) << 1) | 1))}};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_zip__example___closed__3 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_zip__example___closed__3_value;
static const lean_ctor_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_zip__example___closed__4_value = {.m_header = {.m_rc = 0, .m_cs_sz = sizeof(lean_ctor_object) + sizeof(void*)*2 + 0, .m_other = 2, .m_tag = 1}, .m_objs = {((lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_zip__example___closed__1_value),((lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_zip__example___closed__3_value)}};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_zip__example___closed__4 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_zip__example___closed__4_value;
static const lean_ctor_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_zip__example___closed__5_value = {.m_header = {.m_rc = 0, .m_cs_sz = sizeof(lean_ctor_object) + sizeof(void*)*2 + 0, .m_other = 2, .m_tag = 1}, .m_objs = {((lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_zip__example___closed__0_value),((lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_zip__example___closed__4_value)}};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_zip__example___closed__5 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_zip__example___closed__5_value;
static lean_once_cell_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_zip__example___closed__6_once = LEAN_ONCE_CELL_INITIALIZER;
static lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_zip__example___closed__6;
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_zip__example;
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_take___redArg(lean_object*, lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_take___redArg___boxed(lean_object*, lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_take(lean_object*, lean_object*, lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_take___boxed(lean_object*, lean_object*, lean_object*);
static lean_once_cell_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_take__3___closed__0_once = LEAN_ONCE_CELL_INITIALIZER;
static lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_take__3___closed__0;
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_take__3;
static lean_once_cell_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_take__10___closed__0_once = LEAN_ONCE_CELL_INITIALIZER;
static lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_take__10___closed__0;
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_take__10;
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_drop___redArg(lean_object*, lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_drop___redArg___boxed(lean_object*, lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_drop(lean_object*, lean_object*, lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_drop___boxed(lean_object*, lean_object*, lean_object*);
static lean_once_cell_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_drop__2___closed__0_once = LEAN_ONCE_CELL_INITIALIZER;
static lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_drop__2___closed__0;
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_drop__2;
LEAN_EXPORT uint8_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_and(uint8_t, uint8_t);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_and___boxed(lean_object*, lean_object*);
LEAN_EXPORT uint8_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_or(uint8_t, uint8_t);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_or___boxed(lean_object*, lean_object*);
LEAN_EXPORT uint8_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_xor(uint8_t, uint8_t);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_xor___boxed(lean_object*, lean_object*);
LEAN_EXPORT uint8_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_leq(lean_object*, lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_leq___boxed(lean_object*, lean_object*);
static lean_once_cell_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_leq__example1___closed__0_once = LEAN_ONCE_CELL_INITIALIZER;
static uint8_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_leq__example1___closed__0;
LEAN_EXPORT uint8_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_leq__example1;
static lean_once_cell_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_leq__example2___closed__0_once = LEAN_ONCE_CELL_INITIALIZER;
static uint8_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_leq__example2___closed__0;
LEAN_EXPORT uint8_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_leq__example2;
static lean_once_cell_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_leq__example3___closed__0_once = LEAN_ONCE_CELL_INITIALIZER;
static uint8_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_leq__example3___closed__0;
LEAN_EXPORT uint8_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_leq__example3;
LEAN_EXPORT uint8_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_eq__nat(lean_object*, lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_eq__nat___boxed(lean_object*, lean_object*);
static lean_once_cell_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_eq__example1___closed__0_once = LEAN_ONCE_CELL_INITIALIZER;
static uint8_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_eq__example1___closed__0;
LEAN_EXPORT uint8_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_eq__example1;
static lean_once_cell_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_eq__example2___closed__0_once = LEAN_ONCE_CELL_INITIALIZER;
static uint8_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_eq__example2___closed__0;
LEAN_EXPORT uint8_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_eq__example2;
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_gcd(lean_object*, lean_object*);
static lean_once_cell_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_gcd__example1___closed__0_once = LEAN_ONCE_CELL_INITIALIZER;
static lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_gcd__example1___closed__0;
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_gcd__example1;
static lean_once_cell_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_gcd__example2___closed__0_once = LEAN_ONCE_CELL_INITIALIZER;
static lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_gcd__example2___closed__0;
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_gcd__example2;
static lean_once_cell_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_gcd__example3___closed__0_once = LEAN_ONCE_CELL_INITIALIZER;
static lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_gcd__example3___closed__0;
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_gcd__example3;
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_insert(lean_object*, lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_insertionSort(lean_object*);
static const lean_ctor_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_sort__example___closed__0_value = {.m_header = {.m_rc = 0, .m_cs_sz = sizeof(lean_ctor_object) + sizeof(void*)*2 + 0, .m_other = 2, .m_tag = 1}, .m_objs = {((lean_object*)(((size_t)(6) << 1) | 1)),((lean_object*)(((size_t)(0) << 1) | 1))}};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_sort__example___closed__0 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_sort__example___closed__0_value;
static const lean_ctor_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_sort__example___closed__1_value = {.m_header = {.m_rc = 0, .m_cs_sz = sizeof(lean_ctor_object) + sizeof(void*)*2 + 0, .m_other = 2, .m_tag = 1}, .m_objs = {((lean_object*)(((size_t)(2) << 1) | 1)),((lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_sort__example___closed__0_value)}};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_sort__example___closed__1 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_sort__example___closed__1_value;
static const lean_ctor_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_sort__example___closed__2_value = {.m_header = {.m_rc = 0, .m_cs_sz = sizeof(lean_ctor_object) + sizeof(void*)*2 + 0, .m_other = 2, .m_tag = 1}, .m_objs = {((lean_object*)(((size_t)(9) << 1) | 1)),((lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_sort__example___closed__1_value)}};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_sort__example___closed__2 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_sort__example___closed__2_value;
static const lean_ctor_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_sort__example___closed__3_value = {.m_header = {.m_rc = 0, .m_cs_sz = sizeof(lean_ctor_object) + sizeof(void*)*2 + 0, .m_other = 2, .m_tag = 1}, .m_objs = {((lean_object*)(((size_t)(5) << 1) | 1)),((lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_sort__example___closed__2_value)}};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_sort__example___closed__3 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_sort__example___closed__3_value;
static const lean_ctor_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_sort__example___closed__4_value = {.m_header = {.m_rc = 0, .m_cs_sz = sizeof(lean_ctor_object) + sizeof(void*)*2 + 0, .m_other = 2, .m_tag = 1}, .m_objs = {((lean_object*)(((size_t)(1) << 1) | 1)),((lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_sort__example___closed__3_value)}};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_sort__example___closed__4 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_sort__example___closed__4_value;
static const lean_ctor_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_sort__example___closed__5_value = {.m_header = {.m_rc = 0, .m_cs_sz = sizeof(lean_ctor_object) + sizeof(void*)*2 + 0, .m_other = 2, .m_tag = 1}, .m_objs = {((lean_object*)(((size_t)(4) << 1) | 1)),((lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_sort__example___closed__4_value)}};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_sort__example___closed__5 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_sort__example___closed__5_value;
static const lean_ctor_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_sort__example___closed__6_value = {.m_header = {.m_rc = 0, .m_cs_sz = sizeof(lean_ctor_object) + sizeof(void*)*2 + 0, .m_other = 2, .m_tag = 1}, .m_objs = {((lean_object*)(((size_t)(1) << 1) | 1)),((lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_sort__example___closed__5_value)}};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_sort__example___closed__6 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_sort__example___closed__6_value;
static const lean_ctor_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_sort__example___closed__7_value = {.m_header = {.m_rc = 0, .m_cs_sz = sizeof(lean_ctor_object) + sizeof(void*)*2 + 0, .m_other = 2, .m_tag = 1}, .m_objs = {((lean_object*)(((size_t)(3) << 1) | 1)),((lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_sort__example___closed__6_value)}};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_sort__example___closed__7 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_sort__example___closed__7_value;
static lean_once_cell_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_sort__example___closed__8_once = LEAN_ONCE_CELL_INITIALIZER;
static lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_sort__example___closed__8;
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_sort__example;
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_nth___redArg(lean_object*, lean_object*, lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_nth___redArg___boxed(lean_object*, lean_object*, lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_nth(lean_object*, lean_object*, lean_object*, lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_nth___boxed(lean_object*, lean_object*, lean_object*, lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_rev_go___redArg(lean_object*, lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_rev_go(lean_object*, lean_object*, lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_rev___redArg(lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_rev(lean_object*, lean_object*);
static lean_once_cell_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_rev__example___closed__0_once = LEAN_ONCE_CELL_INITIALIZER;
static lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_rev__example___closed__0;
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_rev__example;
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_factorial__match(lean_object* v_n_1_){
_start:
{
lean_object* v_zero_2_; uint8_t v_isZero_3_; 
v_zero_2_ = lean_unsigned_to_nat(0u);
v_isZero_3_ = lean_nat_dec_eq(v_n_1_, v_zero_2_);
if (v_isZero_3_ == 1)
{
lean_object* v___x_4_; 
v___x_4_ = lean_unsigned_to_nat(1u);
return v___x_4_;
}
else
{
lean_object* v_one_5_; lean_object* v_n_6_; lean_object* v___x_7_; lean_object* v___x_8_; lean_object* v___x_9_; 
v_one_5_ = lean_unsigned_to_nat(1u);
v_n_6_ = lean_nat_sub(v_n_1_, v_one_5_);
v___x_7_ = lean_nat_add(v_n_6_, v_one_5_);
v___x_8_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_factorial__match(v_n_6_);
lean_dec(v_n_6_);
v___x_9_ = lean_nat_mul(v___x_7_, v___x_8_);
lean_dec(v___x_8_);
lean_dec(v___x_7_);
return v___x_9_;
}
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_factorial__match___boxed(lean_object* v_n_10_){
_start:
{
lean_object* v_res_11_; 
v_res_11_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_factorial__match(v_n_10_);
lean_dec(v_n_10_);
return v_res_11_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_factorial(lean_object* v_x_12_){
_start:
{
lean_object* v_zero_13_; uint8_t v_isZero_14_; 
v_zero_13_ = lean_unsigned_to_nat(0u);
v_isZero_14_ = lean_nat_dec_eq(v_x_12_, v_zero_13_);
if (v_isZero_14_ == 1)
{
lean_object* v___x_15_; 
v___x_15_ = lean_unsigned_to_nat(1u);
return v___x_15_;
}
else
{
lean_object* v_one_16_; lean_object* v_n_17_; lean_object* v___x_18_; lean_object* v___x_19_; lean_object* v___x_20_; 
v_one_16_ = lean_unsigned_to_nat(1u);
v_n_17_ = lean_nat_sub(v_x_12_, v_one_16_);
v___x_18_ = lean_nat_add(v_n_17_, v_one_16_);
v___x_19_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_factorial(v_n_17_);
lean_dec(v_n_17_);
v___x_20_ = lean_nat_mul(v___x_18_, v___x_19_);
lean_dec(v___x_19_);
lean_dec(v___x_18_);
return v___x_20_;
}
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_factorial___boxed(lean_object* v_x_21_){
_start:
{
lean_object* v_res_22_; 
v_res_22_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_factorial(v_x_21_);
lean_dec(v_x_21_);
return v_res_22_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_fac__0___closed__0(void){
_start:
{
lean_object* v___x_23_; lean_object* v___x_24_; 
v___x_23_ = lean_unsigned_to_nat(0u);
v___x_24_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_factorial(v___x_23_);
return v___x_24_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_fac__0(void){
_start:
{
lean_object* v___x_25_; 
v___x_25_ = lean_obj_once(&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_fac__0___closed__0, &lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_fac__0___closed__0_once, _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_fac__0___closed__0);
return v___x_25_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_fac__1___closed__0(void){
_start:
{
lean_object* v___x_26_; lean_object* v___x_27_; 
v___x_26_ = lean_unsigned_to_nat(1u);
v___x_27_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_factorial(v___x_26_);
return v___x_27_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_fac__1(void){
_start:
{
lean_object* v___x_28_; 
v___x_28_ = lean_obj_once(&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_fac__1___closed__0, &lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_fac__1___closed__0_once, _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_fac__1___closed__0);
return v___x_28_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_fac__5___closed__0(void){
_start:
{
lean_object* v___x_29_; lean_object* v___x_30_; 
v___x_29_ = lean_unsigned_to_nat(5u);
v___x_30_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_factorial(v___x_29_);
return v___x_30_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_fac__5(void){
_start:
{
lean_object* v___x_31_; 
v___x_31_ = lean_obj_once(&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_fac__5___closed__0, &lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_fac__5___closed__0_once, _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_fac__5___closed__0);
return v___x_31_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_fac__10___closed__0(void){
_start:
{
lean_object* v___x_32_; lean_object* v___x_33_; 
v___x_32_ = lean_unsigned_to_nat(10u);
v___x_33_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_factorial(v___x_32_);
return v___x_33_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_fac__10(void){
_start:
{
lean_object* v___x_34_; 
v___x_34_ = lean_obj_once(&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_fac__10___closed__0, &lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_fac__10___closed__0_once, _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_fac__10___closed__0);
return v___x_34_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_fib(lean_object* v_x_35_){
_start:
{
lean_object* v_zero_36_; uint8_t v_isZero_37_; 
v_zero_36_ = lean_unsigned_to_nat(0u);
v_isZero_37_ = lean_nat_dec_eq(v_x_35_, v_zero_36_);
if (v_isZero_37_ == 1)
{
return v_zero_36_;
}
else
{
lean_object* v_one_38_; lean_object* v_n_39_; uint8_t v_isZero_40_; 
v_one_38_ = lean_unsigned_to_nat(1u);
v_n_39_ = lean_nat_sub(v_x_35_, v_one_38_);
v_isZero_40_ = lean_nat_dec_eq(v_n_39_, v_zero_36_);
if (v_isZero_40_ == 1)
{
lean_dec(v_n_39_);
return v_one_38_;
}
else
{
lean_object* v_n_41_; lean_object* v___x_42_; lean_object* v___x_43_; lean_object* v___x_44_; lean_object* v___x_45_; 
v_n_41_ = lean_nat_sub(v_n_39_, v_one_38_);
lean_dec(v_n_39_);
v___x_42_ = lean_nat_add(v_n_41_, v_one_38_);
v___x_43_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_fib(v___x_42_);
lean_dec(v___x_42_);
v___x_44_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_fib(v_n_41_);
lean_dec(v_n_41_);
v___x_45_ = lean_nat_add(v___x_43_, v___x_44_);
lean_dec(v___x_44_);
lean_dec(v___x_43_);
return v___x_45_;
}
}
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_fib___boxed(lean_object* v_x_46_){
_start:
{
lean_object* v_res_47_; 
v_res_47_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_fib(v_x_46_);
lean_dec(v_x_46_);
return v_res_47_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_fib__0___closed__0(void){
_start:
{
lean_object* v___x_48_; lean_object* v___x_49_; 
v___x_48_ = lean_unsigned_to_nat(0u);
v___x_49_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_fib(v___x_48_);
return v___x_49_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_fib__0(void){
_start:
{
lean_object* v___x_50_; 
v___x_50_ = lean_obj_once(&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_fib__0___closed__0, &lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_fib__0___closed__0_once, _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_fib__0___closed__0);
return v___x_50_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_fib__1___closed__0(void){
_start:
{
lean_object* v___x_51_; lean_object* v___x_52_; 
v___x_51_ = lean_unsigned_to_nat(1u);
v___x_52_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_fib(v___x_51_);
return v___x_52_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_fib__1(void){
_start:
{
lean_object* v___x_53_; 
v___x_53_ = lean_obj_once(&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_fib__1___closed__0, &lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_fib__1___closed__0_once, _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_fib__1___closed__0);
return v___x_53_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_fib__2___closed__0(void){
_start:
{
lean_object* v___x_54_; lean_object* v___x_55_; 
v___x_54_ = lean_unsigned_to_nat(2u);
v___x_55_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_fib(v___x_54_);
return v___x_55_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_fib__2(void){
_start:
{
lean_object* v___x_56_; 
v___x_56_ = lean_obj_once(&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_fib__2___closed__0, &lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_fib__2___closed__0_once, _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_fib__2___closed__0);
return v___x_56_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_fib__5___closed__0(void){
_start:
{
lean_object* v___x_57_; lean_object* v___x_58_; 
v___x_57_ = lean_unsigned_to_nat(5u);
v___x_58_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_fib(v___x_57_);
return v___x_58_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_fib__5(void){
_start:
{
lean_object* v___x_59_; 
v___x_59_ = lean_obj_once(&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_fib__5___closed__0, &lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_fib__5___closed__0_once, _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_fib__5___closed__0);
return v___x_59_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_fib__10___closed__0(void){
_start:
{
lean_object* v___x_60_; lean_object* v___x_61_; 
v___x_60_ = lean_unsigned_to_nat(10u);
v___x_61_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_fib(v___x_60_);
return v___x_61_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_fib__10(void){
_start:
{
lean_object* v___x_62_; 
v___x_62_ = lean_obj_once(&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_fib__10___closed__0, &lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_fib__10___closed__0_once, _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_fib__10___closed__0);
return v___x_62_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_add(lean_object* v_x_63_, lean_object* v_x_64_){
_start:
{
lean_object* v_zero_65_; uint8_t v_isZero_66_; 
v_zero_65_ = lean_unsigned_to_nat(0u);
v_isZero_66_ = lean_nat_dec_eq(v_x_64_, v_zero_65_);
if (v_isZero_66_ == 1)
{
lean_inc(v_x_63_);
return v_x_63_;
}
else
{
lean_object* v_one_67_; lean_object* v_n_68_; lean_object* v___x_69_; lean_object* v___x_70_; 
v_one_67_ = lean_unsigned_to_nat(1u);
v_n_68_ = lean_nat_sub(v_x_64_, v_one_67_);
v___x_69_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_add(v_x_63_, v_n_68_);
lean_dec(v_n_68_);
v___x_70_ = lean_nat_add(v___x_69_, v_one_67_);
lean_dec(v___x_69_);
return v___x_70_;
}
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_add___boxed(lean_object* v_x_71_, lean_object* v_x_72_){
_start:
{
lean_object* v_res_73_; 
v_res_73_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_add(v_x_71_, v_x_72_);
lean_dec(v_x_72_);
lean_dec(v_x_71_);
return v_res_73_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_add__3__4___closed__0(void){
_start:
{
lean_object* v___x_74_; lean_object* v___x_75_; lean_object* v___x_76_; 
v___x_74_ = lean_unsigned_to_nat(4u);
v___x_75_ = lean_unsigned_to_nat(3u);
v___x_76_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_add(v___x_75_, v___x_74_);
return v___x_76_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_add__3__4(void){
_start:
{
lean_object* v___x_77_; 
v___x_77_ = lean_obj_once(&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_add__3__4___closed__0, &lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_add__3__4___closed__0_once, _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_add__3__4___closed__0);
return v___x_77_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_mul(lean_object* v_x_78_, lean_object* v_x_79_){
_start:
{
lean_object* v_zero_80_; uint8_t v_isZero_81_; 
v_zero_80_ = lean_unsigned_to_nat(0u);
v_isZero_81_ = lean_nat_dec_eq(v_x_79_, v_zero_80_);
if (v_isZero_81_ == 1)
{
return v_zero_80_;
}
else
{
lean_object* v_one_82_; lean_object* v_n_83_; lean_object* v___x_84_; lean_object* v___x_85_; 
v_one_82_ = lean_unsigned_to_nat(1u);
v_n_83_ = lean_nat_sub(v_x_79_, v_one_82_);
v___x_84_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_mul(v_x_78_, v_n_83_);
lean_dec(v_n_83_);
v___x_85_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_add(v___x_84_, v_x_78_);
lean_dec(v___x_84_);
return v___x_85_;
}
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_mul___boxed(lean_object* v_x_86_, lean_object* v_x_87_){
_start:
{
lean_object* v_res_88_; 
v_res_88_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_mul(v_x_86_, v_x_87_);
lean_dec(v_x_87_);
lean_dec(v_x_86_);
return v_res_88_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_mul__3__4___closed__0(void){
_start:
{
lean_object* v___x_89_; lean_object* v___x_90_; lean_object* v___x_91_; 
v___x_89_ = lean_unsigned_to_nat(4u);
v___x_90_ = lean_unsigned_to_nat(3u);
v___x_91_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_mul(v___x_90_, v___x_89_);
return v___x_91_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_mul__3__4(void){
_start:
{
lean_object* v___x_92_; 
v___x_92_ = lean_obj_once(&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_mul__3__4___closed__0, &lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_mul__3__4___closed__0_once, _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_mul__3__4___closed__0);
return v___x_92_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_power(lean_object* v_x_93_, lean_object* v_x_94_){
_start:
{
lean_object* v_zero_95_; uint8_t v_isZero_96_; 
v_zero_95_ = lean_unsigned_to_nat(0u);
v_isZero_96_ = lean_nat_dec_eq(v_x_94_, v_zero_95_);
if (v_isZero_96_ == 1)
{
lean_object* v___x_97_; 
v___x_97_ = lean_unsigned_to_nat(1u);
return v___x_97_;
}
else
{
lean_object* v_one_98_; lean_object* v_n_99_; lean_object* v___x_100_; lean_object* v___x_101_; 
v_one_98_ = lean_unsigned_to_nat(1u);
v_n_99_ = lean_nat_sub(v_x_94_, v_one_98_);
v___x_100_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_power(v_x_93_, v_n_99_);
lean_dec(v_n_99_);
v___x_101_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_mul(v___x_100_, v_x_93_);
lean_dec(v___x_100_);
return v___x_101_;
}
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_power___boxed(lean_object* v_x_102_, lean_object* v_x_103_){
_start:
{
lean_object* v_res_104_; 
v_res_104_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_power(v_x_102_, v_x_103_);
lean_dec(v_x_103_);
lean_dec(v_x_102_);
return v_res_104_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_power__2__10___closed__0(void){
_start:
{
lean_object* v___x_105_; lean_object* v___x_106_; lean_object* v___x_107_; 
v___x_105_ = lean_unsigned_to_nat(10u);
v___x_106_ = lean_unsigned_to_nat(2u);
v___x_107_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_power(v___x_106_, v___x_105_);
return v___x_107_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_power__2__10(void){
_start:
{
lean_object* v___x_108_; 
v___x_108_ = lean_obj_once(&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_power__2__10___closed__0, &lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_power__2__10___closed__0_once, _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_power__2__10___closed__0);
return v___x_108_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_length___redArg(lean_object* v_x_109_){
_start:
{
if (lean_obj_tag(v_x_109_) == 0)
{
lean_object* v___x_110_; 
v___x_110_ = lean_unsigned_to_nat(0u);
return v___x_110_;
}
else
{
lean_object* v_tail_111_; lean_object* v___x_112_; lean_object* v___x_113_; lean_object* v___x_114_; 
v_tail_111_ = lean_ctor_get(v_x_109_, 1);
v___x_112_ = lean_unsigned_to_nat(1u);
v___x_113_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_length___redArg(v_tail_111_);
v___x_114_ = lean_nat_add(v___x_112_, v___x_113_);
lean_dec(v___x_113_);
return v___x_114_;
}
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_length___redArg___boxed(lean_object* v_x_115_){
_start:
{
lean_object* v_res_116_; 
v_res_116_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_length___redArg(v_x_115_);
lean_dec(v_x_115_);
return v_res_116_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_length(lean_object* v_00_u03b1_117_, lean_object* v_x_118_){
_start:
{
lean_object* v___x_119_; 
v___x_119_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_length___redArg(v_x_118_);
return v___x_119_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_length___boxed(lean_object* v_00_u03b1_120_, lean_object* v_x_121_){
_start:
{
lean_object* v_res_122_; 
v_res_122_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_length(v_00_u03b1_120_, v_x_121_);
lean_dec(v_x_121_);
return v_res_122_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_len__example___closed__5(void){
_start:
{
lean_object* v___x_138_; lean_object* v___x_139_; 
v___x_138_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_len__example___closed__4));
v___x_139_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_length___redArg(v___x_138_);
return v___x_139_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_len__example(void){
_start:
{
lean_object* v___x_140_; 
v___x_140_ = lean_obj_once(&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_len__example___closed__5, &lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_len__example___closed__5_once, _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_len__example___closed__5);
return v___x_140_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_append___redArg(lean_object* v_x_141_, lean_object* v_x_142_){
_start:
{
if (lean_obj_tag(v_x_141_) == 0)
{
lean_inc(v_x_142_);
return v_x_142_;
}
else
{
lean_object* v_head_143_; lean_object* v_tail_144_; lean_object* v___x_146_; uint8_t v_isShared_147_; uint8_t v_isSharedCheck_152_; 
v_head_143_ = lean_ctor_get(v_x_141_, 0);
v_tail_144_ = lean_ctor_get(v_x_141_, 1);
v_isSharedCheck_152_ = !lean_is_exclusive(v_x_141_);
if (v_isSharedCheck_152_ == 0)
{
v___x_146_ = v_x_141_;
v_isShared_147_ = v_isSharedCheck_152_;
goto v_resetjp_145_;
}
else
{
lean_inc(v_tail_144_);
lean_inc(v_head_143_);
lean_dec(v_x_141_);
v___x_146_ = lean_box(0);
v_isShared_147_ = v_isSharedCheck_152_;
goto v_resetjp_145_;
}
v_resetjp_145_:
{
lean_object* v___x_148_; lean_object* v___x_150_; 
v___x_148_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_append___redArg(v_tail_144_, v_x_142_);
if (v_isShared_147_ == 0)
{
lean_ctor_set(v___x_146_, 1, v___x_148_);
v___x_150_ = v___x_146_;
goto v_reusejp_149_;
}
else
{
lean_object* v_reuseFailAlloc_151_; 
v_reuseFailAlloc_151_ = lean_alloc_ctor(1, 2, 0);
lean_ctor_set(v_reuseFailAlloc_151_, 0, v_head_143_);
lean_ctor_set(v_reuseFailAlloc_151_, 1, v___x_148_);
v___x_150_ = v_reuseFailAlloc_151_;
goto v_reusejp_149_;
}
v_reusejp_149_:
{
return v___x_150_;
}
}
}
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_append___redArg___boxed(lean_object* v_x_153_, lean_object* v_x_154_){
_start:
{
lean_object* v_res_155_; 
v_res_155_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_append___redArg(v_x_153_, v_x_154_);
lean_dec(v_x_154_);
return v_res_155_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_append(lean_object* v_00_u03b1_156_, lean_object* v_x_157_, lean_object* v_x_158_){
_start:
{
lean_object* v___x_159_; 
v___x_159_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_append___redArg(v_x_157_, v_x_158_);
return v___x_159_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_append___boxed(lean_object* v_00_u03b1_160_, lean_object* v_x_161_, lean_object* v_x_162_){
_start:
{
lean_object* v_res_163_; 
v_res_163_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_append(v_00_u03b1_160_, v_x_161_, v_x_162_);
lean_dec(v_x_162_);
return v_res_163_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_append__example___closed__2(void){
_start:
{
lean_object* v___x_170_; lean_object* v___x_171_; lean_object* v___x_172_; 
v___x_170_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_len__example___closed__2));
v___x_171_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_append__example___closed__1));
v___x_172_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_append___redArg(v___x_171_, v___x_170_);
return v___x_172_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_append__example(void){
_start:
{
lean_object* v___x_173_; 
v___x_173_ = lean_obj_once(&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_append__example___closed__2, &lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_append__example___closed__2_once, _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_append__example___closed__2);
return v___x_173_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_reverse___redArg(lean_object* v_x_174_){
_start:
{
if (lean_obj_tag(v_x_174_) == 0)
{
return v_x_174_;
}
else
{
lean_object* v_head_175_; lean_object* v_tail_176_; lean_object* v___x_178_; uint8_t v_isShared_179_; uint8_t v_isSharedCheck_186_; 
v_head_175_ = lean_ctor_get(v_x_174_, 0);
v_tail_176_ = lean_ctor_get(v_x_174_, 1);
v_isSharedCheck_186_ = !lean_is_exclusive(v_x_174_);
if (v_isSharedCheck_186_ == 0)
{
v___x_178_ = v_x_174_;
v_isShared_179_ = v_isSharedCheck_186_;
goto v_resetjp_177_;
}
else
{
lean_inc(v_tail_176_);
lean_inc(v_head_175_);
lean_dec(v_x_174_);
v___x_178_ = lean_box(0);
v_isShared_179_ = v_isSharedCheck_186_;
goto v_resetjp_177_;
}
v_resetjp_177_:
{
lean_object* v___x_180_; lean_object* v___x_181_; lean_object* v___x_183_; 
v___x_180_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_reverse___redArg(v_tail_176_);
v___x_181_ = lean_box(0);
if (v_isShared_179_ == 0)
{
lean_ctor_set(v___x_178_, 1, v___x_181_);
v___x_183_ = v___x_178_;
goto v_reusejp_182_;
}
else
{
lean_object* v_reuseFailAlloc_185_; 
v_reuseFailAlloc_185_ = lean_alloc_ctor(1, 2, 0);
lean_ctor_set(v_reuseFailAlloc_185_, 0, v_head_175_);
lean_ctor_set(v_reuseFailAlloc_185_, 1, v___x_181_);
v___x_183_ = v_reuseFailAlloc_185_;
goto v_reusejp_182_;
}
v_reusejp_182_:
{
lean_object* v___x_184_; 
v___x_184_ = l_List_appendTR___redArg(v___x_180_, v___x_183_);
return v___x_184_;
}
}
}
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_reverse(lean_object* v_00_u03b1_187_, lean_object* v_x_188_){
_start:
{
lean_object* v___x_189_; 
v___x_189_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_reverse___redArg(v_x_188_);
return v___x_189_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_reverse__example___closed__3(void){
_start:
{
lean_object* v___x_199_; lean_object* v___x_200_; 
v___x_199_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_reverse__example___closed__2));
v___x_200_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_reverse___redArg(v___x_199_);
return v___x_200_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_reverse__example(void){
_start:
{
lean_object* v___x_201_; 
v___x_201_ = lean_obj_once(&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_reverse__example___closed__3, &lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_reverse__example___closed__3_once, _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_reverse__example___closed__3);
return v___x_201_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_zip___redArg(lean_object* v_x_202_, lean_object* v_x_203_){
_start:
{
if (lean_obj_tag(v_x_202_) == 0)
{
lean_object* v___x_204_; 
lean_dec(v_x_203_);
v___x_204_ = lean_box(0);
return v___x_204_;
}
else
{
if (lean_obj_tag(v_x_203_) == 0)
{
lean_object* v___x_205_; 
lean_dec_ref_known(v_x_202_, 2);
v___x_205_ = lean_box(0);
return v___x_205_;
}
else
{
lean_object* v_head_206_; lean_object* v_tail_207_; lean_object* v___x_209_; uint8_t v_isShared_210_; uint8_t v_isSharedCheck_224_; 
v_head_206_ = lean_ctor_get(v_x_202_, 0);
v_tail_207_ = lean_ctor_get(v_x_202_, 1);
v_isSharedCheck_224_ = !lean_is_exclusive(v_x_202_);
if (v_isSharedCheck_224_ == 0)
{
v___x_209_ = v_x_202_;
v_isShared_210_ = v_isSharedCheck_224_;
goto v_resetjp_208_;
}
else
{
lean_inc(v_tail_207_);
lean_inc(v_head_206_);
lean_dec(v_x_202_);
v___x_209_ = lean_box(0);
v_isShared_210_ = v_isSharedCheck_224_;
goto v_resetjp_208_;
}
v_resetjp_208_:
{
lean_object* v_head_211_; lean_object* v_tail_212_; lean_object* v___x_214_; uint8_t v_isShared_215_; uint8_t v_isSharedCheck_223_; 
v_head_211_ = lean_ctor_get(v_x_203_, 0);
v_tail_212_ = lean_ctor_get(v_x_203_, 1);
v_isSharedCheck_223_ = !lean_is_exclusive(v_x_203_);
if (v_isSharedCheck_223_ == 0)
{
v___x_214_ = v_x_203_;
v_isShared_215_ = v_isSharedCheck_223_;
goto v_resetjp_213_;
}
else
{
lean_inc(v_tail_212_);
lean_inc(v_head_211_);
lean_dec(v_x_203_);
v___x_214_ = lean_box(0);
v_isShared_215_ = v_isSharedCheck_223_;
goto v_resetjp_213_;
}
v_resetjp_213_:
{
lean_object* v___x_217_; 
if (v_isShared_210_ == 0)
{
lean_ctor_set_tag(v___x_209_, 0);
lean_ctor_set(v___x_209_, 1, v_head_211_);
v___x_217_ = v___x_209_;
goto v_reusejp_216_;
}
else
{
lean_object* v_reuseFailAlloc_222_; 
v_reuseFailAlloc_222_ = lean_alloc_ctor(0, 2, 0);
lean_ctor_set(v_reuseFailAlloc_222_, 0, v_head_206_);
lean_ctor_set(v_reuseFailAlloc_222_, 1, v_head_211_);
v___x_217_ = v_reuseFailAlloc_222_;
goto v_reusejp_216_;
}
v_reusejp_216_:
{
lean_object* v___x_218_; lean_object* v___x_220_; 
v___x_218_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_zip___redArg(v_tail_207_, v_tail_212_);
if (v_isShared_215_ == 0)
{
lean_ctor_set(v___x_214_, 1, v___x_218_);
lean_ctor_set(v___x_214_, 0, v___x_217_);
v___x_220_ = v___x_214_;
goto v_reusejp_219_;
}
else
{
lean_object* v_reuseFailAlloc_221_; 
v_reuseFailAlloc_221_ = lean_alloc_ctor(1, 2, 0);
lean_ctor_set(v_reuseFailAlloc_221_, 0, v___x_217_);
lean_ctor_set(v_reuseFailAlloc_221_, 1, v___x_218_);
v___x_220_ = v_reuseFailAlloc_221_;
goto v_reusejp_219_;
}
v_reusejp_219_:
{
return v___x_220_;
}
}
}
}
}
}
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_zip(lean_object* v_00_u03b1_225_, lean_object* v_00_u03b2_226_, lean_object* v_x_227_, lean_object* v_x_228_){
_start:
{
lean_object* v___x_229_; 
v___x_229_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_zip___redArg(v_x_227_, v_x_228_);
return v___x_229_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_zip__example___closed__6(void){
_start:
{
lean_object* v___x_242_; lean_object* v___x_243_; lean_object* v___x_244_; 
v___x_242_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_zip__example___closed__5));
v___x_243_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_reverse__example___closed__2));
v___x_244_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_zip___redArg(v___x_243_, v___x_242_);
return v___x_244_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_zip__example(void){
_start:
{
lean_object* v___x_245_; 
v___x_245_ = lean_obj_once(&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_zip__example___closed__6, &lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_zip__example___closed__6_once, _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_zip__example___closed__6);
return v___x_245_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_take___redArg(lean_object* v_x_246_, lean_object* v_x_247_){
_start:
{
lean_object* v_zero_248_; uint8_t v_isZero_249_; 
v_zero_248_ = lean_unsigned_to_nat(0u);
v_isZero_249_ = lean_nat_dec_eq(v_x_246_, v_zero_248_);
if (v_isZero_249_ == 1)
{
lean_object* v___x_250_; 
lean_dec(v_x_247_);
v___x_250_ = lean_box(0);
return v___x_250_;
}
else
{
if (lean_obj_tag(v_x_247_) == 0)
{
return v_x_247_;
}
else
{
lean_object* v_head_251_; lean_object* v_tail_252_; lean_object* v___x_254_; uint8_t v_isShared_255_; uint8_t v_isSharedCheck_262_; 
v_head_251_ = lean_ctor_get(v_x_247_, 0);
v_tail_252_ = lean_ctor_get(v_x_247_, 1);
v_isSharedCheck_262_ = !lean_is_exclusive(v_x_247_);
if (v_isSharedCheck_262_ == 0)
{
v___x_254_ = v_x_247_;
v_isShared_255_ = v_isSharedCheck_262_;
goto v_resetjp_253_;
}
else
{
lean_inc(v_tail_252_);
lean_inc(v_head_251_);
lean_dec(v_x_247_);
v___x_254_ = lean_box(0);
v_isShared_255_ = v_isSharedCheck_262_;
goto v_resetjp_253_;
}
v_resetjp_253_:
{
lean_object* v_one_256_; lean_object* v_n_257_; lean_object* v___x_258_; lean_object* v___x_260_; 
v_one_256_ = lean_unsigned_to_nat(1u);
v_n_257_ = lean_nat_sub(v_x_246_, v_one_256_);
v___x_258_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_take___redArg(v_n_257_, v_tail_252_);
lean_dec(v_n_257_);
if (v_isShared_255_ == 0)
{
lean_ctor_set(v___x_254_, 1, v___x_258_);
v___x_260_ = v___x_254_;
goto v_reusejp_259_;
}
else
{
lean_object* v_reuseFailAlloc_261_; 
v_reuseFailAlloc_261_ = lean_alloc_ctor(1, 2, 0);
lean_ctor_set(v_reuseFailAlloc_261_, 0, v_head_251_);
lean_ctor_set(v_reuseFailAlloc_261_, 1, v___x_258_);
v___x_260_ = v_reuseFailAlloc_261_;
goto v_reusejp_259_;
}
v_reusejp_259_:
{
return v___x_260_;
}
}
}
}
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_take___redArg___boxed(lean_object* v_x_263_, lean_object* v_x_264_){
_start:
{
lean_object* v_res_265_; 
v_res_265_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_take___redArg(v_x_263_, v_x_264_);
lean_dec(v_x_263_);
return v_res_265_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_take(lean_object* v_00_u03b1_266_, lean_object* v_x_267_, lean_object* v_x_268_){
_start:
{
lean_object* v___x_269_; 
v___x_269_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_take___redArg(v_x_267_, v_x_268_);
return v___x_269_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_take___boxed(lean_object* v_00_u03b1_270_, lean_object* v_x_271_, lean_object* v_x_272_){
_start:
{
lean_object* v_res_273_; 
v_res_273_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_take(v_00_u03b1_270_, v_x_271_, v_x_272_);
lean_dec(v_x_271_);
return v_res_273_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_take__3___closed__0(void){
_start:
{
lean_object* v___x_274_; lean_object* v___x_275_; lean_object* v___x_276_; 
v___x_274_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_len__example___closed__4));
v___x_275_ = lean_unsigned_to_nat(3u);
v___x_276_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_take___redArg(v___x_275_, v___x_274_);
return v___x_276_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_take__3(void){
_start:
{
lean_object* v___x_277_; 
v___x_277_ = lean_obj_once(&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_take__3___closed__0, &lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_take__3___closed__0_once, _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_take__3___closed__0);
return v___x_277_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_take__10___closed__0(void){
_start:
{
lean_object* v___x_278_; lean_object* v___x_279_; lean_object* v___x_280_; 
v___x_278_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_reverse__example___closed__2));
v___x_279_ = lean_unsigned_to_nat(10u);
v___x_280_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_take___redArg(v___x_279_, v___x_278_);
return v___x_280_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_take__10(void){
_start:
{
lean_object* v___x_281_; 
v___x_281_ = lean_obj_once(&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_take__10___closed__0, &lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_take__10___closed__0_once, _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_take__10___closed__0);
return v___x_281_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_drop___redArg(lean_object* v_x_282_, lean_object* v_x_283_){
_start:
{
lean_object* v_zero_284_; uint8_t v_isZero_285_; 
v_zero_284_ = lean_unsigned_to_nat(0u);
v_isZero_285_ = lean_nat_dec_eq(v_x_282_, v_zero_284_);
if (v_isZero_285_ == 1)
{
lean_dec(v_x_282_);
lean_inc(v_x_283_);
return v_x_283_;
}
else
{
if (lean_obj_tag(v_x_283_) == 0)
{
lean_dec(v_x_282_);
return v_x_283_;
}
else
{
lean_object* v_tail_286_; lean_object* v_one_287_; lean_object* v_n_288_; 
v_tail_286_ = lean_ctor_get(v_x_283_, 1);
v_one_287_ = lean_unsigned_to_nat(1u);
v_n_288_ = lean_nat_sub(v_x_282_, v_one_287_);
lean_dec(v_x_282_);
v_x_282_ = v_n_288_;
v_x_283_ = v_tail_286_;
goto _start;
}
}
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_drop___redArg___boxed(lean_object* v_x_290_, lean_object* v_x_291_){
_start:
{
lean_object* v_res_292_; 
v_res_292_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_drop___redArg(v_x_290_, v_x_291_);
lean_dec(v_x_291_);
return v_res_292_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_drop(lean_object* v_00_u03b1_293_, lean_object* v_x_294_, lean_object* v_x_295_){
_start:
{
lean_object* v___x_296_; 
v___x_296_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_drop___redArg(v_x_294_, v_x_295_);
return v___x_296_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_drop___boxed(lean_object* v_00_u03b1_297_, lean_object* v_x_298_, lean_object* v_x_299_){
_start:
{
lean_object* v_res_300_; 
v_res_300_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_drop(v_00_u03b1_297_, v_x_298_, v_x_299_);
lean_dec(v_x_299_);
return v_res_300_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_drop__2___closed__0(void){
_start:
{
lean_object* v___x_301_; lean_object* v___x_302_; lean_object* v___x_303_; 
v___x_301_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_len__example___closed__4));
v___x_302_ = lean_unsigned_to_nat(2u);
v___x_303_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_drop___redArg(v___x_302_, v___x_301_);
return v___x_303_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_drop__2(void){
_start:
{
lean_object* v___x_304_; 
v___x_304_ = lean_obj_once(&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_drop__2___closed__0, &lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_drop__2___closed__0_once, _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_drop__2___closed__0);
return v___x_304_;
}
}
LEAN_EXPORT uint8_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_and(uint8_t v_x_305_, uint8_t v_x_306_){
_start:
{
if (v_x_305_ == 1)
{
if (v_x_306_ == 1)
{
return v_x_306_;
}
else
{
uint8_t v___x_307_; 
v___x_307_ = 0;
return v___x_307_;
}
}
else
{
uint8_t v___x_308_; 
v___x_308_ = 0;
return v___x_308_;
}
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_and___boxed(lean_object* v_x_309_, lean_object* v_x_310_){
_start:
{
uint8_t v_x_32__boxed_311_; uint8_t v_x_33__boxed_312_; uint8_t v_res_313_; lean_object* v_r_314_; 
v_x_32__boxed_311_ = lean_unbox(v_x_309_);
v_x_33__boxed_312_ = lean_unbox(v_x_310_);
v_res_313_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_and(v_x_32__boxed_311_, v_x_33__boxed_312_);
v_r_314_ = lean_box(v_res_313_);
return v_r_314_;
}
}
LEAN_EXPORT uint8_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_or(uint8_t v_x_315_, uint8_t v_x_316_){
_start:
{
if (v_x_315_ == 0)
{
if (v_x_316_ == 0)
{
return v_x_316_;
}
else
{
uint8_t v___x_317_; 
v___x_317_ = 1;
return v___x_317_;
}
}
else
{
uint8_t v___x_318_; 
v___x_318_ = 1;
return v___x_318_;
}
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_or___boxed(lean_object* v_x_319_, lean_object* v_x_320_){
_start:
{
uint8_t v_x_32__boxed_321_; uint8_t v_x_33__boxed_322_; uint8_t v_res_323_; lean_object* v_r_324_; 
v_x_32__boxed_321_ = lean_unbox(v_x_319_);
v_x_33__boxed_322_ = lean_unbox(v_x_320_);
v_res_323_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_or(v_x_32__boxed_321_, v_x_33__boxed_322_);
v_r_324_ = lean_box(v_res_323_);
return v_r_324_;
}
}
LEAN_EXPORT uint8_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_xor(uint8_t v_x_325_, uint8_t v_x_326_){
_start:
{
if (v_x_325_ == 0)
{
if (v_x_326_ == 1)
{
return v_x_326_;
}
else
{
return v_x_325_;
}
}
else
{
if (v_x_326_ == 0)
{
return v_x_325_;
}
else
{
uint8_t v___x_327_; 
v___x_327_ = 0;
return v___x_327_;
}
}
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_xor___boxed(lean_object* v_x_328_, lean_object* v_x_329_){
_start:
{
uint8_t v_x_40__boxed_330_; uint8_t v_x_41__boxed_331_; uint8_t v_res_332_; lean_object* v_r_333_; 
v_x_40__boxed_330_ = lean_unbox(v_x_328_);
v_x_41__boxed_331_ = lean_unbox(v_x_329_);
v_res_332_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_xor(v_x_40__boxed_330_, v_x_41__boxed_331_);
v_r_333_ = lean_box(v_res_332_);
return v_r_333_;
}
}
LEAN_EXPORT uint8_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_leq(lean_object* v_x_334_, lean_object* v_x_335_){
_start:
{
lean_object* v_zero_336_; uint8_t v_isZero_337_; 
v_zero_336_ = lean_unsigned_to_nat(0u);
v_isZero_337_ = lean_nat_dec_eq(v_x_334_, v_zero_336_);
if (v_isZero_337_ == 1)
{
lean_dec(v_x_335_);
lean_dec(v_x_334_);
return v_isZero_337_;
}
else
{
uint8_t v_isZero_338_; 
v_isZero_338_ = lean_nat_dec_eq(v_x_335_, v_zero_336_);
if (v_isZero_338_ == 1)
{
lean_dec(v_x_335_);
lean_dec(v_x_334_);
return v_isZero_337_;
}
else
{
lean_object* v_one_339_; lean_object* v_n_340_; lean_object* v_n_341_; 
v_one_339_ = lean_unsigned_to_nat(1u);
v_n_340_ = lean_nat_sub(v_x_334_, v_one_339_);
lean_dec(v_x_334_);
v_n_341_ = lean_nat_sub(v_x_335_, v_one_339_);
lean_dec(v_x_335_);
v_x_334_ = v_n_340_;
v_x_335_ = v_n_341_;
goto _start;
}
}
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_leq___boxed(lean_object* v_x_343_, lean_object* v_x_344_){
_start:
{
uint8_t v_res_345_; lean_object* v_r_346_; 
v_res_345_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_leq(v_x_343_, v_x_344_);
v_r_346_ = lean_box(v_res_345_);
return v_r_346_;
}
}
static uint8_t _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_leq__example1___closed__0(void){
_start:
{
lean_object* v___x_347_; lean_object* v___x_348_; uint8_t v___x_349_; 
v___x_347_ = lean_unsigned_to_nat(5u);
v___x_348_ = lean_unsigned_to_nat(3u);
v___x_349_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_leq(v___x_348_, v___x_347_);
return v___x_349_;
}
}
static uint8_t _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_leq__example1(void){
_start:
{
uint8_t v___x_350_; 
v___x_350_ = lean_uint8_once(&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_leq__example1___closed__0, &lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_leq__example1___closed__0_once, _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_leq__example1___closed__0);
return v___x_350_;
}
}
static uint8_t _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_leq__example2___closed__0(void){
_start:
{
lean_object* v___x_351_; lean_object* v___x_352_; uint8_t v___x_353_; 
v___x_351_ = lean_unsigned_to_nat(3u);
v___x_352_ = lean_unsigned_to_nat(5u);
v___x_353_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_leq(v___x_352_, v___x_351_);
return v___x_353_;
}
}
static uint8_t _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_leq__example2(void){
_start:
{
uint8_t v___x_354_; 
v___x_354_ = lean_uint8_once(&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_leq__example2___closed__0, &lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_leq__example2___closed__0_once, _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_leq__example2___closed__0);
return v___x_354_;
}
}
static uint8_t _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_leq__example3___closed__0(void){
_start:
{
lean_object* v___x_355_; uint8_t v___x_356_; 
v___x_355_ = lean_unsigned_to_nat(5u);
v___x_356_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_leq(v___x_355_, v___x_355_);
return v___x_356_;
}
}
static uint8_t _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_leq__example3(void){
_start:
{
uint8_t v___x_357_; 
v___x_357_ = lean_uint8_once(&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_leq__example3___closed__0, &lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_leq__example3___closed__0_once, _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_leq__example3___closed__0);
return v___x_357_;
}
}
LEAN_EXPORT uint8_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_eq__nat(lean_object* v_x_358_, lean_object* v_x_359_){
_start:
{
lean_object* v_zero_360_; uint8_t v_isZero_361_; 
v_zero_360_ = lean_unsigned_to_nat(0u);
v_isZero_361_ = lean_nat_dec_eq(v_x_358_, v_zero_360_);
if (v_isZero_361_ == 1)
{
uint8_t v_isZero_362_; 
lean_dec(v_x_358_);
v_isZero_362_ = lean_nat_dec_eq(v_x_359_, v_zero_360_);
lean_dec(v_x_359_);
return v_isZero_362_;
}
else
{
uint8_t v_isZero_363_; 
v_isZero_363_ = lean_nat_dec_eq(v_x_359_, v_zero_360_);
if (v_isZero_363_ == 1)
{
lean_dec(v_x_359_);
lean_dec(v_x_358_);
return v_isZero_361_;
}
else
{
lean_object* v_one_364_; lean_object* v_n_365_; lean_object* v_n_366_; 
v_one_364_ = lean_unsigned_to_nat(1u);
v_n_365_ = lean_nat_sub(v_x_358_, v_one_364_);
lean_dec(v_x_358_);
v_n_366_ = lean_nat_sub(v_x_359_, v_one_364_);
lean_dec(v_x_359_);
v_x_358_ = v_n_365_;
v_x_359_ = v_n_366_;
goto _start;
}
}
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_eq__nat___boxed(lean_object* v_x_368_, lean_object* v_x_369_){
_start:
{
uint8_t v_res_370_; lean_object* v_r_371_; 
v_res_370_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_eq__nat(v_x_368_, v_x_369_);
v_r_371_ = lean_box(v_res_370_);
return v_r_371_;
}
}
static uint8_t _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_eq__example1___closed__0(void){
_start:
{
lean_object* v___x_372_; uint8_t v___x_373_; 
v___x_372_ = lean_unsigned_to_nat(5u);
v___x_373_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_eq__nat(v___x_372_, v___x_372_);
return v___x_373_;
}
}
static uint8_t _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_eq__example1(void){
_start:
{
uint8_t v___x_374_; 
v___x_374_ = lean_uint8_once(&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_eq__example1___closed__0, &lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_eq__example1___closed__0_once, _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_eq__example1___closed__0);
return v___x_374_;
}
}
static uint8_t _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_eq__example2___closed__0(void){
_start:
{
lean_object* v___x_375_; lean_object* v___x_376_; uint8_t v___x_377_; 
v___x_375_ = lean_unsigned_to_nat(5u);
v___x_376_ = lean_unsigned_to_nat(3u);
v___x_377_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_eq__nat(v___x_376_, v___x_375_);
return v___x_377_;
}
}
static uint8_t _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_eq__example2(void){
_start:
{
uint8_t v___x_378_; 
v___x_378_ = lean_uint8_once(&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_eq__example2___closed__0, &lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_eq__example2___closed__0_once, _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_eq__example2___closed__0);
return v___x_378_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_gcd(lean_object* v_m_379_, lean_object* v_n_380_){
_start:
{
lean_object* v___x_381_; uint8_t v___x_382_; 
v___x_381_ = lean_unsigned_to_nat(0u);
v___x_382_ = lean_nat_dec_eq(v_n_380_, v___x_381_);
if (v___x_382_ == 0)
{
lean_object* v___x_383_; 
v___x_383_ = lean_nat_mod(v_m_379_, v_n_380_);
lean_dec(v_m_379_);
v_m_379_ = v_n_380_;
v_n_380_ = v___x_383_;
goto _start;
}
else
{
lean_dec(v_n_380_);
return v_m_379_;
}
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_gcd__example1___closed__0(void){
_start:
{
lean_object* v___x_385_; lean_object* v___x_386_; lean_object* v___x_387_; 
v___x_385_ = lean_unsigned_to_nat(18u);
v___x_386_ = lean_unsigned_to_nat(48u);
v___x_387_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_gcd(v___x_386_, v___x_385_);
return v___x_387_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_gcd__example1(void){
_start:
{
lean_object* v___x_388_; 
v___x_388_ = lean_obj_once(&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_gcd__example1___closed__0, &lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_gcd__example1___closed__0_once, _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_gcd__example1___closed__0);
return v___x_388_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_gcd__example2___closed__0(void){
_start:
{
lean_object* v___x_389_; lean_object* v___x_390_; lean_object* v___x_391_; 
v___x_389_ = lean_unsigned_to_nat(75u);
v___x_390_ = lean_unsigned_to_nat(100u);
v___x_391_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_gcd(v___x_390_, v___x_389_);
return v___x_391_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_gcd__example2(void){
_start:
{
lean_object* v___x_392_; 
v___x_392_ = lean_obj_once(&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_gcd__example2___closed__0, &lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_gcd__example2___closed__0_once, _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_gcd__example2___closed__0);
return v___x_392_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_gcd__example3___closed__0(void){
_start:
{
lean_object* v___x_393_; lean_object* v___x_394_; lean_object* v___x_395_; 
v___x_393_ = lean_unsigned_to_nat(13u);
v___x_394_ = lean_unsigned_to_nat(7u);
v___x_395_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_gcd(v___x_394_, v___x_393_);
return v___x_395_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_gcd__example3(void){
_start:
{
lean_object* v___x_396_; 
v___x_396_ = lean_obj_once(&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_gcd__example3___closed__0, &lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_gcd__example3___closed__0_once, _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_gcd__example3___closed__0);
return v___x_396_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_insert(lean_object* v_x_397_, lean_object* v_x_398_){
_start:
{
if (lean_obj_tag(v_x_398_) == 0)
{
lean_object* v___x_399_; 
v___x_399_ = lean_alloc_ctor(1, 2, 0);
lean_ctor_set(v___x_399_, 0, v_x_397_);
lean_ctor_set(v___x_399_, 1, v_x_398_);
return v___x_399_;
}
else
{
lean_object* v_head_400_; lean_object* v_tail_401_; uint8_t v___x_402_; 
v_head_400_ = lean_ctor_get(v_x_398_, 0);
v_tail_401_ = lean_ctor_get(v_x_398_, 1);
v___x_402_ = lean_nat_dec_le(v_x_397_, v_head_400_);
if (v___x_402_ == 0)
{
lean_object* v___x_404_; uint8_t v_isShared_405_; uint8_t v_isSharedCheck_410_; 
lean_inc(v_tail_401_);
lean_inc(v_head_400_);
v_isSharedCheck_410_ = !lean_is_exclusive(v_x_398_);
if (v_isSharedCheck_410_ == 0)
{
lean_object* v_unused_411_; lean_object* v_unused_412_; 
v_unused_411_ = lean_ctor_get(v_x_398_, 1);
lean_dec(v_unused_411_);
v_unused_412_ = lean_ctor_get(v_x_398_, 0);
lean_dec(v_unused_412_);
v___x_404_ = v_x_398_;
v_isShared_405_ = v_isSharedCheck_410_;
goto v_resetjp_403_;
}
else
{
lean_dec(v_x_398_);
v___x_404_ = lean_box(0);
v_isShared_405_ = v_isSharedCheck_410_;
goto v_resetjp_403_;
}
v_resetjp_403_:
{
lean_object* v___x_406_; lean_object* v___x_408_; 
v___x_406_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_insert(v_x_397_, v_tail_401_);
if (v_isShared_405_ == 0)
{
lean_ctor_set(v___x_404_, 1, v___x_406_);
v___x_408_ = v___x_404_;
goto v_reusejp_407_;
}
else
{
lean_object* v_reuseFailAlloc_409_; 
v_reuseFailAlloc_409_ = lean_alloc_ctor(1, 2, 0);
lean_ctor_set(v_reuseFailAlloc_409_, 0, v_head_400_);
lean_ctor_set(v_reuseFailAlloc_409_, 1, v___x_406_);
v___x_408_ = v_reuseFailAlloc_409_;
goto v_reusejp_407_;
}
v_reusejp_407_:
{
return v___x_408_;
}
}
}
else
{
lean_object* v___x_413_; 
v___x_413_ = lean_alloc_ctor(1, 2, 0);
lean_ctor_set(v___x_413_, 0, v_x_397_);
lean_ctor_set(v___x_413_, 1, v_x_398_);
return v___x_413_;
}
}
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_insertionSort(lean_object* v_x_414_){
_start:
{
if (lean_obj_tag(v_x_414_) == 0)
{
return v_x_414_;
}
else
{
lean_object* v_head_415_; lean_object* v_tail_416_; lean_object* v___x_417_; lean_object* v___x_418_; 
v_head_415_ = lean_ctor_get(v_x_414_, 0);
lean_inc(v_head_415_);
v_tail_416_ = lean_ctor_get(v_x_414_, 1);
lean_inc(v_tail_416_);
lean_dec_ref_known(v_x_414_, 2);
v___x_417_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_insertionSort(v_tail_416_);
v___x_418_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_insert(v_head_415_, v___x_417_);
return v___x_418_;
}
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_sort__example___closed__8(void){
_start:
{
lean_object* v___x_443_; lean_object* v___x_444_; 
v___x_443_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_sort__example___closed__7));
v___x_444_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_insertionSort(v___x_443_);
return v___x_444_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_sort__example(void){
_start:
{
lean_object* v___x_445_; 
v___x_445_ = lean_obj_once(&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_sort__example___closed__8, &lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_sort__example___closed__8_once, _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_sort__example___closed__8);
return v___x_445_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_nth___redArg(lean_object* v_default_446_, lean_object* v_x_447_, lean_object* v_x_448_){
_start:
{
if (lean_obj_tag(v_x_447_) == 0)
{
lean_dec(v_x_448_);
lean_inc(v_default_446_);
return v_default_446_;
}
else
{
lean_object* v_head_449_; lean_object* v_tail_450_; lean_object* v_zero_451_; uint8_t v_isZero_452_; 
v_head_449_ = lean_ctor_get(v_x_447_, 0);
v_tail_450_ = lean_ctor_get(v_x_447_, 1);
v_zero_451_ = lean_unsigned_to_nat(0u);
v_isZero_452_ = lean_nat_dec_eq(v_x_448_, v_zero_451_);
if (v_isZero_452_ == 1)
{
lean_dec(v_x_448_);
lean_inc(v_head_449_);
return v_head_449_;
}
else
{
lean_object* v_one_453_; lean_object* v_n_454_; 
v_one_453_ = lean_unsigned_to_nat(1u);
v_n_454_ = lean_nat_sub(v_x_448_, v_one_453_);
lean_dec(v_x_448_);
v_x_447_ = v_tail_450_;
v_x_448_ = v_n_454_;
goto _start;
}
}
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_nth___redArg___boxed(lean_object* v_default_456_, lean_object* v_x_457_, lean_object* v_x_458_){
_start:
{
lean_object* v_res_459_; 
v_res_459_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_nth___redArg(v_default_456_, v_x_457_, v_x_458_);
lean_dec(v_x_457_);
lean_dec(v_default_456_);
return v_res_459_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_nth(lean_object* v_00_u03b1_460_, lean_object* v_default_461_, lean_object* v_x_462_, lean_object* v_x_463_){
_start:
{
lean_object* v___x_464_; 
v___x_464_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_nth___redArg(v_default_461_, v_x_462_, v_x_463_);
return v___x_464_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_nth___boxed(lean_object* v_00_u03b1_465_, lean_object* v_default_466_, lean_object* v_x_467_, lean_object* v_x_468_){
_start:
{
lean_object* v_res_469_; 
v_res_469_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_nth(v_00_u03b1_465_, v_default_466_, v_x_467_, v_x_468_);
lean_dec(v_x_467_);
lean_dec(v_default_466_);
return v_res_469_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_rev_go___redArg(lean_object* v_a_470_, lean_object* v_a_471_){
_start:
{
if (lean_obj_tag(v_a_470_) == 0)
{
return v_a_471_;
}
else
{
lean_object* v_head_472_; lean_object* v_tail_473_; lean_object* v___x_475_; uint8_t v_isShared_476_; uint8_t v_isSharedCheck_481_; 
v_head_472_ = lean_ctor_get(v_a_470_, 0);
v_tail_473_ = lean_ctor_get(v_a_470_, 1);
v_isSharedCheck_481_ = !lean_is_exclusive(v_a_470_);
if (v_isSharedCheck_481_ == 0)
{
v___x_475_ = v_a_470_;
v_isShared_476_ = v_isSharedCheck_481_;
goto v_resetjp_474_;
}
else
{
lean_inc(v_tail_473_);
lean_inc(v_head_472_);
lean_dec(v_a_470_);
v___x_475_ = lean_box(0);
v_isShared_476_ = v_isSharedCheck_481_;
goto v_resetjp_474_;
}
v_resetjp_474_:
{
lean_object* v___x_478_; 
if (v_isShared_476_ == 0)
{
lean_ctor_set(v___x_475_, 1, v_a_471_);
v___x_478_ = v___x_475_;
goto v_reusejp_477_;
}
else
{
lean_object* v_reuseFailAlloc_480_; 
v_reuseFailAlloc_480_ = lean_alloc_ctor(1, 2, 0);
lean_ctor_set(v_reuseFailAlloc_480_, 0, v_head_472_);
lean_ctor_set(v_reuseFailAlloc_480_, 1, v_a_471_);
v___x_478_ = v_reuseFailAlloc_480_;
goto v_reusejp_477_;
}
v_reusejp_477_:
{
v_a_470_ = v_tail_473_;
v_a_471_ = v___x_478_;
goto _start;
}
}
}
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_rev_go(lean_object* v_00_u03b1_482_, lean_object* v_a_483_, lean_object* v_a_484_){
_start:
{
lean_object* v___x_485_; 
v___x_485_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_rev_go___redArg(v_a_483_, v_a_484_);
return v___x_485_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_rev___redArg(lean_object* v_l_486_){
_start:
{
lean_object* v___x_487_; lean_object* v___x_488_; 
v___x_487_ = lean_box(0);
v___x_488_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_rev_go___redArg(v_l_486_, v___x_487_);
return v___x_488_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_rev(lean_object* v_00_u03b1_489_, lean_object* v_l_490_){
_start:
{
lean_object* v___x_491_; 
v___x_491_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_rev___redArg(v_l_490_);
return v___x_491_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_rev__example___closed__0(void){
_start:
{
lean_object* v___x_492_; lean_object* v___x_493_; 
v___x_492_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_len__example___closed__4));
v___x_493_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_rev___redArg(v___x_492_);
return v___x_493_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_rev__example(void){
_start:
{
lean_object* v___x_494_; 
v___x_494_ = lean_obj_once(&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_rev__example___closed__0, &lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_rev__example___closed__0_once, _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_rev__example___closed__0);
return v___x_494_;
}
}
lean_object* initialize_Init(uint8_t builtin);
lean_object* initialize_Init(uint8_t builtin);
static bool _G_initialized = false;
LEAN_EXPORT lean_object* initialize_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler(uint8_t builtin) {
lean_object * res;
if (_G_initialized) return lean_io_result_mk_ok(lean_box(0));
_G_initialized = true;
res = initialize_Init(builtin);
if (lean_io_result_is_error(res)) return res;
lean_dec_ref(res);
res = initialize_Init(builtin);
if (lean_io_result_is_error(res)) return res;
lean_dec_ref(res);
lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_fac__0 = _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_fac__0();
lean_mark_persistent(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_fac__0);
lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_fac__1 = _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_fac__1();
lean_mark_persistent(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_fac__1);
lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_fac__5 = _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_fac__5();
lean_mark_persistent(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_fac__5);
lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_fac__10 = _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_fac__10();
lean_mark_persistent(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_fac__10);
lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_fib__0 = _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_fib__0();
lean_mark_persistent(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_fib__0);
lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_fib__1 = _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_fib__1();
lean_mark_persistent(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_fib__1);
lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_fib__2 = _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_fib__2();
lean_mark_persistent(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_fib__2);
lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_fib__5 = _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_fib__5();
lean_mark_persistent(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_fib__5);
lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_fib__10 = _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_fib__10();
lean_mark_persistent(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_fib__10);
lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_add__3__4 = _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_add__3__4();
lean_mark_persistent(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_add__3__4);
lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_mul__3__4 = _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_mul__3__4();
lean_mark_persistent(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_mul__3__4);
lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_power__2__10 = _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_power__2__10();
lean_mark_persistent(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_power__2__10);
lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_len__example = _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_len__example();
lean_mark_persistent(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_len__example);
lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_append__example = _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_append__example();
lean_mark_persistent(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_append__example);
lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_reverse__example = _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_reverse__example();
lean_mark_persistent(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_reverse__example);
lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_zip__example = _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_zip__example();
lean_mark_persistent(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_zip__example);
lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_take__3 = _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_take__3();
lean_mark_persistent(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_take__3);
lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_take__10 = _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_take__10();
lean_mark_persistent(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_take__10);
lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_drop__2 = _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_drop__2();
lean_mark_persistent(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_drop__2);
lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_leq__example1 = _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_leq__example1();
lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_leq__example2 = _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_leq__example2();
lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_leq__example3 = _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_leq__example3();
lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_eq__example1 = _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_eq__example1();
lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_eq__example2 = _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_eq__example2();
lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_gcd__example1 = _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_gcd__example1();
lean_mark_persistent(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_gcd__example1);
lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_gcd__example2 = _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_gcd__example2();
lean_mark_persistent(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_gcd__example2);
lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_gcd__example3 = _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_gcd__example3();
lean_mark_persistent(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_gcd__example3);
lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_sort__example = _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_sort__example();
lean_mark_persistent(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_sort__example);
lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_rev__example = _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_rev__example();
lean_mark_persistent(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_EquationCompiler_rev__example);
return lean_io_result_mk_ok(lean_box(0));
}
#ifdef __cplusplus
}
#endif
