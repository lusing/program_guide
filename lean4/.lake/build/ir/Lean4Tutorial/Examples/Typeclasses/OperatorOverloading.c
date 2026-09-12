// Lean compiler output
// Module: Lean4Tutorial.Examples.Typeclasses.OperatorOverloading
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
lean_object* lean_nat_add(lean_object*, lean_object*);
lean_object* lean_nat_to_int(lean_object*);
uint8_t lean_nat_dec_eq(lean_object*, lean_object*);
uint8_t lean_nat_dec_lt(lean_object*, lean_object*);
lean_object* lean_nat_mul(lean_object*, lean_object*);
lean_object* l_List_appendTR___redArg(lean_object*, lean_object*);
lean_object* l_Nat_reprFast(lean_object*);
lean_object* lean_string_length(lean_object*);
lean_object* lean_nat_sub(lean_object*, lean_object*);
uint8_t l_instDecidableEqOrdering(uint8_t, uint8_t);
static const lean_string_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_OperatorOverloading_instReprPoint_repr___redArg___closed__0_value = {.m_header = {.m_rc = 0, .m_cs_sz = 0, .m_other = 0, .m_tag = 249}, .m_size = 3, .m_capacity = 3, .m_length = 2, .m_data = "{ "};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_OperatorOverloading_instReprPoint_repr___redArg___closed__0 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_OperatorOverloading_instReprPoint_repr___redArg___closed__0_value;
static const lean_string_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_OperatorOverloading_instReprPoint_repr___redArg___closed__1_value = {.m_header = {.m_rc = 0, .m_cs_sz = 0, .m_other = 0, .m_tag = 249}, .m_size = 2, .m_capacity = 2, .m_length = 1, .m_data = "x"};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_OperatorOverloading_instReprPoint_repr___redArg___closed__1 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_OperatorOverloading_instReprPoint_repr___redArg___closed__1_value;
static const lean_ctor_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_OperatorOverloading_instReprPoint_repr___redArg___closed__2_value = {.m_header = {.m_rc = 0, .m_cs_sz = sizeof(lean_ctor_object) + sizeof(void*)*1 + 0, .m_other = 1, .m_tag = 3}, .m_objs = {((lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_OperatorOverloading_instReprPoint_repr___redArg___closed__1_value)}};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_OperatorOverloading_instReprPoint_repr___redArg___closed__2 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_OperatorOverloading_instReprPoint_repr___redArg___closed__2_value;
static const lean_ctor_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_OperatorOverloading_instReprPoint_repr___redArg___closed__3_value = {.m_header = {.m_rc = 0, .m_cs_sz = sizeof(lean_ctor_object) + sizeof(void*)*2 + 0, .m_other = 2, .m_tag = 5}, .m_objs = {((lean_object*)(((size_t)(0) << 1) | 1)),((lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_OperatorOverloading_instReprPoint_repr___redArg___closed__2_value)}};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_OperatorOverloading_instReprPoint_repr___redArg___closed__3 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_OperatorOverloading_instReprPoint_repr___redArg___closed__3_value;
static const lean_string_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_OperatorOverloading_instReprPoint_repr___redArg___closed__4_value = {.m_header = {.m_rc = 0, .m_cs_sz = 0, .m_other = 0, .m_tag = 249}, .m_size = 5, .m_capacity = 5, .m_length = 4, .m_data = " := "};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_OperatorOverloading_instReprPoint_repr___redArg___closed__4 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_OperatorOverloading_instReprPoint_repr___redArg___closed__4_value;
static const lean_ctor_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_OperatorOverloading_instReprPoint_repr___redArg___closed__5_value = {.m_header = {.m_rc = 0, .m_cs_sz = sizeof(lean_ctor_object) + sizeof(void*)*1 + 0, .m_other = 1, .m_tag = 3}, .m_objs = {((lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_OperatorOverloading_instReprPoint_repr___redArg___closed__4_value)}};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_OperatorOverloading_instReprPoint_repr___redArg___closed__5 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_OperatorOverloading_instReprPoint_repr___redArg___closed__5_value;
static const lean_ctor_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_OperatorOverloading_instReprPoint_repr___redArg___closed__6_value = {.m_header = {.m_rc = 0, .m_cs_sz = sizeof(lean_ctor_object) + sizeof(void*)*2 + 0, .m_other = 2, .m_tag = 5}, .m_objs = {((lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_OperatorOverloading_instReprPoint_repr___redArg___closed__3_value),((lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_OperatorOverloading_instReprPoint_repr___redArg___closed__5_value)}};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_OperatorOverloading_instReprPoint_repr___redArg___closed__6 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_OperatorOverloading_instReprPoint_repr___redArg___closed__6_value;
static lean_once_cell_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_OperatorOverloading_instReprPoint_repr___redArg___closed__7_once = LEAN_ONCE_CELL_INITIALIZER;
static lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_OperatorOverloading_instReprPoint_repr___redArg___closed__7;
static const lean_string_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_OperatorOverloading_instReprPoint_repr___redArg___closed__8_value = {.m_header = {.m_rc = 0, .m_cs_sz = 0, .m_other = 0, .m_tag = 249}, .m_size = 2, .m_capacity = 2, .m_length = 1, .m_data = ","};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_OperatorOverloading_instReprPoint_repr___redArg___closed__8 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_OperatorOverloading_instReprPoint_repr___redArg___closed__8_value;
static const lean_ctor_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_OperatorOverloading_instReprPoint_repr___redArg___closed__9_value = {.m_header = {.m_rc = 0, .m_cs_sz = sizeof(lean_ctor_object) + sizeof(void*)*1 + 0, .m_other = 1, .m_tag = 3}, .m_objs = {((lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_OperatorOverloading_instReprPoint_repr___redArg___closed__8_value)}};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_OperatorOverloading_instReprPoint_repr___redArg___closed__9 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_OperatorOverloading_instReprPoint_repr___redArg___closed__9_value;
static const lean_string_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_OperatorOverloading_instReprPoint_repr___redArg___closed__10_value = {.m_header = {.m_rc = 0, .m_cs_sz = 0, .m_other = 0, .m_tag = 249}, .m_size = 2, .m_capacity = 2, .m_length = 1, .m_data = "y"};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_OperatorOverloading_instReprPoint_repr___redArg___closed__10 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_OperatorOverloading_instReprPoint_repr___redArg___closed__10_value;
static const lean_ctor_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_OperatorOverloading_instReprPoint_repr___redArg___closed__11_value = {.m_header = {.m_rc = 0, .m_cs_sz = sizeof(lean_ctor_object) + sizeof(void*)*1 + 0, .m_other = 1, .m_tag = 3}, .m_objs = {((lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_OperatorOverloading_instReprPoint_repr___redArg___closed__10_value)}};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_OperatorOverloading_instReprPoint_repr___redArg___closed__11 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_OperatorOverloading_instReprPoint_repr___redArg___closed__11_value;
static const lean_string_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_OperatorOverloading_instReprPoint_repr___redArg___closed__12_value = {.m_header = {.m_rc = 0, .m_cs_sz = 0, .m_other = 0, .m_tag = 249}, .m_size = 3, .m_capacity = 3, .m_length = 2, .m_data = " }"};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_OperatorOverloading_instReprPoint_repr___redArg___closed__12 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_OperatorOverloading_instReprPoint_repr___redArg___closed__12_value;
static lean_once_cell_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_OperatorOverloading_instReprPoint_repr___redArg___closed__13_once = LEAN_ONCE_CELL_INITIALIZER;
static lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_OperatorOverloading_instReprPoint_repr___redArg___closed__13;
static lean_once_cell_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_OperatorOverloading_instReprPoint_repr___redArg___closed__14_once = LEAN_ONCE_CELL_INITIALIZER;
static lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_OperatorOverloading_instReprPoint_repr___redArg___closed__14;
static const lean_ctor_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_OperatorOverloading_instReprPoint_repr___redArg___closed__15_value = {.m_header = {.m_rc = 0, .m_cs_sz = sizeof(lean_ctor_object) + sizeof(void*)*1 + 0, .m_other = 1, .m_tag = 3}, .m_objs = {((lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_OperatorOverloading_instReprPoint_repr___redArg___closed__0_value)}};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_OperatorOverloading_instReprPoint_repr___redArg___closed__15 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_OperatorOverloading_instReprPoint_repr___redArg___closed__15_value;
static const lean_ctor_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_OperatorOverloading_instReprPoint_repr___redArg___closed__16_value = {.m_header = {.m_rc = 0, .m_cs_sz = sizeof(lean_ctor_object) + sizeof(void*)*1 + 0, .m_other = 1, .m_tag = 3}, .m_objs = {((lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_OperatorOverloading_instReprPoint_repr___redArg___closed__12_value)}};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_OperatorOverloading_instReprPoint_repr___redArg___closed__16 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_OperatorOverloading_instReprPoint_repr___redArg___closed__16_value;
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_OperatorOverloading_instReprPoint_repr___redArg(lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_OperatorOverloading_instReprPoint_repr(lean_object*, lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_OperatorOverloading_instReprPoint_repr___boxed(lean_object*, lean_object*);
static const lean_closure_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_OperatorOverloading_instReprPoint___closed__0_value = {.m_header = {.m_rc = 0, .m_cs_sz = sizeof(lean_closure_object) + sizeof(void*)*0, .m_other = 0, .m_tag = 245}, .m_fun = (void*)lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_OperatorOverloading_instReprPoint_repr___boxed, .m_arity = 2, .m_num_fixed = 0, .m_objs = {} };
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_OperatorOverloading_instReprPoint___closed__0 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_OperatorOverloading_instReprPoint___closed__0_value;
LEAN_EXPORT const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_OperatorOverloading_instReprPoint = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_OperatorOverloading_instReprPoint___closed__0_value;
LEAN_EXPORT uint8_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_OperatorOverloading_instDecidableEqPoint_decEq(lean_object*, lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_OperatorOverloading_instDecidableEqPoint_decEq___boxed(lean_object*, lean_object*);
LEAN_EXPORT uint8_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_OperatorOverloading_instDecidableEqPoint(lean_object*, lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_OperatorOverloading_instDecidableEqPoint___boxed(lean_object*, lean_object*);
static const lean_ctor_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_OperatorOverloading_p1___closed__0_value = {.m_header = {.m_rc = 0, .m_cs_sz = sizeof(lean_ctor_object) + sizeof(void*)*2 + 0, .m_other = 2, .m_tag = 0}, .m_objs = {((lean_object*)(((size_t)(1) << 1) | 1)),((lean_object*)(((size_t)(2) << 1) | 1))}};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_OperatorOverloading_p1___closed__0 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_OperatorOverloading_p1___closed__0_value;
LEAN_EXPORT const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_OperatorOverloading_p1 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_OperatorOverloading_p1___closed__0_value;
static const lean_ctor_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_OperatorOverloading_p2___closed__0_value = {.m_header = {.m_rc = 0, .m_cs_sz = sizeof(lean_ctor_object) + sizeof(void*)*2 + 0, .m_other = 2, .m_tag = 0}, .m_objs = {((lean_object*)(((size_t)(3) << 1) | 1)),((lean_object*)(((size_t)(4) << 1) | 1))}};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_OperatorOverloading_p2___closed__0 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_OperatorOverloading_p2___closed__0_value;
LEAN_EXPORT const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_OperatorOverloading_p2 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_OperatorOverloading_p2___closed__0_value;
static const lean_ctor_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_OperatorOverloading_p3___closed__0_value = {.m_header = {.m_rc = 0, .m_cs_sz = sizeof(lean_ctor_object) + sizeof(void*)*2 + 0, .m_other = 2, .m_tag = 0}, .m_objs = {((lean_object*)(((size_t)(5) << 1) | 1)),((lean_object*)(((size_t)(6) << 1) | 1))}};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_OperatorOverloading_p3___closed__0 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_OperatorOverloading_p3___closed__0_value;
LEAN_EXPORT const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_OperatorOverloading_p3 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_OperatorOverloading_p3___closed__0_value;
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_OperatorOverloading_instAddPoint___lam__0(lean_object*, lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_OperatorOverloading_instAddPoint___lam__0___boxed(lean_object*, lean_object*);
static const lean_closure_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_OperatorOverloading_instAddPoint___closed__0_value = {.m_header = {.m_rc = 0, .m_cs_sz = sizeof(lean_closure_object) + sizeof(void*)*0, .m_other = 0, .m_tag = 245}, .m_fun = (void*)lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_OperatorOverloading_instAddPoint___lam__0___boxed, .m_arity = 2, .m_num_fixed = 0, .m_objs = {} };
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_OperatorOverloading_instAddPoint___closed__0 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_OperatorOverloading_instAddPoint___closed__0_value;
LEAN_EXPORT const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_OperatorOverloading_instAddPoint = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_OperatorOverloading_instAddPoint___closed__0_value;
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_OperatorOverloading_p__add;
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_OperatorOverloading_p__add3;
static const lean_ctor_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_OperatorOverloading_instZeroPoint___closed__0_value = {.m_header = {.m_rc = 0, .m_cs_sz = sizeof(lean_ctor_object) + sizeof(void*)*2 + 0, .m_other = 2, .m_tag = 0}, .m_objs = {((lean_object*)(((size_t)(0) << 1) | 1)),((lean_object*)(((size_t)(0) << 1) | 1))}};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_OperatorOverloading_instZeroPoint___closed__0 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_OperatorOverloading_instZeroPoint___closed__0_value;
LEAN_EXPORT const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_OperatorOverloading_instZeroPoint = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_OperatorOverloading_instZeroPoint___closed__0_value;
LEAN_EXPORT const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_OperatorOverloading_p__zero = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_OperatorOverloading_instZeroPoint___closed__0_value;
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_OperatorOverloading_instSubPoint___lam__0(lean_object*, lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_OperatorOverloading_instSubPoint___lam__0___boxed(lean_object*, lean_object*);
static const lean_closure_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_OperatorOverloading_instSubPoint___closed__0_value = {.m_header = {.m_rc = 0, .m_cs_sz = sizeof(lean_closure_object) + sizeof(void*)*0, .m_other = 0, .m_tag = 245}, .m_fun = (void*)lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_OperatorOverloading_instSubPoint___lam__0___boxed, .m_arity = 2, .m_num_fixed = 0, .m_objs = {} };
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_OperatorOverloading_instSubPoint___closed__0 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_OperatorOverloading_instSubPoint___closed__0_value;
LEAN_EXPORT const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_OperatorOverloading_instSubPoint = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_OperatorOverloading_instSubPoint___closed__0_value;
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_OperatorOverloading_p__sub;
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_OperatorOverloading_p__sub__trunc;
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_OperatorOverloading_Point_scale(lean_object*, lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_OperatorOverloading_Point_scale___boxed(lean_object*, lean_object*);
static lean_once_cell_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_OperatorOverloading_p__scale___closed__0_once = LEAN_ONCE_CELL_INITIALIZER;
static lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_OperatorOverloading_p__scale___closed__0;
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_OperatorOverloading_p__scale;
LEAN_EXPORT uint8_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_OperatorOverloading_instOrdPoint___lam__0(lean_object*, lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_OperatorOverloading_instOrdPoint___lam__0___boxed(lean_object*, lean_object*);
static const lean_closure_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_OperatorOverloading_instOrdPoint___closed__0_value = {.m_header = {.m_rc = 0, .m_cs_sz = sizeof(lean_closure_object) + sizeof(void*)*0, .m_other = 0, .m_tag = 245}, .m_fun = (void*)lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_OperatorOverloading_instOrdPoint___lam__0___boxed, .m_arity = 2, .m_num_fixed = 0, .m_objs = {} };
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_OperatorOverloading_instOrdPoint___closed__0 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_OperatorOverloading_instOrdPoint___closed__0_value;
LEAN_EXPORT const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_OperatorOverloading_instOrdPoint = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_OperatorOverloading_instOrdPoint___closed__0_value;
LEAN_EXPORT uint8_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_OperatorOverloading_p__compare;
LEAN_EXPORT uint8_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_OperatorOverloading_p__lt;
LEAN_EXPORT uint8_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_OperatorOverloading_p__eq;
LEAN_EXPORT uint8_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_OperatorOverloading_p__gt;
static const lean_string_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_OperatorOverloading_str__concat___closed__0_value = {.m_header = {.m_rc = 0, .m_cs_sz = 0, .m_other = 0, .m_tag = 249}, .m_size = 14, .m_capacity = 14, .m_length = 13, .m_data = "Hello, World!"};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_OperatorOverloading_str__concat___closed__0 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_OperatorOverloading_str__concat___closed__0_value;
LEAN_EXPORT const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_OperatorOverloading_str__concat = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_OperatorOverloading_str__concat___closed__0_value;
static const lean_ctor_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_OperatorOverloading_list__concat___closed__0_value = {.m_header = {.m_rc = 0, .m_cs_sz = sizeof(lean_ctor_object) + sizeof(void*)*2 + 0, .m_other = 2, .m_tag = 1}, .m_objs = {((lean_object*)(((size_t)(2) << 1) | 1)),((lean_object*)(((size_t)(0) << 1) | 1))}};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_OperatorOverloading_list__concat___closed__0 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_OperatorOverloading_list__concat___closed__0_value;
static const lean_ctor_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_OperatorOverloading_list__concat___closed__1_value = {.m_header = {.m_rc = 0, .m_cs_sz = sizeof(lean_ctor_object) + sizeof(void*)*2 + 0, .m_other = 2, .m_tag = 1}, .m_objs = {((lean_object*)(((size_t)(1) << 1) | 1)),((lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_OperatorOverloading_list__concat___closed__0_value)}};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_OperatorOverloading_list__concat___closed__1 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_OperatorOverloading_list__concat___closed__1_value;
static const lean_ctor_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_OperatorOverloading_list__concat___closed__2_value = {.m_header = {.m_rc = 0, .m_cs_sz = sizeof(lean_ctor_object) + sizeof(void*)*2 + 0, .m_other = 2, .m_tag = 1}, .m_objs = {((lean_object*)(((size_t)(4) << 1) | 1)),((lean_object*)(((size_t)(0) << 1) | 1))}};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_OperatorOverloading_list__concat___closed__2 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_OperatorOverloading_list__concat___closed__2_value;
static const lean_ctor_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_OperatorOverloading_list__concat___closed__3_value = {.m_header = {.m_rc = 0, .m_cs_sz = sizeof(lean_ctor_object) + sizeof(void*)*2 + 0, .m_other = 2, .m_tag = 1}, .m_objs = {((lean_object*)(((size_t)(3) << 1) | 1)),((lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_OperatorOverloading_list__concat___closed__2_value)}};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_OperatorOverloading_list__concat___closed__3 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_OperatorOverloading_list__concat___closed__3_value;
static lean_once_cell_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_OperatorOverloading_list__concat___closed__4_once = LEAN_ONCE_CELL_INITIALIZER;
static lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_OperatorOverloading_list__concat___closed__4;
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_OperatorOverloading_list__concat;
static const lean_ctor_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_OperatorOverloading_list__cons___closed__0_value = {.m_header = {.m_rc = 0, .m_cs_sz = sizeof(lean_ctor_object) + sizeof(void*)*2 + 0, .m_other = 2, .m_tag = 1}, .m_objs = {((lean_object*)(((size_t)(3) << 1) | 1)),((lean_object*)(((size_t)(0) << 1) | 1))}};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_OperatorOverloading_list__cons___closed__0 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_OperatorOverloading_list__cons___closed__0_value;
static const lean_ctor_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_OperatorOverloading_list__cons___closed__1_value = {.m_header = {.m_rc = 0, .m_cs_sz = sizeof(lean_ctor_object) + sizeof(void*)*2 + 0, .m_other = 2, .m_tag = 1}, .m_objs = {((lean_object*)(((size_t)(2) << 1) | 1)),((lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_OperatorOverloading_list__cons___closed__0_value)}};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_OperatorOverloading_list__cons___closed__1 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_OperatorOverloading_list__cons___closed__1_value;
static const lean_ctor_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_OperatorOverloading_list__cons___closed__2_value = {.m_header = {.m_rc = 0, .m_cs_sz = sizeof(lean_ctor_object) + sizeof(void*)*2 + 0, .m_other = 2, .m_tag = 1}, .m_objs = {((lean_object*)(((size_t)(1) << 1) | 1)),((lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_OperatorOverloading_list__cons___closed__1_value)}};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_OperatorOverloading_list__cons___closed__2 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_OperatorOverloading_list__cons___closed__2_value;
LEAN_EXPORT const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_OperatorOverloading_list__cons = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_OperatorOverloading_list__cons___closed__2_value;
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_OperatorOverloading_nat__of__nat;
static lean_once_cell_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_OperatorOverloading_int__of__nat___closed__0_once = LEAN_ONCE_CELL_INITIALIZER;
static lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_OperatorOverloading_int__of__nat___closed__0;
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_OperatorOverloading_int__of__nat;
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_OperatorOverloading_instOfNatPoint(lean_object*);
static const lean_ctor_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_OperatorOverloading_p__of__nat___closed__0_value = {.m_header = {.m_rc = 0, .m_cs_sz = sizeof(lean_ctor_object) + sizeof(void*)*2 + 0, .m_other = 2, .m_tag = 0}, .m_objs = {((lean_object*)(((size_t)(5) << 1) | 1)),((lean_object*)(((size_t)(5) << 1) | 1))}};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_OperatorOverloading_p__of__nat___closed__0 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_OperatorOverloading_p__of__nat___closed__0_value;
LEAN_EXPORT const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_OperatorOverloading_p__of__nat = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_OperatorOverloading_p__of__nat___closed__0_value;
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_OperatorOverloading_instReprPoint_repr___redArg___closed__7(void){
_start:
{
lean_object* v___x_14_; lean_object* v___x_15_; 
v___x_14_ = lean_unsigned_to_nat(5u);
v___x_15_ = lean_nat_to_int(v___x_14_);
return v___x_15_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_OperatorOverloading_instReprPoint_repr___redArg___closed__13(void){
_start:
{
lean_object* v___x_23_; lean_object* v___x_24_; 
v___x_23_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_OperatorOverloading_instReprPoint_repr___redArg___closed__0));
v___x_24_ = lean_string_length(v___x_23_);
return v___x_24_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_OperatorOverloading_instReprPoint_repr___redArg___closed__14(void){
_start:
{
lean_object* v___x_25_; lean_object* v___x_26_; 
v___x_25_ = lean_obj_once(&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_OperatorOverloading_instReprPoint_repr___redArg___closed__13, &lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_OperatorOverloading_instReprPoint_repr___redArg___closed__13_once, _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_OperatorOverloading_instReprPoint_repr___redArg___closed__13);
v___x_26_ = lean_nat_to_int(v___x_25_);
return v___x_26_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_OperatorOverloading_instReprPoint_repr___redArg(lean_object* v_x_31_){
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
v___x_37_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_OperatorOverloading_instReprPoint_repr___redArg___closed__5));
v___x_38_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_OperatorOverloading_instReprPoint_repr___redArg___closed__6));
v___x_39_ = lean_obj_once(&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_OperatorOverloading_instReprPoint_repr___redArg___closed__7, &lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_OperatorOverloading_instReprPoint_repr___redArg___closed__7_once, _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_OperatorOverloading_instReprPoint_repr___redArg___closed__7);
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
v___x_47_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_OperatorOverloading_instReprPoint_repr___redArg___closed__9));
v___x_48_ = lean_alloc_ctor(5, 2, 0);
lean_ctor_set(v___x_48_, 0, v___x_46_);
lean_ctor_set(v___x_48_, 1, v___x_47_);
v___x_49_ = lean_box(1);
v___x_50_ = lean_alloc_ctor(5, 2, 0);
lean_ctor_set(v___x_50_, 0, v___x_48_);
lean_ctor_set(v___x_50_, 1, v___x_49_);
v___x_51_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_OperatorOverloading_instReprPoint_repr___redArg___closed__11));
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
v___x_59_ = lean_obj_once(&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_OperatorOverloading_instReprPoint_repr___redArg___closed__14, &lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_OperatorOverloading_instReprPoint_repr___redArg___closed__14_once, _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_OperatorOverloading_instReprPoint_repr___redArg___closed__14);
v___x_60_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_OperatorOverloading_instReprPoint_repr___redArg___closed__15));
v___x_61_ = lean_alloc_ctor(5, 2, 0);
lean_ctor_set(v___x_61_, 0, v___x_60_);
lean_ctor_set(v___x_61_, 1, v___x_58_);
v___x_62_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_OperatorOverloading_instReprPoint_repr___redArg___closed__16));
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
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_OperatorOverloading_instReprPoint_repr(lean_object* v_x_68_, lean_object* v_prec_69_){
_start:
{
lean_object* v___x_70_; 
v___x_70_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_OperatorOverloading_instReprPoint_repr___redArg(v_x_68_);
return v___x_70_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_OperatorOverloading_instReprPoint_repr___boxed(lean_object* v_x_71_, lean_object* v_prec_72_){
_start:
{
lean_object* v_res_73_; 
v_res_73_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_OperatorOverloading_instReprPoint_repr(v_x_71_, v_prec_72_);
lean_dec(v_prec_72_);
return v_res_73_;
}
}
LEAN_EXPORT uint8_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_OperatorOverloading_instDecidableEqPoint_decEq(lean_object* v_x_76_, lean_object* v_x_77_){
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
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_OperatorOverloading_instDecidableEqPoint_decEq___boxed(lean_object* v_x_84_, lean_object* v_x_85_){
_start:
{
uint8_t v_res_86_; lean_object* v_r_87_; 
v_res_86_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_OperatorOverloading_instDecidableEqPoint_decEq(v_x_84_, v_x_85_);
lean_dec_ref(v_x_85_);
lean_dec_ref(v_x_84_);
v_r_87_ = lean_box(v_res_86_);
return v_r_87_;
}
}
LEAN_EXPORT uint8_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_OperatorOverloading_instDecidableEqPoint(lean_object* v_x_88_, lean_object* v_x_89_){
_start:
{
uint8_t v___x_90_; 
v___x_90_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_OperatorOverloading_instDecidableEqPoint_decEq(v_x_88_, v_x_89_);
return v___x_90_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_OperatorOverloading_instDecidableEqPoint___boxed(lean_object* v_x_91_, lean_object* v_x_92_){
_start:
{
uint8_t v_res_93_; lean_object* v_r_94_; 
v_res_93_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_OperatorOverloading_instDecidableEqPoint(v_x_91_, v_x_92_);
lean_dec_ref(v_x_92_);
lean_dec_ref(v_x_91_);
v_r_94_ = lean_box(v_res_93_);
return v_r_94_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_OperatorOverloading_instAddPoint___lam__0(lean_object* v_p1_107_, lean_object* v_p2_108_){
_start:
{
lean_object* v_x_109_; lean_object* v_y_110_; lean_object* v_x_111_; lean_object* v_y_112_; lean_object* v___x_114_; uint8_t v_isShared_115_; uint8_t v_isSharedCheck_121_; 
v_x_109_ = lean_ctor_get(v_p1_107_, 0);
v_y_110_ = lean_ctor_get(v_p1_107_, 1);
v_x_111_ = lean_ctor_get(v_p2_108_, 0);
v_y_112_ = lean_ctor_get(v_p2_108_, 1);
v_isSharedCheck_121_ = !lean_is_exclusive(v_p2_108_);
if (v_isSharedCheck_121_ == 0)
{
v___x_114_ = v_p2_108_;
v_isShared_115_ = v_isSharedCheck_121_;
goto v_resetjp_113_;
}
else
{
lean_inc(v_y_112_);
lean_inc(v_x_111_);
lean_dec(v_p2_108_);
v___x_114_ = lean_box(0);
v_isShared_115_ = v_isSharedCheck_121_;
goto v_resetjp_113_;
}
v_resetjp_113_:
{
lean_object* v___x_116_; lean_object* v___x_117_; lean_object* v___x_119_; 
v___x_116_ = lean_nat_add(v_x_109_, v_x_111_);
lean_dec(v_x_111_);
v___x_117_ = lean_nat_add(v_y_110_, v_y_112_);
lean_dec(v_y_112_);
if (v_isShared_115_ == 0)
{
lean_ctor_set(v___x_114_, 1, v___x_117_);
lean_ctor_set(v___x_114_, 0, v___x_116_);
v___x_119_ = v___x_114_;
goto v_reusejp_118_;
}
else
{
lean_object* v_reuseFailAlloc_120_; 
v_reuseFailAlloc_120_ = lean_alloc_ctor(0, 2, 0);
lean_ctor_set(v_reuseFailAlloc_120_, 0, v___x_116_);
lean_ctor_set(v_reuseFailAlloc_120_, 1, v___x_117_);
v___x_119_ = v_reuseFailAlloc_120_;
goto v_reusejp_118_;
}
v_reusejp_118_:
{
return v___x_119_;
}
}
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_OperatorOverloading_instAddPoint___lam__0___boxed(lean_object* v_p1_122_, lean_object* v_p2_123_){
_start:
{
lean_object* v_res_124_; 
v_res_124_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_OperatorOverloading_instAddPoint___lam__0(v_p1_122_, v_p2_123_);
lean_dec_ref(v_p1_122_);
return v_res_124_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_OperatorOverloading_p__add(void){
_start:
{
lean_object* v___x_127_; lean_object* v_x_128_; lean_object* v_y_129_; lean_object* v___x_130_; lean_object* v_x_131_; lean_object* v_y_132_; lean_object* v___x_133_; lean_object* v___x_134_; lean_object* v___x_135_; 
v___x_127_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_OperatorOverloading_p1));
v_x_128_ = lean_ctor_get(v___x_127_, 0);
v_y_129_ = lean_ctor_get(v___x_127_, 1);
v___x_130_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_OperatorOverloading_p2));
v_x_131_ = lean_ctor_get(v___x_130_, 0);
v_y_132_ = lean_ctor_get(v___x_130_, 1);
v___x_133_ = lean_nat_add(v_x_128_, v_x_131_);
v___x_134_ = lean_nat_add(v_y_129_, v_y_132_);
v___x_135_ = lean_alloc_ctor(0, 2, 0);
lean_ctor_set(v___x_135_, 0, v___x_133_);
lean_ctor_set(v___x_135_, 1, v___x_134_);
return v___x_135_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_OperatorOverloading_p__add3(void){
_start:
{
lean_object* v___x_136_; lean_object* v_x_137_; lean_object* v_y_138_; lean_object* v___x_139_; lean_object* v_x_140_; lean_object* v_y_141_; lean_object* v___x_142_; lean_object* v_x_143_; lean_object* v_y_144_; lean_object* v___x_145_; lean_object* v___x_146_; lean_object* v___x_147_; lean_object* v___x_148_; lean_object* v___x_149_; 
v___x_136_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_OperatorOverloading_p1));
v_x_137_ = lean_ctor_get(v___x_136_, 0);
v_y_138_ = lean_ctor_get(v___x_136_, 1);
v___x_139_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_OperatorOverloading_p2));
v_x_140_ = lean_ctor_get(v___x_139_, 0);
v_y_141_ = lean_ctor_get(v___x_139_, 1);
v___x_142_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_OperatorOverloading_p3));
v_x_143_ = lean_ctor_get(v___x_142_, 0);
v_y_144_ = lean_ctor_get(v___x_142_, 1);
v___x_145_ = lean_nat_add(v_x_137_, v_x_140_);
v___x_146_ = lean_nat_add(v_y_138_, v_y_141_);
v___x_147_ = lean_nat_add(v___x_145_, v_x_143_);
lean_dec(v___x_145_);
v___x_148_ = lean_nat_add(v___x_146_, v_y_144_);
lean_dec(v___x_146_);
v___x_149_ = lean_alloc_ctor(0, 2, 0);
lean_ctor_set(v___x_149_, 0, v___x_147_);
lean_ctor_set(v___x_149_, 1, v___x_148_);
return v___x_149_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_OperatorOverloading_instSubPoint___lam__0(lean_object* v_p1_154_, lean_object* v_p2_155_){
_start:
{
lean_object* v_x_156_; lean_object* v_y_157_; lean_object* v_x_158_; lean_object* v_y_159_; lean_object* v___x_161_; uint8_t v_isShared_162_; uint8_t v_isSharedCheck_168_; 
v_x_156_ = lean_ctor_get(v_p1_154_, 0);
v_y_157_ = lean_ctor_get(v_p1_154_, 1);
v_x_158_ = lean_ctor_get(v_p2_155_, 0);
v_y_159_ = lean_ctor_get(v_p2_155_, 1);
v_isSharedCheck_168_ = !lean_is_exclusive(v_p2_155_);
if (v_isSharedCheck_168_ == 0)
{
v___x_161_ = v_p2_155_;
v_isShared_162_ = v_isSharedCheck_168_;
goto v_resetjp_160_;
}
else
{
lean_inc(v_y_159_);
lean_inc(v_x_158_);
lean_dec(v_p2_155_);
v___x_161_ = lean_box(0);
v_isShared_162_ = v_isSharedCheck_168_;
goto v_resetjp_160_;
}
v_resetjp_160_:
{
lean_object* v___x_163_; lean_object* v___x_164_; lean_object* v___x_166_; 
v___x_163_ = lean_nat_sub(v_x_156_, v_x_158_);
lean_dec(v_x_158_);
v___x_164_ = lean_nat_sub(v_y_157_, v_y_159_);
lean_dec(v_y_159_);
if (v_isShared_162_ == 0)
{
lean_ctor_set(v___x_161_, 1, v___x_164_);
lean_ctor_set(v___x_161_, 0, v___x_163_);
v___x_166_ = v___x_161_;
goto v_reusejp_165_;
}
else
{
lean_object* v_reuseFailAlloc_167_; 
v_reuseFailAlloc_167_ = lean_alloc_ctor(0, 2, 0);
lean_ctor_set(v_reuseFailAlloc_167_, 0, v___x_163_);
lean_ctor_set(v_reuseFailAlloc_167_, 1, v___x_164_);
v___x_166_ = v_reuseFailAlloc_167_;
goto v_reusejp_165_;
}
v_reusejp_165_:
{
return v___x_166_;
}
}
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_OperatorOverloading_instSubPoint___lam__0___boxed(lean_object* v_p1_169_, lean_object* v_p2_170_){
_start:
{
lean_object* v_res_171_; 
v_res_171_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_OperatorOverloading_instSubPoint___lam__0(v_p1_169_, v_p2_170_);
lean_dec_ref(v_p1_169_);
return v_res_171_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_OperatorOverloading_p__sub(void){
_start:
{
lean_object* v___x_174_; lean_object* v_x_175_; lean_object* v_y_176_; lean_object* v___x_177_; lean_object* v_x_178_; lean_object* v_y_179_; lean_object* v___x_180_; lean_object* v___x_181_; lean_object* v___x_182_; 
v___x_174_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_OperatorOverloading_p3));
v_x_175_ = lean_ctor_get(v___x_174_, 0);
v_y_176_ = lean_ctor_get(v___x_174_, 1);
v___x_177_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_OperatorOverloading_p1));
v_x_178_ = lean_ctor_get(v___x_177_, 0);
v_y_179_ = lean_ctor_get(v___x_177_, 1);
v___x_180_ = lean_nat_sub(v_x_175_, v_x_178_);
v___x_181_ = lean_nat_sub(v_y_176_, v_y_179_);
v___x_182_ = lean_alloc_ctor(0, 2, 0);
lean_ctor_set(v___x_182_, 0, v___x_180_);
lean_ctor_set(v___x_182_, 1, v___x_181_);
return v___x_182_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_OperatorOverloading_p__sub__trunc(void){
_start:
{
lean_object* v___x_183_; lean_object* v_x_184_; lean_object* v_y_185_; lean_object* v___x_186_; lean_object* v_x_187_; lean_object* v_y_188_; lean_object* v___x_189_; lean_object* v___x_190_; lean_object* v___x_191_; 
v___x_183_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_OperatorOverloading_p1));
v_x_184_ = lean_ctor_get(v___x_183_, 0);
v_y_185_ = lean_ctor_get(v___x_183_, 1);
v___x_186_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_OperatorOverloading_p3));
v_x_187_ = lean_ctor_get(v___x_186_, 0);
v_y_188_ = lean_ctor_get(v___x_186_, 1);
v___x_189_ = lean_nat_sub(v_x_184_, v_x_187_);
v___x_190_ = lean_nat_sub(v_y_185_, v_y_188_);
v___x_191_ = lean_alloc_ctor(0, 2, 0);
lean_ctor_set(v___x_191_, 0, v___x_189_);
lean_ctor_set(v___x_191_, 1, v___x_190_);
return v___x_191_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_OperatorOverloading_Point_scale(lean_object* v_p_192_, lean_object* v_s_193_){
_start:
{
lean_object* v_x_194_; lean_object* v_y_195_; lean_object* v___x_197_; uint8_t v_isShared_198_; uint8_t v_isSharedCheck_204_; 
v_x_194_ = lean_ctor_get(v_p_192_, 0);
v_y_195_ = lean_ctor_get(v_p_192_, 1);
v_isSharedCheck_204_ = !lean_is_exclusive(v_p_192_);
if (v_isSharedCheck_204_ == 0)
{
v___x_197_ = v_p_192_;
v_isShared_198_ = v_isSharedCheck_204_;
goto v_resetjp_196_;
}
else
{
lean_inc(v_y_195_);
lean_inc(v_x_194_);
lean_dec(v_p_192_);
v___x_197_ = lean_box(0);
v_isShared_198_ = v_isSharedCheck_204_;
goto v_resetjp_196_;
}
v_resetjp_196_:
{
lean_object* v___x_199_; lean_object* v___x_200_; lean_object* v___x_202_; 
v___x_199_ = lean_nat_mul(v_x_194_, v_s_193_);
lean_dec(v_x_194_);
v___x_200_ = lean_nat_mul(v_y_195_, v_s_193_);
lean_dec(v_y_195_);
if (v_isShared_198_ == 0)
{
lean_ctor_set(v___x_197_, 1, v___x_200_);
lean_ctor_set(v___x_197_, 0, v___x_199_);
v___x_202_ = v___x_197_;
goto v_reusejp_201_;
}
else
{
lean_object* v_reuseFailAlloc_203_; 
v_reuseFailAlloc_203_ = lean_alloc_ctor(0, 2, 0);
lean_ctor_set(v_reuseFailAlloc_203_, 0, v___x_199_);
lean_ctor_set(v_reuseFailAlloc_203_, 1, v___x_200_);
v___x_202_ = v_reuseFailAlloc_203_;
goto v_reusejp_201_;
}
v_reusejp_201_:
{
return v___x_202_;
}
}
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_OperatorOverloading_Point_scale___boxed(lean_object* v_p_205_, lean_object* v_s_206_){
_start:
{
lean_object* v_res_207_; 
v_res_207_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_OperatorOverloading_Point_scale(v_p_205_, v_s_206_);
lean_dec(v_s_206_);
return v_res_207_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_OperatorOverloading_p__scale___closed__0(void){
_start:
{
lean_object* v___x_208_; lean_object* v___x_209_; lean_object* v___x_210_; 
v___x_208_ = lean_unsigned_to_nat(3u);
v___x_209_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_OperatorOverloading_p1));
v___x_210_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_OperatorOverloading_Point_scale(v___x_209_, v___x_208_);
return v___x_210_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_OperatorOverloading_p__scale(void){
_start:
{
lean_object* v___x_211_; 
v___x_211_ = lean_obj_once(&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_OperatorOverloading_p__scale___closed__0, &lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_OperatorOverloading_p__scale___closed__0_once, _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_OperatorOverloading_p__scale___closed__0);
return v___x_211_;
}
}
LEAN_EXPORT uint8_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_OperatorOverloading_instOrdPoint___lam__0(lean_object* v_p1_212_, lean_object* v_p2_213_){
_start:
{
lean_object* v_x_214_; lean_object* v_y_215_; lean_object* v_x_216_; lean_object* v_y_217_; uint8_t v___x_218_; 
v_x_214_ = lean_ctor_get(v_p1_212_, 0);
v_y_215_ = lean_ctor_get(v_p1_212_, 1);
v_x_216_ = lean_ctor_get(v_p2_213_, 0);
v_y_217_ = lean_ctor_get(v_p2_213_, 1);
v___x_218_ = lean_nat_dec_lt(v_x_214_, v_x_216_);
if (v___x_218_ == 0)
{
uint8_t v___x_219_; 
v___x_219_ = lean_nat_dec_eq(v_x_214_, v_x_216_);
if (v___x_219_ == 0)
{
uint8_t v___x_220_; 
v___x_220_ = 2;
return v___x_220_;
}
else
{
uint8_t v___x_221_; 
v___x_221_ = lean_nat_dec_lt(v_y_215_, v_y_217_);
if (v___x_221_ == 0)
{
uint8_t v___x_222_; 
v___x_222_ = lean_nat_dec_eq(v_y_215_, v_y_217_);
if (v___x_222_ == 0)
{
uint8_t v___x_223_; 
v___x_223_ = 2;
return v___x_223_;
}
else
{
uint8_t v___x_224_; 
v___x_224_ = 1;
return v___x_224_;
}
}
else
{
uint8_t v___x_225_; 
v___x_225_ = 0;
return v___x_225_;
}
}
}
else
{
uint8_t v___x_226_; 
v___x_226_ = 0;
return v___x_226_;
}
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_OperatorOverloading_instOrdPoint___lam__0___boxed(lean_object* v_p1_227_, lean_object* v_p2_228_){
_start:
{
uint8_t v_res_229_; lean_object* v_r_230_; 
v_res_229_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_OperatorOverloading_instOrdPoint___lam__0(v_p1_227_, v_p2_228_);
lean_dec_ref(v_p2_228_);
lean_dec_ref(v_p1_227_);
v_r_230_ = lean_box(v_res_229_);
return v_r_230_;
}
}
static uint8_t _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_OperatorOverloading_p__compare(void){
_start:
{
lean_object* v___x_233_; lean_object* v_x_234_; lean_object* v_y_235_; lean_object* v___x_236_; lean_object* v_x_237_; lean_object* v_y_238_; uint8_t v___x_239_; 
v___x_233_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_OperatorOverloading_p1));
v_x_234_ = lean_ctor_get(v___x_233_, 0);
v_y_235_ = lean_ctor_get(v___x_233_, 1);
v___x_236_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_OperatorOverloading_p2));
v_x_237_ = lean_ctor_get(v___x_236_, 0);
v_y_238_ = lean_ctor_get(v___x_236_, 1);
v___x_239_ = lean_nat_dec_lt(v_x_234_, v_x_237_);
if (v___x_239_ == 0)
{
uint8_t v___x_240_; 
v___x_240_ = lean_nat_dec_eq(v_x_234_, v_x_237_);
if (v___x_240_ == 0)
{
uint8_t v___x_241_; 
v___x_241_ = 2;
return v___x_241_;
}
else
{
uint8_t v___x_242_; 
v___x_242_ = lean_nat_dec_lt(v_y_235_, v_y_238_);
if (v___x_242_ == 0)
{
uint8_t v___x_243_; 
v___x_243_ = lean_nat_dec_eq(v_y_235_, v_y_238_);
if (v___x_243_ == 0)
{
uint8_t v___x_244_; 
v___x_244_ = 2;
return v___x_244_;
}
else
{
uint8_t v___x_245_; 
v___x_245_ = 1;
return v___x_245_;
}
}
else
{
uint8_t v___x_246_; 
v___x_246_ = 0;
return v___x_246_;
}
}
}
else
{
uint8_t v___x_247_; 
v___x_247_ = 0;
return v___x_247_;
}
}
}
static uint8_t _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_OperatorOverloading_p__lt(void){
_start:
{
uint8_t v___y_249_; lean_object* v___x_252_; lean_object* v_x_253_; lean_object* v_y_254_; lean_object* v___x_255_; lean_object* v_x_256_; lean_object* v_y_257_; uint8_t v___x_258_; 
v___x_252_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_OperatorOverloading_p1));
v_x_253_ = lean_ctor_get(v___x_252_, 0);
v_y_254_ = lean_ctor_get(v___x_252_, 1);
v___x_255_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_OperatorOverloading_p2));
v_x_256_ = lean_ctor_get(v___x_255_, 0);
v_y_257_ = lean_ctor_get(v___x_255_, 1);
v___x_258_ = lean_nat_dec_lt(v_x_253_, v_x_256_);
if (v___x_258_ == 0)
{
uint8_t v___x_259_; 
v___x_259_ = lean_nat_dec_eq(v_x_253_, v_x_256_);
if (v___x_259_ == 0)
{
uint8_t v___x_260_; 
v___x_260_ = 2;
v___y_249_ = v___x_260_;
goto v___jp_248_;
}
else
{
uint8_t v___x_261_; 
v___x_261_ = lean_nat_dec_lt(v_y_254_, v_y_257_);
if (v___x_261_ == 0)
{
uint8_t v___x_262_; 
v___x_262_ = lean_nat_dec_eq(v_y_254_, v_y_257_);
if (v___x_262_ == 0)
{
uint8_t v___x_263_; 
v___x_263_ = 2;
v___y_249_ = v___x_263_;
goto v___jp_248_;
}
else
{
uint8_t v___x_264_; 
v___x_264_ = 1;
v___y_249_ = v___x_264_;
goto v___jp_248_;
}
}
else
{
uint8_t v___x_265_; 
v___x_265_ = 0;
v___y_249_ = v___x_265_;
goto v___jp_248_;
}
}
}
else
{
uint8_t v___x_266_; 
v___x_266_ = 0;
v___y_249_ = v___x_266_;
goto v___jp_248_;
}
v___jp_248_:
{
uint8_t v___x_250_; uint8_t v___x_251_; 
v___x_250_ = 0;
v___x_251_ = l_instDecidableEqOrdering(v___y_249_, v___x_250_);
return v___x_251_;
}
}
}
static uint8_t _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_OperatorOverloading_p__eq(void){
_start:
{
uint8_t v___y_268_; lean_object* v___x_271_; lean_object* v_x_272_; lean_object* v_y_273_; uint8_t v___x_274_; 
v___x_271_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_OperatorOverloading_p1));
v_x_272_ = lean_ctor_get(v___x_271_, 0);
v_y_273_ = lean_ctor_get(v___x_271_, 1);
v___x_274_ = lean_nat_dec_lt(v_x_272_, v_x_272_);
if (v___x_274_ == 0)
{
uint8_t v___x_275_; 
v___x_275_ = lean_nat_dec_eq(v_x_272_, v_x_272_);
if (v___x_275_ == 0)
{
uint8_t v___x_276_; 
v___x_276_ = 2;
v___y_268_ = v___x_276_;
goto v___jp_267_;
}
else
{
uint8_t v___x_277_; 
v___x_277_ = lean_nat_dec_lt(v_y_273_, v_y_273_);
if (v___x_277_ == 0)
{
uint8_t v___x_278_; 
v___x_278_ = lean_nat_dec_eq(v_y_273_, v_y_273_);
if (v___x_278_ == 0)
{
uint8_t v___x_279_; 
v___x_279_ = 2;
v___y_268_ = v___x_279_;
goto v___jp_267_;
}
else
{
uint8_t v___x_280_; 
v___x_280_ = 1;
v___y_268_ = v___x_280_;
goto v___jp_267_;
}
}
else
{
uint8_t v___x_281_; 
v___x_281_ = 0;
v___y_268_ = v___x_281_;
goto v___jp_267_;
}
}
}
else
{
uint8_t v___x_282_; 
v___x_282_ = 0;
v___y_268_ = v___x_282_;
goto v___jp_267_;
}
v___jp_267_:
{
uint8_t v___x_269_; uint8_t v___x_270_; 
v___x_269_ = 1;
v___x_270_ = l_instDecidableEqOrdering(v___y_268_, v___x_269_);
return v___x_270_;
}
}
}
static uint8_t _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_OperatorOverloading_p__gt(void){
_start:
{
uint8_t v___y_284_; lean_object* v___x_287_; lean_object* v_x_288_; lean_object* v_y_289_; lean_object* v___x_290_; lean_object* v_x_291_; lean_object* v_y_292_; uint8_t v___x_293_; 
v___x_287_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_OperatorOverloading_p3));
v_x_288_ = lean_ctor_get(v___x_287_, 0);
v_y_289_ = lean_ctor_get(v___x_287_, 1);
v___x_290_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_OperatorOverloading_p2));
v_x_291_ = lean_ctor_get(v___x_290_, 0);
v_y_292_ = lean_ctor_get(v___x_290_, 1);
v___x_293_ = lean_nat_dec_lt(v_x_288_, v_x_291_);
if (v___x_293_ == 0)
{
uint8_t v___x_294_; 
v___x_294_ = lean_nat_dec_eq(v_x_288_, v_x_291_);
if (v___x_294_ == 0)
{
uint8_t v___x_295_; 
v___x_295_ = 2;
v___y_284_ = v___x_295_;
goto v___jp_283_;
}
else
{
uint8_t v___x_296_; 
v___x_296_ = lean_nat_dec_lt(v_y_289_, v_y_292_);
if (v___x_296_ == 0)
{
uint8_t v___x_297_; 
v___x_297_ = lean_nat_dec_eq(v_y_289_, v_y_292_);
if (v___x_297_ == 0)
{
uint8_t v___x_298_; 
v___x_298_ = 2;
v___y_284_ = v___x_298_;
goto v___jp_283_;
}
else
{
uint8_t v___x_299_; 
v___x_299_ = 1;
v___y_284_ = v___x_299_;
goto v___jp_283_;
}
}
else
{
uint8_t v___x_300_; 
v___x_300_ = 0;
v___y_284_ = v___x_300_;
goto v___jp_283_;
}
}
}
else
{
uint8_t v___x_301_; 
v___x_301_ = 0;
v___y_284_ = v___x_301_;
goto v___jp_283_;
}
v___jp_283_:
{
uint8_t v___x_285_; uint8_t v___x_286_; 
v___x_285_ = 2;
v___x_286_ = l_instDecidableEqOrdering(v___y_284_, v___x_285_);
return v___x_286_;
}
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_OperatorOverloading_list__concat___closed__4(void){
_start:
{
lean_object* v___x_316_; lean_object* v___x_317_; lean_object* v___x_318_; 
v___x_316_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_OperatorOverloading_list__concat___closed__3));
v___x_317_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_OperatorOverloading_list__concat___closed__1));
v___x_318_ = l_List_appendTR___redArg(v___x_317_, v___x_316_);
return v___x_318_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_OperatorOverloading_list__concat(void){
_start:
{
lean_object* v___x_319_; 
v___x_319_ = lean_obj_once(&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_OperatorOverloading_list__concat___closed__4, &lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_OperatorOverloading_list__concat___closed__4_once, _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_OperatorOverloading_list__concat___closed__4);
return v___x_319_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_OperatorOverloading_nat__of__nat(void){
_start:
{
lean_object* v___x_330_; 
v___x_330_ = lean_unsigned_to_nat(42u);
return v___x_330_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_OperatorOverloading_int__of__nat___closed__0(void){
_start:
{
lean_object* v___x_331_; lean_object* v___x_332_; 
v___x_331_ = lean_unsigned_to_nat(42u);
v___x_332_ = lean_nat_to_int(v___x_331_);
return v___x_332_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_OperatorOverloading_int__of__nat(void){
_start:
{
lean_object* v___x_333_; 
v___x_333_ = lean_obj_once(&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_OperatorOverloading_int__of__nat___closed__0, &lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_OperatorOverloading_int__of__nat___closed__0_once, _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_OperatorOverloading_int__of__nat___closed__0);
return v___x_333_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_OperatorOverloading_instOfNatPoint(lean_object* v_n_334_){
_start:
{
lean_object* v___x_335_; 
lean_inc(v_n_334_);
v___x_335_ = lean_alloc_ctor(0, 2, 0);
lean_ctor_set(v___x_335_, 0, v_n_334_);
lean_ctor_set(v___x_335_, 1, v_n_334_);
return v___x_335_;
}
}
lean_object* initialize_Init(uint8_t builtin);
lean_object* initialize_Init(uint8_t builtin);
static bool _G_initialized = false;
LEAN_EXPORT lean_object* initialize_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_OperatorOverloading(uint8_t builtin) {
lean_object * res;
if (_G_initialized) return lean_io_result_mk_ok(lean_box(0));
_G_initialized = true;
res = initialize_Init(builtin);
if (lean_io_result_is_error(res)) return res;
lean_dec_ref(res);
res = initialize_Init(builtin);
if (lean_io_result_is_error(res)) return res;
lean_dec_ref(res);
lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_OperatorOverloading_p__add = _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_OperatorOverloading_p__add();
lean_mark_persistent(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_OperatorOverloading_p__add);
lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_OperatorOverloading_p__add3 = _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_OperatorOverloading_p__add3();
lean_mark_persistent(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_OperatorOverloading_p__add3);
lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_OperatorOverloading_p__sub = _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_OperatorOverloading_p__sub();
lean_mark_persistent(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_OperatorOverloading_p__sub);
lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_OperatorOverloading_p__sub__trunc = _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_OperatorOverloading_p__sub__trunc();
lean_mark_persistent(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_OperatorOverloading_p__sub__trunc);
lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_OperatorOverloading_p__scale = _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_OperatorOverloading_p__scale();
lean_mark_persistent(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_OperatorOverloading_p__scale);
lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_OperatorOverloading_p__compare = _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_OperatorOverloading_p__compare();
lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_OperatorOverloading_p__lt = _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_OperatorOverloading_p__lt();
lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_OperatorOverloading_p__eq = _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_OperatorOverloading_p__eq();
lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_OperatorOverloading_p__gt = _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_OperatorOverloading_p__gt();
lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_OperatorOverloading_list__concat = _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_OperatorOverloading_list__concat();
lean_mark_persistent(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_OperatorOverloading_list__concat);
lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_OperatorOverloading_nat__of__nat = _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_OperatorOverloading_nat__of__nat();
lean_mark_persistent(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_OperatorOverloading_nat__of__nat);
lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_OperatorOverloading_int__of__nat = _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_OperatorOverloading_int__of__nat();
lean_mark_persistent(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_OperatorOverloading_int__of__nat);
return lean_io_result_mk_ok(lean_box(0));
}
#ifdef __cplusplus
}
#endif
