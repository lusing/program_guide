// Lean compiler output
// Module: Lean4Tutorial.Examples.Structures.PatternMatchingStruct
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
uint8_t lean_nat_dec_le(lean_object*, lean_object*);
lean_object* lean_nat_add(lean_object*, lean_object*);
uint8_t lean_nat_dec_eq(lean_object*, lean_object*);
uint8_t lean_nat_dec_lt(lean_object*, lean_object*);
lean_object* l_Repr_addAppParen(lean_object*, lean_object*);
lean_object* lean_nat_to_int(lean_object*);
lean_object* l_Nat_reprFast(lean_object*);
lean_object* lean_string_length(lean_object*);
lean_object* lean_string_append(lean_object*, lean_object*);
lean_object* lean_nat_mul(lean_object*, lean_object*);
static const lean_string_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_instReprPoint_repr___redArg___closed__0_value = {.m_header = {.m_rc = 0, .m_cs_sz = 0, .m_other = 0, .m_tag = 249}, .m_size = 3, .m_capacity = 3, .m_length = 2, .m_data = "{ "};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_instReprPoint_repr___redArg___closed__0 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_instReprPoint_repr___redArg___closed__0_value;
static const lean_string_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_instReprPoint_repr___redArg___closed__1_value = {.m_header = {.m_rc = 0, .m_cs_sz = 0, .m_other = 0, .m_tag = 249}, .m_size = 2, .m_capacity = 2, .m_length = 1, .m_data = "x"};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_instReprPoint_repr___redArg___closed__1 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_instReprPoint_repr___redArg___closed__1_value;
static const lean_ctor_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_instReprPoint_repr___redArg___closed__2_value = {.m_header = {.m_rc = 0, .m_cs_sz = sizeof(lean_ctor_object) + sizeof(void*)*1 + 0, .m_other = 1, .m_tag = 3}, .m_objs = {((lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_instReprPoint_repr___redArg___closed__1_value)}};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_instReprPoint_repr___redArg___closed__2 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_instReprPoint_repr___redArg___closed__2_value;
static const lean_ctor_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_instReprPoint_repr___redArg___closed__3_value = {.m_header = {.m_rc = 0, .m_cs_sz = sizeof(lean_ctor_object) + sizeof(void*)*2 + 0, .m_other = 2, .m_tag = 5}, .m_objs = {((lean_object*)(((size_t)(0) << 1) | 1)),((lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_instReprPoint_repr___redArg___closed__2_value)}};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_instReprPoint_repr___redArg___closed__3 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_instReprPoint_repr___redArg___closed__3_value;
static const lean_string_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_instReprPoint_repr___redArg___closed__4_value = {.m_header = {.m_rc = 0, .m_cs_sz = 0, .m_other = 0, .m_tag = 249}, .m_size = 5, .m_capacity = 5, .m_length = 4, .m_data = " := "};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_instReprPoint_repr___redArg___closed__4 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_instReprPoint_repr___redArg___closed__4_value;
static const lean_ctor_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_instReprPoint_repr___redArg___closed__5_value = {.m_header = {.m_rc = 0, .m_cs_sz = sizeof(lean_ctor_object) + sizeof(void*)*1 + 0, .m_other = 1, .m_tag = 3}, .m_objs = {((lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_instReprPoint_repr___redArg___closed__4_value)}};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_instReprPoint_repr___redArg___closed__5 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_instReprPoint_repr___redArg___closed__5_value;
static const lean_ctor_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_instReprPoint_repr___redArg___closed__6_value = {.m_header = {.m_rc = 0, .m_cs_sz = sizeof(lean_ctor_object) + sizeof(void*)*2 + 0, .m_other = 2, .m_tag = 5}, .m_objs = {((lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_instReprPoint_repr___redArg___closed__3_value),((lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_instReprPoint_repr___redArg___closed__5_value)}};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_instReprPoint_repr___redArg___closed__6 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_instReprPoint_repr___redArg___closed__6_value;
static lean_once_cell_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_instReprPoint_repr___redArg___closed__7_once = LEAN_ONCE_CELL_INITIALIZER;
static lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_instReprPoint_repr___redArg___closed__7;
static const lean_string_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_instReprPoint_repr___redArg___closed__8_value = {.m_header = {.m_rc = 0, .m_cs_sz = 0, .m_other = 0, .m_tag = 249}, .m_size = 2, .m_capacity = 2, .m_length = 1, .m_data = ","};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_instReprPoint_repr___redArg___closed__8 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_instReprPoint_repr___redArg___closed__8_value;
static const lean_ctor_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_instReprPoint_repr___redArg___closed__9_value = {.m_header = {.m_rc = 0, .m_cs_sz = sizeof(lean_ctor_object) + sizeof(void*)*1 + 0, .m_other = 1, .m_tag = 3}, .m_objs = {((lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_instReprPoint_repr___redArg___closed__8_value)}};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_instReprPoint_repr___redArg___closed__9 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_instReprPoint_repr___redArg___closed__9_value;
static const lean_string_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_instReprPoint_repr___redArg___closed__10_value = {.m_header = {.m_rc = 0, .m_cs_sz = 0, .m_other = 0, .m_tag = 249}, .m_size = 2, .m_capacity = 2, .m_length = 1, .m_data = "y"};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_instReprPoint_repr___redArg___closed__10 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_instReprPoint_repr___redArg___closed__10_value;
static const lean_ctor_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_instReprPoint_repr___redArg___closed__11_value = {.m_header = {.m_rc = 0, .m_cs_sz = sizeof(lean_ctor_object) + sizeof(void*)*1 + 0, .m_other = 1, .m_tag = 3}, .m_objs = {((lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_instReprPoint_repr___redArg___closed__10_value)}};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_instReprPoint_repr___redArg___closed__11 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_instReprPoint_repr___redArg___closed__11_value;
static const lean_string_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_instReprPoint_repr___redArg___closed__12_value = {.m_header = {.m_rc = 0, .m_cs_sz = 0, .m_other = 0, .m_tag = 249}, .m_size = 3, .m_capacity = 3, .m_length = 2, .m_data = " }"};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_instReprPoint_repr___redArg___closed__12 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_instReprPoint_repr___redArg___closed__12_value;
static lean_once_cell_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_instReprPoint_repr___redArg___closed__13_once = LEAN_ONCE_CELL_INITIALIZER;
static lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_instReprPoint_repr___redArg___closed__13;
static lean_once_cell_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_instReprPoint_repr___redArg___closed__14_once = LEAN_ONCE_CELL_INITIALIZER;
static lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_instReprPoint_repr___redArg___closed__14;
static const lean_ctor_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_instReprPoint_repr___redArg___closed__15_value = {.m_header = {.m_rc = 0, .m_cs_sz = sizeof(lean_ctor_object) + sizeof(void*)*1 + 0, .m_other = 1, .m_tag = 3}, .m_objs = {((lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_instReprPoint_repr___redArg___closed__0_value)}};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_instReprPoint_repr___redArg___closed__15 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_instReprPoint_repr___redArg___closed__15_value;
static const lean_ctor_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_instReprPoint_repr___redArg___closed__16_value = {.m_header = {.m_rc = 0, .m_cs_sz = sizeof(lean_ctor_object) + sizeof(void*)*1 + 0, .m_other = 1, .m_tag = 3}, .m_objs = {((lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_instReprPoint_repr___redArg___closed__12_value)}};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_instReprPoint_repr___redArg___closed__16 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_instReprPoint_repr___redArg___closed__16_value;
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_instReprPoint_repr___redArg(lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_instReprPoint_repr(lean_object*, lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_instReprPoint_repr___boxed(lean_object*, lean_object*);
static const lean_closure_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_instReprPoint___closed__0_value = {.m_header = {.m_rc = 0, .m_cs_sz = sizeof(lean_closure_object) + sizeof(void*)*0, .m_other = 0, .m_tag = 245}, .m_fun = (void*)lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_instReprPoint_repr___boxed, .m_arity = 2, .m_num_fixed = 0, .m_objs = {} };
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_instReprPoint___closed__0 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_instReprPoint___closed__0_value;
LEAN_EXPORT const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_instReprPoint = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_instReprPoint___closed__0_value;
LEAN_EXPORT uint8_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_instDecidableEqPoint_decEq(lean_object*, lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_instDecidableEqPoint_decEq___boxed(lean_object*, lean_object*);
LEAN_EXPORT uint8_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_instDecidableEqPoint(lean_object*, lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_instDecidableEqPoint___boxed(lean_object*, lean_object*);
static const lean_ctor_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_p1___closed__0_value = {.m_header = {.m_rc = 0, .m_cs_sz = sizeof(lean_ctor_object) + sizeof(void*)*2 + 0, .m_other = 2, .m_tag = 0}, .m_objs = {((lean_object*)(((size_t)(3) << 1) | 1)),((lean_object*)(((size_t)(4) << 1) | 1))}};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_p1___closed__0 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_p1___closed__0_value;
LEAN_EXPORT const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_p1 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_p1___closed__0_value;
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_distSq(lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_distSq___boxed(lean_object*);
static lean_once_cell_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_dist1___closed__0_once = LEAN_ONCE_CELL_INITIALIZER;
static lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_dist1___closed__0;
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_dist1;
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_getX(lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_getX___boxed(lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_x1;
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_addPoints(lean_object*, lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_addPoints___boxed(lean_object*, lean_object*);
static const lean_ctor_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_sum___closed__0_value = {.m_header = {.m_rc = 0, .m_cs_sz = sizeof(lean_ctor_object) + sizeof(void*)*2 + 0, .m_other = 2, .m_tag = 0}, .m_objs = {((lean_object*)(((size_t)(1) << 1) | 1)),((lean_object*)(((size_t)(2) << 1) | 1))}};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_sum___closed__0 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_sum___closed__0_value;
static lean_once_cell_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_sum___closed__1_once = LEAN_ONCE_CELL_INITIALIZER;
static lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_sum___closed__1;
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_sum;
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_addPoints_x27(lean_object*, lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_addPoints_x27___boxed(lean_object*, lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_let__example(lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_let__example___boxed(lean_object*);
static lean_once_cell_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_let__sum___closed__0_once = LEAN_ONCE_CELL_INITIALIZER;
static lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_let__sum___closed__0;
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_let__sum;
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_param__destruct(lean_object*, lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_param__destruct___boxed(lean_object*, lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_lambda__destruct(lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_lambda__destruct___boxed(lean_object*);
static lean_once_cell_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_lambda__sum___closed__0_once = LEAN_ONCE_CELL_INITIALIZER;
static lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_lambda__sum___closed__0;
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_lambda__sum;
static const lean_string_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_instReprColor_repr___redArg___closed__0_value = {.m_header = {.m_rc = 0, .m_cs_sz = 0, .m_other = 0, .m_tag = 249}, .m_size = 4, .m_capacity = 4, .m_length = 3, .m_data = "red"};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_instReprColor_repr___redArg___closed__0 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_instReprColor_repr___redArg___closed__0_value;
static const lean_ctor_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_instReprColor_repr___redArg___closed__1_value = {.m_header = {.m_rc = 0, .m_cs_sz = sizeof(lean_ctor_object) + sizeof(void*)*1 + 0, .m_other = 1, .m_tag = 3}, .m_objs = {((lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_instReprColor_repr___redArg___closed__0_value)}};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_instReprColor_repr___redArg___closed__1 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_instReprColor_repr___redArg___closed__1_value;
static const lean_ctor_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_instReprColor_repr___redArg___closed__2_value = {.m_header = {.m_rc = 0, .m_cs_sz = sizeof(lean_ctor_object) + sizeof(void*)*2 + 0, .m_other = 2, .m_tag = 5}, .m_objs = {((lean_object*)(((size_t)(0) << 1) | 1)),((lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_instReprColor_repr___redArg___closed__1_value)}};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_instReprColor_repr___redArg___closed__2 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_instReprColor_repr___redArg___closed__2_value;
static const lean_ctor_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_instReprColor_repr___redArg___closed__3_value = {.m_header = {.m_rc = 0, .m_cs_sz = sizeof(lean_ctor_object) + sizeof(void*)*2 + 0, .m_other = 2, .m_tag = 5}, .m_objs = {((lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_instReprColor_repr___redArg___closed__2_value),((lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_instReprPoint_repr___redArg___closed__5_value)}};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_instReprColor_repr___redArg___closed__3 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_instReprColor_repr___redArg___closed__3_value;
static lean_once_cell_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_instReprColor_repr___redArg___closed__4_once = LEAN_ONCE_CELL_INITIALIZER;
static lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_instReprColor_repr___redArg___closed__4;
static const lean_string_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_instReprColor_repr___redArg___closed__5_value = {.m_header = {.m_rc = 0, .m_cs_sz = 0, .m_other = 0, .m_tag = 249}, .m_size = 6, .m_capacity = 6, .m_length = 5, .m_data = "green"};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_instReprColor_repr___redArg___closed__5 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_instReprColor_repr___redArg___closed__5_value;
static const lean_ctor_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_instReprColor_repr___redArg___closed__6_value = {.m_header = {.m_rc = 0, .m_cs_sz = sizeof(lean_ctor_object) + sizeof(void*)*1 + 0, .m_other = 1, .m_tag = 3}, .m_objs = {((lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_instReprColor_repr___redArg___closed__5_value)}};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_instReprColor_repr___redArg___closed__6 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_instReprColor_repr___redArg___closed__6_value;
static lean_once_cell_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_instReprColor_repr___redArg___closed__7_once = LEAN_ONCE_CELL_INITIALIZER;
static lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_instReprColor_repr___redArg___closed__7;
static const lean_string_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_instReprColor_repr___redArg___closed__8_value = {.m_header = {.m_rc = 0, .m_cs_sz = 0, .m_other = 0, .m_tag = 249}, .m_size = 5, .m_capacity = 5, .m_length = 4, .m_data = "blue"};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_instReprColor_repr___redArg___closed__8 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_instReprColor_repr___redArg___closed__8_value;
static const lean_ctor_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_instReprColor_repr___redArg___closed__9_value = {.m_header = {.m_rc = 0, .m_cs_sz = sizeof(lean_ctor_object) + sizeof(void*)*1 + 0, .m_other = 1, .m_tag = 3}, .m_objs = {((lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_instReprColor_repr___redArg___closed__8_value)}};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_instReprColor_repr___redArg___closed__9 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_instReprColor_repr___redArg___closed__9_value;
static lean_once_cell_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_instReprColor_repr___redArg___closed__10_once = LEAN_ONCE_CELL_INITIALIZER;
static lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_instReprColor_repr___redArg___closed__10;
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_instReprColor_repr___redArg(lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_instReprColor_repr(lean_object*, lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_instReprColor_repr___boxed(lean_object*, lean_object*);
static const lean_closure_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_instReprColor___closed__0_value = {.m_header = {.m_rc = 0, .m_cs_sz = sizeof(lean_closure_object) + sizeof(void*)*0, .m_other = 0, .m_tag = 245}, .m_fun = (void*)lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_instReprColor_repr___boxed, .m_arity = 2, .m_num_fixed = 0, .m_objs = {} };
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_instReprColor___closed__0 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_instReprColor___closed__0_value;
LEAN_EXPORT const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_instReprColor = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_instReprColor___closed__0_value;
static const lean_string_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_instReprColoredPoint_repr___redArg___closed__0_value = {.m_header = {.m_rc = 0, .m_cs_sz = 0, .m_other = 0, .m_tag = 249}, .m_size = 6, .m_capacity = 6, .m_length = 5, .m_data = "point"};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_instReprColoredPoint_repr___redArg___closed__0 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_instReprColoredPoint_repr___redArg___closed__0_value;
static const lean_ctor_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_instReprColoredPoint_repr___redArg___closed__1_value = {.m_header = {.m_rc = 0, .m_cs_sz = sizeof(lean_ctor_object) + sizeof(void*)*1 + 0, .m_other = 1, .m_tag = 3}, .m_objs = {((lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_instReprColoredPoint_repr___redArg___closed__0_value)}};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_instReprColoredPoint_repr___redArg___closed__1 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_instReprColoredPoint_repr___redArg___closed__1_value;
static const lean_ctor_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_instReprColoredPoint_repr___redArg___closed__2_value = {.m_header = {.m_rc = 0, .m_cs_sz = sizeof(lean_ctor_object) + sizeof(void*)*2 + 0, .m_other = 2, .m_tag = 5}, .m_objs = {((lean_object*)(((size_t)(0) << 1) | 1)),((lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_instReprColoredPoint_repr___redArg___closed__1_value)}};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_instReprColoredPoint_repr___redArg___closed__2 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_instReprColoredPoint_repr___redArg___closed__2_value;
static const lean_ctor_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_instReprColoredPoint_repr___redArg___closed__3_value = {.m_header = {.m_rc = 0, .m_cs_sz = sizeof(lean_ctor_object) + sizeof(void*)*2 + 0, .m_other = 2, .m_tag = 5}, .m_objs = {((lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_instReprColoredPoint_repr___redArg___closed__2_value),((lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_instReprPoint_repr___redArg___closed__5_value)}};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_instReprColoredPoint_repr___redArg___closed__3 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_instReprColoredPoint_repr___redArg___closed__3_value;
static const lean_string_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_instReprColoredPoint_repr___redArg___closed__4_value = {.m_header = {.m_rc = 0, .m_cs_sz = 0, .m_other = 0, .m_tag = 249}, .m_size = 6, .m_capacity = 6, .m_length = 5, .m_data = "color"};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_instReprColoredPoint_repr___redArg___closed__4 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_instReprColoredPoint_repr___redArg___closed__4_value;
static const lean_ctor_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_instReprColoredPoint_repr___redArg___closed__5_value = {.m_header = {.m_rc = 0, .m_cs_sz = sizeof(lean_ctor_object) + sizeof(void*)*1 + 0, .m_other = 1, .m_tag = 3}, .m_objs = {((lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_instReprColoredPoint_repr___redArg___closed__4_value)}};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_instReprColoredPoint_repr___redArg___closed__5 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_instReprColoredPoint_repr___redArg___closed__5_value;
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_instReprColoredPoint_repr___redArg(lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_instReprColoredPoint_repr(lean_object*, lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_instReprColoredPoint_repr___boxed(lean_object*, lean_object*);
static const lean_closure_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_instReprColoredPoint___closed__0_value = {.m_header = {.m_rc = 0, .m_cs_sz = sizeof(lean_closure_object) + sizeof(void*)*0, .m_other = 0, .m_tag = 245}, .m_fun = (void*)lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_instReprColoredPoint_repr___boxed, .m_arity = 2, .m_num_fixed = 0, .m_objs = {} };
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_instReprColoredPoint___closed__0 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_instReprColoredPoint___closed__0_value;
LEAN_EXPORT const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_instReprColoredPoint = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_instReprColoredPoint___closed__0_value;
static const lean_ctor_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_cp___closed__0_value = {.m_header = {.m_rc = 0, .m_cs_sz = sizeof(lean_ctor_object) + sizeof(void*)*2 + 0, .m_other = 2, .m_tag = 0}, .m_objs = {((lean_object*)(((size_t)(10) << 1) | 1)),((lean_object*)(((size_t)(20) << 1) | 1))}};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_cp___closed__0 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_cp___closed__0_value;
static const lean_ctor_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_cp___closed__1_value = {.m_header = {.m_rc = 0, .m_cs_sz = sizeof(lean_ctor_object) + sizeof(void*)*3 + 0, .m_other = 3, .m_tag = 0}, .m_objs = {((lean_object*)(((size_t)(255) << 1) | 1)),((lean_object*)(((size_t)(0) << 1) | 1)),((lean_object*)(((size_t)(0) << 1) | 1))}};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_cp___closed__1 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_cp___closed__1_value;
static const lean_ctor_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_cp___closed__2_value = {.m_header = {.m_rc = 0, .m_cs_sz = sizeof(lean_ctor_object) + sizeof(void*)*2 + 0, .m_other = 2, .m_tag = 0}, .m_objs = {((lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_cp___closed__0_value),((lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_cp___closed__1_value)}};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_cp___closed__2 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_cp___closed__2_value;
LEAN_EXPORT const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_cp = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_cp___closed__2_value;
LEAN_EXPORT uint8_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_isRedAtOrigin(lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_isRedAtOrigin___boxed(lean_object*);
static lean_once_cell_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_check__red__origin___closed__0_once = LEAN_ONCE_CELL_INITIALIZER;
static uint8_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_check__red__origin___closed__0;
LEAN_EXPORT uint8_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_check__red__origin;
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_getPointX(lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_getPointX___boxed(lean_object*);
static lean_once_cell_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_cp__x___closed__0_once = LEAN_ONCE_CELL_INITIALIZER;
static lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_cp__x___closed__0;
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_cp__x;
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_scaleAndSum(lean_object*, lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_scaleAndSum___boxed(lean_object*, lean_object*);
static lean_once_cell_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_scaled__sum___closed__0_once = LEAN_ONCE_CELL_INITIALIZER;
static lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_scaled__sum___closed__0;
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_scaled__sum;
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_BinTree_ctorIdx(lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_BinTree_ctorIdx___boxed(lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_BinTree_ctorElim___redArg(lean_object*, lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_BinTree_ctorElim(lean_object*, lean_object*, lean_object*, lean_object*, lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_BinTree_ctorElim___boxed(lean_object*, lean_object*, lean_object*, lean_object*, lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_BinTree_leaf_elim___redArg(lean_object*, lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_BinTree_leaf_elim(lean_object*, lean_object*, lean_object*, lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_BinTree_node_elim___redArg(lean_object*, lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_BinTree_node_elim(lean_object*, lean_object*, lean_object*, lean_object*);
static const lean_string_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_instReprBinTree_repr___closed__0_value = {.m_header = {.m_rc = 0, .m_cs_sz = 0, .m_other = 0, .m_tag = 249}, .m_size = 69, .m_capacity = 69, .m_length = 68, .m_data = "Lean4Tutorial.Examples.Structures.PatternMatchingStruct.BinTree.leaf"};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_instReprBinTree_repr___closed__0 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_instReprBinTree_repr___closed__0_value;
static const lean_ctor_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_instReprBinTree_repr___closed__1_value = {.m_header = {.m_rc = 0, .m_cs_sz = sizeof(lean_ctor_object) + sizeof(void*)*1 + 0, .m_other = 1, .m_tag = 3}, .m_objs = {((lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_instReprBinTree_repr___closed__0_value)}};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_instReprBinTree_repr___closed__1 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_instReprBinTree_repr___closed__1_value;
static lean_once_cell_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_instReprBinTree_repr___closed__2_once = LEAN_ONCE_CELL_INITIALIZER;
static lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_instReprBinTree_repr___closed__2;
static lean_once_cell_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_instReprBinTree_repr___closed__3_once = LEAN_ONCE_CELL_INITIALIZER;
static lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_instReprBinTree_repr___closed__3;
static const lean_string_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_instReprBinTree_repr___closed__4_value = {.m_header = {.m_rc = 0, .m_cs_sz = 0, .m_other = 0, .m_tag = 249}, .m_size = 69, .m_capacity = 69, .m_length = 68, .m_data = "Lean4Tutorial.Examples.Structures.PatternMatchingStruct.BinTree.node"};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_instReprBinTree_repr___closed__4 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_instReprBinTree_repr___closed__4_value;
static const lean_ctor_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_instReprBinTree_repr___closed__5_value = {.m_header = {.m_rc = 0, .m_cs_sz = sizeof(lean_ctor_object) + sizeof(void*)*1 + 0, .m_other = 1, .m_tag = 3}, .m_objs = {((lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_instReprBinTree_repr___closed__4_value)}};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_instReprBinTree_repr___closed__5 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_instReprBinTree_repr___closed__5_value;
static const lean_ctor_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_instReprBinTree_repr___closed__6_value = {.m_header = {.m_rc = 0, .m_cs_sz = sizeof(lean_ctor_object) + sizeof(void*)*2 + 0, .m_other = 2, .m_tag = 5}, .m_objs = {((lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_instReprBinTree_repr___closed__5_value),((lean_object*)(((size_t)(1) << 1) | 1))}};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_instReprBinTree_repr___closed__6 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_instReprBinTree_repr___closed__6_value;
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_instReprBinTree_repr(lean_object*, lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_instReprBinTree_repr___boxed(lean_object*, lean_object*);
static const lean_closure_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_instReprBinTree___closed__0_value = {.m_header = {.m_rc = 0, .m_cs_sz = sizeof(lean_closure_object) + sizeof(void*)*0, .m_other = 0, .m_tag = 245}, .m_fun = (void*)lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_instReprBinTree_repr___boxed, .m_arity = 2, .m_num_fixed = 0, .m_objs = {} };
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_instReprBinTree___closed__0 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_instReprBinTree___closed__0_value;
LEAN_EXPORT const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_instReprBinTree = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_instReprBinTree___closed__0_value;
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_treeSum(lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_treeSum___boxed(lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_leafCount(lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_leafCount___boxed(lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_treeHeight(lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_treeHeight___boxed(lean_object*);
static const lean_ctor_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_example__tree___closed__0_value = {.m_header = {.m_rc = 0, .m_cs_sz = sizeof(lean_ctor_object) + sizeof(void*)*3 + 0, .m_other = 3, .m_tag = 1}, .m_objs = {((lean_object*)(((size_t)(1) << 1) | 1)),((lean_object*)(((size_t)(0) << 1) | 1)),((lean_object*)(((size_t)(0) << 1) | 1))}};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_example__tree___closed__0 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_example__tree___closed__0_value;
static const lean_ctor_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_example__tree___closed__1_value = {.m_header = {.m_rc = 0, .m_cs_sz = sizeof(lean_ctor_object) + sizeof(void*)*3 + 0, .m_other = 3, .m_tag = 1}, .m_objs = {((lean_object*)(((size_t)(7) << 1) | 1)),((lean_object*)(((size_t)(0) << 1) | 1)),((lean_object*)(((size_t)(0) << 1) | 1))}};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_example__tree___closed__1 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_example__tree___closed__1_value;
static const lean_ctor_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_example__tree___closed__2_value = {.m_header = {.m_rc = 0, .m_cs_sz = sizeof(lean_ctor_object) + sizeof(void*)*3 + 0, .m_other = 3, .m_tag = 1}, .m_objs = {((lean_object*)(((size_t)(5) << 1) | 1)),((lean_object*)(((size_t)(0) << 1) | 1)),((lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_example__tree___closed__1_value)}};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_example__tree___closed__2 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_example__tree___closed__2_value;
static const lean_ctor_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_example__tree___closed__3_value = {.m_header = {.m_rc = 0, .m_cs_sz = sizeof(lean_ctor_object) + sizeof(void*)*3 + 0, .m_other = 3, .m_tag = 1}, .m_objs = {((lean_object*)(((size_t)(3) << 1) | 1)),((lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_example__tree___closed__0_value),((lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_example__tree___closed__2_value)}};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_example__tree___closed__3 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_example__tree___closed__3_value;
LEAN_EXPORT const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_example__tree = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_example__tree___closed__3_value;
static lean_once_cell_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_tree__sum___closed__0_once = LEAN_ONCE_CELL_INITIALIZER;
static lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_tree__sum___closed__0;
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_tree__sum;
static lean_once_cell_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_tree__leaves___closed__0_once = LEAN_ONCE_CELL_INITIALIZER;
static lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_tree__leaves___closed__0;
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_tree__leaves;
static lean_once_cell_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_tree__height___closed__0_once = LEAN_ONCE_CELL_INITIALIZER;
static lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_tree__height___closed__0;
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_tree__height;
LEAN_EXPORT uint8_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_pointCompare(lean_object*, lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_pointCompare___boxed(lean_object*, lean_object*);
LEAN_EXPORT uint8_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_pointCompareFull(lean_object*, lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_pointCompareFull___boxed(lean_object*, lean_object*);
static const lean_ctor_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_cmp1___closed__0_value = {.m_header = {.m_rc = 0, .m_cs_sz = sizeof(lean_ctor_object) + sizeof(void*)*2 + 0, .m_other = 2, .m_tag = 0}, .m_objs = {((lean_object*)(((size_t)(1) << 1) | 1)),((lean_object*)(((size_t)(5) << 1) | 1))}};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_cmp1___closed__0 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_cmp1___closed__0_value;
static const lean_ctor_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_cmp1___closed__1_value = {.m_header = {.m_rc = 0, .m_cs_sz = sizeof(lean_ctor_object) + sizeof(void*)*2 + 0, .m_other = 2, .m_tag = 0}, .m_objs = {((lean_object*)(((size_t)(2) << 1) | 1)),((lean_object*)(((size_t)(3) << 1) | 1))}};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_cmp1___closed__1 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_cmp1___closed__1_value;
static lean_once_cell_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_cmp1___closed__2_once = LEAN_ONCE_CELL_INITIALIZER;
static uint8_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_cmp1___closed__2;
LEAN_EXPORT uint8_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_cmp1;
static const lean_ctor_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_cmp2___closed__0_value = {.m_header = {.m_rc = 0, .m_cs_sz = sizeof(lean_ctor_object) + sizeof(void*)*2 + 0, .m_other = 2, .m_tag = 0}, .m_objs = {((lean_object*)(((size_t)(1) << 1) | 1)),((lean_object*)(((size_t)(3) << 1) | 1))}};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_cmp2___closed__0 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_cmp2___closed__0_value;
static lean_once_cell_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_cmp2___closed__1_once = LEAN_ONCE_CELL_INITIALIZER;
static uint8_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_cmp2___closed__1;
LEAN_EXPORT uint8_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_cmp2;
LEAN_EXPORT uint8_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_inFirstQuadrant(lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_inFirstQuadrant___boxed(lean_object*);
LEAN_EXPORT uint8_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_inFirstQuadrant_x27(lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_inFirstQuadrant_x27___boxed(lean_object*);
static const lean_string_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_quadrant___closed__0_value = {.m_header = {.m_rc = 0, .m_cs_sz = 0, .m_other = 0, .m_tag = 249}, .m_size = 13, .m_capacity = 13, .m_length = 4, .m_data = "第三象限"};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_quadrant___closed__0 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_quadrant___closed__0_value;
static const lean_string_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_quadrant___closed__1_value = {.m_header = {.m_rc = 0, .m_cs_sz = 0, .m_other = 0, .m_tag = 249}, .m_size = 13, .m_capacity = 13, .m_length = 4, .m_data = "第二象限"};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_quadrant___closed__1 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_quadrant___closed__1_value;
static const lean_string_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_quadrant___closed__2_value = {.m_header = {.m_rc = 0, .m_cs_sz = 0, .m_other = 0, .m_tag = 249}, .m_size = 13, .m_capacity = 13, .m_length = 4, .m_data = "第四象限"};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_quadrant___closed__2 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_quadrant___closed__2_value;
static const lean_string_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_quadrant___closed__3_value = {.m_header = {.m_rc = 0, .m_cs_sz = 0, .m_other = 0, .m_tag = 249}, .m_size = 13, .m_capacity = 13, .m_length = 4, .m_data = "第一象限"};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_quadrant___closed__3 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_quadrant___closed__3_value;
static const lean_string_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_quadrant___closed__4_value = {.m_header = {.m_rc = 0, .m_cs_sz = 0, .m_other = 0, .m_tag = 249}, .m_size = 8, .m_capacity = 8, .m_length = 3, .m_data = "x轴上"};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_quadrant___closed__4 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_quadrant___closed__4_value;
static const lean_string_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_quadrant___closed__5_value = {.m_header = {.m_rc = 0, .m_cs_sz = 0, .m_other = 0, .m_tag = 249}, .m_size = 8, .m_capacity = 8, .m_length = 3, .m_data = "y轴上"};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_quadrant___closed__5 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_quadrant___closed__5_value;
static const lean_string_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_quadrant___closed__6_value = {.m_header = {.m_rc = 0, .m_cs_sz = 0, .m_other = 0, .m_tag = 249}, .m_size = 7, .m_capacity = 7, .m_length = 2, .m_data = "原点"};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_quadrant___closed__6 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_quadrant___closed__6_value;
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_quadrant(lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_quadrant___boxed(lean_object*);
static lean_once_cell_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_q1___closed__0_once = LEAN_ONCE_CELL_INITIALIZER;
static lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_q1___closed__0;
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_q1;
static const lean_ctor_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_q0___closed__0_value = {.m_header = {.m_rc = 0, .m_cs_sz = sizeof(lean_ctor_object) + sizeof(void*)*2 + 0, .m_other = 2, .m_tag = 0}, .m_objs = {((lean_object*)(((size_t)(0) << 1) | 1)),((lean_object*)(((size_t)(0) << 1) | 1))}};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_q0___closed__0 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_q0___closed__0_value;
static lean_once_cell_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_q0___closed__1_once = LEAN_ONCE_CELL_INITIALIZER;
static lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_q0___closed__1;
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_q0;
static const lean_ctor_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_points___closed__0_value = {.m_header = {.m_rc = 0, .m_cs_sz = sizeof(lean_ctor_object) + sizeof(void*)*2 + 0, .m_other = 2, .m_tag = 0}, .m_objs = {((lean_object*)(((size_t)(5) << 1) | 1)),((lean_object*)(((size_t)(6) << 1) | 1))}};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_points___closed__0 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_points___closed__0_value;
static const lean_ctor_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_points___closed__1_value = {.m_header = {.m_rc = 0, .m_cs_sz = sizeof(lean_ctor_object) + sizeof(void*)*2 + 0, .m_other = 2, .m_tag = 1}, .m_objs = {((lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_points___closed__0_value),((lean_object*)(((size_t)(0) << 1) | 1))}};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_points___closed__1 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_points___closed__1_value;
static const lean_ctor_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_points___closed__2_value = {.m_header = {.m_rc = 0, .m_cs_sz = sizeof(lean_ctor_object) + sizeof(void*)*2 + 0, .m_other = 2, .m_tag = 1}, .m_objs = {((lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_p1___closed__0_value),((lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_points___closed__1_value)}};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_points___closed__2 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_points___closed__2_value;
static const lean_ctor_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_points___closed__3_value = {.m_header = {.m_rc = 0, .m_cs_sz = sizeof(lean_ctor_object) + sizeof(void*)*2 + 0, .m_other = 2, .m_tag = 1}, .m_objs = {((lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_sum___closed__0_value),((lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_points___closed__2_value)}};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_points___closed__3 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_points___closed__3_value;
LEAN_EXPORT const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_points = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_points___closed__3_value;
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_sumXs(lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_sumXs___boxed(lean_object*);
static lean_once_cell_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_sum__xs___closed__0_once = LEAN_ONCE_CELL_INITIALIZER;
static lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_sum__xs___closed__0;
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_sum__xs;
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_findYGT5(lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_findYGT5___boxed(lean_object*);
static lean_once_cell_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_found___closed__0_once = LEAN_ONCE_CELL_INITIALIZER;
static lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_found___closed__0;
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_found;
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial___private_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_0__Lean4Tutorial_Examples_Structures_PatternMatchingStruct_distSq_match__1_splitter___redArg(lean_object*, lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial___private_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_0__Lean4Tutorial_Examples_Structures_PatternMatchingStruct_distSq_match__1_splitter(lean_object*, lean_object*, lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_getX_x27(lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_getX_x27___boxed(lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_getY_x27(lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_getY_x27___boxed(lean_object*);
static const lean_string_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_instReprBigStruct_repr___redArg___closed__0_value = {.m_header = {.m_rc = 0, .m_cs_sz = 0, .m_other = 0, .m_tag = 249}, .m_size = 2, .m_capacity = 2, .m_length = 1, .m_data = "a"};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_instReprBigStruct_repr___redArg___closed__0 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_instReprBigStruct_repr___redArg___closed__0_value;
static const lean_ctor_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_instReprBigStruct_repr___redArg___closed__1_value = {.m_header = {.m_rc = 0, .m_cs_sz = sizeof(lean_ctor_object) + sizeof(void*)*1 + 0, .m_other = 1, .m_tag = 3}, .m_objs = {((lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_instReprBigStruct_repr___redArg___closed__0_value)}};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_instReprBigStruct_repr___redArg___closed__1 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_instReprBigStruct_repr___redArg___closed__1_value;
static const lean_ctor_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_instReprBigStruct_repr___redArg___closed__2_value = {.m_header = {.m_rc = 0, .m_cs_sz = sizeof(lean_ctor_object) + sizeof(void*)*2 + 0, .m_other = 2, .m_tag = 5}, .m_objs = {((lean_object*)(((size_t)(0) << 1) | 1)),((lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_instReprBigStruct_repr___redArg___closed__1_value)}};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_instReprBigStruct_repr___redArg___closed__2 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_instReprBigStruct_repr___redArg___closed__2_value;
static const lean_ctor_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_instReprBigStruct_repr___redArg___closed__3_value = {.m_header = {.m_rc = 0, .m_cs_sz = sizeof(lean_ctor_object) + sizeof(void*)*2 + 0, .m_other = 2, .m_tag = 5}, .m_objs = {((lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_instReprBigStruct_repr___redArg___closed__2_value),((lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_instReprPoint_repr___redArg___closed__5_value)}};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_instReprBigStruct_repr___redArg___closed__3 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_instReprBigStruct_repr___redArg___closed__3_value;
static const lean_string_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_instReprBigStruct_repr___redArg___closed__4_value = {.m_header = {.m_rc = 0, .m_cs_sz = 0, .m_other = 0, .m_tag = 249}, .m_size = 2, .m_capacity = 2, .m_length = 1, .m_data = "b"};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_instReprBigStruct_repr___redArg___closed__4 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_instReprBigStruct_repr___redArg___closed__4_value;
static const lean_ctor_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_instReprBigStruct_repr___redArg___closed__5_value = {.m_header = {.m_rc = 0, .m_cs_sz = sizeof(lean_ctor_object) + sizeof(void*)*1 + 0, .m_other = 1, .m_tag = 3}, .m_objs = {((lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_instReprBigStruct_repr___redArg___closed__4_value)}};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_instReprBigStruct_repr___redArg___closed__5 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_instReprBigStruct_repr___redArg___closed__5_value;
static const lean_string_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_instReprBigStruct_repr___redArg___closed__6_value = {.m_header = {.m_rc = 0, .m_cs_sz = 0, .m_other = 0, .m_tag = 249}, .m_size = 2, .m_capacity = 2, .m_length = 1, .m_data = "c"};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_instReprBigStruct_repr___redArg___closed__6 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_instReprBigStruct_repr___redArg___closed__6_value;
static const lean_ctor_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_instReprBigStruct_repr___redArg___closed__7_value = {.m_header = {.m_rc = 0, .m_cs_sz = sizeof(lean_ctor_object) + sizeof(void*)*1 + 0, .m_other = 1, .m_tag = 3}, .m_objs = {((lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_instReprBigStruct_repr___redArg___closed__6_value)}};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_instReprBigStruct_repr___redArg___closed__7 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_instReprBigStruct_repr___redArg___closed__7_value;
static const lean_string_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_instReprBigStruct_repr___redArg___closed__8_value = {.m_header = {.m_rc = 0, .m_cs_sz = 0, .m_other = 0, .m_tag = 249}, .m_size = 2, .m_capacity = 2, .m_length = 1, .m_data = "d"};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_instReprBigStruct_repr___redArg___closed__8 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_instReprBigStruct_repr___redArg___closed__8_value;
static const lean_ctor_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_instReprBigStruct_repr___redArg___closed__9_value = {.m_header = {.m_rc = 0, .m_cs_sz = sizeof(lean_ctor_object) + sizeof(void*)*1 + 0, .m_other = 1, .m_tag = 3}, .m_objs = {((lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_instReprBigStruct_repr___redArg___closed__8_value)}};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_instReprBigStruct_repr___redArg___closed__9 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_instReprBigStruct_repr___redArg___closed__9_value;
static const lean_string_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_instReprBigStruct_repr___redArg___closed__10_value = {.m_header = {.m_rc = 0, .m_cs_sz = 0, .m_other = 0, .m_tag = 249}, .m_size = 2, .m_capacity = 2, .m_length = 1, .m_data = "e"};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_instReprBigStruct_repr___redArg___closed__10 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_instReprBigStruct_repr___redArg___closed__10_value;
static const lean_ctor_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_instReprBigStruct_repr___redArg___closed__11_value = {.m_header = {.m_rc = 0, .m_cs_sz = sizeof(lean_ctor_object) + sizeof(void*)*1 + 0, .m_other = 1, .m_tag = 3}, .m_objs = {((lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_instReprBigStruct_repr___redArg___closed__10_value)}};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_instReprBigStruct_repr___redArg___closed__11 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_instReprBigStruct_repr___redArg___closed__11_value;
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_instReprBigStruct_repr___redArg(lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_instReprBigStruct_repr(lean_object*, lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_instReprBigStruct_repr___boxed(lean_object*, lean_object*);
static const lean_closure_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_instReprBigStruct___closed__0_value = {.m_header = {.m_rc = 0, .m_cs_sz = sizeof(lean_closure_object) + sizeof(void*)*0, .m_other = 0, .m_tag = 245}, .m_fun = (void*)lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_instReprBigStruct_repr___boxed, .m_arity = 2, .m_num_fixed = 0, .m_objs = {} };
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_instReprBigStruct___closed__0 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_instReprBigStruct___closed__0_value;
LEAN_EXPORT const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_instReprBigStruct = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_instReprBigStruct___closed__0_value;
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_getA(lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_getA___boxed(lean_object*);
static const lean_ctor_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_big___closed__0_value = {.m_header = {.m_rc = 0, .m_cs_sz = sizeof(lean_ctor_object) + sizeof(void*)*5 + 0, .m_other = 5, .m_tag = 0}, .m_objs = {((lean_object*)(((size_t)(1) << 1) | 1)),((lean_object*)(((size_t)(2) << 1) | 1)),((lean_object*)(((size_t)(3) << 1) | 1)),((lean_object*)(((size_t)(4) << 1) | 1)),((lean_object*)(((size_t)(5) << 1) | 1))}};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_big___closed__0 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_big___closed__0_value;
LEAN_EXPORT const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_big = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_big___closed__0_value;
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_a__val;
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_addPoints2(lean_object*, lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_addPoints2___boxed(lean_object*, lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_addPoints3(lean_object*, lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_addPoints3___boxed(lean_object*, lean_object*);
static const lean_string_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_describePoint___closed__0_value = {.m_header = {.m_rc = 0, .m_cs_sz = 0, .m_other = 0, .m_tag = 249}, .m_size = 7, .m_capacity = 7, .m_length = 6, .m_data = "Point("};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_describePoint___closed__0 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_describePoint___closed__0_value;
static const lean_string_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_describePoint___closed__1_value = {.m_header = {.m_rc = 0, .m_cs_sz = 0, .m_other = 0, .m_tag = 249}, .m_size = 3, .m_capacity = 3, .m_length = 2, .m_data = ", "};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_describePoint___closed__1 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_describePoint___closed__1_value;
static const lean_string_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_describePoint___closed__2_value = {.m_header = {.m_rc = 0, .m_cs_sz = 0, .m_other = 0, .m_tag = 249}, .m_size = 8, .m_capacity = 8, .m_length = 7, .m_data = "), sum="};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_describePoint___closed__2 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_describePoint___closed__2_value;
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_describePoint(lean_object*);
static lean_once_cell_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_desc___closed__0_once = LEAN_ONCE_CELL_INITIALIZER;
static lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_desc___closed__0;
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_desc;
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_instReprPoint_repr___redArg___closed__7(void){
_start:
{
lean_object* v___x_14_; lean_object* v___x_15_; 
v___x_14_ = lean_unsigned_to_nat(5u);
v___x_15_ = lean_nat_to_int(v___x_14_);
return v___x_15_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_instReprPoint_repr___redArg___closed__13(void){
_start:
{
lean_object* v___x_23_; lean_object* v___x_24_; 
v___x_23_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_instReprPoint_repr___redArg___closed__0));
v___x_24_ = lean_string_length(v___x_23_);
return v___x_24_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_instReprPoint_repr___redArg___closed__14(void){
_start:
{
lean_object* v___x_25_; lean_object* v___x_26_; 
v___x_25_ = lean_obj_once(&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_instReprPoint_repr___redArg___closed__13, &lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_instReprPoint_repr___redArg___closed__13_once, _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_instReprPoint_repr___redArg___closed__13);
v___x_26_ = lean_nat_to_int(v___x_25_);
return v___x_26_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_instReprPoint_repr___redArg(lean_object* v_x_31_){
_start:
{
lean_object* v_x_32_; lean_object* v_y_33_; lean_object* v___x_35_; uint8_t v_isShared_36_; uint8_t v_isSharedCheck_67_; 
v_x_32_ = lean_ctor_get(v_x_31_, 0);
v_y_33_ = lean_ctor_get(v_x_31_, 1);
v_isSharedCheck_67_ = !lean_is_exclusive(v_x_31_);
if (v_isSharedCheck_67_ == 0)
{
v___x_35_ = v_x_31_;
v_isShared_36_ = v_isSharedCheck_67_;
goto v_resetjp_34_;
}
else
{
lean_inc(v_y_33_);
lean_inc(v_x_32_);
lean_dec(v_x_31_);
v___x_35_ = lean_box(0);
v_isShared_36_ = v_isSharedCheck_67_;
goto v_resetjp_34_;
}
v_resetjp_34_:
{
lean_object* v___x_37_; lean_object* v___x_38_; lean_object* v___x_39_; lean_object* v___x_40_; lean_object* v___x_41_; lean_object* v___x_43_; 
v___x_37_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_instReprPoint_repr___redArg___closed__5));
v___x_38_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_instReprPoint_repr___redArg___closed__6));
v___x_39_ = lean_obj_once(&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_instReprPoint_repr___redArg___closed__7, &lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_instReprPoint_repr___redArg___closed__7_once, _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_instReprPoint_repr___redArg___closed__7);
v___x_40_ = l_Nat_reprFast(v_x_32_);
v___x_41_ = lean_alloc_ctor(3, 1, 0);
lean_ctor_set(v___x_41_, 0, v___x_40_);
if (v_isShared_36_ == 0)
{
lean_ctor_set_tag(v___x_35_, 4);
lean_ctor_set(v___x_35_, 1, v___x_41_);
lean_ctor_set(v___x_35_, 0, v___x_39_);
v___x_43_ = v___x_35_;
goto v_reusejp_42_;
}
else
{
lean_object* v_reuseFailAlloc_66_; 
v_reuseFailAlloc_66_ = lean_alloc_ctor(4, 2, 0);
lean_ctor_set(v_reuseFailAlloc_66_, 0, v___x_39_);
lean_ctor_set(v_reuseFailAlloc_66_, 1, v___x_41_);
v___x_43_ = v_reuseFailAlloc_66_;
goto v_reusejp_42_;
}
v_reusejp_42_:
{
uint8_t v___x_44_; lean_object* v___x_45_; lean_object* v___x_46_; lean_object* v___x_47_; lean_object* v___x_48_; lean_object* v___x_49_; lean_object* v___x_50_; lean_object* v___x_51_; lean_object* v___x_52_; lean_object* v___x_53_; lean_object* v___x_54_; lean_object* v___x_55_; lean_object* v___x_56_; lean_object* v___x_57_; lean_object* v___x_58_; lean_object* v___x_59_; lean_object* v___x_60_; lean_object* v___x_61_; lean_object* v___x_62_; lean_object* v___x_63_; lean_object* v___x_64_; lean_object* v___x_65_; 
v___x_44_ = 0;
v___x_45_ = lean_alloc_ctor(6, 1, 1);
lean_ctor_set(v___x_45_, 0, v___x_43_);
lean_ctor_set_uint8(v___x_45_, sizeof(void*)*1, v___x_44_);
v___x_46_ = lean_alloc_ctor(5, 2, 0);
lean_ctor_set(v___x_46_, 0, v___x_38_);
lean_ctor_set(v___x_46_, 1, v___x_45_);
v___x_47_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_instReprPoint_repr___redArg___closed__9));
v___x_48_ = lean_alloc_ctor(5, 2, 0);
lean_ctor_set(v___x_48_, 0, v___x_46_);
lean_ctor_set(v___x_48_, 1, v___x_47_);
v___x_49_ = lean_box(1);
v___x_50_ = lean_alloc_ctor(5, 2, 0);
lean_ctor_set(v___x_50_, 0, v___x_48_);
lean_ctor_set(v___x_50_, 1, v___x_49_);
v___x_51_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_instReprPoint_repr___redArg___closed__11));
v___x_52_ = lean_alloc_ctor(5, 2, 0);
lean_ctor_set(v___x_52_, 0, v___x_50_);
lean_ctor_set(v___x_52_, 1, v___x_51_);
v___x_53_ = lean_alloc_ctor(5, 2, 0);
lean_ctor_set(v___x_53_, 0, v___x_52_);
lean_ctor_set(v___x_53_, 1, v___x_37_);
v___x_54_ = l_Nat_reprFast(v_y_33_);
v___x_55_ = lean_alloc_ctor(3, 1, 0);
lean_ctor_set(v___x_55_, 0, v___x_54_);
v___x_56_ = lean_alloc_ctor(4, 2, 0);
lean_ctor_set(v___x_56_, 0, v___x_39_);
lean_ctor_set(v___x_56_, 1, v___x_55_);
v___x_57_ = lean_alloc_ctor(6, 1, 1);
lean_ctor_set(v___x_57_, 0, v___x_56_);
lean_ctor_set_uint8(v___x_57_, sizeof(void*)*1, v___x_44_);
v___x_58_ = lean_alloc_ctor(5, 2, 0);
lean_ctor_set(v___x_58_, 0, v___x_53_);
lean_ctor_set(v___x_58_, 1, v___x_57_);
v___x_59_ = lean_obj_once(&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_instReprPoint_repr___redArg___closed__14, &lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_instReprPoint_repr___redArg___closed__14_once, _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_instReprPoint_repr___redArg___closed__14);
v___x_60_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_instReprPoint_repr___redArg___closed__15));
v___x_61_ = lean_alloc_ctor(5, 2, 0);
lean_ctor_set(v___x_61_, 0, v___x_60_);
lean_ctor_set(v___x_61_, 1, v___x_58_);
v___x_62_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_instReprPoint_repr___redArg___closed__16));
v___x_63_ = lean_alloc_ctor(5, 2, 0);
lean_ctor_set(v___x_63_, 0, v___x_61_);
lean_ctor_set(v___x_63_, 1, v___x_62_);
v___x_64_ = lean_alloc_ctor(4, 2, 0);
lean_ctor_set(v___x_64_, 0, v___x_59_);
lean_ctor_set(v___x_64_, 1, v___x_63_);
v___x_65_ = lean_alloc_ctor(6, 1, 1);
lean_ctor_set(v___x_65_, 0, v___x_64_);
lean_ctor_set_uint8(v___x_65_, sizeof(void*)*1, v___x_44_);
return v___x_65_;
}
}
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_instReprPoint_repr(lean_object* v_x_68_, lean_object* v_prec_69_){
_start:
{
lean_object* v___x_70_; 
v___x_70_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_instReprPoint_repr___redArg(v_x_68_);
return v___x_70_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_instReprPoint_repr___boxed(lean_object* v_x_71_, lean_object* v_prec_72_){
_start:
{
lean_object* v_res_73_; 
v_res_73_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_instReprPoint_repr(v_x_71_, v_prec_72_);
lean_dec(v_prec_72_);
return v_res_73_;
}
}
LEAN_EXPORT uint8_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_instDecidableEqPoint_decEq(lean_object* v_x_76_, lean_object* v_x_77_){
_start:
{
lean_object* v_x_78_; lean_object* v_y_79_; lean_object* v_x_80_; lean_object* v_y_81_; uint8_t v___x_82_; 
v_x_78_ = lean_ctor_get(v_x_76_, 0);
v_y_79_ = lean_ctor_get(v_x_76_, 1);
v_x_80_ = lean_ctor_get(v_x_77_, 0);
v_y_81_ = lean_ctor_get(v_x_77_, 1);
v___x_82_ = lean_nat_dec_eq(v_x_78_, v_x_80_);
if (v___x_82_ == 0)
{
return v___x_82_;
}
else
{
uint8_t v___x_83_; 
v___x_83_ = lean_nat_dec_eq(v_y_79_, v_y_81_);
return v___x_83_;
}
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_instDecidableEqPoint_decEq___boxed(lean_object* v_x_84_, lean_object* v_x_85_){
_start:
{
uint8_t v_res_86_; lean_object* v_r_87_; 
v_res_86_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_instDecidableEqPoint_decEq(v_x_84_, v_x_85_);
lean_dec_ref(v_x_85_);
lean_dec_ref(v_x_84_);
v_r_87_ = lean_box(v_res_86_);
return v_r_87_;
}
}
LEAN_EXPORT uint8_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_instDecidableEqPoint(lean_object* v_x_88_, lean_object* v_x_89_){
_start:
{
uint8_t v___x_90_; 
v___x_90_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_instDecidableEqPoint_decEq(v_x_88_, v_x_89_);
return v___x_90_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_instDecidableEqPoint___boxed(lean_object* v_x_91_, lean_object* v_x_92_){
_start:
{
uint8_t v_res_93_; lean_object* v_r_94_; 
v_res_93_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_instDecidableEqPoint(v_x_91_, v_x_92_);
lean_dec_ref(v_x_92_);
lean_dec_ref(v_x_91_);
v_r_94_ = lean_box(v_res_93_);
return v_r_94_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_distSq(lean_object* v_p_99_){
_start:
{
lean_object* v_x_100_; lean_object* v_y_101_; lean_object* v___x_102_; lean_object* v___x_103_; lean_object* v___x_104_; 
v_x_100_ = lean_ctor_get(v_p_99_, 0);
v_y_101_ = lean_ctor_get(v_p_99_, 1);
v___x_102_ = lean_nat_mul(v_x_100_, v_x_100_);
v___x_103_ = lean_nat_mul(v_y_101_, v_y_101_);
v___x_104_ = lean_nat_add(v___x_102_, v___x_103_);
lean_dec(v___x_103_);
lean_dec(v___x_102_);
return v___x_104_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_distSq___boxed(lean_object* v_p_105_){
_start:
{
lean_object* v_res_106_; 
v_res_106_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_distSq(v_p_105_);
lean_dec_ref(v_p_105_);
return v_res_106_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_dist1___closed__0(void){
_start:
{
lean_object* v___x_107_; lean_object* v___x_108_; 
v___x_107_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_p1));
v___x_108_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_distSq(v___x_107_);
return v___x_108_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_dist1(void){
_start:
{
lean_object* v___x_109_; 
v___x_109_ = lean_obj_once(&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_dist1___closed__0, &lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_dist1___closed__0_once, _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_dist1___closed__0);
return v___x_109_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_getX(lean_object* v_p_110_){
_start:
{
lean_object* v_x_111_; 
v_x_111_ = lean_ctor_get(v_p_110_, 0);
lean_inc(v_x_111_);
return v_x_111_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_getX___boxed(lean_object* v_p_112_){
_start:
{
lean_object* v_res_113_; 
v_res_113_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_getX(v_p_112_);
lean_dec_ref(v_p_112_);
return v_res_113_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_x1(void){
_start:
{
lean_object* v___x_114_; lean_object* v_x_115_; 
v___x_114_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_p1));
v_x_115_ = lean_ctor_get(v___x_114_, 0);
lean_inc(v_x_115_);
return v_x_115_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_addPoints(lean_object* v_x_116_, lean_object* v_x_117_){
_start:
{
lean_object* v_x_118_; lean_object* v_y_119_; lean_object* v_x_120_; lean_object* v_y_121_; lean_object* v___x_123_; uint8_t v_isShared_124_; uint8_t v_isSharedCheck_130_; 
v_x_118_ = lean_ctor_get(v_x_116_, 0);
v_y_119_ = lean_ctor_get(v_x_116_, 1);
v_x_120_ = lean_ctor_get(v_x_117_, 0);
v_y_121_ = lean_ctor_get(v_x_117_, 1);
v_isSharedCheck_130_ = !lean_is_exclusive(v_x_117_);
if (v_isSharedCheck_130_ == 0)
{
v___x_123_ = v_x_117_;
v_isShared_124_ = v_isSharedCheck_130_;
goto v_resetjp_122_;
}
else
{
lean_inc(v_y_121_);
lean_inc(v_x_120_);
lean_dec(v_x_117_);
v___x_123_ = lean_box(0);
v_isShared_124_ = v_isSharedCheck_130_;
goto v_resetjp_122_;
}
v_resetjp_122_:
{
lean_object* v___x_125_; lean_object* v___x_126_; lean_object* v___x_128_; 
v___x_125_ = lean_nat_add(v_x_118_, v_x_120_);
lean_dec(v_x_120_);
v___x_126_ = lean_nat_add(v_y_119_, v_y_121_);
lean_dec(v_y_121_);
if (v_isShared_124_ == 0)
{
lean_ctor_set(v___x_123_, 1, v___x_126_);
lean_ctor_set(v___x_123_, 0, v___x_125_);
v___x_128_ = v___x_123_;
goto v_reusejp_127_;
}
else
{
lean_object* v_reuseFailAlloc_129_; 
v_reuseFailAlloc_129_ = lean_alloc_ctor(0, 2, 0);
lean_ctor_set(v_reuseFailAlloc_129_, 0, v___x_125_);
lean_ctor_set(v_reuseFailAlloc_129_, 1, v___x_126_);
v___x_128_ = v_reuseFailAlloc_129_;
goto v_reusejp_127_;
}
v_reusejp_127_:
{
return v___x_128_;
}
}
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_addPoints___boxed(lean_object* v_x_131_, lean_object* v_x_132_){
_start:
{
lean_object* v_res_133_; 
v_res_133_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_addPoints(v_x_131_, v_x_132_);
lean_dec_ref(v_x_131_);
return v_res_133_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_sum___closed__1(void){
_start:
{
lean_object* v___x_137_; lean_object* v___x_138_; lean_object* v___x_139_; 
v___x_137_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_p1___closed__0));
v___x_138_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_sum___closed__0));
v___x_139_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_addPoints(v___x_138_, v___x_137_);
return v___x_139_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_sum(void){
_start:
{
lean_object* v___x_140_; 
v___x_140_ = lean_obj_once(&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_sum___closed__1, &lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_sum___closed__1_once, _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_sum___closed__1);
return v___x_140_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_addPoints_x27(lean_object* v_p1_141_, lean_object* v_p2_142_){
_start:
{
lean_object* v_x_143_; lean_object* v_y_144_; lean_object* v_x_145_; lean_object* v_y_146_; lean_object* v___x_148_; uint8_t v_isShared_149_; uint8_t v_isSharedCheck_155_; 
v_x_143_ = lean_ctor_get(v_p1_141_, 0);
v_y_144_ = lean_ctor_get(v_p1_141_, 1);
v_x_145_ = lean_ctor_get(v_p2_142_, 0);
v_y_146_ = lean_ctor_get(v_p2_142_, 1);
v_isSharedCheck_155_ = !lean_is_exclusive(v_p2_142_);
if (v_isSharedCheck_155_ == 0)
{
v___x_148_ = v_p2_142_;
v_isShared_149_ = v_isSharedCheck_155_;
goto v_resetjp_147_;
}
else
{
lean_inc(v_y_146_);
lean_inc(v_x_145_);
lean_dec(v_p2_142_);
v___x_148_ = lean_box(0);
v_isShared_149_ = v_isSharedCheck_155_;
goto v_resetjp_147_;
}
v_resetjp_147_:
{
lean_object* v___x_150_; lean_object* v___x_151_; lean_object* v___x_153_; 
v___x_150_ = lean_nat_add(v_x_143_, v_x_145_);
lean_dec(v_x_145_);
v___x_151_ = lean_nat_add(v_y_144_, v_y_146_);
lean_dec(v_y_146_);
if (v_isShared_149_ == 0)
{
lean_ctor_set(v___x_148_, 1, v___x_151_);
lean_ctor_set(v___x_148_, 0, v___x_150_);
v___x_153_ = v___x_148_;
goto v_reusejp_152_;
}
else
{
lean_object* v_reuseFailAlloc_154_; 
v_reuseFailAlloc_154_ = lean_alloc_ctor(0, 2, 0);
lean_ctor_set(v_reuseFailAlloc_154_, 0, v___x_150_);
lean_ctor_set(v_reuseFailAlloc_154_, 1, v___x_151_);
v___x_153_ = v_reuseFailAlloc_154_;
goto v_reusejp_152_;
}
v_reusejp_152_:
{
return v___x_153_;
}
}
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_addPoints_x27___boxed(lean_object* v_p1_156_, lean_object* v_p2_157_){
_start:
{
lean_object* v_res_158_; 
v_res_158_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_addPoints_x27(v_p1_156_, v_p2_157_);
lean_dec_ref(v_p1_156_);
return v_res_158_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_let__example(lean_object* v_p_159_){
_start:
{
lean_object* v_x_160_; lean_object* v_y_161_; lean_object* v___x_162_; 
v_x_160_ = lean_ctor_get(v_p_159_, 0);
v_y_161_ = lean_ctor_get(v_p_159_, 1);
v___x_162_ = lean_nat_add(v_x_160_, v_y_161_);
return v___x_162_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_let__example___boxed(lean_object* v_p_163_){
_start:
{
lean_object* v_res_164_; 
v_res_164_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_let__example(v_p_163_);
lean_dec_ref(v_p_163_);
return v_res_164_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_let__sum___closed__0(void){
_start:
{
lean_object* v___x_165_; lean_object* v___x_166_; 
v___x_165_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_p1));
v___x_166_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_let__example(v___x_165_);
return v___x_166_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_let__sum(void){
_start:
{
lean_object* v___x_167_; 
v___x_167_ = lean_obj_once(&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_let__sum___closed__0, &lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_let__sum___closed__0_once, _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_let__sum___closed__0);
return v___x_167_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_param__destruct(lean_object* v_x_168_, lean_object* v_y_169_){
_start:
{
lean_object* v___x_170_; 
v___x_170_ = lean_nat_add(v_x_168_, v_y_169_);
return v___x_170_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_param__destruct___boxed(lean_object* v_x_171_, lean_object* v_y_172_){
_start:
{
lean_object* v_res_173_; 
v_res_173_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_param__destruct(v_x_171_, v_y_172_);
lean_dec(v_y_172_);
lean_dec(v_x_171_);
return v_res_173_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_lambda__destruct(lean_object* v_x_174_){
_start:
{
lean_object* v_x_175_; lean_object* v_y_176_; lean_object* v___x_177_; 
v_x_175_ = lean_ctor_get(v_x_174_, 0);
v_y_176_ = lean_ctor_get(v_x_174_, 1);
v___x_177_ = lean_nat_add(v_x_175_, v_y_176_);
return v___x_177_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_lambda__destruct___boxed(lean_object* v_x_178_){
_start:
{
lean_object* v_res_179_; 
v_res_179_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_lambda__destruct(v_x_178_);
lean_dec_ref(v_x_178_);
return v_res_179_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_lambda__sum___closed__0(void){
_start:
{
lean_object* v___x_180_; lean_object* v___x_181_; 
v___x_180_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_p1));
v___x_181_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_lambda__destruct(v___x_180_);
return v___x_181_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_lambda__sum(void){
_start:
{
lean_object* v___x_182_; 
v___x_182_ = lean_obj_once(&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_lambda__sum___closed__0, &lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_lambda__sum___closed__0_once, _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_lambda__sum___closed__0);
return v___x_182_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_instReprColor_repr___redArg___closed__4(void){
_start:
{
lean_object* v___x_192_; lean_object* v___x_193_; 
v___x_192_ = lean_unsigned_to_nat(7u);
v___x_193_ = lean_nat_to_int(v___x_192_);
return v___x_193_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_instReprColor_repr___redArg___closed__7(void){
_start:
{
lean_object* v___x_197_; lean_object* v___x_198_; 
v___x_197_ = lean_unsigned_to_nat(9u);
v___x_198_ = lean_nat_to_int(v___x_197_);
return v___x_198_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_instReprColor_repr___redArg___closed__10(void){
_start:
{
lean_object* v___x_202_; lean_object* v___x_203_; 
v___x_202_ = lean_unsigned_to_nat(8u);
v___x_203_ = lean_nat_to_int(v___x_202_);
return v___x_203_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_instReprColor_repr___redArg(lean_object* v_x_204_){
_start:
{
lean_object* v_red_205_; lean_object* v_green_206_; lean_object* v_blue_207_; lean_object* v___x_208_; lean_object* v___x_209_; lean_object* v___x_210_; lean_object* v___x_211_; lean_object* v___x_212_; lean_object* v___x_213_; uint8_t v___x_214_; lean_object* v___x_215_; lean_object* v___x_216_; lean_object* v___x_217_; lean_object* v___x_218_; lean_object* v___x_219_; lean_object* v___x_220_; lean_object* v___x_221_; lean_object* v___x_222_; lean_object* v___x_223_; lean_object* v___x_224_; lean_object* v___x_225_; lean_object* v___x_226_; lean_object* v___x_227_; lean_object* v___x_228_; lean_object* v___x_229_; lean_object* v___x_230_; lean_object* v___x_231_; lean_object* v___x_232_; lean_object* v___x_233_; lean_object* v___x_234_; lean_object* v___x_235_; lean_object* v___x_236_; lean_object* v___x_237_; lean_object* v___x_238_; lean_object* v___x_239_; lean_object* v___x_240_; lean_object* v___x_241_; lean_object* v___x_242_; lean_object* v___x_243_; lean_object* v___x_244_; lean_object* v___x_245_; lean_object* v___x_246_; lean_object* v___x_247_; 
v_red_205_ = lean_ctor_get(v_x_204_, 0);
lean_inc(v_red_205_);
v_green_206_ = lean_ctor_get(v_x_204_, 1);
lean_inc(v_green_206_);
v_blue_207_ = lean_ctor_get(v_x_204_, 2);
lean_inc(v_blue_207_);
lean_dec_ref(v_x_204_);
v___x_208_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_instReprPoint_repr___redArg___closed__5));
v___x_209_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_instReprColor_repr___redArg___closed__3));
v___x_210_ = lean_obj_once(&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_instReprColor_repr___redArg___closed__4, &lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_instReprColor_repr___redArg___closed__4_once, _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_instReprColor_repr___redArg___closed__4);
v___x_211_ = l_Nat_reprFast(v_red_205_);
v___x_212_ = lean_alloc_ctor(3, 1, 0);
lean_ctor_set(v___x_212_, 0, v___x_211_);
v___x_213_ = lean_alloc_ctor(4, 2, 0);
lean_ctor_set(v___x_213_, 0, v___x_210_);
lean_ctor_set(v___x_213_, 1, v___x_212_);
v___x_214_ = 0;
v___x_215_ = lean_alloc_ctor(6, 1, 1);
lean_ctor_set(v___x_215_, 0, v___x_213_);
lean_ctor_set_uint8(v___x_215_, sizeof(void*)*1, v___x_214_);
v___x_216_ = lean_alloc_ctor(5, 2, 0);
lean_ctor_set(v___x_216_, 0, v___x_209_);
lean_ctor_set(v___x_216_, 1, v___x_215_);
v___x_217_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_instReprPoint_repr___redArg___closed__9));
v___x_218_ = lean_alloc_ctor(5, 2, 0);
lean_ctor_set(v___x_218_, 0, v___x_216_);
lean_ctor_set(v___x_218_, 1, v___x_217_);
v___x_219_ = lean_box(1);
v___x_220_ = lean_alloc_ctor(5, 2, 0);
lean_ctor_set(v___x_220_, 0, v___x_218_);
lean_ctor_set(v___x_220_, 1, v___x_219_);
v___x_221_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_instReprColor_repr___redArg___closed__6));
v___x_222_ = lean_alloc_ctor(5, 2, 0);
lean_ctor_set(v___x_222_, 0, v___x_220_);
lean_ctor_set(v___x_222_, 1, v___x_221_);
v___x_223_ = lean_alloc_ctor(5, 2, 0);
lean_ctor_set(v___x_223_, 0, v___x_222_);
lean_ctor_set(v___x_223_, 1, v___x_208_);
v___x_224_ = lean_obj_once(&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_instReprColor_repr___redArg___closed__7, &lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_instReprColor_repr___redArg___closed__7_once, _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_instReprColor_repr___redArg___closed__7);
v___x_225_ = l_Nat_reprFast(v_green_206_);
v___x_226_ = lean_alloc_ctor(3, 1, 0);
lean_ctor_set(v___x_226_, 0, v___x_225_);
v___x_227_ = lean_alloc_ctor(4, 2, 0);
lean_ctor_set(v___x_227_, 0, v___x_224_);
lean_ctor_set(v___x_227_, 1, v___x_226_);
v___x_228_ = lean_alloc_ctor(6, 1, 1);
lean_ctor_set(v___x_228_, 0, v___x_227_);
lean_ctor_set_uint8(v___x_228_, sizeof(void*)*1, v___x_214_);
v___x_229_ = lean_alloc_ctor(5, 2, 0);
lean_ctor_set(v___x_229_, 0, v___x_223_);
lean_ctor_set(v___x_229_, 1, v___x_228_);
v___x_230_ = lean_alloc_ctor(5, 2, 0);
lean_ctor_set(v___x_230_, 0, v___x_229_);
lean_ctor_set(v___x_230_, 1, v___x_217_);
v___x_231_ = lean_alloc_ctor(5, 2, 0);
lean_ctor_set(v___x_231_, 0, v___x_230_);
lean_ctor_set(v___x_231_, 1, v___x_219_);
v___x_232_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_instReprColor_repr___redArg___closed__9));
v___x_233_ = lean_alloc_ctor(5, 2, 0);
lean_ctor_set(v___x_233_, 0, v___x_231_);
lean_ctor_set(v___x_233_, 1, v___x_232_);
v___x_234_ = lean_alloc_ctor(5, 2, 0);
lean_ctor_set(v___x_234_, 0, v___x_233_);
lean_ctor_set(v___x_234_, 1, v___x_208_);
v___x_235_ = lean_obj_once(&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_instReprColor_repr___redArg___closed__10, &lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_instReprColor_repr___redArg___closed__10_once, _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_instReprColor_repr___redArg___closed__10);
v___x_236_ = l_Nat_reprFast(v_blue_207_);
v___x_237_ = lean_alloc_ctor(3, 1, 0);
lean_ctor_set(v___x_237_, 0, v___x_236_);
v___x_238_ = lean_alloc_ctor(4, 2, 0);
lean_ctor_set(v___x_238_, 0, v___x_235_);
lean_ctor_set(v___x_238_, 1, v___x_237_);
v___x_239_ = lean_alloc_ctor(6, 1, 1);
lean_ctor_set(v___x_239_, 0, v___x_238_);
lean_ctor_set_uint8(v___x_239_, sizeof(void*)*1, v___x_214_);
v___x_240_ = lean_alloc_ctor(5, 2, 0);
lean_ctor_set(v___x_240_, 0, v___x_234_);
lean_ctor_set(v___x_240_, 1, v___x_239_);
v___x_241_ = lean_obj_once(&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_instReprPoint_repr___redArg___closed__14, &lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_instReprPoint_repr___redArg___closed__14_once, _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_instReprPoint_repr___redArg___closed__14);
v___x_242_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_instReprPoint_repr___redArg___closed__15));
v___x_243_ = lean_alloc_ctor(5, 2, 0);
lean_ctor_set(v___x_243_, 0, v___x_242_);
lean_ctor_set(v___x_243_, 1, v___x_240_);
v___x_244_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_instReprPoint_repr___redArg___closed__16));
v___x_245_ = lean_alloc_ctor(5, 2, 0);
lean_ctor_set(v___x_245_, 0, v___x_243_);
lean_ctor_set(v___x_245_, 1, v___x_244_);
v___x_246_ = lean_alloc_ctor(4, 2, 0);
lean_ctor_set(v___x_246_, 0, v___x_241_);
lean_ctor_set(v___x_246_, 1, v___x_245_);
v___x_247_ = lean_alloc_ctor(6, 1, 1);
lean_ctor_set(v___x_247_, 0, v___x_246_);
lean_ctor_set_uint8(v___x_247_, sizeof(void*)*1, v___x_214_);
return v___x_247_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_instReprColor_repr(lean_object* v_x_248_, lean_object* v_prec_249_){
_start:
{
lean_object* v___x_250_; 
v___x_250_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_instReprColor_repr___redArg(v_x_248_);
return v___x_250_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_instReprColor_repr___boxed(lean_object* v_x_251_, lean_object* v_prec_252_){
_start:
{
lean_object* v_res_253_; 
v_res_253_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_instReprColor_repr(v_x_251_, v_prec_252_);
lean_dec(v_prec_252_);
return v_res_253_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_instReprColoredPoint_repr___redArg(lean_object* v_x_268_){
_start:
{
lean_object* v_point_269_; lean_object* v_color_270_; lean_object* v___x_272_; uint8_t v_isShared_273_; uint8_t v_isSharedCheck_302_; 
v_point_269_ = lean_ctor_get(v_x_268_, 0);
v_color_270_ = lean_ctor_get(v_x_268_, 1);
v_isSharedCheck_302_ = !lean_is_exclusive(v_x_268_);
if (v_isSharedCheck_302_ == 0)
{
v___x_272_ = v_x_268_;
v_isShared_273_ = v_isSharedCheck_302_;
goto v_resetjp_271_;
}
else
{
lean_inc(v_color_270_);
lean_inc(v_point_269_);
lean_dec(v_x_268_);
v___x_272_ = lean_box(0);
v_isShared_273_ = v_isSharedCheck_302_;
goto v_resetjp_271_;
}
v_resetjp_271_:
{
lean_object* v___x_274_; lean_object* v___x_275_; lean_object* v___x_276_; lean_object* v___x_277_; lean_object* v___x_279_; 
v___x_274_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_instReprPoint_repr___redArg___closed__5));
v___x_275_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_instReprColoredPoint_repr___redArg___closed__3));
v___x_276_ = lean_obj_once(&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_instReprColor_repr___redArg___closed__7, &lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_instReprColor_repr___redArg___closed__7_once, _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_instReprColor_repr___redArg___closed__7);
v___x_277_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_instReprPoint_repr___redArg(v_point_269_);
if (v_isShared_273_ == 0)
{
lean_ctor_set_tag(v___x_272_, 4);
lean_ctor_set(v___x_272_, 1, v___x_277_);
lean_ctor_set(v___x_272_, 0, v___x_276_);
v___x_279_ = v___x_272_;
goto v_reusejp_278_;
}
else
{
lean_object* v_reuseFailAlloc_301_; 
v_reuseFailAlloc_301_ = lean_alloc_ctor(4, 2, 0);
lean_ctor_set(v_reuseFailAlloc_301_, 0, v___x_276_);
lean_ctor_set(v_reuseFailAlloc_301_, 1, v___x_277_);
v___x_279_ = v_reuseFailAlloc_301_;
goto v_reusejp_278_;
}
v_reusejp_278_:
{
uint8_t v___x_280_; lean_object* v___x_281_; lean_object* v___x_282_; lean_object* v___x_283_; lean_object* v___x_284_; lean_object* v___x_285_; lean_object* v___x_286_; lean_object* v___x_287_; lean_object* v___x_288_; lean_object* v___x_289_; lean_object* v___x_290_; lean_object* v___x_291_; lean_object* v___x_292_; lean_object* v___x_293_; lean_object* v___x_294_; lean_object* v___x_295_; lean_object* v___x_296_; lean_object* v___x_297_; lean_object* v___x_298_; lean_object* v___x_299_; lean_object* v___x_300_; 
v___x_280_ = 0;
v___x_281_ = lean_alloc_ctor(6, 1, 1);
lean_ctor_set(v___x_281_, 0, v___x_279_);
lean_ctor_set_uint8(v___x_281_, sizeof(void*)*1, v___x_280_);
v___x_282_ = lean_alloc_ctor(5, 2, 0);
lean_ctor_set(v___x_282_, 0, v___x_275_);
lean_ctor_set(v___x_282_, 1, v___x_281_);
v___x_283_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_instReprPoint_repr___redArg___closed__9));
v___x_284_ = lean_alloc_ctor(5, 2, 0);
lean_ctor_set(v___x_284_, 0, v___x_282_);
lean_ctor_set(v___x_284_, 1, v___x_283_);
v___x_285_ = lean_box(1);
v___x_286_ = lean_alloc_ctor(5, 2, 0);
lean_ctor_set(v___x_286_, 0, v___x_284_);
lean_ctor_set(v___x_286_, 1, v___x_285_);
v___x_287_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_instReprColoredPoint_repr___redArg___closed__5));
v___x_288_ = lean_alloc_ctor(5, 2, 0);
lean_ctor_set(v___x_288_, 0, v___x_286_);
lean_ctor_set(v___x_288_, 1, v___x_287_);
v___x_289_ = lean_alloc_ctor(5, 2, 0);
lean_ctor_set(v___x_289_, 0, v___x_288_);
lean_ctor_set(v___x_289_, 1, v___x_274_);
v___x_290_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_instReprColor_repr___redArg(v_color_270_);
v___x_291_ = lean_alloc_ctor(4, 2, 0);
lean_ctor_set(v___x_291_, 0, v___x_276_);
lean_ctor_set(v___x_291_, 1, v___x_290_);
v___x_292_ = lean_alloc_ctor(6, 1, 1);
lean_ctor_set(v___x_292_, 0, v___x_291_);
lean_ctor_set_uint8(v___x_292_, sizeof(void*)*1, v___x_280_);
v___x_293_ = lean_alloc_ctor(5, 2, 0);
lean_ctor_set(v___x_293_, 0, v___x_289_);
lean_ctor_set(v___x_293_, 1, v___x_292_);
v___x_294_ = lean_obj_once(&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_instReprPoint_repr___redArg___closed__14, &lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_instReprPoint_repr___redArg___closed__14_once, _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_instReprPoint_repr___redArg___closed__14);
v___x_295_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_instReprPoint_repr___redArg___closed__15));
v___x_296_ = lean_alloc_ctor(5, 2, 0);
lean_ctor_set(v___x_296_, 0, v___x_295_);
lean_ctor_set(v___x_296_, 1, v___x_293_);
v___x_297_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_instReprPoint_repr___redArg___closed__16));
v___x_298_ = lean_alloc_ctor(5, 2, 0);
lean_ctor_set(v___x_298_, 0, v___x_296_);
lean_ctor_set(v___x_298_, 1, v___x_297_);
v___x_299_ = lean_alloc_ctor(4, 2, 0);
lean_ctor_set(v___x_299_, 0, v___x_294_);
lean_ctor_set(v___x_299_, 1, v___x_298_);
v___x_300_ = lean_alloc_ctor(6, 1, 1);
lean_ctor_set(v___x_300_, 0, v___x_299_);
lean_ctor_set_uint8(v___x_300_, sizeof(void*)*1, v___x_280_);
return v___x_300_;
}
}
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_instReprColoredPoint_repr(lean_object* v_x_303_, lean_object* v_prec_304_){
_start:
{
lean_object* v___x_305_; 
v___x_305_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_instReprColoredPoint_repr___redArg(v_x_303_);
return v___x_305_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_instReprColoredPoint_repr___boxed(lean_object* v_x_306_, lean_object* v_prec_307_){
_start:
{
lean_object* v_res_308_; 
v_res_308_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_instReprColoredPoint_repr(v_x_306_, v_prec_307_);
lean_dec(v_prec_307_);
return v_res_308_;
}
}
LEAN_EXPORT uint8_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_isRedAtOrigin(lean_object* v_cp_321_){
_start:
{
lean_object* v_point_322_; lean_object* v_color_323_; lean_object* v_x_324_; lean_object* v_y_325_; lean_object* v___x_326_; uint8_t v___x_327_; 
v_point_322_ = lean_ctor_get(v_cp_321_, 0);
v_color_323_ = lean_ctor_get(v_cp_321_, 1);
v_x_324_ = lean_ctor_get(v_point_322_, 0);
v_y_325_ = lean_ctor_get(v_point_322_, 1);
v___x_326_ = lean_unsigned_to_nat(0u);
v___x_327_ = lean_nat_dec_eq(v_x_324_, v___x_326_);
if (v___x_327_ == 0)
{
return v___x_327_;
}
else
{
uint8_t v___x_328_; 
v___x_328_ = lean_nat_dec_eq(v_y_325_, v___x_326_);
if (v___x_328_ == 0)
{
return v___x_328_;
}
else
{
lean_object* v_red_329_; lean_object* v_green_330_; lean_object* v_blue_331_; lean_object* v___x_332_; uint8_t v___x_333_; 
v_red_329_ = lean_ctor_get(v_color_323_, 0);
v_green_330_ = lean_ctor_get(v_color_323_, 1);
v_blue_331_ = lean_ctor_get(v_color_323_, 2);
v___x_332_ = lean_unsigned_to_nat(255u);
v___x_333_ = lean_nat_dec_eq(v_red_329_, v___x_332_);
if (v___x_333_ == 0)
{
return v___x_333_;
}
else
{
uint8_t v___x_334_; 
v___x_334_ = lean_nat_dec_eq(v_green_330_, v___x_326_);
if (v___x_334_ == 0)
{
return v___x_334_;
}
else
{
uint8_t v___x_335_; 
v___x_335_ = lean_nat_dec_eq(v_blue_331_, v___x_326_);
return v___x_335_;
}
}
}
}
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_isRedAtOrigin___boxed(lean_object* v_cp_336_){
_start:
{
uint8_t v_res_337_; lean_object* v_r_338_; 
v_res_337_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_isRedAtOrigin(v_cp_336_);
lean_dec_ref(v_cp_336_);
v_r_338_ = lean_box(v_res_337_);
return v_r_338_;
}
}
static uint8_t _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_check__red__origin___closed__0(void){
_start:
{
lean_object* v___x_339_; uint8_t v___x_340_; 
v___x_339_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_cp));
v___x_340_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_isRedAtOrigin(v___x_339_);
return v___x_340_;
}
}
static uint8_t _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_check__red__origin(void){
_start:
{
uint8_t v___x_341_; 
v___x_341_ = lean_uint8_once(&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_check__red__origin___closed__0, &lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_check__red__origin___closed__0_once, _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_check__red__origin___closed__0);
return v___x_341_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_getPointX(lean_object* v_cp_342_){
_start:
{
lean_object* v_point_343_; lean_object* v_x_344_; 
v_point_343_ = lean_ctor_get(v_cp_342_, 0);
v_x_344_ = lean_ctor_get(v_point_343_, 0);
lean_inc(v_x_344_);
return v_x_344_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_getPointX___boxed(lean_object* v_cp_345_){
_start:
{
lean_object* v_res_346_; 
v_res_346_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_getPointX(v_cp_345_);
lean_dec_ref(v_cp_345_);
return v_res_346_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_cp__x___closed__0(void){
_start:
{
lean_object* v___x_347_; lean_object* v___x_348_; 
v___x_347_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_cp));
v___x_348_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_getPointX(v___x_347_);
return v___x_348_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_cp__x(void){
_start:
{
lean_object* v___x_349_; 
v___x_349_ = lean_obj_once(&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_cp__x___closed__0, &lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_cp__x___closed__0_once, _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_cp__x___closed__0);
return v___x_349_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_scaleAndSum(lean_object* v_p_350_, lean_object* v_s_351_){
_start:
{
lean_object* v_x_352_; lean_object* v_y_353_; lean_object* v___x_354_; lean_object* v___x_355_; lean_object* v___x_356_; 
v_x_352_ = lean_ctor_get(v_p_350_, 0);
v_y_353_ = lean_ctor_get(v_p_350_, 1);
v___x_354_ = lean_nat_mul(v_x_352_, v_s_351_);
v___x_355_ = lean_nat_mul(v_y_353_, v_s_351_);
v___x_356_ = lean_nat_add(v___x_354_, v___x_355_);
lean_dec(v___x_355_);
lean_dec(v___x_354_);
return v___x_356_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_scaleAndSum___boxed(lean_object* v_p_357_, lean_object* v_s_358_){
_start:
{
lean_object* v_res_359_; 
v_res_359_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_scaleAndSum(v_p_357_, v_s_358_);
lean_dec(v_s_358_);
lean_dec_ref(v_p_357_);
return v_res_359_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_scaled__sum___closed__0(void){
_start:
{
lean_object* v___x_360_; lean_object* v___x_361_; lean_object* v___x_362_; 
v___x_360_ = lean_unsigned_to_nat(2u);
v___x_361_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_p1));
v___x_362_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_scaleAndSum(v___x_361_, v___x_360_);
return v___x_362_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_scaled__sum(void){
_start:
{
lean_object* v___x_363_; 
v___x_363_ = lean_obj_once(&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_scaled__sum___closed__0, &lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_scaled__sum___closed__0_once, _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_scaled__sum___closed__0);
return v___x_363_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_BinTree_ctorIdx(lean_object* v_x_364_){
_start:
{
if (lean_obj_tag(v_x_364_) == 0)
{
lean_object* v___x_365_; 
v___x_365_ = lean_unsigned_to_nat(0u);
return v___x_365_;
}
else
{
lean_object* v___x_366_; 
v___x_366_ = lean_unsigned_to_nat(1u);
return v___x_366_;
}
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_BinTree_ctorIdx___boxed(lean_object* v_x_367_){
_start:
{
lean_object* v_res_368_; 
v_res_368_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_BinTree_ctorIdx(v_x_367_);
lean_dec(v_x_367_);
return v_res_368_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_BinTree_ctorElim___redArg(lean_object* v_t_369_, lean_object* v_k_370_){
_start:
{
if (lean_obj_tag(v_t_369_) == 0)
{
return v_k_370_;
}
else
{
lean_object* v_value_371_; lean_object* v_left_372_; lean_object* v_right_373_; lean_object* v___x_374_; 
v_value_371_ = lean_ctor_get(v_t_369_, 0);
lean_inc(v_value_371_);
v_left_372_ = lean_ctor_get(v_t_369_, 1);
lean_inc(v_left_372_);
v_right_373_ = lean_ctor_get(v_t_369_, 2);
lean_inc(v_right_373_);
lean_dec_ref_known(v_t_369_, 3);
v___x_374_ = lean_apply_3(v_k_370_, v_value_371_, v_left_372_, v_right_373_);
return v___x_374_;
}
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_BinTree_ctorElim(lean_object* v_motive_375_, lean_object* v_ctorIdx_376_, lean_object* v_t_377_, lean_object* v_h_378_, lean_object* v_k_379_){
_start:
{
lean_object* v___x_380_; 
v___x_380_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_BinTree_ctorElim___redArg(v_t_377_, v_k_379_);
return v___x_380_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_BinTree_ctorElim___boxed(lean_object* v_motive_381_, lean_object* v_ctorIdx_382_, lean_object* v_t_383_, lean_object* v_h_384_, lean_object* v_k_385_){
_start:
{
lean_object* v_res_386_; 
v_res_386_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_BinTree_ctorElim(v_motive_381_, v_ctorIdx_382_, v_t_383_, v_h_384_, v_k_385_);
lean_dec(v_ctorIdx_382_);
return v_res_386_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_BinTree_leaf_elim___redArg(lean_object* v_t_387_, lean_object* v_leaf_388_){
_start:
{
lean_object* v___x_389_; 
v___x_389_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_BinTree_ctorElim___redArg(v_t_387_, v_leaf_388_);
return v___x_389_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_BinTree_leaf_elim(lean_object* v_motive_390_, lean_object* v_t_391_, lean_object* v_h_392_, lean_object* v_leaf_393_){
_start:
{
lean_object* v___x_394_; 
v___x_394_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_BinTree_ctorElim___redArg(v_t_391_, v_leaf_393_);
return v___x_394_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_BinTree_node_elim___redArg(lean_object* v_t_395_, lean_object* v_node_396_){
_start:
{
lean_object* v___x_397_; 
v___x_397_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_BinTree_ctorElim___redArg(v_t_395_, v_node_396_);
return v___x_397_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_BinTree_node_elim(lean_object* v_motive_398_, lean_object* v_t_399_, lean_object* v_h_400_, lean_object* v_node_401_){
_start:
{
lean_object* v___x_402_; 
v___x_402_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_BinTree_ctorElim___redArg(v_t_399_, v_node_401_);
return v___x_402_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_instReprBinTree_repr___closed__2(void){
_start:
{
lean_object* v___x_406_; lean_object* v___x_407_; 
v___x_406_ = lean_unsigned_to_nat(2u);
v___x_407_ = lean_nat_to_int(v___x_406_);
return v___x_407_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_instReprBinTree_repr___closed__3(void){
_start:
{
lean_object* v___x_408_; lean_object* v___x_409_; 
v___x_408_ = lean_unsigned_to_nat(1u);
v___x_409_ = lean_nat_to_int(v___x_408_);
return v___x_409_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_instReprBinTree_repr(lean_object* v_x_416_, lean_object* v_prec_417_){
_start:
{
lean_object* v___y_419_; 
if (lean_obj_tag(v_x_416_) == 0)
{
lean_object* v___x_425_; uint8_t v___x_426_; 
v___x_425_ = lean_unsigned_to_nat(1024u);
v___x_426_ = lean_nat_dec_le(v___x_425_, v_prec_417_);
if (v___x_426_ == 0)
{
lean_object* v___x_427_; 
v___x_427_ = lean_obj_once(&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_instReprBinTree_repr___closed__2, &lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_instReprBinTree_repr___closed__2_once, _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_instReprBinTree_repr___closed__2);
v___y_419_ = v___x_427_;
goto v___jp_418_;
}
else
{
lean_object* v___x_428_; 
v___x_428_ = lean_obj_once(&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_instReprBinTree_repr___closed__3, &lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_instReprBinTree_repr___closed__3_once, _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_instReprBinTree_repr___closed__3);
v___y_419_ = v___x_428_;
goto v___jp_418_;
}
}
else
{
lean_object* v_value_429_; lean_object* v_left_430_; lean_object* v_right_431_; lean_object* v___x_432_; lean_object* v___y_434_; uint8_t v___x_450_; 
v_value_429_ = lean_ctor_get(v_x_416_, 0);
lean_inc(v_value_429_);
v_left_430_ = lean_ctor_get(v_x_416_, 1);
lean_inc(v_left_430_);
v_right_431_ = lean_ctor_get(v_x_416_, 2);
lean_inc(v_right_431_);
lean_dec_ref_known(v_x_416_, 3);
v___x_432_ = lean_unsigned_to_nat(1024u);
v___x_450_ = lean_nat_dec_le(v___x_432_, v_prec_417_);
if (v___x_450_ == 0)
{
lean_object* v___x_451_; 
v___x_451_ = lean_obj_once(&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_instReprBinTree_repr___closed__2, &lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_instReprBinTree_repr___closed__2_once, _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_instReprBinTree_repr___closed__2);
v___y_434_ = v___x_451_;
goto v___jp_433_;
}
else
{
lean_object* v___x_452_; 
v___x_452_ = lean_obj_once(&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_instReprBinTree_repr___closed__3, &lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_instReprBinTree_repr___closed__3_once, _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_instReprBinTree_repr___closed__3);
v___y_434_ = v___x_452_;
goto v___jp_433_;
}
v___jp_433_:
{
lean_object* v___x_435_; lean_object* v___x_436_; lean_object* v___x_437_; lean_object* v___x_438_; lean_object* v___x_439_; lean_object* v___x_440_; lean_object* v___x_441_; lean_object* v___x_442_; lean_object* v___x_443_; lean_object* v___x_444_; lean_object* v___x_445_; lean_object* v___x_446_; uint8_t v___x_447_; lean_object* v___x_448_; lean_object* v___x_449_; 
v___x_435_ = lean_box(1);
v___x_436_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_instReprBinTree_repr___closed__6));
v___x_437_ = l_Nat_reprFast(v_value_429_);
v___x_438_ = lean_alloc_ctor(3, 1, 0);
lean_ctor_set(v___x_438_, 0, v___x_437_);
v___x_439_ = lean_alloc_ctor(5, 2, 0);
lean_ctor_set(v___x_439_, 0, v___x_436_);
lean_ctor_set(v___x_439_, 1, v___x_438_);
v___x_440_ = lean_alloc_ctor(5, 2, 0);
lean_ctor_set(v___x_440_, 0, v___x_439_);
lean_ctor_set(v___x_440_, 1, v___x_435_);
v___x_441_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_instReprBinTree_repr(v_left_430_, v___x_432_);
v___x_442_ = lean_alloc_ctor(5, 2, 0);
lean_ctor_set(v___x_442_, 0, v___x_440_);
lean_ctor_set(v___x_442_, 1, v___x_441_);
v___x_443_ = lean_alloc_ctor(5, 2, 0);
lean_ctor_set(v___x_443_, 0, v___x_442_);
lean_ctor_set(v___x_443_, 1, v___x_435_);
v___x_444_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_instReprBinTree_repr(v_right_431_, v___x_432_);
v___x_445_ = lean_alloc_ctor(5, 2, 0);
lean_ctor_set(v___x_445_, 0, v___x_443_);
lean_ctor_set(v___x_445_, 1, v___x_444_);
lean_inc(v___y_434_);
v___x_446_ = lean_alloc_ctor(4, 2, 0);
lean_ctor_set(v___x_446_, 0, v___y_434_);
lean_ctor_set(v___x_446_, 1, v___x_445_);
v___x_447_ = 0;
v___x_448_ = lean_alloc_ctor(6, 1, 1);
lean_ctor_set(v___x_448_, 0, v___x_446_);
lean_ctor_set_uint8(v___x_448_, sizeof(void*)*1, v___x_447_);
v___x_449_ = l_Repr_addAppParen(v___x_448_, v_prec_417_);
return v___x_449_;
}
}
v___jp_418_:
{
lean_object* v___x_420_; lean_object* v___x_421_; uint8_t v___x_422_; lean_object* v___x_423_; lean_object* v___x_424_; 
v___x_420_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_instReprBinTree_repr___closed__1));
lean_inc(v___y_419_);
v___x_421_ = lean_alloc_ctor(4, 2, 0);
lean_ctor_set(v___x_421_, 0, v___y_419_);
lean_ctor_set(v___x_421_, 1, v___x_420_);
v___x_422_ = 0;
v___x_423_ = lean_alloc_ctor(6, 1, 1);
lean_ctor_set(v___x_423_, 0, v___x_421_);
lean_ctor_set_uint8(v___x_423_, sizeof(void*)*1, v___x_422_);
v___x_424_ = l_Repr_addAppParen(v___x_423_, v_prec_417_);
return v___x_424_;
}
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_instReprBinTree_repr___boxed(lean_object* v_x_453_, lean_object* v_prec_454_){
_start:
{
lean_object* v_res_455_; 
v_res_455_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_instReprBinTree_repr(v_x_453_, v_prec_454_);
lean_dec(v_prec_454_);
return v_res_455_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_treeSum(lean_object* v_x_458_){
_start:
{
if (lean_obj_tag(v_x_458_) == 0)
{
lean_object* v___x_459_; 
v___x_459_ = lean_unsigned_to_nat(0u);
return v___x_459_;
}
else
{
lean_object* v_value_460_; lean_object* v_left_461_; lean_object* v_right_462_; lean_object* v___x_463_; lean_object* v___x_464_; lean_object* v___x_465_; lean_object* v___x_466_; 
v_value_460_ = lean_ctor_get(v_x_458_, 0);
v_left_461_ = lean_ctor_get(v_x_458_, 1);
v_right_462_ = lean_ctor_get(v_x_458_, 2);
v___x_463_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_treeSum(v_left_461_);
v___x_464_ = lean_nat_add(v_value_460_, v___x_463_);
lean_dec(v___x_463_);
v___x_465_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_treeSum(v_right_462_);
v___x_466_ = lean_nat_add(v___x_464_, v___x_465_);
lean_dec(v___x_465_);
lean_dec(v___x_464_);
return v___x_466_;
}
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_treeSum___boxed(lean_object* v_x_467_){
_start:
{
lean_object* v_res_468_; 
v_res_468_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_treeSum(v_x_467_);
lean_dec(v_x_467_);
return v_res_468_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_leafCount(lean_object* v_x_469_){
_start:
{
if (lean_obj_tag(v_x_469_) == 0)
{
lean_object* v___x_470_; 
v___x_470_ = lean_unsigned_to_nat(1u);
return v___x_470_;
}
else
{
lean_object* v_left_471_; lean_object* v_right_472_; lean_object* v___x_473_; lean_object* v___x_474_; lean_object* v___x_475_; 
v_left_471_ = lean_ctor_get(v_x_469_, 1);
v_right_472_ = lean_ctor_get(v_x_469_, 2);
v___x_473_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_leafCount(v_left_471_);
v___x_474_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_leafCount(v_right_472_);
v___x_475_ = lean_nat_add(v___x_473_, v___x_474_);
lean_dec(v___x_474_);
lean_dec(v___x_473_);
return v___x_475_;
}
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_leafCount___boxed(lean_object* v_x_476_){
_start:
{
lean_object* v_res_477_; 
v_res_477_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_leafCount(v_x_476_);
lean_dec(v_x_476_);
return v_res_477_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_treeHeight(lean_object* v_x_478_){
_start:
{
if (lean_obj_tag(v_x_478_) == 0)
{
lean_object* v___x_479_; 
v___x_479_ = lean_unsigned_to_nat(0u);
return v___x_479_;
}
else
{
lean_object* v_left_480_; lean_object* v_right_481_; lean_object* v___x_482_; lean_object* v___x_483_; lean_object* v___x_484_; uint8_t v___x_485_; 
v_left_480_ = lean_ctor_get(v_x_478_, 1);
v_right_481_ = lean_ctor_get(v_x_478_, 2);
v___x_482_ = lean_unsigned_to_nat(1u);
v___x_483_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_treeHeight(v_left_480_);
v___x_484_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_treeHeight(v_right_481_);
v___x_485_ = lean_nat_dec_le(v___x_483_, v___x_484_);
if (v___x_485_ == 0)
{
lean_object* v___x_486_; 
lean_dec(v___x_484_);
v___x_486_ = lean_nat_add(v___x_482_, v___x_483_);
lean_dec(v___x_483_);
return v___x_486_;
}
else
{
lean_object* v___x_487_; 
lean_dec(v___x_483_);
v___x_487_ = lean_nat_add(v___x_482_, v___x_484_);
lean_dec(v___x_484_);
return v___x_487_;
}
}
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_treeHeight___boxed(lean_object* v_x_488_){
_start:
{
lean_object* v_res_489_; 
v_res_489_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_treeHeight(v_x_488_);
lean_dec(v_x_488_);
return v_res_489_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_tree__sum___closed__0(void){
_start:
{
lean_object* v___x_505_; lean_object* v___x_506_; 
v___x_505_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_example__tree));
v___x_506_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_treeSum(v___x_505_);
return v___x_506_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_tree__sum(void){
_start:
{
lean_object* v___x_507_; 
v___x_507_ = lean_obj_once(&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_tree__sum___closed__0, &lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_tree__sum___closed__0_once, _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_tree__sum___closed__0);
return v___x_507_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_tree__leaves___closed__0(void){
_start:
{
lean_object* v___x_508_; lean_object* v___x_509_; 
v___x_508_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_example__tree));
v___x_509_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_leafCount(v___x_508_);
return v___x_509_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_tree__leaves(void){
_start:
{
lean_object* v___x_510_; 
v___x_510_ = lean_obj_once(&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_tree__leaves___closed__0, &lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_tree__leaves___closed__0_once, _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_tree__leaves___closed__0);
return v___x_510_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_tree__height___closed__0(void){
_start:
{
lean_object* v___x_511_; lean_object* v___x_512_; 
v___x_511_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_example__tree));
v___x_512_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_treeHeight(v___x_511_);
return v___x_512_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_tree__height(void){
_start:
{
lean_object* v___x_513_; 
v___x_513_ = lean_obj_once(&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_tree__height___closed__0, &lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_tree__height___closed__0_once, _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_tree__height___closed__0);
return v___x_513_;
}
}
LEAN_EXPORT uint8_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_pointCompare(lean_object* v_x_514_, lean_object* v_x_515_){
_start:
{
lean_object* v_x_516_; lean_object* v_x_517_; uint8_t v___x_518_; 
v_x_516_ = lean_ctor_get(v_x_514_, 0);
v_x_517_ = lean_ctor_get(v_x_515_, 0);
v___x_518_ = lean_nat_dec_lt(v_x_516_, v_x_517_);
if (v___x_518_ == 0)
{
uint8_t v___x_519_; 
v___x_519_ = lean_nat_dec_lt(v_x_517_, v_x_516_);
if (v___x_519_ == 0)
{
uint8_t v___x_520_; 
v___x_520_ = 1;
return v___x_520_;
}
else
{
uint8_t v___x_521_; 
v___x_521_ = 2;
return v___x_521_;
}
}
else
{
uint8_t v___x_522_; 
v___x_522_ = 0;
return v___x_522_;
}
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_pointCompare___boxed(lean_object* v_x_523_, lean_object* v_x_524_){
_start:
{
uint8_t v_res_525_; lean_object* v_r_526_; 
v_res_525_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_pointCompare(v_x_523_, v_x_524_);
lean_dec_ref(v_x_524_);
lean_dec_ref(v_x_523_);
v_r_526_ = lean_box(v_res_525_);
return v_r_526_;
}
}
LEAN_EXPORT uint8_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_pointCompareFull(lean_object* v_x_527_, lean_object* v_x_528_){
_start:
{
lean_object* v_x_529_; lean_object* v_y_530_; lean_object* v_x_531_; lean_object* v_y_532_; uint8_t v___x_533_; 
v_x_529_ = lean_ctor_get(v_x_527_, 0);
v_y_530_ = lean_ctor_get(v_x_527_, 1);
v_x_531_ = lean_ctor_get(v_x_528_, 0);
v_y_532_ = lean_ctor_get(v_x_528_, 1);
v___x_533_ = lean_nat_dec_lt(v_x_529_, v_x_531_);
if (v___x_533_ == 0)
{
uint8_t v___x_534_; 
v___x_534_ = lean_nat_dec_eq(v_x_529_, v_x_531_);
if (v___x_534_ == 0)
{
uint8_t v___x_535_; 
v___x_535_ = 2;
return v___x_535_;
}
else
{
uint8_t v___x_536_; 
v___x_536_ = lean_nat_dec_lt(v_y_530_, v_y_532_);
if (v___x_536_ == 0)
{
uint8_t v___x_537_; 
v___x_537_ = lean_nat_dec_eq(v_y_530_, v_y_532_);
if (v___x_537_ == 0)
{
uint8_t v___x_538_; 
v___x_538_ = 2;
return v___x_538_;
}
else
{
uint8_t v___x_539_; 
v___x_539_ = 1;
return v___x_539_;
}
}
else
{
uint8_t v___x_540_; 
v___x_540_ = 0;
return v___x_540_;
}
}
}
else
{
uint8_t v___x_541_; 
v___x_541_ = 0;
return v___x_541_;
}
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_pointCompareFull___boxed(lean_object* v_x_542_, lean_object* v_x_543_){
_start:
{
uint8_t v_res_544_; lean_object* v_r_545_; 
v_res_544_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_pointCompareFull(v_x_542_, v_x_543_);
lean_dec_ref(v_x_543_);
lean_dec_ref(v_x_542_);
v_r_545_ = lean_box(v_res_544_);
return v_r_545_;
}
}
static uint8_t _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_cmp1___closed__2(void){
_start:
{
lean_object* v___x_552_; lean_object* v___x_553_; uint8_t v___x_554_; 
v___x_552_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_cmp1___closed__1));
v___x_553_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_cmp1___closed__0));
v___x_554_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_pointCompareFull(v___x_553_, v___x_552_);
return v___x_554_;
}
}
static uint8_t _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_cmp1(void){
_start:
{
uint8_t v___x_555_; 
v___x_555_ = lean_uint8_once(&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_cmp1___closed__2, &lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_cmp1___closed__2_once, _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_cmp1___closed__2);
return v___x_555_;
}
}
static uint8_t _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_cmp2___closed__1(void){
_start:
{
lean_object* v___x_559_; lean_object* v___x_560_; uint8_t v___x_561_; 
v___x_559_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_cmp2___closed__0));
v___x_560_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_cmp1___closed__0));
v___x_561_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_pointCompareFull(v___x_560_, v___x_559_);
return v___x_561_;
}
}
static uint8_t _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_cmp2(void){
_start:
{
uint8_t v___x_562_; 
v___x_562_ = lean_uint8_once(&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_cmp2___closed__1, &lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_cmp2___closed__1_once, _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_cmp2___closed__1);
return v___x_562_;
}
}
LEAN_EXPORT uint8_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_inFirstQuadrant(lean_object* v_x_563_){
_start:
{
lean_object* v_x_564_; lean_object* v_y_565_; lean_object* v___x_566_; uint8_t v___x_567_; 
v_x_564_ = lean_ctor_get(v_x_563_, 0);
v_y_565_ = lean_ctor_get(v_x_563_, 1);
v___x_566_ = lean_unsigned_to_nat(0u);
v___x_567_ = lean_nat_dec_lt(v___x_566_, v_x_564_);
if (v___x_567_ == 0)
{
return v___x_567_;
}
else
{
uint8_t v___x_568_; 
v___x_568_ = lean_nat_dec_lt(v___x_566_, v_y_565_);
return v___x_568_;
}
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_inFirstQuadrant___boxed(lean_object* v_x_569_){
_start:
{
uint8_t v_res_570_; lean_object* v_r_571_; 
v_res_570_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_inFirstQuadrant(v_x_569_);
lean_dec_ref(v_x_569_);
v_r_571_ = lean_box(v_res_570_);
return v_r_571_;
}
}
LEAN_EXPORT uint8_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_inFirstQuadrant_x27(lean_object* v_p_572_){
_start:
{
lean_object* v_x_573_; lean_object* v_y_574_; lean_object* v___x_575_; uint8_t v___x_576_; 
v_x_573_ = lean_ctor_get(v_p_572_, 0);
v_y_574_ = lean_ctor_get(v_p_572_, 1);
v___x_575_ = lean_unsigned_to_nat(0u);
v___x_576_ = lean_nat_dec_lt(v___x_575_, v_x_573_);
if (v___x_576_ == 0)
{
return v___x_576_;
}
else
{
uint8_t v___x_577_; 
v___x_577_ = lean_nat_dec_lt(v___x_575_, v_y_574_);
return v___x_577_;
}
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_inFirstQuadrant_x27___boxed(lean_object* v_p_578_){
_start:
{
uint8_t v_res_579_; lean_object* v_r_580_; 
v_res_579_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_inFirstQuadrant_x27(v_p_578_);
lean_dec_ref(v_p_578_);
v_r_580_ = lean_box(v_res_579_);
return v_r_580_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_quadrant(lean_object* v_x_588_){
_start:
{
lean_object* v_x_589_; lean_object* v_y_590_; lean_object* v___x_591_; uint8_t v___x_592_; 
v_x_589_ = lean_ctor_get(v_x_588_, 0);
v_y_590_ = lean_ctor_get(v_x_588_, 1);
v___x_591_ = lean_unsigned_to_nat(0u);
v___x_592_ = lean_nat_dec_eq(v_x_589_, v___x_591_);
if (v___x_592_ == 0)
{
uint8_t v___x_593_; 
v___x_593_ = lean_nat_dec_eq(v_y_590_, v___x_591_);
if (v___x_593_ == 0)
{
uint8_t v___x_594_; 
v___x_594_ = lean_nat_dec_lt(v___x_591_, v_x_589_);
if (v___x_594_ == 0)
{
uint8_t v___x_595_; 
v___x_595_ = lean_nat_dec_lt(v___x_591_, v_y_590_);
if (v___x_595_ == 0)
{
lean_object* v___x_596_; 
v___x_596_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_quadrant___closed__0));
return v___x_596_;
}
else
{
lean_object* v___x_597_; 
v___x_597_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_quadrant___closed__1));
return v___x_597_;
}
}
else
{
uint8_t v___x_598_; 
v___x_598_ = lean_nat_dec_lt(v___x_591_, v_y_590_);
if (v___x_598_ == 0)
{
lean_object* v___x_599_; 
v___x_599_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_quadrant___closed__2));
return v___x_599_;
}
else
{
lean_object* v___x_600_; 
v___x_600_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_quadrant___closed__3));
return v___x_600_;
}
}
}
else
{
lean_object* v___x_601_; 
v___x_601_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_quadrant___closed__4));
return v___x_601_;
}
}
else
{
uint8_t v___x_602_; 
v___x_602_ = lean_nat_dec_eq(v_y_590_, v___x_591_);
if (v___x_602_ == 0)
{
lean_object* v___x_603_; 
v___x_603_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_quadrant___closed__5));
return v___x_603_;
}
else
{
lean_object* v___x_604_; 
v___x_604_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_quadrant___closed__6));
return v___x_604_;
}
}
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_quadrant___boxed(lean_object* v_x_605_){
_start:
{
lean_object* v_res_606_; 
v_res_606_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_quadrant(v_x_605_);
lean_dec_ref(v_x_605_);
return v_res_606_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_q1___closed__0(void){
_start:
{
lean_object* v___x_607_; lean_object* v___x_608_; 
v___x_607_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_p1___closed__0));
v___x_608_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_quadrant(v___x_607_);
return v___x_608_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_q1(void){
_start:
{
lean_object* v___x_609_; 
v___x_609_ = lean_obj_once(&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_q1___closed__0, &lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_q1___closed__0_once, _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_q1___closed__0);
return v___x_609_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_q0___closed__1(void){
_start:
{
lean_object* v___x_612_; lean_object* v___x_613_; 
v___x_612_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_q0___closed__0));
v___x_613_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_quadrant(v___x_612_);
return v___x_613_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_q0(void){
_start:
{
lean_object* v___x_614_; 
v___x_614_ = lean_obj_once(&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_q0___closed__1, &lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_q0___closed__1_once, _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_q0___closed__1);
return v___x_614_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_sumXs(lean_object* v_x_628_){
_start:
{
if (lean_obj_tag(v_x_628_) == 0)
{
lean_object* v___x_629_; 
v___x_629_ = lean_unsigned_to_nat(0u);
return v___x_629_;
}
else
{
lean_object* v_head_630_; lean_object* v_tail_631_; lean_object* v_x_632_; lean_object* v___x_633_; lean_object* v___x_634_; 
v_head_630_ = lean_ctor_get(v_x_628_, 0);
v_tail_631_ = lean_ctor_get(v_x_628_, 1);
v_x_632_ = lean_ctor_get(v_head_630_, 0);
v___x_633_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_sumXs(v_tail_631_);
v___x_634_ = lean_nat_add(v_x_632_, v___x_633_);
lean_dec(v___x_633_);
return v___x_634_;
}
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_sumXs___boxed(lean_object* v_x_635_){
_start:
{
lean_object* v_res_636_; 
v_res_636_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_sumXs(v_x_635_);
lean_dec(v_x_635_);
return v_res_636_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_sum__xs___closed__0(void){
_start:
{
lean_object* v___x_637_; lean_object* v___x_638_; 
v___x_637_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_points));
v___x_638_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_sumXs(v___x_637_);
return v___x_638_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_sum__xs(void){
_start:
{
lean_object* v___x_639_; 
v___x_639_ = lean_obj_once(&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_sum__xs___closed__0, &lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_sum__xs___closed__0_once, _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_sum__xs___closed__0);
return v___x_639_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_findYGT5(lean_object* v_x_640_){
_start:
{
if (lean_obj_tag(v_x_640_) == 0)
{
lean_object* v___x_641_; 
v___x_641_ = lean_box(0);
return v___x_641_;
}
else
{
lean_object* v_head_642_; lean_object* v_tail_643_; lean_object* v_y_644_; lean_object* v___x_645_; uint8_t v___x_646_; 
v_head_642_ = lean_ctor_get(v_x_640_, 0);
v_tail_643_ = lean_ctor_get(v_x_640_, 1);
v_y_644_ = lean_ctor_get(v_head_642_, 1);
v___x_645_ = lean_unsigned_to_nat(5u);
v___x_646_ = lean_nat_dec_lt(v___x_645_, v_y_644_);
if (v___x_646_ == 0)
{
v_x_640_ = v_tail_643_;
goto _start;
}
else
{
lean_object* v___x_648_; 
lean_inc(v_head_642_);
v___x_648_ = lean_alloc_ctor(1, 1, 0);
lean_ctor_set(v___x_648_, 0, v_head_642_);
return v___x_648_;
}
}
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_findYGT5___boxed(lean_object* v_x_649_){
_start:
{
lean_object* v_res_650_; 
v_res_650_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_findYGT5(v_x_649_);
lean_dec(v_x_649_);
return v_res_650_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_found___closed__0(void){
_start:
{
lean_object* v___x_651_; lean_object* v___x_652_; 
v___x_651_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_points));
v___x_652_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_findYGT5(v___x_651_);
return v___x_652_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_found(void){
_start:
{
lean_object* v___x_653_; 
v___x_653_ = lean_obj_once(&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_found___closed__0, &lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_found___closed__0_once, _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_found___closed__0);
return v___x_653_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial___private_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_0__Lean4Tutorial_Examples_Structures_PatternMatchingStruct_distSq_match__1_splitter___redArg(lean_object* v_p_654_, lean_object* v_h__1_655_){
_start:
{
lean_object* v_x_656_; lean_object* v_y_657_; lean_object* v___x_658_; 
v_x_656_ = lean_ctor_get(v_p_654_, 0);
lean_inc(v_x_656_);
v_y_657_ = lean_ctor_get(v_p_654_, 1);
lean_inc(v_y_657_);
lean_dec_ref(v_p_654_);
v___x_658_ = lean_apply_2(v_h__1_655_, v_x_656_, v_y_657_);
return v___x_658_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial___private_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_0__Lean4Tutorial_Examples_Structures_PatternMatchingStruct_distSq_match__1_splitter(lean_object* v_motive_659_, lean_object* v_p_660_, lean_object* v_h__1_661_){
_start:
{
lean_object* v_x_662_; lean_object* v_y_663_; lean_object* v___x_664_; 
v_x_662_ = lean_ctor_get(v_p_660_, 0);
lean_inc(v_x_662_);
v_y_663_ = lean_ctor_get(v_p_660_, 1);
lean_inc(v_y_663_);
lean_dec_ref(v_p_660_);
v___x_664_ = lean_apply_2(v_h__1_661_, v_x_662_, v_y_663_);
return v___x_664_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_getX_x27(lean_object* v_p_665_){
_start:
{
lean_object* v_x_666_; 
v_x_666_ = lean_ctor_get(v_p_665_, 0);
lean_inc(v_x_666_);
return v_x_666_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_getX_x27___boxed(lean_object* v_p_667_){
_start:
{
lean_object* v_res_668_; 
v_res_668_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_getX_x27(v_p_667_);
lean_dec_ref(v_p_667_);
return v_res_668_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_getY_x27(lean_object* v_p_669_){
_start:
{
lean_object* v_y_670_; 
v_y_670_ = lean_ctor_get(v_p_669_, 1);
lean_inc(v_y_670_);
return v_y_670_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_getY_x27___boxed(lean_object* v_p_671_){
_start:
{
lean_object* v_res_672_; 
v_res_672_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_getY_x27(v_p_671_);
lean_dec_ref(v_p_671_);
return v_res_672_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_instReprBigStruct_repr___redArg(lean_object* v_x_694_){
_start:
{
lean_object* v_a_695_; lean_object* v_b_696_; lean_object* v_c_697_; lean_object* v_d_698_; lean_object* v_e_699_; lean_object* v___x_700_; lean_object* v___x_701_; lean_object* v___x_702_; lean_object* v___x_703_; lean_object* v___x_704_; lean_object* v___x_705_; uint8_t v___x_706_; lean_object* v___x_707_; lean_object* v___x_708_; lean_object* v___x_709_; lean_object* v___x_710_; lean_object* v___x_711_; lean_object* v___x_712_; lean_object* v___x_713_; lean_object* v___x_714_; lean_object* v___x_715_; lean_object* v___x_716_; lean_object* v___x_717_; lean_object* v___x_718_; lean_object* v___x_719_; lean_object* v___x_720_; lean_object* v___x_721_; lean_object* v___x_722_; lean_object* v___x_723_; lean_object* v___x_724_; lean_object* v___x_725_; lean_object* v___x_726_; lean_object* v___x_727_; lean_object* v___x_728_; lean_object* v___x_729_; lean_object* v___x_730_; lean_object* v___x_731_; lean_object* v___x_732_; lean_object* v___x_733_; lean_object* v___x_734_; lean_object* v___x_735_; lean_object* v___x_736_; lean_object* v___x_737_; lean_object* v___x_738_; lean_object* v___x_739_; lean_object* v___x_740_; lean_object* v___x_741_; lean_object* v___x_742_; lean_object* v___x_743_; lean_object* v___x_744_; lean_object* v___x_745_; lean_object* v___x_746_; lean_object* v___x_747_; lean_object* v___x_748_; lean_object* v___x_749_; lean_object* v___x_750_; lean_object* v___x_751_; lean_object* v___x_752_; lean_object* v___x_753_; lean_object* v___x_754_; lean_object* v___x_755_; lean_object* v___x_756_; lean_object* v___x_757_; 
v_a_695_ = lean_ctor_get(v_x_694_, 0);
lean_inc(v_a_695_);
v_b_696_ = lean_ctor_get(v_x_694_, 1);
lean_inc(v_b_696_);
v_c_697_ = lean_ctor_get(v_x_694_, 2);
lean_inc(v_c_697_);
v_d_698_ = lean_ctor_get(v_x_694_, 3);
lean_inc(v_d_698_);
v_e_699_ = lean_ctor_get(v_x_694_, 4);
lean_inc(v_e_699_);
lean_dec_ref(v_x_694_);
v___x_700_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_instReprPoint_repr___redArg___closed__5));
v___x_701_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_instReprBigStruct_repr___redArg___closed__3));
v___x_702_ = lean_obj_once(&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_instReprPoint_repr___redArg___closed__7, &lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_instReprPoint_repr___redArg___closed__7_once, _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_instReprPoint_repr___redArg___closed__7);
v___x_703_ = l_Nat_reprFast(v_a_695_);
v___x_704_ = lean_alloc_ctor(3, 1, 0);
lean_ctor_set(v___x_704_, 0, v___x_703_);
v___x_705_ = lean_alloc_ctor(4, 2, 0);
lean_ctor_set(v___x_705_, 0, v___x_702_);
lean_ctor_set(v___x_705_, 1, v___x_704_);
v___x_706_ = 0;
v___x_707_ = lean_alloc_ctor(6, 1, 1);
lean_ctor_set(v___x_707_, 0, v___x_705_);
lean_ctor_set_uint8(v___x_707_, sizeof(void*)*1, v___x_706_);
v___x_708_ = lean_alloc_ctor(5, 2, 0);
lean_ctor_set(v___x_708_, 0, v___x_701_);
lean_ctor_set(v___x_708_, 1, v___x_707_);
v___x_709_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_instReprPoint_repr___redArg___closed__9));
v___x_710_ = lean_alloc_ctor(5, 2, 0);
lean_ctor_set(v___x_710_, 0, v___x_708_);
lean_ctor_set(v___x_710_, 1, v___x_709_);
v___x_711_ = lean_box(1);
v___x_712_ = lean_alloc_ctor(5, 2, 0);
lean_ctor_set(v___x_712_, 0, v___x_710_);
lean_ctor_set(v___x_712_, 1, v___x_711_);
v___x_713_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_instReprBigStruct_repr___redArg___closed__5));
v___x_714_ = lean_alloc_ctor(5, 2, 0);
lean_ctor_set(v___x_714_, 0, v___x_712_);
lean_ctor_set(v___x_714_, 1, v___x_713_);
v___x_715_ = lean_alloc_ctor(5, 2, 0);
lean_ctor_set(v___x_715_, 0, v___x_714_);
lean_ctor_set(v___x_715_, 1, v___x_700_);
v___x_716_ = l_Nat_reprFast(v_b_696_);
v___x_717_ = lean_alloc_ctor(3, 1, 0);
lean_ctor_set(v___x_717_, 0, v___x_716_);
v___x_718_ = lean_alloc_ctor(4, 2, 0);
lean_ctor_set(v___x_718_, 0, v___x_702_);
lean_ctor_set(v___x_718_, 1, v___x_717_);
v___x_719_ = lean_alloc_ctor(6, 1, 1);
lean_ctor_set(v___x_719_, 0, v___x_718_);
lean_ctor_set_uint8(v___x_719_, sizeof(void*)*1, v___x_706_);
v___x_720_ = lean_alloc_ctor(5, 2, 0);
lean_ctor_set(v___x_720_, 0, v___x_715_);
lean_ctor_set(v___x_720_, 1, v___x_719_);
v___x_721_ = lean_alloc_ctor(5, 2, 0);
lean_ctor_set(v___x_721_, 0, v___x_720_);
lean_ctor_set(v___x_721_, 1, v___x_709_);
v___x_722_ = lean_alloc_ctor(5, 2, 0);
lean_ctor_set(v___x_722_, 0, v___x_721_);
lean_ctor_set(v___x_722_, 1, v___x_711_);
v___x_723_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_instReprBigStruct_repr___redArg___closed__7));
v___x_724_ = lean_alloc_ctor(5, 2, 0);
lean_ctor_set(v___x_724_, 0, v___x_722_);
lean_ctor_set(v___x_724_, 1, v___x_723_);
v___x_725_ = lean_alloc_ctor(5, 2, 0);
lean_ctor_set(v___x_725_, 0, v___x_724_);
lean_ctor_set(v___x_725_, 1, v___x_700_);
v___x_726_ = l_Nat_reprFast(v_c_697_);
v___x_727_ = lean_alloc_ctor(3, 1, 0);
lean_ctor_set(v___x_727_, 0, v___x_726_);
v___x_728_ = lean_alloc_ctor(4, 2, 0);
lean_ctor_set(v___x_728_, 0, v___x_702_);
lean_ctor_set(v___x_728_, 1, v___x_727_);
v___x_729_ = lean_alloc_ctor(6, 1, 1);
lean_ctor_set(v___x_729_, 0, v___x_728_);
lean_ctor_set_uint8(v___x_729_, sizeof(void*)*1, v___x_706_);
v___x_730_ = lean_alloc_ctor(5, 2, 0);
lean_ctor_set(v___x_730_, 0, v___x_725_);
lean_ctor_set(v___x_730_, 1, v___x_729_);
v___x_731_ = lean_alloc_ctor(5, 2, 0);
lean_ctor_set(v___x_731_, 0, v___x_730_);
lean_ctor_set(v___x_731_, 1, v___x_709_);
v___x_732_ = lean_alloc_ctor(5, 2, 0);
lean_ctor_set(v___x_732_, 0, v___x_731_);
lean_ctor_set(v___x_732_, 1, v___x_711_);
v___x_733_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_instReprBigStruct_repr___redArg___closed__9));
v___x_734_ = lean_alloc_ctor(5, 2, 0);
lean_ctor_set(v___x_734_, 0, v___x_732_);
lean_ctor_set(v___x_734_, 1, v___x_733_);
v___x_735_ = lean_alloc_ctor(5, 2, 0);
lean_ctor_set(v___x_735_, 0, v___x_734_);
lean_ctor_set(v___x_735_, 1, v___x_700_);
v___x_736_ = l_Nat_reprFast(v_d_698_);
v___x_737_ = lean_alloc_ctor(3, 1, 0);
lean_ctor_set(v___x_737_, 0, v___x_736_);
v___x_738_ = lean_alloc_ctor(4, 2, 0);
lean_ctor_set(v___x_738_, 0, v___x_702_);
lean_ctor_set(v___x_738_, 1, v___x_737_);
v___x_739_ = lean_alloc_ctor(6, 1, 1);
lean_ctor_set(v___x_739_, 0, v___x_738_);
lean_ctor_set_uint8(v___x_739_, sizeof(void*)*1, v___x_706_);
v___x_740_ = lean_alloc_ctor(5, 2, 0);
lean_ctor_set(v___x_740_, 0, v___x_735_);
lean_ctor_set(v___x_740_, 1, v___x_739_);
v___x_741_ = lean_alloc_ctor(5, 2, 0);
lean_ctor_set(v___x_741_, 0, v___x_740_);
lean_ctor_set(v___x_741_, 1, v___x_709_);
v___x_742_ = lean_alloc_ctor(5, 2, 0);
lean_ctor_set(v___x_742_, 0, v___x_741_);
lean_ctor_set(v___x_742_, 1, v___x_711_);
v___x_743_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_instReprBigStruct_repr___redArg___closed__11));
v___x_744_ = lean_alloc_ctor(5, 2, 0);
lean_ctor_set(v___x_744_, 0, v___x_742_);
lean_ctor_set(v___x_744_, 1, v___x_743_);
v___x_745_ = lean_alloc_ctor(5, 2, 0);
lean_ctor_set(v___x_745_, 0, v___x_744_);
lean_ctor_set(v___x_745_, 1, v___x_700_);
v___x_746_ = l_Nat_reprFast(v_e_699_);
v___x_747_ = lean_alloc_ctor(3, 1, 0);
lean_ctor_set(v___x_747_, 0, v___x_746_);
v___x_748_ = lean_alloc_ctor(4, 2, 0);
lean_ctor_set(v___x_748_, 0, v___x_702_);
lean_ctor_set(v___x_748_, 1, v___x_747_);
v___x_749_ = lean_alloc_ctor(6, 1, 1);
lean_ctor_set(v___x_749_, 0, v___x_748_);
lean_ctor_set_uint8(v___x_749_, sizeof(void*)*1, v___x_706_);
v___x_750_ = lean_alloc_ctor(5, 2, 0);
lean_ctor_set(v___x_750_, 0, v___x_745_);
lean_ctor_set(v___x_750_, 1, v___x_749_);
v___x_751_ = lean_obj_once(&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_instReprPoint_repr___redArg___closed__14, &lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_instReprPoint_repr___redArg___closed__14_once, _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_instReprPoint_repr___redArg___closed__14);
v___x_752_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_instReprPoint_repr___redArg___closed__15));
v___x_753_ = lean_alloc_ctor(5, 2, 0);
lean_ctor_set(v___x_753_, 0, v___x_752_);
lean_ctor_set(v___x_753_, 1, v___x_750_);
v___x_754_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_instReprPoint_repr___redArg___closed__16));
v___x_755_ = lean_alloc_ctor(5, 2, 0);
lean_ctor_set(v___x_755_, 0, v___x_753_);
lean_ctor_set(v___x_755_, 1, v___x_754_);
v___x_756_ = lean_alloc_ctor(4, 2, 0);
lean_ctor_set(v___x_756_, 0, v___x_751_);
lean_ctor_set(v___x_756_, 1, v___x_755_);
v___x_757_ = lean_alloc_ctor(6, 1, 1);
lean_ctor_set(v___x_757_, 0, v___x_756_);
lean_ctor_set_uint8(v___x_757_, sizeof(void*)*1, v___x_706_);
return v___x_757_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_instReprBigStruct_repr(lean_object* v_x_758_, lean_object* v_prec_759_){
_start:
{
lean_object* v___x_760_; 
v___x_760_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_instReprBigStruct_repr___redArg(v_x_758_);
return v___x_760_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_instReprBigStruct_repr___boxed(lean_object* v_x_761_, lean_object* v_prec_762_){
_start:
{
lean_object* v_res_763_; 
v_res_763_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_instReprBigStruct_repr(v_x_761_, v_prec_762_);
lean_dec(v_prec_762_);
return v_res_763_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_getA(lean_object* v_s_766_){
_start:
{
lean_object* v_a_767_; 
v_a_767_ = lean_ctor_get(v_s_766_, 0);
lean_inc(v_a_767_);
return v_a_767_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_getA___boxed(lean_object* v_s_768_){
_start:
{
lean_object* v_res_769_; 
v_res_769_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_getA(v_s_768_);
lean_dec_ref(v_s_768_);
return v_res_769_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_a__val(void){
_start:
{
lean_object* v___x_777_; lean_object* v_a_778_; 
v___x_777_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_big));
v_a_778_ = lean_ctor_get(v___x_777_, 0);
lean_inc(v_a_778_);
return v_a_778_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_addPoints2(lean_object* v_x_779_, lean_object* v_x_780_){
_start:
{
lean_object* v_x_781_; lean_object* v_y_782_; lean_object* v_x_783_; lean_object* v_y_784_; lean_object* v___x_786_; uint8_t v_isShared_787_; uint8_t v_isSharedCheck_793_; 
v_x_781_ = lean_ctor_get(v_x_779_, 0);
v_y_782_ = lean_ctor_get(v_x_779_, 1);
v_x_783_ = lean_ctor_get(v_x_780_, 0);
v_y_784_ = lean_ctor_get(v_x_780_, 1);
v_isSharedCheck_793_ = !lean_is_exclusive(v_x_780_);
if (v_isSharedCheck_793_ == 0)
{
v___x_786_ = v_x_780_;
v_isShared_787_ = v_isSharedCheck_793_;
goto v_resetjp_785_;
}
else
{
lean_inc(v_y_784_);
lean_inc(v_x_783_);
lean_dec(v_x_780_);
v___x_786_ = lean_box(0);
v_isShared_787_ = v_isSharedCheck_793_;
goto v_resetjp_785_;
}
v_resetjp_785_:
{
lean_object* v___x_788_; lean_object* v___x_789_; lean_object* v___x_791_; 
v___x_788_ = lean_nat_add(v_x_781_, v_x_783_);
lean_dec(v_x_783_);
v___x_789_ = lean_nat_add(v_y_782_, v_y_784_);
lean_dec(v_y_784_);
if (v_isShared_787_ == 0)
{
lean_ctor_set(v___x_786_, 1, v___x_789_);
lean_ctor_set(v___x_786_, 0, v___x_788_);
v___x_791_ = v___x_786_;
goto v_reusejp_790_;
}
else
{
lean_object* v_reuseFailAlloc_792_; 
v_reuseFailAlloc_792_ = lean_alloc_ctor(0, 2, 0);
lean_ctor_set(v_reuseFailAlloc_792_, 0, v___x_788_);
lean_ctor_set(v_reuseFailAlloc_792_, 1, v___x_789_);
v___x_791_ = v_reuseFailAlloc_792_;
goto v_reusejp_790_;
}
v_reusejp_790_:
{
return v___x_791_;
}
}
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_addPoints2___boxed(lean_object* v_x_794_, lean_object* v_x_795_){
_start:
{
lean_object* v_res_796_; 
v_res_796_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_addPoints2(v_x_794_, v_x_795_);
lean_dec_ref(v_x_794_);
return v_res_796_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_addPoints3(lean_object* v_x_797_, lean_object* v_x_798_){
_start:
{
lean_object* v_x_799_; lean_object* v_y_800_; lean_object* v_x_801_; lean_object* v_y_802_; lean_object* v___x_804_; uint8_t v_isShared_805_; uint8_t v_isSharedCheck_811_; 
v_x_799_ = lean_ctor_get(v_x_797_, 0);
v_y_800_ = lean_ctor_get(v_x_797_, 1);
v_x_801_ = lean_ctor_get(v_x_798_, 0);
v_y_802_ = lean_ctor_get(v_x_798_, 1);
v_isSharedCheck_811_ = !lean_is_exclusive(v_x_798_);
if (v_isSharedCheck_811_ == 0)
{
v___x_804_ = v_x_798_;
v_isShared_805_ = v_isSharedCheck_811_;
goto v_resetjp_803_;
}
else
{
lean_inc(v_y_802_);
lean_inc(v_x_801_);
lean_dec(v_x_798_);
v___x_804_ = lean_box(0);
v_isShared_805_ = v_isSharedCheck_811_;
goto v_resetjp_803_;
}
v_resetjp_803_:
{
lean_object* v___x_806_; lean_object* v___x_807_; lean_object* v___x_809_; 
v___x_806_ = lean_nat_add(v_x_799_, v_x_801_);
lean_dec(v_x_801_);
v___x_807_ = lean_nat_add(v_y_800_, v_y_802_);
lean_dec(v_y_802_);
if (v_isShared_805_ == 0)
{
lean_ctor_set(v___x_804_, 1, v___x_807_);
lean_ctor_set(v___x_804_, 0, v___x_806_);
v___x_809_ = v___x_804_;
goto v_reusejp_808_;
}
else
{
lean_object* v_reuseFailAlloc_810_; 
v_reuseFailAlloc_810_ = lean_alloc_ctor(0, 2, 0);
lean_ctor_set(v_reuseFailAlloc_810_, 0, v___x_806_);
lean_ctor_set(v_reuseFailAlloc_810_, 1, v___x_807_);
v___x_809_ = v_reuseFailAlloc_810_;
goto v_reusejp_808_;
}
v_reusejp_808_:
{
return v___x_809_;
}
}
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_addPoints3___boxed(lean_object* v_x_812_, lean_object* v_x_813_){
_start:
{
lean_object* v_res_814_; 
v_res_814_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_addPoints3(v_x_812_, v_x_813_);
lean_dec_ref(v_x_812_);
return v_res_814_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_describePoint(lean_object* v_p_818_){
_start:
{
lean_object* v_x_819_; lean_object* v_y_820_; lean_object* v___x_821_; lean_object* v___x_822_; lean_object* v___x_823_; lean_object* v___x_824_; lean_object* v___x_825_; lean_object* v___x_826_; lean_object* v___x_827_; lean_object* v___x_828_; lean_object* v___x_829_; lean_object* v___x_830_; lean_object* v___x_831_; lean_object* v___x_832_; 
v_x_819_ = lean_ctor_get(v_p_818_, 0);
lean_inc_n(v_x_819_, 2);
v_y_820_ = lean_ctor_get(v_p_818_, 1);
lean_inc_n(v_y_820_, 2);
lean_dec_ref(v_p_818_);
v___x_821_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_describePoint___closed__0));
v___x_822_ = l_Nat_reprFast(v_x_819_);
v___x_823_ = lean_string_append(v___x_821_, v___x_822_);
lean_dec_ref(v___x_822_);
v___x_824_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_describePoint___closed__1));
v___x_825_ = lean_string_append(v___x_823_, v___x_824_);
v___x_826_ = l_Nat_reprFast(v_y_820_);
v___x_827_ = lean_string_append(v___x_825_, v___x_826_);
lean_dec_ref(v___x_826_);
v___x_828_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_describePoint___closed__2));
v___x_829_ = lean_string_append(v___x_827_, v___x_828_);
v___x_830_ = lean_nat_add(v_x_819_, v_y_820_);
lean_dec(v_y_820_);
lean_dec(v_x_819_);
v___x_831_ = l_Nat_reprFast(v___x_830_);
v___x_832_ = lean_string_append(v___x_829_, v___x_831_);
lean_dec_ref(v___x_831_);
return v___x_832_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_desc___closed__0(void){
_start:
{
lean_object* v___x_833_; lean_object* v___x_834_; 
v___x_833_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_p1));
v___x_834_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_describePoint(v___x_833_);
return v___x_834_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_desc(void){
_start:
{
lean_object* v___x_835_; 
v___x_835_ = lean_obj_once(&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_desc___closed__0, &lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_desc___closed__0_once, _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_desc___closed__0);
return v___x_835_;
}
}
lean_object* initialize_Init(uint8_t builtin);
lean_object* initialize_Init(uint8_t builtin);
static bool _G_initialized = false;
LEAN_EXPORT lean_object* initialize_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct(uint8_t builtin) {
lean_object * res;
if (_G_initialized) return lean_io_result_mk_ok(lean_box(0));
_G_initialized = true;
res = initialize_Init(builtin);
if (lean_io_result_is_error(res)) return res;
lean_dec_ref(res);
res = initialize_Init(builtin);
if (lean_io_result_is_error(res)) return res;
lean_dec_ref(res);
lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_dist1 = _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_dist1();
lean_mark_persistent(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_dist1);
lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_x1 = _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_x1();
lean_mark_persistent(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_x1);
lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_sum = _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_sum();
lean_mark_persistent(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_sum);
lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_let__sum = _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_let__sum();
lean_mark_persistent(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_let__sum);
lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_lambda__sum = _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_lambda__sum();
lean_mark_persistent(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_lambda__sum);
lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_check__red__origin = _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_check__red__origin();
lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_cp__x = _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_cp__x();
lean_mark_persistent(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_cp__x);
lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_scaled__sum = _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_scaled__sum();
lean_mark_persistent(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_scaled__sum);
lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_tree__sum = _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_tree__sum();
lean_mark_persistent(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_tree__sum);
lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_tree__leaves = _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_tree__leaves();
lean_mark_persistent(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_tree__leaves);
lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_tree__height = _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_tree__height();
lean_mark_persistent(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_tree__height);
lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_cmp1 = _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_cmp1();
lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_cmp2 = _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_cmp2();
lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_q1 = _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_q1();
lean_mark_persistent(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_q1);
lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_q0 = _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_q0();
lean_mark_persistent(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_q0);
lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_sum__xs = _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_sum__xs();
lean_mark_persistent(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_sum__xs);
lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_found = _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_found();
lean_mark_persistent(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_found);
lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_a__val = _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_a__val();
lean_mark_persistent(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_a__val);
lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_desc = _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_desc();
lean_mark_persistent(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_PatternMatchingStruct_desc);
return lean_io_result_mk_ok(lean_box(0));
}
#ifdef __cplusplus
}
#endif
