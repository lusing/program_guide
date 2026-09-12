// Lean compiler output
// Module: Lean4Tutorial.Examples.PatternMatching.ListRecursion
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
lean_object* l_instBEqOfDecidableEq___redArg___lam__0___boxed(lean_object*, lean_object*, lean_object*);
uint8_t l_List_elem___redArg(lean_object*, lean_object*, lean_object*);
lean_object* lean_nat_add(lean_object*, lean_object*);
lean_object* lean_string_length(lean_object*);
uint8_t lean_nat_dec_lt(lean_object*, lean_object*);
uint8_t l_List_elem___at___00Lean_Meta_Occurrences_contains_spec__0(lean_object*, lean_object*);
lean_object* l_Nat_add___boxed(lean_object*, lean_object*);
lean_object* lean_nat_mod(lean_object*, lean_object*);
uint8_t lean_nat_dec_le(lean_object*, lean_object*);
lean_object* l_String_length___boxed(lean_object*);
lean_object* lean_nat_mul(lean_object*, lean_object*);
lean_object* l_Nat_mul___boxed(lean_object*, lean_object*);
lean_object* l_Nat_reprFast(lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_length___redArg(lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_length___redArg___boxed(lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_length(lean_object*, lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_length___boxed(lean_object*, lean_object*);
static lean_once_cell_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_len1___closed__0_once = LEAN_ONCE_CELL_INITIALIZER;
static lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_len1___closed__0;
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_len1;
static const lean_ctor_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_len2___closed__0_value = {.m_header = {.m_rc = 0, .m_cs_sz = sizeof(lean_ctor_object) + sizeof(void*)*2 + 0, .m_other = 2, .m_tag = 1}, .m_objs = {((lean_object*)(((size_t)(1) << 1) | 1)),((lean_object*)(((size_t)(0) << 1) | 1))}};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_len2___closed__0 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_len2___closed__0_value;
static lean_once_cell_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_len2___closed__1_once = LEAN_ONCE_CELL_INITIALIZER;
static lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_len2___closed__1;
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_len2;
static const lean_ctor_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_len3___closed__0_value = {.m_header = {.m_rc = 0, .m_cs_sz = sizeof(lean_ctor_object) + sizeof(void*)*2 + 0, .m_other = 2, .m_tag = 1}, .m_objs = {((lean_object*)(((size_t)(5) << 1) | 1)),((lean_object*)(((size_t)(0) << 1) | 1))}};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_len3___closed__0 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_len3___closed__0_value;
static const lean_ctor_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_len3___closed__1_value = {.m_header = {.m_rc = 0, .m_cs_sz = sizeof(lean_ctor_object) + sizeof(void*)*2 + 0, .m_other = 2, .m_tag = 1}, .m_objs = {((lean_object*)(((size_t)(4) << 1) | 1)),((lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_len3___closed__0_value)}};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_len3___closed__1 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_len3___closed__1_value;
static const lean_ctor_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_len3___closed__2_value = {.m_header = {.m_rc = 0, .m_cs_sz = sizeof(lean_ctor_object) + sizeof(void*)*2 + 0, .m_other = 2, .m_tag = 1}, .m_objs = {((lean_object*)(((size_t)(3) << 1) | 1)),((lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_len3___closed__1_value)}};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_len3___closed__2 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_len3___closed__2_value;
static const lean_ctor_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_len3___closed__3_value = {.m_header = {.m_rc = 0, .m_cs_sz = sizeof(lean_ctor_object) + sizeof(void*)*2 + 0, .m_other = 2, .m_tag = 1}, .m_objs = {((lean_object*)(((size_t)(2) << 1) | 1)),((lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_len3___closed__2_value)}};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_len3___closed__3 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_len3___closed__3_value;
static const lean_ctor_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_len3___closed__4_value = {.m_header = {.m_rc = 0, .m_cs_sz = sizeof(lean_ctor_object) + sizeof(void*)*2 + 0, .m_other = 2, .m_tag = 1}, .m_objs = {((lean_object*)(((size_t)(1) << 1) | 1)),((lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_len3___closed__3_value)}};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_len3___closed__4 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_len3___closed__4_value;
static lean_once_cell_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_len3___closed__5_once = LEAN_ONCE_CELL_INITIALIZER;
static lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_len3___closed__5;
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_len3;
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_map___redArg(lean_object*, lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_map(lean_object*, lean_object*, lean_object*, lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_map__double___lam__0(lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_map__double___lam__0___boxed(lean_object*);
static const lean_closure_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_map__double___closed__0_value = {.m_header = {.m_rc = 0, .m_cs_sz = sizeof(lean_closure_object) + sizeof(void*)*0, .m_other = 0, .m_tag = 245}, .m_fun = (void*)lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_map__double___lam__0___boxed, .m_arity = 1, .m_num_fixed = 0, .m_objs = {} };
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_map__double___closed__0 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_map__double___closed__0_value;
static const lean_ctor_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_map__double___closed__1_value = {.m_header = {.m_rc = 0, .m_cs_sz = sizeof(lean_ctor_object) + sizeof(void*)*2 + 0, .m_other = 2, .m_tag = 1}, .m_objs = {((lean_object*)(((size_t)(3) << 1) | 1)),((lean_object*)(((size_t)(0) << 1) | 1))}};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_map__double___closed__1 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_map__double___closed__1_value;
static const lean_ctor_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_map__double___closed__2_value = {.m_header = {.m_rc = 0, .m_cs_sz = sizeof(lean_ctor_object) + sizeof(void*)*2 + 0, .m_other = 2, .m_tag = 1}, .m_objs = {((lean_object*)(((size_t)(2) << 1) | 1)),((lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_map__double___closed__1_value)}};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_map__double___closed__2 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_map__double___closed__2_value;
static const lean_ctor_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_map__double___closed__3_value = {.m_header = {.m_rc = 0, .m_cs_sz = sizeof(lean_ctor_object) + sizeof(void*)*2 + 0, .m_other = 2, .m_tag = 1}, .m_objs = {((lean_object*)(((size_t)(1) << 1) | 1)),((lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_map__double___closed__2_value)}};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_map__double___closed__3 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_map__double___closed__3_value;
static lean_once_cell_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_map__double___closed__4_once = LEAN_ONCE_CELL_INITIALIZER;
static lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_map__double___closed__4;
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_map__double;
static const lean_closure_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_map__toString___closed__0_value = {.m_header = {.m_rc = 0, .m_cs_sz = sizeof(lean_closure_object) + sizeof(void*)*0, .m_other = 0, .m_tag = 245}, .m_fun = (void*)l_Nat_reprFast, .m_arity = 1, .m_num_fixed = 0, .m_objs = {} };
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_map__toString___closed__0 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_map__toString___closed__0_value;
static lean_once_cell_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_map__toString___closed__1_once = LEAN_ONCE_CELL_INITIALIZER;
static lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_map__toString___closed__1;
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_map__toString;
static const lean_closure_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_map__length___closed__0_value = {.m_header = {.m_rc = 0, .m_cs_sz = sizeof(lean_closure_object) + sizeof(void*)*0, .m_other = 0, .m_tag = 245}, .m_fun = (void*)l_String_length___boxed, .m_arity = 1, .m_num_fixed = 0, .m_objs = {} };
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_map__length___closed__0 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_map__length___closed__0_value;
static const lean_string_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_map__length___closed__1_value = {.m_header = {.m_rc = 0, .m_cs_sz = 0, .m_other = 0, .m_tag = 249}, .m_size = 6, .m_capacity = 6, .m_length = 5, .m_data = "hello"};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_map__length___closed__1 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_map__length___closed__1_value;
static const lean_string_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_map__length___closed__2_value = {.m_header = {.m_rc = 0, .m_cs_sz = 0, .m_other = 0, .m_tag = 249}, .m_size = 6, .m_capacity = 6, .m_length = 5, .m_data = "world"};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_map__length___closed__2 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_map__length___closed__2_value;
static const lean_string_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_map__length___closed__3_value = {.m_header = {.m_rc = 0, .m_cs_sz = 0, .m_other = 0, .m_tag = 249}, .m_size = 5, .m_capacity = 5, .m_length = 4, .m_data = "lean"};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_map__length___closed__3 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_map__length___closed__3_value;
static const lean_ctor_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_map__length___closed__4_value = {.m_header = {.m_rc = 0, .m_cs_sz = sizeof(lean_ctor_object) + sizeof(void*)*2 + 0, .m_other = 2, .m_tag = 1}, .m_objs = {((lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_map__length___closed__3_value),((lean_object*)(((size_t)(0) << 1) | 1))}};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_map__length___closed__4 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_map__length___closed__4_value;
static const lean_ctor_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_map__length___closed__5_value = {.m_header = {.m_rc = 0, .m_cs_sz = sizeof(lean_ctor_object) + sizeof(void*)*2 + 0, .m_other = 2, .m_tag = 1}, .m_objs = {((lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_map__length___closed__2_value),((lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_map__length___closed__4_value)}};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_map__length___closed__5 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_map__length___closed__5_value;
static const lean_ctor_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_map__length___closed__6_value = {.m_header = {.m_rc = 0, .m_cs_sz = sizeof(lean_ctor_object) + sizeof(void*)*2 + 0, .m_other = 2, .m_tag = 1}, .m_objs = {((lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_map__length___closed__1_value),((lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_map__length___closed__5_value)}};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_map__length___closed__6 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_map__length___closed__6_value;
static lean_once_cell_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_map__length___closed__7_once = LEAN_ONCE_CELL_INITIALIZER;
static lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_map__length___closed__7;
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_map__length;
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_filter___redArg(lean_object*, lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_filter(lean_object*, lean_object*, lean_object*);
LEAN_EXPORT uint8_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_filter__even___lam__0(lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_filter__even___lam__0___boxed(lean_object*);
static const lean_closure_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_filter__even___closed__0_value = {.m_header = {.m_rc = 0, .m_cs_sz = sizeof(lean_closure_object) + sizeof(void*)*0, .m_other = 0, .m_tag = 245}, .m_fun = (void*)lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_filter__even___lam__0___boxed, .m_arity = 1, .m_num_fixed = 0, .m_objs = {} };
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_filter__even___closed__0 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_filter__even___closed__0_value;
static const lean_ctor_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_filter__even___closed__1_value = {.m_header = {.m_rc = 0, .m_cs_sz = sizeof(lean_ctor_object) + sizeof(void*)*2 + 0, .m_other = 2, .m_tag = 1}, .m_objs = {((lean_object*)(((size_t)(6) << 1) | 1)),((lean_object*)(((size_t)(0) << 1) | 1))}};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_filter__even___closed__1 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_filter__even___closed__1_value;
static const lean_ctor_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_filter__even___closed__2_value = {.m_header = {.m_rc = 0, .m_cs_sz = sizeof(lean_ctor_object) + sizeof(void*)*2 + 0, .m_other = 2, .m_tag = 1}, .m_objs = {((lean_object*)(((size_t)(5) << 1) | 1)),((lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_filter__even___closed__1_value)}};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_filter__even___closed__2 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_filter__even___closed__2_value;
static const lean_ctor_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_filter__even___closed__3_value = {.m_header = {.m_rc = 0, .m_cs_sz = sizeof(lean_ctor_object) + sizeof(void*)*2 + 0, .m_other = 2, .m_tag = 1}, .m_objs = {((lean_object*)(((size_t)(4) << 1) | 1)),((lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_filter__even___closed__2_value)}};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_filter__even___closed__3 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_filter__even___closed__3_value;
static const lean_ctor_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_filter__even___closed__4_value = {.m_header = {.m_rc = 0, .m_cs_sz = sizeof(lean_ctor_object) + sizeof(void*)*2 + 0, .m_other = 2, .m_tag = 1}, .m_objs = {((lean_object*)(((size_t)(3) << 1) | 1)),((lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_filter__even___closed__3_value)}};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_filter__even___closed__4 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_filter__even___closed__4_value;
static const lean_ctor_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_filter__even___closed__5_value = {.m_header = {.m_rc = 0, .m_cs_sz = sizeof(lean_ctor_object) + sizeof(void*)*2 + 0, .m_other = 2, .m_tag = 1}, .m_objs = {((lean_object*)(((size_t)(2) << 1) | 1)),((lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_filter__even___closed__4_value)}};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_filter__even___closed__5 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_filter__even___closed__5_value;
static const lean_ctor_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_filter__even___closed__6_value = {.m_header = {.m_rc = 0, .m_cs_sz = sizeof(lean_ctor_object) + sizeof(void*)*2 + 0, .m_other = 2, .m_tag = 1}, .m_objs = {((lean_object*)(((size_t)(1) << 1) | 1)),((lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_filter__even___closed__5_value)}};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_filter__even___closed__6 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_filter__even___closed__6_value;
static lean_once_cell_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_filter__even___closed__7_once = LEAN_ONCE_CELL_INITIALIZER;
static lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_filter__even___closed__7;
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_filter__even;
LEAN_EXPORT uint8_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_filter__long___lam__0(lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_filter__long___lam__0___boxed(lean_object*);
static const lean_closure_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_filter__long___closed__0_value = {.m_header = {.m_rc = 0, .m_cs_sz = sizeof(lean_closure_object) + sizeof(void*)*0, .m_other = 0, .m_tag = 245}, .m_fun = (void*)lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_filter__long___lam__0___boxed, .m_arity = 1, .m_num_fixed = 0, .m_objs = {} };
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_filter__long___closed__0 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_filter__long___closed__0_value;
static const lean_string_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_filter__long___closed__1_value = {.m_header = {.m_rc = 0, .m_cs_sz = 0, .m_other = 0, .m_tag = 249}, .m_size = 2, .m_capacity = 2, .m_length = 1, .m_data = "a"};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_filter__long___closed__1 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_filter__long___closed__1_value;
static const lean_string_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_filter__long___closed__2_value = {.m_header = {.m_rc = 0, .m_cs_sz = 0, .m_other = 0, .m_tag = 249}, .m_size = 3, .m_capacity = 3, .m_length = 2, .m_data = "bb"};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_filter__long___closed__2 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_filter__long___closed__2_value;
static const lean_string_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_filter__long___closed__3_value = {.m_header = {.m_rc = 0, .m_cs_sz = 0, .m_other = 0, .m_tag = 249}, .m_size = 4, .m_capacity = 4, .m_length = 3, .m_data = "ccc"};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_filter__long___closed__3 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_filter__long___closed__3_value;
static const lean_string_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_filter__long___closed__4_value = {.m_header = {.m_rc = 0, .m_cs_sz = 0, .m_other = 0, .m_tag = 249}, .m_size = 5, .m_capacity = 5, .m_length = 4, .m_data = "dddd"};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_filter__long___closed__4 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_filter__long___closed__4_value;
static const lean_ctor_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_filter__long___closed__5_value = {.m_header = {.m_rc = 0, .m_cs_sz = sizeof(lean_ctor_object) + sizeof(void*)*2 + 0, .m_other = 2, .m_tag = 1}, .m_objs = {((lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_filter__long___closed__4_value),((lean_object*)(((size_t)(0) << 1) | 1))}};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_filter__long___closed__5 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_filter__long___closed__5_value;
static const lean_ctor_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_filter__long___closed__6_value = {.m_header = {.m_rc = 0, .m_cs_sz = sizeof(lean_ctor_object) + sizeof(void*)*2 + 0, .m_other = 2, .m_tag = 1}, .m_objs = {((lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_filter__long___closed__3_value),((lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_filter__long___closed__5_value)}};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_filter__long___closed__6 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_filter__long___closed__6_value;
static const lean_ctor_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_filter__long___closed__7_value = {.m_header = {.m_rc = 0, .m_cs_sz = sizeof(lean_ctor_object) + sizeof(void*)*2 + 0, .m_other = 2, .m_tag = 1}, .m_objs = {((lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_filter__long___closed__2_value),((lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_filter__long___closed__6_value)}};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_filter__long___closed__7 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_filter__long___closed__7_value;
static const lean_ctor_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_filter__long___closed__8_value = {.m_header = {.m_rc = 0, .m_cs_sz = sizeof(lean_ctor_object) + sizeof(void*)*2 + 0, .m_other = 2, .m_tag = 1}, .m_objs = {((lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_filter__long___closed__1_value),((lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_filter__long___closed__7_value)}};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_filter__long___closed__8 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_filter__long___closed__8_value;
static lean_once_cell_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_filter__long___closed__9_once = LEAN_ONCE_CELL_INITIALIZER;
static lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_filter__long___closed__9;
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_filter__long;
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_foldr___redArg(lean_object*, lean_object*, lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_foldr___redArg___boxed(lean_object*, lean_object*, lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_foldr(lean_object*, lean_object*, lean_object*, lean_object*, lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_foldr___boxed(lean_object*, lean_object*, lean_object*, lean_object*, lean_object*);
static const lean_closure_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_sum___closed__0_value = {.m_header = {.m_rc = 0, .m_cs_sz = sizeof(lean_closure_object) + sizeof(void*)*0, .m_other = 0, .m_tag = 245}, .m_fun = (void*)l_Nat_add___boxed, .m_arity = 2, .m_num_fixed = 0, .m_objs = {} };
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_sum___closed__0 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_sum___closed__0_value;
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_sum(lean_object*);
static lean_once_cell_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_sum__example___closed__0_once = LEAN_ONCE_CELL_INITIALIZER;
static lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_sum__example___closed__0;
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_sum__example;
static const lean_closure_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_product___closed__0_value = {.m_header = {.m_rc = 0, .m_cs_sz = sizeof(lean_closure_object) + sizeof(void*)*0, .m_other = 0, .m_tag = 245}, .m_fun = (void*)l_Nat_mul___boxed, .m_arity = 2, .m_num_fixed = 0, .m_objs = {} };
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_product___closed__0 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_product___closed__0_value;
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_product(lean_object*);
static lean_once_cell_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_product__example___closed__0_once = LEAN_ONCE_CELL_INITIALIZER;
static lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_product__example___closed__0;
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_product__example;
LEAN_EXPORT uint8_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_all___redArg___lam__0(lean_object*, lean_object*, uint8_t);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_all___redArg___lam__0___boxed(lean_object*, lean_object*, lean_object*);
LEAN_EXPORT uint8_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_all___redArg(lean_object*, lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_all___redArg___boxed(lean_object*, lean_object*);
LEAN_EXPORT uint8_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_all(lean_object*, lean_object*, lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_all___boxed(lean_object*, lean_object*, lean_object*);
static const lean_ctor_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_all__even___closed__0_value = {.m_header = {.m_rc = 0, .m_cs_sz = sizeof(lean_ctor_object) + sizeof(void*)*2 + 0, .m_other = 2, .m_tag = 1}, .m_objs = {((lean_object*)(((size_t)(4) << 1) | 1)),((lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_filter__even___closed__1_value)}};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_all__even___closed__0 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_all__even___closed__0_value;
static const lean_ctor_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_all__even___closed__1_value = {.m_header = {.m_rc = 0, .m_cs_sz = sizeof(lean_ctor_object) + sizeof(void*)*2 + 0, .m_other = 2, .m_tag = 1}, .m_objs = {((lean_object*)(((size_t)(2) << 1) | 1)),((lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_all__even___closed__0_value)}};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_all__even___closed__1 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_all__even___closed__1_value;
static lean_once_cell_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_all__even___closed__2_once = LEAN_ONCE_CELL_INITIALIZER;
static uint8_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_all__even___closed__2;
LEAN_EXPORT uint8_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_all__even;
static const lean_ctor_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_all__even2___closed__0_value = {.m_header = {.m_rc = 0, .m_cs_sz = sizeof(lean_ctor_object) + sizeof(void*)*2 + 0, .m_other = 2, .m_tag = 1}, .m_objs = {((lean_object*)(((size_t)(3) << 1) | 1)),((lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_filter__even___closed__1_value)}};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_all__even2___closed__0 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_all__even2___closed__0_value;
static const lean_ctor_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_all__even2___closed__1_value = {.m_header = {.m_rc = 0, .m_cs_sz = sizeof(lean_ctor_object) + sizeof(void*)*2 + 0, .m_other = 2, .m_tag = 1}, .m_objs = {((lean_object*)(((size_t)(2) << 1) | 1)),((lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_all__even2___closed__0_value)}};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_all__even2___closed__1 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_all__even2___closed__1_value;
static lean_once_cell_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_all__even2___closed__2_once = LEAN_ONCE_CELL_INITIALIZER;
static uint8_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_all__even2___closed__2;
LEAN_EXPORT uint8_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_all__even2;
LEAN_EXPORT uint8_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_any___redArg___lam__0(lean_object*, lean_object*, uint8_t);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_any___redArg___lam__0___boxed(lean_object*, lean_object*, lean_object*);
LEAN_EXPORT uint8_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_any___redArg(lean_object*, lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_any___redArg___boxed(lean_object*, lean_object*);
LEAN_EXPORT uint8_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_any(lean_object*, lean_object*, lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_any___boxed(lean_object*, lean_object*, lean_object*);
static const lean_ctor_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_any__even___closed__0_value = {.m_header = {.m_rc = 0, .m_cs_sz = sizeof(lean_ctor_object) + sizeof(void*)*2 + 0, .m_other = 2, .m_tag = 1}, .m_objs = {((lean_object*)(((size_t)(3) << 1) | 1)),((lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_len3___closed__0_value)}};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_any__even___closed__0 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_any__even___closed__0_value;
static const lean_ctor_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_any__even___closed__1_value = {.m_header = {.m_rc = 0, .m_cs_sz = sizeof(lean_ctor_object) + sizeof(void*)*2 + 0, .m_other = 2, .m_tag = 1}, .m_objs = {((lean_object*)(((size_t)(1) << 1) | 1)),((lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_any__even___closed__0_value)}};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_any__even___closed__1 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_any__even___closed__1_value;
static lean_once_cell_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_any__even___closed__2_once = LEAN_ONCE_CELL_INITIALIZER;
static uint8_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_any__even___closed__2;
LEAN_EXPORT uint8_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_any__even;
static lean_once_cell_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_any__even2___closed__0_once = LEAN_ONCE_CELL_INITIALIZER;
static uint8_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_any__even2___closed__0;
LEAN_EXPORT uint8_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_any__even2;
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_foldl___redArg(lean_object*, lean_object*, lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_foldl(lean_object*, lean_object*, lean_object*, lean_object*, lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_reverse___redArg___lam__0(lean_object*, lean_object*);
static const lean_closure_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_reverse___redArg___closed__0_value = {.m_header = {.m_rc = 0, .m_cs_sz = sizeof(lean_closure_object) + sizeof(void*)*0, .m_other = 0, .m_tag = 245}, .m_fun = (void*)lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_reverse___redArg___lam__0, .m_arity = 2, .m_num_fixed = 0, .m_objs = {} };
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_reverse___redArg___closed__0 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_reverse___redArg___closed__0_value;
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_reverse___redArg(lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_reverse(lean_object*, lean_object*);
static lean_once_cell_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_reverse__example___closed__0_once = LEAN_ONCE_CELL_INITIALIZER;
static lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_reverse__example___closed__0;
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_reverse__example;
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_sum__l(lean_object*);
static lean_once_cell_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_sum__l__example___closed__0_once = LEAN_ONCE_CELL_INITIALIZER;
static lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_sum__l__example___closed__0;
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_sum__l__example;
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_append___redArg(lean_object*, lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_append___redArg___boxed(lean_object*, lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_append(lean_object*, lean_object*, lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_append___boxed(lean_object*, lean_object*, lean_object*);
static const lean_ctor_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_append__example___closed__0_value = {.m_header = {.m_rc = 0, .m_cs_sz = sizeof(lean_ctor_object) + sizeof(void*)*2 + 0, .m_other = 2, .m_tag = 1}, .m_objs = {((lean_object*)(((size_t)(2) << 1) | 1)),((lean_object*)(((size_t)(0) << 1) | 1))}};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_append__example___closed__0 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_append__example___closed__0_value;
static const lean_ctor_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_append__example___closed__1_value = {.m_header = {.m_rc = 0, .m_cs_sz = sizeof(lean_ctor_object) + sizeof(void*)*2 + 0, .m_other = 2, .m_tag = 1}, .m_objs = {((lean_object*)(((size_t)(1) << 1) | 1)),((lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_append__example___closed__0_value)}};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_append__example___closed__1 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_append__example___closed__1_value;
static const lean_ctor_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_append__example___closed__2_value = {.m_header = {.m_rc = 0, .m_cs_sz = sizeof(lean_ctor_object) + sizeof(void*)*2 + 0, .m_other = 2, .m_tag = 1}, .m_objs = {((lean_object*)(((size_t)(4) << 1) | 1)),((lean_object*)(((size_t)(0) << 1) | 1))}};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_append__example___closed__2 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_append__example___closed__2_value;
static const lean_ctor_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_append__example___closed__3_value = {.m_header = {.m_rc = 0, .m_cs_sz = sizeof(lean_ctor_object) + sizeof(void*)*2 + 0, .m_other = 2, .m_tag = 1}, .m_objs = {((lean_object*)(((size_t)(3) << 1) | 1)),((lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_append__example___closed__2_value)}};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_append__example___closed__3 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_append__example___closed__3_value;
static lean_once_cell_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_append__example___closed__4_once = LEAN_ONCE_CELL_INITIALIZER;
static lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_append__example___closed__4;
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_append__example;
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_flatMap___redArg(lean_object*, lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_flatMap(lean_object*, lean_object*, lean_object*, lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_dup__and__double___lam__0(lean_object*);
static const lean_closure_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_dup__and__double___closed__0_value = {.m_header = {.m_rc = 0, .m_cs_sz = sizeof(lean_closure_object) + sizeof(void*)*0, .m_other = 0, .m_tag = 245}, .m_fun = (void*)lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_dup__and__double___lam__0, .m_arity = 1, .m_num_fixed = 0, .m_objs = {} };
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_dup__and__double___closed__0 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_dup__and__double___closed__0_value;
static lean_once_cell_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_dup__and__double___closed__1_once = LEAN_ONCE_CELL_INITIALIZER;
static lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_dup__and__double___closed__1;
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_dup__and__double;
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_zip___redArg(lean_object*, lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_zip(lean_object*, lean_object*, lean_object*, lean_object*);
static const lean_string_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_zip__example___closed__0_value = {.m_header = {.m_rc = 0, .m_cs_sz = 0, .m_other = 0, .m_tag = 249}, .m_size = 2, .m_capacity = 2, .m_length = 1, .m_data = "b"};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_zip__example___closed__0 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_zip__example___closed__0_value;
static const lean_string_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_zip__example___closed__1_value = {.m_header = {.m_rc = 0, .m_cs_sz = 0, .m_other = 0, .m_tag = 249}, .m_size = 2, .m_capacity = 2, .m_length = 1, .m_data = "c"};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_zip__example___closed__1 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_zip__example___closed__1_value;
static const lean_ctor_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_zip__example___closed__2_value = {.m_header = {.m_rc = 0, .m_cs_sz = sizeof(lean_ctor_object) + sizeof(void*)*2 + 0, .m_other = 2, .m_tag = 1}, .m_objs = {((lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_zip__example___closed__1_value),((lean_object*)(((size_t)(0) << 1) | 1))}};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_zip__example___closed__2 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_zip__example___closed__2_value;
static const lean_ctor_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_zip__example___closed__3_value = {.m_header = {.m_rc = 0, .m_cs_sz = sizeof(lean_ctor_object) + sizeof(void*)*2 + 0, .m_other = 2, .m_tag = 1}, .m_objs = {((lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_zip__example___closed__0_value),((lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_zip__example___closed__2_value)}};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_zip__example___closed__3 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_zip__example___closed__3_value;
static const lean_ctor_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_zip__example___closed__4_value = {.m_header = {.m_rc = 0, .m_cs_sz = sizeof(lean_ctor_object) + sizeof(void*)*2 + 0, .m_other = 2, .m_tag = 1}, .m_objs = {((lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_filter__long___closed__1_value),((lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_zip__example___closed__3_value)}};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_zip__example___closed__4 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_zip__example___closed__4_value;
static lean_once_cell_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_zip__example___closed__5_once = LEAN_ONCE_CELL_INITIALIZER;
static lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_zip__example___closed__5;
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_zip__example;
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_zipWith___redArg(lean_object*, lean_object*, lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_zipWith(lean_object*, lean_object*, lean_object*, lean_object*, lean_object*, lean_object*);
static lean_once_cell_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_zipWith__add___closed__0_once = LEAN_ONCE_CELL_INITIALIZER;
static lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_zipWith__add___closed__0;
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_zipWith__add;
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_take___redArg(lean_object*, lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_take___redArg___boxed(lean_object*, lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_take(lean_object*, lean_object*, lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_take___boxed(lean_object*, lean_object*, lean_object*);
static lean_once_cell_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_take__3___closed__0_once = LEAN_ONCE_CELL_INITIALIZER;
static lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_take__3___closed__0;
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_take__3;
static lean_once_cell_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_take__10___closed__0_once = LEAN_ONCE_CELL_INITIALIZER;
static lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_take__10___closed__0;
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_take__10;
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_drop___redArg(lean_object*, lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_drop___redArg___boxed(lean_object*, lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_drop(lean_object*, lean_object*, lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_drop___boxed(lean_object*, lean_object*, lean_object*);
static lean_once_cell_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_drop__2___closed__0_once = LEAN_ONCE_CELL_INITIALIZER;
static lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_drop__2___closed__0;
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_drop__2;
static lean_once_cell_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_drop__10___closed__0_once = LEAN_ONCE_CELL_INITIALIZER;
static lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_drop__10___closed__0;
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_drop__10;
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_get_x3f___redArg(lean_object*, lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_get_x3f___redArg___boxed(lean_object*, lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_get_x3f(lean_object*, lean_object*, lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_get_x3f___boxed(lean_object*, lean_object*, lean_object*);
static const lean_ctor_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_get__2___closed__0_value = {.m_header = {.m_rc = 0, .m_cs_sz = sizeof(lean_ctor_object) + sizeof(void*)*2 + 0, .m_other = 2, .m_tag = 1}, .m_objs = {((lean_object*)(((size_t)(40) << 1) | 1)),((lean_object*)(((size_t)(0) << 1) | 1))}};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_get__2___closed__0 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_get__2___closed__0_value;
static const lean_ctor_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_get__2___closed__1_value = {.m_header = {.m_rc = 0, .m_cs_sz = sizeof(lean_ctor_object) + sizeof(void*)*2 + 0, .m_other = 2, .m_tag = 1}, .m_objs = {((lean_object*)(((size_t)(30) << 1) | 1)),((lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_get__2___closed__0_value)}};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_get__2___closed__1 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_get__2___closed__1_value;
static const lean_ctor_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_get__2___closed__2_value = {.m_header = {.m_rc = 0, .m_cs_sz = sizeof(lean_ctor_object) + sizeof(void*)*2 + 0, .m_other = 2, .m_tag = 1}, .m_objs = {((lean_object*)(((size_t)(20) << 1) | 1)),((lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_get__2___closed__1_value)}};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_get__2___closed__2 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_get__2___closed__2_value;
static const lean_ctor_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_get__2___closed__3_value = {.m_header = {.m_rc = 0, .m_cs_sz = sizeof(lean_ctor_object) + sizeof(void*)*2 + 0, .m_other = 2, .m_tag = 1}, .m_objs = {((lean_object*)(((size_t)(10) << 1) | 1)),((lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_get__2___closed__2_value)}};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_get__2___closed__3 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_get__2___closed__3_value;
static lean_once_cell_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_get__2___closed__4_once = LEAN_ONCE_CELL_INITIALIZER;
static lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_get__2___closed__4;
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_get__2;
static const lean_ctor_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_get__10___closed__0_value = {.m_header = {.m_rc = 0, .m_cs_sz = sizeof(lean_ctor_object) + sizeof(void*)*2 + 0, .m_other = 2, .m_tag = 1}, .m_objs = {((lean_object*)(((size_t)(30) << 1) | 1)),((lean_object*)(((size_t)(0) << 1) | 1))}};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_get__10___closed__0 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_get__10___closed__0_value;
static const lean_ctor_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_get__10___closed__1_value = {.m_header = {.m_rc = 0, .m_cs_sz = sizeof(lean_ctor_object) + sizeof(void*)*2 + 0, .m_other = 2, .m_tag = 1}, .m_objs = {((lean_object*)(((size_t)(20) << 1) | 1)),((lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_get__10___closed__0_value)}};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_get__10___closed__1 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_get__10___closed__1_value;
static const lean_ctor_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_get__10___closed__2_value = {.m_header = {.m_rc = 0, .m_cs_sz = sizeof(lean_ctor_object) + sizeof(void*)*2 + 0, .m_other = 2, .m_tag = 1}, .m_objs = {((lean_object*)(((size_t)(10) << 1) | 1)),((lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_get__10___closed__1_value)}};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_get__10___closed__2 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_get__10___closed__2_value;
static lean_once_cell_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_get__10___closed__3_once = LEAN_ONCE_CELL_INITIALIZER;
static lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_get__10___closed__3;
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_get__10;
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_set_x3f___redArg(lean_object*, lean_object*, lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_set_x3f___redArg___boxed(lean_object*, lean_object*, lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_set_x3f(lean_object*, lean_object*, lean_object*, lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_set_x3f___boxed(lean_object*, lean_object*, lean_object*, lean_object*);
static lean_once_cell_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_set__2___closed__0_once = LEAN_ONCE_CELL_INITIALIZER;
static lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_set__2___closed__0;
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_set__2;
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_find_x3f___redArg(lean_object*, lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_find_x3f(lean_object*, lean_object*, lean_object*);
static const lean_ctor_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_find__even___closed__0_value = {.m_header = {.m_rc = 0, .m_cs_sz = sizeof(lean_ctor_object) + sizeof(void*)*2 + 0, .m_other = 2, .m_tag = 1}, .m_objs = {((lean_object*)(((size_t)(1) << 1) | 1)),((lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_filter__even___closed__4_value)}};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_find__even___closed__0 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_find__even___closed__0_value;
static lean_once_cell_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_find__even___closed__1_once = LEAN_ONCE_CELL_INITIALIZER;
static lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_find__even___closed__1;
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_find__even;
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_findIndex_x3f_go___redArg(lean_object*, lean_object*, lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_findIndex_x3f_go(lean_object*, lean_object*, lean_object*, lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_findIndex_x3f___redArg(lean_object*, lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_findIndex_x3f(lean_object*, lean_object*, lean_object*);
LEAN_EXPORT uint8_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_find__index___lam__0(lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_find__index___lam__0___boxed(lean_object*);
static const lean_closure_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_find__index___closed__0_value = {.m_header = {.m_rc = 0, .m_cs_sz = sizeof(lean_closure_object) + sizeof(void*)*0, .m_other = 0, .m_tag = 245}, .m_fun = (void*)lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_find__index___lam__0___boxed, .m_arity = 1, .m_num_fixed = 0, .m_objs = {} };
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_find__index___closed__0 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_find__index___closed__0_value;
static const lean_ctor_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_find__index___closed__1_value = {.m_header = {.m_rc = 0, .m_cs_sz = sizeof(lean_ctor_object) + sizeof(void*)*2 + 0, .m_other = 2, .m_tag = 1}, .m_objs = {((lean_object*)(((size_t)(2) << 1) | 1)),((lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_append__example___closed__3_value)}};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_find__index___closed__1 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_find__index___closed__1_value;
static const lean_ctor_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_find__index___closed__2_value = {.m_header = {.m_rc = 0, .m_cs_sz = sizeof(lean_ctor_object) + sizeof(void*)*2 + 0, .m_other = 2, .m_tag = 1}, .m_objs = {((lean_object*)(((size_t)(1) << 1) | 1)),((lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_find__index___closed__1_value)}};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_find__index___closed__2 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_find__index___closed__2_value;
static lean_once_cell_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_find__index___closed__3_once = LEAN_ONCE_CELL_INITIALIZER;
static lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_find__index___closed__3;
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_find__index;
LEAN_EXPORT uint8_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_isSorted(lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_isSorted___boxed(lean_object*);
static lean_once_cell_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_sorted__true___closed__0_once = LEAN_ONCE_CELL_INITIALIZER;
static uint8_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_sorted__true___closed__0;
LEAN_EXPORT uint8_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_sorted__true;
static const lean_ctor_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_sorted__false___closed__0_value = {.m_header = {.m_rc = 0, .m_cs_sz = sizeof(lean_ctor_object) + sizeof(void*)*2 + 0, .m_other = 2, .m_tag = 1}, .m_objs = {((lean_object*)(((size_t)(2) << 1) | 1)),((lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_append__example___closed__2_value)}};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_sorted__false___closed__0 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_sorted__false___closed__0_value;
static const lean_ctor_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_sorted__false___closed__1_value = {.m_header = {.m_rc = 0, .m_cs_sz = sizeof(lean_ctor_object) + sizeof(void*)*2 + 0, .m_other = 2, .m_tag = 1}, .m_objs = {((lean_object*)(((size_t)(3) << 1) | 1)),((lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_sorted__false___closed__0_value)}};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_sorted__false___closed__1 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_sorted__false___closed__1_value;
static const lean_ctor_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_sorted__false___closed__2_value = {.m_header = {.m_rc = 0, .m_cs_sz = sizeof(lean_ctor_object) + sizeof(void*)*2 + 0, .m_other = 2, .m_tag = 1}, .m_objs = {((lean_object*)(((size_t)(1) << 1) | 1)),((lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_sorted__false___closed__1_value)}};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_sorted__false___closed__2 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_sorted__false___closed__2_value;
static lean_once_cell_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_sorted__false___closed__3_once = LEAN_ONCE_CELL_INITIALIZER;
static uint8_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_sorted__false___closed__3;
LEAN_EXPORT uint8_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_sorted__false;
LEAN_EXPORT uint8_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_hasDuplicates___redArg(lean_object*, lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_hasDuplicates___redArg___boxed(lean_object*, lean_object*);
LEAN_EXPORT uint8_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_hasDuplicates(lean_object*, lean_object*, lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_hasDuplicates___boxed(lean_object*, lean_object*, lean_object*);
LEAN_EXPORT uint8_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_hasDuplicates___at___00Lean4Tutorial_Examples_PatternMatching_ListRecursion_dup__true_spec__0(lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_hasDuplicates___at___00Lean4Tutorial_Examples_PatternMatching_ListRecursion_dup__true_spec__0___boxed(lean_object*);
static const lean_ctor_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_dup__true___closed__0_value = {.m_header = {.m_rc = 0, .m_cs_sz = sizeof(lean_ctor_object) + sizeof(void*)*2 + 0, .m_other = 2, .m_tag = 1}, .m_objs = {((lean_object*)(((size_t)(3) << 1) | 1)),((lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_append__example___closed__0_value)}};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_dup__true___closed__0 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_dup__true___closed__0_value;
static const lean_ctor_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_dup__true___closed__1_value = {.m_header = {.m_rc = 0, .m_cs_sz = sizeof(lean_ctor_object) + sizeof(void*)*2 + 0, .m_other = 2, .m_tag = 1}, .m_objs = {((lean_object*)(((size_t)(2) << 1) | 1)),((lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_dup__true___closed__0_value)}};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_dup__true___closed__1 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_dup__true___closed__1_value;
static const lean_ctor_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_dup__true___closed__2_value = {.m_header = {.m_rc = 0, .m_cs_sz = sizeof(lean_ctor_object) + sizeof(void*)*2 + 0, .m_other = 2, .m_tag = 1}, .m_objs = {((lean_object*)(((size_t)(1) << 1) | 1)),((lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_dup__true___closed__1_value)}};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_dup__true___closed__2 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_dup__true___closed__2_value;
static lean_once_cell_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_dup__true___closed__3_once = LEAN_ONCE_CELL_INITIALIZER;
static uint8_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_dup__true___closed__3;
LEAN_EXPORT uint8_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_dup__true;
static lean_once_cell_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_dup__false___closed__0_once = LEAN_ONCE_CELL_INITIALIZER;
static uint8_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_dup__false___closed__0;
LEAN_EXPORT uint8_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_dup__false;
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial___private_Lean4Tutorial_Examples_PatternMatching_ListRecursion_0__Lean4Tutorial_Examples_PatternMatching_ListRecursion_length_match__1_splitter___redArg(lean_object*, lean_object*, lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial___private_Lean4Tutorial_Examples_PatternMatching_ListRecursion_0__Lean4Tutorial_Examples_PatternMatching_ListRecursion_length_match__1_splitter(lean_object*, lean_object*, lean_object*, lean_object*, lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial___private_Lean4Tutorial_Examples_PatternMatching_ListRecursion_0__Lean4Tutorial_Examples_PatternMatching_ListRecursion_append_match__1_splitter___redArg(lean_object*, lean_object*, lean_object*, lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial___private_Lean4Tutorial_Examples_PatternMatching_ListRecursion_0__Lean4Tutorial_Examples_PatternMatching_ListRecursion_append_match__1_splitter(lean_object*, lean_object*, lean_object*, lean_object*, lean_object*, lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_length___redArg(lean_object* v_x_1_){
_start:
{
if (lean_obj_tag(v_x_1_) == 0)
{
lean_object* v___x_2_; 
v___x_2_ = lean_unsigned_to_nat(0u);
return v___x_2_;
}
else
{
lean_object* v_tail_3_; lean_object* v___x_4_; lean_object* v___x_5_; lean_object* v___x_6_; 
v_tail_3_ = lean_ctor_get(v_x_1_, 1);
v___x_4_ = lean_unsigned_to_nat(1u);
v___x_5_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_length___redArg(v_tail_3_);
v___x_6_ = lean_nat_add(v___x_4_, v___x_5_);
lean_dec(v___x_5_);
return v___x_6_;
}
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_length___redArg___boxed(lean_object* v_x_7_){
_start:
{
lean_object* v_res_8_; 
v_res_8_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_length___redArg(v_x_7_);
lean_dec(v_x_7_);
return v_res_8_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_length(lean_object* v_00_u03b1_9_, lean_object* v_x_10_){
_start:
{
lean_object* v___x_11_; 
v___x_11_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_length___redArg(v_x_10_);
return v___x_11_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_length___boxed(lean_object* v_00_u03b1_12_, lean_object* v_x_13_){
_start:
{
lean_object* v_res_14_; 
v_res_14_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_length(v_00_u03b1_12_, v_x_13_);
lean_dec(v_x_13_);
return v_res_14_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_len1___closed__0(void){
_start:
{
lean_object* v___x_15_; lean_object* v___x_16_; 
v___x_15_ = lean_box(0);
v___x_16_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_length___redArg(v___x_15_);
return v___x_16_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_len1(void){
_start:
{
lean_object* v___x_17_; 
v___x_17_ = lean_obj_once(&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_len1___closed__0, &lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_len1___closed__0_once, _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_len1___closed__0);
return v___x_17_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_len2___closed__1(void){
_start:
{
lean_object* v___x_21_; lean_object* v___x_22_; 
v___x_21_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_len2___closed__0));
v___x_22_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_length___redArg(v___x_21_);
return v___x_22_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_len2(void){
_start:
{
lean_object* v___x_23_; 
v___x_23_ = lean_obj_once(&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_len2___closed__1, &lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_len2___closed__1_once, _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_len2___closed__1);
return v___x_23_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_len3___closed__5(void){
_start:
{
lean_object* v___x_39_; lean_object* v___x_40_; 
v___x_39_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_len3___closed__4));
v___x_40_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_length___redArg(v___x_39_);
return v___x_40_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_len3(void){
_start:
{
lean_object* v___x_41_; 
v___x_41_ = lean_obj_once(&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_len3___closed__5, &lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_len3___closed__5_once, _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_len3___closed__5);
return v___x_41_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_map___redArg(lean_object* v_f_42_, lean_object* v_x_43_){
_start:
{
if (lean_obj_tag(v_x_43_) == 0)
{
lean_object* v___x_44_; 
lean_dec(v_f_42_);
v___x_44_ = lean_box(0);
return v___x_44_;
}
else
{
lean_object* v_head_45_; lean_object* v_tail_46_; lean_object* v___x_48_; uint8_t v_isShared_49_; uint8_t v_isSharedCheck_55_; 
v_head_45_ = lean_ctor_get(v_x_43_, 0);
v_tail_46_ = lean_ctor_get(v_x_43_, 1);
v_isSharedCheck_55_ = !lean_is_exclusive(v_x_43_);
if (v_isSharedCheck_55_ == 0)
{
v___x_48_ = v_x_43_;
v_isShared_49_ = v_isSharedCheck_55_;
goto v_resetjp_47_;
}
else
{
lean_inc(v_tail_46_);
lean_inc(v_head_45_);
lean_dec(v_x_43_);
v___x_48_ = lean_box(0);
v_isShared_49_ = v_isSharedCheck_55_;
goto v_resetjp_47_;
}
v_resetjp_47_:
{
lean_object* v___x_50_; lean_object* v___x_51_; lean_object* v___x_53_; 
lean_inc(v_f_42_);
v___x_50_ = lean_apply_1(v_f_42_, v_head_45_);
v___x_51_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_map___redArg(v_f_42_, v_tail_46_);
if (v_isShared_49_ == 0)
{
lean_ctor_set(v___x_48_, 1, v___x_51_);
lean_ctor_set(v___x_48_, 0, v___x_50_);
v___x_53_ = v___x_48_;
goto v_reusejp_52_;
}
else
{
lean_object* v_reuseFailAlloc_54_; 
v_reuseFailAlloc_54_ = lean_alloc_ctor(1, 2, 0);
lean_ctor_set(v_reuseFailAlloc_54_, 0, v___x_50_);
lean_ctor_set(v_reuseFailAlloc_54_, 1, v___x_51_);
v___x_53_ = v_reuseFailAlloc_54_;
goto v_reusejp_52_;
}
v_reusejp_52_:
{
return v___x_53_;
}
}
}
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_map(lean_object* v_00_u03b1_56_, lean_object* v_00_u03b2_57_, lean_object* v_f_58_, lean_object* v_x_59_){
_start:
{
lean_object* v___x_60_; 
v___x_60_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_map___redArg(v_f_58_, v_x_59_);
return v___x_60_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_map__double___lam__0(lean_object* v_x_61_){
_start:
{
lean_object* v___x_62_; lean_object* v___x_63_; 
v___x_62_ = lean_unsigned_to_nat(2u);
v___x_63_ = lean_nat_mul(v_x_61_, v___x_62_);
return v___x_63_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_map__double___lam__0___boxed(lean_object* v_x_64_){
_start:
{
lean_object* v_res_65_; 
v_res_65_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_map__double___lam__0(v_x_64_);
lean_dec(v_x_64_);
return v_res_65_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_map__double___closed__4(void){
_start:
{
lean_object* v___x_76_; lean_object* v___f_77_; lean_object* v___x_78_; 
v___x_76_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_map__double___closed__3));
v___f_77_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_map__double___closed__0));
v___x_78_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_map___redArg(v___f_77_, v___x_76_);
return v___x_78_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_map__double(void){
_start:
{
lean_object* v___x_79_; 
v___x_79_ = lean_obj_once(&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_map__double___closed__4, &lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_map__double___closed__4_once, _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_map__double___closed__4);
return v___x_79_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_map__toString___closed__1(void){
_start:
{
lean_object* v___x_81_; lean_object* v___f_82_; lean_object* v___x_83_; 
v___x_81_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_map__double___closed__3));
v___f_82_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_map__toString___closed__0));
v___x_83_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_map___redArg(v___f_82_, v___x_81_);
return v___x_83_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_map__toString(void){
_start:
{
lean_object* v___x_84_; 
v___x_84_ = lean_obj_once(&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_map__toString___closed__1, &lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_map__toString___closed__1_once, _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_map__toString___closed__1);
return v___x_84_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_map__length___closed__7(void){
_start:
{
lean_object* v___x_98_; lean_object* v___x_99_; lean_object* v___x_100_; 
v___x_98_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_map__length___closed__6));
v___x_99_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_map__length___closed__0));
v___x_100_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_map___redArg(v___x_99_, v___x_98_);
return v___x_100_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_map__length(void){
_start:
{
lean_object* v___x_101_; 
v___x_101_ = lean_obj_once(&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_map__length___closed__7, &lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_map__length___closed__7_once, _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_map__length___closed__7);
return v___x_101_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_filter___redArg(lean_object* v_p_102_, lean_object* v_x_103_){
_start:
{
if (lean_obj_tag(v_x_103_) == 0)
{
lean_dec_ref(v_p_102_);
return v_x_103_;
}
else
{
lean_object* v_head_104_; lean_object* v_tail_105_; lean_object* v___x_107_; uint8_t v_isShared_108_; uint8_t v_isSharedCheck_116_; 
v_head_104_ = lean_ctor_get(v_x_103_, 0);
v_tail_105_ = lean_ctor_get(v_x_103_, 1);
v_isSharedCheck_116_ = !lean_is_exclusive(v_x_103_);
if (v_isSharedCheck_116_ == 0)
{
v___x_107_ = v_x_103_;
v_isShared_108_ = v_isSharedCheck_116_;
goto v_resetjp_106_;
}
else
{
lean_inc(v_tail_105_);
lean_inc(v_head_104_);
lean_dec(v_x_103_);
v___x_107_ = lean_box(0);
v_isShared_108_ = v_isSharedCheck_116_;
goto v_resetjp_106_;
}
v_resetjp_106_:
{
lean_object* v___x_109_; uint8_t v___x_110_; 
lean_inc_ref(v_p_102_);
lean_inc(v_head_104_);
v___x_109_ = lean_apply_1(v_p_102_, v_head_104_);
v___x_110_ = lean_unbox(v___x_109_);
if (v___x_110_ == 0)
{
lean_del_object(v___x_107_);
lean_dec(v_head_104_);
v_x_103_ = v_tail_105_;
goto _start;
}
else
{
lean_object* v___x_112_; lean_object* v___x_114_; 
v___x_112_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_filter___redArg(v_p_102_, v_tail_105_);
if (v_isShared_108_ == 0)
{
lean_ctor_set(v___x_107_, 1, v___x_112_);
v___x_114_ = v___x_107_;
goto v_reusejp_113_;
}
else
{
lean_object* v_reuseFailAlloc_115_; 
v_reuseFailAlloc_115_ = lean_alloc_ctor(1, 2, 0);
lean_ctor_set(v_reuseFailAlloc_115_, 0, v_head_104_);
lean_ctor_set(v_reuseFailAlloc_115_, 1, v___x_112_);
v___x_114_ = v_reuseFailAlloc_115_;
goto v_reusejp_113_;
}
v_reusejp_113_:
{
return v___x_114_;
}
}
}
}
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_filter(lean_object* v_00_u03b1_117_, lean_object* v_p_118_, lean_object* v_x_119_){
_start:
{
lean_object* v___x_120_; 
v___x_120_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_filter___redArg(v_p_118_, v_x_119_);
return v___x_120_;
}
}
LEAN_EXPORT uint8_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_filter__even___lam__0(lean_object* v_x_121_){
_start:
{
lean_object* v___x_122_; lean_object* v___x_123_; lean_object* v___x_124_; uint8_t v___x_125_; 
v___x_122_ = lean_unsigned_to_nat(2u);
v___x_123_ = lean_nat_mod(v_x_121_, v___x_122_);
v___x_124_ = lean_unsigned_to_nat(0u);
v___x_125_ = lean_nat_dec_eq(v___x_123_, v___x_124_);
lean_dec(v___x_123_);
return v___x_125_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_filter__even___lam__0___boxed(lean_object* v_x_126_){
_start:
{
uint8_t v_res_127_; lean_object* v_r_128_; 
v_res_127_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_filter__even___lam__0(v_x_126_);
lean_dec(v_x_126_);
v_r_128_ = lean_box(v_res_127_);
return v_r_128_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_filter__even___closed__7(void){
_start:
{
lean_object* v___x_148_; lean_object* v___f_149_; lean_object* v___x_150_; 
v___x_148_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_filter__even___closed__6));
v___f_149_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_filter__even___closed__0));
v___x_150_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_filter___redArg(v___f_149_, v___x_148_);
return v___x_150_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_filter__even(void){
_start:
{
lean_object* v___x_151_; 
v___x_151_ = lean_obj_once(&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_filter__even___closed__7, &lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_filter__even___closed__7_once, _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_filter__even___closed__7);
return v___x_151_;
}
}
LEAN_EXPORT uint8_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_filter__long___lam__0(lean_object* v_s_152_){
_start:
{
lean_object* v___x_153_; lean_object* v___x_154_; uint8_t v___x_155_; 
v___x_153_ = lean_unsigned_to_nat(3u);
v___x_154_ = lean_string_length(v_s_152_);
v___x_155_ = lean_nat_dec_lt(v___x_153_, v___x_154_);
return v___x_155_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_filter__long___lam__0___boxed(lean_object* v_s_156_){
_start:
{
uint8_t v_res_157_; lean_object* v_r_158_; 
v_res_157_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_filter__long___lam__0(v_s_156_);
lean_dec_ref(v_s_156_);
v_r_158_ = lean_box(v_res_157_);
return v_r_158_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_filter__long___closed__9(void){
_start:
{
lean_object* v___x_176_; lean_object* v___f_177_; lean_object* v___x_178_; 
v___x_176_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_filter__long___closed__8));
v___f_177_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_filter__long___closed__0));
v___x_178_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_filter___redArg(v___f_177_, v___x_176_);
return v___x_178_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_filter__long(void){
_start:
{
lean_object* v___x_179_; 
v___x_179_ = lean_obj_once(&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_filter__long___closed__9, &lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_filter__long___closed__9_once, _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_filter__long___closed__9);
return v___x_179_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_foldr___redArg(lean_object* v_f_180_, lean_object* v_init_181_, lean_object* v_x_182_){
_start:
{
if (lean_obj_tag(v_x_182_) == 0)
{
lean_dec(v_f_180_);
lean_inc(v_init_181_);
return v_init_181_;
}
else
{
lean_object* v_head_183_; lean_object* v_tail_184_; lean_object* v___x_185_; lean_object* v___x_186_; 
v_head_183_ = lean_ctor_get(v_x_182_, 0);
lean_inc(v_head_183_);
v_tail_184_ = lean_ctor_get(v_x_182_, 1);
lean_inc(v_tail_184_);
lean_dec_ref_known(v_x_182_, 2);
lean_inc(v_f_180_);
v___x_185_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_foldr___redArg(v_f_180_, v_init_181_, v_tail_184_);
v___x_186_ = lean_apply_2(v_f_180_, v_head_183_, v___x_185_);
return v___x_186_;
}
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_foldr___redArg___boxed(lean_object* v_f_187_, lean_object* v_init_188_, lean_object* v_x_189_){
_start:
{
lean_object* v_res_190_; 
v_res_190_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_foldr___redArg(v_f_187_, v_init_188_, v_x_189_);
lean_dec(v_init_188_);
return v_res_190_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_foldr(lean_object* v_00_u03b1_191_, lean_object* v_00_u03b2_192_, lean_object* v_f_193_, lean_object* v_init_194_, lean_object* v_x_195_){
_start:
{
lean_object* v___x_196_; 
v___x_196_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_foldr___redArg(v_f_193_, v_init_194_, v_x_195_);
return v___x_196_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_foldr___boxed(lean_object* v_00_u03b1_197_, lean_object* v_00_u03b2_198_, lean_object* v_f_199_, lean_object* v_init_200_, lean_object* v_x_201_){
_start:
{
lean_object* v_res_202_; 
v_res_202_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_foldr(v_00_u03b1_197_, v_00_u03b2_198_, v_f_199_, v_init_200_, v_x_201_);
lean_dec(v_init_200_);
return v_res_202_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_sum(lean_object* v_a_204_){
_start:
{
lean_object* v___f_205_; lean_object* v___x_206_; lean_object* v___x_207_; 
v___f_205_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_sum___closed__0));
v___x_206_ = lean_unsigned_to_nat(0u);
v___x_207_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_foldr___redArg(v___f_205_, v___x_206_, v_a_204_);
return v___x_207_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_sum__example___closed__0(void){
_start:
{
lean_object* v___x_208_; lean_object* v___x_209_; 
v___x_208_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_len3___closed__4));
v___x_209_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_sum(v___x_208_);
return v___x_209_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_sum__example(void){
_start:
{
lean_object* v___x_210_; 
v___x_210_ = lean_obj_once(&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_sum__example___closed__0, &lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_sum__example___closed__0_once, _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_sum__example___closed__0);
return v___x_210_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_product(lean_object* v_a_212_){
_start:
{
lean_object* v___f_213_; lean_object* v___x_214_; lean_object* v___x_215_; 
v___f_213_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_product___closed__0));
v___x_214_ = lean_unsigned_to_nat(1u);
v___x_215_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_foldr___redArg(v___f_213_, v___x_214_, v_a_212_);
return v___x_215_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_product__example___closed__0(void){
_start:
{
lean_object* v___x_216_; lean_object* v___x_217_; 
v___x_216_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_len3___closed__4));
v___x_217_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_product(v___x_216_);
return v___x_217_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_product__example(void){
_start:
{
lean_object* v___x_218_; 
v___x_218_ = lean_obj_once(&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_product__example___closed__0, &lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_product__example___closed__0_once, _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_product__example___closed__0);
return v___x_218_;
}
}
LEAN_EXPORT uint8_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_all___redArg___lam__0(lean_object* v_p_219_, lean_object* v_x_220_, uint8_t v_acc_221_){
_start:
{
lean_object* v___x_222_; uint8_t v___x_223_; 
v___x_222_ = lean_apply_1(v_p_219_, v_x_220_);
v___x_223_ = lean_unbox(v___x_222_);
if (v___x_223_ == 0)
{
uint8_t v___x_224_; 
v___x_224_ = lean_unbox(v___x_222_);
return v___x_224_;
}
else
{
return v_acc_221_;
}
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_all___redArg___lam__0___boxed(lean_object* v_p_225_, lean_object* v_x_226_, lean_object* v_acc_227_){
_start:
{
uint8_t v_acc_boxed_228_; uint8_t v_res_229_; lean_object* v_r_230_; 
v_acc_boxed_228_ = lean_unbox(v_acc_227_);
v_res_229_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_all___redArg___lam__0(v_p_225_, v_x_226_, v_acc_boxed_228_);
v_r_230_ = lean_box(v_res_229_);
return v_r_230_;
}
}
LEAN_EXPORT uint8_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_all___redArg(lean_object* v_p_231_, lean_object* v_a_232_){
_start:
{
lean_object* v___f_233_; uint8_t v___x_234_; lean_object* v___x_235_; lean_object* v___x_236_; uint8_t v___x_237_; 
v___f_233_ = lean_alloc_closure((void*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_all___redArg___lam__0___boxed), 3, 1);
lean_closure_set(v___f_233_, 0, v_p_231_);
v___x_234_ = 1;
v___x_235_ = lean_box(v___x_234_);
v___x_236_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_foldr___redArg(v___f_233_, v___x_235_, v_a_232_);
lean_dec(v___x_235_);
v___x_237_ = lean_unbox(v___x_236_);
lean_dec(v___x_236_);
return v___x_237_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_all___redArg___boxed(lean_object* v_p_238_, lean_object* v_a_239_){
_start:
{
uint8_t v_res_240_; lean_object* v_r_241_; 
v_res_240_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_all___redArg(v_p_238_, v_a_239_);
v_r_241_ = lean_box(v_res_240_);
return v_r_241_;
}
}
LEAN_EXPORT uint8_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_all(lean_object* v_00_u03b1_242_, lean_object* v_p_243_, lean_object* v_a_244_){
_start:
{
uint8_t v___x_245_; 
v___x_245_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_all___redArg(v_p_243_, v_a_244_);
return v___x_245_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_all___boxed(lean_object* v_00_u03b1_246_, lean_object* v_p_247_, lean_object* v_a_248_){
_start:
{
uint8_t v_res_249_; lean_object* v_r_250_; 
v_res_249_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_all(v_00_u03b1_246_, v_p_247_, v_a_248_);
v_r_250_ = lean_box(v_res_249_);
return v_r_250_;
}
}
static uint8_t _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_all__even___closed__2(void){
_start:
{
lean_object* v___x_257_; lean_object* v___f_258_; uint8_t v___x_259_; 
v___x_257_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_all__even___closed__1));
v___f_258_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_filter__even___closed__0));
v___x_259_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_all___redArg(v___f_258_, v___x_257_);
return v___x_259_;
}
}
static uint8_t _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_all__even(void){
_start:
{
uint8_t v___x_260_; 
v___x_260_ = lean_uint8_once(&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_all__even___closed__2, &lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_all__even___closed__2_once, _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_all__even___closed__2);
return v___x_260_;
}
}
static uint8_t _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_all__even2___closed__2(void){
_start:
{
lean_object* v___x_267_; lean_object* v___f_268_; uint8_t v___x_269_; 
v___x_267_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_all__even2___closed__1));
v___f_268_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_filter__even___closed__0));
v___x_269_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_all___redArg(v___f_268_, v___x_267_);
return v___x_269_;
}
}
static uint8_t _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_all__even2(void){
_start:
{
uint8_t v___x_270_; 
v___x_270_ = lean_uint8_once(&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_all__even2___closed__2, &lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_all__even2___closed__2_once, _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_all__even2___closed__2);
return v___x_270_;
}
}
LEAN_EXPORT uint8_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_any___redArg___lam__0(lean_object* v_p_271_, lean_object* v_x_272_, uint8_t v_acc_273_){
_start:
{
lean_object* v___x_274_; uint8_t v___x_275_; 
v___x_274_ = lean_apply_1(v_p_271_, v_x_272_);
v___x_275_ = lean_unbox(v___x_274_);
if (v___x_275_ == 0)
{
return v_acc_273_;
}
else
{
uint8_t v___x_276_; 
v___x_276_ = lean_unbox(v___x_274_);
return v___x_276_;
}
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_any___redArg___lam__0___boxed(lean_object* v_p_277_, lean_object* v_x_278_, lean_object* v_acc_279_){
_start:
{
uint8_t v_acc_boxed_280_; uint8_t v_res_281_; lean_object* v_r_282_; 
v_acc_boxed_280_ = lean_unbox(v_acc_279_);
v_res_281_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_any___redArg___lam__0(v_p_277_, v_x_278_, v_acc_boxed_280_);
v_r_282_ = lean_box(v_res_281_);
return v_r_282_;
}
}
LEAN_EXPORT uint8_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_any___redArg(lean_object* v_p_283_, lean_object* v_a_284_){
_start:
{
lean_object* v___f_285_; uint8_t v___x_286_; lean_object* v___x_287_; lean_object* v___x_288_; uint8_t v___x_289_; 
v___f_285_ = lean_alloc_closure((void*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_any___redArg___lam__0___boxed), 3, 1);
lean_closure_set(v___f_285_, 0, v_p_283_);
v___x_286_ = 0;
v___x_287_ = lean_box(v___x_286_);
v___x_288_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_foldr___redArg(v___f_285_, v___x_287_, v_a_284_);
lean_dec(v___x_287_);
v___x_289_ = lean_unbox(v___x_288_);
lean_dec(v___x_288_);
return v___x_289_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_any___redArg___boxed(lean_object* v_p_290_, lean_object* v_a_291_){
_start:
{
uint8_t v_res_292_; lean_object* v_r_293_; 
v_res_292_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_any___redArg(v_p_290_, v_a_291_);
v_r_293_ = lean_box(v_res_292_);
return v_r_293_;
}
}
LEAN_EXPORT uint8_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_any(lean_object* v_00_u03b1_294_, lean_object* v_p_295_, lean_object* v_a_296_){
_start:
{
uint8_t v___x_297_; 
v___x_297_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_any___redArg(v_p_295_, v_a_296_);
return v___x_297_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_any___boxed(lean_object* v_00_u03b1_298_, lean_object* v_p_299_, lean_object* v_a_300_){
_start:
{
uint8_t v_res_301_; lean_object* v_r_302_; 
v_res_301_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_any(v_00_u03b1_298_, v_p_299_, v_a_300_);
v_r_302_ = lean_box(v_res_301_);
return v_r_302_;
}
}
static uint8_t _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_any__even___closed__2(void){
_start:
{
lean_object* v___x_309_; lean_object* v___f_310_; uint8_t v___x_311_; 
v___x_309_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_any__even___closed__1));
v___f_310_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_filter__even___closed__0));
v___x_311_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_any___redArg(v___f_310_, v___x_309_);
return v___x_311_;
}
}
static uint8_t _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_any__even(void){
_start:
{
uint8_t v___x_312_; 
v___x_312_ = lean_uint8_once(&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_any__even___closed__2, &lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_any__even___closed__2_once, _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_any__even___closed__2);
return v___x_312_;
}
}
static uint8_t _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_any__even2___closed__0(void){
_start:
{
lean_object* v___x_313_; lean_object* v___f_314_; uint8_t v___x_315_; 
v___x_313_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_map__double___closed__3));
v___f_314_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_filter__even___closed__0));
v___x_315_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_any___redArg(v___f_314_, v___x_313_);
return v___x_315_;
}
}
static uint8_t _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_any__even2(void){
_start:
{
uint8_t v___x_316_; 
v___x_316_ = lean_uint8_once(&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_any__even2___closed__0, &lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_any__even2___closed__0_once, _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_any__even2___closed__0);
return v___x_316_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_foldl___redArg(lean_object* v_f_317_, lean_object* v_init_318_, lean_object* v_x_319_){
_start:
{
if (lean_obj_tag(v_x_319_) == 0)
{
lean_dec(v_f_317_);
return v_init_318_;
}
else
{
lean_object* v_head_320_; lean_object* v_tail_321_; lean_object* v___x_322_; 
v_head_320_ = lean_ctor_get(v_x_319_, 0);
lean_inc(v_head_320_);
v_tail_321_ = lean_ctor_get(v_x_319_, 1);
lean_inc(v_tail_321_);
lean_dec_ref_known(v_x_319_, 2);
lean_inc(v_f_317_);
v___x_322_ = lean_apply_2(v_f_317_, v_init_318_, v_head_320_);
v_init_318_ = v___x_322_;
v_x_319_ = v_tail_321_;
goto _start;
}
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_foldl(lean_object* v_00_u03b1_324_, lean_object* v_00_u03b2_325_, lean_object* v_f_326_, lean_object* v_init_327_, lean_object* v_x_328_){
_start:
{
lean_object* v___x_329_; 
v___x_329_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_foldl___redArg(v_f_326_, v_init_327_, v_x_328_);
return v___x_329_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_reverse___redArg___lam__0(lean_object* v_acc_330_, lean_object* v_x_331_){
_start:
{
lean_object* v___x_332_; 
v___x_332_ = lean_alloc_ctor(1, 2, 0);
lean_ctor_set(v___x_332_, 0, v_x_331_);
lean_ctor_set(v___x_332_, 1, v_acc_330_);
return v___x_332_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_reverse___redArg(lean_object* v_l_334_){
_start:
{
lean_object* v___f_335_; lean_object* v___x_336_; lean_object* v___x_337_; 
v___f_335_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_reverse___redArg___closed__0));
v___x_336_ = lean_box(0);
v___x_337_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_foldl___redArg(v___f_335_, v___x_336_, v_l_334_);
return v___x_337_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_reverse(lean_object* v_00_u03b1_338_, lean_object* v_l_339_){
_start:
{
lean_object* v___x_340_; 
v___x_340_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_reverse___redArg(v_l_339_);
return v___x_340_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_reverse__example___closed__0(void){
_start:
{
lean_object* v___x_341_; lean_object* v___x_342_; 
v___x_341_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_map__double___closed__3));
v___x_342_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_reverse___redArg(v___x_341_);
return v___x_342_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_reverse__example(void){
_start:
{
lean_object* v___x_343_; 
v___x_343_ = lean_obj_once(&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_reverse__example___closed__0, &lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_reverse__example___closed__0_once, _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_reverse__example___closed__0);
return v___x_343_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_sum__l(lean_object* v_a_344_){
_start:
{
lean_object* v___f_345_; lean_object* v___x_346_; lean_object* v___x_347_; 
v___f_345_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_sum___closed__0));
v___x_346_ = lean_unsigned_to_nat(0u);
v___x_347_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_foldl___redArg(v___f_345_, v___x_346_, v_a_344_);
return v___x_347_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_sum__l__example___closed__0(void){
_start:
{
lean_object* v___x_348_; lean_object* v___x_349_; 
v___x_348_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_map__double___closed__3));
v___x_349_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_sum__l(v___x_348_);
return v___x_349_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_sum__l__example(void){
_start:
{
lean_object* v___x_350_; 
v___x_350_ = lean_obj_once(&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_sum__l__example___closed__0, &lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_sum__l__example___closed__0_once, _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_sum__l__example___closed__0);
return v___x_350_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_append___redArg(lean_object* v_x_351_, lean_object* v_x_352_){
_start:
{
if (lean_obj_tag(v_x_351_) == 0)
{
lean_inc(v_x_352_);
return v_x_352_;
}
else
{
lean_object* v_head_353_; lean_object* v_tail_354_; lean_object* v___x_356_; uint8_t v_isShared_357_; uint8_t v_isSharedCheck_362_; 
v_head_353_ = lean_ctor_get(v_x_351_, 0);
v_tail_354_ = lean_ctor_get(v_x_351_, 1);
v_isSharedCheck_362_ = !lean_is_exclusive(v_x_351_);
if (v_isSharedCheck_362_ == 0)
{
v___x_356_ = v_x_351_;
v_isShared_357_ = v_isSharedCheck_362_;
goto v_resetjp_355_;
}
else
{
lean_inc(v_tail_354_);
lean_inc(v_head_353_);
lean_dec(v_x_351_);
v___x_356_ = lean_box(0);
v_isShared_357_ = v_isSharedCheck_362_;
goto v_resetjp_355_;
}
v_resetjp_355_:
{
lean_object* v___x_358_; lean_object* v___x_360_; 
v___x_358_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_append___redArg(v_tail_354_, v_x_352_);
if (v_isShared_357_ == 0)
{
lean_ctor_set(v___x_356_, 1, v___x_358_);
v___x_360_ = v___x_356_;
goto v_reusejp_359_;
}
else
{
lean_object* v_reuseFailAlloc_361_; 
v_reuseFailAlloc_361_ = lean_alloc_ctor(1, 2, 0);
lean_ctor_set(v_reuseFailAlloc_361_, 0, v_head_353_);
lean_ctor_set(v_reuseFailAlloc_361_, 1, v___x_358_);
v___x_360_ = v_reuseFailAlloc_361_;
goto v_reusejp_359_;
}
v_reusejp_359_:
{
return v___x_360_;
}
}
}
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_append___redArg___boxed(lean_object* v_x_363_, lean_object* v_x_364_){
_start:
{
lean_object* v_res_365_; 
v_res_365_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_append___redArg(v_x_363_, v_x_364_);
lean_dec(v_x_364_);
return v_res_365_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_append(lean_object* v_00_u03b1_366_, lean_object* v_x_367_, lean_object* v_x_368_){
_start:
{
lean_object* v___x_369_; 
v___x_369_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_append___redArg(v_x_367_, v_x_368_);
return v___x_369_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_append___boxed(lean_object* v_00_u03b1_370_, lean_object* v_x_371_, lean_object* v_x_372_){
_start:
{
lean_object* v_res_373_; 
v_res_373_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_append(v_00_u03b1_370_, v_x_371_, v_x_372_);
lean_dec(v_x_372_);
return v_res_373_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_append__example___closed__4(void){
_start:
{
lean_object* v___x_386_; lean_object* v___x_387_; lean_object* v___x_388_; 
v___x_386_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_append__example___closed__3));
v___x_387_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_append__example___closed__1));
v___x_388_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_append___redArg(v___x_387_, v___x_386_);
return v___x_388_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_append__example(void){
_start:
{
lean_object* v___x_389_; 
v___x_389_ = lean_obj_once(&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_append__example___closed__4, &lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_append__example___closed__4_once, _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_append__example___closed__4);
return v___x_389_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_flatMap___redArg(lean_object* v_f_390_, lean_object* v_x_391_){
_start:
{
if (lean_obj_tag(v_x_391_) == 0)
{
lean_object* v___x_392_; 
lean_dec_ref(v_f_390_);
v___x_392_ = lean_box(0);
return v___x_392_;
}
else
{
lean_object* v_head_393_; lean_object* v_tail_394_; lean_object* v___x_395_; lean_object* v___x_396_; lean_object* v___x_397_; 
v_head_393_ = lean_ctor_get(v_x_391_, 0);
lean_inc(v_head_393_);
v_tail_394_ = lean_ctor_get(v_x_391_, 1);
lean_inc(v_tail_394_);
lean_dec_ref_known(v_x_391_, 2);
lean_inc_ref(v_f_390_);
v___x_395_ = lean_apply_1(v_f_390_, v_head_393_);
v___x_396_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_flatMap___redArg(v_f_390_, v_tail_394_);
v___x_397_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_append___redArg(v___x_395_, v___x_396_);
lean_dec(v___x_396_);
return v___x_397_;
}
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_flatMap(lean_object* v_00_u03b1_398_, lean_object* v_00_u03b2_399_, lean_object* v_f_400_, lean_object* v_x_401_){
_start:
{
lean_object* v___x_402_; 
v___x_402_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_flatMap___redArg(v_f_400_, v_x_401_);
return v___x_402_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_dup__and__double___lam__0(lean_object* v_n_403_){
_start:
{
lean_object* v___x_404_; lean_object* v___x_405_; lean_object* v___x_406_; lean_object* v___x_407_; lean_object* v___x_408_; 
v___x_404_ = lean_unsigned_to_nat(2u);
v___x_405_ = lean_nat_mul(v_n_403_, v___x_404_);
v___x_406_ = lean_box(0);
v___x_407_ = lean_alloc_ctor(1, 2, 0);
lean_ctor_set(v___x_407_, 0, v___x_405_);
lean_ctor_set(v___x_407_, 1, v___x_406_);
v___x_408_ = lean_alloc_ctor(1, 2, 0);
lean_ctor_set(v___x_408_, 0, v_n_403_);
lean_ctor_set(v___x_408_, 1, v___x_407_);
return v___x_408_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_dup__and__double___closed__1(void){
_start:
{
lean_object* v___x_410_; lean_object* v___f_411_; lean_object* v___x_412_; 
v___x_410_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_map__double___closed__3));
v___f_411_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_dup__and__double___closed__0));
v___x_412_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_flatMap___redArg(v___f_411_, v___x_410_);
return v___x_412_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_dup__and__double(void){
_start:
{
lean_object* v___x_413_; 
v___x_413_ = lean_obj_once(&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_dup__and__double___closed__1, &lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_dup__and__double___closed__1_once, _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_dup__and__double___closed__1);
return v___x_413_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_zip___redArg(lean_object* v_x_414_, lean_object* v_x_415_){
_start:
{
if (lean_obj_tag(v_x_414_) == 0)
{
lean_object* v___x_416_; 
lean_dec(v_x_415_);
v___x_416_ = lean_box(0);
return v___x_416_;
}
else
{
if (lean_obj_tag(v_x_415_) == 0)
{
lean_object* v___x_417_; 
lean_dec_ref_known(v_x_414_, 2);
v___x_417_ = lean_box(0);
return v___x_417_;
}
else
{
lean_object* v_head_418_; lean_object* v_tail_419_; lean_object* v___x_421_; uint8_t v_isShared_422_; uint8_t v_isSharedCheck_436_; 
v_head_418_ = lean_ctor_get(v_x_414_, 0);
v_tail_419_ = lean_ctor_get(v_x_414_, 1);
v_isSharedCheck_436_ = !lean_is_exclusive(v_x_414_);
if (v_isSharedCheck_436_ == 0)
{
v___x_421_ = v_x_414_;
v_isShared_422_ = v_isSharedCheck_436_;
goto v_resetjp_420_;
}
else
{
lean_inc(v_tail_419_);
lean_inc(v_head_418_);
lean_dec(v_x_414_);
v___x_421_ = lean_box(0);
v_isShared_422_ = v_isSharedCheck_436_;
goto v_resetjp_420_;
}
v_resetjp_420_:
{
lean_object* v_head_423_; lean_object* v_tail_424_; lean_object* v___x_426_; uint8_t v_isShared_427_; uint8_t v_isSharedCheck_435_; 
v_head_423_ = lean_ctor_get(v_x_415_, 0);
v_tail_424_ = lean_ctor_get(v_x_415_, 1);
v_isSharedCheck_435_ = !lean_is_exclusive(v_x_415_);
if (v_isSharedCheck_435_ == 0)
{
v___x_426_ = v_x_415_;
v_isShared_427_ = v_isSharedCheck_435_;
goto v_resetjp_425_;
}
else
{
lean_inc(v_tail_424_);
lean_inc(v_head_423_);
lean_dec(v_x_415_);
v___x_426_ = lean_box(0);
v_isShared_427_ = v_isSharedCheck_435_;
goto v_resetjp_425_;
}
v_resetjp_425_:
{
lean_object* v___x_429_; 
if (v_isShared_422_ == 0)
{
lean_ctor_set_tag(v___x_421_, 0);
lean_ctor_set(v___x_421_, 1, v_head_423_);
v___x_429_ = v___x_421_;
goto v_reusejp_428_;
}
else
{
lean_object* v_reuseFailAlloc_434_; 
v_reuseFailAlloc_434_ = lean_alloc_ctor(0, 2, 0);
lean_ctor_set(v_reuseFailAlloc_434_, 0, v_head_418_);
lean_ctor_set(v_reuseFailAlloc_434_, 1, v_head_423_);
v___x_429_ = v_reuseFailAlloc_434_;
goto v_reusejp_428_;
}
v_reusejp_428_:
{
lean_object* v___x_430_; lean_object* v___x_432_; 
v___x_430_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_zip___redArg(v_tail_419_, v_tail_424_);
if (v_isShared_427_ == 0)
{
lean_ctor_set(v___x_426_, 1, v___x_430_);
lean_ctor_set(v___x_426_, 0, v___x_429_);
v___x_432_ = v___x_426_;
goto v_reusejp_431_;
}
else
{
lean_object* v_reuseFailAlloc_433_; 
v_reuseFailAlloc_433_ = lean_alloc_ctor(1, 2, 0);
lean_ctor_set(v_reuseFailAlloc_433_, 0, v___x_429_);
lean_ctor_set(v_reuseFailAlloc_433_, 1, v___x_430_);
v___x_432_ = v_reuseFailAlloc_433_;
goto v_reusejp_431_;
}
v_reusejp_431_:
{
return v___x_432_;
}
}
}
}
}
}
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_zip(lean_object* v_00_u03b1_437_, lean_object* v_00_u03b2_438_, lean_object* v_x_439_, lean_object* v_x_440_){
_start:
{
lean_object* v___x_441_; 
v___x_441_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_zip___redArg(v_x_439_, v_x_440_);
return v___x_441_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_zip__example___closed__5(void){
_start:
{
lean_object* v___x_453_; lean_object* v___x_454_; lean_object* v___x_455_; 
v___x_453_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_zip__example___closed__4));
v___x_454_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_map__double___closed__3));
v___x_455_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_zip___redArg(v___x_454_, v___x_453_);
return v___x_455_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_zip__example(void){
_start:
{
lean_object* v___x_456_; 
v___x_456_ = lean_obj_once(&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_zip__example___closed__5, &lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_zip__example___closed__5_once, _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_zip__example___closed__5);
return v___x_456_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_zipWith___redArg(lean_object* v_f_457_, lean_object* v_x_458_, lean_object* v_x_459_){
_start:
{
if (lean_obj_tag(v_x_458_) == 0)
{
lean_object* v___x_460_; 
lean_dec(v_x_459_);
lean_dec(v_f_457_);
v___x_460_ = lean_box(0);
return v___x_460_;
}
else
{
if (lean_obj_tag(v_x_459_) == 0)
{
lean_object* v___x_461_; 
lean_dec_ref_known(v_x_458_, 2);
lean_dec(v_f_457_);
v___x_461_ = lean_box(0);
return v___x_461_;
}
else
{
lean_object* v_head_462_; lean_object* v_tail_463_; lean_object* v_head_464_; lean_object* v_tail_465_; lean_object* v___x_467_; uint8_t v_isShared_468_; uint8_t v_isSharedCheck_474_; 
v_head_462_ = lean_ctor_get(v_x_458_, 0);
lean_inc(v_head_462_);
v_tail_463_ = lean_ctor_get(v_x_458_, 1);
lean_inc(v_tail_463_);
lean_dec_ref_known(v_x_458_, 2);
v_head_464_ = lean_ctor_get(v_x_459_, 0);
v_tail_465_ = lean_ctor_get(v_x_459_, 1);
v_isSharedCheck_474_ = !lean_is_exclusive(v_x_459_);
if (v_isSharedCheck_474_ == 0)
{
v___x_467_ = v_x_459_;
v_isShared_468_ = v_isSharedCheck_474_;
goto v_resetjp_466_;
}
else
{
lean_inc(v_tail_465_);
lean_inc(v_head_464_);
lean_dec(v_x_459_);
v___x_467_ = lean_box(0);
v_isShared_468_ = v_isSharedCheck_474_;
goto v_resetjp_466_;
}
v_resetjp_466_:
{
lean_object* v___x_469_; lean_object* v___x_470_; lean_object* v___x_472_; 
lean_inc(v_f_457_);
v___x_469_ = lean_apply_2(v_f_457_, v_head_462_, v_head_464_);
v___x_470_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_zipWith___redArg(v_f_457_, v_tail_463_, v_tail_465_);
if (v_isShared_468_ == 0)
{
lean_ctor_set(v___x_467_, 1, v___x_470_);
lean_ctor_set(v___x_467_, 0, v___x_469_);
v___x_472_ = v___x_467_;
goto v_reusejp_471_;
}
else
{
lean_object* v_reuseFailAlloc_473_; 
v_reuseFailAlloc_473_ = lean_alloc_ctor(1, 2, 0);
lean_ctor_set(v_reuseFailAlloc_473_, 0, v___x_469_);
lean_ctor_set(v_reuseFailAlloc_473_, 1, v___x_470_);
v___x_472_ = v_reuseFailAlloc_473_;
goto v_reusejp_471_;
}
v_reusejp_471_:
{
return v___x_472_;
}
}
}
}
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_zipWith(lean_object* v_00_u03b1_475_, lean_object* v_00_u03b2_476_, lean_object* v_00_u03b3_477_, lean_object* v_f_478_, lean_object* v_x_479_, lean_object* v_x_480_){
_start:
{
lean_object* v___x_481_; 
v___x_481_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_zipWith___redArg(v_f_478_, v_x_479_, v_x_480_);
return v___x_481_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_zipWith__add___closed__0(void){
_start:
{
lean_object* v___x_482_; lean_object* v___x_483_; lean_object* v___f_484_; lean_object* v___x_485_; 
v___x_482_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_filter__even___closed__3));
v___x_483_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_map__double___closed__3));
v___f_484_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_sum___closed__0));
v___x_485_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_zipWith___redArg(v___f_484_, v___x_483_, v___x_482_);
return v___x_485_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_zipWith__add(void){
_start:
{
lean_object* v___x_486_; 
v___x_486_ = lean_obj_once(&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_zipWith__add___closed__0, &lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_zipWith__add___closed__0_once, _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_zipWith__add___closed__0);
return v___x_486_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_take___redArg(lean_object* v_x_487_, lean_object* v_x_488_){
_start:
{
lean_object* v_zero_489_; uint8_t v_isZero_490_; 
v_zero_489_ = lean_unsigned_to_nat(0u);
v_isZero_490_ = lean_nat_dec_eq(v_x_487_, v_zero_489_);
if (v_isZero_490_ == 1)
{
lean_object* v___x_491_; 
lean_dec(v_x_488_);
v___x_491_ = lean_box(0);
return v___x_491_;
}
else
{
if (lean_obj_tag(v_x_488_) == 0)
{
return v_x_488_;
}
else
{
lean_object* v_head_492_; lean_object* v_tail_493_; lean_object* v___x_495_; uint8_t v_isShared_496_; uint8_t v_isSharedCheck_503_; 
v_head_492_ = lean_ctor_get(v_x_488_, 0);
v_tail_493_ = lean_ctor_get(v_x_488_, 1);
v_isSharedCheck_503_ = !lean_is_exclusive(v_x_488_);
if (v_isSharedCheck_503_ == 0)
{
v___x_495_ = v_x_488_;
v_isShared_496_ = v_isSharedCheck_503_;
goto v_resetjp_494_;
}
else
{
lean_inc(v_tail_493_);
lean_inc(v_head_492_);
lean_dec(v_x_488_);
v___x_495_ = lean_box(0);
v_isShared_496_ = v_isSharedCheck_503_;
goto v_resetjp_494_;
}
v_resetjp_494_:
{
lean_object* v_one_497_; lean_object* v_n_498_; lean_object* v___x_499_; lean_object* v___x_501_; 
v_one_497_ = lean_unsigned_to_nat(1u);
v_n_498_ = lean_nat_sub(v_x_487_, v_one_497_);
v___x_499_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_take___redArg(v_n_498_, v_tail_493_);
lean_dec(v_n_498_);
if (v_isShared_496_ == 0)
{
lean_ctor_set(v___x_495_, 1, v___x_499_);
v___x_501_ = v___x_495_;
goto v_reusejp_500_;
}
else
{
lean_object* v_reuseFailAlloc_502_; 
v_reuseFailAlloc_502_ = lean_alloc_ctor(1, 2, 0);
lean_ctor_set(v_reuseFailAlloc_502_, 0, v_head_492_);
lean_ctor_set(v_reuseFailAlloc_502_, 1, v___x_499_);
v___x_501_ = v_reuseFailAlloc_502_;
goto v_reusejp_500_;
}
v_reusejp_500_:
{
return v___x_501_;
}
}
}
}
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_take___redArg___boxed(lean_object* v_x_504_, lean_object* v_x_505_){
_start:
{
lean_object* v_res_506_; 
v_res_506_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_take___redArg(v_x_504_, v_x_505_);
lean_dec(v_x_504_);
return v_res_506_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_take(lean_object* v_00_u03b1_507_, lean_object* v_x_508_, lean_object* v_x_509_){
_start:
{
lean_object* v___x_510_; 
v___x_510_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_take___redArg(v_x_508_, v_x_509_);
return v___x_510_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_take___boxed(lean_object* v_00_u03b1_511_, lean_object* v_x_512_, lean_object* v_x_513_){
_start:
{
lean_object* v_res_514_; 
v_res_514_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_take(v_00_u03b1_511_, v_x_512_, v_x_513_);
lean_dec(v_x_512_);
return v_res_514_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_take__3___closed__0(void){
_start:
{
lean_object* v___x_515_; lean_object* v___x_516_; lean_object* v___x_517_; 
v___x_515_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_len3___closed__4));
v___x_516_ = lean_unsigned_to_nat(3u);
v___x_517_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_take___redArg(v___x_516_, v___x_515_);
return v___x_517_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_take__3(void){
_start:
{
lean_object* v___x_518_; 
v___x_518_ = lean_obj_once(&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_take__3___closed__0, &lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_take__3___closed__0_once, _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_take__3___closed__0);
return v___x_518_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_take__10___closed__0(void){
_start:
{
lean_object* v___x_519_; lean_object* v___x_520_; lean_object* v___x_521_; 
v___x_519_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_map__double___closed__3));
v___x_520_ = lean_unsigned_to_nat(10u);
v___x_521_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_take___redArg(v___x_520_, v___x_519_);
return v___x_521_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_take__10(void){
_start:
{
lean_object* v___x_522_; 
v___x_522_ = lean_obj_once(&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_take__10___closed__0, &lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_take__10___closed__0_once, _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_take__10___closed__0);
return v___x_522_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_drop___redArg(lean_object* v_x_523_, lean_object* v_x_524_){
_start:
{
lean_object* v_zero_525_; uint8_t v_isZero_526_; 
v_zero_525_ = lean_unsigned_to_nat(0u);
v_isZero_526_ = lean_nat_dec_eq(v_x_523_, v_zero_525_);
if (v_isZero_526_ == 1)
{
lean_dec(v_x_523_);
lean_inc(v_x_524_);
return v_x_524_;
}
else
{
if (lean_obj_tag(v_x_524_) == 0)
{
lean_dec(v_x_523_);
return v_x_524_;
}
else
{
lean_object* v_tail_527_; lean_object* v_one_528_; lean_object* v_n_529_; 
v_tail_527_ = lean_ctor_get(v_x_524_, 1);
v_one_528_ = lean_unsigned_to_nat(1u);
v_n_529_ = lean_nat_sub(v_x_523_, v_one_528_);
lean_dec(v_x_523_);
v_x_523_ = v_n_529_;
v_x_524_ = v_tail_527_;
goto _start;
}
}
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_drop___redArg___boxed(lean_object* v_x_531_, lean_object* v_x_532_){
_start:
{
lean_object* v_res_533_; 
v_res_533_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_drop___redArg(v_x_531_, v_x_532_);
lean_dec(v_x_532_);
return v_res_533_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_drop(lean_object* v_00_u03b1_534_, lean_object* v_x_535_, lean_object* v_x_536_){
_start:
{
lean_object* v___x_537_; 
v___x_537_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_drop___redArg(v_x_535_, v_x_536_);
return v___x_537_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_drop___boxed(lean_object* v_00_u03b1_538_, lean_object* v_x_539_, lean_object* v_x_540_){
_start:
{
lean_object* v_res_541_; 
v_res_541_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_drop(v_00_u03b1_538_, v_x_539_, v_x_540_);
lean_dec(v_x_540_);
return v_res_541_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_drop__2___closed__0(void){
_start:
{
lean_object* v___x_542_; lean_object* v___x_543_; lean_object* v___x_544_; 
v___x_542_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_len3___closed__4));
v___x_543_ = lean_unsigned_to_nat(2u);
v___x_544_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_drop___redArg(v___x_543_, v___x_542_);
return v___x_544_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_drop__2(void){
_start:
{
lean_object* v___x_545_; 
v___x_545_ = lean_obj_once(&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_drop__2___closed__0, &lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_drop__2___closed__0_once, _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_drop__2___closed__0);
return v___x_545_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_drop__10___closed__0(void){
_start:
{
lean_object* v___x_546_; lean_object* v___x_547_; lean_object* v___x_548_; 
v___x_546_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_map__double___closed__3));
v___x_547_ = lean_unsigned_to_nat(10u);
v___x_548_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_drop___redArg(v___x_547_, v___x_546_);
return v___x_548_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_drop__10(void){
_start:
{
lean_object* v___x_549_; 
v___x_549_ = lean_obj_once(&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_drop__10___closed__0, &lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_drop__10___closed__0_once, _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_drop__10___closed__0);
return v___x_549_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_get_x3f___redArg(lean_object* v_x_550_, lean_object* v_x_551_){
_start:
{
if (lean_obj_tag(v_x_550_) == 0)
{
lean_object* v___x_552_; 
lean_dec(v_x_551_);
v___x_552_ = lean_box(0);
return v___x_552_;
}
else
{
lean_object* v_head_553_; lean_object* v_tail_554_; lean_object* v_zero_555_; uint8_t v_isZero_556_; 
v_head_553_ = lean_ctor_get(v_x_550_, 0);
v_tail_554_ = lean_ctor_get(v_x_550_, 1);
v_zero_555_ = lean_unsigned_to_nat(0u);
v_isZero_556_ = lean_nat_dec_eq(v_x_551_, v_zero_555_);
if (v_isZero_556_ == 1)
{
lean_object* v___x_557_; 
lean_dec(v_x_551_);
lean_inc(v_head_553_);
v___x_557_ = lean_alloc_ctor(1, 1, 0);
lean_ctor_set(v___x_557_, 0, v_head_553_);
return v___x_557_;
}
else
{
lean_object* v_one_558_; lean_object* v_n_559_; 
v_one_558_ = lean_unsigned_to_nat(1u);
v_n_559_ = lean_nat_sub(v_x_551_, v_one_558_);
lean_dec(v_x_551_);
v_x_550_ = v_tail_554_;
v_x_551_ = v_n_559_;
goto _start;
}
}
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_get_x3f___redArg___boxed(lean_object* v_x_561_, lean_object* v_x_562_){
_start:
{
lean_object* v_res_563_; 
v_res_563_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_get_x3f___redArg(v_x_561_, v_x_562_);
lean_dec(v_x_561_);
return v_res_563_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_get_x3f(lean_object* v_00_u03b1_564_, lean_object* v_x_565_, lean_object* v_x_566_){
_start:
{
lean_object* v___x_567_; 
v___x_567_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_get_x3f___redArg(v_x_565_, v_x_566_);
return v___x_567_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_get_x3f___boxed(lean_object* v_00_u03b1_568_, lean_object* v_x_569_, lean_object* v_x_570_){
_start:
{
lean_object* v_res_571_; 
v_res_571_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_get_x3f(v_00_u03b1_568_, v_x_569_, v_x_570_);
lean_dec(v_x_569_);
return v_res_571_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_get__2___closed__4(void){
_start:
{
lean_object* v___x_584_; lean_object* v___x_585_; lean_object* v___x_586_; 
v___x_584_ = lean_unsigned_to_nat(2u);
v___x_585_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_get__2___closed__3));
v___x_586_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_get_x3f___redArg(v___x_585_, v___x_584_);
return v___x_586_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_get__2(void){
_start:
{
lean_object* v___x_587_; 
v___x_587_ = lean_obj_once(&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_get__2___closed__4, &lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_get__2___closed__4_once, _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_get__2___closed__4);
return v___x_587_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_get__10___closed__3(void){
_start:
{
lean_object* v___x_597_; lean_object* v___x_598_; lean_object* v___x_599_; 
v___x_597_ = lean_unsigned_to_nat(10u);
v___x_598_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_get__10___closed__2));
v___x_599_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_get_x3f___redArg(v___x_598_, v___x_597_);
return v___x_599_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_get__10(void){
_start:
{
lean_object* v___x_600_; 
v___x_600_ = lean_obj_once(&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_get__10___closed__3, &lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_get__10___closed__3_once, _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_get__10___closed__3);
return v___x_600_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_set_x3f___redArg(lean_object* v_x_601_, lean_object* v_x_602_, lean_object* v_x_603_){
_start:
{
if (lean_obj_tag(v_x_601_) == 0)
{
lean_object* v___x_604_; 
lean_dec(v_x_603_);
v___x_604_ = lean_box(0);
return v___x_604_;
}
else
{
lean_object* v_head_605_; lean_object* v_tail_606_; lean_object* v___x_608_; uint8_t v_isShared_609_; uint8_t v_isSharedCheck_630_; 
v_head_605_ = lean_ctor_get(v_x_601_, 0);
v_tail_606_ = lean_ctor_get(v_x_601_, 1);
v_isSharedCheck_630_ = !lean_is_exclusive(v_x_601_);
if (v_isSharedCheck_630_ == 0)
{
v___x_608_ = v_x_601_;
v_isShared_609_ = v_isSharedCheck_630_;
goto v_resetjp_607_;
}
else
{
lean_inc(v_tail_606_);
lean_inc(v_head_605_);
lean_dec(v_x_601_);
v___x_608_ = lean_box(0);
v_isShared_609_ = v_isSharedCheck_630_;
goto v_resetjp_607_;
}
v_resetjp_607_:
{
lean_object* v_zero_610_; uint8_t v_isZero_611_; 
v_zero_610_ = lean_unsigned_to_nat(0u);
v_isZero_611_ = lean_nat_dec_eq(v_x_602_, v_zero_610_);
if (v_isZero_611_ == 1)
{
lean_object* v___x_613_; 
lean_dec(v_head_605_);
if (v_isShared_609_ == 0)
{
lean_ctor_set(v___x_608_, 0, v_x_603_);
v___x_613_ = v___x_608_;
goto v_reusejp_612_;
}
else
{
lean_object* v_reuseFailAlloc_615_; 
v_reuseFailAlloc_615_ = lean_alloc_ctor(1, 2, 0);
lean_ctor_set(v_reuseFailAlloc_615_, 0, v_x_603_);
lean_ctor_set(v_reuseFailAlloc_615_, 1, v_tail_606_);
v___x_613_ = v_reuseFailAlloc_615_;
goto v_reusejp_612_;
}
v_reusejp_612_:
{
lean_object* v___x_614_; 
v___x_614_ = lean_alloc_ctor(1, 1, 0);
lean_ctor_set(v___x_614_, 0, v___x_613_);
return v___x_614_;
}
}
else
{
lean_object* v_one_616_; lean_object* v_n_617_; lean_object* v___x_618_; 
v_one_616_ = lean_unsigned_to_nat(1u);
v_n_617_ = lean_nat_sub(v_x_602_, v_one_616_);
v___x_618_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_set_x3f___redArg(v_tail_606_, v_n_617_, v_x_603_);
lean_dec(v_n_617_);
if (lean_obj_tag(v___x_618_) == 0)
{
lean_del_object(v___x_608_);
lean_dec(v_head_605_);
return v___x_618_;
}
else
{
lean_object* v_val_619_; lean_object* v___x_621_; uint8_t v_isShared_622_; uint8_t v_isSharedCheck_629_; 
v_val_619_ = lean_ctor_get(v___x_618_, 0);
v_isSharedCheck_629_ = !lean_is_exclusive(v___x_618_);
if (v_isSharedCheck_629_ == 0)
{
v___x_621_ = v___x_618_;
v_isShared_622_ = v_isSharedCheck_629_;
goto v_resetjp_620_;
}
else
{
lean_inc(v_val_619_);
lean_dec(v___x_618_);
v___x_621_ = lean_box(0);
v_isShared_622_ = v_isSharedCheck_629_;
goto v_resetjp_620_;
}
v_resetjp_620_:
{
lean_object* v___x_624_; 
if (v_isShared_609_ == 0)
{
lean_ctor_set(v___x_608_, 1, v_val_619_);
v___x_624_ = v___x_608_;
goto v_reusejp_623_;
}
else
{
lean_object* v_reuseFailAlloc_628_; 
v_reuseFailAlloc_628_ = lean_alloc_ctor(1, 2, 0);
lean_ctor_set(v_reuseFailAlloc_628_, 0, v_head_605_);
lean_ctor_set(v_reuseFailAlloc_628_, 1, v_val_619_);
v___x_624_ = v_reuseFailAlloc_628_;
goto v_reusejp_623_;
}
v_reusejp_623_:
{
lean_object* v___x_626_; 
if (v_isShared_622_ == 0)
{
lean_ctor_set(v___x_621_, 0, v___x_624_);
v___x_626_ = v___x_621_;
goto v_reusejp_625_;
}
else
{
lean_object* v_reuseFailAlloc_627_; 
v_reuseFailAlloc_627_ = lean_alloc_ctor(1, 1, 0);
lean_ctor_set(v_reuseFailAlloc_627_, 0, v___x_624_);
v___x_626_ = v_reuseFailAlloc_627_;
goto v_reusejp_625_;
}
v_reusejp_625_:
{
return v___x_626_;
}
}
}
}
}
}
}
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_set_x3f___redArg___boxed(lean_object* v_x_631_, lean_object* v_x_632_, lean_object* v_x_633_){
_start:
{
lean_object* v_res_634_; 
v_res_634_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_set_x3f___redArg(v_x_631_, v_x_632_, v_x_633_);
lean_dec(v_x_632_);
return v_res_634_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_set_x3f(lean_object* v_00_u03b1_635_, lean_object* v_x_636_, lean_object* v_x_637_, lean_object* v_x_638_){
_start:
{
lean_object* v___x_639_; 
v___x_639_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_set_x3f___redArg(v_x_636_, v_x_637_, v_x_638_);
return v___x_639_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_set_x3f___boxed(lean_object* v_00_u03b1_640_, lean_object* v_x_641_, lean_object* v_x_642_, lean_object* v_x_643_){
_start:
{
lean_object* v_res_644_; 
v_res_644_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_set_x3f(v_00_u03b1_640_, v_x_641_, v_x_642_, v_x_643_);
lean_dec(v_x_642_);
return v_res_644_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_set__2___closed__0(void){
_start:
{
lean_object* v___x_645_; lean_object* v___x_646_; lean_object* v___x_647_; lean_object* v___x_648_; 
v___x_645_ = lean_unsigned_to_nat(42u);
v___x_646_ = lean_unsigned_to_nat(1u);
v___x_647_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_map__double___closed__3));
v___x_648_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_set_x3f___redArg(v___x_647_, v___x_646_, v___x_645_);
return v___x_648_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_set__2(void){
_start:
{
lean_object* v___x_649_; 
v___x_649_ = lean_obj_once(&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_set__2___closed__0, &lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_set__2___closed__0_once, _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_set__2___closed__0);
return v___x_649_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_find_x3f___redArg(lean_object* v_p_650_, lean_object* v_x_651_){
_start:
{
if (lean_obj_tag(v_x_651_) == 0)
{
lean_object* v___x_652_; 
lean_dec_ref(v_p_650_);
v___x_652_ = lean_box(0);
return v___x_652_;
}
else
{
lean_object* v_head_653_; lean_object* v_tail_654_; lean_object* v___x_655_; uint8_t v___x_656_; 
v_head_653_ = lean_ctor_get(v_x_651_, 0);
lean_inc_n(v_head_653_, 2);
v_tail_654_ = lean_ctor_get(v_x_651_, 1);
lean_inc(v_tail_654_);
lean_dec_ref_known(v_x_651_, 2);
lean_inc_ref(v_p_650_);
v___x_655_ = lean_apply_1(v_p_650_, v_head_653_);
v___x_656_ = lean_unbox(v___x_655_);
if (v___x_656_ == 0)
{
lean_dec(v_head_653_);
v_x_651_ = v_tail_654_;
goto _start;
}
else
{
lean_object* v___x_658_; 
lean_dec(v_tail_654_);
lean_dec_ref(v_p_650_);
v___x_658_ = lean_alloc_ctor(1, 1, 0);
lean_ctor_set(v___x_658_, 0, v_head_653_);
return v___x_658_;
}
}
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_find_x3f(lean_object* v_00_u03b1_659_, lean_object* v_p_660_, lean_object* v_x_661_){
_start:
{
lean_object* v___x_662_; 
v___x_662_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_find_x3f___redArg(v_p_660_, v_x_661_);
return v___x_662_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_find__even___closed__1(void){
_start:
{
lean_object* v___x_666_; lean_object* v___f_667_; lean_object* v___x_668_; 
v___x_666_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_find__even___closed__0));
v___f_667_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_filter__even___closed__0));
v___x_668_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_find_x3f___redArg(v___f_667_, v___x_666_);
return v___x_668_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_find__even(void){
_start:
{
lean_object* v___x_669_; 
v___x_669_ = lean_obj_once(&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_find__even___closed__1, &lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_find__even___closed__1_once, _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_find__even___closed__1);
return v___x_669_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_findIndex_x3f_go___redArg(lean_object* v_p_670_, lean_object* v_a_671_, lean_object* v_a_672_){
_start:
{
if (lean_obj_tag(v_a_671_) == 0)
{
lean_object* v___x_673_; 
lean_dec(v_a_672_);
lean_dec_ref(v_p_670_);
v___x_673_ = lean_box(0);
return v___x_673_;
}
else
{
lean_object* v_head_674_; lean_object* v_tail_675_; lean_object* v___x_676_; uint8_t v___x_677_; 
v_head_674_ = lean_ctor_get(v_a_671_, 0);
lean_inc(v_head_674_);
v_tail_675_ = lean_ctor_get(v_a_671_, 1);
lean_inc(v_tail_675_);
lean_dec_ref_known(v_a_671_, 2);
lean_inc_ref(v_p_670_);
v___x_676_ = lean_apply_1(v_p_670_, v_head_674_);
v___x_677_ = lean_unbox(v___x_676_);
if (v___x_677_ == 0)
{
lean_object* v___x_678_; lean_object* v___x_679_; 
v___x_678_ = lean_unsigned_to_nat(1u);
v___x_679_ = lean_nat_add(v_a_672_, v___x_678_);
lean_dec(v_a_672_);
v_a_671_ = v_tail_675_;
v_a_672_ = v___x_679_;
goto _start;
}
else
{
lean_object* v___x_681_; 
lean_dec(v_tail_675_);
lean_dec_ref(v_p_670_);
v___x_681_ = lean_alloc_ctor(1, 1, 0);
lean_ctor_set(v___x_681_, 0, v_a_672_);
return v___x_681_;
}
}
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_findIndex_x3f_go(lean_object* v_00_u03b1_682_, lean_object* v_p_683_, lean_object* v_a_684_, lean_object* v_a_685_){
_start:
{
lean_object* v___x_686_; 
v___x_686_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_findIndex_x3f_go___redArg(v_p_683_, v_a_684_, v_a_685_);
return v___x_686_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_findIndex_x3f___redArg(lean_object* v_p_687_, lean_object* v_l_688_){
_start:
{
lean_object* v___x_689_; lean_object* v___x_690_; 
v___x_689_ = lean_unsigned_to_nat(0u);
v___x_690_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_findIndex_x3f_go___redArg(v_p_687_, v_l_688_, v___x_689_);
return v___x_690_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_findIndex_x3f(lean_object* v_00_u03b1_691_, lean_object* v_p_692_, lean_object* v_l_693_){
_start:
{
lean_object* v___x_694_; 
v___x_694_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_findIndex_x3f___redArg(v_p_692_, v_l_693_);
return v___x_694_;
}
}
LEAN_EXPORT uint8_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_find__index___lam__0(lean_object* v_x_695_){
_start:
{
lean_object* v___x_696_; uint8_t v___x_697_; 
v___x_696_ = lean_unsigned_to_nat(3u);
v___x_697_ = lean_nat_dec_eq(v_x_695_, v___x_696_);
return v___x_697_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_find__index___lam__0___boxed(lean_object* v_x_698_){
_start:
{
uint8_t v_res_699_; lean_object* v_r_700_; 
v_res_699_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_find__index___lam__0(v_x_698_);
lean_dec(v_x_698_);
v_r_700_ = lean_box(v_res_699_);
return v_r_700_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_find__index___closed__3(void){
_start:
{
lean_object* v___x_708_; lean_object* v___f_709_; lean_object* v___x_710_; 
v___x_708_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_find__index___closed__2));
v___f_709_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_find__index___closed__0));
v___x_710_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_findIndex_x3f___redArg(v___f_709_, v___x_708_);
return v___x_710_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_find__index(void){
_start:
{
lean_object* v___x_711_; 
v___x_711_ = lean_obj_once(&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_find__index___closed__3, &lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_find__index___closed__3_once, _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_find__index___closed__3);
return v___x_711_;
}
}
LEAN_EXPORT uint8_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_isSorted(lean_object* v_x_712_){
_start:
{
if (lean_obj_tag(v_x_712_) == 0)
{
uint8_t v___x_713_; 
v___x_713_ = 1;
return v___x_713_;
}
else
{
lean_object* v_tail_714_; 
v_tail_714_ = lean_ctor_get(v_x_712_, 1);
if (lean_obj_tag(v_tail_714_) == 0)
{
uint8_t v___x_715_; 
v___x_715_ = 1;
return v___x_715_;
}
else
{
lean_object* v_head_716_; lean_object* v_head_717_; uint8_t v___x_718_; 
v_head_716_ = lean_ctor_get(v_x_712_, 0);
v_head_717_ = lean_ctor_get(v_tail_714_, 0);
v___x_718_ = lean_nat_dec_le(v_head_716_, v_head_717_);
if (v___x_718_ == 0)
{
return v___x_718_;
}
else
{
v_x_712_ = v_tail_714_;
goto _start;
}
}
}
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_isSorted___boxed(lean_object* v_x_720_){
_start:
{
uint8_t v_res_721_; lean_object* v_r_722_; 
v_res_721_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_isSorted(v_x_720_);
lean_dec(v_x_720_);
v_r_722_ = lean_box(v_res_721_);
return v_r_722_;
}
}
static uint8_t _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_sorted__true___closed__0(void){
_start:
{
lean_object* v___x_723_; uint8_t v___x_724_; 
v___x_723_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_len3___closed__4));
v___x_724_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_isSorted(v___x_723_);
return v___x_724_;
}
}
static uint8_t _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_sorted__true(void){
_start:
{
uint8_t v___x_725_; 
v___x_725_ = lean_uint8_once(&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_sorted__true___closed__0, &lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_sorted__true___closed__0_once, _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_sorted__true___closed__0);
return v___x_725_;
}
}
static uint8_t _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_sorted__false___closed__3(void){
_start:
{
lean_object* v___x_735_; uint8_t v___x_736_; 
v___x_735_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_sorted__false___closed__2));
v___x_736_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_isSorted(v___x_735_);
return v___x_736_;
}
}
static uint8_t _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_sorted__false(void){
_start:
{
uint8_t v___x_737_; 
v___x_737_ = lean_uint8_once(&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_sorted__false___closed__3, &lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_sorted__false___closed__3_once, _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_sorted__false___closed__3);
return v___x_737_;
}
}
LEAN_EXPORT uint8_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_hasDuplicates___redArg(lean_object* v_inst_738_, lean_object* v_x_739_){
_start:
{
if (lean_obj_tag(v_x_739_) == 0)
{
uint8_t v___x_740_; 
lean_dec_ref(v_inst_738_);
v___x_740_ = 0;
return v___x_740_;
}
else
{
lean_object* v_head_741_; lean_object* v_tail_742_; lean_object* v___f_743_; uint8_t v___x_744_; 
v_head_741_ = lean_ctor_get(v_x_739_, 0);
lean_inc(v_head_741_);
v_tail_742_ = lean_ctor_get(v_x_739_, 1);
lean_inc_n(v_tail_742_, 2);
lean_dec_ref_known(v_x_739_, 2);
lean_inc_ref(v_inst_738_);
v___f_743_ = lean_alloc_closure((void*)(l_instBEqOfDecidableEq___redArg___lam__0___boxed), 3, 1);
lean_closure_set(v___f_743_, 0, v_inst_738_);
v___x_744_ = l_List_elem___redArg(v___f_743_, v_head_741_, v_tail_742_);
if (v___x_744_ == 0)
{
v_x_739_ = v_tail_742_;
goto _start;
}
else
{
lean_dec(v_tail_742_);
lean_dec_ref(v_inst_738_);
return v___x_744_;
}
}
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_hasDuplicates___redArg___boxed(lean_object* v_inst_746_, lean_object* v_x_747_){
_start:
{
uint8_t v_res_748_; lean_object* v_r_749_; 
v_res_748_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_hasDuplicates___redArg(v_inst_746_, v_x_747_);
v_r_749_ = lean_box(v_res_748_);
return v_r_749_;
}
}
LEAN_EXPORT uint8_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_hasDuplicates(lean_object* v_00_u03b1_750_, lean_object* v_inst_751_, lean_object* v_x_752_){
_start:
{
uint8_t v___x_753_; 
v___x_753_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_hasDuplicates___redArg(v_inst_751_, v_x_752_);
return v___x_753_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_hasDuplicates___boxed(lean_object* v_00_u03b1_754_, lean_object* v_inst_755_, lean_object* v_x_756_){
_start:
{
uint8_t v_res_757_; lean_object* v_r_758_; 
v_res_757_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_hasDuplicates(v_00_u03b1_754_, v_inst_755_, v_x_756_);
v_r_758_ = lean_box(v_res_757_);
return v_r_758_;
}
}
LEAN_EXPORT uint8_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_hasDuplicates___at___00Lean4Tutorial_Examples_PatternMatching_ListRecursion_dup__true_spec__0(lean_object* v_x_759_){
_start:
{
if (lean_obj_tag(v_x_759_) == 0)
{
uint8_t v___x_760_; 
v___x_760_ = 0;
return v___x_760_;
}
else
{
lean_object* v_head_761_; lean_object* v_tail_762_; uint8_t v___x_763_; 
v_head_761_ = lean_ctor_get(v_x_759_, 0);
v_tail_762_ = lean_ctor_get(v_x_759_, 1);
v___x_763_ = l_List_elem___at___00Lean_Meta_Occurrences_contains_spec__0(v_head_761_, v_tail_762_);
if (v___x_763_ == 0)
{
v_x_759_ = v_tail_762_;
goto _start;
}
else
{
return v___x_763_;
}
}
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_hasDuplicates___at___00Lean4Tutorial_Examples_PatternMatching_ListRecursion_dup__true_spec__0___boxed(lean_object* v_x_765_){
_start:
{
uint8_t v_res_766_; lean_object* v_r_767_; 
v_res_766_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_hasDuplicates___at___00Lean4Tutorial_Examples_PatternMatching_ListRecursion_dup__true_spec__0(v_x_765_);
lean_dec(v_x_765_);
v_r_767_ = lean_box(v_res_766_);
return v_r_767_;
}
}
static uint8_t _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_dup__true___closed__3(void){
_start:
{
lean_object* v___x_777_; uint8_t v___x_778_; 
v___x_777_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_dup__true___closed__2));
v___x_778_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_hasDuplicates___at___00Lean4Tutorial_Examples_PatternMatching_ListRecursion_dup__true_spec__0(v___x_777_);
return v___x_778_;
}
}
static uint8_t _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_dup__true(void){
_start:
{
uint8_t v___x_779_; 
v___x_779_ = lean_uint8_once(&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_dup__true___closed__3, &lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_dup__true___closed__3_once, _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_dup__true___closed__3);
return v___x_779_;
}
}
static uint8_t _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_dup__false___closed__0(void){
_start:
{
lean_object* v___x_780_; uint8_t v___x_781_; 
v___x_780_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_map__double___closed__3));
v___x_781_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_hasDuplicates___at___00Lean4Tutorial_Examples_PatternMatching_ListRecursion_dup__true_spec__0(v___x_780_);
return v___x_781_;
}
}
static uint8_t _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_dup__false(void){
_start:
{
uint8_t v___x_782_; 
v___x_782_ = lean_uint8_once(&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_dup__false___closed__0, &lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_dup__false___closed__0_once, _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_dup__false___closed__0);
return v___x_782_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial___private_Lean4Tutorial_Examples_PatternMatching_ListRecursion_0__Lean4Tutorial_Examples_PatternMatching_ListRecursion_length_match__1_splitter___redArg(lean_object* v_x_783_, lean_object* v_h__1_784_, lean_object* v_h__2_785_){
_start:
{
if (lean_obj_tag(v_x_783_) == 0)
{
lean_object* v___x_786_; lean_object* v___x_787_; 
lean_dec(v_h__2_785_);
v___x_786_ = lean_box(0);
v___x_787_ = lean_apply_1(v_h__1_784_, v___x_786_);
return v___x_787_;
}
else
{
lean_object* v_head_788_; lean_object* v_tail_789_; lean_object* v___x_790_; 
lean_dec(v_h__1_784_);
v_head_788_ = lean_ctor_get(v_x_783_, 0);
lean_inc(v_head_788_);
v_tail_789_ = lean_ctor_get(v_x_783_, 1);
lean_inc(v_tail_789_);
lean_dec_ref_known(v_x_783_, 2);
v___x_790_ = lean_apply_2(v_h__2_785_, v_head_788_, v_tail_789_);
return v___x_790_;
}
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial___private_Lean4Tutorial_Examples_PatternMatching_ListRecursion_0__Lean4Tutorial_Examples_PatternMatching_ListRecursion_length_match__1_splitter(lean_object* v_00_u03b1_791_, lean_object* v_motive_792_, lean_object* v_x_793_, lean_object* v_h__1_794_, lean_object* v_h__2_795_){
_start:
{
if (lean_obj_tag(v_x_793_) == 0)
{
lean_object* v___x_796_; lean_object* v___x_797_; 
lean_dec(v_h__2_795_);
v___x_796_ = lean_box(0);
v___x_797_ = lean_apply_1(v_h__1_794_, v___x_796_);
return v___x_797_;
}
else
{
lean_object* v_head_798_; lean_object* v_tail_799_; lean_object* v___x_800_; 
lean_dec(v_h__1_794_);
v_head_798_ = lean_ctor_get(v_x_793_, 0);
lean_inc(v_head_798_);
v_tail_799_ = lean_ctor_get(v_x_793_, 1);
lean_inc(v_tail_799_);
lean_dec_ref_known(v_x_793_, 2);
v___x_800_ = lean_apply_2(v_h__2_795_, v_head_798_, v_tail_799_);
return v___x_800_;
}
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial___private_Lean4Tutorial_Examples_PatternMatching_ListRecursion_0__Lean4Tutorial_Examples_PatternMatching_ListRecursion_append_match__1_splitter___redArg(lean_object* v_x_801_, lean_object* v_x_802_, lean_object* v_h__1_803_, lean_object* v_h__2_804_){
_start:
{
if (lean_obj_tag(v_x_801_) == 0)
{
lean_object* v___x_805_; 
lean_dec(v_h__2_804_);
v___x_805_ = lean_apply_1(v_h__1_803_, v_x_802_);
return v___x_805_;
}
else
{
lean_object* v_head_806_; lean_object* v_tail_807_; lean_object* v___x_808_; 
lean_dec(v_h__1_803_);
v_head_806_ = lean_ctor_get(v_x_801_, 0);
lean_inc(v_head_806_);
v_tail_807_ = lean_ctor_get(v_x_801_, 1);
lean_inc(v_tail_807_);
lean_dec_ref_known(v_x_801_, 2);
v___x_808_ = lean_apply_3(v_h__2_804_, v_head_806_, v_tail_807_, v_x_802_);
return v___x_808_;
}
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial___private_Lean4Tutorial_Examples_PatternMatching_ListRecursion_0__Lean4Tutorial_Examples_PatternMatching_ListRecursion_append_match__1_splitter(lean_object* v_00_u03b1_809_, lean_object* v_motive_810_, lean_object* v_x_811_, lean_object* v_x_812_, lean_object* v_h__1_813_, lean_object* v_h__2_814_){
_start:
{
if (lean_obj_tag(v_x_811_) == 0)
{
lean_object* v___x_815_; 
lean_dec(v_h__2_814_);
v___x_815_ = lean_apply_1(v_h__1_813_, v_x_812_);
return v___x_815_;
}
else
{
lean_object* v_head_816_; lean_object* v_tail_817_; lean_object* v___x_818_; 
lean_dec(v_h__1_813_);
v_head_816_ = lean_ctor_get(v_x_811_, 0);
lean_inc(v_head_816_);
v_tail_817_ = lean_ctor_get(v_x_811_, 1);
lean_inc(v_tail_817_);
lean_dec_ref_known(v_x_811_, 2);
v___x_818_ = lean_apply_3(v_h__2_814_, v_head_816_, v_tail_817_, v_x_812_);
return v___x_818_;
}
}
}
lean_object* initialize_Init(uint8_t builtin);
lean_object* initialize_Init(uint8_t builtin);
static bool _G_initialized = false;
LEAN_EXPORT lean_object* initialize_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion(uint8_t builtin) {
lean_object * res;
if (_G_initialized) return lean_io_result_mk_ok(lean_box(0));
_G_initialized = true;
res = initialize_Init(builtin);
if (lean_io_result_is_error(res)) return res;
lean_dec_ref(res);
res = initialize_Init(builtin);
if (lean_io_result_is_error(res)) return res;
lean_dec_ref(res);
lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_len1 = _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_len1();
lean_mark_persistent(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_len1);
lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_len2 = _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_len2();
lean_mark_persistent(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_len2);
lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_len3 = _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_len3();
lean_mark_persistent(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_len3);
lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_map__double = _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_map__double();
lean_mark_persistent(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_map__double);
lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_map__toString = _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_map__toString();
lean_mark_persistent(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_map__toString);
lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_map__length = _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_map__length();
lean_mark_persistent(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_map__length);
lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_filter__even = _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_filter__even();
lean_mark_persistent(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_filter__even);
lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_filter__long = _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_filter__long();
lean_mark_persistent(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_filter__long);
lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_sum__example = _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_sum__example();
lean_mark_persistent(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_sum__example);
lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_product__example = _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_product__example();
lean_mark_persistent(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_product__example);
lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_all__even = _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_all__even();
lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_all__even2 = _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_all__even2();
lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_any__even = _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_any__even();
lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_any__even2 = _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_any__even2();
lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_reverse__example = _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_reverse__example();
lean_mark_persistent(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_reverse__example);
lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_sum__l__example = _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_sum__l__example();
lean_mark_persistent(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_sum__l__example);
lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_append__example = _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_append__example();
lean_mark_persistent(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_append__example);
lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_dup__and__double = _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_dup__and__double();
lean_mark_persistent(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_dup__and__double);
lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_zip__example = _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_zip__example();
lean_mark_persistent(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_zip__example);
lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_zipWith__add = _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_zipWith__add();
lean_mark_persistent(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_zipWith__add);
lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_take__3 = _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_take__3();
lean_mark_persistent(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_take__3);
lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_take__10 = _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_take__10();
lean_mark_persistent(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_take__10);
lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_drop__2 = _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_drop__2();
lean_mark_persistent(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_drop__2);
lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_drop__10 = _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_drop__10();
lean_mark_persistent(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_drop__10);
lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_get__2 = _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_get__2();
lean_mark_persistent(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_get__2);
lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_get__10 = _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_get__10();
lean_mark_persistent(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_get__10);
lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_set__2 = _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_set__2();
lean_mark_persistent(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_set__2);
lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_find__even = _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_find__even();
lean_mark_persistent(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_find__even);
lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_find__index = _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_find__index();
lean_mark_persistent(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_find__index);
lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_sorted__true = _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_sorted__true();
lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_sorted__false = _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_sorted__false();
lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_dup__true = _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_dup__true();
lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_dup__false = _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_ListRecursion_dup__false();
return lean_io_result_mk_ok(lean_box(0));
}
#ifdef __cplusplus
}
#endif
