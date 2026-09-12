// Lean compiler output
// Module: Lean4Tutorial.Examples.InductiveTypes.RecursiveTypes
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
lean_object* lean_nat_mul(lean_object*, lean_object*);
lean_object* l_List_reverse___redArg(lean_object*);
lean_object* l_List_appendTR___redArg(lean_object*, lean_object*);
uint8_t lean_nat_dec_le(lean_object*, lean_object*);
lean_object* l_Repr_addAppParen(lean_object*, lean_object*);
lean_object* lean_nat_to_int(lean_object*);
lean_object* l_List_lengthTR___redArg(lean_object*);
lean_object* l_Nat_mul___boxed(lean_object*, lean_object*);
lean_object* lean_array_mk(lean_object*);
lean_object* lean_array_get_size(lean_object*);
uint8_t lean_nat_dec_lt(lean_object*, lean_object*);
size_t lean_usize_of_nat(lean_object*);
uint8_t lean_usize_dec_eq(size_t, size_t);
size_t lean_usize_sub(size_t, size_t);
lean_object* lean_array_uget_borrowed(lean_object*, size_t);
lean_object* lean_nat_mod(lean_object*, lean_object*);
uint8_t lean_nat_dec_eq(lean_object*, lean_object*);
lean_object* l_List_head_x3f___redArg(lean_object*);
lean_object* lean_nat_sub(lean_object*, lean_object*);
lean_object* l_Nat_add___boxed(lean_object*, lean_object*);
lean_object* l_List_tail_x21___redArg(lean_object*);
lean_object* l_Nat_reprFast(lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_MyNat_ctorIdx(lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_MyNat_ctorIdx___boxed(lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_MyNat_ctorElim___redArg(lean_object*, lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_MyNat_ctorElim(lean_object*, lean_object*, lean_object*, lean_object*, lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_MyNat_ctorElim___boxed(lean_object*, lean_object*, lean_object*, lean_object*, lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_MyNat_zero_elim___redArg(lean_object*, lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_MyNat_zero_elim(lean_object*, lean_object*, lean_object*, lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_MyNat_succ_elim___redArg(lean_object*, lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_MyNat_succ_elim(lean_object*, lean_object*, lean_object*, lean_object*);
static const lean_string_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_instReprMyNat_repr___closed__0_value = {.m_header = {.m_rc = 0, .m_cs_sz = 0, .m_other = 0, .m_tag = 249}, .m_size = 64, .m_capacity = 64, .m_length = 63, .m_data = "Lean4Tutorial.Examples.InductiveTypes.RecursiveTypes.MyNat.zero"};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_instReprMyNat_repr___closed__0 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_instReprMyNat_repr___closed__0_value;
static const lean_ctor_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_instReprMyNat_repr___closed__1_value = {.m_header = {.m_rc = 0, .m_cs_sz = sizeof(lean_ctor_object) + sizeof(void*)*1 + 0, .m_other = 1, .m_tag = 3}, .m_objs = {((lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_instReprMyNat_repr___closed__0_value)}};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_instReprMyNat_repr___closed__1 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_instReprMyNat_repr___closed__1_value;
static lean_once_cell_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_instReprMyNat_repr___closed__2_once = LEAN_ONCE_CELL_INITIALIZER;
static lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_instReprMyNat_repr___closed__2;
static lean_once_cell_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_instReprMyNat_repr___closed__3_once = LEAN_ONCE_CELL_INITIALIZER;
static lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_instReprMyNat_repr___closed__3;
static const lean_string_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_instReprMyNat_repr___closed__4_value = {.m_header = {.m_rc = 0, .m_cs_sz = 0, .m_other = 0, .m_tag = 249}, .m_size = 64, .m_capacity = 64, .m_length = 63, .m_data = "Lean4Tutorial.Examples.InductiveTypes.RecursiveTypes.MyNat.succ"};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_instReprMyNat_repr___closed__4 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_instReprMyNat_repr___closed__4_value;
static const lean_ctor_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_instReprMyNat_repr___closed__5_value = {.m_header = {.m_rc = 0, .m_cs_sz = sizeof(lean_ctor_object) + sizeof(void*)*1 + 0, .m_other = 1, .m_tag = 3}, .m_objs = {((lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_instReprMyNat_repr___closed__4_value)}};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_instReprMyNat_repr___closed__5 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_instReprMyNat_repr___closed__5_value;
static const lean_ctor_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_instReprMyNat_repr___closed__6_value = {.m_header = {.m_rc = 0, .m_cs_sz = sizeof(lean_ctor_object) + sizeof(void*)*2 + 0, .m_other = 2, .m_tag = 5}, .m_objs = {((lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_instReprMyNat_repr___closed__5_value),((lean_object*)(((size_t)(1) << 1) | 1))}};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_instReprMyNat_repr___closed__6 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_instReprMyNat_repr___closed__6_value;
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_instReprMyNat_repr(lean_object*, lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_instReprMyNat_repr___boxed(lean_object*, lean_object*);
static const lean_closure_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_instReprMyNat___closed__0_value = {.m_header = {.m_rc = 0, .m_cs_sz = sizeof(lean_closure_object) + sizeof(void*)*0, .m_other = 0, .m_tag = 245}, .m_fun = (void*)lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_instReprMyNat_repr___boxed, .m_arity = 2, .m_num_fixed = 0, .m_objs = {} };
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_instReprMyNat___closed__0 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_instReprMyNat___closed__0_value;
LEAN_EXPORT const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_instReprMyNat = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_instReprMyNat___closed__0_value;
LEAN_EXPORT uint8_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_instDecidableEqMyNat_decEq(lean_object*, lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_instDecidableEqMyNat_decEq___boxed(lean_object*, lean_object*);
LEAN_EXPORT uint8_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_instDecidableEqMyNat(lean_object*, lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_instDecidableEqMyNat___boxed(lean_object*, lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_my__zero;
static const lean_ctor_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_my__one___closed__0_value = {.m_header = {.m_rc = 0, .m_cs_sz = sizeof(lean_ctor_object) + sizeof(void*)*1 + 0, .m_other = 1, .m_tag = 1}, .m_objs = {((lean_object*)(((size_t)(0) << 1) | 1))}};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_my__one___closed__0 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_my__one___closed__0_value;
LEAN_EXPORT const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_my__one = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_my__one___closed__0_value;
static const lean_ctor_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_my__two___closed__0_value = {.m_header = {.m_rc = 0, .m_cs_sz = sizeof(lean_ctor_object) + sizeof(void*)*1 + 0, .m_other = 1, .m_tag = 1}, .m_objs = {((lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_my__one___closed__0_value)}};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_my__two___closed__0 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_my__two___closed__0_value;
LEAN_EXPORT const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_my__two = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_my__two___closed__0_value;
static const lean_ctor_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_my__three___closed__0_value = {.m_header = {.m_rc = 0, .m_cs_sz = sizeof(lean_ctor_object) + sizeof(void*)*1 + 0, .m_other = 1, .m_tag = 1}, .m_objs = {((lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_my__two___closed__0_value)}};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_my__three___closed__0 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_my__three___closed__0_value;
LEAN_EXPORT const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_my__three = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_my__three___closed__0_value;
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_add(lean_object*, lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_add___boxed(lean_object*, lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_mul(lean_object*, lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_mul___boxed(lean_object*, lean_object*);
static lean_once_cell_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_two__plus__three___closed__0_once = LEAN_ONCE_CELL_INITIALIZER;
static lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_two__plus__three___closed__0;
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_two__plus__three;
static lean_once_cell_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_two__times__three___closed__0_once = LEAN_ONCE_CELL_INITIALIZER;
static lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_two__times__three___closed__0;
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_two__times__three;
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_MyNat_toNat(lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_MyNat_toNat___boxed(lean_object*);
static lean_once_cell_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_three__to__nat___closed__0_once = LEAN_ONCE_CELL_INITIALIZER;
static lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_three__to__nat___closed__0;
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_three__to__nat;
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_MyNat_ofNat(lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_MyNat_ofNat___boxed(lean_object*);
static lean_once_cell_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_five__of__nat___closed__0_once = LEAN_ONCE_CELL_INITIALIZER;
static lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_five__of__nat___closed__0;
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_five__of__nat;
LEAN_EXPORT uint8_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_leq(lean_object*, lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_leq___boxed(lean_object*, lean_object*);
static lean_once_cell_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_leq__example1___closed__0_once = LEAN_ONCE_CELL_INITIALIZER;
static uint8_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_leq__example1___closed__0;
LEAN_EXPORT uint8_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_leq__example1;
static lean_once_cell_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_leq__example2___closed__0_once = LEAN_ONCE_CELL_INITIALIZER;
static uint8_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_leq__example2___closed__0;
LEAN_EXPORT uint8_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_leq__example2;
static lean_once_cell_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_eq__example___closed__0_once = LEAN_ONCE_CELL_INITIALIZER;
static uint8_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_eq__example___closed__0;
LEAN_EXPORT uint8_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_eq__example;
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_MyList_ctorIdx___redArg(lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_MyList_ctorIdx___redArg___boxed(lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_MyList_ctorIdx(lean_object*, lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_MyList_ctorIdx___boxed(lean_object*, lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_MyList_ctorElim___redArg(lean_object*, lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_MyList_ctorElim(lean_object*, lean_object*, lean_object*, lean_object*, lean_object*, lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_MyList_ctorElim___boxed(lean_object*, lean_object*, lean_object*, lean_object*, lean_object*, lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_MyList_nil_elim___redArg(lean_object*, lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_MyList_nil_elim(lean_object*, lean_object*, lean_object*, lean_object*, lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_MyList_cons_elim___redArg(lean_object*, lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_MyList_cons_elim(lean_object*, lean_object*, lean_object*, lean_object*, lean_object*);
static const lean_string_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_instReprMyList_repr___redArg___closed__0_value = {.m_header = {.m_rc = 0, .m_cs_sz = 0, .m_other = 0, .m_tag = 249}, .m_size = 64, .m_capacity = 64, .m_length = 63, .m_data = "Lean4Tutorial.Examples.InductiveTypes.RecursiveTypes.MyList.nil"};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_instReprMyList_repr___redArg___closed__0 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_instReprMyList_repr___redArg___closed__0_value;
static const lean_ctor_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_instReprMyList_repr___redArg___closed__1_value = {.m_header = {.m_rc = 0, .m_cs_sz = sizeof(lean_ctor_object) + sizeof(void*)*1 + 0, .m_other = 1, .m_tag = 3}, .m_objs = {((lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_instReprMyList_repr___redArg___closed__0_value)}};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_instReprMyList_repr___redArg___closed__1 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_instReprMyList_repr___redArg___closed__1_value;
static const lean_string_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_instReprMyList_repr___redArg___closed__2_value = {.m_header = {.m_rc = 0, .m_cs_sz = 0, .m_other = 0, .m_tag = 249}, .m_size = 65, .m_capacity = 65, .m_length = 64, .m_data = "Lean4Tutorial.Examples.InductiveTypes.RecursiveTypes.MyList.cons"};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_instReprMyList_repr___redArg___closed__2 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_instReprMyList_repr___redArg___closed__2_value;
static const lean_ctor_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_instReprMyList_repr___redArg___closed__3_value = {.m_header = {.m_rc = 0, .m_cs_sz = sizeof(lean_ctor_object) + sizeof(void*)*1 + 0, .m_other = 1, .m_tag = 3}, .m_objs = {((lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_instReprMyList_repr___redArg___closed__2_value)}};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_instReprMyList_repr___redArg___closed__3 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_instReprMyList_repr___redArg___closed__3_value;
static const lean_ctor_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_instReprMyList_repr___redArg___closed__4_value = {.m_header = {.m_rc = 0, .m_cs_sz = sizeof(lean_ctor_object) + sizeof(void*)*2 + 0, .m_other = 2, .m_tag = 5}, .m_objs = {((lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_instReprMyList_repr___redArg___closed__3_value),((lean_object*)(((size_t)(1) << 1) | 1))}};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_instReprMyList_repr___redArg___closed__4 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_instReprMyList_repr___redArg___closed__4_value;
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_instReprMyList_repr___redArg(lean_object*, lean_object*, lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_instReprMyList_repr___redArg___boxed(lean_object*, lean_object*, lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_instReprMyList_repr(lean_object*, lean_object*, lean_object*, lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_instReprMyList_repr___boxed(lean_object*, lean_object*, lean_object*, lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_instReprMyList___redArg(lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_instReprMyList(lean_object*, lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_empty__list;
static const lean_ctor_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_singleton___closed__0_value = {.m_header = {.m_rc = 0, .m_cs_sz = sizeof(lean_ctor_object) + sizeof(void*)*2 + 0, .m_other = 2, .m_tag = 1}, .m_objs = {((lean_object*)(((size_t)(1) << 1) | 1)),((lean_object*)(((size_t)(0) << 1) | 1))}};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_singleton___closed__0 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_singleton___closed__0_value;
LEAN_EXPORT const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_singleton = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_singleton___closed__0_value;
static const lean_ctor_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_list123___closed__0_value = {.m_header = {.m_rc = 0, .m_cs_sz = sizeof(lean_ctor_object) + sizeof(void*)*2 + 0, .m_other = 2, .m_tag = 1}, .m_objs = {((lean_object*)(((size_t)(3) << 1) | 1)),((lean_object*)(((size_t)(0) << 1) | 1))}};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_list123___closed__0 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_list123___closed__0_value;
static const lean_ctor_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_list123___closed__1_value = {.m_header = {.m_rc = 0, .m_cs_sz = sizeof(lean_ctor_object) + sizeof(void*)*2 + 0, .m_other = 2, .m_tag = 1}, .m_objs = {((lean_object*)(((size_t)(2) << 1) | 1)),((lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_list123___closed__0_value)}};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_list123___closed__1 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_list123___closed__1_value;
static const lean_ctor_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_list123___closed__2_value = {.m_header = {.m_rc = 0, .m_cs_sz = sizeof(lean_ctor_object) + sizeof(void*)*2 + 0, .m_other = 2, .m_tag = 1}, .m_objs = {((lean_object*)(((size_t)(1) << 1) | 1)),((lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_list123___closed__1_value)}};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_list123___closed__2 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_list123___closed__2_value;
LEAN_EXPORT const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_list123 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_list123___closed__2_value;
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_length___redArg(lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_length___redArg___boxed(lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_length(lean_object*, lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_length___boxed(lean_object*, lean_object*);
static lean_once_cell_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_len1___closed__0_once = LEAN_ONCE_CELL_INITIALIZER;
static lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_len1___closed__0;
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_len1;
static lean_once_cell_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_len2___closed__0_once = LEAN_ONCE_CELL_INITIALIZER;
static lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_len2___closed__0;
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_len2;
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_append___redArg(lean_object*, lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_append___redArg___boxed(lean_object*, lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_append(lean_object*, lean_object*, lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_append___boxed(lean_object*, lean_object*, lean_object*);
static lean_once_cell_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_appended___closed__0_once = LEAN_ONCE_CELL_INITIALIZER;
static lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_appended___closed__0;
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_appended;
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_map___redArg(lean_object*, lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_map(lean_object*, lean_object*, lean_object*, lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_doubled___lam__0(lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_doubled___lam__0___boxed(lean_object*);
static const lean_closure_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_doubled___closed__0_value = {.m_header = {.m_rc = 0, .m_cs_sz = sizeof(lean_closure_object) + sizeof(void*)*0, .m_other = 0, .m_tag = 245}, .m_fun = (void*)lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_doubled___lam__0___boxed, .m_arity = 1, .m_num_fixed = 0, .m_objs = {} };
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_doubled___closed__0 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_doubled___closed__0_value;
static lean_once_cell_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_doubled___closed__1_once = LEAN_ONCE_CELL_INITIALIZER;
static lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_doubled___closed__1;
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_doubled;
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_filter___redArg(lean_object*, lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_filter(lean_object*, lean_object*, lean_object*);
LEAN_EXPORT uint8_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_evens___lam__0(lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_evens___lam__0___boxed(lean_object*);
static const lean_closure_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_evens___closed__0_value = {.m_header = {.m_rc = 0, .m_cs_sz = sizeof(lean_closure_object) + sizeof(void*)*0, .m_other = 0, .m_tag = 245}, .m_fun = (void*)lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_evens___lam__0___boxed, .m_arity = 1, .m_num_fixed = 0, .m_objs = {} };
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_evens___closed__0 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_evens___closed__0_value;
static lean_once_cell_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_evens___closed__1_once = LEAN_ONCE_CELL_INITIALIZER;
static lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_evens___closed__1;
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_evens;
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_foldr___redArg(lean_object*, lean_object*, lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_foldr___redArg___boxed(lean_object*, lean_object*, lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_foldr(lean_object*, lean_object*, lean_object*, lean_object*, lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_foldr___boxed(lean_object*, lean_object*, lean_object*, lean_object*, lean_object*);
static const lean_closure_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_sum__list___closed__0_value = {.m_header = {.m_rc = 0, .m_cs_sz = sizeof(lean_closure_object) + sizeof(void*)*0, .m_other = 0, .m_tag = 245}, .m_fun = (void*)l_Nat_add___boxed, .m_arity = 2, .m_num_fixed = 0, .m_objs = {} };
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_sum__list___closed__0 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_sum__list___closed__0_value;
static lean_once_cell_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_sum__list___closed__1_once = LEAN_ONCE_CELL_INITIALIZER;
static lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_sum__list___closed__1;
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_sum__list;
static const lean_closure_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_product__list___closed__0_value = {.m_header = {.m_rc = 0, .m_cs_sz = sizeof(lean_closure_object) + sizeof(void*)*0, .m_other = 0, .m_tag = 245}, .m_fun = (void*)l_Nat_mul___boxed, .m_arity = 2, .m_num_fixed = 0, .m_objs = {} };
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_product__list___closed__0 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_product__list___closed__0_value;
static lean_once_cell_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_product__list___closed__1_once = LEAN_ONCE_CELL_INITIALIZER;
static lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_product__list___closed__1;
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_product__list;
static const lean_ctor_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_std__list___closed__0_value = {.m_header = {.m_rc = 0, .m_cs_sz = sizeof(lean_ctor_object) + sizeof(void*)*2 + 0, .m_other = 2, .m_tag = 1}, .m_objs = {((lean_object*)(((size_t)(5) << 1) | 1)),((lean_object*)(((size_t)(0) << 1) | 1))}};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_std__list___closed__0 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_std__list___closed__0_value;
static const lean_ctor_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_std__list___closed__1_value = {.m_header = {.m_rc = 0, .m_cs_sz = sizeof(lean_ctor_object) + sizeof(void*)*2 + 0, .m_other = 2, .m_tag = 1}, .m_objs = {((lean_object*)(((size_t)(4) << 1) | 1)),((lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_std__list___closed__0_value)}};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_std__list___closed__1 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_std__list___closed__1_value;
static const lean_ctor_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_std__list___closed__2_value = {.m_header = {.m_rc = 0, .m_cs_sz = sizeof(lean_ctor_object) + sizeof(void*)*2 + 0, .m_other = 2, .m_tag = 1}, .m_objs = {((lean_object*)(((size_t)(3) << 1) | 1)),((lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_std__list___closed__1_value)}};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_std__list___closed__2 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_std__list___closed__2_value;
static const lean_ctor_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_std__list___closed__3_value = {.m_header = {.m_rc = 0, .m_cs_sz = sizeof(lean_ctor_object) + sizeof(void*)*2 + 0, .m_other = 2, .m_tag = 1}, .m_objs = {((lean_object*)(((size_t)(2) << 1) | 1)),((lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_std__list___closed__2_value)}};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_std__list___closed__3 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_std__list___closed__3_value;
static const lean_ctor_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_std__list___closed__4_value = {.m_header = {.m_rc = 0, .m_cs_sz = sizeof(lean_ctor_object) + sizeof(void*)*2 + 0, .m_other = 2, .m_tag = 1}, .m_objs = {((lean_object*)(((size_t)(1) << 1) | 1)),((lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_std__list___closed__3_value)}};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_std__list___closed__4 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_std__list___closed__4_value;
LEAN_EXPORT const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_std__list = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_std__list___closed__4_value;
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_std__empty;
static lean_once_cell_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_std__length___closed__0_once = LEAN_ONCE_CELL_INITIALIZER;
static lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_std__length___closed__0;
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_std__length;
static lean_once_cell_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_std__head_x3f___closed__0_once = LEAN_ONCE_CELL_INITIALIZER;
static lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_std__head_x3f___closed__0;
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_std__head_x3f;
static lean_once_cell_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_std__tail___closed__0_once = LEAN_ONCE_CELL_INITIALIZER;
static lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_std__tail___closed__0;
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_std__tail;
static const lean_ctor_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_std__append___closed__0_value = {.m_header = {.m_rc = 0, .m_cs_sz = sizeof(lean_ctor_object) + sizeof(void*)*2 + 0, .m_other = 2, .m_tag = 1}, .m_objs = {((lean_object*)(((size_t)(2) << 1) | 1)),((lean_object*)(((size_t)(0) << 1) | 1))}};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_std__append___closed__0 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_std__append___closed__0_value;
static const lean_ctor_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_std__append___closed__1_value = {.m_header = {.m_rc = 0, .m_cs_sz = sizeof(lean_ctor_object) + sizeof(void*)*2 + 0, .m_other = 2, .m_tag = 1}, .m_objs = {((lean_object*)(((size_t)(1) << 1) | 1)),((lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_std__append___closed__0_value)}};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_std__append___closed__1 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_std__append___closed__1_value;
static const lean_ctor_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_std__append___closed__2_value = {.m_header = {.m_rc = 0, .m_cs_sz = sizeof(lean_ctor_object) + sizeof(void*)*2 + 0, .m_other = 2, .m_tag = 1}, .m_objs = {((lean_object*)(((size_t)(4) << 1) | 1)),((lean_object*)(((size_t)(0) << 1) | 1))}};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_std__append___closed__2 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_std__append___closed__2_value;
static const lean_ctor_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_std__append___closed__3_value = {.m_header = {.m_rc = 0, .m_cs_sz = sizeof(lean_ctor_object) + sizeof(void*)*2 + 0, .m_other = 2, .m_tag = 1}, .m_objs = {((lean_object*)(((size_t)(3) << 1) | 1)),((lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_std__append___closed__2_value)}};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_std__append___closed__3 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_std__append___closed__3_value;
static lean_once_cell_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_std__append___closed__4_once = LEAN_ONCE_CELL_INITIALIZER;
static lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_std__append___closed__4;
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_std__append;
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_List_mapTR_loop___at___00Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_std__map_spec__0(lean_object*, lean_object*);
static const lean_ctor_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_std__map___closed__0_value = {.m_header = {.m_rc = 0, .m_cs_sz = sizeof(lean_ctor_object) + sizeof(void*)*2 + 0, .m_other = 2, .m_tag = 1}, .m_objs = {((lean_object*)(((size_t)(3) << 1) | 1)),((lean_object*)(((size_t)(0) << 1) | 1))}};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_std__map___closed__0 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_std__map___closed__0_value;
static const lean_ctor_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_std__map___closed__1_value = {.m_header = {.m_rc = 0, .m_cs_sz = sizeof(lean_ctor_object) + sizeof(void*)*2 + 0, .m_other = 2, .m_tag = 1}, .m_objs = {((lean_object*)(((size_t)(2) << 1) | 1)),((lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_std__map___closed__0_value)}};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_std__map___closed__1 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_std__map___closed__1_value;
static const lean_ctor_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_std__map___closed__2_value = {.m_header = {.m_rc = 0, .m_cs_sz = sizeof(lean_ctor_object) + sizeof(void*)*2 + 0, .m_other = 2, .m_tag = 1}, .m_objs = {((lean_object*)(((size_t)(1) << 1) | 1)),((lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_std__map___closed__1_value)}};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_std__map___closed__2 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_std__map___closed__2_value;
static lean_once_cell_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_std__map___closed__3_once = LEAN_ONCE_CELL_INITIALIZER;
static lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_std__map___closed__3;
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_std__map;
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_List_filterTR_loop___at___00Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_std__filter_spec__0(lean_object*, lean_object*);
static const lean_ctor_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_std__filter___closed__0_value = {.m_header = {.m_rc = 0, .m_cs_sz = sizeof(lean_ctor_object) + sizeof(void*)*2 + 0, .m_other = 2, .m_tag = 1}, .m_objs = {((lean_object*)(((size_t)(2) << 1) | 1)),((lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_std__append___closed__3_value)}};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_std__filter___closed__0 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_std__filter___closed__0_value;
static const lean_ctor_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_std__filter___closed__1_value = {.m_header = {.m_rc = 0, .m_cs_sz = sizeof(lean_ctor_object) + sizeof(void*)*2 + 0, .m_other = 2, .m_tag = 1}, .m_objs = {((lean_object*)(((size_t)(1) << 1) | 1)),((lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_std__filter___closed__0_value)}};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_std__filter___closed__1 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_std__filter___closed__1_value;
static lean_once_cell_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_std__filter___closed__2_once = LEAN_ONCE_CELL_INITIALIZER;
static lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_std__filter___closed__2;
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_std__filter;
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_List_foldl___at___00Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_std__sum_spec__0(lean_object*, lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_List_foldl___at___00Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_std__sum_spec__0___boxed(lean_object*, lean_object*);
static lean_once_cell_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_std__sum___closed__0_once = LEAN_ONCE_CELL_INITIALIZER;
static lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_std__sum___closed__0;
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_std__sum;
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial___private_Init_Data_Array_Basic_0__Array_foldrMUnsafe_fold___at___00List_foldrTR___at___00Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_std__foldr_spec__0_spec__0(lean_object*, size_t, size_t, lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial___private_Init_Data_Array_Basic_0__Array_foldrMUnsafe_fold___at___00List_foldrTR___at___00Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_std__foldr_spec__0_spec__0___boxed(lean_object*, lean_object*, lean_object*, lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_List_foldrTR___at___00Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_std__foldr_spec__0(lean_object*, lean_object*);
static lean_once_cell_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_std__foldr___closed__0_once = LEAN_ONCE_CELL_INITIALIZER;
static lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_std__foldr___closed__0;
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_std__foldr;
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_BinTree_ctorIdx___redArg(lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_BinTree_ctorIdx___redArg___boxed(lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_BinTree_ctorIdx(lean_object*, lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_BinTree_ctorIdx___boxed(lean_object*, lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_BinTree_ctorElim___redArg(lean_object*, lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_BinTree_ctorElim(lean_object*, lean_object*, lean_object*, lean_object*, lean_object*, lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_BinTree_ctorElim___boxed(lean_object*, lean_object*, lean_object*, lean_object*, lean_object*, lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_BinTree_leaf_elim___redArg(lean_object*, lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_BinTree_leaf_elim(lean_object*, lean_object*, lean_object*, lean_object*, lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_BinTree_node_elim___redArg(lean_object*, lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_BinTree_node_elim(lean_object*, lean_object*, lean_object*, lean_object*, lean_object*);
static const lean_string_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_instReprBinTree_repr___redArg___closed__0_value = {.m_header = {.m_rc = 0, .m_cs_sz = 0, .m_other = 0, .m_tag = 249}, .m_size = 66, .m_capacity = 66, .m_length = 65, .m_data = "Lean4Tutorial.Examples.InductiveTypes.RecursiveTypes.BinTree.leaf"};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_instReprBinTree_repr___redArg___closed__0 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_instReprBinTree_repr___redArg___closed__0_value;
static const lean_ctor_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_instReprBinTree_repr___redArg___closed__1_value = {.m_header = {.m_rc = 0, .m_cs_sz = sizeof(lean_ctor_object) + sizeof(void*)*1 + 0, .m_other = 1, .m_tag = 3}, .m_objs = {((lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_instReprBinTree_repr___redArg___closed__0_value)}};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_instReprBinTree_repr___redArg___closed__1 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_instReprBinTree_repr___redArg___closed__1_value;
static const lean_string_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_instReprBinTree_repr___redArg___closed__2_value = {.m_header = {.m_rc = 0, .m_cs_sz = 0, .m_other = 0, .m_tag = 249}, .m_size = 66, .m_capacity = 66, .m_length = 65, .m_data = "Lean4Tutorial.Examples.InductiveTypes.RecursiveTypes.BinTree.node"};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_instReprBinTree_repr___redArg___closed__2 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_instReprBinTree_repr___redArg___closed__2_value;
static const lean_ctor_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_instReprBinTree_repr___redArg___closed__3_value = {.m_header = {.m_rc = 0, .m_cs_sz = sizeof(lean_ctor_object) + sizeof(void*)*1 + 0, .m_other = 1, .m_tag = 3}, .m_objs = {((lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_instReprBinTree_repr___redArg___closed__2_value)}};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_instReprBinTree_repr___redArg___closed__3 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_instReprBinTree_repr___redArg___closed__3_value;
static const lean_ctor_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_instReprBinTree_repr___redArg___closed__4_value = {.m_header = {.m_rc = 0, .m_cs_sz = sizeof(lean_ctor_object) + sizeof(void*)*2 + 0, .m_other = 2, .m_tag = 5}, .m_objs = {((lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_instReprBinTree_repr___redArg___closed__3_value),((lean_object*)(((size_t)(1) << 1) | 1))}};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_instReprBinTree_repr___redArg___closed__4 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_instReprBinTree_repr___redArg___closed__4_value;
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_instReprBinTree_repr___redArg(lean_object*, lean_object*, lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_instReprBinTree_repr___redArg___boxed(lean_object*, lean_object*, lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_instReprBinTree_repr(lean_object*, lean_object*, lean_object*, lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_instReprBinTree_repr___boxed(lean_object*, lean_object*, lean_object*, lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_instReprBinTree___redArg(lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_instReprBinTree(lean_object*, lean_object*);
static const lean_ctor_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_example__tree___closed__0_value = {.m_header = {.m_rc = 0, .m_cs_sz = sizeof(lean_ctor_object) + sizeof(void*)*3 + 0, .m_other = 3, .m_tag = 1}, .m_objs = {((lean_object*)(((size_t)(2) << 1) | 1)),((lean_object*)(((size_t)(0) << 1) | 1)),((lean_object*)(((size_t)(0) << 1) | 1))}};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_example__tree___closed__0 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_example__tree___closed__0_value;
static const lean_ctor_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_example__tree___closed__1_value = {.m_header = {.m_rc = 0, .m_cs_sz = sizeof(lean_ctor_object) + sizeof(void*)*3 + 0, .m_other = 3, .m_tag = 1}, .m_objs = {((lean_object*)(((size_t)(1) << 1) | 1)),((lean_object*)(((size_t)(0) << 1) | 1)),((lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_example__tree___closed__0_value)}};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_example__tree___closed__1 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_example__tree___closed__1_value;
static const lean_ctor_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_example__tree___closed__2_value = {.m_header = {.m_rc = 0, .m_cs_sz = sizeof(lean_ctor_object) + sizeof(void*)*3 + 0, .m_other = 3, .m_tag = 1}, .m_objs = {((lean_object*)(((size_t)(5) << 1) | 1)),((lean_object*)(((size_t)(0) << 1) | 1)),((lean_object*)(((size_t)(0) << 1) | 1))}};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_example__tree___closed__2 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_example__tree___closed__2_value;
static const lean_ctor_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_example__tree___closed__3_value = {.m_header = {.m_rc = 0, .m_cs_sz = sizeof(lean_ctor_object) + sizeof(void*)*3 + 0, .m_other = 3, .m_tag = 1}, .m_objs = {((lean_object*)(((size_t)(3) << 1) | 1)),((lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_example__tree___closed__1_value),((lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_example__tree___closed__2_value)}};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_example__tree___closed__3 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_example__tree___closed__3_value;
LEAN_EXPORT const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_example__tree = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_example__tree___closed__3_value;
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_size___redArg(lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_size___redArg___boxed(lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_size(lean_object*, lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_size___boxed(lean_object*, lean_object*);
static lean_once_cell_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_tree__size___closed__0_once = LEAN_ONCE_CELL_INITIALIZER;
static lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_tree__size___closed__0;
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_tree__size;
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_height___redArg(lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_height___redArg___boxed(lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_height(lean_object*, lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_height___boxed(lean_object*, lean_object*);
static lean_once_cell_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_tree__height___closed__0_once = LEAN_ONCE_CELL_INITIALIZER;
static lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_tree__height___closed__0;
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_tree__height;
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_treeMap___redArg(lean_object*, lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_treeMap(lean_object*, lean_object*, lean_object*, lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_tree__doubled___lam__0(lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_tree__doubled___lam__0___boxed(lean_object*);
static const lean_closure_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_tree__doubled___closed__0_value = {.m_header = {.m_rc = 0, .m_cs_sz = sizeof(lean_closure_object) + sizeof(void*)*0, .m_other = 0, .m_tag = 245}, .m_fun = (void*)lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_tree__doubled___lam__0___boxed, .m_arity = 1, .m_num_fixed = 0, .m_objs = {} };
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_tree__doubled___closed__0 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_tree__doubled___closed__0_value;
static lean_once_cell_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_tree__doubled___closed__1_once = LEAN_ONCE_CELL_INITIALIZER;
static lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_tree__doubled___closed__1;
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_tree__doubled;
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_inorder___redArg(lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_inorder___redArg___boxed(lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_inorder(lean_object*, lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_inorder___boxed(lean_object*, lean_object*);
static lean_once_cell_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_inorder__example___closed__0_once = LEAN_ONCE_CELL_INITIALIZER;
static lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_inorder__example___closed__0;
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_inorder__example;
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_AExpr_ctorIdx(lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_AExpr_ctorIdx___boxed(lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_AExpr_ctorElim___redArg(lean_object*, lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_AExpr_ctorElim(lean_object*, lean_object*, lean_object*, lean_object*, lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_AExpr_ctorElim___boxed(lean_object*, lean_object*, lean_object*, lean_object*, lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_AExpr_num_elim___redArg(lean_object*, lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_AExpr_num_elim(lean_object*, lean_object*, lean_object*, lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_AExpr_add_elim___redArg(lean_object*, lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_AExpr_add_elim(lean_object*, lean_object*, lean_object*, lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_AExpr_mul_elim___redArg(lean_object*, lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_AExpr_mul_elim(lean_object*, lean_object*, lean_object*, lean_object*);
static const lean_string_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_instReprAExpr_repr___closed__0_value = {.m_header = {.m_rc = 0, .m_cs_sz = 0, .m_other = 0, .m_tag = 249}, .m_size = 63, .m_capacity = 63, .m_length = 62, .m_data = "Lean4Tutorial.Examples.InductiveTypes.RecursiveTypes.AExpr.num"};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_instReprAExpr_repr___closed__0 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_instReprAExpr_repr___closed__0_value;
static const lean_ctor_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_instReprAExpr_repr___closed__1_value = {.m_header = {.m_rc = 0, .m_cs_sz = sizeof(lean_ctor_object) + sizeof(void*)*1 + 0, .m_other = 1, .m_tag = 3}, .m_objs = {((lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_instReprAExpr_repr___closed__0_value)}};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_instReprAExpr_repr___closed__1 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_instReprAExpr_repr___closed__1_value;
static const lean_ctor_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_instReprAExpr_repr___closed__2_value = {.m_header = {.m_rc = 0, .m_cs_sz = sizeof(lean_ctor_object) + sizeof(void*)*2 + 0, .m_other = 2, .m_tag = 5}, .m_objs = {((lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_instReprAExpr_repr___closed__1_value),((lean_object*)(((size_t)(1) << 1) | 1))}};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_instReprAExpr_repr___closed__2 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_instReprAExpr_repr___closed__2_value;
static const lean_string_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_instReprAExpr_repr___closed__3_value = {.m_header = {.m_rc = 0, .m_cs_sz = 0, .m_other = 0, .m_tag = 249}, .m_size = 63, .m_capacity = 63, .m_length = 62, .m_data = "Lean4Tutorial.Examples.InductiveTypes.RecursiveTypes.AExpr.add"};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_instReprAExpr_repr___closed__3 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_instReprAExpr_repr___closed__3_value;
static const lean_ctor_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_instReprAExpr_repr___closed__4_value = {.m_header = {.m_rc = 0, .m_cs_sz = sizeof(lean_ctor_object) + sizeof(void*)*1 + 0, .m_other = 1, .m_tag = 3}, .m_objs = {((lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_instReprAExpr_repr___closed__3_value)}};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_instReprAExpr_repr___closed__4 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_instReprAExpr_repr___closed__4_value;
static const lean_ctor_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_instReprAExpr_repr___closed__5_value = {.m_header = {.m_rc = 0, .m_cs_sz = sizeof(lean_ctor_object) + sizeof(void*)*2 + 0, .m_other = 2, .m_tag = 5}, .m_objs = {((lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_instReprAExpr_repr___closed__4_value),((lean_object*)(((size_t)(1) << 1) | 1))}};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_instReprAExpr_repr___closed__5 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_instReprAExpr_repr___closed__5_value;
static const lean_string_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_instReprAExpr_repr___closed__6_value = {.m_header = {.m_rc = 0, .m_cs_sz = 0, .m_other = 0, .m_tag = 249}, .m_size = 63, .m_capacity = 63, .m_length = 62, .m_data = "Lean4Tutorial.Examples.InductiveTypes.RecursiveTypes.AExpr.mul"};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_instReprAExpr_repr___closed__6 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_instReprAExpr_repr___closed__6_value;
static const lean_ctor_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_instReprAExpr_repr___closed__7_value = {.m_header = {.m_rc = 0, .m_cs_sz = sizeof(lean_ctor_object) + sizeof(void*)*1 + 0, .m_other = 1, .m_tag = 3}, .m_objs = {((lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_instReprAExpr_repr___closed__6_value)}};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_instReprAExpr_repr___closed__7 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_instReprAExpr_repr___closed__7_value;
static const lean_ctor_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_instReprAExpr_repr___closed__8_value = {.m_header = {.m_rc = 0, .m_cs_sz = sizeof(lean_ctor_object) + sizeof(void*)*2 + 0, .m_other = 2, .m_tag = 5}, .m_objs = {((lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_instReprAExpr_repr___closed__7_value),((lean_object*)(((size_t)(1) << 1) | 1))}};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_instReprAExpr_repr___closed__8 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_instReprAExpr_repr___closed__8_value;
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_instReprAExpr_repr(lean_object*, lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_instReprAExpr_repr___boxed(lean_object*, lean_object*);
static const lean_closure_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_instReprAExpr___closed__0_value = {.m_header = {.m_rc = 0, .m_cs_sz = sizeof(lean_closure_object) + sizeof(void*)*0, .m_other = 0, .m_tag = 245}, .m_fun = (void*)lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_instReprAExpr_repr___boxed, .m_arity = 2, .m_num_fixed = 0, .m_objs = {} };
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_instReprAExpr___closed__0 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_instReprAExpr___closed__0_value;
LEAN_EXPORT const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_instReprAExpr = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_instReprAExpr___closed__0_value;
static const lean_ctor_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_expr1___closed__0_value = {.m_header = {.m_rc = 0, .m_cs_sz = sizeof(lean_ctor_object) + sizeof(void*)*1 + 0, .m_other = 1, .m_tag = 0}, .m_objs = {((lean_object*)(((size_t)(3) << 1) | 1))}};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_expr1___closed__0 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_expr1___closed__0_value;
static const lean_ctor_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_expr1___closed__1_value = {.m_header = {.m_rc = 0, .m_cs_sz = sizeof(lean_ctor_object) + sizeof(void*)*1 + 0, .m_other = 1, .m_tag = 0}, .m_objs = {((lean_object*)(((size_t)(4) << 1) | 1))}};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_expr1___closed__1 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_expr1___closed__1_value;
static const lean_ctor_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_expr1___closed__2_value = {.m_header = {.m_rc = 0, .m_cs_sz = sizeof(lean_ctor_object) + sizeof(void*)*2 + 0, .m_other = 2, .m_tag = 1}, .m_objs = {((lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_expr1___closed__0_value),((lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_expr1___closed__1_value)}};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_expr1___closed__2 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_expr1___closed__2_value;
static const lean_ctor_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_expr1___closed__3_value = {.m_header = {.m_rc = 0, .m_cs_sz = sizeof(lean_ctor_object) + sizeof(void*)*1 + 0, .m_other = 1, .m_tag = 0}, .m_objs = {((lean_object*)(((size_t)(5) << 1) | 1))}};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_expr1___closed__3 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_expr1___closed__3_value;
static const lean_ctor_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_expr1___closed__4_value = {.m_header = {.m_rc = 0, .m_cs_sz = sizeof(lean_ctor_object) + sizeof(void*)*2 + 0, .m_other = 2, .m_tag = 2}, .m_objs = {((lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_expr1___closed__2_value),((lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_expr1___closed__3_value)}};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_expr1___closed__4 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_expr1___closed__4_value;
LEAN_EXPORT const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_expr1 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_expr1___closed__4_value;
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_eval(lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_eval___boxed(lean_object*);
static lean_once_cell_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_eval1___closed__0_once = LEAN_ONCE_CELL_INITIALIZER;
static lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_eval1___closed__0;
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_eval1;
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_exprSize(lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_exprSize___boxed(lean_object*);
static lean_once_cell_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_size1___closed__0_once = LEAN_ONCE_CELL_INITIALIZER;
static lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_size1___closed__0;
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_size1;
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_MyNat_ctorIdx(lean_object* v_x_1_){
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
lean_object* v___x_3_; 
v___x_3_ = lean_unsigned_to_nat(1u);
return v___x_3_;
}
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_MyNat_ctorIdx___boxed(lean_object* v_x_4_){
_start:
{
lean_object* v_res_5_; 
v_res_5_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_MyNat_ctorIdx(v_x_4_);
lean_dec(v_x_4_);
return v_res_5_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_MyNat_ctorElim___redArg(lean_object* v_t_6_, lean_object* v_k_7_){
_start:
{
if (lean_obj_tag(v_t_6_) == 0)
{
return v_k_7_;
}
else
{
lean_object* v_n_8_; lean_object* v___x_9_; 
v_n_8_ = lean_ctor_get(v_t_6_, 0);
lean_inc(v_n_8_);
lean_dec_ref_known(v_t_6_, 1);
v___x_9_ = lean_apply_1(v_k_7_, v_n_8_);
return v___x_9_;
}
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_MyNat_ctorElim(lean_object* v_motive_10_, lean_object* v_ctorIdx_11_, lean_object* v_t_12_, lean_object* v_h_13_, lean_object* v_k_14_){
_start:
{
lean_object* v___x_15_; 
v___x_15_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_MyNat_ctorElim___redArg(v_t_12_, v_k_14_);
return v___x_15_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_MyNat_ctorElim___boxed(lean_object* v_motive_16_, lean_object* v_ctorIdx_17_, lean_object* v_t_18_, lean_object* v_h_19_, lean_object* v_k_20_){
_start:
{
lean_object* v_res_21_; 
v_res_21_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_MyNat_ctorElim(v_motive_16_, v_ctorIdx_17_, v_t_18_, v_h_19_, v_k_20_);
lean_dec(v_ctorIdx_17_);
return v_res_21_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_MyNat_zero_elim___redArg(lean_object* v_t_22_, lean_object* v_zero_23_){
_start:
{
lean_object* v___x_24_; 
v___x_24_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_MyNat_ctorElim___redArg(v_t_22_, v_zero_23_);
return v___x_24_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_MyNat_zero_elim(lean_object* v_motive_25_, lean_object* v_t_26_, lean_object* v_h_27_, lean_object* v_zero_28_){
_start:
{
lean_object* v___x_29_; 
v___x_29_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_MyNat_ctorElim___redArg(v_t_26_, v_zero_28_);
return v___x_29_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_MyNat_succ_elim___redArg(lean_object* v_t_30_, lean_object* v_succ_31_){
_start:
{
lean_object* v___x_32_; 
v___x_32_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_MyNat_ctorElim___redArg(v_t_30_, v_succ_31_);
return v___x_32_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_MyNat_succ_elim(lean_object* v_motive_33_, lean_object* v_t_34_, lean_object* v_h_35_, lean_object* v_succ_36_){
_start:
{
lean_object* v___x_37_; 
v___x_37_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_MyNat_ctorElim___redArg(v_t_34_, v_succ_36_);
return v___x_37_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_instReprMyNat_repr___closed__2(void){
_start:
{
lean_object* v___x_41_; lean_object* v___x_42_; 
v___x_41_ = lean_unsigned_to_nat(2u);
v___x_42_ = lean_nat_to_int(v___x_41_);
return v___x_42_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_instReprMyNat_repr___closed__3(void){
_start:
{
lean_object* v___x_43_; lean_object* v___x_44_; 
v___x_43_ = lean_unsigned_to_nat(1u);
v___x_44_ = lean_nat_to_int(v___x_43_);
return v___x_44_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_instReprMyNat_repr(lean_object* v_x_51_, lean_object* v_prec_52_){
_start:
{
lean_object* v___y_54_; 
if (lean_obj_tag(v_x_51_) == 0)
{
lean_object* v___x_60_; uint8_t v___x_61_; 
v___x_60_ = lean_unsigned_to_nat(1024u);
v___x_61_ = lean_nat_dec_le(v___x_60_, v_prec_52_);
if (v___x_61_ == 0)
{
lean_object* v___x_62_; 
v___x_62_ = lean_obj_once(&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_instReprMyNat_repr___closed__2, &lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_instReprMyNat_repr___closed__2_once, _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_instReprMyNat_repr___closed__2);
v___y_54_ = v___x_62_;
goto v___jp_53_;
}
else
{
lean_object* v___x_63_; 
v___x_63_ = lean_obj_once(&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_instReprMyNat_repr___closed__3, &lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_instReprMyNat_repr___closed__3_once, _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_instReprMyNat_repr___closed__3);
v___y_54_ = v___x_63_;
goto v___jp_53_;
}
}
else
{
lean_object* v_n_64_; lean_object* v___x_65_; lean_object* v___y_67_; uint8_t v___x_75_; 
v_n_64_ = lean_ctor_get(v_x_51_, 0);
v___x_65_ = lean_unsigned_to_nat(1024u);
v___x_75_ = lean_nat_dec_le(v___x_65_, v_prec_52_);
if (v___x_75_ == 0)
{
lean_object* v___x_76_; 
v___x_76_ = lean_obj_once(&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_instReprMyNat_repr___closed__2, &lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_instReprMyNat_repr___closed__2_once, _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_instReprMyNat_repr___closed__2);
v___y_67_ = v___x_76_;
goto v___jp_66_;
}
else
{
lean_object* v___x_77_; 
v___x_77_ = lean_obj_once(&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_instReprMyNat_repr___closed__3, &lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_instReprMyNat_repr___closed__3_once, _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_instReprMyNat_repr___closed__3);
v___y_67_ = v___x_77_;
goto v___jp_66_;
}
v___jp_66_:
{
lean_object* v___x_68_; lean_object* v___x_69_; lean_object* v___x_70_; lean_object* v___x_71_; uint8_t v___x_72_; lean_object* v___x_73_; lean_object* v___x_74_; 
v___x_68_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_instReprMyNat_repr___closed__6));
v___x_69_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_instReprMyNat_repr(v_n_64_, v___x_65_);
v___x_70_ = lean_alloc_ctor(5, 2, 0);
lean_ctor_set(v___x_70_, 0, v___x_68_);
lean_ctor_set(v___x_70_, 1, v___x_69_);
lean_inc(v___y_67_);
v___x_71_ = lean_alloc_ctor(4, 2, 0);
lean_ctor_set(v___x_71_, 0, v___y_67_);
lean_ctor_set(v___x_71_, 1, v___x_70_);
v___x_72_ = 0;
v___x_73_ = lean_alloc_ctor(6, 1, 1);
lean_ctor_set(v___x_73_, 0, v___x_71_);
lean_ctor_set_uint8(v___x_73_, sizeof(void*)*1, v___x_72_);
v___x_74_ = l_Repr_addAppParen(v___x_73_, v_prec_52_);
return v___x_74_;
}
}
v___jp_53_:
{
lean_object* v___x_55_; lean_object* v___x_56_; uint8_t v___x_57_; lean_object* v___x_58_; lean_object* v___x_59_; 
v___x_55_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_instReprMyNat_repr___closed__1));
lean_inc(v___y_54_);
v___x_56_ = lean_alloc_ctor(4, 2, 0);
lean_ctor_set(v___x_56_, 0, v___y_54_);
lean_ctor_set(v___x_56_, 1, v___x_55_);
v___x_57_ = 0;
v___x_58_ = lean_alloc_ctor(6, 1, 1);
lean_ctor_set(v___x_58_, 0, v___x_56_);
lean_ctor_set_uint8(v___x_58_, sizeof(void*)*1, v___x_57_);
v___x_59_ = l_Repr_addAppParen(v___x_58_, v_prec_52_);
return v___x_59_;
}
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_instReprMyNat_repr___boxed(lean_object* v_x_78_, lean_object* v_prec_79_){
_start:
{
lean_object* v_res_80_; 
v_res_80_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_instReprMyNat_repr(v_x_78_, v_prec_79_);
lean_dec(v_prec_79_);
lean_dec(v_x_78_);
return v_res_80_;
}
}
LEAN_EXPORT uint8_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_instDecidableEqMyNat_decEq(lean_object* v_x_83_, lean_object* v_x_84_){
_start:
{
if (lean_obj_tag(v_x_83_) == 0)
{
if (lean_obj_tag(v_x_84_) == 0)
{
uint8_t v___x_85_; 
v___x_85_ = 1;
return v___x_85_;
}
else
{
uint8_t v___x_86_; 
v___x_86_ = 0;
return v___x_86_;
}
}
else
{
lean_object* v_n_87_; uint8_t v___x_88_; 
v_n_87_ = lean_ctor_get(v_x_83_, 0);
v___x_88_ = 0;
if (lean_obj_tag(v_x_84_) == 0)
{
return v___x_88_;
}
else
{
lean_object* v_n_89_; uint8_t v_inst_90_; 
v_n_89_ = lean_ctor_get(v_x_84_, 0);
v_inst_90_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_instDecidableEqMyNat_decEq(v_n_87_, v_n_89_);
if (v_inst_90_ == 0)
{
return v___x_88_;
}
else
{
return v_inst_90_;
}
}
}
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_instDecidableEqMyNat_decEq___boxed(lean_object* v_x_91_, lean_object* v_x_92_){
_start:
{
uint8_t v_res_93_; lean_object* v_r_94_; 
v_res_93_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_instDecidableEqMyNat_decEq(v_x_91_, v_x_92_);
lean_dec(v_x_92_);
lean_dec(v_x_91_);
v_r_94_ = lean_box(v_res_93_);
return v_r_94_;
}
}
LEAN_EXPORT uint8_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_instDecidableEqMyNat(lean_object* v_x_95_, lean_object* v_x_96_){
_start:
{
uint8_t v___x_97_; 
v___x_97_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_instDecidableEqMyNat_decEq(v_x_95_, v_x_96_);
return v___x_97_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_instDecidableEqMyNat___boxed(lean_object* v_x_98_, lean_object* v_x_99_){
_start:
{
uint8_t v_res_100_; lean_object* v_r_101_; 
v_res_100_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_instDecidableEqMyNat(v_x_98_, v_x_99_);
lean_dec(v_x_99_);
lean_dec(v_x_98_);
v_r_101_ = lean_box(v_res_100_);
return v_r_101_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_my__zero(void){
_start:
{
lean_object* v___x_102_; 
v___x_102_ = lean_box(0);
return v___x_102_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_add(lean_object* v_m_112_, lean_object* v_n_113_){
_start:
{
if (lean_obj_tag(v_n_113_) == 0)
{
lean_inc(v_m_112_);
return v_m_112_;
}
else
{
lean_object* v_n_114_; lean_object* v___x_116_; uint8_t v_isShared_117_; uint8_t v_isSharedCheck_122_; 
v_n_114_ = lean_ctor_get(v_n_113_, 0);
v_isSharedCheck_122_ = !lean_is_exclusive(v_n_113_);
if (v_isSharedCheck_122_ == 0)
{
v___x_116_ = v_n_113_;
v_isShared_117_ = v_isSharedCheck_122_;
goto v_resetjp_115_;
}
else
{
lean_inc(v_n_114_);
lean_dec(v_n_113_);
v___x_116_ = lean_box(0);
v_isShared_117_ = v_isSharedCheck_122_;
goto v_resetjp_115_;
}
v_resetjp_115_:
{
lean_object* v___x_118_; lean_object* v___x_120_; 
v___x_118_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_add(v_m_112_, v_n_114_);
if (v_isShared_117_ == 0)
{
lean_ctor_set(v___x_116_, 0, v___x_118_);
v___x_120_ = v___x_116_;
goto v_reusejp_119_;
}
else
{
lean_object* v_reuseFailAlloc_121_; 
v_reuseFailAlloc_121_ = lean_alloc_ctor(1, 1, 0);
lean_ctor_set(v_reuseFailAlloc_121_, 0, v___x_118_);
v___x_120_ = v_reuseFailAlloc_121_;
goto v_reusejp_119_;
}
v_reusejp_119_:
{
return v___x_120_;
}
}
}
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_add___boxed(lean_object* v_m_123_, lean_object* v_n_124_){
_start:
{
lean_object* v_res_125_; 
v_res_125_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_add(v_m_123_, v_n_124_);
lean_dec(v_m_123_);
return v_res_125_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_mul(lean_object* v_m_126_, lean_object* v_n_127_){
_start:
{
if (lean_obj_tag(v_n_127_) == 0)
{
return v_n_127_;
}
else
{
lean_object* v_n_128_; lean_object* v___x_129_; lean_object* v___x_130_; 
v_n_128_ = lean_ctor_get(v_n_127_, 0);
v___x_129_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_mul(v_m_126_, v_n_128_);
v___x_130_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_add(v_m_126_, v___x_129_);
return v___x_130_;
}
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_mul___boxed(lean_object* v_m_131_, lean_object* v_n_132_){
_start:
{
lean_object* v_res_133_; 
v_res_133_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_mul(v_m_131_, v_n_132_);
lean_dec(v_n_132_);
lean_dec(v_m_131_);
return v_res_133_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_two__plus__three___closed__0(void){
_start:
{
lean_object* v___x_134_; lean_object* v___x_135_; lean_object* v___x_136_; 
v___x_134_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_my__three));
v___x_135_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_my__two));
v___x_136_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_add(v___x_135_, v___x_134_);
return v___x_136_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_two__plus__three(void){
_start:
{
lean_object* v___x_137_; 
v___x_137_ = lean_obj_once(&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_two__plus__three___closed__0, &lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_two__plus__three___closed__0_once, _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_two__plus__three___closed__0);
return v___x_137_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_two__times__three___closed__0(void){
_start:
{
lean_object* v___x_138_; lean_object* v___x_139_; lean_object* v___x_140_; 
v___x_138_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_my__three));
v___x_139_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_my__two));
v___x_140_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_mul(v___x_139_, v___x_138_);
return v___x_140_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_two__times__three(void){
_start:
{
lean_object* v___x_141_; 
v___x_141_ = lean_obj_once(&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_two__times__three___closed__0, &lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_two__times__three___closed__0_once, _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_two__times__three___closed__0);
return v___x_141_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_MyNat_toNat(lean_object* v_n_142_){
_start:
{
if (lean_obj_tag(v_n_142_) == 0)
{
lean_object* v___x_143_; 
v___x_143_ = lean_unsigned_to_nat(0u);
return v___x_143_;
}
else
{
lean_object* v_n_144_; lean_object* v___x_145_; lean_object* v___x_146_; lean_object* v___x_147_; 
v_n_144_ = lean_ctor_get(v_n_142_, 0);
v___x_145_ = lean_unsigned_to_nat(1u);
v___x_146_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_MyNat_toNat(v_n_144_);
v___x_147_ = lean_nat_add(v___x_145_, v___x_146_);
lean_dec(v___x_146_);
return v___x_147_;
}
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_MyNat_toNat___boxed(lean_object* v_n_148_){
_start:
{
lean_object* v_res_149_; 
v_res_149_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_MyNat_toNat(v_n_148_);
lean_dec(v_n_148_);
return v_res_149_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_three__to__nat___closed__0(void){
_start:
{
lean_object* v___x_150_; lean_object* v___x_151_; 
v___x_150_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_my__three));
v___x_151_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_MyNat_toNat(v___x_150_);
return v___x_151_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_three__to__nat(void){
_start:
{
lean_object* v___x_152_; 
v___x_152_ = lean_obj_once(&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_three__to__nat___closed__0, &lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_three__to__nat___closed__0_once, _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_three__to__nat___closed__0);
return v___x_152_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_MyNat_ofNat(lean_object* v_n_153_){
_start:
{
lean_object* v_zero_154_; uint8_t v_isZero_155_; 
v_zero_154_ = lean_unsigned_to_nat(0u);
v_isZero_155_ = lean_nat_dec_eq(v_n_153_, v_zero_154_);
if (v_isZero_155_ == 1)
{
lean_object* v___x_156_; 
v___x_156_ = lean_box(0);
return v___x_156_;
}
else
{
lean_object* v_one_157_; lean_object* v_n_158_; lean_object* v___x_159_; lean_object* v___x_160_; 
v_one_157_ = lean_unsigned_to_nat(1u);
v_n_158_ = lean_nat_sub(v_n_153_, v_one_157_);
v___x_159_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_MyNat_ofNat(v_n_158_);
lean_dec(v_n_158_);
v___x_160_ = lean_alloc_ctor(1, 1, 0);
lean_ctor_set(v___x_160_, 0, v___x_159_);
return v___x_160_;
}
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_MyNat_ofNat___boxed(lean_object* v_n_161_){
_start:
{
lean_object* v_res_162_; 
v_res_162_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_MyNat_ofNat(v_n_161_);
lean_dec(v_n_161_);
return v_res_162_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_five__of__nat___closed__0(void){
_start:
{
lean_object* v___x_163_; lean_object* v___x_164_; 
v___x_163_ = lean_unsigned_to_nat(5u);
v___x_164_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_MyNat_ofNat(v___x_163_);
return v___x_164_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_five__of__nat(void){
_start:
{
lean_object* v___x_165_; 
v___x_165_ = lean_obj_once(&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_five__of__nat___closed__0, &lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_five__of__nat___closed__0_once, _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_five__of__nat___closed__0);
return v___x_165_;
}
}
LEAN_EXPORT uint8_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_leq(lean_object* v_m_166_, lean_object* v_n_167_){
_start:
{
if (lean_obj_tag(v_m_166_) == 0)
{
uint8_t v___x_168_; 
v___x_168_ = 1;
return v___x_168_;
}
else
{
if (lean_obj_tag(v_n_167_) == 0)
{
uint8_t v___x_169_; 
v___x_169_ = 0;
return v___x_169_;
}
else
{
lean_object* v_n_170_; lean_object* v_n_171_; 
v_n_170_ = lean_ctor_get(v_m_166_, 0);
v_n_171_ = lean_ctor_get(v_n_167_, 0);
v_m_166_ = v_n_170_;
v_n_167_ = v_n_171_;
goto _start;
}
}
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_leq___boxed(lean_object* v_m_173_, lean_object* v_n_174_){
_start:
{
uint8_t v_res_175_; lean_object* v_r_176_; 
v_res_175_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_leq(v_m_173_, v_n_174_);
lean_dec(v_n_174_);
lean_dec(v_m_173_);
v_r_176_ = lean_box(v_res_175_);
return v_r_176_;
}
}
static uint8_t _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_leq__example1___closed__0(void){
_start:
{
lean_object* v___x_177_; lean_object* v___x_178_; uint8_t v___x_179_; 
v___x_177_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_my__three));
v___x_178_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_my__one));
v___x_179_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_leq(v___x_178_, v___x_177_);
return v___x_179_;
}
}
static uint8_t _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_leq__example1(void){
_start:
{
uint8_t v___x_180_; 
v___x_180_ = lean_uint8_once(&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_leq__example1___closed__0, &lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_leq__example1___closed__0_once, _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_leq__example1___closed__0);
return v___x_180_;
}
}
static uint8_t _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_leq__example2___closed__0(void){
_start:
{
lean_object* v___x_181_; lean_object* v___x_182_; uint8_t v___x_183_; 
v___x_181_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_my__one));
v___x_182_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_my__three));
v___x_183_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_leq(v___x_182_, v___x_181_);
return v___x_183_;
}
}
static uint8_t _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_leq__example2(void){
_start:
{
uint8_t v___x_184_; 
v___x_184_ = lean_uint8_once(&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_leq__example2___closed__0, &lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_leq__example2___closed__0_once, _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_leq__example2___closed__0);
return v___x_184_;
}
}
static uint8_t _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_eq__example___closed__0(void){
_start:
{
lean_object* v___x_185_; uint8_t v___x_186_; 
v___x_185_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_my__two));
v___x_186_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_instDecidableEqMyNat_decEq(v___x_185_, v___x_185_);
return v___x_186_;
}
}
static uint8_t _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_eq__example(void){
_start:
{
uint8_t v___x_187_; 
v___x_187_ = lean_uint8_once(&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_eq__example___closed__0, &lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_eq__example___closed__0_once, _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_eq__example___closed__0);
return v___x_187_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_MyList_ctorIdx___redArg(lean_object* v_x_188_){
_start:
{
if (lean_obj_tag(v_x_188_) == 0)
{
lean_object* v___x_189_; 
v___x_189_ = lean_unsigned_to_nat(0u);
return v___x_189_;
}
else
{
lean_object* v___x_190_; 
v___x_190_ = lean_unsigned_to_nat(1u);
return v___x_190_;
}
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_MyList_ctorIdx___redArg___boxed(lean_object* v_x_191_){
_start:
{
lean_object* v_res_192_; 
v_res_192_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_MyList_ctorIdx___redArg(v_x_191_);
lean_dec(v_x_191_);
return v_res_192_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_MyList_ctorIdx(lean_object* v_00_u03b1_193_, lean_object* v_x_194_){
_start:
{
lean_object* v___x_195_; 
v___x_195_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_MyList_ctorIdx___redArg(v_x_194_);
return v___x_195_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_MyList_ctorIdx___boxed(lean_object* v_00_u03b1_196_, lean_object* v_x_197_){
_start:
{
lean_object* v_res_198_; 
v_res_198_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_MyList_ctorIdx(v_00_u03b1_196_, v_x_197_);
lean_dec(v_x_197_);
return v_res_198_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_MyList_ctorElim___redArg(lean_object* v_t_199_, lean_object* v_k_200_){
_start:
{
if (lean_obj_tag(v_t_199_) == 0)
{
return v_k_200_;
}
else
{
lean_object* v_head_201_; lean_object* v_tail_202_; lean_object* v___x_203_; 
v_head_201_ = lean_ctor_get(v_t_199_, 0);
lean_inc(v_head_201_);
v_tail_202_ = lean_ctor_get(v_t_199_, 1);
lean_inc(v_tail_202_);
lean_dec_ref_known(v_t_199_, 2);
v___x_203_ = lean_apply_2(v_k_200_, v_head_201_, v_tail_202_);
return v___x_203_;
}
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_MyList_ctorElim(lean_object* v_00_u03b1_204_, lean_object* v_motive_205_, lean_object* v_ctorIdx_206_, lean_object* v_t_207_, lean_object* v_h_208_, lean_object* v_k_209_){
_start:
{
lean_object* v___x_210_; 
v___x_210_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_MyList_ctorElim___redArg(v_t_207_, v_k_209_);
return v___x_210_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_MyList_ctorElim___boxed(lean_object* v_00_u03b1_211_, lean_object* v_motive_212_, lean_object* v_ctorIdx_213_, lean_object* v_t_214_, lean_object* v_h_215_, lean_object* v_k_216_){
_start:
{
lean_object* v_res_217_; 
v_res_217_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_MyList_ctorElim(v_00_u03b1_211_, v_motive_212_, v_ctorIdx_213_, v_t_214_, v_h_215_, v_k_216_);
lean_dec(v_ctorIdx_213_);
return v_res_217_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_MyList_nil_elim___redArg(lean_object* v_t_218_, lean_object* v_nil_219_){
_start:
{
lean_object* v___x_220_; 
v___x_220_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_MyList_ctorElim___redArg(v_t_218_, v_nil_219_);
return v___x_220_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_MyList_nil_elim(lean_object* v_00_u03b1_221_, lean_object* v_motive_222_, lean_object* v_t_223_, lean_object* v_h_224_, lean_object* v_nil_225_){
_start:
{
lean_object* v___x_226_; 
v___x_226_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_MyList_ctorElim___redArg(v_t_223_, v_nil_225_);
return v___x_226_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_MyList_cons_elim___redArg(lean_object* v_t_227_, lean_object* v_cons_228_){
_start:
{
lean_object* v___x_229_; 
v___x_229_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_MyList_ctorElim___redArg(v_t_227_, v_cons_228_);
return v___x_229_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_MyList_cons_elim(lean_object* v_00_u03b1_230_, lean_object* v_motive_231_, lean_object* v_t_232_, lean_object* v_h_233_, lean_object* v_cons_234_){
_start:
{
lean_object* v___x_235_; 
v___x_235_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_MyList_ctorElim___redArg(v_t_232_, v_cons_234_);
return v___x_235_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_instReprMyList_repr___redArg(lean_object* v_inst_245_, lean_object* v_x_246_, lean_object* v_prec_247_){
_start:
{
lean_object* v___y_249_; 
if (lean_obj_tag(v_x_246_) == 0)
{
lean_object* v___x_255_; uint8_t v___x_256_; 
lean_dec_ref(v_inst_245_);
v___x_255_ = lean_unsigned_to_nat(1024u);
v___x_256_ = lean_nat_dec_le(v___x_255_, v_prec_247_);
if (v___x_256_ == 0)
{
lean_object* v___x_257_; 
v___x_257_ = lean_obj_once(&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_instReprMyNat_repr___closed__2, &lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_instReprMyNat_repr___closed__2_once, _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_instReprMyNat_repr___closed__2);
v___y_249_ = v___x_257_;
goto v___jp_248_;
}
else
{
lean_object* v___x_258_; 
v___x_258_ = lean_obj_once(&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_instReprMyNat_repr___closed__3, &lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_instReprMyNat_repr___closed__3_once, _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_instReprMyNat_repr___closed__3);
v___y_249_ = v___x_258_;
goto v___jp_248_;
}
}
else
{
lean_object* v_head_259_; lean_object* v_tail_260_; lean_object* v___x_262_; uint8_t v_isShared_263_; uint8_t v_isSharedCheck_283_; 
v_head_259_ = lean_ctor_get(v_x_246_, 0);
v_tail_260_ = lean_ctor_get(v_x_246_, 1);
v_isSharedCheck_283_ = !lean_is_exclusive(v_x_246_);
if (v_isSharedCheck_283_ == 0)
{
v___x_262_ = v_x_246_;
v_isShared_263_ = v_isSharedCheck_283_;
goto v_resetjp_261_;
}
else
{
lean_inc(v_tail_260_);
lean_inc(v_head_259_);
lean_dec(v_x_246_);
v___x_262_ = lean_box(0);
v_isShared_263_ = v_isSharedCheck_283_;
goto v_resetjp_261_;
}
v_resetjp_261_:
{
lean_object* v___x_264_; lean_object* v___y_266_; uint8_t v___x_280_; 
v___x_264_ = lean_unsigned_to_nat(1024u);
v___x_280_ = lean_nat_dec_le(v___x_264_, v_prec_247_);
if (v___x_280_ == 0)
{
lean_object* v___x_281_; 
v___x_281_ = lean_obj_once(&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_instReprMyNat_repr___closed__2, &lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_instReprMyNat_repr___closed__2_once, _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_instReprMyNat_repr___closed__2);
v___y_266_ = v___x_281_;
goto v___jp_265_;
}
else
{
lean_object* v___x_282_; 
v___x_282_ = lean_obj_once(&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_instReprMyNat_repr___closed__3, &lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_instReprMyNat_repr___closed__3_once, _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_instReprMyNat_repr___closed__3);
v___y_266_ = v___x_282_;
goto v___jp_265_;
}
v___jp_265_:
{
lean_object* v___x_267_; lean_object* v___x_268_; lean_object* v___x_269_; lean_object* v___x_271_; 
v___x_267_ = lean_box(1);
v___x_268_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_instReprMyList_repr___redArg___closed__4));
lean_inc_ref(v_inst_245_);
v___x_269_ = lean_apply_2(v_inst_245_, v_head_259_, v___x_264_);
if (v_isShared_263_ == 0)
{
lean_ctor_set_tag(v___x_262_, 5);
lean_ctor_set(v___x_262_, 1, v___x_269_);
lean_ctor_set(v___x_262_, 0, v___x_268_);
v___x_271_ = v___x_262_;
goto v_reusejp_270_;
}
else
{
lean_object* v_reuseFailAlloc_279_; 
v_reuseFailAlloc_279_ = lean_alloc_ctor(5, 2, 0);
lean_ctor_set(v_reuseFailAlloc_279_, 0, v___x_268_);
lean_ctor_set(v_reuseFailAlloc_279_, 1, v___x_269_);
v___x_271_ = v_reuseFailAlloc_279_;
goto v_reusejp_270_;
}
v_reusejp_270_:
{
lean_object* v___x_272_; lean_object* v___x_273_; lean_object* v___x_274_; lean_object* v___x_275_; uint8_t v___x_276_; lean_object* v___x_277_; lean_object* v___x_278_; 
v___x_272_ = lean_alloc_ctor(5, 2, 0);
lean_ctor_set(v___x_272_, 0, v___x_271_);
lean_ctor_set(v___x_272_, 1, v___x_267_);
v___x_273_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_instReprMyList_repr___redArg(v_inst_245_, v_tail_260_, v___x_264_);
v___x_274_ = lean_alloc_ctor(5, 2, 0);
lean_ctor_set(v___x_274_, 0, v___x_272_);
lean_ctor_set(v___x_274_, 1, v___x_273_);
lean_inc(v___y_266_);
v___x_275_ = lean_alloc_ctor(4, 2, 0);
lean_ctor_set(v___x_275_, 0, v___y_266_);
lean_ctor_set(v___x_275_, 1, v___x_274_);
v___x_276_ = 0;
v___x_277_ = lean_alloc_ctor(6, 1, 1);
lean_ctor_set(v___x_277_, 0, v___x_275_);
lean_ctor_set_uint8(v___x_277_, sizeof(void*)*1, v___x_276_);
v___x_278_ = l_Repr_addAppParen(v___x_277_, v_prec_247_);
return v___x_278_;
}
}
}
}
v___jp_248_:
{
lean_object* v___x_250_; lean_object* v___x_251_; uint8_t v___x_252_; lean_object* v___x_253_; lean_object* v___x_254_; 
v___x_250_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_instReprMyList_repr___redArg___closed__1));
lean_inc(v___y_249_);
v___x_251_ = lean_alloc_ctor(4, 2, 0);
lean_ctor_set(v___x_251_, 0, v___y_249_);
lean_ctor_set(v___x_251_, 1, v___x_250_);
v___x_252_ = 0;
v___x_253_ = lean_alloc_ctor(6, 1, 1);
lean_ctor_set(v___x_253_, 0, v___x_251_);
lean_ctor_set_uint8(v___x_253_, sizeof(void*)*1, v___x_252_);
v___x_254_ = l_Repr_addAppParen(v___x_253_, v_prec_247_);
return v___x_254_;
}
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_instReprMyList_repr___redArg___boxed(lean_object* v_inst_284_, lean_object* v_x_285_, lean_object* v_prec_286_){
_start:
{
lean_object* v_res_287_; 
v_res_287_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_instReprMyList_repr___redArg(v_inst_284_, v_x_285_, v_prec_286_);
lean_dec(v_prec_286_);
return v_res_287_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_instReprMyList_repr(lean_object* v_00_u03b1_288_, lean_object* v_inst_289_, lean_object* v_x_290_, lean_object* v_prec_291_){
_start:
{
lean_object* v___x_292_; 
v___x_292_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_instReprMyList_repr___redArg(v_inst_289_, v_x_290_, v_prec_291_);
return v___x_292_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_instReprMyList_repr___boxed(lean_object* v_00_u03b1_293_, lean_object* v_inst_294_, lean_object* v_x_295_, lean_object* v_prec_296_){
_start:
{
lean_object* v_res_297_; 
v_res_297_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_instReprMyList_repr(v_00_u03b1_293_, v_inst_294_, v_x_295_, v_prec_296_);
lean_dec(v_prec_296_);
return v_res_297_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_instReprMyList___redArg(lean_object* v_inst_298_){
_start:
{
lean_object* v___x_299_; 
v___x_299_ = lean_alloc_closure((void*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_instReprMyList_repr___boxed), 4, 2);
lean_closure_set(v___x_299_, 0, lean_box(0));
lean_closure_set(v___x_299_, 1, v_inst_298_);
return v___x_299_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_instReprMyList(lean_object* v_00_u03b1_300_, lean_object* v_inst_301_){
_start:
{
lean_object* v___x_302_; 
v___x_302_ = lean_alloc_closure((void*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_instReprMyList_repr___boxed), 4, 2);
lean_closure_set(v___x_302_, 0, lean_box(0));
lean_closure_set(v___x_302_, 1, v_inst_301_);
return v___x_302_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_empty__list(void){
_start:
{
lean_object* v___x_303_; 
v___x_303_ = lean_box(0);
return v___x_303_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_length___redArg(lean_object* v_l_318_){
_start:
{
if (lean_obj_tag(v_l_318_) == 0)
{
lean_object* v___x_319_; 
v___x_319_ = lean_unsigned_to_nat(0u);
return v___x_319_;
}
else
{
lean_object* v_tail_320_; lean_object* v___x_321_; lean_object* v___x_322_; lean_object* v___x_323_; 
v_tail_320_ = lean_ctor_get(v_l_318_, 1);
v___x_321_ = lean_unsigned_to_nat(1u);
v___x_322_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_length___redArg(v_tail_320_);
v___x_323_ = lean_nat_add(v___x_321_, v___x_322_);
lean_dec(v___x_322_);
return v___x_323_;
}
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_length___redArg___boxed(lean_object* v_l_324_){
_start:
{
lean_object* v_res_325_; 
v_res_325_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_length___redArg(v_l_324_);
lean_dec(v_l_324_);
return v_res_325_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_length(lean_object* v_00_u03b1_326_, lean_object* v_l_327_){
_start:
{
lean_object* v___x_328_; 
v___x_328_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_length___redArg(v_l_327_);
return v___x_328_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_length___boxed(lean_object* v_00_u03b1_329_, lean_object* v_l_330_){
_start:
{
lean_object* v_res_331_; 
v_res_331_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_length(v_00_u03b1_329_, v_l_330_);
lean_dec(v_l_330_);
return v_res_331_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_len1___closed__0(void){
_start:
{
lean_object* v___x_332_; lean_object* v___x_333_; 
v___x_332_ = lean_box(0);
v___x_333_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_length___redArg(v___x_332_);
return v___x_333_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_len1(void){
_start:
{
lean_object* v___x_334_; 
v___x_334_ = lean_obj_once(&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_len1___closed__0, &lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_len1___closed__0_once, _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_len1___closed__0);
return v___x_334_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_len2___closed__0(void){
_start:
{
lean_object* v___x_335_; lean_object* v___x_336_; 
v___x_335_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_list123));
v___x_336_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_length___redArg(v___x_335_);
return v___x_336_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_len2(void){
_start:
{
lean_object* v___x_337_; 
v___x_337_ = lean_obj_once(&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_len2___closed__0, &lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_len2___closed__0_once, _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_len2___closed__0);
return v___x_337_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_append___redArg(lean_object* v_l1_338_, lean_object* v_l2_339_){
_start:
{
if (lean_obj_tag(v_l1_338_) == 0)
{
lean_inc(v_l2_339_);
return v_l2_339_;
}
else
{
lean_object* v_head_340_; lean_object* v_tail_341_; lean_object* v___x_343_; uint8_t v_isShared_344_; uint8_t v_isSharedCheck_349_; 
v_head_340_ = lean_ctor_get(v_l1_338_, 0);
v_tail_341_ = lean_ctor_get(v_l1_338_, 1);
v_isSharedCheck_349_ = !lean_is_exclusive(v_l1_338_);
if (v_isSharedCheck_349_ == 0)
{
v___x_343_ = v_l1_338_;
v_isShared_344_ = v_isSharedCheck_349_;
goto v_resetjp_342_;
}
else
{
lean_inc(v_tail_341_);
lean_inc(v_head_340_);
lean_dec(v_l1_338_);
v___x_343_ = lean_box(0);
v_isShared_344_ = v_isSharedCheck_349_;
goto v_resetjp_342_;
}
v_resetjp_342_:
{
lean_object* v___x_345_; lean_object* v___x_347_; 
v___x_345_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_append___redArg(v_tail_341_, v_l2_339_);
if (v_isShared_344_ == 0)
{
lean_ctor_set(v___x_343_, 1, v___x_345_);
v___x_347_ = v___x_343_;
goto v_reusejp_346_;
}
else
{
lean_object* v_reuseFailAlloc_348_; 
v_reuseFailAlloc_348_ = lean_alloc_ctor(1, 2, 0);
lean_ctor_set(v_reuseFailAlloc_348_, 0, v_head_340_);
lean_ctor_set(v_reuseFailAlloc_348_, 1, v___x_345_);
v___x_347_ = v_reuseFailAlloc_348_;
goto v_reusejp_346_;
}
v_reusejp_346_:
{
return v___x_347_;
}
}
}
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_append___redArg___boxed(lean_object* v_l1_350_, lean_object* v_l2_351_){
_start:
{
lean_object* v_res_352_; 
v_res_352_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_append___redArg(v_l1_350_, v_l2_351_);
lean_dec(v_l2_351_);
return v_res_352_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_append(lean_object* v_00_u03b1_353_, lean_object* v_l1_354_, lean_object* v_l2_355_){
_start:
{
lean_object* v___x_356_; 
v___x_356_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_append___redArg(v_l1_354_, v_l2_355_);
return v___x_356_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_append___boxed(lean_object* v_00_u03b1_357_, lean_object* v_l1_358_, lean_object* v_l2_359_){
_start:
{
lean_object* v_res_360_; 
v_res_360_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_append(v_00_u03b1_357_, v_l1_358_, v_l2_359_);
lean_dec(v_l2_359_);
return v_res_360_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_appended___closed__0(void){
_start:
{
lean_object* v___x_361_; lean_object* v___x_362_; lean_object* v___x_363_; 
v___x_361_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_list123___closed__1));
v___x_362_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_singleton___closed__0));
v___x_363_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_append___redArg(v___x_362_, v___x_361_);
return v___x_363_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_appended(void){
_start:
{
lean_object* v___x_364_; 
v___x_364_ = lean_obj_once(&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_appended___closed__0, &lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_appended___closed__0_once, _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_appended___closed__0);
return v___x_364_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_map___redArg(lean_object* v_f_365_, lean_object* v_l_366_){
_start:
{
if (lean_obj_tag(v_l_366_) == 0)
{
lean_object* v___x_367_; 
lean_dec(v_f_365_);
v___x_367_ = lean_box(0);
return v___x_367_;
}
else
{
lean_object* v_head_368_; lean_object* v_tail_369_; lean_object* v___x_371_; uint8_t v_isShared_372_; uint8_t v_isSharedCheck_378_; 
v_head_368_ = lean_ctor_get(v_l_366_, 0);
v_tail_369_ = lean_ctor_get(v_l_366_, 1);
v_isSharedCheck_378_ = !lean_is_exclusive(v_l_366_);
if (v_isSharedCheck_378_ == 0)
{
v___x_371_ = v_l_366_;
v_isShared_372_ = v_isSharedCheck_378_;
goto v_resetjp_370_;
}
else
{
lean_inc(v_tail_369_);
lean_inc(v_head_368_);
lean_dec(v_l_366_);
v___x_371_ = lean_box(0);
v_isShared_372_ = v_isSharedCheck_378_;
goto v_resetjp_370_;
}
v_resetjp_370_:
{
lean_object* v___x_373_; lean_object* v___x_374_; lean_object* v___x_376_; 
lean_inc(v_f_365_);
v___x_373_ = lean_apply_1(v_f_365_, v_head_368_);
v___x_374_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_map___redArg(v_f_365_, v_tail_369_);
if (v_isShared_372_ == 0)
{
lean_ctor_set(v___x_371_, 1, v___x_374_);
lean_ctor_set(v___x_371_, 0, v___x_373_);
v___x_376_ = v___x_371_;
goto v_reusejp_375_;
}
else
{
lean_object* v_reuseFailAlloc_377_; 
v_reuseFailAlloc_377_ = lean_alloc_ctor(1, 2, 0);
lean_ctor_set(v_reuseFailAlloc_377_, 0, v___x_373_);
lean_ctor_set(v_reuseFailAlloc_377_, 1, v___x_374_);
v___x_376_ = v_reuseFailAlloc_377_;
goto v_reusejp_375_;
}
v_reusejp_375_:
{
return v___x_376_;
}
}
}
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_map(lean_object* v_00_u03b1_379_, lean_object* v_00_u03b2_380_, lean_object* v_f_381_, lean_object* v_l_382_){
_start:
{
lean_object* v___x_383_; 
v___x_383_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_map___redArg(v_f_381_, v_l_382_);
return v___x_383_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_doubled___lam__0(lean_object* v_x_384_){
_start:
{
lean_object* v___x_385_; lean_object* v___x_386_; 
v___x_385_ = lean_unsigned_to_nat(2u);
v___x_386_ = lean_nat_mul(v_x_384_, v___x_385_);
return v___x_386_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_doubled___lam__0___boxed(lean_object* v_x_387_){
_start:
{
lean_object* v_res_388_; 
v_res_388_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_doubled___lam__0(v_x_387_);
lean_dec(v_x_387_);
return v_res_388_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_doubled___closed__1(void){
_start:
{
lean_object* v___x_390_; lean_object* v___f_391_; lean_object* v___x_392_; 
v___x_390_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_list123));
v___f_391_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_doubled___closed__0));
v___x_392_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_map___redArg(v___f_391_, v___x_390_);
return v___x_392_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_doubled(void){
_start:
{
lean_object* v___x_393_; 
v___x_393_ = lean_obj_once(&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_doubled___closed__1, &lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_doubled___closed__1_once, _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_doubled___closed__1);
return v___x_393_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_filter___redArg(lean_object* v_p_394_, lean_object* v_l_395_){
_start:
{
if (lean_obj_tag(v_l_395_) == 0)
{
lean_dec_ref(v_p_394_);
return v_l_395_;
}
else
{
lean_object* v_head_396_; lean_object* v_tail_397_; lean_object* v___x_399_; uint8_t v_isShared_400_; uint8_t v_isSharedCheck_408_; 
v_head_396_ = lean_ctor_get(v_l_395_, 0);
v_tail_397_ = lean_ctor_get(v_l_395_, 1);
v_isSharedCheck_408_ = !lean_is_exclusive(v_l_395_);
if (v_isSharedCheck_408_ == 0)
{
v___x_399_ = v_l_395_;
v_isShared_400_ = v_isSharedCheck_408_;
goto v_resetjp_398_;
}
else
{
lean_inc(v_tail_397_);
lean_inc(v_head_396_);
lean_dec(v_l_395_);
v___x_399_ = lean_box(0);
v_isShared_400_ = v_isSharedCheck_408_;
goto v_resetjp_398_;
}
v_resetjp_398_:
{
lean_object* v___x_401_; uint8_t v___x_402_; 
lean_inc_ref(v_p_394_);
lean_inc(v_head_396_);
v___x_401_ = lean_apply_1(v_p_394_, v_head_396_);
v___x_402_ = lean_unbox(v___x_401_);
if (v___x_402_ == 0)
{
lean_del_object(v___x_399_);
lean_dec(v_head_396_);
v_l_395_ = v_tail_397_;
goto _start;
}
else
{
lean_object* v___x_404_; lean_object* v___x_406_; 
v___x_404_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_filter___redArg(v_p_394_, v_tail_397_);
if (v_isShared_400_ == 0)
{
lean_ctor_set(v___x_399_, 1, v___x_404_);
v___x_406_ = v___x_399_;
goto v_reusejp_405_;
}
else
{
lean_object* v_reuseFailAlloc_407_; 
v_reuseFailAlloc_407_ = lean_alloc_ctor(1, 2, 0);
lean_ctor_set(v_reuseFailAlloc_407_, 0, v_head_396_);
lean_ctor_set(v_reuseFailAlloc_407_, 1, v___x_404_);
v___x_406_ = v_reuseFailAlloc_407_;
goto v_reusejp_405_;
}
v_reusejp_405_:
{
return v___x_406_;
}
}
}
}
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_filter(lean_object* v_00_u03b1_409_, lean_object* v_p_410_, lean_object* v_l_411_){
_start:
{
lean_object* v___x_412_; 
v___x_412_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_filter___redArg(v_p_410_, v_l_411_);
return v___x_412_;
}
}
LEAN_EXPORT uint8_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_evens___lam__0(lean_object* v_x_413_){
_start:
{
lean_object* v___x_414_; lean_object* v___x_415_; lean_object* v___x_416_; uint8_t v___x_417_; 
v___x_414_ = lean_unsigned_to_nat(2u);
v___x_415_ = lean_nat_mod(v_x_413_, v___x_414_);
v___x_416_ = lean_unsigned_to_nat(0u);
v___x_417_ = lean_nat_dec_eq(v___x_415_, v___x_416_);
lean_dec(v___x_415_);
return v___x_417_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_evens___lam__0___boxed(lean_object* v_x_418_){
_start:
{
uint8_t v_res_419_; lean_object* v_r_420_; 
v_res_419_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_evens___lam__0(v_x_418_);
lean_dec(v_x_418_);
v_r_420_ = lean_box(v_res_419_);
return v_r_420_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_evens___closed__1(void){
_start:
{
lean_object* v___x_422_; lean_object* v___f_423_; lean_object* v___x_424_; 
v___x_422_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_list123));
v___f_423_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_evens___closed__0));
v___x_424_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_filter___redArg(v___f_423_, v___x_422_);
return v___x_424_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_evens(void){
_start:
{
lean_object* v___x_425_; 
v___x_425_ = lean_obj_once(&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_evens___closed__1, &lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_evens___closed__1_once, _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_evens___closed__1);
return v___x_425_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_foldr___redArg(lean_object* v_f_426_, lean_object* v_init_427_, lean_object* v_l_428_){
_start:
{
if (lean_obj_tag(v_l_428_) == 0)
{
lean_dec(v_f_426_);
lean_inc(v_init_427_);
return v_init_427_;
}
else
{
lean_object* v_head_429_; lean_object* v_tail_430_; lean_object* v___x_431_; lean_object* v___x_432_; 
v_head_429_ = lean_ctor_get(v_l_428_, 0);
lean_inc(v_head_429_);
v_tail_430_ = lean_ctor_get(v_l_428_, 1);
lean_inc(v_tail_430_);
lean_dec_ref_known(v_l_428_, 2);
lean_inc(v_f_426_);
v___x_431_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_foldr___redArg(v_f_426_, v_init_427_, v_tail_430_);
v___x_432_ = lean_apply_2(v_f_426_, v_head_429_, v___x_431_);
return v___x_432_;
}
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_foldr___redArg___boxed(lean_object* v_f_433_, lean_object* v_init_434_, lean_object* v_l_435_){
_start:
{
lean_object* v_res_436_; 
v_res_436_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_foldr___redArg(v_f_433_, v_init_434_, v_l_435_);
lean_dec(v_init_434_);
return v_res_436_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_foldr(lean_object* v_00_u03b1_437_, lean_object* v_00_u03b2_438_, lean_object* v_f_439_, lean_object* v_init_440_, lean_object* v_l_441_){
_start:
{
lean_object* v___x_442_; 
v___x_442_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_foldr___redArg(v_f_439_, v_init_440_, v_l_441_);
return v___x_442_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_foldr___boxed(lean_object* v_00_u03b1_443_, lean_object* v_00_u03b2_444_, lean_object* v_f_445_, lean_object* v_init_446_, lean_object* v_l_447_){
_start:
{
lean_object* v_res_448_; 
v_res_448_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_foldr(v_00_u03b1_443_, v_00_u03b2_444_, v_f_445_, v_init_446_, v_l_447_);
lean_dec(v_init_446_);
return v_res_448_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_sum__list___closed__1(void){
_start:
{
lean_object* v___x_450_; lean_object* v___x_451_; lean_object* v___f_452_; lean_object* v___x_453_; 
v___x_450_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_list123));
v___x_451_ = lean_unsigned_to_nat(0u);
v___f_452_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_sum__list___closed__0));
v___x_453_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_foldr___redArg(v___f_452_, v___x_451_, v___x_450_);
return v___x_453_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_sum__list(void){
_start:
{
lean_object* v___x_454_; 
v___x_454_ = lean_obj_once(&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_sum__list___closed__1, &lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_sum__list___closed__1_once, _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_sum__list___closed__1);
return v___x_454_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_product__list___closed__1(void){
_start:
{
lean_object* v___x_456_; lean_object* v___x_457_; lean_object* v___f_458_; lean_object* v___x_459_; 
v___x_456_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_list123));
v___x_457_ = lean_unsigned_to_nat(1u);
v___f_458_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_product__list___closed__0));
v___x_459_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_foldr___redArg(v___f_458_, v___x_457_, v___x_456_);
return v___x_459_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_product__list(void){
_start:
{
lean_object* v___x_460_; 
v___x_460_ = lean_obj_once(&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_product__list___closed__1, &lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_product__list___closed__1_once, _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_product__list___closed__1);
return v___x_460_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_std__empty(void){
_start:
{
lean_object* v___x_477_; 
v___x_477_ = lean_box(0);
return v___x_477_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_std__length___closed__0(void){
_start:
{
lean_object* v___x_478_; lean_object* v___x_479_; 
v___x_478_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_std__list));
v___x_479_ = l_List_lengthTR___redArg(v___x_478_);
return v___x_479_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_std__length(void){
_start:
{
lean_object* v___x_480_; 
v___x_480_ = lean_obj_once(&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_std__length___closed__0, &lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_std__length___closed__0_once, _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_std__length___closed__0);
return v___x_480_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_std__head_x3f___closed__0(void){
_start:
{
lean_object* v___x_481_; lean_object* v___x_482_; 
v___x_481_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_std__list));
v___x_482_ = l_List_head_x3f___redArg(v___x_481_);
return v___x_482_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_std__head_x3f(void){
_start:
{
lean_object* v___x_483_; 
v___x_483_ = lean_obj_once(&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_std__head_x3f___closed__0, &lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_std__head_x3f___closed__0_once, _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_std__head_x3f___closed__0);
return v___x_483_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_std__tail___closed__0(void){
_start:
{
lean_object* v___x_484_; lean_object* v___x_485_; 
v___x_484_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_std__list));
v___x_485_ = l_List_tail_x21___redArg(v___x_484_);
return v___x_485_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_std__tail(void){
_start:
{
lean_object* v___x_486_; 
v___x_486_ = lean_obj_once(&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_std__tail___closed__0, &lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_std__tail___closed__0_once, _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_std__tail___closed__0);
return v___x_486_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_std__append___closed__4(void){
_start:
{
lean_object* v___x_499_; lean_object* v___x_500_; lean_object* v___x_501_; 
v___x_499_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_std__append___closed__3));
v___x_500_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_std__append___closed__1));
v___x_501_ = l_List_appendTR___redArg(v___x_500_, v___x_499_);
return v___x_501_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_std__append(void){
_start:
{
lean_object* v___x_502_; 
v___x_502_ = lean_obj_once(&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_std__append___closed__4, &lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_std__append___closed__4_once, _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_std__append___closed__4);
return v___x_502_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_List_mapTR_loop___at___00Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_std__map_spec__0(lean_object* v_a_503_, lean_object* v_a_504_){
_start:
{
if (lean_obj_tag(v_a_503_) == 0)
{
lean_object* v___x_505_; 
v___x_505_ = l_List_reverse___redArg(v_a_504_);
return v___x_505_;
}
else
{
lean_object* v_head_506_; lean_object* v_tail_507_; lean_object* v___x_509_; uint8_t v_isShared_510_; uint8_t v_isSharedCheck_517_; 
v_head_506_ = lean_ctor_get(v_a_503_, 0);
v_tail_507_ = lean_ctor_get(v_a_503_, 1);
v_isSharedCheck_517_ = !lean_is_exclusive(v_a_503_);
if (v_isSharedCheck_517_ == 0)
{
v___x_509_ = v_a_503_;
v_isShared_510_ = v_isSharedCheck_517_;
goto v_resetjp_508_;
}
else
{
lean_inc(v_tail_507_);
lean_inc(v_head_506_);
lean_dec(v_a_503_);
v___x_509_ = lean_box(0);
v_isShared_510_ = v_isSharedCheck_517_;
goto v_resetjp_508_;
}
v_resetjp_508_:
{
lean_object* v___x_511_; lean_object* v___x_512_; lean_object* v___x_514_; 
v___x_511_ = lean_unsigned_to_nat(2u);
v___x_512_ = lean_nat_mul(v_head_506_, v___x_511_);
lean_dec(v_head_506_);
if (v_isShared_510_ == 0)
{
lean_ctor_set(v___x_509_, 1, v_a_504_);
lean_ctor_set(v___x_509_, 0, v___x_512_);
v___x_514_ = v___x_509_;
goto v_reusejp_513_;
}
else
{
lean_object* v_reuseFailAlloc_516_; 
v_reuseFailAlloc_516_ = lean_alloc_ctor(1, 2, 0);
lean_ctor_set(v_reuseFailAlloc_516_, 0, v___x_512_);
lean_ctor_set(v_reuseFailAlloc_516_, 1, v_a_504_);
v___x_514_ = v_reuseFailAlloc_516_;
goto v_reusejp_513_;
}
v_reusejp_513_:
{
v_a_503_ = v_tail_507_;
v_a_504_ = v___x_514_;
goto _start;
}
}
}
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_std__map___closed__3(void){
_start:
{
lean_object* v___x_527_; lean_object* v___x_528_; lean_object* v___x_529_; 
v___x_527_ = lean_box(0);
v___x_528_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_std__map___closed__2));
v___x_529_ = lp_lean4_x2dtutorial_List_mapTR_loop___at___00Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_std__map_spec__0(v___x_528_, v___x_527_);
return v___x_529_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_std__map(void){
_start:
{
lean_object* v___x_530_; 
v___x_530_ = lean_obj_once(&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_std__map___closed__3, &lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_std__map___closed__3_once, _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_std__map___closed__3);
return v___x_530_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_List_filterTR_loop___at___00Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_std__filter_spec__0(lean_object* v_a_531_, lean_object* v_a_532_){
_start:
{
if (lean_obj_tag(v_a_531_) == 0)
{
lean_object* v___x_533_; 
v___x_533_ = l_List_reverse___redArg(v_a_532_);
return v___x_533_;
}
else
{
lean_object* v_head_534_; lean_object* v_tail_535_; lean_object* v___x_537_; uint8_t v_isShared_538_; uint8_t v_isSharedCheck_548_; 
v_head_534_ = lean_ctor_get(v_a_531_, 0);
v_tail_535_ = lean_ctor_get(v_a_531_, 1);
v_isSharedCheck_548_ = !lean_is_exclusive(v_a_531_);
if (v_isSharedCheck_548_ == 0)
{
v___x_537_ = v_a_531_;
v_isShared_538_ = v_isSharedCheck_548_;
goto v_resetjp_536_;
}
else
{
lean_inc(v_tail_535_);
lean_inc(v_head_534_);
lean_dec(v_a_531_);
v___x_537_ = lean_box(0);
v_isShared_538_ = v_isSharedCheck_548_;
goto v_resetjp_536_;
}
v_resetjp_536_:
{
lean_object* v___x_539_; lean_object* v___x_540_; lean_object* v___x_541_; uint8_t v___x_542_; 
v___x_539_ = lean_unsigned_to_nat(2u);
v___x_540_ = lean_nat_mod(v_head_534_, v___x_539_);
v___x_541_ = lean_unsigned_to_nat(0u);
v___x_542_ = lean_nat_dec_eq(v___x_540_, v___x_541_);
lean_dec(v___x_540_);
if (v___x_542_ == 0)
{
lean_del_object(v___x_537_);
lean_dec(v_head_534_);
v_a_531_ = v_tail_535_;
goto _start;
}
else
{
lean_object* v___x_545_; 
if (v_isShared_538_ == 0)
{
lean_ctor_set(v___x_537_, 1, v_a_532_);
v___x_545_ = v___x_537_;
goto v_reusejp_544_;
}
else
{
lean_object* v_reuseFailAlloc_547_; 
v_reuseFailAlloc_547_ = lean_alloc_ctor(1, 2, 0);
lean_ctor_set(v_reuseFailAlloc_547_, 0, v_head_534_);
lean_ctor_set(v_reuseFailAlloc_547_, 1, v_a_532_);
v___x_545_ = v_reuseFailAlloc_547_;
goto v_reusejp_544_;
}
v_reusejp_544_:
{
v_a_531_ = v_tail_535_;
v_a_532_ = v___x_545_;
goto _start;
}
}
}
}
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_std__filter___closed__2(void){
_start:
{
lean_object* v___x_555_; lean_object* v___x_556_; lean_object* v___x_557_; 
v___x_555_ = lean_box(0);
v___x_556_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_std__filter___closed__1));
v___x_557_ = lp_lean4_x2dtutorial_List_filterTR_loop___at___00Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_std__filter_spec__0(v___x_556_, v___x_555_);
return v___x_557_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_std__filter(void){
_start:
{
lean_object* v___x_558_; 
v___x_558_ = lean_obj_once(&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_std__filter___closed__2, &lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_std__filter___closed__2_once, _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_std__filter___closed__2);
return v___x_558_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_List_foldl___at___00Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_std__sum_spec__0(lean_object* v_x_559_, lean_object* v_x_560_){
_start:
{
if (lean_obj_tag(v_x_560_) == 0)
{
return v_x_559_;
}
else
{
lean_object* v_head_561_; lean_object* v_tail_562_; lean_object* v___x_563_; 
v_head_561_ = lean_ctor_get(v_x_560_, 0);
v_tail_562_ = lean_ctor_get(v_x_560_, 1);
v___x_563_ = lean_nat_add(v_x_559_, v_head_561_);
lean_dec(v_x_559_);
v_x_559_ = v___x_563_;
v_x_560_ = v_tail_562_;
goto _start;
}
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_List_foldl___at___00Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_std__sum_spec__0___boxed(lean_object* v_x_565_, lean_object* v_x_566_){
_start:
{
lean_object* v_res_567_; 
v_res_567_ = lp_lean4_x2dtutorial_List_foldl___at___00Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_std__sum_spec__0(v_x_565_, v_x_566_);
lean_dec(v_x_566_);
return v_res_567_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_std__sum___closed__0(void){
_start:
{
lean_object* v___x_568_; lean_object* v___x_569_; lean_object* v___x_570_; 
v___x_568_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_std__map___closed__2));
v___x_569_ = lean_unsigned_to_nat(0u);
v___x_570_ = lp_lean4_x2dtutorial_List_foldl___at___00Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_std__sum_spec__0(v___x_569_, v___x_568_);
return v___x_570_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_std__sum(void){
_start:
{
lean_object* v___x_571_; 
v___x_571_ = lean_obj_once(&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_std__sum___closed__0, &lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_std__sum___closed__0_once, _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_std__sum___closed__0);
return v___x_571_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial___private_Init_Data_Array_Basic_0__Array_foldrMUnsafe_fold___at___00List_foldrTR___at___00Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_std__foldr_spec__0_spec__0(lean_object* v_as_572_, size_t v_i_573_, size_t v_stop_574_, lean_object* v_b_575_){
_start:
{
uint8_t v___x_576_; 
v___x_576_ = lean_usize_dec_eq(v_i_573_, v_stop_574_);
if (v___x_576_ == 0)
{
size_t v___x_577_; size_t v___x_578_; lean_object* v___x_579_; lean_object* v___x_580_; 
v___x_577_ = ((size_t)1ULL);
v___x_578_ = lean_usize_sub(v_i_573_, v___x_577_);
v___x_579_ = lean_array_uget_borrowed(v_as_572_, v___x_578_);
v___x_580_ = lean_nat_add(v___x_579_, v_b_575_);
lean_dec(v_b_575_);
v_i_573_ = v___x_578_;
v_b_575_ = v___x_580_;
goto _start;
}
else
{
return v_b_575_;
}
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial___private_Init_Data_Array_Basic_0__Array_foldrMUnsafe_fold___at___00List_foldrTR___at___00Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_std__foldr_spec__0_spec__0___boxed(lean_object* v_as_582_, lean_object* v_i_583_, lean_object* v_stop_584_, lean_object* v_b_585_){
_start:
{
size_t v_i_boxed_586_; size_t v_stop_boxed_587_; lean_object* v_res_588_; 
v_i_boxed_586_ = lean_unbox_usize(v_i_583_);
lean_dec(v_i_583_);
v_stop_boxed_587_ = lean_unbox_usize(v_stop_584_);
lean_dec(v_stop_584_);
v_res_588_ = lp_lean4_x2dtutorial___private_Init_Data_Array_Basic_0__Array_foldrMUnsafe_fold___at___00List_foldrTR___at___00Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_std__foldr_spec__0_spec__0(v_as_582_, v_i_boxed_586_, v_stop_boxed_587_, v_b_585_);
lean_dec_ref(v_as_582_);
return v_res_588_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_List_foldrTR___at___00Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_std__foldr_spec__0(lean_object* v_init_589_, lean_object* v_l_590_){
_start:
{
lean_object* v___x_591_; lean_object* v___x_592_; lean_object* v___x_593_; uint8_t v___x_594_; 
v___x_591_ = lean_array_mk(v_l_590_);
v___x_592_ = lean_array_get_size(v___x_591_);
v___x_593_ = lean_unsigned_to_nat(0u);
v___x_594_ = lean_nat_dec_lt(v___x_593_, v___x_592_);
if (v___x_594_ == 0)
{
lean_dec_ref(v___x_591_);
return v_init_589_;
}
else
{
size_t v___x_595_; size_t v___x_596_; lean_object* v___x_597_; 
v___x_595_ = lean_usize_of_nat(v___x_592_);
v___x_596_ = ((size_t)0ULL);
v___x_597_ = lp_lean4_x2dtutorial___private_Init_Data_Array_Basic_0__Array_foldrMUnsafe_fold___at___00List_foldrTR___at___00Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_std__foldr_spec__0_spec__0(v___x_591_, v___x_595_, v___x_596_, v_init_589_);
lean_dec_ref(v___x_591_);
return v___x_597_;
}
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_std__foldr___closed__0(void){
_start:
{
lean_object* v___x_598_; lean_object* v___x_599_; lean_object* v___x_600_; 
v___x_598_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_std__map___closed__2));
v___x_599_ = lean_unsigned_to_nat(0u);
v___x_600_ = lp_lean4_x2dtutorial_List_foldrTR___at___00Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_std__foldr_spec__0(v___x_599_, v___x_598_);
return v___x_600_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_std__foldr(void){
_start:
{
lean_object* v___x_601_; 
v___x_601_ = lean_obj_once(&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_std__foldr___closed__0, &lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_std__foldr___closed__0_once, _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_std__foldr___closed__0);
return v___x_601_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_BinTree_ctorIdx___redArg(lean_object* v_x_602_){
_start:
{
if (lean_obj_tag(v_x_602_) == 0)
{
lean_object* v___x_603_; 
v___x_603_ = lean_unsigned_to_nat(0u);
return v___x_603_;
}
else
{
lean_object* v___x_604_; 
v___x_604_ = lean_unsigned_to_nat(1u);
return v___x_604_;
}
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_BinTree_ctorIdx___redArg___boxed(lean_object* v_x_605_){
_start:
{
lean_object* v_res_606_; 
v_res_606_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_BinTree_ctorIdx___redArg(v_x_605_);
lean_dec(v_x_605_);
return v_res_606_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_BinTree_ctorIdx(lean_object* v_00_u03b1_607_, lean_object* v_x_608_){
_start:
{
lean_object* v___x_609_; 
v___x_609_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_BinTree_ctorIdx___redArg(v_x_608_);
return v___x_609_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_BinTree_ctorIdx___boxed(lean_object* v_00_u03b1_610_, lean_object* v_x_611_){
_start:
{
lean_object* v_res_612_; 
v_res_612_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_BinTree_ctorIdx(v_00_u03b1_610_, v_x_611_);
lean_dec(v_x_611_);
return v_res_612_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_BinTree_ctorElim___redArg(lean_object* v_t_613_, lean_object* v_k_614_){
_start:
{
if (lean_obj_tag(v_t_613_) == 0)
{
return v_k_614_;
}
else
{
lean_object* v_value_615_; lean_object* v_left_616_; lean_object* v_right_617_; lean_object* v___x_618_; 
v_value_615_ = lean_ctor_get(v_t_613_, 0);
lean_inc(v_value_615_);
v_left_616_ = lean_ctor_get(v_t_613_, 1);
lean_inc(v_left_616_);
v_right_617_ = lean_ctor_get(v_t_613_, 2);
lean_inc(v_right_617_);
lean_dec_ref_known(v_t_613_, 3);
v___x_618_ = lean_apply_3(v_k_614_, v_value_615_, v_left_616_, v_right_617_);
return v___x_618_;
}
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_BinTree_ctorElim(lean_object* v_00_u03b1_619_, lean_object* v_motive_620_, lean_object* v_ctorIdx_621_, lean_object* v_t_622_, lean_object* v_h_623_, lean_object* v_k_624_){
_start:
{
lean_object* v___x_625_; 
v___x_625_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_BinTree_ctorElim___redArg(v_t_622_, v_k_624_);
return v___x_625_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_BinTree_ctorElim___boxed(lean_object* v_00_u03b1_626_, lean_object* v_motive_627_, lean_object* v_ctorIdx_628_, lean_object* v_t_629_, lean_object* v_h_630_, lean_object* v_k_631_){
_start:
{
lean_object* v_res_632_; 
v_res_632_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_BinTree_ctorElim(v_00_u03b1_626_, v_motive_627_, v_ctorIdx_628_, v_t_629_, v_h_630_, v_k_631_);
lean_dec(v_ctorIdx_628_);
return v_res_632_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_BinTree_leaf_elim___redArg(lean_object* v_t_633_, lean_object* v_leaf_634_){
_start:
{
lean_object* v___x_635_; 
v___x_635_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_BinTree_ctorElim___redArg(v_t_633_, v_leaf_634_);
return v___x_635_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_BinTree_leaf_elim(lean_object* v_00_u03b1_636_, lean_object* v_motive_637_, lean_object* v_t_638_, lean_object* v_h_639_, lean_object* v_leaf_640_){
_start:
{
lean_object* v___x_641_; 
v___x_641_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_BinTree_ctorElim___redArg(v_t_638_, v_leaf_640_);
return v___x_641_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_BinTree_node_elim___redArg(lean_object* v_t_642_, lean_object* v_node_643_){
_start:
{
lean_object* v___x_644_; 
v___x_644_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_BinTree_ctorElim___redArg(v_t_642_, v_node_643_);
return v___x_644_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_BinTree_node_elim(lean_object* v_00_u03b1_645_, lean_object* v_motive_646_, lean_object* v_t_647_, lean_object* v_h_648_, lean_object* v_node_649_){
_start:
{
lean_object* v___x_650_; 
v___x_650_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_BinTree_ctorElim___redArg(v_t_647_, v_node_649_);
return v___x_650_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_instReprBinTree_repr___redArg(lean_object* v_inst_660_, lean_object* v_x_661_, lean_object* v_prec_662_){
_start:
{
lean_object* v___y_664_; 
if (lean_obj_tag(v_x_661_) == 0)
{
lean_object* v___x_670_; uint8_t v___x_671_; 
lean_dec_ref(v_inst_660_);
v___x_670_ = lean_unsigned_to_nat(1024u);
v___x_671_ = lean_nat_dec_le(v___x_670_, v_prec_662_);
if (v___x_671_ == 0)
{
lean_object* v___x_672_; 
v___x_672_ = lean_obj_once(&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_instReprMyNat_repr___closed__2, &lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_instReprMyNat_repr___closed__2_once, _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_instReprMyNat_repr___closed__2);
v___y_664_ = v___x_672_;
goto v___jp_663_;
}
else
{
lean_object* v___x_673_; 
v___x_673_ = lean_obj_once(&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_instReprMyNat_repr___closed__3, &lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_instReprMyNat_repr___closed__3_once, _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_instReprMyNat_repr___closed__3);
v___y_664_ = v___x_673_;
goto v___jp_663_;
}
}
else
{
lean_object* v_value_674_; lean_object* v_left_675_; lean_object* v_right_676_; lean_object* v___x_677_; lean_object* v___y_679_; uint8_t v___x_694_; 
v_value_674_ = lean_ctor_get(v_x_661_, 0);
lean_inc(v_value_674_);
v_left_675_ = lean_ctor_get(v_x_661_, 1);
lean_inc(v_left_675_);
v_right_676_ = lean_ctor_get(v_x_661_, 2);
lean_inc(v_right_676_);
lean_dec_ref_known(v_x_661_, 3);
v___x_677_ = lean_unsigned_to_nat(1024u);
v___x_694_ = lean_nat_dec_le(v___x_677_, v_prec_662_);
if (v___x_694_ == 0)
{
lean_object* v___x_695_; 
v___x_695_ = lean_obj_once(&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_instReprMyNat_repr___closed__2, &lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_instReprMyNat_repr___closed__2_once, _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_instReprMyNat_repr___closed__2);
v___y_679_ = v___x_695_;
goto v___jp_678_;
}
else
{
lean_object* v___x_696_; 
v___x_696_ = lean_obj_once(&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_instReprMyNat_repr___closed__3, &lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_instReprMyNat_repr___closed__3_once, _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_instReprMyNat_repr___closed__3);
v___y_679_ = v___x_696_;
goto v___jp_678_;
}
v___jp_678_:
{
lean_object* v___x_680_; lean_object* v___x_681_; lean_object* v___x_682_; lean_object* v___x_683_; lean_object* v___x_684_; lean_object* v___x_685_; lean_object* v___x_686_; lean_object* v___x_687_; lean_object* v___x_688_; lean_object* v___x_689_; lean_object* v___x_690_; uint8_t v___x_691_; lean_object* v___x_692_; lean_object* v___x_693_; 
v___x_680_ = lean_box(1);
v___x_681_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_instReprBinTree_repr___redArg___closed__4));
lean_inc_ref_n(v_inst_660_, 2);
v___x_682_ = lean_apply_2(v_inst_660_, v_value_674_, v___x_677_);
v___x_683_ = lean_alloc_ctor(5, 2, 0);
lean_ctor_set(v___x_683_, 0, v___x_681_);
lean_ctor_set(v___x_683_, 1, v___x_682_);
v___x_684_ = lean_alloc_ctor(5, 2, 0);
lean_ctor_set(v___x_684_, 0, v___x_683_);
lean_ctor_set(v___x_684_, 1, v___x_680_);
v___x_685_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_instReprBinTree_repr___redArg(v_inst_660_, v_left_675_, v___x_677_);
v___x_686_ = lean_alloc_ctor(5, 2, 0);
lean_ctor_set(v___x_686_, 0, v___x_684_);
lean_ctor_set(v___x_686_, 1, v___x_685_);
v___x_687_ = lean_alloc_ctor(5, 2, 0);
lean_ctor_set(v___x_687_, 0, v___x_686_);
lean_ctor_set(v___x_687_, 1, v___x_680_);
v___x_688_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_instReprBinTree_repr___redArg(v_inst_660_, v_right_676_, v___x_677_);
v___x_689_ = lean_alloc_ctor(5, 2, 0);
lean_ctor_set(v___x_689_, 0, v___x_687_);
lean_ctor_set(v___x_689_, 1, v___x_688_);
lean_inc(v___y_679_);
v___x_690_ = lean_alloc_ctor(4, 2, 0);
lean_ctor_set(v___x_690_, 0, v___y_679_);
lean_ctor_set(v___x_690_, 1, v___x_689_);
v___x_691_ = 0;
v___x_692_ = lean_alloc_ctor(6, 1, 1);
lean_ctor_set(v___x_692_, 0, v___x_690_);
lean_ctor_set_uint8(v___x_692_, sizeof(void*)*1, v___x_691_);
v___x_693_ = l_Repr_addAppParen(v___x_692_, v_prec_662_);
return v___x_693_;
}
}
v___jp_663_:
{
lean_object* v___x_665_; lean_object* v___x_666_; uint8_t v___x_667_; lean_object* v___x_668_; lean_object* v___x_669_; 
v___x_665_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_instReprBinTree_repr___redArg___closed__1));
lean_inc(v___y_664_);
v___x_666_ = lean_alloc_ctor(4, 2, 0);
lean_ctor_set(v___x_666_, 0, v___y_664_);
lean_ctor_set(v___x_666_, 1, v___x_665_);
v___x_667_ = 0;
v___x_668_ = lean_alloc_ctor(6, 1, 1);
lean_ctor_set(v___x_668_, 0, v___x_666_);
lean_ctor_set_uint8(v___x_668_, sizeof(void*)*1, v___x_667_);
v___x_669_ = l_Repr_addAppParen(v___x_668_, v_prec_662_);
return v___x_669_;
}
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_instReprBinTree_repr___redArg___boxed(lean_object* v_inst_697_, lean_object* v_x_698_, lean_object* v_prec_699_){
_start:
{
lean_object* v_res_700_; 
v_res_700_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_instReprBinTree_repr___redArg(v_inst_697_, v_x_698_, v_prec_699_);
lean_dec(v_prec_699_);
return v_res_700_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_instReprBinTree_repr(lean_object* v_00_u03b1_701_, lean_object* v_inst_702_, lean_object* v_x_703_, lean_object* v_prec_704_){
_start:
{
lean_object* v___x_705_; 
v___x_705_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_instReprBinTree_repr___redArg(v_inst_702_, v_x_703_, v_prec_704_);
return v___x_705_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_instReprBinTree_repr___boxed(lean_object* v_00_u03b1_706_, lean_object* v_inst_707_, lean_object* v_x_708_, lean_object* v_prec_709_){
_start:
{
lean_object* v_res_710_; 
v_res_710_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_instReprBinTree_repr(v_00_u03b1_706_, v_inst_707_, v_x_708_, v_prec_709_);
lean_dec(v_prec_709_);
return v_res_710_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_instReprBinTree___redArg(lean_object* v_inst_711_){
_start:
{
lean_object* v___x_712_; 
v___x_712_ = lean_alloc_closure((void*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_instReprBinTree_repr___boxed), 4, 2);
lean_closure_set(v___x_712_, 0, lean_box(0));
lean_closure_set(v___x_712_, 1, v_inst_711_);
return v___x_712_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_instReprBinTree(lean_object* v_00_u03b1_713_, lean_object* v_inst_714_){
_start:
{
lean_object* v___x_715_; 
v___x_715_ = lean_alloc_closure((void*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_instReprBinTree_repr___boxed), 4, 2);
lean_closure_set(v___x_715_, 0, lean_box(0));
lean_closure_set(v___x_715_, 1, v_inst_714_);
return v___x_715_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_size___redArg(lean_object* v_t_731_){
_start:
{
if (lean_obj_tag(v_t_731_) == 0)
{
lean_object* v___x_732_; 
v___x_732_ = lean_unsigned_to_nat(0u);
return v___x_732_;
}
else
{
lean_object* v_left_733_; lean_object* v_right_734_; lean_object* v___x_735_; lean_object* v___x_736_; lean_object* v___x_737_; lean_object* v___x_738_; lean_object* v___x_739_; 
v_left_733_ = lean_ctor_get(v_t_731_, 1);
v_right_734_ = lean_ctor_get(v_t_731_, 2);
v___x_735_ = lean_unsigned_to_nat(1u);
v___x_736_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_size___redArg(v_left_733_);
v___x_737_ = lean_nat_add(v___x_735_, v___x_736_);
lean_dec(v___x_736_);
v___x_738_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_size___redArg(v_right_734_);
v___x_739_ = lean_nat_add(v___x_737_, v___x_738_);
lean_dec(v___x_738_);
lean_dec(v___x_737_);
return v___x_739_;
}
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_size___redArg___boxed(lean_object* v_t_740_){
_start:
{
lean_object* v_res_741_; 
v_res_741_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_size___redArg(v_t_740_);
lean_dec(v_t_740_);
return v_res_741_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_size(lean_object* v_00_u03b1_742_, lean_object* v_t_743_){
_start:
{
lean_object* v___x_744_; 
v___x_744_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_size___redArg(v_t_743_);
return v___x_744_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_size___boxed(lean_object* v_00_u03b1_745_, lean_object* v_t_746_){
_start:
{
lean_object* v_res_747_; 
v_res_747_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_size(v_00_u03b1_745_, v_t_746_);
lean_dec(v_t_746_);
return v_res_747_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_tree__size___closed__0(void){
_start:
{
lean_object* v___x_748_; lean_object* v___x_749_; 
v___x_748_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_example__tree));
v___x_749_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_size___redArg(v___x_748_);
return v___x_749_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_tree__size(void){
_start:
{
lean_object* v___x_750_; 
v___x_750_ = lean_obj_once(&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_tree__size___closed__0, &lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_tree__size___closed__0_once, _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_tree__size___closed__0);
return v___x_750_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_height___redArg(lean_object* v_t_751_){
_start:
{
if (lean_obj_tag(v_t_751_) == 0)
{
lean_object* v___x_752_; 
v___x_752_ = lean_unsigned_to_nat(0u);
return v___x_752_;
}
else
{
lean_object* v_left_753_; lean_object* v_right_754_; lean_object* v___x_755_; lean_object* v___x_756_; lean_object* v___x_757_; uint8_t v___x_758_; 
v_left_753_ = lean_ctor_get(v_t_751_, 1);
v_right_754_ = lean_ctor_get(v_t_751_, 2);
v___x_755_ = lean_unsigned_to_nat(1u);
v___x_756_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_height___redArg(v_left_753_);
v___x_757_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_height___redArg(v_right_754_);
v___x_758_ = lean_nat_dec_le(v___x_756_, v___x_757_);
if (v___x_758_ == 0)
{
lean_object* v___x_759_; 
lean_dec(v___x_757_);
v___x_759_ = lean_nat_add(v___x_755_, v___x_756_);
lean_dec(v___x_756_);
return v___x_759_;
}
else
{
lean_object* v___x_760_; 
lean_dec(v___x_756_);
v___x_760_ = lean_nat_add(v___x_755_, v___x_757_);
lean_dec(v___x_757_);
return v___x_760_;
}
}
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_height___redArg___boxed(lean_object* v_t_761_){
_start:
{
lean_object* v_res_762_; 
v_res_762_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_height___redArg(v_t_761_);
lean_dec(v_t_761_);
return v_res_762_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_height(lean_object* v_00_u03b1_763_, lean_object* v_t_764_){
_start:
{
lean_object* v___x_765_; 
v___x_765_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_height___redArg(v_t_764_);
return v___x_765_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_height___boxed(lean_object* v_00_u03b1_766_, lean_object* v_t_767_){
_start:
{
lean_object* v_res_768_; 
v_res_768_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_height(v_00_u03b1_766_, v_t_767_);
lean_dec(v_t_767_);
return v_res_768_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_tree__height___closed__0(void){
_start:
{
lean_object* v___x_769_; lean_object* v___x_770_; 
v___x_769_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_example__tree));
v___x_770_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_height___redArg(v___x_769_);
return v___x_770_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_tree__height(void){
_start:
{
lean_object* v___x_771_; 
v___x_771_ = lean_obj_once(&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_tree__height___closed__0, &lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_tree__height___closed__0_once, _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_tree__height___closed__0);
return v___x_771_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_treeMap___redArg(lean_object* v_f_772_, lean_object* v_t_773_){
_start:
{
if (lean_obj_tag(v_t_773_) == 0)
{
lean_object* v___x_774_; 
lean_dec(v_f_772_);
v___x_774_ = lean_box(0);
return v___x_774_;
}
else
{
lean_object* v_value_775_; lean_object* v_left_776_; lean_object* v_right_777_; lean_object* v___x_779_; uint8_t v_isShared_780_; uint8_t v_isSharedCheck_787_; 
v_value_775_ = lean_ctor_get(v_t_773_, 0);
v_left_776_ = lean_ctor_get(v_t_773_, 1);
v_right_777_ = lean_ctor_get(v_t_773_, 2);
v_isSharedCheck_787_ = !lean_is_exclusive(v_t_773_);
if (v_isSharedCheck_787_ == 0)
{
v___x_779_ = v_t_773_;
v_isShared_780_ = v_isSharedCheck_787_;
goto v_resetjp_778_;
}
else
{
lean_inc(v_right_777_);
lean_inc(v_left_776_);
lean_inc(v_value_775_);
lean_dec(v_t_773_);
v___x_779_ = lean_box(0);
v_isShared_780_ = v_isSharedCheck_787_;
goto v_resetjp_778_;
}
v_resetjp_778_:
{
lean_object* v___x_781_; lean_object* v___x_782_; lean_object* v___x_783_; lean_object* v___x_785_; 
lean_inc_n(v_f_772_, 2);
v___x_781_ = lean_apply_1(v_f_772_, v_value_775_);
v___x_782_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_treeMap___redArg(v_f_772_, v_left_776_);
v___x_783_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_treeMap___redArg(v_f_772_, v_right_777_);
if (v_isShared_780_ == 0)
{
lean_ctor_set(v___x_779_, 2, v___x_783_);
lean_ctor_set(v___x_779_, 1, v___x_782_);
lean_ctor_set(v___x_779_, 0, v___x_781_);
v___x_785_ = v___x_779_;
goto v_reusejp_784_;
}
else
{
lean_object* v_reuseFailAlloc_786_; 
v_reuseFailAlloc_786_ = lean_alloc_ctor(1, 3, 0);
lean_ctor_set(v_reuseFailAlloc_786_, 0, v___x_781_);
lean_ctor_set(v_reuseFailAlloc_786_, 1, v___x_782_);
lean_ctor_set(v_reuseFailAlloc_786_, 2, v___x_783_);
v___x_785_ = v_reuseFailAlloc_786_;
goto v_reusejp_784_;
}
v_reusejp_784_:
{
return v___x_785_;
}
}
}
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_treeMap(lean_object* v_00_u03b1_788_, lean_object* v_00_u03b2_789_, lean_object* v_f_790_, lean_object* v_t_791_){
_start:
{
lean_object* v___x_792_; 
v___x_792_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_treeMap___redArg(v_f_790_, v_t_791_);
return v___x_792_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_tree__doubled___lam__0(lean_object* v_x_793_){
_start:
{
lean_object* v___x_794_; lean_object* v___x_795_; 
v___x_794_ = lean_unsigned_to_nat(2u);
v___x_795_ = lean_nat_mul(v_x_793_, v___x_794_);
return v___x_795_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_tree__doubled___lam__0___boxed(lean_object* v_x_796_){
_start:
{
lean_object* v_res_797_; 
v_res_797_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_tree__doubled___lam__0(v_x_796_);
lean_dec(v_x_796_);
return v_res_797_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_tree__doubled___closed__1(void){
_start:
{
lean_object* v___x_799_; lean_object* v___f_800_; lean_object* v___x_801_; 
v___x_799_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_example__tree));
v___f_800_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_tree__doubled___closed__0));
v___x_801_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_treeMap___redArg(v___f_800_, v___x_799_);
return v___x_801_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_tree__doubled(void){
_start:
{
lean_object* v___x_802_; 
v___x_802_ = lean_obj_once(&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_tree__doubled___closed__1, &lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_tree__doubled___closed__1_once, _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_tree__doubled___closed__1);
return v___x_802_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_inorder___redArg(lean_object* v_t_803_){
_start:
{
if (lean_obj_tag(v_t_803_) == 0)
{
lean_object* v___x_804_; 
v___x_804_ = lean_box(0);
return v___x_804_;
}
else
{
lean_object* v_value_805_; lean_object* v_left_806_; lean_object* v_right_807_; lean_object* v___x_808_; lean_object* v___x_809_; lean_object* v___x_810_; lean_object* v___x_811_; lean_object* v___x_812_; lean_object* v___x_813_; 
v_value_805_ = lean_ctor_get(v_t_803_, 0);
v_left_806_ = lean_ctor_get(v_t_803_, 1);
v_right_807_ = lean_ctor_get(v_t_803_, 2);
v___x_808_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_inorder___redArg(v_left_806_);
v___x_809_ = lean_box(0);
lean_inc(v_value_805_);
v___x_810_ = lean_alloc_ctor(1, 2, 0);
lean_ctor_set(v___x_810_, 0, v_value_805_);
lean_ctor_set(v___x_810_, 1, v___x_809_);
v___x_811_ = l_List_appendTR___redArg(v___x_808_, v___x_810_);
v___x_812_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_inorder___redArg(v_right_807_);
v___x_813_ = l_List_appendTR___redArg(v___x_811_, v___x_812_);
return v___x_813_;
}
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_inorder___redArg___boxed(lean_object* v_t_814_){
_start:
{
lean_object* v_res_815_; 
v_res_815_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_inorder___redArg(v_t_814_);
lean_dec(v_t_814_);
return v_res_815_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_inorder(lean_object* v_00_u03b1_816_, lean_object* v_t_817_){
_start:
{
lean_object* v___x_818_; 
v___x_818_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_inorder___redArg(v_t_817_);
return v___x_818_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_inorder___boxed(lean_object* v_00_u03b1_819_, lean_object* v_t_820_){
_start:
{
lean_object* v_res_821_; 
v_res_821_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_inorder(v_00_u03b1_819_, v_t_820_);
lean_dec(v_t_820_);
return v_res_821_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_inorder__example___closed__0(void){
_start:
{
lean_object* v___x_822_; lean_object* v___x_823_; 
v___x_822_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_example__tree));
v___x_823_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_inorder___redArg(v___x_822_);
return v___x_823_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_inorder__example(void){
_start:
{
lean_object* v___x_824_; 
v___x_824_ = lean_obj_once(&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_inorder__example___closed__0, &lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_inorder__example___closed__0_once, _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_inorder__example___closed__0);
return v___x_824_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_AExpr_ctorIdx(lean_object* v_x_825_){
_start:
{
switch(lean_obj_tag(v_x_825_))
{
case 0:
{
lean_object* v___x_826_; 
v___x_826_ = lean_unsigned_to_nat(0u);
return v___x_826_;
}
case 1:
{
lean_object* v___x_827_; 
v___x_827_ = lean_unsigned_to_nat(1u);
return v___x_827_;
}
default: 
{
lean_object* v___x_828_; 
v___x_828_ = lean_unsigned_to_nat(2u);
return v___x_828_;
}
}
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_AExpr_ctorIdx___boxed(lean_object* v_x_829_){
_start:
{
lean_object* v_res_830_; 
v_res_830_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_AExpr_ctorIdx(v_x_829_);
lean_dec_ref(v_x_829_);
return v_res_830_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_AExpr_ctorElim___redArg(lean_object* v_t_831_, lean_object* v_k_832_){
_start:
{
if (lean_obj_tag(v_t_831_) == 0)
{
lean_object* v_n_833_; lean_object* v___x_834_; 
v_n_833_ = lean_ctor_get(v_t_831_, 0);
lean_inc(v_n_833_);
lean_dec_ref_known(v_t_831_, 1);
v___x_834_ = lean_apply_1(v_k_832_, v_n_833_);
return v___x_834_;
}
else
{
lean_object* v_e1_835_; lean_object* v_e2_836_; lean_object* v___x_837_; 
v_e1_835_ = lean_ctor_get(v_t_831_, 0);
lean_inc_ref(v_e1_835_);
v_e2_836_ = lean_ctor_get(v_t_831_, 1);
lean_inc_ref(v_e2_836_);
lean_dec_ref(v_t_831_);
v___x_837_ = lean_apply_2(v_k_832_, v_e1_835_, v_e2_836_);
return v___x_837_;
}
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_AExpr_ctorElim(lean_object* v_motive_838_, lean_object* v_ctorIdx_839_, lean_object* v_t_840_, lean_object* v_h_841_, lean_object* v_k_842_){
_start:
{
lean_object* v___x_843_; 
v___x_843_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_AExpr_ctorElim___redArg(v_t_840_, v_k_842_);
return v___x_843_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_AExpr_ctorElim___boxed(lean_object* v_motive_844_, lean_object* v_ctorIdx_845_, lean_object* v_t_846_, lean_object* v_h_847_, lean_object* v_k_848_){
_start:
{
lean_object* v_res_849_; 
v_res_849_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_AExpr_ctorElim(v_motive_844_, v_ctorIdx_845_, v_t_846_, v_h_847_, v_k_848_);
lean_dec(v_ctorIdx_845_);
return v_res_849_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_AExpr_num_elim___redArg(lean_object* v_t_850_, lean_object* v_num_851_){
_start:
{
lean_object* v___x_852_; 
v___x_852_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_AExpr_ctorElim___redArg(v_t_850_, v_num_851_);
return v___x_852_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_AExpr_num_elim(lean_object* v_motive_853_, lean_object* v_t_854_, lean_object* v_h_855_, lean_object* v_num_856_){
_start:
{
lean_object* v___x_857_; 
v___x_857_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_AExpr_ctorElim___redArg(v_t_854_, v_num_856_);
return v___x_857_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_AExpr_add_elim___redArg(lean_object* v_t_858_, lean_object* v_add_859_){
_start:
{
lean_object* v___x_860_; 
v___x_860_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_AExpr_ctorElim___redArg(v_t_858_, v_add_859_);
return v___x_860_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_AExpr_add_elim(lean_object* v_motive_861_, lean_object* v_t_862_, lean_object* v_h_863_, lean_object* v_add_864_){
_start:
{
lean_object* v___x_865_; 
v___x_865_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_AExpr_ctorElim___redArg(v_t_862_, v_add_864_);
return v___x_865_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_AExpr_mul_elim___redArg(lean_object* v_t_866_, lean_object* v_mul_867_){
_start:
{
lean_object* v___x_868_; 
v___x_868_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_AExpr_ctorElim___redArg(v_t_866_, v_mul_867_);
return v___x_868_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_AExpr_mul_elim(lean_object* v_motive_869_, lean_object* v_t_870_, lean_object* v_h_871_, lean_object* v_mul_872_){
_start:
{
lean_object* v___x_873_; 
v___x_873_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_AExpr_ctorElim___redArg(v_t_870_, v_mul_872_);
return v___x_873_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_instReprAExpr_repr(lean_object* v_x_892_, lean_object* v_prec_893_){
_start:
{
switch(lean_obj_tag(v_x_892_))
{
case 0:
{
lean_object* v_n_894_; lean_object* v___x_896_; uint8_t v_isShared_897_; uint8_t v_isSharedCheck_914_; 
v_n_894_ = lean_ctor_get(v_x_892_, 0);
v_isSharedCheck_914_ = !lean_is_exclusive(v_x_892_);
if (v_isSharedCheck_914_ == 0)
{
v___x_896_ = v_x_892_;
v_isShared_897_ = v_isSharedCheck_914_;
goto v_resetjp_895_;
}
else
{
lean_inc(v_n_894_);
lean_dec(v_x_892_);
v___x_896_ = lean_box(0);
v_isShared_897_ = v_isSharedCheck_914_;
goto v_resetjp_895_;
}
v_resetjp_895_:
{
lean_object* v___y_899_; lean_object* v___x_910_; uint8_t v___x_911_; 
v___x_910_ = lean_unsigned_to_nat(1024u);
v___x_911_ = lean_nat_dec_le(v___x_910_, v_prec_893_);
if (v___x_911_ == 0)
{
lean_object* v___x_912_; 
v___x_912_ = lean_obj_once(&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_instReprMyNat_repr___closed__2, &lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_instReprMyNat_repr___closed__2_once, _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_instReprMyNat_repr___closed__2);
v___y_899_ = v___x_912_;
goto v___jp_898_;
}
else
{
lean_object* v___x_913_; 
v___x_913_ = lean_obj_once(&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_instReprMyNat_repr___closed__3, &lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_instReprMyNat_repr___closed__3_once, _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_instReprMyNat_repr___closed__3);
v___y_899_ = v___x_913_;
goto v___jp_898_;
}
v___jp_898_:
{
lean_object* v___x_900_; lean_object* v___x_901_; lean_object* v___x_903_; 
v___x_900_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_instReprAExpr_repr___closed__2));
v___x_901_ = l_Nat_reprFast(v_n_894_);
if (v_isShared_897_ == 0)
{
lean_ctor_set_tag(v___x_896_, 3);
lean_ctor_set(v___x_896_, 0, v___x_901_);
v___x_903_ = v___x_896_;
goto v_reusejp_902_;
}
else
{
lean_object* v_reuseFailAlloc_909_; 
v_reuseFailAlloc_909_ = lean_alloc_ctor(3, 1, 0);
lean_ctor_set(v_reuseFailAlloc_909_, 0, v___x_901_);
v___x_903_ = v_reuseFailAlloc_909_;
goto v_reusejp_902_;
}
v_reusejp_902_:
{
lean_object* v___x_904_; lean_object* v___x_905_; uint8_t v___x_906_; lean_object* v___x_907_; lean_object* v___x_908_; 
v___x_904_ = lean_alloc_ctor(5, 2, 0);
lean_ctor_set(v___x_904_, 0, v___x_900_);
lean_ctor_set(v___x_904_, 1, v___x_903_);
lean_inc(v___y_899_);
v___x_905_ = lean_alloc_ctor(4, 2, 0);
lean_ctor_set(v___x_905_, 0, v___y_899_);
lean_ctor_set(v___x_905_, 1, v___x_904_);
v___x_906_ = 0;
v___x_907_ = lean_alloc_ctor(6, 1, 1);
lean_ctor_set(v___x_907_, 0, v___x_905_);
lean_ctor_set_uint8(v___x_907_, sizeof(void*)*1, v___x_906_);
v___x_908_ = l_Repr_addAppParen(v___x_907_, v_prec_893_);
return v___x_908_;
}
}
}
}
case 1:
{
lean_object* v_e1_915_; lean_object* v_e2_916_; lean_object* v___x_918_; uint8_t v_isShared_919_; uint8_t v_isSharedCheck_939_; 
v_e1_915_ = lean_ctor_get(v_x_892_, 0);
v_e2_916_ = lean_ctor_get(v_x_892_, 1);
v_isSharedCheck_939_ = !lean_is_exclusive(v_x_892_);
if (v_isSharedCheck_939_ == 0)
{
v___x_918_ = v_x_892_;
v_isShared_919_ = v_isSharedCheck_939_;
goto v_resetjp_917_;
}
else
{
lean_inc(v_e2_916_);
lean_inc(v_e1_915_);
lean_dec(v_x_892_);
v___x_918_ = lean_box(0);
v_isShared_919_ = v_isSharedCheck_939_;
goto v_resetjp_917_;
}
v_resetjp_917_:
{
lean_object* v___x_920_; lean_object* v___y_922_; uint8_t v___x_936_; 
v___x_920_ = lean_unsigned_to_nat(1024u);
v___x_936_ = lean_nat_dec_le(v___x_920_, v_prec_893_);
if (v___x_936_ == 0)
{
lean_object* v___x_937_; 
v___x_937_ = lean_obj_once(&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_instReprMyNat_repr___closed__2, &lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_instReprMyNat_repr___closed__2_once, _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_instReprMyNat_repr___closed__2);
v___y_922_ = v___x_937_;
goto v___jp_921_;
}
else
{
lean_object* v___x_938_; 
v___x_938_ = lean_obj_once(&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_instReprMyNat_repr___closed__3, &lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_instReprMyNat_repr___closed__3_once, _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_instReprMyNat_repr___closed__3);
v___y_922_ = v___x_938_;
goto v___jp_921_;
}
v___jp_921_:
{
lean_object* v___x_923_; lean_object* v___x_924_; lean_object* v___x_925_; lean_object* v___x_927_; 
v___x_923_ = lean_box(1);
v___x_924_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_instReprAExpr_repr___closed__5));
v___x_925_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_instReprAExpr_repr(v_e1_915_, v___x_920_);
if (v_isShared_919_ == 0)
{
lean_ctor_set_tag(v___x_918_, 5);
lean_ctor_set(v___x_918_, 1, v___x_925_);
lean_ctor_set(v___x_918_, 0, v___x_924_);
v___x_927_ = v___x_918_;
goto v_reusejp_926_;
}
else
{
lean_object* v_reuseFailAlloc_935_; 
v_reuseFailAlloc_935_ = lean_alloc_ctor(5, 2, 0);
lean_ctor_set(v_reuseFailAlloc_935_, 0, v___x_924_);
lean_ctor_set(v_reuseFailAlloc_935_, 1, v___x_925_);
v___x_927_ = v_reuseFailAlloc_935_;
goto v_reusejp_926_;
}
v_reusejp_926_:
{
lean_object* v___x_928_; lean_object* v___x_929_; lean_object* v___x_930_; lean_object* v___x_931_; uint8_t v___x_932_; lean_object* v___x_933_; lean_object* v___x_934_; 
v___x_928_ = lean_alloc_ctor(5, 2, 0);
lean_ctor_set(v___x_928_, 0, v___x_927_);
lean_ctor_set(v___x_928_, 1, v___x_923_);
v___x_929_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_instReprAExpr_repr(v_e2_916_, v___x_920_);
v___x_930_ = lean_alloc_ctor(5, 2, 0);
lean_ctor_set(v___x_930_, 0, v___x_928_);
lean_ctor_set(v___x_930_, 1, v___x_929_);
lean_inc(v___y_922_);
v___x_931_ = lean_alloc_ctor(4, 2, 0);
lean_ctor_set(v___x_931_, 0, v___y_922_);
lean_ctor_set(v___x_931_, 1, v___x_930_);
v___x_932_ = 0;
v___x_933_ = lean_alloc_ctor(6, 1, 1);
lean_ctor_set(v___x_933_, 0, v___x_931_);
lean_ctor_set_uint8(v___x_933_, sizeof(void*)*1, v___x_932_);
v___x_934_ = l_Repr_addAppParen(v___x_933_, v_prec_893_);
return v___x_934_;
}
}
}
}
default: 
{
lean_object* v_e1_940_; lean_object* v_e2_941_; lean_object* v___x_943_; uint8_t v_isShared_944_; uint8_t v_isSharedCheck_964_; 
v_e1_940_ = lean_ctor_get(v_x_892_, 0);
v_e2_941_ = lean_ctor_get(v_x_892_, 1);
v_isSharedCheck_964_ = !lean_is_exclusive(v_x_892_);
if (v_isSharedCheck_964_ == 0)
{
v___x_943_ = v_x_892_;
v_isShared_944_ = v_isSharedCheck_964_;
goto v_resetjp_942_;
}
else
{
lean_inc(v_e2_941_);
lean_inc(v_e1_940_);
lean_dec(v_x_892_);
v___x_943_ = lean_box(0);
v_isShared_944_ = v_isSharedCheck_964_;
goto v_resetjp_942_;
}
v_resetjp_942_:
{
lean_object* v___x_945_; lean_object* v___y_947_; uint8_t v___x_961_; 
v___x_945_ = lean_unsigned_to_nat(1024u);
v___x_961_ = lean_nat_dec_le(v___x_945_, v_prec_893_);
if (v___x_961_ == 0)
{
lean_object* v___x_962_; 
v___x_962_ = lean_obj_once(&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_instReprMyNat_repr___closed__2, &lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_instReprMyNat_repr___closed__2_once, _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_instReprMyNat_repr___closed__2);
v___y_947_ = v___x_962_;
goto v___jp_946_;
}
else
{
lean_object* v___x_963_; 
v___x_963_ = lean_obj_once(&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_instReprMyNat_repr___closed__3, &lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_instReprMyNat_repr___closed__3_once, _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_instReprMyNat_repr___closed__3);
v___y_947_ = v___x_963_;
goto v___jp_946_;
}
v___jp_946_:
{
lean_object* v___x_948_; lean_object* v___x_949_; lean_object* v___x_950_; lean_object* v___x_952_; 
v___x_948_ = lean_box(1);
v___x_949_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_instReprAExpr_repr___closed__8));
v___x_950_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_instReprAExpr_repr(v_e1_940_, v___x_945_);
if (v_isShared_944_ == 0)
{
lean_ctor_set_tag(v___x_943_, 5);
lean_ctor_set(v___x_943_, 1, v___x_950_);
lean_ctor_set(v___x_943_, 0, v___x_949_);
v___x_952_ = v___x_943_;
goto v_reusejp_951_;
}
else
{
lean_object* v_reuseFailAlloc_960_; 
v_reuseFailAlloc_960_ = lean_alloc_ctor(5, 2, 0);
lean_ctor_set(v_reuseFailAlloc_960_, 0, v___x_949_);
lean_ctor_set(v_reuseFailAlloc_960_, 1, v___x_950_);
v___x_952_ = v_reuseFailAlloc_960_;
goto v_reusejp_951_;
}
v_reusejp_951_:
{
lean_object* v___x_953_; lean_object* v___x_954_; lean_object* v___x_955_; lean_object* v___x_956_; uint8_t v___x_957_; lean_object* v___x_958_; lean_object* v___x_959_; 
v___x_953_ = lean_alloc_ctor(5, 2, 0);
lean_ctor_set(v___x_953_, 0, v___x_952_);
lean_ctor_set(v___x_953_, 1, v___x_948_);
v___x_954_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_instReprAExpr_repr(v_e2_941_, v___x_945_);
v___x_955_ = lean_alloc_ctor(5, 2, 0);
lean_ctor_set(v___x_955_, 0, v___x_953_);
lean_ctor_set(v___x_955_, 1, v___x_954_);
lean_inc(v___y_947_);
v___x_956_ = lean_alloc_ctor(4, 2, 0);
lean_ctor_set(v___x_956_, 0, v___y_947_);
lean_ctor_set(v___x_956_, 1, v___x_955_);
v___x_957_ = 0;
v___x_958_ = lean_alloc_ctor(6, 1, 1);
lean_ctor_set(v___x_958_, 0, v___x_956_);
lean_ctor_set_uint8(v___x_958_, sizeof(void*)*1, v___x_957_);
v___x_959_ = l_Repr_addAppParen(v___x_958_, v_prec_893_);
return v___x_959_;
}
}
}
}
}
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_instReprAExpr_repr___boxed(lean_object* v_x_965_, lean_object* v_prec_966_){
_start:
{
lean_object* v_res_967_; 
v_res_967_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_instReprAExpr_repr(v_x_965_, v_prec_966_);
lean_dec(v_prec_966_);
return v_res_967_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_eval(lean_object* v_e_983_){
_start:
{
switch(lean_obj_tag(v_e_983_))
{
case 0:
{
lean_object* v_n_984_; 
v_n_984_ = lean_ctor_get(v_e_983_, 0);
lean_inc(v_n_984_);
return v_n_984_;
}
case 1:
{
lean_object* v_e1_985_; lean_object* v_e2_986_; lean_object* v___x_987_; lean_object* v___x_988_; lean_object* v___x_989_; 
v_e1_985_ = lean_ctor_get(v_e_983_, 0);
v_e2_986_ = lean_ctor_get(v_e_983_, 1);
v___x_987_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_eval(v_e1_985_);
v___x_988_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_eval(v_e2_986_);
v___x_989_ = lean_nat_add(v___x_987_, v___x_988_);
lean_dec(v___x_988_);
lean_dec(v___x_987_);
return v___x_989_;
}
default: 
{
lean_object* v_e1_990_; lean_object* v_e2_991_; lean_object* v___x_992_; lean_object* v___x_993_; lean_object* v___x_994_; 
v_e1_990_ = lean_ctor_get(v_e_983_, 0);
v_e2_991_ = lean_ctor_get(v_e_983_, 1);
v___x_992_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_eval(v_e1_990_);
v___x_993_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_eval(v_e2_991_);
v___x_994_ = lean_nat_mul(v___x_992_, v___x_993_);
lean_dec(v___x_993_);
lean_dec(v___x_992_);
return v___x_994_;
}
}
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_eval___boxed(lean_object* v_e_995_){
_start:
{
lean_object* v_res_996_; 
v_res_996_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_eval(v_e_995_);
lean_dec_ref(v_e_995_);
return v_res_996_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_eval1___closed__0(void){
_start:
{
lean_object* v___x_997_; lean_object* v___x_998_; 
v___x_997_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_expr1));
v___x_998_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_eval(v___x_997_);
return v___x_998_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_eval1(void){
_start:
{
lean_object* v___x_999_; 
v___x_999_ = lean_obj_once(&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_eval1___closed__0, &lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_eval1___closed__0_once, _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_eval1___closed__0);
return v___x_999_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_exprSize(lean_object* v_e_1000_){
_start:
{
lean_object* v_e1_1002_; lean_object* v_e2_1003_; 
if (lean_obj_tag(v_e_1000_) == 0)
{
lean_object* v___x_1009_; 
v___x_1009_ = lean_unsigned_to_nat(1u);
return v___x_1009_;
}
else
{
lean_object* v_e1_1010_; lean_object* v_e2_1011_; 
v_e1_1010_ = lean_ctor_get(v_e_1000_, 0);
v_e2_1011_ = lean_ctor_get(v_e_1000_, 1);
v_e1_1002_ = v_e1_1010_;
v_e2_1003_ = v_e2_1011_;
goto v___jp_1001_;
}
v___jp_1001_:
{
lean_object* v___x_1004_; lean_object* v___x_1005_; lean_object* v___x_1006_; lean_object* v___x_1007_; lean_object* v___x_1008_; 
v___x_1004_ = lean_unsigned_to_nat(1u);
v___x_1005_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_exprSize(v_e1_1002_);
v___x_1006_ = lean_nat_add(v___x_1004_, v___x_1005_);
lean_dec(v___x_1005_);
v___x_1007_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_exprSize(v_e2_1003_);
v___x_1008_ = lean_nat_add(v___x_1006_, v___x_1007_);
lean_dec(v___x_1007_);
lean_dec(v___x_1006_);
return v___x_1008_;
}
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_exprSize___boxed(lean_object* v_e_1012_){
_start:
{
lean_object* v_res_1013_; 
v_res_1013_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_exprSize(v_e_1012_);
lean_dec_ref(v_e_1012_);
return v_res_1013_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_size1___closed__0(void){
_start:
{
lean_object* v___x_1014_; lean_object* v___x_1015_; 
v___x_1014_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_expr1));
v___x_1015_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_exprSize(v___x_1014_);
return v___x_1015_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_size1(void){
_start:
{
lean_object* v___x_1016_; 
v___x_1016_ = lean_obj_once(&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_size1___closed__0, &lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_size1___closed__0_once, _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_size1___closed__0);
return v___x_1016_;
}
}
lean_object* initialize_Init(uint8_t builtin);
lean_object* initialize_Init(uint8_t builtin);
static bool _G_initialized = false;
LEAN_EXPORT lean_object* initialize_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes(uint8_t builtin) {
lean_object * res;
if (_G_initialized) return lean_io_result_mk_ok(lean_box(0));
_G_initialized = true;
res = initialize_Init(builtin);
if (lean_io_result_is_error(res)) return res;
lean_dec_ref(res);
res = initialize_Init(builtin);
if (lean_io_result_is_error(res)) return res;
lean_dec_ref(res);
lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_my__zero = _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_my__zero();
lean_mark_persistent(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_my__zero);
lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_two__plus__three = _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_two__plus__three();
lean_mark_persistent(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_two__plus__three);
lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_two__times__three = _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_two__times__three();
lean_mark_persistent(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_two__times__three);
lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_three__to__nat = _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_three__to__nat();
lean_mark_persistent(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_three__to__nat);
lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_five__of__nat = _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_five__of__nat();
lean_mark_persistent(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_five__of__nat);
lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_leq__example1 = _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_leq__example1();
lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_leq__example2 = _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_leq__example2();
lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_eq__example = _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_eq__example();
lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_empty__list = _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_empty__list();
lean_mark_persistent(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_empty__list);
lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_len1 = _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_len1();
lean_mark_persistent(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_len1);
lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_len2 = _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_len2();
lean_mark_persistent(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_len2);
lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_appended = _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_appended();
lean_mark_persistent(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_appended);
lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_doubled = _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_doubled();
lean_mark_persistent(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_doubled);
lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_evens = _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_evens();
lean_mark_persistent(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_evens);
lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_sum__list = _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_sum__list();
lean_mark_persistent(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_sum__list);
lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_product__list = _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_product__list();
lean_mark_persistent(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_product__list);
lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_std__empty = _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_std__empty();
lean_mark_persistent(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_std__empty);
lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_std__length = _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_std__length();
lean_mark_persistent(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_std__length);
lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_std__head_x3f = _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_std__head_x3f();
lean_mark_persistent(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_std__head_x3f);
lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_std__tail = _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_std__tail();
lean_mark_persistent(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_std__tail);
lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_std__append = _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_std__append();
lean_mark_persistent(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_std__append);
lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_std__map = _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_std__map();
lean_mark_persistent(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_std__map);
lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_std__filter = _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_std__filter();
lean_mark_persistent(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_std__filter);
lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_std__sum = _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_std__sum();
lean_mark_persistent(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_std__sum);
lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_std__foldr = _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_std__foldr();
lean_mark_persistent(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_std__foldr);
lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_tree__size = _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_tree__size();
lean_mark_persistent(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_tree__size);
lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_tree__height = _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_tree__height();
lean_mark_persistent(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_tree__height);
lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_tree__doubled = _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_tree__doubled();
lean_mark_persistent(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_tree__doubled);
lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_inorder__example = _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_inorder__example();
lean_mark_persistent(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_inorder__example);
lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_eval1 = _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_eval1();
lean_mark_persistent(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_eval1);
lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_size1 = _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_size1();
lean_mark_persistent(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_RecursiveTypes_size1);
return lean_io_result_mk_ok(lean_box(0));
}
#ifdef __cplusplus
}
#endif
