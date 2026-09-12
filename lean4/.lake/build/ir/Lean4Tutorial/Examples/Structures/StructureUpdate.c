// Lean compiler output
// Module: Lean4Tutorial.Examples.Structures.StructureUpdate
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
lean_object* lean_nat_to_int(lean_object*);
lean_object* l_Nat_reprFast(lean_object*);
lean_object* lean_string_length(lean_object*);
lean_object* l_String_quote(lean_object*);
uint8_t lean_nat_dec_eq(lean_object*, lean_object*);
lean_object* lean_nat_add(lean_object*, lean_object*);
lean_object* lean_nat_mul(lean_object*, lean_object*);
static const lean_string_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instReprPoint_repr___redArg___closed__0_value = {.m_header = {.m_rc = 0, .m_cs_sz = 0, .m_other = 0, .m_tag = 249}, .m_size = 3, .m_capacity = 3, .m_length = 2, .m_data = "{ "};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instReprPoint_repr___redArg___closed__0 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instReprPoint_repr___redArg___closed__0_value;
static const lean_string_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instReprPoint_repr___redArg___closed__1_value = {.m_header = {.m_rc = 0, .m_cs_sz = 0, .m_other = 0, .m_tag = 249}, .m_size = 2, .m_capacity = 2, .m_length = 1, .m_data = "x"};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instReprPoint_repr___redArg___closed__1 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instReprPoint_repr___redArg___closed__1_value;
static const lean_ctor_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instReprPoint_repr___redArg___closed__2_value = {.m_header = {.m_rc = 0, .m_cs_sz = sizeof(lean_ctor_object) + sizeof(void*)*1 + 0, .m_other = 1, .m_tag = 3}, .m_objs = {((lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instReprPoint_repr___redArg___closed__1_value)}};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instReprPoint_repr___redArg___closed__2 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instReprPoint_repr___redArg___closed__2_value;
static const lean_ctor_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instReprPoint_repr___redArg___closed__3_value = {.m_header = {.m_rc = 0, .m_cs_sz = sizeof(lean_ctor_object) + sizeof(void*)*2 + 0, .m_other = 2, .m_tag = 5}, .m_objs = {((lean_object*)(((size_t)(0) << 1) | 1)),((lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instReprPoint_repr___redArg___closed__2_value)}};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instReprPoint_repr___redArg___closed__3 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instReprPoint_repr___redArg___closed__3_value;
static const lean_string_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instReprPoint_repr___redArg___closed__4_value = {.m_header = {.m_rc = 0, .m_cs_sz = 0, .m_other = 0, .m_tag = 249}, .m_size = 5, .m_capacity = 5, .m_length = 4, .m_data = " := "};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instReprPoint_repr___redArg___closed__4 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instReprPoint_repr___redArg___closed__4_value;
static const lean_ctor_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instReprPoint_repr___redArg___closed__5_value = {.m_header = {.m_rc = 0, .m_cs_sz = sizeof(lean_ctor_object) + sizeof(void*)*1 + 0, .m_other = 1, .m_tag = 3}, .m_objs = {((lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instReprPoint_repr___redArg___closed__4_value)}};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instReprPoint_repr___redArg___closed__5 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instReprPoint_repr___redArg___closed__5_value;
static const lean_ctor_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instReprPoint_repr___redArg___closed__6_value = {.m_header = {.m_rc = 0, .m_cs_sz = sizeof(lean_ctor_object) + sizeof(void*)*2 + 0, .m_other = 2, .m_tag = 5}, .m_objs = {((lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instReprPoint_repr___redArg___closed__3_value),((lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instReprPoint_repr___redArg___closed__5_value)}};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instReprPoint_repr___redArg___closed__6 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instReprPoint_repr___redArg___closed__6_value;
static lean_once_cell_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instReprPoint_repr___redArg___closed__7_once = LEAN_ONCE_CELL_INITIALIZER;
static lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instReprPoint_repr___redArg___closed__7;
static const lean_string_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instReprPoint_repr___redArg___closed__8_value = {.m_header = {.m_rc = 0, .m_cs_sz = 0, .m_other = 0, .m_tag = 249}, .m_size = 2, .m_capacity = 2, .m_length = 1, .m_data = ","};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instReprPoint_repr___redArg___closed__8 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instReprPoint_repr___redArg___closed__8_value;
static const lean_ctor_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instReprPoint_repr___redArg___closed__9_value = {.m_header = {.m_rc = 0, .m_cs_sz = sizeof(lean_ctor_object) + sizeof(void*)*1 + 0, .m_other = 1, .m_tag = 3}, .m_objs = {((lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instReprPoint_repr___redArg___closed__8_value)}};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instReprPoint_repr___redArg___closed__9 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instReprPoint_repr___redArg___closed__9_value;
static const lean_string_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instReprPoint_repr___redArg___closed__10_value = {.m_header = {.m_rc = 0, .m_cs_sz = 0, .m_other = 0, .m_tag = 249}, .m_size = 2, .m_capacity = 2, .m_length = 1, .m_data = "y"};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instReprPoint_repr___redArg___closed__10 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instReprPoint_repr___redArg___closed__10_value;
static const lean_ctor_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instReprPoint_repr___redArg___closed__11_value = {.m_header = {.m_rc = 0, .m_cs_sz = sizeof(lean_ctor_object) + sizeof(void*)*1 + 0, .m_other = 1, .m_tag = 3}, .m_objs = {((lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instReprPoint_repr___redArg___closed__10_value)}};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instReprPoint_repr___redArg___closed__11 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instReprPoint_repr___redArg___closed__11_value;
static const lean_string_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instReprPoint_repr___redArg___closed__12_value = {.m_header = {.m_rc = 0, .m_cs_sz = 0, .m_other = 0, .m_tag = 249}, .m_size = 3, .m_capacity = 3, .m_length = 2, .m_data = " }"};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instReprPoint_repr___redArg___closed__12 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instReprPoint_repr___redArg___closed__12_value;
static lean_once_cell_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instReprPoint_repr___redArg___closed__13_once = LEAN_ONCE_CELL_INITIALIZER;
static lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instReprPoint_repr___redArg___closed__13;
static lean_once_cell_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instReprPoint_repr___redArg___closed__14_once = LEAN_ONCE_CELL_INITIALIZER;
static lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instReprPoint_repr___redArg___closed__14;
static const lean_ctor_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instReprPoint_repr___redArg___closed__15_value = {.m_header = {.m_rc = 0, .m_cs_sz = sizeof(lean_ctor_object) + sizeof(void*)*1 + 0, .m_other = 1, .m_tag = 3}, .m_objs = {((lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instReprPoint_repr___redArg___closed__0_value)}};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instReprPoint_repr___redArg___closed__15 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instReprPoint_repr___redArg___closed__15_value;
static const lean_ctor_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instReprPoint_repr___redArg___closed__16_value = {.m_header = {.m_rc = 0, .m_cs_sz = sizeof(lean_ctor_object) + sizeof(void*)*1 + 0, .m_other = 1, .m_tag = 3}, .m_objs = {((lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instReprPoint_repr___redArg___closed__12_value)}};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instReprPoint_repr___redArg___closed__16 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instReprPoint_repr___redArg___closed__16_value;
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instReprPoint_repr___redArg(lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instReprPoint_repr(lean_object*, lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instReprPoint_repr___boxed(lean_object*, lean_object*);
static const lean_closure_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instReprPoint___closed__0_value = {.m_header = {.m_rc = 0, .m_cs_sz = sizeof(lean_closure_object) + sizeof(void*)*0, .m_other = 0, .m_tag = 245}, .m_fun = (void*)lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instReprPoint_repr___boxed, .m_arity = 2, .m_num_fixed = 0, .m_objs = {} };
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instReprPoint___closed__0 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instReprPoint___closed__0_value;
LEAN_EXPORT const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instReprPoint = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instReprPoint___closed__0_value;
LEAN_EXPORT uint8_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instDecidableEqPoint_decEq(lean_object*, lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instDecidableEqPoint_decEq___boxed(lean_object*, lean_object*);
LEAN_EXPORT uint8_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instDecidableEqPoint(lean_object*, lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instDecidableEqPoint___boxed(lean_object*, lean_object*);
static const lean_ctor_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_p1___closed__0_value = {.m_header = {.m_rc = 0, .m_cs_sz = sizeof(lean_ctor_object) + sizeof(void*)*2 + 0, .m_other = 2, .m_tag = 0}, .m_objs = {((lean_object*)(((size_t)(1) << 1) | 1)),((lean_object*)(((size_t)(2) << 1) | 1))}};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_p1___closed__0 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_p1___closed__0_value;
LEAN_EXPORT const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_p1 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_p1___closed__0_value;
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_p1_x27;
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_p1_x27_x27;
static const lean_ctor_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_p1_x27_x27_x27___closed__0_value = {.m_header = {.m_rc = 0, .m_cs_sz = sizeof(lean_ctor_object) + sizeof(void*)*2 + 0, .m_other = 2, .m_tag = 0}, .m_objs = {((lean_object*)(((size_t)(10) << 1) | 1)),((lean_object*)(((size_t)(20) << 1) | 1))}};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_p1_x27_x27_x27___closed__0 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_p1_x27_x27_x27___closed__0_value;
LEAN_EXPORT const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_p1_x27_x27_x27 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_p1_x27_x27_x27___closed__0_value;
static const lean_ctor_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_original___closed__0_value = {.m_header = {.m_rc = 0, .m_cs_sz = sizeof(lean_ctor_object) + sizeof(void*)*2 + 0, .m_other = 2, .m_tag = 0}, .m_objs = {((lean_object*)(((size_t)(5) << 1) | 1)),((lean_object*)(((size_t)(5) << 1) | 1))}};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_original___closed__0 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_original___closed__0_value;
LEAN_EXPORT const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_original = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_original___closed__0_value;
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_updated;
static const lean_string_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instReprColor_repr___redArg___closed__0_value = {.m_header = {.m_rc = 0, .m_cs_sz = 0, .m_other = 0, .m_tag = 249}, .m_size = 4, .m_capacity = 4, .m_length = 3, .m_data = "red"};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instReprColor_repr___redArg___closed__0 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instReprColor_repr___redArg___closed__0_value;
static const lean_ctor_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instReprColor_repr___redArg___closed__1_value = {.m_header = {.m_rc = 0, .m_cs_sz = sizeof(lean_ctor_object) + sizeof(void*)*1 + 0, .m_other = 1, .m_tag = 3}, .m_objs = {((lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instReprColor_repr___redArg___closed__0_value)}};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instReprColor_repr___redArg___closed__1 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instReprColor_repr___redArg___closed__1_value;
static const lean_ctor_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instReprColor_repr___redArg___closed__2_value = {.m_header = {.m_rc = 0, .m_cs_sz = sizeof(lean_ctor_object) + sizeof(void*)*2 + 0, .m_other = 2, .m_tag = 5}, .m_objs = {((lean_object*)(((size_t)(0) << 1) | 1)),((lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instReprColor_repr___redArg___closed__1_value)}};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instReprColor_repr___redArg___closed__2 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instReprColor_repr___redArg___closed__2_value;
static const lean_ctor_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instReprColor_repr___redArg___closed__3_value = {.m_header = {.m_rc = 0, .m_cs_sz = sizeof(lean_ctor_object) + sizeof(void*)*2 + 0, .m_other = 2, .m_tag = 5}, .m_objs = {((lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instReprColor_repr___redArg___closed__2_value),((lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instReprPoint_repr___redArg___closed__5_value)}};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instReprColor_repr___redArg___closed__3 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instReprColor_repr___redArg___closed__3_value;
static lean_once_cell_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instReprColor_repr___redArg___closed__4_once = LEAN_ONCE_CELL_INITIALIZER;
static lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instReprColor_repr___redArg___closed__4;
static const lean_string_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instReprColor_repr___redArg___closed__5_value = {.m_header = {.m_rc = 0, .m_cs_sz = 0, .m_other = 0, .m_tag = 249}, .m_size = 6, .m_capacity = 6, .m_length = 5, .m_data = "green"};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instReprColor_repr___redArg___closed__5 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instReprColor_repr___redArg___closed__5_value;
static const lean_ctor_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instReprColor_repr___redArg___closed__6_value = {.m_header = {.m_rc = 0, .m_cs_sz = sizeof(lean_ctor_object) + sizeof(void*)*1 + 0, .m_other = 1, .m_tag = 3}, .m_objs = {((lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instReprColor_repr___redArg___closed__5_value)}};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instReprColor_repr___redArg___closed__6 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instReprColor_repr___redArg___closed__6_value;
static lean_once_cell_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instReprColor_repr___redArg___closed__7_once = LEAN_ONCE_CELL_INITIALIZER;
static lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instReprColor_repr___redArg___closed__7;
static const lean_string_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instReprColor_repr___redArg___closed__8_value = {.m_header = {.m_rc = 0, .m_cs_sz = 0, .m_other = 0, .m_tag = 249}, .m_size = 5, .m_capacity = 5, .m_length = 4, .m_data = "blue"};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instReprColor_repr___redArg___closed__8 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instReprColor_repr___redArg___closed__8_value;
static const lean_ctor_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instReprColor_repr___redArg___closed__9_value = {.m_header = {.m_rc = 0, .m_cs_sz = sizeof(lean_ctor_object) + sizeof(void*)*1 + 0, .m_other = 1, .m_tag = 3}, .m_objs = {((lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instReprColor_repr___redArg___closed__8_value)}};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instReprColor_repr___redArg___closed__9 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instReprColor_repr___redArg___closed__9_value;
static lean_once_cell_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instReprColor_repr___redArg___closed__10_once = LEAN_ONCE_CELL_INITIALIZER;
static lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instReprColor_repr___redArg___closed__10;
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instReprColor_repr___redArg(lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instReprColor_repr(lean_object*, lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instReprColor_repr___boxed(lean_object*, lean_object*);
static const lean_closure_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instReprColor___closed__0_value = {.m_header = {.m_rc = 0, .m_cs_sz = sizeof(lean_closure_object) + sizeof(void*)*0, .m_other = 0, .m_tag = 245}, .m_fun = (void*)lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instReprColor_repr___boxed, .m_arity = 2, .m_num_fixed = 0, .m_objs = {} };
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instReprColor___closed__0 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instReprColor___closed__0_value;
LEAN_EXPORT const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instReprColor = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instReprColor___closed__0_value;
LEAN_EXPORT uint8_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instDecidableEqColor_decEq(lean_object*, lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instDecidableEqColor_decEq___boxed(lean_object*, lean_object*);
LEAN_EXPORT uint8_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instDecidableEqColor(lean_object*, lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instDecidableEqColor___boxed(lean_object*, lean_object*);
static const lean_string_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instReprColoredPoint_repr___redArg___closed__0_value = {.m_header = {.m_rc = 0, .m_cs_sz = 0, .m_other = 0, .m_tag = 249}, .m_size = 6, .m_capacity = 6, .m_length = 5, .m_data = "point"};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instReprColoredPoint_repr___redArg___closed__0 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instReprColoredPoint_repr___redArg___closed__0_value;
static const lean_ctor_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instReprColoredPoint_repr___redArg___closed__1_value = {.m_header = {.m_rc = 0, .m_cs_sz = sizeof(lean_ctor_object) + sizeof(void*)*1 + 0, .m_other = 1, .m_tag = 3}, .m_objs = {((lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instReprColoredPoint_repr___redArg___closed__0_value)}};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instReprColoredPoint_repr___redArg___closed__1 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instReprColoredPoint_repr___redArg___closed__1_value;
static const lean_ctor_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instReprColoredPoint_repr___redArg___closed__2_value = {.m_header = {.m_rc = 0, .m_cs_sz = sizeof(lean_ctor_object) + sizeof(void*)*2 + 0, .m_other = 2, .m_tag = 5}, .m_objs = {((lean_object*)(((size_t)(0) << 1) | 1)),((lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instReprColoredPoint_repr___redArg___closed__1_value)}};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instReprColoredPoint_repr___redArg___closed__2 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instReprColoredPoint_repr___redArg___closed__2_value;
static const lean_ctor_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instReprColoredPoint_repr___redArg___closed__3_value = {.m_header = {.m_rc = 0, .m_cs_sz = sizeof(lean_ctor_object) + sizeof(void*)*2 + 0, .m_other = 2, .m_tag = 5}, .m_objs = {((lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instReprColoredPoint_repr___redArg___closed__2_value),((lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instReprPoint_repr___redArg___closed__5_value)}};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instReprColoredPoint_repr___redArg___closed__3 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instReprColoredPoint_repr___redArg___closed__3_value;
static const lean_string_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instReprColoredPoint_repr___redArg___closed__4_value = {.m_header = {.m_rc = 0, .m_cs_sz = 0, .m_other = 0, .m_tag = 249}, .m_size = 6, .m_capacity = 6, .m_length = 5, .m_data = "color"};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instReprColoredPoint_repr___redArg___closed__4 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instReprColoredPoint_repr___redArg___closed__4_value;
static const lean_ctor_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instReprColoredPoint_repr___redArg___closed__5_value = {.m_header = {.m_rc = 0, .m_cs_sz = sizeof(lean_ctor_object) + sizeof(void*)*1 + 0, .m_other = 1, .m_tag = 3}, .m_objs = {((lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instReprColoredPoint_repr___redArg___closed__4_value)}};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instReprColoredPoint_repr___redArg___closed__5 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instReprColoredPoint_repr___redArg___closed__5_value;
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instReprColoredPoint_repr___redArg(lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instReprColoredPoint_repr(lean_object*, lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instReprColoredPoint_repr___boxed(lean_object*, lean_object*);
static const lean_closure_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instReprColoredPoint___closed__0_value = {.m_header = {.m_rc = 0, .m_cs_sz = sizeof(lean_closure_object) + sizeof(void*)*0, .m_other = 0, .m_tag = 245}, .m_fun = (void*)lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instReprColoredPoint_repr___boxed, .m_arity = 2, .m_num_fixed = 0, .m_objs = {} };
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instReprColoredPoint___closed__0 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instReprColoredPoint___closed__0_value;
LEAN_EXPORT const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instReprColoredPoint = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instReprColoredPoint___closed__0_value;
static const lean_ctor_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_redPoint___closed__0_value = {.m_header = {.m_rc = 0, .m_cs_sz = sizeof(lean_ctor_object) + sizeof(void*)*3 + 0, .m_other = 3, .m_tag = 0}, .m_objs = {((lean_object*)(((size_t)(255) << 1) | 1)),((lean_object*)(((size_t)(0) << 1) | 1)),((lean_object*)(((size_t)(0) << 1) | 1))}};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_redPoint___closed__0 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_redPoint___closed__0_value;
static const lean_ctor_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_redPoint___closed__1_value = {.m_header = {.m_rc = 0, .m_cs_sz = sizeof(lean_ctor_object) + sizeof(void*)*2 + 0, .m_other = 2, .m_tag = 0}, .m_objs = {((lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_p1_x27_x27_x27___closed__0_value),((lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_redPoint___closed__0_value)}};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_redPoint___closed__1 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_redPoint___closed__1_value;
LEAN_EXPORT const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_redPoint = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_redPoint___closed__1_value;
static const lean_ctor_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_darkerRed___closed__0_value = {.m_header = {.m_rc = 0, .m_cs_sz = sizeof(lean_ctor_object) + sizeof(void*)*3 + 0, .m_other = 3, .m_tag = 0}, .m_objs = {((lean_object*)(((size_t)(128) << 1) | 1)),((lean_object*)(((size_t)(0) << 1) | 1)),((lean_object*)(((size_t)(0) << 1) | 1))}};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_darkerRed___closed__0 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_darkerRed___closed__0_value;
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_darkerRed;
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_moveRight;
static const lean_ctor_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_moveAndRecolor___closed__0_value = {.m_header = {.m_rc = 0, .m_cs_sz = sizeof(lean_ctor_object) + sizeof(void*)*3 + 0, .m_other = 3, .m_tag = 0}, .m_objs = {((lean_object*)(((size_t)(0) << 1) | 1)),((lean_object*)(((size_t)(255) << 1) | 1)),((lean_object*)(((size_t)(0) << 1) | 1))}};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_moveAndRecolor___closed__0 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_moveAndRecolor___closed__0_value;
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_moveAndRecolor;
static const lean_string_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instReprPoint3D_repr___redArg___closed__0_value = {.m_header = {.m_rc = 0, .m_cs_sz = 0, .m_other = 0, .m_tag = 249}, .m_size = 8, .m_capacity = 8, .m_length = 7, .m_data = "toPoint"};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instReprPoint3D_repr___redArg___closed__0 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instReprPoint3D_repr___redArg___closed__0_value;
static const lean_ctor_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instReprPoint3D_repr___redArg___closed__1_value = {.m_header = {.m_rc = 0, .m_cs_sz = sizeof(lean_ctor_object) + sizeof(void*)*1 + 0, .m_other = 1, .m_tag = 3}, .m_objs = {((lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instReprPoint3D_repr___redArg___closed__0_value)}};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instReprPoint3D_repr___redArg___closed__1 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instReprPoint3D_repr___redArg___closed__1_value;
static const lean_ctor_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instReprPoint3D_repr___redArg___closed__2_value = {.m_header = {.m_rc = 0, .m_cs_sz = sizeof(lean_ctor_object) + sizeof(void*)*2 + 0, .m_other = 2, .m_tag = 5}, .m_objs = {((lean_object*)(((size_t)(0) << 1) | 1)),((lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instReprPoint3D_repr___redArg___closed__1_value)}};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instReprPoint3D_repr___redArg___closed__2 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instReprPoint3D_repr___redArg___closed__2_value;
static const lean_ctor_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instReprPoint3D_repr___redArg___closed__3_value = {.m_header = {.m_rc = 0, .m_cs_sz = sizeof(lean_ctor_object) + sizeof(void*)*2 + 0, .m_other = 2, .m_tag = 5}, .m_objs = {((lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instReprPoint3D_repr___redArg___closed__2_value),((lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instReprPoint_repr___redArg___closed__5_value)}};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instReprPoint3D_repr___redArg___closed__3 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instReprPoint3D_repr___redArg___closed__3_value;
static lean_once_cell_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instReprPoint3D_repr___redArg___closed__4_once = LEAN_ONCE_CELL_INITIALIZER;
static lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instReprPoint3D_repr___redArg___closed__4;
static const lean_string_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instReprPoint3D_repr___redArg___closed__5_value = {.m_header = {.m_rc = 0, .m_cs_sz = 0, .m_other = 0, .m_tag = 249}, .m_size = 2, .m_capacity = 2, .m_length = 1, .m_data = "z"};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instReprPoint3D_repr___redArg___closed__5 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instReprPoint3D_repr___redArg___closed__5_value;
static const lean_ctor_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instReprPoint3D_repr___redArg___closed__6_value = {.m_header = {.m_rc = 0, .m_cs_sz = sizeof(lean_ctor_object) + sizeof(void*)*1 + 0, .m_other = 1, .m_tag = 3}, .m_objs = {((lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instReprPoint3D_repr___redArg___closed__5_value)}};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instReprPoint3D_repr___redArg___closed__6 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instReprPoint3D_repr___redArg___closed__6_value;
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instReprPoint3D_repr___redArg(lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instReprPoint3D_repr(lean_object*, lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instReprPoint3D_repr___boxed(lean_object*, lean_object*);
static const lean_closure_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instReprPoint3D___closed__0_value = {.m_header = {.m_rc = 0, .m_cs_sz = sizeof(lean_closure_object) + sizeof(void*)*0, .m_other = 0, .m_tag = 245}, .m_fun = (void*)lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instReprPoint3D_repr___boxed, .m_arity = 2, .m_num_fixed = 0, .m_objs = {} };
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instReprPoint3D___closed__0 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instReprPoint3D___closed__0_value;
LEAN_EXPORT const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instReprPoint3D = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instReprPoint3D___closed__0_value;
LEAN_EXPORT uint8_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instDecidableEqPoint3D_decEq(lean_object*, lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instDecidableEqPoint3D_decEq___boxed(lean_object*, lean_object*);
LEAN_EXPORT uint8_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instDecidableEqPoint3D(lean_object*, lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instDecidableEqPoint3D___boxed(lean_object*, lean_object*);
static const lean_ctor_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_p3d1___closed__0_value = {.m_header = {.m_rc = 0, .m_cs_sz = sizeof(lean_ctor_object) + sizeof(void*)*2 + 0, .m_other = 2, .m_tag = 0}, .m_objs = {((lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_p1___closed__0_value),((lean_object*)(((size_t)(3) << 1) | 1))}};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_p3d1___closed__0 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_p3d1___closed__0_value;
LEAN_EXPORT const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_p3d1 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_p3d1___closed__0_value;
LEAN_EXPORT const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_p3d2 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_p3d1___closed__0_value;
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_p3d__x;
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_p3d__y;
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_p3d__z;
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_p3d__point;
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_p3d1_x27;
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_p3d1_x27_x27;
static const lean_ctor_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_p3d1_x27_x27_x27___closed__0_value = {.m_header = {.m_rc = 0, .m_cs_sz = sizeof(lean_ctor_object) + sizeof(void*)*2 + 0, .m_other = 2, .m_tag = 0}, .m_objs = {((lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_p1_x27_x27_x27___closed__0_value),((lean_object*)(((size_t)(30) << 1) | 1))}};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_p3d1_x27_x27_x27___closed__0 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_p3d1_x27_x27_x27___closed__0_value;
LEAN_EXPORT const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_p3d1_x27_x27_x27 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_p3d1_x27_x27_x27___closed__0_value;
static const lean_string_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instReprNamedPoint3D_repr___redArg___closed__0_value = {.m_header = {.m_rc = 0, .m_cs_sz = 0, .m_other = 0, .m_tag = 249}, .m_size = 10, .m_capacity = 10, .m_length = 9, .m_data = "toPoint3D"};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instReprNamedPoint3D_repr___redArg___closed__0 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instReprNamedPoint3D_repr___redArg___closed__0_value;
static const lean_ctor_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instReprNamedPoint3D_repr___redArg___closed__1_value = {.m_header = {.m_rc = 0, .m_cs_sz = sizeof(lean_ctor_object) + sizeof(void*)*1 + 0, .m_other = 1, .m_tag = 3}, .m_objs = {((lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instReprNamedPoint3D_repr___redArg___closed__0_value)}};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instReprNamedPoint3D_repr___redArg___closed__1 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instReprNamedPoint3D_repr___redArg___closed__1_value;
static const lean_ctor_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instReprNamedPoint3D_repr___redArg___closed__2_value = {.m_header = {.m_rc = 0, .m_cs_sz = sizeof(lean_ctor_object) + sizeof(void*)*2 + 0, .m_other = 2, .m_tag = 5}, .m_objs = {((lean_object*)(((size_t)(0) << 1) | 1)),((lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instReprNamedPoint3D_repr___redArg___closed__1_value)}};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instReprNamedPoint3D_repr___redArg___closed__2 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instReprNamedPoint3D_repr___redArg___closed__2_value;
static const lean_ctor_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instReprNamedPoint3D_repr___redArg___closed__3_value = {.m_header = {.m_rc = 0, .m_cs_sz = sizeof(lean_ctor_object) + sizeof(void*)*2 + 0, .m_other = 2, .m_tag = 5}, .m_objs = {((lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instReprNamedPoint3D_repr___redArg___closed__2_value),((lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instReprPoint_repr___redArg___closed__5_value)}};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instReprNamedPoint3D_repr___redArg___closed__3 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instReprNamedPoint3D_repr___redArg___closed__3_value;
static lean_once_cell_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instReprNamedPoint3D_repr___redArg___closed__4_once = LEAN_ONCE_CELL_INITIALIZER;
static lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instReprNamedPoint3D_repr___redArg___closed__4;
static const lean_string_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instReprNamedPoint3D_repr___redArg___closed__5_value = {.m_header = {.m_rc = 0, .m_cs_sz = 0, .m_other = 0, .m_tag = 249}, .m_size = 5, .m_capacity = 5, .m_length = 4, .m_data = "name"};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instReprNamedPoint3D_repr___redArg___closed__5 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instReprNamedPoint3D_repr___redArg___closed__5_value;
static const lean_ctor_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instReprNamedPoint3D_repr___redArg___closed__6_value = {.m_header = {.m_rc = 0, .m_cs_sz = sizeof(lean_ctor_object) + sizeof(void*)*1 + 0, .m_other = 1, .m_tag = 3}, .m_objs = {((lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instReprNamedPoint3D_repr___redArg___closed__5_value)}};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instReprNamedPoint3D_repr___redArg___closed__6 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instReprNamedPoint3D_repr___redArg___closed__6_value;
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instReprNamedPoint3D_repr___redArg(lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instReprNamedPoint3D_repr(lean_object*, lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instReprNamedPoint3D_repr___boxed(lean_object*, lean_object*);
static const lean_closure_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instReprNamedPoint3D___closed__0_value = {.m_header = {.m_rc = 0, .m_cs_sz = sizeof(lean_closure_object) + sizeof(void*)*0, .m_other = 0, .m_tag = 245}, .m_fun = (void*)lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instReprNamedPoint3D_repr___boxed, .m_arity = 2, .m_num_fixed = 0, .m_objs = {} };
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instReprNamedPoint3D___closed__0 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instReprNamedPoint3D___closed__0_value;
LEAN_EXPORT const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instReprNamedPoint3D = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instReprNamedPoint3D___closed__0_value;
static const lean_string_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_np3d___closed__0_value = {.m_header = {.m_rc = 0, .m_cs_sz = 0, .m_other = 0, .m_tag = 249}, .m_size = 7, .m_capacity = 7, .m_length = 6, .m_data = "origin"};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_np3d___closed__0 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_np3d___closed__0_value;
static const lean_ctor_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_np3d___closed__1_value = {.m_header = {.m_rc = 0, .m_cs_sz = sizeof(lean_ctor_object) + sizeof(void*)*2 + 0, .m_other = 2, .m_tag = 0}, .m_objs = {((lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_p3d1___closed__0_value),((lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_np3d___closed__0_value)}};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_np3d___closed__1 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_np3d___closed__1_value;
LEAN_EXPORT const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_np3d = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_np3d___closed__1_value;
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_np3d__name;
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_np3d__x;
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_np3d__z;
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_np3d__to__p3d;
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_np3d__to__point;
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instReprColoredPoint_x27_repr___redArg(lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instReprColoredPoint_x27_repr(lean_object*, lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instReprColoredPoint_x27_repr___boxed(lean_object*, lean_object*);
static const lean_closure_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instReprColoredPoint_x27___closed__0_value = {.m_header = {.m_rc = 0, .m_cs_sz = sizeof(lean_closure_object) + sizeof(void*)*0, .m_other = 0, .m_tag = 245}, .m_fun = (void*)lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instReprColoredPoint_x27_repr___boxed, .m_arity = 2, .m_num_fixed = 0, .m_objs = {} };
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instReprColoredPoint_x27___closed__0 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instReprColoredPoint_x27___closed__0_value;
LEAN_EXPORT const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instReprColoredPoint_x27 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instReprColoredPoint_x27___closed__0_value;
static const lean_ctor_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_redPoint_x27___closed__0_value = {.m_header = {.m_rc = 0, .m_cs_sz = sizeof(lean_ctor_object) + sizeof(void*)*2 + 0, .m_other = 2, .m_tag = 0}, .m_objs = {((lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_p1_x27_x27_x27___closed__0_value),((lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_redPoint___closed__0_value)}};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_redPoint_x27___closed__0 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_redPoint_x27___closed__0_value;
LEAN_EXPORT const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_redPoint_x27 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_redPoint_x27___closed__0_value;
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_rp__x;
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_rp__y;
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_rp__color;
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_greenPoint_x27;
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instAddPoint___lam__0(lean_object*, lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instAddPoint___lam__0___boxed(lean_object*, lean_object*);
static const lean_closure_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instAddPoint___closed__0_value = {.m_header = {.m_rc = 0, .m_cs_sz = sizeof(lean_closure_object) + sizeof(void*)*0, .m_other = 0, .m_tag = 245}, .m_fun = (void*)lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instAddPoint___lam__0___boxed, .m_arity = 2, .m_num_fixed = 0, .m_objs = {} };
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instAddPoint___closed__0 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instAddPoint___closed__0_value;
LEAN_EXPORT const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instAddPoint = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instAddPoint___closed__0_value;
static const lean_ctor_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instZeroPoint___closed__0_value = {.m_header = {.m_rc = 0, .m_cs_sz = sizeof(lean_ctor_object) + sizeof(void*)*2 + 0, .m_other = 2, .m_tag = 0}, .m_objs = {((lean_object*)(((size_t)(0) << 1) | 1)),((lean_object*)(((size_t)(0) << 1) | 1))}};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instZeroPoint___closed__0 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instZeroPoint___closed__0_value;
LEAN_EXPORT const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instZeroPoint = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instZeroPoint___closed__0_value;
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instAddPoint3D___lam__0(lean_object*, lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instAddPoint3D___lam__0___boxed(lean_object*, lean_object*);
static const lean_closure_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instAddPoint3D___closed__0_value = {.m_header = {.m_rc = 0, .m_cs_sz = sizeof(lean_closure_object) + sizeof(void*)*0, .m_other = 0, .m_tag = 245}, .m_fun = (void*)lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instAddPoint3D___lam__0___boxed, .m_arity = 2, .m_num_fixed = 0, .m_objs = {} };
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instAddPoint3D___closed__0 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instAddPoint3D___closed__0_value;
LEAN_EXPORT const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instAddPoint3D = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instAddPoint3D___closed__0_value;
static const lean_ctor_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instZeroPoint3D___closed__0_value = {.m_header = {.m_rc = 0, .m_cs_sz = sizeof(lean_ctor_object) + sizeof(void*)*2 + 0, .m_other = 2, .m_tag = 0}, .m_objs = {((lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instZeroPoint___closed__0_value),((lean_object*)(((size_t)(0) << 1) | 1))}};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instZeroPoint3D___closed__0 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instZeroPoint3D___closed__0_value;
LEAN_EXPORT const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instZeroPoint3D = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instZeroPoint3D___closed__0_value;
static const lean_ctor_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_p3d__add___closed__0_value = {.m_header = {.m_rc = 0, .m_cs_sz = sizeof(lean_ctor_object) + sizeof(void*)*2 + 0, .m_other = 2, .m_tag = 0}, .m_objs = {((lean_object*)(((size_t)(5) << 1) | 1)),((lean_object*)(((size_t)(7) << 1) | 1))}};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_p3d__add___closed__0 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_p3d__add___closed__0_value;
static const lean_ctor_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_p3d__add___closed__1_value = {.m_header = {.m_rc = 0, .m_cs_sz = sizeof(lean_ctor_object) + sizeof(void*)*2 + 0, .m_other = 2, .m_tag = 0}, .m_objs = {((lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_p3d__add___closed__0_value),((lean_object*)(((size_t)(9) << 1) | 1))}};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_p3d__add___closed__1 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_p3d__add___closed__1_value;
LEAN_EXPORT const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_p3d__add = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_p3d__add___closed__1_value;
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_upcast__example;
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_Point_toPoint3D(lean_object*, lean_object*);
LEAN_EXPORT const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_downcast__example = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_p3d1___closed__0_value;
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_Point_double(lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_Point3D_doubleXY(lean_object*);
static lean_once_cell_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_p3d__double__xy___closed__0_once = LEAN_ONCE_CELL_INITIALIZER;
static lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_p3d__double__xy___closed__0;
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_p3d__double__xy;
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_Point3D_double(lean_object*);
static lean_once_cell_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_p3d__double___closed__0_once = LEAN_ONCE_CELL_INITIALIZER;
static lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_p3d__double___closed__0;
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_p3d__double;
static const lean_ctor_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instReprHasName_repr___redArg___closed__0_value = {.m_header = {.m_rc = 0, .m_cs_sz = sizeof(lean_ctor_object) + sizeof(void*)*2 + 0, .m_other = 2, .m_tag = 5}, .m_objs = {((lean_object*)(((size_t)(0) << 1) | 1)),((lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instReprNamedPoint3D_repr___redArg___closed__6_value)}};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instReprHasName_repr___redArg___closed__0 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instReprHasName_repr___redArg___closed__0_value;
static const lean_ctor_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instReprHasName_repr___redArg___closed__1_value = {.m_header = {.m_rc = 0, .m_cs_sz = sizeof(lean_ctor_object) + sizeof(void*)*2 + 0, .m_other = 2, .m_tag = 5}, .m_objs = {((lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instReprHasName_repr___redArg___closed__0_value),((lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instReprPoint_repr___redArg___closed__5_value)}};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instReprHasName_repr___redArg___closed__1 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instReprHasName_repr___redArg___closed__1_value;
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instReprHasName_repr___redArg(lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instReprHasName_repr(lean_object*, lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instReprHasName_repr___boxed(lean_object*, lean_object*);
static const lean_closure_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instReprHasName___closed__0_value = {.m_header = {.m_rc = 0, .m_cs_sz = sizeof(lean_closure_object) + sizeof(void*)*0, .m_other = 0, .m_tag = 245}, .m_fun = (void*)lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instReprHasName_repr___boxed, .m_arity = 2, .m_num_fixed = 0, .m_objs = {} };
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instReprHasName___closed__0 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instReprHasName___closed__0_value;
LEAN_EXPORT const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instReprHasName = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instReprHasName___closed__0_value;
static const lean_string_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instReprHasAge_repr___redArg___closed__0_value = {.m_header = {.m_rc = 0, .m_cs_sz = 0, .m_other = 0, .m_tag = 249}, .m_size = 4, .m_capacity = 4, .m_length = 3, .m_data = "age"};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instReprHasAge_repr___redArg___closed__0 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instReprHasAge_repr___redArg___closed__0_value;
static const lean_ctor_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instReprHasAge_repr___redArg___closed__1_value = {.m_header = {.m_rc = 0, .m_cs_sz = sizeof(lean_ctor_object) + sizeof(void*)*1 + 0, .m_other = 1, .m_tag = 3}, .m_objs = {((lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instReprHasAge_repr___redArg___closed__0_value)}};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instReprHasAge_repr___redArg___closed__1 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instReprHasAge_repr___redArg___closed__1_value;
static const lean_ctor_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instReprHasAge_repr___redArg___closed__2_value = {.m_header = {.m_rc = 0, .m_cs_sz = sizeof(lean_ctor_object) + sizeof(void*)*2 + 0, .m_other = 2, .m_tag = 5}, .m_objs = {((lean_object*)(((size_t)(0) << 1) | 1)),((lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instReprHasAge_repr___redArg___closed__1_value)}};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instReprHasAge_repr___redArg___closed__2 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instReprHasAge_repr___redArg___closed__2_value;
static const lean_ctor_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instReprHasAge_repr___redArg___closed__3_value = {.m_header = {.m_rc = 0, .m_cs_sz = sizeof(lean_ctor_object) + sizeof(void*)*2 + 0, .m_other = 2, .m_tag = 5}, .m_objs = {((lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instReprHasAge_repr___redArg___closed__2_value),((lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instReprPoint_repr___redArg___closed__5_value)}};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instReprHasAge_repr___redArg___closed__3 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instReprHasAge_repr___redArg___closed__3_value;
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instReprHasAge_repr___redArg(lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instReprHasAge_repr(lean_object*, lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instReprHasAge_repr___boxed(lean_object*, lean_object*);
static const lean_closure_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instReprHasAge___closed__0_value = {.m_header = {.m_rc = 0, .m_cs_sz = sizeof(lean_closure_object) + sizeof(void*)*0, .m_other = 0, .m_tag = 245}, .m_fun = (void*)lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instReprHasAge_repr___boxed, .m_arity = 2, .m_num_fixed = 0, .m_objs = {} };
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instReprHasAge___closed__0 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instReprHasAge___closed__0_value;
LEAN_EXPORT const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instReprHasAge = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instReprHasAge___closed__0_value;
static const lean_string_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instReprStudent_repr___redArg___closed__0_value = {.m_header = {.m_rc = 0, .m_cs_sz = 0, .m_other = 0, .m_tag = 249}, .m_size = 10, .m_capacity = 10, .m_length = 9, .m_data = "toHasName"};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instReprStudent_repr___redArg___closed__0 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instReprStudent_repr___redArg___closed__0_value;
static const lean_ctor_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instReprStudent_repr___redArg___closed__1_value = {.m_header = {.m_rc = 0, .m_cs_sz = sizeof(lean_ctor_object) + sizeof(void*)*1 + 0, .m_other = 1, .m_tag = 3}, .m_objs = {((lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instReprStudent_repr___redArg___closed__0_value)}};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instReprStudent_repr___redArg___closed__1 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instReprStudent_repr___redArg___closed__1_value;
static const lean_ctor_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instReprStudent_repr___redArg___closed__2_value = {.m_header = {.m_rc = 0, .m_cs_sz = sizeof(lean_ctor_object) + sizeof(void*)*2 + 0, .m_other = 2, .m_tag = 5}, .m_objs = {((lean_object*)(((size_t)(0) << 1) | 1)),((lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instReprStudent_repr___redArg___closed__1_value)}};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instReprStudent_repr___redArg___closed__2 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instReprStudent_repr___redArg___closed__2_value;
static const lean_ctor_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instReprStudent_repr___redArg___closed__3_value = {.m_header = {.m_rc = 0, .m_cs_sz = sizeof(lean_ctor_object) + sizeof(void*)*2 + 0, .m_other = 2, .m_tag = 5}, .m_objs = {((lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instReprStudent_repr___redArg___closed__2_value),((lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instReprPoint_repr___redArg___closed__5_value)}};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instReprStudent_repr___redArg___closed__3 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instReprStudent_repr___redArg___closed__3_value;
static const lean_string_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instReprStudent_repr___redArg___closed__4_value = {.m_header = {.m_rc = 0, .m_cs_sz = 0, .m_other = 0, .m_tag = 249}, .m_size = 9, .m_capacity = 9, .m_length = 8, .m_data = "toHasAge"};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instReprStudent_repr___redArg___closed__4 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instReprStudent_repr___redArg___closed__4_value;
static const lean_ctor_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instReprStudent_repr___redArg___closed__5_value = {.m_header = {.m_rc = 0, .m_cs_sz = sizeof(lean_ctor_object) + sizeof(void*)*1 + 0, .m_other = 1, .m_tag = 3}, .m_objs = {((lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instReprStudent_repr___redArg___closed__4_value)}};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instReprStudent_repr___redArg___closed__5 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instReprStudent_repr___redArg___closed__5_value;
static lean_once_cell_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instReprStudent_repr___redArg___closed__6_once = LEAN_ONCE_CELL_INITIALIZER;
static lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instReprStudent_repr___redArg___closed__6;
static const lean_string_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instReprStudent_repr___redArg___closed__7_value = {.m_header = {.m_rc = 0, .m_cs_sz = 0, .m_other = 0, .m_tag = 249}, .m_size = 3, .m_capacity = 3, .m_length = 2, .m_data = "id"};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instReprStudent_repr___redArg___closed__7 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instReprStudent_repr___redArg___closed__7_value;
static const lean_ctor_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instReprStudent_repr___redArg___closed__8_value = {.m_header = {.m_rc = 0, .m_cs_sz = sizeof(lean_ctor_object) + sizeof(void*)*1 + 0, .m_other = 1, .m_tag = 3}, .m_objs = {((lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instReprStudent_repr___redArg___closed__7_value)}};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instReprStudent_repr___redArg___closed__8 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instReprStudent_repr___redArg___closed__8_value;
static lean_once_cell_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instReprStudent_repr___redArg___closed__9_once = LEAN_ONCE_CELL_INITIALIZER;
static lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instReprStudent_repr___redArg___closed__9;
static const lean_string_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instReprStudent_repr___redArg___closed__10_value = {.m_header = {.m_rc = 0, .m_cs_sz = 0, .m_other = 0, .m_tag = 249}, .m_size = 6, .m_capacity = 6, .m_length = 5, .m_data = "major"};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instReprStudent_repr___redArg___closed__10 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instReprStudent_repr___redArg___closed__10_value;
static const lean_ctor_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instReprStudent_repr___redArg___closed__11_value = {.m_header = {.m_rc = 0, .m_cs_sz = sizeof(lean_ctor_object) + sizeof(void*)*1 + 0, .m_other = 1, .m_tag = 3}, .m_objs = {((lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instReprStudent_repr___redArg___closed__10_value)}};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instReprStudent_repr___redArg___closed__11 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instReprStudent_repr___redArg___closed__11_value;
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instReprStudent_repr___redArg(lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instReprStudent_repr(lean_object*, lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instReprStudent_repr___boxed(lean_object*, lean_object*);
static const lean_closure_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instReprStudent___closed__0_value = {.m_header = {.m_rc = 0, .m_cs_sz = sizeof(lean_closure_object) + sizeof(void*)*0, .m_other = 0, .m_tag = 245}, .m_fun = (void*)lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instReprStudent_repr___boxed, .m_arity = 2, .m_num_fixed = 0, .m_objs = {} };
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instReprStudent___closed__0 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instReprStudent___closed__0_value;
LEAN_EXPORT const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instReprStudent = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instReprStudent___closed__0_value;
static const lean_string_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_student___closed__0_value = {.m_header = {.m_rc = 0, .m_cs_sz = 0, .m_other = 0, .m_tag = 249}, .m_size = 6, .m_capacity = 6, .m_length = 5, .m_data = "Alice"};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_student___closed__0 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_student___closed__0_value;
static const lean_string_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_student___closed__1_value = {.m_header = {.m_rc = 0, .m_cs_sz = 0, .m_other = 0, .m_tag = 249}, .m_size = 17, .m_capacity = 17, .m_length = 16, .m_data = "Computer Science"};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_student___closed__1 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_student___closed__1_value;
static const lean_ctor_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_student___closed__2_value = {.m_header = {.m_rc = 0, .m_cs_sz = sizeof(lean_ctor_object) + sizeof(void*)*4 + 0, .m_other = 4, .m_tag = 0}, .m_objs = {((lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_student___closed__0_value),((lean_object*)(((size_t)(20) << 1) | 1)),((lean_object*)(((size_t)(12345) << 1) | 1)),((lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_student___closed__1_value)}};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_student___closed__2 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_student___closed__2_value;
LEAN_EXPORT const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_student = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_student___closed__2_value;
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_student__name;
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_student__age;
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_student__id;
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_student__has__name;
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_student__has__age;
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instReprPoint_repr___redArg___closed__7(void){
_start:
{
lean_object* v___x_14_; lean_object* v___x_15_; 
v___x_14_ = lean_unsigned_to_nat(5u);
v___x_15_ = lean_nat_to_int(v___x_14_);
return v___x_15_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instReprPoint_repr___redArg___closed__13(void){
_start:
{
lean_object* v___x_23_; lean_object* v___x_24_; 
v___x_23_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instReprPoint_repr___redArg___closed__0));
v___x_24_ = lean_string_length(v___x_23_);
return v___x_24_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instReprPoint_repr___redArg___closed__14(void){
_start:
{
lean_object* v___x_25_; lean_object* v___x_26_; 
v___x_25_ = lean_obj_once(&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instReprPoint_repr___redArg___closed__13, &lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instReprPoint_repr___redArg___closed__13_once, _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instReprPoint_repr___redArg___closed__13);
v___x_26_ = lean_nat_to_int(v___x_25_);
return v___x_26_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instReprPoint_repr___redArg(lean_object* v_x_31_){
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
v___x_37_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instReprPoint_repr___redArg___closed__5));
v___x_38_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instReprPoint_repr___redArg___closed__6));
v___x_39_ = lean_obj_once(&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instReprPoint_repr___redArg___closed__7, &lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instReprPoint_repr___redArg___closed__7_once, _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instReprPoint_repr___redArg___closed__7);
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
v___x_47_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instReprPoint_repr___redArg___closed__9));
v___x_48_ = lean_alloc_ctor(5, 2, 0);
lean_ctor_set(v___x_48_, 0, v___x_46_);
lean_ctor_set(v___x_48_, 1, v___x_47_);
v___x_49_ = lean_box(1);
v___x_50_ = lean_alloc_ctor(5, 2, 0);
lean_ctor_set(v___x_50_, 0, v___x_48_);
lean_ctor_set(v___x_50_, 1, v___x_49_);
v___x_51_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instReprPoint_repr___redArg___closed__11));
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
v___x_59_ = lean_obj_once(&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instReprPoint_repr___redArg___closed__14, &lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instReprPoint_repr___redArg___closed__14_once, _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instReprPoint_repr___redArg___closed__14);
v___x_60_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instReprPoint_repr___redArg___closed__15));
v___x_61_ = lean_alloc_ctor(5, 2, 0);
lean_ctor_set(v___x_61_, 0, v___x_60_);
lean_ctor_set(v___x_61_, 1, v___x_58_);
v___x_62_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instReprPoint_repr___redArg___closed__16));
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
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instReprPoint_repr(lean_object* v_x_68_, lean_object* v_prec_69_){
_start:
{
lean_object* v___x_70_; 
v___x_70_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instReprPoint_repr___redArg(v_x_68_);
return v___x_70_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instReprPoint_repr___boxed(lean_object* v_x_71_, lean_object* v_prec_72_){
_start:
{
lean_object* v_res_73_; 
v_res_73_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instReprPoint_repr(v_x_71_, v_prec_72_);
lean_dec(v_prec_72_);
return v_res_73_;
}
}
LEAN_EXPORT uint8_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instDecidableEqPoint_decEq(lean_object* v_x_76_, lean_object* v_x_77_){
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
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instDecidableEqPoint_decEq___boxed(lean_object* v_x_84_, lean_object* v_x_85_){
_start:
{
uint8_t v_res_86_; lean_object* v_r_87_; 
v_res_86_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instDecidableEqPoint_decEq(v_x_84_, v_x_85_);
lean_dec_ref(v_x_85_);
lean_dec_ref(v_x_84_);
v_r_87_ = lean_box(v_res_86_);
return v_r_87_;
}
}
LEAN_EXPORT uint8_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instDecidableEqPoint(lean_object* v_x_88_, lean_object* v_x_89_){
_start:
{
uint8_t v___x_90_; 
v___x_90_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instDecidableEqPoint_decEq(v_x_88_, v_x_89_);
return v___x_90_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instDecidableEqPoint___boxed(lean_object* v_x_91_, lean_object* v_x_92_){
_start:
{
uint8_t v_res_93_; lean_object* v_r_94_; 
v_res_93_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instDecidableEqPoint(v_x_91_, v_x_92_);
lean_dec_ref(v_x_92_);
lean_dec_ref(v_x_91_);
v_r_94_ = lean_box(v_res_93_);
return v_r_94_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_p1_x27(void){
_start:
{
lean_object* v___x_99_; lean_object* v_y_100_; lean_object* v___x_101_; lean_object* v___x_102_; 
v___x_99_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_p1));
v_y_100_ = lean_ctor_get(v___x_99_, 1);
v___x_101_ = lean_unsigned_to_nat(10u);
lean_inc(v_y_100_);
v___x_102_ = lean_alloc_ctor(0, 2, 0);
lean_ctor_set(v___x_102_, 0, v___x_101_);
lean_ctor_set(v___x_102_, 1, v_y_100_);
return v___x_102_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_p1_x27_x27(void){
_start:
{
lean_object* v___x_103_; lean_object* v_x_104_; lean_object* v___x_105_; lean_object* v___x_106_; 
v___x_103_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_p1));
v_x_104_ = lean_ctor_get(v___x_103_, 0);
v___x_105_ = lean_unsigned_to_nat(20u);
lean_inc(v_x_104_);
v___x_106_ = lean_alloc_ctor(0, 2, 0);
lean_ctor_set(v___x_106_, 0, v_x_104_);
lean_ctor_set(v___x_106_, 1, v___x_105_);
return v___x_106_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_updated(void){
_start:
{
lean_object* v___x_114_; lean_object* v_y_115_; lean_object* v___x_116_; lean_object* v___x_117_; 
v___x_114_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_original));
v_y_115_ = lean_ctor_get(v___x_114_, 1);
v___x_116_ = lean_unsigned_to_nat(10u);
lean_inc(v_y_115_);
v___x_117_ = lean_alloc_ctor(0, 2, 0);
lean_ctor_set(v___x_117_, 0, v___x_116_);
lean_ctor_set(v___x_117_, 1, v_y_115_);
return v___x_117_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instReprColor_repr___redArg___closed__4(void){
_start:
{
lean_object* v___x_127_; lean_object* v___x_128_; 
v___x_127_ = lean_unsigned_to_nat(7u);
v___x_128_ = lean_nat_to_int(v___x_127_);
return v___x_128_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instReprColor_repr___redArg___closed__7(void){
_start:
{
lean_object* v___x_132_; lean_object* v___x_133_; 
v___x_132_ = lean_unsigned_to_nat(9u);
v___x_133_ = lean_nat_to_int(v___x_132_);
return v___x_133_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instReprColor_repr___redArg___closed__10(void){
_start:
{
lean_object* v___x_137_; lean_object* v___x_138_; 
v___x_137_ = lean_unsigned_to_nat(8u);
v___x_138_ = lean_nat_to_int(v___x_137_);
return v___x_138_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instReprColor_repr___redArg(lean_object* v_x_139_){
_start:
{
lean_object* v_red_140_; lean_object* v_green_141_; lean_object* v_blue_142_; lean_object* v___x_143_; lean_object* v___x_144_; lean_object* v___x_145_; lean_object* v___x_146_; lean_object* v___x_147_; lean_object* v___x_148_; uint8_t v___x_149_; lean_object* v___x_150_; lean_object* v___x_151_; lean_object* v___x_152_; lean_object* v___x_153_; lean_object* v___x_154_; lean_object* v___x_155_; lean_object* v___x_156_; lean_object* v___x_157_; lean_object* v___x_158_; lean_object* v___x_159_; lean_object* v___x_160_; lean_object* v___x_161_; lean_object* v___x_162_; lean_object* v___x_163_; lean_object* v___x_164_; lean_object* v___x_165_; lean_object* v___x_166_; lean_object* v___x_167_; lean_object* v___x_168_; lean_object* v___x_169_; lean_object* v___x_170_; lean_object* v___x_171_; lean_object* v___x_172_; lean_object* v___x_173_; lean_object* v___x_174_; lean_object* v___x_175_; lean_object* v___x_176_; lean_object* v___x_177_; lean_object* v___x_178_; lean_object* v___x_179_; lean_object* v___x_180_; lean_object* v___x_181_; lean_object* v___x_182_; 
v_red_140_ = lean_ctor_get(v_x_139_, 0);
lean_inc(v_red_140_);
v_green_141_ = lean_ctor_get(v_x_139_, 1);
lean_inc(v_green_141_);
v_blue_142_ = lean_ctor_get(v_x_139_, 2);
lean_inc(v_blue_142_);
lean_dec_ref(v_x_139_);
v___x_143_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instReprPoint_repr___redArg___closed__5));
v___x_144_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instReprColor_repr___redArg___closed__3));
v___x_145_ = lean_obj_once(&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instReprColor_repr___redArg___closed__4, &lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instReprColor_repr___redArg___closed__4_once, _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instReprColor_repr___redArg___closed__4);
v___x_146_ = l_Nat_reprFast(v_red_140_);
v___x_147_ = lean_alloc_ctor(3, 1, 0);
lean_ctor_set(v___x_147_, 0, v___x_146_);
v___x_148_ = lean_alloc_ctor(4, 2, 0);
lean_ctor_set(v___x_148_, 0, v___x_145_);
lean_ctor_set(v___x_148_, 1, v___x_147_);
v___x_149_ = 0;
v___x_150_ = lean_alloc_ctor(6, 1, 1);
lean_ctor_set(v___x_150_, 0, v___x_148_);
lean_ctor_set_uint8(v___x_150_, sizeof(void*)*1, v___x_149_);
v___x_151_ = lean_alloc_ctor(5, 2, 0);
lean_ctor_set(v___x_151_, 0, v___x_144_);
lean_ctor_set(v___x_151_, 1, v___x_150_);
v___x_152_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instReprPoint_repr___redArg___closed__9));
v___x_153_ = lean_alloc_ctor(5, 2, 0);
lean_ctor_set(v___x_153_, 0, v___x_151_);
lean_ctor_set(v___x_153_, 1, v___x_152_);
v___x_154_ = lean_box(1);
v___x_155_ = lean_alloc_ctor(5, 2, 0);
lean_ctor_set(v___x_155_, 0, v___x_153_);
lean_ctor_set(v___x_155_, 1, v___x_154_);
v___x_156_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instReprColor_repr___redArg___closed__6));
v___x_157_ = lean_alloc_ctor(5, 2, 0);
lean_ctor_set(v___x_157_, 0, v___x_155_);
lean_ctor_set(v___x_157_, 1, v___x_156_);
v___x_158_ = lean_alloc_ctor(5, 2, 0);
lean_ctor_set(v___x_158_, 0, v___x_157_);
lean_ctor_set(v___x_158_, 1, v___x_143_);
v___x_159_ = lean_obj_once(&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instReprColor_repr___redArg___closed__7, &lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instReprColor_repr___redArg___closed__7_once, _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instReprColor_repr___redArg___closed__7);
v___x_160_ = l_Nat_reprFast(v_green_141_);
v___x_161_ = lean_alloc_ctor(3, 1, 0);
lean_ctor_set(v___x_161_, 0, v___x_160_);
v___x_162_ = lean_alloc_ctor(4, 2, 0);
lean_ctor_set(v___x_162_, 0, v___x_159_);
lean_ctor_set(v___x_162_, 1, v___x_161_);
v___x_163_ = lean_alloc_ctor(6, 1, 1);
lean_ctor_set(v___x_163_, 0, v___x_162_);
lean_ctor_set_uint8(v___x_163_, sizeof(void*)*1, v___x_149_);
v___x_164_ = lean_alloc_ctor(5, 2, 0);
lean_ctor_set(v___x_164_, 0, v___x_158_);
lean_ctor_set(v___x_164_, 1, v___x_163_);
v___x_165_ = lean_alloc_ctor(5, 2, 0);
lean_ctor_set(v___x_165_, 0, v___x_164_);
lean_ctor_set(v___x_165_, 1, v___x_152_);
v___x_166_ = lean_alloc_ctor(5, 2, 0);
lean_ctor_set(v___x_166_, 0, v___x_165_);
lean_ctor_set(v___x_166_, 1, v___x_154_);
v___x_167_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instReprColor_repr___redArg___closed__9));
v___x_168_ = lean_alloc_ctor(5, 2, 0);
lean_ctor_set(v___x_168_, 0, v___x_166_);
lean_ctor_set(v___x_168_, 1, v___x_167_);
v___x_169_ = lean_alloc_ctor(5, 2, 0);
lean_ctor_set(v___x_169_, 0, v___x_168_);
lean_ctor_set(v___x_169_, 1, v___x_143_);
v___x_170_ = lean_obj_once(&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instReprColor_repr___redArg___closed__10, &lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instReprColor_repr___redArg___closed__10_once, _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instReprColor_repr___redArg___closed__10);
v___x_171_ = l_Nat_reprFast(v_blue_142_);
v___x_172_ = lean_alloc_ctor(3, 1, 0);
lean_ctor_set(v___x_172_, 0, v___x_171_);
v___x_173_ = lean_alloc_ctor(4, 2, 0);
lean_ctor_set(v___x_173_, 0, v___x_170_);
lean_ctor_set(v___x_173_, 1, v___x_172_);
v___x_174_ = lean_alloc_ctor(6, 1, 1);
lean_ctor_set(v___x_174_, 0, v___x_173_);
lean_ctor_set_uint8(v___x_174_, sizeof(void*)*1, v___x_149_);
v___x_175_ = lean_alloc_ctor(5, 2, 0);
lean_ctor_set(v___x_175_, 0, v___x_169_);
lean_ctor_set(v___x_175_, 1, v___x_174_);
v___x_176_ = lean_obj_once(&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instReprPoint_repr___redArg___closed__14, &lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instReprPoint_repr___redArg___closed__14_once, _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instReprPoint_repr___redArg___closed__14);
v___x_177_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instReprPoint_repr___redArg___closed__15));
v___x_178_ = lean_alloc_ctor(5, 2, 0);
lean_ctor_set(v___x_178_, 0, v___x_177_);
lean_ctor_set(v___x_178_, 1, v___x_175_);
v___x_179_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instReprPoint_repr___redArg___closed__16));
v___x_180_ = lean_alloc_ctor(5, 2, 0);
lean_ctor_set(v___x_180_, 0, v___x_178_);
lean_ctor_set(v___x_180_, 1, v___x_179_);
v___x_181_ = lean_alloc_ctor(4, 2, 0);
lean_ctor_set(v___x_181_, 0, v___x_176_);
lean_ctor_set(v___x_181_, 1, v___x_180_);
v___x_182_ = lean_alloc_ctor(6, 1, 1);
lean_ctor_set(v___x_182_, 0, v___x_181_);
lean_ctor_set_uint8(v___x_182_, sizeof(void*)*1, v___x_149_);
return v___x_182_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instReprColor_repr(lean_object* v_x_183_, lean_object* v_prec_184_){
_start:
{
lean_object* v___x_185_; 
v___x_185_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instReprColor_repr___redArg(v_x_183_);
return v___x_185_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instReprColor_repr___boxed(lean_object* v_x_186_, lean_object* v_prec_187_){
_start:
{
lean_object* v_res_188_; 
v_res_188_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instReprColor_repr(v_x_186_, v_prec_187_);
lean_dec(v_prec_187_);
return v_res_188_;
}
}
LEAN_EXPORT uint8_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instDecidableEqColor_decEq(lean_object* v_x_191_, lean_object* v_x_192_){
_start:
{
lean_object* v_red_193_; lean_object* v_green_194_; lean_object* v_blue_195_; lean_object* v_red_196_; lean_object* v_green_197_; lean_object* v_blue_198_; uint8_t v___x_199_; 
v_red_193_ = lean_ctor_get(v_x_191_, 0);
v_green_194_ = lean_ctor_get(v_x_191_, 1);
v_blue_195_ = lean_ctor_get(v_x_191_, 2);
v_red_196_ = lean_ctor_get(v_x_192_, 0);
v_green_197_ = lean_ctor_get(v_x_192_, 1);
v_blue_198_ = lean_ctor_get(v_x_192_, 2);
v___x_199_ = lean_nat_dec_eq(v_red_193_, v_red_196_);
if (v___x_199_ == 0)
{
return v___x_199_;
}
else
{
uint8_t v___x_200_; 
v___x_200_ = lean_nat_dec_eq(v_green_194_, v_green_197_);
if (v___x_200_ == 0)
{
return v___x_200_;
}
else
{
uint8_t v___x_201_; 
v___x_201_ = lean_nat_dec_eq(v_blue_195_, v_blue_198_);
return v___x_201_;
}
}
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instDecidableEqColor_decEq___boxed(lean_object* v_x_202_, lean_object* v_x_203_){
_start:
{
uint8_t v_res_204_; lean_object* v_r_205_; 
v_res_204_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instDecidableEqColor_decEq(v_x_202_, v_x_203_);
lean_dec_ref(v_x_203_);
lean_dec_ref(v_x_202_);
v_r_205_ = lean_box(v_res_204_);
return v_r_205_;
}
}
LEAN_EXPORT uint8_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instDecidableEqColor(lean_object* v_x_206_, lean_object* v_x_207_){
_start:
{
uint8_t v___x_208_; 
v___x_208_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instDecidableEqColor_decEq(v_x_206_, v_x_207_);
return v___x_208_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instDecidableEqColor___boxed(lean_object* v_x_209_, lean_object* v_x_210_){
_start:
{
uint8_t v_res_211_; lean_object* v_r_212_; 
v_res_211_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instDecidableEqColor(v_x_209_, v_x_210_);
lean_dec_ref(v_x_210_);
lean_dec_ref(v_x_209_);
v_r_212_ = lean_box(v_res_211_);
return v_r_212_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instReprColoredPoint_repr___redArg(lean_object* v_x_225_){
_start:
{
lean_object* v_point_226_; lean_object* v_color_227_; lean_object* v___x_229_; uint8_t v_isShared_230_; uint8_t v_isSharedCheck_259_; 
v_point_226_ = lean_ctor_get(v_x_225_, 0);
v_color_227_ = lean_ctor_get(v_x_225_, 1);
v_isSharedCheck_259_ = !lean_is_exclusive(v_x_225_);
if (v_isSharedCheck_259_ == 0)
{
v___x_229_ = v_x_225_;
v_isShared_230_ = v_isSharedCheck_259_;
goto v_resetjp_228_;
}
else
{
lean_inc(v_color_227_);
lean_inc(v_point_226_);
lean_dec(v_x_225_);
v___x_229_ = lean_box(0);
v_isShared_230_ = v_isSharedCheck_259_;
goto v_resetjp_228_;
}
v_resetjp_228_:
{
lean_object* v___x_231_; lean_object* v___x_232_; lean_object* v___x_233_; lean_object* v___x_234_; lean_object* v___x_236_; 
v___x_231_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instReprPoint_repr___redArg___closed__5));
v___x_232_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instReprColoredPoint_repr___redArg___closed__3));
v___x_233_ = lean_obj_once(&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instReprColor_repr___redArg___closed__7, &lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instReprColor_repr___redArg___closed__7_once, _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instReprColor_repr___redArg___closed__7);
v___x_234_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instReprPoint_repr___redArg(v_point_226_);
if (v_isShared_230_ == 0)
{
lean_ctor_set_tag(v___x_229_, 4);
lean_ctor_set(v___x_229_, 1, v___x_234_);
lean_ctor_set(v___x_229_, 0, v___x_233_);
v___x_236_ = v___x_229_;
goto v_reusejp_235_;
}
else
{
lean_object* v_reuseFailAlloc_258_; 
v_reuseFailAlloc_258_ = lean_alloc_ctor(4, 2, 0);
lean_ctor_set(v_reuseFailAlloc_258_, 0, v___x_233_);
lean_ctor_set(v_reuseFailAlloc_258_, 1, v___x_234_);
v___x_236_ = v_reuseFailAlloc_258_;
goto v_reusejp_235_;
}
v_reusejp_235_:
{
uint8_t v___x_237_; lean_object* v___x_238_; lean_object* v___x_239_; lean_object* v___x_240_; lean_object* v___x_241_; lean_object* v___x_242_; lean_object* v___x_243_; lean_object* v___x_244_; lean_object* v___x_245_; lean_object* v___x_246_; lean_object* v___x_247_; lean_object* v___x_248_; lean_object* v___x_249_; lean_object* v___x_250_; lean_object* v___x_251_; lean_object* v___x_252_; lean_object* v___x_253_; lean_object* v___x_254_; lean_object* v___x_255_; lean_object* v___x_256_; lean_object* v___x_257_; 
v___x_237_ = 0;
v___x_238_ = lean_alloc_ctor(6, 1, 1);
lean_ctor_set(v___x_238_, 0, v___x_236_);
lean_ctor_set_uint8(v___x_238_, sizeof(void*)*1, v___x_237_);
v___x_239_ = lean_alloc_ctor(5, 2, 0);
lean_ctor_set(v___x_239_, 0, v___x_232_);
lean_ctor_set(v___x_239_, 1, v___x_238_);
v___x_240_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instReprPoint_repr___redArg___closed__9));
v___x_241_ = lean_alloc_ctor(5, 2, 0);
lean_ctor_set(v___x_241_, 0, v___x_239_);
lean_ctor_set(v___x_241_, 1, v___x_240_);
v___x_242_ = lean_box(1);
v___x_243_ = lean_alloc_ctor(5, 2, 0);
lean_ctor_set(v___x_243_, 0, v___x_241_);
lean_ctor_set(v___x_243_, 1, v___x_242_);
v___x_244_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instReprColoredPoint_repr___redArg___closed__5));
v___x_245_ = lean_alloc_ctor(5, 2, 0);
lean_ctor_set(v___x_245_, 0, v___x_243_);
lean_ctor_set(v___x_245_, 1, v___x_244_);
v___x_246_ = lean_alloc_ctor(5, 2, 0);
lean_ctor_set(v___x_246_, 0, v___x_245_);
lean_ctor_set(v___x_246_, 1, v___x_231_);
v___x_247_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instReprColor_repr___redArg(v_color_227_);
v___x_248_ = lean_alloc_ctor(4, 2, 0);
lean_ctor_set(v___x_248_, 0, v___x_233_);
lean_ctor_set(v___x_248_, 1, v___x_247_);
v___x_249_ = lean_alloc_ctor(6, 1, 1);
lean_ctor_set(v___x_249_, 0, v___x_248_);
lean_ctor_set_uint8(v___x_249_, sizeof(void*)*1, v___x_237_);
v___x_250_ = lean_alloc_ctor(5, 2, 0);
lean_ctor_set(v___x_250_, 0, v___x_246_);
lean_ctor_set(v___x_250_, 1, v___x_249_);
v___x_251_ = lean_obj_once(&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instReprPoint_repr___redArg___closed__14, &lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instReprPoint_repr___redArg___closed__14_once, _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instReprPoint_repr___redArg___closed__14);
v___x_252_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instReprPoint_repr___redArg___closed__15));
v___x_253_ = lean_alloc_ctor(5, 2, 0);
lean_ctor_set(v___x_253_, 0, v___x_252_);
lean_ctor_set(v___x_253_, 1, v___x_250_);
v___x_254_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instReprPoint_repr___redArg___closed__16));
v___x_255_ = lean_alloc_ctor(5, 2, 0);
lean_ctor_set(v___x_255_, 0, v___x_253_);
lean_ctor_set(v___x_255_, 1, v___x_254_);
v___x_256_ = lean_alloc_ctor(4, 2, 0);
lean_ctor_set(v___x_256_, 0, v___x_251_);
lean_ctor_set(v___x_256_, 1, v___x_255_);
v___x_257_ = lean_alloc_ctor(6, 1, 1);
lean_ctor_set(v___x_257_, 0, v___x_256_);
lean_ctor_set_uint8(v___x_257_, sizeof(void*)*1, v___x_237_);
return v___x_257_;
}
}
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instReprColoredPoint_repr(lean_object* v_x_260_, lean_object* v_prec_261_){
_start:
{
lean_object* v___x_262_; 
v___x_262_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instReprColoredPoint_repr___redArg(v_x_260_);
return v___x_262_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instReprColoredPoint_repr___boxed(lean_object* v_x_263_, lean_object* v_prec_264_){
_start:
{
lean_object* v_res_265_; 
v_res_265_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instReprColoredPoint_repr(v_x_263_, v_prec_264_);
lean_dec(v_prec_264_);
return v_res_265_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_darkerRed(void){
_start:
{
lean_object* v___x_278_; lean_object* v_point_279_; lean_object* v___x_280_; lean_object* v___x_281_; 
v___x_278_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_redPoint));
v_point_279_ = lean_ctor_get(v___x_278_, 0);
v___x_280_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_darkerRed___closed__0));
lean_inc_ref(v_point_279_);
v___x_281_ = lean_alloc_ctor(0, 2, 0);
lean_ctor_set(v___x_281_, 0, v_point_279_);
lean_ctor_set(v___x_281_, 1, v___x_280_);
return v___x_281_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_moveRight(void){
_start:
{
lean_object* v___x_282_; lean_object* v_point_283_; lean_object* v_color_284_; lean_object* v_x_285_; lean_object* v_y_286_; lean_object* v___x_287_; lean_object* v___x_288_; lean_object* v___x_289_; lean_object* v___x_290_; 
v___x_282_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_redPoint));
v_point_283_ = lean_ctor_get(v___x_282_, 0);
v_color_284_ = lean_ctor_get(v___x_282_, 1);
v_x_285_ = lean_ctor_get(v_point_283_, 0);
v_y_286_ = lean_ctor_get(v_point_283_, 1);
v___x_287_ = lean_unsigned_to_nat(10u);
v___x_288_ = lean_nat_add(v_x_285_, v___x_287_);
lean_inc(v_y_286_);
v___x_289_ = lean_alloc_ctor(0, 2, 0);
lean_ctor_set(v___x_289_, 0, v___x_288_);
lean_ctor_set(v___x_289_, 1, v_y_286_);
lean_inc_ref(v_color_284_);
v___x_290_ = lean_alloc_ctor(0, 2, 0);
lean_ctor_set(v___x_290_, 0, v___x_289_);
lean_ctor_set(v___x_290_, 1, v_color_284_);
return v___x_290_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_moveAndRecolor(void){
_start:
{
lean_object* v___x_294_; lean_object* v_point_295_; lean_object* v_y_296_; lean_object* v___x_297_; lean_object* v___x_298_; lean_object* v___x_299_; lean_object* v___x_300_; 
v___x_294_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_redPoint));
v_point_295_ = lean_ctor_get(v___x_294_, 0);
v_y_296_ = lean_ctor_get(v_point_295_, 1);
v___x_297_ = lean_unsigned_to_nat(100u);
lean_inc(v_y_296_);
v___x_298_ = lean_alloc_ctor(0, 2, 0);
lean_ctor_set(v___x_298_, 0, v___x_297_);
lean_ctor_set(v___x_298_, 1, v_y_296_);
v___x_299_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_moveAndRecolor___closed__0));
v___x_300_ = lean_alloc_ctor(0, 2, 0);
lean_ctor_set(v___x_300_, 0, v___x_298_);
lean_ctor_set(v___x_300_, 1, v___x_299_);
return v___x_300_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instReprPoint3D_repr___redArg___closed__4(void){
_start:
{
lean_object* v___x_310_; lean_object* v___x_311_; 
v___x_310_ = lean_unsigned_to_nat(11u);
v___x_311_ = lean_nat_to_int(v___x_310_);
return v___x_311_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instReprPoint3D_repr___redArg(lean_object* v_x_315_){
_start:
{
lean_object* v_toPoint_316_; lean_object* v_z_317_; lean_object* v___x_319_; uint8_t v_isShared_320_; uint8_t v_isSharedCheck_351_; 
v_toPoint_316_ = lean_ctor_get(v_x_315_, 0);
v_z_317_ = lean_ctor_get(v_x_315_, 1);
v_isSharedCheck_351_ = !lean_is_exclusive(v_x_315_);
if (v_isSharedCheck_351_ == 0)
{
v___x_319_ = v_x_315_;
v_isShared_320_ = v_isSharedCheck_351_;
goto v_resetjp_318_;
}
else
{
lean_inc(v_z_317_);
lean_inc(v_toPoint_316_);
lean_dec(v_x_315_);
v___x_319_ = lean_box(0);
v_isShared_320_ = v_isSharedCheck_351_;
goto v_resetjp_318_;
}
v_resetjp_318_:
{
lean_object* v___x_321_; lean_object* v___x_322_; lean_object* v___x_323_; lean_object* v___x_324_; lean_object* v___x_326_; 
v___x_321_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instReprPoint_repr___redArg___closed__5));
v___x_322_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instReprPoint3D_repr___redArg___closed__3));
v___x_323_ = lean_obj_once(&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instReprPoint3D_repr___redArg___closed__4, &lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instReprPoint3D_repr___redArg___closed__4_once, _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instReprPoint3D_repr___redArg___closed__4);
v___x_324_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instReprPoint_repr___redArg(v_toPoint_316_);
if (v_isShared_320_ == 0)
{
lean_ctor_set_tag(v___x_319_, 4);
lean_ctor_set(v___x_319_, 1, v___x_324_);
lean_ctor_set(v___x_319_, 0, v___x_323_);
v___x_326_ = v___x_319_;
goto v_reusejp_325_;
}
else
{
lean_object* v_reuseFailAlloc_350_; 
v_reuseFailAlloc_350_ = lean_alloc_ctor(4, 2, 0);
lean_ctor_set(v_reuseFailAlloc_350_, 0, v___x_323_);
lean_ctor_set(v_reuseFailAlloc_350_, 1, v___x_324_);
v___x_326_ = v_reuseFailAlloc_350_;
goto v_reusejp_325_;
}
v_reusejp_325_:
{
uint8_t v___x_327_; lean_object* v___x_328_; lean_object* v___x_329_; lean_object* v___x_330_; lean_object* v___x_331_; lean_object* v___x_332_; lean_object* v___x_333_; lean_object* v___x_334_; lean_object* v___x_335_; lean_object* v___x_336_; lean_object* v___x_337_; lean_object* v___x_338_; lean_object* v___x_339_; lean_object* v___x_340_; lean_object* v___x_341_; lean_object* v___x_342_; lean_object* v___x_343_; lean_object* v___x_344_; lean_object* v___x_345_; lean_object* v___x_346_; lean_object* v___x_347_; lean_object* v___x_348_; lean_object* v___x_349_; 
v___x_327_ = 0;
v___x_328_ = lean_alloc_ctor(6, 1, 1);
lean_ctor_set(v___x_328_, 0, v___x_326_);
lean_ctor_set_uint8(v___x_328_, sizeof(void*)*1, v___x_327_);
v___x_329_ = lean_alloc_ctor(5, 2, 0);
lean_ctor_set(v___x_329_, 0, v___x_322_);
lean_ctor_set(v___x_329_, 1, v___x_328_);
v___x_330_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instReprPoint_repr___redArg___closed__9));
v___x_331_ = lean_alloc_ctor(5, 2, 0);
lean_ctor_set(v___x_331_, 0, v___x_329_);
lean_ctor_set(v___x_331_, 1, v___x_330_);
v___x_332_ = lean_box(1);
v___x_333_ = lean_alloc_ctor(5, 2, 0);
lean_ctor_set(v___x_333_, 0, v___x_331_);
lean_ctor_set(v___x_333_, 1, v___x_332_);
v___x_334_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instReprPoint3D_repr___redArg___closed__6));
v___x_335_ = lean_alloc_ctor(5, 2, 0);
lean_ctor_set(v___x_335_, 0, v___x_333_);
lean_ctor_set(v___x_335_, 1, v___x_334_);
v___x_336_ = lean_alloc_ctor(5, 2, 0);
lean_ctor_set(v___x_336_, 0, v___x_335_);
lean_ctor_set(v___x_336_, 1, v___x_321_);
v___x_337_ = lean_obj_once(&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instReprPoint_repr___redArg___closed__7, &lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instReprPoint_repr___redArg___closed__7_once, _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instReprPoint_repr___redArg___closed__7);
v___x_338_ = l_Nat_reprFast(v_z_317_);
v___x_339_ = lean_alloc_ctor(3, 1, 0);
lean_ctor_set(v___x_339_, 0, v___x_338_);
v___x_340_ = lean_alloc_ctor(4, 2, 0);
lean_ctor_set(v___x_340_, 0, v___x_337_);
lean_ctor_set(v___x_340_, 1, v___x_339_);
v___x_341_ = lean_alloc_ctor(6, 1, 1);
lean_ctor_set(v___x_341_, 0, v___x_340_);
lean_ctor_set_uint8(v___x_341_, sizeof(void*)*1, v___x_327_);
v___x_342_ = lean_alloc_ctor(5, 2, 0);
lean_ctor_set(v___x_342_, 0, v___x_336_);
lean_ctor_set(v___x_342_, 1, v___x_341_);
v___x_343_ = lean_obj_once(&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instReprPoint_repr___redArg___closed__14, &lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instReprPoint_repr___redArg___closed__14_once, _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instReprPoint_repr___redArg___closed__14);
v___x_344_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instReprPoint_repr___redArg___closed__15));
v___x_345_ = lean_alloc_ctor(5, 2, 0);
lean_ctor_set(v___x_345_, 0, v___x_344_);
lean_ctor_set(v___x_345_, 1, v___x_342_);
v___x_346_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instReprPoint_repr___redArg___closed__16));
v___x_347_ = lean_alloc_ctor(5, 2, 0);
lean_ctor_set(v___x_347_, 0, v___x_345_);
lean_ctor_set(v___x_347_, 1, v___x_346_);
v___x_348_ = lean_alloc_ctor(4, 2, 0);
lean_ctor_set(v___x_348_, 0, v___x_343_);
lean_ctor_set(v___x_348_, 1, v___x_347_);
v___x_349_ = lean_alloc_ctor(6, 1, 1);
lean_ctor_set(v___x_349_, 0, v___x_348_);
lean_ctor_set_uint8(v___x_349_, sizeof(void*)*1, v___x_327_);
return v___x_349_;
}
}
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instReprPoint3D_repr(lean_object* v_x_352_, lean_object* v_prec_353_){
_start:
{
lean_object* v___x_354_; 
v___x_354_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instReprPoint3D_repr___redArg(v_x_352_);
return v___x_354_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instReprPoint3D_repr___boxed(lean_object* v_x_355_, lean_object* v_prec_356_){
_start:
{
lean_object* v_res_357_; 
v_res_357_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instReprPoint3D_repr(v_x_355_, v_prec_356_);
lean_dec(v_prec_356_);
return v_res_357_;
}
}
LEAN_EXPORT uint8_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instDecidableEqPoint3D_decEq(lean_object* v_x_360_, lean_object* v_x_361_){
_start:
{
lean_object* v_toPoint_362_; lean_object* v_z_363_; lean_object* v_toPoint_364_; lean_object* v_z_365_; uint8_t v___x_366_; 
v_toPoint_362_ = lean_ctor_get(v_x_360_, 0);
v_z_363_ = lean_ctor_get(v_x_360_, 1);
v_toPoint_364_ = lean_ctor_get(v_x_361_, 0);
v_z_365_ = lean_ctor_get(v_x_361_, 1);
v___x_366_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instDecidableEqPoint_decEq(v_toPoint_362_, v_toPoint_364_);
if (v___x_366_ == 0)
{
return v___x_366_;
}
else
{
uint8_t v___x_367_; 
v___x_367_ = lean_nat_dec_eq(v_z_363_, v_z_365_);
return v___x_367_;
}
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instDecidableEqPoint3D_decEq___boxed(lean_object* v_x_368_, lean_object* v_x_369_){
_start:
{
uint8_t v_res_370_; lean_object* v_r_371_; 
v_res_370_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instDecidableEqPoint3D_decEq(v_x_368_, v_x_369_);
lean_dec_ref(v_x_369_);
lean_dec_ref(v_x_368_);
v_r_371_ = lean_box(v_res_370_);
return v_r_371_;
}
}
LEAN_EXPORT uint8_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instDecidableEqPoint3D(lean_object* v_x_372_, lean_object* v_x_373_){
_start:
{
uint8_t v___x_374_; 
v___x_374_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instDecidableEqPoint3D_decEq(v_x_372_, v_x_373_);
return v___x_374_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instDecidableEqPoint3D___boxed(lean_object* v_x_375_, lean_object* v_x_376_){
_start:
{
uint8_t v_res_377_; lean_object* v_r_378_; 
v_res_377_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instDecidableEqPoint3D(v_x_375_, v_x_376_);
lean_dec_ref(v_x_376_);
lean_dec_ref(v_x_375_);
v_r_378_ = lean_box(v_res_377_);
return v_r_378_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_p3d__x(void){
_start:
{
lean_object* v___x_384_; lean_object* v_toPoint_385_; lean_object* v_x_386_; 
v___x_384_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_p3d1));
v_toPoint_385_ = lean_ctor_get(v___x_384_, 0);
v_x_386_ = lean_ctor_get(v_toPoint_385_, 0);
lean_inc(v_x_386_);
return v_x_386_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_p3d__y(void){
_start:
{
lean_object* v___x_387_; lean_object* v_toPoint_388_; lean_object* v_y_389_; 
v___x_387_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_p3d1));
v_toPoint_388_ = lean_ctor_get(v___x_387_, 0);
v_y_389_ = lean_ctor_get(v_toPoint_388_, 1);
lean_inc(v_y_389_);
return v_y_389_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_p3d__z(void){
_start:
{
lean_object* v___x_390_; lean_object* v_z_391_; 
v___x_390_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_p3d1));
v_z_391_ = lean_ctor_get(v___x_390_, 1);
lean_inc(v_z_391_);
return v_z_391_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_p3d__point(void){
_start:
{
lean_object* v___x_392_; lean_object* v_toPoint_393_; 
v___x_392_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_p3d1));
v_toPoint_393_ = lean_ctor_get(v___x_392_, 0);
lean_inc_ref(v_toPoint_393_);
return v_toPoint_393_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_p3d1_x27(void){
_start:
{
lean_object* v___x_394_; lean_object* v_toPoint_395_; lean_object* v_z_396_; lean_object* v_y_397_; lean_object* v___x_398_; lean_object* v___x_399_; lean_object* v___x_400_; 
v___x_394_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_p3d1));
v_toPoint_395_ = lean_ctor_get(v___x_394_, 0);
v_z_396_ = lean_ctor_get(v___x_394_, 1);
v_y_397_ = lean_ctor_get(v_toPoint_395_, 1);
v___x_398_ = lean_unsigned_to_nat(10u);
lean_inc(v_y_397_);
v___x_399_ = lean_alloc_ctor(0, 2, 0);
lean_ctor_set(v___x_399_, 0, v___x_398_);
lean_ctor_set(v___x_399_, 1, v_y_397_);
lean_inc(v_z_396_);
v___x_400_ = lean_alloc_ctor(0, 2, 0);
lean_ctor_set(v___x_400_, 0, v___x_399_);
lean_ctor_set(v___x_400_, 1, v_z_396_);
return v___x_400_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_p3d1_x27_x27(void){
_start:
{
lean_object* v___x_401_; lean_object* v_toPoint_402_; lean_object* v___x_403_; lean_object* v___x_404_; 
v___x_401_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_p3d1));
v_toPoint_402_ = lean_ctor_get(v___x_401_, 0);
v___x_403_ = lean_unsigned_to_nat(30u);
lean_inc_ref(v_toPoint_402_);
v___x_404_ = lean_alloc_ctor(0, 2, 0);
lean_ctor_set(v___x_404_, 0, v_toPoint_402_);
lean_ctor_set(v___x_404_, 1, v___x_403_);
return v___x_404_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instReprNamedPoint3D_repr___redArg___closed__4(void){
_start:
{
lean_object* v___x_418_; lean_object* v___x_419_; 
v___x_418_ = lean_unsigned_to_nat(13u);
v___x_419_ = lean_nat_to_int(v___x_418_);
return v___x_419_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instReprNamedPoint3D_repr___redArg(lean_object* v_x_423_){
_start:
{
lean_object* v_toPoint3D_424_; lean_object* v_name_425_; lean_object* v___x_427_; uint8_t v_isShared_428_; uint8_t v_isSharedCheck_459_; 
v_toPoint3D_424_ = lean_ctor_get(v_x_423_, 0);
v_name_425_ = lean_ctor_get(v_x_423_, 1);
v_isSharedCheck_459_ = !lean_is_exclusive(v_x_423_);
if (v_isSharedCheck_459_ == 0)
{
v___x_427_ = v_x_423_;
v_isShared_428_ = v_isSharedCheck_459_;
goto v_resetjp_426_;
}
else
{
lean_inc(v_name_425_);
lean_inc(v_toPoint3D_424_);
lean_dec(v_x_423_);
v___x_427_ = lean_box(0);
v_isShared_428_ = v_isSharedCheck_459_;
goto v_resetjp_426_;
}
v_resetjp_426_:
{
lean_object* v___x_429_; lean_object* v___x_430_; lean_object* v___x_431_; lean_object* v___x_432_; lean_object* v___x_434_; 
v___x_429_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instReprPoint_repr___redArg___closed__5));
v___x_430_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instReprNamedPoint3D_repr___redArg___closed__3));
v___x_431_ = lean_obj_once(&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instReprNamedPoint3D_repr___redArg___closed__4, &lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instReprNamedPoint3D_repr___redArg___closed__4_once, _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instReprNamedPoint3D_repr___redArg___closed__4);
v___x_432_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instReprPoint3D_repr___redArg(v_toPoint3D_424_);
if (v_isShared_428_ == 0)
{
lean_ctor_set_tag(v___x_427_, 4);
lean_ctor_set(v___x_427_, 1, v___x_432_);
lean_ctor_set(v___x_427_, 0, v___x_431_);
v___x_434_ = v___x_427_;
goto v_reusejp_433_;
}
else
{
lean_object* v_reuseFailAlloc_458_; 
v_reuseFailAlloc_458_ = lean_alloc_ctor(4, 2, 0);
lean_ctor_set(v_reuseFailAlloc_458_, 0, v___x_431_);
lean_ctor_set(v_reuseFailAlloc_458_, 1, v___x_432_);
v___x_434_ = v_reuseFailAlloc_458_;
goto v_reusejp_433_;
}
v_reusejp_433_:
{
uint8_t v___x_435_; lean_object* v___x_436_; lean_object* v___x_437_; lean_object* v___x_438_; lean_object* v___x_439_; lean_object* v___x_440_; lean_object* v___x_441_; lean_object* v___x_442_; lean_object* v___x_443_; lean_object* v___x_444_; lean_object* v___x_445_; lean_object* v___x_446_; lean_object* v___x_447_; lean_object* v___x_448_; lean_object* v___x_449_; lean_object* v___x_450_; lean_object* v___x_451_; lean_object* v___x_452_; lean_object* v___x_453_; lean_object* v___x_454_; lean_object* v___x_455_; lean_object* v___x_456_; lean_object* v___x_457_; 
v___x_435_ = 0;
v___x_436_ = lean_alloc_ctor(6, 1, 1);
lean_ctor_set(v___x_436_, 0, v___x_434_);
lean_ctor_set_uint8(v___x_436_, sizeof(void*)*1, v___x_435_);
v___x_437_ = lean_alloc_ctor(5, 2, 0);
lean_ctor_set(v___x_437_, 0, v___x_430_);
lean_ctor_set(v___x_437_, 1, v___x_436_);
v___x_438_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instReprPoint_repr___redArg___closed__9));
v___x_439_ = lean_alloc_ctor(5, 2, 0);
lean_ctor_set(v___x_439_, 0, v___x_437_);
lean_ctor_set(v___x_439_, 1, v___x_438_);
v___x_440_ = lean_box(1);
v___x_441_ = lean_alloc_ctor(5, 2, 0);
lean_ctor_set(v___x_441_, 0, v___x_439_);
lean_ctor_set(v___x_441_, 1, v___x_440_);
v___x_442_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instReprNamedPoint3D_repr___redArg___closed__6));
v___x_443_ = lean_alloc_ctor(5, 2, 0);
lean_ctor_set(v___x_443_, 0, v___x_441_);
lean_ctor_set(v___x_443_, 1, v___x_442_);
v___x_444_ = lean_alloc_ctor(5, 2, 0);
lean_ctor_set(v___x_444_, 0, v___x_443_);
lean_ctor_set(v___x_444_, 1, v___x_429_);
v___x_445_ = lean_obj_once(&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instReprColor_repr___redArg___closed__10, &lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instReprColor_repr___redArg___closed__10_once, _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instReprColor_repr___redArg___closed__10);
v___x_446_ = l_String_quote(v_name_425_);
v___x_447_ = lean_alloc_ctor(3, 1, 0);
lean_ctor_set(v___x_447_, 0, v___x_446_);
v___x_448_ = lean_alloc_ctor(4, 2, 0);
lean_ctor_set(v___x_448_, 0, v___x_445_);
lean_ctor_set(v___x_448_, 1, v___x_447_);
v___x_449_ = lean_alloc_ctor(6, 1, 1);
lean_ctor_set(v___x_449_, 0, v___x_448_);
lean_ctor_set_uint8(v___x_449_, sizeof(void*)*1, v___x_435_);
v___x_450_ = lean_alloc_ctor(5, 2, 0);
lean_ctor_set(v___x_450_, 0, v___x_444_);
lean_ctor_set(v___x_450_, 1, v___x_449_);
v___x_451_ = lean_obj_once(&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instReprPoint_repr___redArg___closed__14, &lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instReprPoint_repr___redArg___closed__14_once, _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instReprPoint_repr___redArg___closed__14);
v___x_452_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instReprPoint_repr___redArg___closed__15));
v___x_453_ = lean_alloc_ctor(5, 2, 0);
lean_ctor_set(v___x_453_, 0, v___x_452_);
lean_ctor_set(v___x_453_, 1, v___x_450_);
v___x_454_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instReprPoint_repr___redArg___closed__16));
v___x_455_ = lean_alloc_ctor(5, 2, 0);
lean_ctor_set(v___x_455_, 0, v___x_453_);
lean_ctor_set(v___x_455_, 1, v___x_454_);
v___x_456_ = lean_alloc_ctor(4, 2, 0);
lean_ctor_set(v___x_456_, 0, v___x_451_);
lean_ctor_set(v___x_456_, 1, v___x_455_);
v___x_457_ = lean_alloc_ctor(6, 1, 1);
lean_ctor_set(v___x_457_, 0, v___x_456_);
lean_ctor_set_uint8(v___x_457_, sizeof(void*)*1, v___x_435_);
return v___x_457_;
}
}
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instReprNamedPoint3D_repr(lean_object* v_x_460_, lean_object* v_prec_461_){
_start:
{
lean_object* v___x_462_; 
v___x_462_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instReprNamedPoint3D_repr___redArg(v_x_460_);
return v___x_462_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instReprNamedPoint3D_repr___boxed(lean_object* v_x_463_, lean_object* v_prec_464_){
_start:
{
lean_object* v_res_465_; 
v_res_465_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instReprNamedPoint3D_repr(v_x_463_, v_prec_464_);
lean_dec(v_prec_464_);
return v_res_465_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_np3d__name(void){
_start:
{
lean_object* v___x_473_; lean_object* v_name_474_; 
v___x_473_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_np3d));
v_name_474_ = lean_ctor_get(v___x_473_, 1);
lean_inc_ref(v_name_474_);
return v_name_474_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_np3d__x(void){
_start:
{
lean_object* v___x_475_; lean_object* v_toPoint3D_476_; lean_object* v_toPoint_477_; lean_object* v_x_478_; 
v___x_475_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_np3d));
v_toPoint3D_476_ = lean_ctor_get(v___x_475_, 0);
v_toPoint_477_ = lean_ctor_get(v_toPoint3D_476_, 0);
v_x_478_ = lean_ctor_get(v_toPoint_477_, 0);
lean_inc(v_x_478_);
return v_x_478_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_np3d__z(void){
_start:
{
lean_object* v___x_479_; lean_object* v_toPoint3D_480_; lean_object* v_z_481_; 
v___x_479_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_np3d));
v_toPoint3D_480_ = lean_ctor_get(v___x_479_, 0);
v_z_481_ = lean_ctor_get(v_toPoint3D_480_, 1);
lean_inc(v_z_481_);
return v_z_481_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_np3d__to__p3d(void){
_start:
{
lean_object* v___x_482_; lean_object* v_toPoint3D_483_; 
v___x_482_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_np3d));
v_toPoint3D_483_ = lean_ctor_get(v___x_482_, 0);
lean_inc_ref(v_toPoint3D_483_);
return v_toPoint3D_483_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_np3d__to__point(void){
_start:
{
lean_object* v___x_484_; lean_object* v_toPoint3D_485_; lean_object* v_toPoint_486_; 
v___x_484_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_np3d));
v_toPoint3D_485_ = lean_ctor_get(v___x_484_, 0);
v_toPoint_486_ = lean_ctor_get(v_toPoint3D_485_, 0);
lean_inc_ref(v_toPoint_486_);
return v_toPoint_486_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instReprColoredPoint_x27_repr___redArg(lean_object* v_x_487_){
_start:
{
lean_object* v_toPoint_488_; lean_object* v_color_489_; lean_object* v___x_491_; uint8_t v_isShared_492_; uint8_t v_isSharedCheck_522_; 
v_toPoint_488_ = lean_ctor_get(v_x_487_, 0);
v_color_489_ = lean_ctor_get(v_x_487_, 1);
v_isSharedCheck_522_ = !lean_is_exclusive(v_x_487_);
if (v_isSharedCheck_522_ == 0)
{
v___x_491_ = v_x_487_;
v_isShared_492_ = v_isSharedCheck_522_;
goto v_resetjp_490_;
}
else
{
lean_inc(v_color_489_);
lean_inc(v_toPoint_488_);
lean_dec(v_x_487_);
v___x_491_ = lean_box(0);
v_isShared_492_ = v_isSharedCheck_522_;
goto v_resetjp_490_;
}
v_resetjp_490_:
{
lean_object* v___x_493_; lean_object* v___x_494_; lean_object* v___x_495_; lean_object* v___x_496_; lean_object* v___x_498_; 
v___x_493_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instReprPoint_repr___redArg___closed__5));
v___x_494_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instReprPoint3D_repr___redArg___closed__3));
v___x_495_ = lean_obj_once(&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instReprPoint3D_repr___redArg___closed__4, &lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instReprPoint3D_repr___redArg___closed__4_once, _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instReprPoint3D_repr___redArg___closed__4);
v___x_496_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instReprPoint_repr___redArg(v_toPoint_488_);
if (v_isShared_492_ == 0)
{
lean_ctor_set_tag(v___x_491_, 4);
lean_ctor_set(v___x_491_, 1, v___x_496_);
lean_ctor_set(v___x_491_, 0, v___x_495_);
v___x_498_ = v___x_491_;
goto v_reusejp_497_;
}
else
{
lean_object* v_reuseFailAlloc_521_; 
v_reuseFailAlloc_521_ = lean_alloc_ctor(4, 2, 0);
lean_ctor_set(v_reuseFailAlloc_521_, 0, v___x_495_);
lean_ctor_set(v_reuseFailAlloc_521_, 1, v___x_496_);
v___x_498_ = v_reuseFailAlloc_521_;
goto v_reusejp_497_;
}
v_reusejp_497_:
{
uint8_t v___x_499_; lean_object* v___x_500_; lean_object* v___x_501_; lean_object* v___x_502_; lean_object* v___x_503_; lean_object* v___x_504_; lean_object* v___x_505_; lean_object* v___x_506_; lean_object* v___x_507_; lean_object* v___x_508_; lean_object* v___x_509_; lean_object* v___x_510_; lean_object* v___x_511_; lean_object* v___x_512_; lean_object* v___x_513_; lean_object* v___x_514_; lean_object* v___x_515_; lean_object* v___x_516_; lean_object* v___x_517_; lean_object* v___x_518_; lean_object* v___x_519_; lean_object* v___x_520_; 
v___x_499_ = 0;
v___x_500_ = lean_alloc_ctor(6, 1, 1);
lean_ctor_set(v___x_500_, 0, v___x_498_);
lean_ctor_set_uint8(v___x_500_, sizeof(void*)*1, v___x_499_);
v___x_501_ = lean_alloc_ctor(5, 2, 0);
lean_ctor_set(v___x_501_, 0, v___x_494_);
lean_ctor_set(v___x_501_, 1, v___x_500_);
v___x_502_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instReprPoint_repr___redArg___closed__9));
v___x_503_ = lean_alloc_ctor(5, 2, 0);
lean_ctor_set(v___x_503_, 0, v___x_501_);
lean_ctor_set(v___x_503_, 1, v___x_502_);
v___x_504_ = lean_box(1);
v___x_505_ = lean_alloc_ctor(5, 2, 0);
lean_ctor_set(v___x_505_, 0, v___x_503_);
lean_ctor_set(v___x_505_, 1, v___x_504_);
v___x_506_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instReprColoredPoint_repr___redArg___closed__5));
v___x_507_ = lean_alloc_ctor(5, 2, 0);
lean_ctor_set(v___x_507_, 0, v___x_505_);
lean_ctor_set(v___x_507_, 1, v___x_506_);
v___x_508_ = lean_alloc_ctor(5, 2, 0);
lean_ctor_set(v___x_508_, 0, v___x_507_);
lean_ctor_set(v___x_508_, 1, v___x_493_);
v___x_509_ = lean_obj_once(&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instReprColor_repr___redArg___closed__7, &lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instReprColor_repr___redArg___closed__7_once, _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instReprColor_repr___redArg___closed__7);
v___x_510_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instReprColor_repr___redArg(v_color_489_);
v___x_511_ = lean_alloc_ctor(4, 2, 0);
lean_ctor_set(v___x_511_, 0, v___x_509_);
lean_ctor_set(v___x_511_, 1, v___x_510_);
v___x_512_ = lean_alloc_ctor(6, 1, 1);
lean_ctor_set(v___x_512_, 0, v___x_511_);
lean_ctor_set_uint8(v___x_512_, sizeof(void*)*1, v___x_499_);
v___x_513_ = lean_alloc_ctor(5, 2, 0);
lean_ctor_set(v___x_513_, 0, v___x_508_);
lean_ctor_set(v___x_513_, 1, v___x_512_);
v___x_514_ = lean_obj_once(&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instReprPoint_repr___redArg___closed__14, &lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instReprPoint_repr___redArg___closed__14_once, _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instReprPoint_repr___redArg___closed__14);
v___x_515_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instReprPoint_repr___redArg___closed__15));
v___x_516_ = lean_alloc_ctor(5, 2, 0);
lean_ctor_set(v___x_516_, 0, v___x_515_);
lean_ctor_set(v___x_516_, 1, v___x_513_);
v___x_517_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instReprPoint_repr___redArg___closed__16));
v___x_518_ = lean_alloc_ctor(5, 2, 0);
lean_ctor_set(v___x_518_, 0, v___x_516_);
lean_ctor_set(v___x_518_, 1, v___x_517_);
v___x_519_ = lean_alloc_ctor(4, 2, 0);
lean_ctor_set(v___x_519_, 0, v___x_514_);
lean_ctor_set(v___x_519_, 1, v___x_518_);
v___x_520_ = lean_alloc_ctor(6, 1, 1);
lean_ctor_set(v___x_520_, 0, v___x_519_);
lean_ctor_set_uint8(v___x_520_, sizeof(void*)*1, v___x_499_);
return v___x_520_;
}
}
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instReprColoredPoint_x27_repr(lean_object* v_x_523_, lean_object* v_prec_524_){
_start:
{
lean_object* v___x_525_; 
v___x_525_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instReprColoredPoint_x27_repr___redArg(v_x_523_);
return v___x_525_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instReprColoredPoint_x27_repr___boxed(lean_object* v_x_526_, lean_object* v_prec_527_){
_start:
{
lean_object* v_res_528_; 
v_res_528_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instReprColoredPoint_x27_repr(v_x_526_, v_prec_527_);
lean_dec(v_prec_527_);
return v_res_528_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_rp__x(void){
_start:
{
lean_object* v___x_535_; lean_object* v_toPoint_536_; lean_object* v_x_537_; 
v___x_535_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_redPoint_x27));
v_toPoint_536_ = lean_ctor_get(v___x_535_, 0);
v_x_537_ = lean_ctor_get(v_toPoint_536_, 0);
lean_inc(v_x_537_);
return v_x_537_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_rp__y(void){
_start:
{
lean_object* v___x_538_; lean_object* v_toPoint_539_; lean_object* v_y_540_; 
v___x_538_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_redPoint_x27));
v_toPoint_539_ = lean_ctor_get(v___x_538_, 0);
v_y_540_ = lean_ctor_get(v_toPoint_539_, 1);
lean_inc(v_y_540_);
return v_y_540_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_rp__color(void){
_start:
{
lean_object* v___x_541_; lean_object* v_color_542_; 
v___x_541_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_redPoint_x27));
v_color_542_ = lean_ctor_get(v___x_541_, 1);
lean_inc_ref(v_color_542_);
return v_color_542_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_greenPoint_x27(void){
_start:
{
lean_object* v___x_543_; lean_object* v_toPoint_544_; lean_object* v_y_545_; lean_object* v___x_546_; lean_object* v___x_547_; lean_object* v___x_548_; lean_object* v___x_549_; 
v___x_543_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_redPoint_x27));
v_toPoint_544_ = lean_ctor_get(v___x_543_, 0);
v_y_545_ = lean_ctor_get(v_toPoint_544_, 1);
v___x_546_ = lean_unsigned_to_nat(100u);
lean_inc(v_y_545_);
v___x_547_ = lean_alloc_ctor(0, 2, 0);
lean_ctor_set(v___x_547_, 0, v___x_546_);
lean_ctor_set(v___x_547_, 1, v_y_545_);
v___x_548_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_moveAndRecolor___closed__0));
v___x_549_ = lean_alloc_ctor(0, 2, 0);
lean_ctor_set(v___x_549_, 0, v___x_547_);
lean_ctor_set(v___x_549_, 1, v___x_548_);
return v___x_549_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instAddPoint___lam__0(lean_object* v_p1_550_, lean_object* v_p2_551_){
_start:
{
lean_object* v_x_552_; lean_object* v_y_553_; lean_object* v_x_554_; lean_object* v_y_555_; lean_object* v___x_557_; uint8_t v_isShared_558_; uint8_t v_isSharedCheck_564_; 
v_x_552_ = lean_ctor_get(v_p1_550_, 0);
v_y_553_ = lean_ctor_get(v_p1_550_, 1);
v_x_554_ = lean_ctor_get(v_p2_551_, 0);
v_y_555_ = lean_ctor_get(v_p2_551_, 1);
v_isSharedCheck_564_ = !lean_is_exclusive(v_p2_551_);
if (v_isSharedCheck_564_ == 0)
{
v___x_557_ = v_p2_551_;
v_isShared_558_ = v_isSharedCheck_564_;
goto v_resetjp_556_;
}
else
{
lean_inc(v_y_555_);
lean_inc(v_x_554_);
lean_dec(v_p2_551_);
v___x_557_ = lean_box(0);
v_isShared_558_ = v_isSharedCheck_564_;
goto v_resetjp_556_;
}
v_resetjp_556_:
{
lean_object* v___x_559_; lean_object* v___x_560_; lean_object* v___x_562_; 
v___x_559_ = lean_nat_add(v_x_552_, v_x_554_);
lean_dec(v_x_554_);
v___x_560_ = lean_nat_add(v_y_553_, v_y_555_);
lean_dec(v_y_555_);
if (v_isShared_558_ == 0)
{
lean_ctor_set(v___x_557_, 1, v___x_560_);
lean_ctor_set(v___x_557_, 0, v___x_559_);
v___x_562_ = v___x_557_;
goto v_reusejp_561_;
}
else
{
lean_object* v_reuseFailAlloc_563_; 
v_reuseFailAlloc_563_ = lean_alloc_ctor(0, 2, 0);
lean_ctor_set(v_reuseFailAlloc_563_, 0, v___x_559_);
lean_ctor_set(v_reuseFailAlloc_563_, 1, v___x_560_);
v___x_562_ = v_reuseFailAlloc_563_;
goto v_reusejp_561_;
}
v_reusejp_561_:
{
return v___x_562_;
}
}
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instAddPoint___lam__0___boxed(lean_object* v_p1_565_, lean_object* v_p2_566_){
_start:
{
lean_object* v_res_567_; 
v_res_567_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instAddPoint___lam__0(v_p1_565_, v_p2_566_);
lean_dec_ref(v_p1_565_);
return v_res_567_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instAddPoint3D___lam__0(lean_object* v_p1_573_, lean_object* v_p2_574_){
_start:
{
lean_object* v_toPoint_575_; lean_object* v_toPoint_576_; lean_object* v_z_577_; lean_object* v_x_578_; lean_object* v_y_579_; lean_object* v_z_580_; lean_object* v___x_582_; uint8_t v_isShared_583_; uint8_t v_isSharedCheck_599_; 
v_toPoint_575_ = lean_ctor_get(v_p1_573_, 0);
v_toPoint_576_ = lean_ctor_get(v_p2_574_, 0);
lean_inc_ref(v_toPoint_576_);
v_z_577_ = lean_ctor_get(v_p1_573_, 1);
v_x_578_ = lean_ctor_get(v_toPoint_575_, 0);
v_y_579_ = lean_ctor_get(v_toPoint_575_, 1);
v_z_580_ = lean_ctor_get(v_p2_574_, 1);
v_isSharedCheck_599_ = !lean_is_exclusive(v_p2_574_);
if (v_isSharedCheck_599_ == 0)
{
lean_object* v_unused_600_; 
v_unused_600_ = lean_ctor_get(v_p2_574_, 0);
lean_dec(v_unused_600_);
v___x_582_ = v_p2_574_;
v_isShared_583_ = v_isSharedCheck_599_;
goto v_resetjp_581_;
}
else
{
lean_inc(v_z_580_);
lean_dec(v_p2_574_);
v___x_582_ = lean_box(0);
v_isShared_583_ = v_isSharedCheck_599_;
goto v_resetjp_581_;
}
v_resetjp_581_:
{
lean_object* v_x_584_; lean_object* v_y_585_; lean_object* v___x_587_; uint8_t v_isShared_588_; uint8_t v_isSharedCheck_598_; 
v_x_584_ = lean_ctor_get(v_toPoint_576_, 0);
v_y_585_ = lean_ctor_get(v_toPoint_576_, 1);
v_isSharedCheck_598_ = !lean_is_exclusive(v_toPoint_576_);
if (v_isSharedCheck_598_ == 0)
{
v___x_587_ = v_toPoint_576_;
v_isShared_588_ = v_isSharedCheck_598_;
goto v_resetjp_586_;
}
else
{
lean_inc(v_y_585_);
lean_inc(v_x_584_);
lean_dec(v_toPoint_576_);
v___x_587_ = lean_box(0);
v_isShared_588_ = v_isSharedCheck_598_;
goto v_resetjp_586_;
}
v_resetjp_586_:
{
lean_object* v___x_589_; lean_object* v___x_590_; lean_object* v___x_592_; 
v___x_589_ = lean_nat_add(v_x_578_, v_x_584_);
lean_dec(v_x_584_);
v___x_590_ = lean_nat_add(v_y_579_, v_y_585_);
lean_dec(v_y_585_);
if (v_isShared_588_ == 0)
{
lean_ctor_set(v___x_587_, 1, v___x_590_);
lean_ctor_set(v___x_587_, 0, v___x_589_);
v___x_592_ = v___x_587_;
goto v_reusejp_591_;
}
else
{
lean_object* v_reuseFailAlloc_597_; 
v_reuseFailAlloc_597_ = lean_alloc_ctor(0, 2, 0);
lean_ctor_set(v_reuseFailAlloc_597_, 0, v___x_589_);
lean_ctor_set(v_reuseFailAlloc_597_, 1, v___x_590_);
v___x_592_ = v_reuseFailAlloc_597_;
goto v_reusejp_591_;
}
v_reusejp_591_:
{
lean_object* v___x_593_; lean_object* v___x_595_; 
v___x_593_ = lean_nat_add(v_z_577_, v_z_580_);
lean_dec(v_z_580_);
if (v_isShared_583_ == 0)
{
lean_ctor_set(v___x_582_, 1, v___x_593_);
lean_ctor_set(v___x_582_, 0, v___x_592_);
v___x_595_ = v___x_582_;
goto v_reusejp_594_;
}
else
{
lean_object* v_reuseFailAlloc_596_; 
v_reuseFailAlloc_596_ = lean_alloc_ctor(0, 2, 0);
lean_ctor_set(v_reuseFailAlloc_596_, 0, v___x_592_);
lean_ctor_set(v_reuseFailAlloc_596_, 1, v___x_593_);
v___x_595_ = v_reuseFailAlloc_596_;
goto v_reusejp_594_;
}
v_reusejp_594_:
{
return v___x_595_;
}
}
}
}
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instAddPoint3D___lam__0___boxed(lean_object* v_p1_601_, lean_object* v_p2_602_){
_start:
{
lean_object* v_res_603_; 
v_res_603_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instAddPoint3D___lam__0(v_p1_601_, v_p2_602_);
lean_dec_ref(v_p1_601_);
return v_res_603_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_upcast__example(void){
_start:
{
lean_object* v___x_617_; lean_object* v_toPoint_618_; 
v___x_617_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_p3d1));
v_toPoint_618_ = lean_ctor_get(v___x_617_, 0);
lean_inc_ref(v_toPoint_618_);
return v_toPoint_618_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_Point_toPoint3D(lean_object* v_p_619_, lean_object* v_z_620_){
_start:
{
lean_object* v___x_621_; 
v___x_621_ = lean_alloc_ctor(0, 2, 0);
lean_ctor_set(v___x_621_, 0, v_p_619_);
lean_ctor_set(v___x_621_, 1, v_z_620_);
return v___x_621_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_Point_double(lean_object* v_p_623_){
_start:
{
lean_object* v_x_624_; lean_object* v_y_625_; lean_object* v___x_627_; uint8_t v_isShared_628_; uint8_t v_isSharedCheck_635_; 
v_x_624_ = lean_ctor_get(v_p_623_, 0);
v_y_625_ = lean_ctor_get(v_p_623_, 1);
v_isSharedCheck_635_ = !lean_is_exclusive(v_p_623_);
if (v_isSharedCheck_635_ == 0)
{
v___x_627_ = v_p_623_;
v_isShared_628_ = v_isSharedCheck_635_;
goto v_resetjp_626_;
}
else
{
lean_inc(v_y_625_);
lean_inc(v_x_624_);
lean_dec(v_p_623_);
v___x_627_ = lean_box(0);
v_isShared_628_ = v_isSharedCheck_635_;
goto v_resetjp_626_;
}
v_resetjp_626_:
{
lean_object* v___x_629_; lean_object* v___x_630_; lean_object* v___x_631_; lean_object* v___x_633_; 
v___x_629_ = lean_unsigned_to_nat(2u);
v___x_630_ = lean_nat_mul(v_x_624_, v___x_629_);
lean_dec(v_x_624_);
v___x_631_ = lean_nat_mul(v_y_625_, v___x_629_);
lean_dec(v_y_625_);
if (v_isShared_628_ == 0)
{
lean_ctor_set(v___x_627_, 1, v___x_631_);
lean_ctor_set(v___x_627_, 0, v___x_630_);
v___x_633_ = v___x_627_;
goto v_reusejp_632_;
}
else
{
lean_object* v_reuseFailAlloc_634_; 
v_reuseFailAlloc_634_ = lean_alloc_ctor(0, 2, 0);
lean_ctor_set(v_reuseFailAlloc_634_, 0, v___x_630_);
lean_ctor_set(v_reuseFailAlloc_634_, 1, v___x_631_);
v___x_633_ = v_reuseFailAlloc_634_;
goto v_reusejp_632_;
}
v_reusejp_632_:
{
return v___x_633_;
}
}
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_Point3D_doubleXY(lean_object* v_p_636_){
_start:
{
lean_object* v_toPoint_637_; lean_object* v_z_638_; lean_object* v___x_640_; uint8_t v_isShared_641_; uint8_t v_isSharedCheck_646_; 
v_toPoint_637_ = lean_ctor_get(v_p_636_, 0);
v_z_638_ = lean_ctor_get(v_p_636_, 1);
v_isSharedCheck_646_ = !lean_is_exclusive(v_p_636_);
if (v_isSharedCheck_646_ == 0)
{
v___x_640_ = v_p_636_;
v_isShared_641_ = v_isSharedCheck_646_;
goto v_resetjp_639_;
}
else
{
lean_inc(v_z_638_);
lean_inc(v_toPoint_637_);
lean_dec(v_p_636_);
v___x_640_ = lean_box(0);
v_isShared_641_ = v_isSharedCheck_646_;
goto v_resetjp_639_;
}
v_resetjp_639_:
{
lean_object* v_p2_642_; lean_object* v___x_644_; 
v_p2_642_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_Point_double(v_toPoint_637_);
if (v_isShared_641_ == 0)
{
lean_ctor_set(v___x_640_, 0, v_p2_642_);
v___x_644_ = v___x_640_;
goto v_reusejp_643_;
}
else
{
lean_object* v_reuseFailAlloc_645_; 
v_reuseFailAlloc_645_ = lean_alloc_ctor(0, 2, 0);
lean_ctor_set(v_reuseFailAlloc_645_, 0, v_p2_642_);
lean_ctor_set(v_reuseFailAlloc_645_, 1, v_z_638_);
v___x_644_ = v_reuseFailAlloc_645_;
goto v_reusejp_643_;
}
v_reusejp_643_:
{
return v___x_644_;
}
}
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_p3d__double__xy___closed__0(void){
_start:
{
lean_object* v___x_647_; lean_object* v___x_648_; 
v___x_647_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_p3d1));
v___x_648_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_Point3D_doubleXY(v___x_647_);
return v___x_648_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_p3d__double__xy(void){
_start:
{
lean_object* v___x_649_; 
v___x_649_ = lean_obj_once(&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_p3d__double__xy___closed__0, &lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_p3d__double__xy___closed__0_once, _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_p3d__double__xy___closed__0);
return v___x_649_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_Point3D_double(lean_object* v_p_650_){
_start:
{
lean_object* v_toPoint_651_; lean_object* v_z_652_; lean_object* v___x_654_; uint8_t v_isShared_655_; uint8_t v_isSharedCheck_672_; 
v_toPoint_651_ = lean_ctor_get(v_p_650_, 0);
v_z_652_ = lean_ctor_get(v_p_650_, 1);
v_isSharedCheck_672_ = !lean_is_exclusive(v_p_650_);
if (v_isSharedCheck_672_ == 0)
{
v___x_654_ = v_p_650_;
v_isShared_655_ = v_isSharedCheck_672_;
goto v_resetjp_653_;
}
else
{
lean_inc(v_z_652_);
lean_inc(v_toPoint_651_);
lean_dec(v_p_650_);
v___x_654_ = lean_box(0);
v_isShared_655_ = v_isSharedCheck_672_;
goto v_resetjp_653_;
}
v_resetjp_653_:
{
lean_object* v_x_656_; lean_object* v_y_657_; lean_object* v___x_659_; uint8_t v_isShared_660_; uint8_t v_isSharedCheck_671_; 
v_x_656_ = lean_ctor_get(v_toPoint_651_, 0);
v_y_657_ = lean_ctor_get(v_toPoint_651_, 1);
v_isSharedCheck_671_ = !lean_is_exclusive(v_toPoint_651_);
if (v_isSharedCheck_671_ == 0)
{
v___x_659_ = v_toPoint_651_;
v_isShared_660_ = v_isSharedCheck_671_;
goto v_resetjp_658_;
}
else
{
lean_inc(v_y_657_);
lean_inc(v_x_656_);
lean_dec(v_toPoint_651_);
v___x_659_ = lean_box(0);
v_isShared_660_ = v_isSharedCheck_671_;
goto v_resetjp_658_;
}
v_resetjp_658_:
{
lean_object* v___x_661_; lean_object* v___x_662_; lean_object* v___x_663_; lean_object* v___x_665_; 
v___x_661_ = lean_unsigned_to_nat(2u);
v___x_662_ = lean_nat_mul(v_x_656_, v___x_661_);
lean_dec(v_x_656_);
v___x_663_ = lean_nat_mul(v_y_657_, v___x_661_);
lean_dec(v_y_657_);
if (v_isShared_660_ == 0)
{
lean_ctor_set(v___x_659_, 1, v___x_663_);
lean_ctor_set(v___x_659_, 0, v___x_662_);
v___x_665_ = v___x_659_;
goto v_reusejp_664_;
}
else
{
lean_object* v_reuseFailAlloc_670_; 
v_reuseFailAlloc_670_ = lean_alloc_ctor(0, 2, 0);
lean_ctor_set(v_reuseFailAlloc_670_, 0, v___x_662_);
lean_ctor_set(v_reuseFailAlloc_670_, 1, v___x_663_);
v___x_665_ = v_reuseFailAlloc_670_;
goto v_reusejp_664_;
}
v_reusejp_664_:
{
lean_object* v___x_666_; lean_object* v___x_668_; 
v___x_666_ = lean_nat_mul(v_z_652_, v___x_661_);
lean_dec(v_z_652_);
if (v_isShared_655_ == 0)
{
lean_ctor_set(v___x_654_, 1, v___x_666_);
lean_ctor_set(v___x_654_, 0, v___x_665_);
v___x_668_ = v___x_654_;
goto v_reusejp_667_;
}
else
{
lean_object* v_reuseFailAlloc_669_; 
v_reuseFailAlloc_669_ = lean_alloc_ctor(0, 2, 0);
lean_ctor_set(v_reuseFailAlloc_669_, 0, v___x_665_);
lean_ctor_set(v_reuseFailAlloc_669_, 1, v___x_666_);
v___x_668_ = v_reuseFailAlloc_669_;
goto v_reusejp_667_;
}
v_reusejp_667_:
{
return v___x_668_;
}
}
}
}
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_p3d__double___closed__0(void){
_start:
{
lean_object* v___x_673_; lean_object* v___x_674_; 
v___x_673_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_p3d1));
v___x_674_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_Point3D_double(v___x_673_);
return v___x_674_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_p3d__double(void){
_start:
{
lean_object* v___x_675_; 
v___x_675_ = lean_obj_once(&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_p3d__double___closed__0, &lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_p3d__double___closed__0_once, _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_p3d__double___closed__0);
return v___x_675_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instReprHasName_repr___redArg(lean_object* v_x_682_){
_start:
{
lean_object* v___x_683_; lean_object* v___x_684_; lean_object* v___x_685_; lean_object* v___x_686_; lean_object* v___x_687_; uint8_t v___x_688_; lean_object* v___x_689_; lean_object* v___x_690_; lean_object* v___x_691_; lean_object* v___x_692_; lean_object* v___x_693_; lean_object* v___x_694_; lean_object* v___x_695_; lean_object* v___x_696_; lean_object* v___x_697_; 
v___x_683_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instReprHasName_repr___redArg___closed__1));
v___x_684_ = lean_obj_once(&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instReprColor_repr___redArg___closed__10, &lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instReprColor_repr___redArg___closed__10_once, _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instReprColor_repr___redArg___closed__10);
v___x_685_ = l_String_quote(v_x_682_);
v___x_686_ = lean_alloc_ctor(3, 1, 0);
lean_ctor_set(v___x_686_, 0, v___x_685_);
v___x_687_ = lean_alloc_ctor(4, 2, 0);
lean_ctor_set(v___x_687_, 0, v___x_684_);
lean_ctor_set(v___x_687_, 1, v___x_686_);
v___x_688_ = 0;
v___x_689_ = lean_alloc_ctor(6, 1, 1);
lean_ctor_set(v___x_689_, 0, v___x_687_);
lean_ctor_set_uint8(v___x_689_, sizeof(void*)*1, v___x_688_);
v___x_690_ = lean_alloc_ctor(5, 2, 0);
lean_ctor_set(v___x_690_, 0, v___x_683_);
lean_ctor_set(v___x_690_, 1, v___x_689_);
v___x_691_ = lean_obj_once(&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instReprPoint_repr___redArg___closed__14, &lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instReprPoint_repr___redArg___closed__14_once, _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instReprPoint_repr___redArg___closed__14);
v___x_692_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instReprPoint_repr___redArg___closed__15));
v___x_693_ = lean_alloc_ctor(5, 2, 0);
lean_ctor_set(v___x_693_, 0, v___x_692_);
lean_ctor_set(v___x_693_, 1, v___x_690_);
v___x_694_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instReprPoint_repr___redArg___closed__16));
v___x_695_ = lean_alloc_ctor(5, 2, 0);
lean_ctor_set(v___x_695_, 0, v___x_693_);
lean_ctor_set(v___x_695_, 1, v___x_694_);
v___x_696_ = lean_alloc_ctor(4, 2, 0);
lean_ctor_set(v___x_696_, 0, v___x_691_);
lean_ctor_set(v___x_696_, 1, v___x_695_);
v___x_697_ = lean_alloc_ctor(6, 1, 1);
lean_ctor_set(v___x_697_, 0, v___x_696_);
lean_ctor_set_uint8(v___x_697_, sizeof(void*)*1, v___x_688_);
return v___x_697_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instReprHasName_repr(lean_object* v_x_698_, lean_object* v_prec_699_){
_start:
{
lean_object* v___x_700_; 
v___x_700_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instReprHasName_repr___redArg(v_x_698_);
return v___x_700_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instReprHasName_repr___boxed(lean_object* v_x_701_, lean_object* v_prec_702_){
_start:
{
lean_object* v_res_703_; 
v_res_703_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instReprHasName_repr(v_x_701_, v_prec_702_);
lean_dec(v_prec_702_);
return v_res_703_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instReprHasAge_repr___redArg(lean_object* v_x_715_){
_start:
{
lean_object* v___x_716_; lean_object* v___x_717_; lean_object* v___x_718_; lean_object* v___x_719_; lean_object* v___x_720_; uint8_t v___x_721_; lean_object* v___x_722_; lean_object* v___x_723_; lean_object* v___x_724_; lean_object* v___x_725_; lean_object* v___x_726_; lean_object* v___x_727_; lean_object* v___x_728_; lean_object* v___x_729_; lean_object* v___x_730_; 
v___x_716_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instReprHasAge_repr___redArg___closed__3));
v___x_717_ = lean_obj_once(&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instReprColor_repr___redArg___closed__4, &lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instReprColor_repr___redArg___closed__4_once, _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instReprColor_repr___redArg___closed__4);
v___x_718_ = l_Nat_reprFast(v_x_715_);
v___x_719_ = lean_alloc_ctor(3, 1, 0);
lean_ctor_set(v___x_719_, 0, v___x_718_);
v___x_720_ = lean_alloc_ctor(4, 2, 0);
lean_ctor_set(v___x_720_, 0, v___x_717_);
lean_ctor_set(v___x_720_, 1, v___x_719_);
v___x_721_ = 0;
v___x_722_ = lean_alloc_ctor(6, 1, 1);
lean_ctor_set(v___x_722_, 0, v___x_720_);
lean_ctor_set_uint8(v___x_722_, sizeof(void*)*1, v___x_721_);
v___x_723_ = lean_alloc_ctor(5, 2, 0);
lean_ctor_set(v___x_723_, 0, v___x_716_);
lean_ctor_set(v___x_723_, 1, v___x_722_);
v___x_724_ = lean_obj_once(&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instReprPoint_repr___redArg___closed__14, &lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instReprPoint_repr___redArg___closed__14_once, _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instReprPoint_repr___redArg___closed__14);
v___x_725_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instReprPoint_repr___redArg___closed__15));
v___x_726_ = lean_alloc_ctor(5, 2, 0);
lean_ctor_set(v___x_726_, 0, v___x_725_);
lean_ctor_set(v___x_726_, 1, v___x_723_);
v___x_727_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instReprPoint_repr___redArg___closed__16));
v___x_728_ = lean_alloc_ctor(5, 2, 0);
lean_ctor_set(v___x_728_, 0, v___x_726_);
lean_ctor_set(v___x_728_, 1, v___x_727_);
v___x_729_ = lean_alloc_ctor(4, 2, 0);
lean_ctor_set(v___x_729_, 0, v___x_724_);
lean_ctor_set(v___x_729_, 1, v___x_728_);
v___x_730_ = lean_alloc_ctor(6, 1, 1);
lean_ctor_set(v___x_730_, 0, v___x_729_);
lean_ctor_set_uint8(v___x_730_, sizeof(void*)*1, v___x_721_);
return v___x_730_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instReprHasAge_repr(lean_object* v_x_731_, lean_object* v_prec_732_){
_start:
{
lean_object* v___x_733_; 
v___x_733_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instReprHasAge_repr___redArg(v_x_731_);
return v___x_733_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instReprHasAge_repr___boxed(lean_object* v_x_734_, lean_object* v_prec_735_){
_start:
{
lean_object* v_res_736_; 
v_res_736_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instReprHasAge_repr(v_x_734_, v_prec_735_);
lean_dec(v_prec_735_);
return v_res_736_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instReprStudent_repr___redArg___closed__6(void){
_start:
{
lean_object* v___x_751_; lean_object* v___x_752_; 
v___x_751_ = lean_unsigned_to_nat(12u);
v___x_752_ = lean_nat_to_int(v___x_751_);
return v___x_752_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instReprStudent_repr___redArg___closed__9(void){
_start:
{
lean_object* v___x_756_; lean_object* v___x_757_; 
v___x_756_ = lean_unsigned_to_nat(6u);
v___x_757_ = lean_nat_to_int(v___x_756_);
return v___x_757_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instReprStudent_repr___redArg(lean_object* v_x_761_){
_start:
{
lean_object* v_toHasName_762_; lean_object* v_toHasAge_763_; lean_object* v_id_764_; lean_object* v_major_765_; lean_object* v___x_766_; lean_object* v___x_767_; lean_object* v___x_768_; lean_object* v___x_769_; lean_object* v___x_770_; uint8_t v___x_771_; lean_object* v___x_772_; lean_object* v___x_773_; lean_object* v___x_774_; lean_object* v___x_775_; lean_object* v___x_776_; lean_object* v___x_777_; lean_object* v___x_778_; lean_object* v___x_779_; lean_object* v___x_780_; lean_object* v___x_781_; lean_object* v___x_782_; lean_object* v___x_783_; lean_object* v___x_784_; lean_object* v___x_785_; lean_object* v___x_786_; lean_object* v___x_787_; lean_object* v___x_788_; lean_object* v___x_789_; lean_object* v___x_790_; lean_object* v___x_791_; lean_object* v___x_792_; lean_object* v___x_793_; lean_object* v___x_794_; lean_object* v___x_795_; lean_object* v___x_796_; lean_object* v___x_797_; lean_object* v___x_798_; lean_object* v___x_799_; lean_object* v___x_800_; lean_object* v___x_801_; lean_object* v___x_802_; lean_object* v___x_803_; lean_object* v___x_804_; lean_object* v___x_805_; lean_object* v___x_806_; lean_object* v___x_807_; lean_object* v___x_808_; lean_object* v___x_809_; lean_object* v___x_810_; lean_object* v___x_811_; lean_object* v___x_812_; lean_object* v___x_813_; lean_object* v___x_814_; 
v_toHasName_762_ = lean_ctor_get(v_x_761_, 0);
lean_inc_ref(v_toHasName_762_);
v_toHasAge_763_ = lean_ctor_get(v_x_761_, 1);
lean_inc(v_toHasAge_763_);
v_id_764_ = lean_ctor_get(v_x_761_, 2);
lean_inc(v_id_764_);
v_major_765_ = lean_ctor_get(v_x_761_, 3);
lean_inc_ref(v_major_765_);
lean_dec_ref(v_x_761_);
v___x_766_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instReprPoint_repr___redArg___closed__5));
v___x_767_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instReprStudent_repr___redArg___closed__3));
v___x_768_ = lean_obj_once(&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instReprNamedPoint3D_repr___redArg___closed__4, &lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instReprNamedPoint3D_repr___redArg___closed__4_once, _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instReprNamedPoint3D_repr___redArg___closed__4);
v___x_769_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instReprHasName_repr___redArg(v_toHasName_762_);
v___x_770_ = lean_alloc_ctor(4, 2, 0);
lean_ctor_set(v___x_770_, 0, v___x_768_);
lean_ctor_set(v___x_770_, 1, v___x_769_);
v___x_771_ = 0;
v___x_772_ = lean_alloc_ctor(6, 1, 1);
lean_ctor_set(v___x_772_, 0, v___x_770_);
lean_ctor_set_uint8(v___x_772_, sizeof(void*)*1, v___x_771_);
v___x_773_ = lean_alloc_ctor(5, 2, 0);
lean_ctor_set(v___x_773_, 0, v___x_767_);
lean_ctor_set(v___x_773_, 1, v___x_772_);
v___x_774_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instReprPoint_repr___redArg___closed__9));
v___x_775_ = lean_alloc_ctor(5, 2, 0);
lean_ctor_set(v___x_775_, 0, v___x_773_);
lean_ctor_set(v___x_775_, 1, v___x_774_);
v___x_776_ = lean_box(1);
v___x_777_ = lean_alloc_ctor(5, 2, 0);
lean_ctor_set(v___x_777_, 0, v___x_775_);
lean_ctor_set(v___x_777_, 1, v___x_776_);
v___x_778_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instReprStudent_repr___redArg___closed__5));
v___x_779_ = lean_alloc_ctor(5, 2, 0);
lean_ctor_set(v___x_779_, 0, v___x_777_);
lean_ctor_set(v___x_779_, 1, v___x_778_);
v___x_780_ = lean_alloc_ctor(5, 2, 0);
lean_ctor_set(v___x_780_, 0, v___x_779_);
lean_ctor_set(v___x_780_, 1, v___x_766_);
v___x_781_ = lean_obj_once(&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instReprStudent_repr___redArg___closed__6, &lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instReprStudent_repr___redArg___closed__6_once, _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instReprStudent_repr___redArg___closed__6);
v___x_782_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instReprHasAge_repr___redArg(v_toHasAge_763_);
v___x_783_ = lean_alloc_ctor(4, 2, 0);
lean_ctor_set(v___x_783_, 0, v___x_781_);
lean_ctor_set(v___x_783_, 1, v___x_782_);
v___x_784_ = lean_alloc_ctor(6, 1, 1);
lean_ctor_set(v___x_784_, 0, v___x_783_);
lean_ctor_set_uint8(v___x_784_, sizeof(void*)*1, v___x_771_);
v___x_785_ = lean_alloc_ctor(5, 2, 0);
lean_ctor_set(v___x_785_, 0, v___x_780_);
lean_ctor_set(v___x_785_, 1, v___x_784_);
v___x_786_ = lean_alloc_ctor(5, 2, 0);
lean_ctor_set(v___x_786_, 0, v___x_785_);
lean_ctor_set(v___x_786_, 1, v___x_774_);
v___x_787_ = lean_alloc_ctor(5, 2, 0);
lean_ctor_set(v___x_787_, 0, v___x_786_);
lean_ctor_set(v___x_787_, 1, v___x_776_);
v___x_788_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instReprStudent_repr___redArg___closed__8));
v___x_789_ = lean_alloc_ctor(5, 2, 0);
lean_ctor_set(v___x_789_, 0, v___x_787_);
lean_ctor_set(v___x_789_, 1, v___x_788_);
v___x_790_ = lean_alloc_ctor(5, 2, 0);
lean_ctor_set(v___x_790_, 0, v___x_789_);
lean_ctor_set(v___x_790_, 1, v___x_766_);
v___x_791_ = lean_obj_once(&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instReprStudent_repr___redArg___closed__9, &lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instReprStudent_repr___redArg___closed__9_once, _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instReprStudent_repr___redArg___closed__9);
v___x_792_ = l_Nat_reprFast(v_id_764_);
v___x_793_ = lean_alloc_ctor(3, 1, 0);
lean_ctor_set(v___x_793_, 0, v___x_792_);
v___x_794_ = lean_alloc_ctor(4, 2, 0);
lean_ctor_set(v___x_794_, 0, v___x_791_);
lean_ctor_set(v___x_794_, 1, v___x_793_);
v___x_795_ = lean_alloc_ctor(6, 1, 1);
lean_ctor_set(v___x_795_, 0, v___x_794_);
lean_ctor_set_uint8(v___x_795_, sizeof(void*)*1, v___x_771_);
v___x_796_ = lean_alloc_ctor(5, 2, 0);
lean_ctor_set(v___x_796_, 0, v___x_790_);
lean_ctor_set(v___x_796_, 1, v___x_795_);
v___x_797_ = lean_alloc_ctor(5, 2, 0);
lean_ctor_set(v___x_797_, 0, v___x_796_);
lean_ctor_set(v___x_797_, 1, v___x_774_);
v___x_798_ = lean_alloc_ctor(5, 2, 0);
lean_ctor_set(v___x_798_, 0, v___x_797_);
lean_ctor_set(v___x_798_, 1, v___x_776_);
v___x_799_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instReprStudent_repr___redArg___closed__11));
v___x_800_ = lean_alloc_ctor(5, 2, 0);
lean_ctor_set(v___x_800_, 0, v___x_798_);
lean_ctor_set(v___x_800_, 1, v___x_799_);
v___x_801_ = lean_alloc_ctor(5, 2, 0);
lean_ctor_set(v___x_801_, 0, v___x_800_);
lean_ctor_set(v___x_801_, 1, v___x_766_);
v___x_802_ = lean_obj_once(&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instReprColor_repr___redArg___closed__7, &lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instReprColor_repr___redArg___closed__7_once, _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instReprColor_repr___redArg___closed__7);
v___x_803_ = l_String_quote(v_major_765_);
v___x_804_ = lean_alloc_ctor(3, 1, 0);
lean_ctor_set(v___x_804_, 0, v___x_803_);
v___x_805_ = lean_alloc_ctor(4, 2, 0);
lean_ctor_set(v___x_805_, 0, v___x_802_);
lean_ctor_set(v___x_805_, 1, v___x_804_);
v___x_806_ = lean_alloc_ctor(6, 1, 1);
lean_ctor_set(v___x_806_, 0, v___x_805_);
lean_ctor_set_uint8(v___x_806_, sizeof(void*)*1, v___x_771_);
v___x_807_ = lean_alloc_ctor(5, 2, 0);
lean_ctor_set(v___x_807_, 0, v___x_801_);
lean_ctor_set(v___x_807_, 1, v___x_806_);
v___x_808_ = lean_obj_once(&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instReprPoint_repr___redArg___closed__14, &lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instReprPoint_repr___redArg___closed__14_once, _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instReprPoint_repr___redArg___closed__14);
v___x_809_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instReprPoint_repr___redArg___closed__15));
v___x_810_ = lean_alloc_ctor(5, 2, 0);
lean_ctor_set(v___x_810_, 0, v___x_809_);
lean_ctor_set(v___x_810_, 1, v___x_807_);
v___x_811_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instReprPoint_repr___redArg___closed__16));
v___x_812_ = lean_alloc_ctor(5, 2, 0);
lean_ctor_set(v___x_812_, 0, v___x_810_);
lean_ctor_set(v___x_812_, 1, v___x_811_);
v___x_813_ = lean_alloc_ctor(4, 2, 0);
lean_ctor_set(v___x_813_, 0, v___x_808_);
lean_ctor_set(v___x_813_, 1, v___x_812_);
v___x_814_ = lean_alloc_ctor(6, 1, 1);
lean_ctor_set(v___x_814_, 0, v___x_813_);
lean_ctor_set_uint8(v___x_814_, sizeof(void*)*1, v___x_771_);
return v___x_814_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instReprStudent_repr(lean_object* v_x_815_, lean_object* v_prec_816_){
_start:
{
lean_object* v___x_817_; 
v___x_817_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instReprStudent_repr___redArg(v_x_815_);
return v___x_817_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instReprStudent_repr___boxed(lean_object* v_x_818_, lean_object* v_prec_819_){
_start:
{
lean_object* v_res_820_; 
v_res_820_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_instReprStudent_repr(v_x_818_, v_prec_819_);
lean_dec(v_prec_819_);
return v_res_820_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_student__name(void){
_start:
{
lean_object* v___x_831_; lean_object* v_toHasName_832_; 
v___x_831_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_student));
v_toHasName_832_ = lean_ctor_get(v___x_831_, 0);
lean_inc_ref(v_toHasName_832_);
return v_toHasName_832_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_student__age(void){
_start:
{
lean_object* v___x_833_; lean_object* v_toHasAge_834_; 
v___x_833_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_student));
v_toHasAge_834_ = lean_ctor_get(v___x_833_, 1);
lean_inc(v_toHasAge_834_);
return v_toHasAge_834_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_student__id(void){
_start:
{
lean_object* v___x_835_; lean_object* v_id_836_; 
v___x_835_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_student));
v_id_836_ = lean_ctor_get(v___x_835_, 2);
lean_inc(v_id_836_);
return v_id_836_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_student__has__name(void){
_start:
{
lean_object* v___x_837_; lean_object* v_toHasName_838_; 
v___x_837_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_student));
v_toHasName_838_ = lean_ctor_get(v___x_837_, 0);
lean_inc_ref(v_toHasName_838_);
return v_toHasName_838_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_student__has__age(void){
_start:
{
lean_object* v___x_839_; lean_object* v_toHasAge_840_; 
v___x_839_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_student));
v_toHasAge_840_ = lean_ctor_get(v___x_839_, 1);
lean_inc(v_toHasAge_840_);
return v_toHasAge_840_;
}
}
lean_object* initialize_Init(uint8_t builtin);
lean_object* initialize_Init(uint8_t builtin);
static bool _G_initialized = false;
LEAN_EXPORT lean_object* initialize_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate(uint8_t builtin) {
lean_object * res;
if (_G_initialized) return lean_io_result_mk_ok(lean_box(0));
_G_initialized = true;
res = initialize_Init(builtin);
if (lean_io_result_is_error(res)) return res;
lean_dec_ref(res);
res = initialize_Init(builtin);
if (lean_io_result_is_error(res)) return res;
lean_dec_ref(res);
lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_p1_x27 = _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_p1_x27();
lean_mark_persistent(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_p1_x27);
lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_p1_x27_x27 = _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_p1_x27_x27();
lean_mark_persistent(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_p1_x27_x27);
lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_updated = _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_updated();
lean_mark_persistent(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_updated);
lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_darkerRed = _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_darkerRed();
lean_mark_persistent(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_darkerRed);
lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_moveRight = _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_moveRight();
lean_mark_persistent(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_moveRight);
lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_moveAndRecolor = _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_moveAndRecolor();
lean_mark_persistent(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_moveAndRecolor);
lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_p3d__x = _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_p3d__x();
lean_mark_persistent(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_p3d__x);
lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_p3d__y = _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_p3d__y();
lean_mark_persistent(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_p3d__y);
lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_p3d__z = _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_p3d__z();
lean_mark_persistent(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_p3d__z);
lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_p3d__point = _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_p3d__point();
lean_mark_persistent(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_p3d__point);
lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_p3d1_x27 = _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_p3d1_x27();
lean_mark_persistent(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_p3d1_x27);
lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_p3d1_x27_x27 = _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_p3d1_x27_x27();
lean_mark_persistent(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_p3d1_x27_x27);
lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_np3d__name = _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_np3d__name();
lean_mark_persistent(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_np3d__name);
lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_np3d__x = _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_np3d__x();
lean_mark_persistent(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_np3d__x);
lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_np3d__z = _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_np3d__z();
lean_mark_persistent(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_np3d__z);
lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_np3d__to__p3d = _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_np3d__to__p3d();
lean_mark_persistent(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_np3d__to__p3d);
lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_np3d__to__point = _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_np3d__to__point();
lean_mark_persistent(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_np3d__to__point);
lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_rp__x = _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_rp__x();
lean_mark_persistent(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_rp__x);
lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_rp__y = _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_rp__y();
lean_mark_persistent(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_rp__y);
lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_rp__color = _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_rp__color();
lean_mark_persistent(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_rp__color);
lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_greenPoint_x27 = _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_greenPoint_x27();
lean_mark_persistent(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_greenPoint_x27);
lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_upcast__example = _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_upcast__example();
lean_mark_persistent(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_upcast__example);
lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_p3d__double__xy = _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_p3d__double__xy();
lean_mark_persistent(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_p3d__double__xy);
lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_p3d__double = _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_p3d__double();
lean_mark_persistent(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_p3d__double);
lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_student__name = _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_student__name();
lean_mark_persistent(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_student__name);
lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_student__age = _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_student__age();
lean_mark_persistent(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_student__age);
lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_student__id = _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_student__id();
lean_mark_persistent(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_student__id);
lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_student__has__name = _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_student__has__name();
lean_mark_persistent(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_student__has__name);
lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_student__has__age = _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_student__has__age();
lean_mark_persistent(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_StructureUpdate_student__has__age);
return lean_io_result_mk_ok(lean_box(0));
}
#ifdef __cplusplus
}
#endif
