// Lean compiler output
// Module: Lean4Tutorial.Examples.Typeclasses.TypeclassBasics
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
lean_object* lean_string_append(lean_object*, lean_object*);
lean_object* l_Nat_reprFast(lean_object*);
lean_object* lean_string_length(lean_object*);
uint8_t lean_nat_dec_le(lean_object*, lean_object*);
lean_object* lean_string_data(lean_object*);
lean_object* lean_mk_empty_array_with_capacity(lean_object*);
lean_object* l___private_Init_Data_List_Impl_0__List_takeTR_go___redArg(lean_object*, lean_object*, lean_object*, lean_object*);
lean_object* lean_string_mk(lean_object*);
uint8_t lean_nat_dec_lt(lean_object*, lean_object*);
lean_object* lean_nat_to_int(lean_object*);
lean_object* l_String_quote(lean_object*);
lean_object* lean_string_length(lean_object*);
lean_object* lean_string_push(lean_object*, uint32_t);
lean_object* lean_string_utf8_byte_size(lean_object*);
lean_object* l_String_Slice_toNat_x3f(lean_object*);
uint8_t lean_string_compare(lean_object*, lean_object*);
static const lean_closure_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_instPrintableNat___closed__0_value = {.m_header = {.m_rc = 0, .m_cs_sz = sizeof(lean_closure_object) + sizeof(void*)*0, .m_other = 0, .m_tag = 245}, .m_fun = (void*)l_Nat_reprFast, .m_arity = 1, .m_num_fixed = 0, .m_objs = {} };
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_instPrintableNat___closed__0 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_instPrintableNat___closed__0_value;
LEAN_EXPORT const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_instPrintableNat = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_instPrintableNat___closed__0_value;
static const lean_string_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_instPrintableBool___lam__0___closed__0_value = {.m_header = {.m_rc = 0, .m_cs_sz = 0, .m_other = 0, .m_tag = 249}, .m_size = 6, .m_capacity = 6, .m_length = 5, .m_data = "false"};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_instPrintableBool___lam__0___closed__0 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_instPrintableBool___lam__0___closed__0_value;
static const lean_string_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_instPrintableBool___lam__0___closed__1_value = {.m_header = {.m_rc = 0, .m_cs_sz = 0, .m_other = 0, .m_tag = 249}, .m_size = 5, .m_capacity = 5, .m_length = 4, .m_data = "true"};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_instPrintableBool___lam__0___closed__1 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_instPrintableBool___lam__0___closed__1_value;
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_instPrintableBool___lam__0(uint8_t);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_instPrintableBool___lam__0___boxed(lean_object*);
static const lean_closure_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_instPrintableBool___closed__0_value = {.m_header = {.m_rc = 0, .m_cs_sz = sizeof(lean_closure_object) + sizeof(void*)*0, .m_other = 0, .m_tag = 245}, .m_fun = (void*)lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_instPrintableBool___lam__0___boxed, .m_arity = 1, .m_num_fixed = 0, .m_objs = {} };
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_instPrintableBool___closed__0 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_instPrintableBool___closed__0_value;
LEAN_EXPORT const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_instPrintableBool = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_instPrintableBool___closed__0_value;
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_instPrintableString___lam__0(lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_instPrintableString___lam__0___boxed(lean_object*);
static const lean_closure_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_instPrintableString___closed__0_value = {.m_header = {.m_rc = 0, .m_cs_sz = sizeof(lean_closure_object) + sizeof(void*)*0, .m_other = 0, .m_tag = 245}, .m_fun = (void*)lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_instPrintableString___lam__0___boxed, .m_arity = 1, .m_num_fixed = 0, .m_objs = {} };
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_instPrintableString___closed__0 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_instPrintableString___closed__0_value;
LEAN_EXPORT const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_instPrintableString = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_instPrintableString___closed__0_value;
static const lean_string_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_instPrintableChar___lam__0___closed__0_value = {.m_header = {.m_rc = 0, .m_cs_sz = 0, .m_other = 0, .m_tag = 249}, .m_size = 1, .m_capacity = 1, .m_length = 0, .m_data = ""};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_instPrintableChar___lam__0___closed__0 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_instPrintableChar___lam__0___closed__0_value;
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_instPrintableChar___lam__0(uint32_t);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_instPrintableChar___lam__0___boxed(lean_object*);
static const lean_closure_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_instPrintableChar___closed__0_value = {.m_header = {.m_rc = 0, .m_cs_sz = sizeof(lean_closure_object) + sizeof(void*)*0, .m_other = 0, .m_tag = 245}, .m_fun = (void*)lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_instPrintableChar___lam__0___boxed, .m_arity = 1, .m_num_fixed = 0, .m_objs = {} };
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_instPrintableChar___closed__0 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_instPrintableChar___closed__0_value;
LEAN_EXPORT const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_instPrintableChar = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_instPrintableChar___closed__0_value;
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_printIt___redArg(lean_object*, lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_printIt(lean_object*, lean_object*, lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_printIt___at___00Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_print__nat_spec__0(lean_object*);
static const lean_string_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_print__nat___closed__0_value = {.m_header = {.m_rc = 0, .m_cs_sz = 0, .m_other = 0, .m_tag = 249}, .m_size = 3, .m_capacity = 3, .m_length = 2, .m_data = "42"};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_print__nat___closed__0 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_print__nat___closed__0_value;
LEAN_EXPORT const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_print__nat = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_print__nat___closed__0_value;
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_printIt___at___00Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_print__bool_spec__0(uint8_t);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_printIt___at___00Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_print__bool_spec__0___boxed(lean_object*);
static lean_once_cell_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_print__bool___closed__0_once = LEAN_ONCE_CELL_INITIALIZER;
static lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_print__bool___closed__0;
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_print__bool;
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_printIt___at___00Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_print__string_spec__0(lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_printIt___at___00Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_print__string_spec__0___boxed(lean_object*);
static const lean_string_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_print__string___closed__0_value = {.m_header = {.m_rc = 0, .m_cs_sz = 0, .m_other = 0, .m_tag = 249}, .m_size = 6, .m_capacity = 6, .m_length = 5, .m_data = "hello"};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_print__string___closed__0 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_print__string___closed__0_value;
LEAN_EXPORT const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_print__string = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_print__string___closed__0_value;
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_printIt___at___00Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_print__char_spec__0(uint32_t);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_printIt___at___00Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_print__char_spec__0___boxed(lean_object*);
static lean_once_cell_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_print__char___closed__0_once = LEAN_ONCE_CELL_INITIALIZER;
static lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_print__char___closed__0;
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_print__char;
static const lean_string_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_printPair___redArg___closed__0_value = {.m_header = {.m_rc = 0, .m_cs_sz = 0, .m_other = 0, .m_tag = 249}, .m_size = 2, .m_capacity = 2, .m_length = 1, .m_data = "("};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_printPair___redArg___closed__0 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_printPair___redArg___closed__0_value;
static const lean_string_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_printPair___redArg___closed__1_value = {.m_header = {.m_rc = 0, .m_cs_sz = 0, .m_other = 0, .m_tag = 249}, .m_size = 3, .m_capacity = 3, .m_length = 2, .m_data = ", "};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_printPair___redArg___closed__1 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_printPair___redArg___closed__1_value;
static const lean_string_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_printPair___redArg___closed__2_value = {.m_header = {.m_rc = 0, .m_cs_sz = 0, .m_other = 0, .m_tag = 249}, .m_size = 2, .m_capacity = 2, .m_length = 1, .m_data = ")"};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_printPair___redArg___closed__2 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_printPair___redArg___closed__2_value;
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_printPair___redArg(lean_object*, lean_object*, lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_printPair(lean_object*, lean_object*, lean_object*, lean_object*, lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_printPair___at___00Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_print__pair_spec__0(lean_object*);
static const lean_ctor_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_print__pair___closed__0_value = {.m_header = {.m_rc = 0, .m_cs_sz = sizeof(lean_ctor_object) + sizeof(void*)*2 + 0, .m_other = 2, .m_tag = 0}, .m_objs = {((lean_object*)(((size_t)(42) << 1) | 1)),((lean_object*)(((size_t)(1) << 1) | 1))}};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_print__pair___closed__0 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_print__pair___closed__0_value;
static lean_once_cell_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_print__pair___closed__1_once = LEAN_ONCE_CELL_INITIALIZER;
static lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_print__pair___closed__1;
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_print__pair;
LEAN_EXPORT const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_instConvertibleNatString = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_instPrintableNat___closed__0_value;
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_instConvertibleBoolNat___lam__0(uint8_t);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_instConvertibleBoolNat___lam__0___boxed(lean_object*);
static const lean_closure_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_instConvertibleBoolNat___closed__0_value = {.m_header = {.m_rc = 0, .m_cs_sz = sizeof(lean_closure_object) + sizeof(void*)*0, .m_other = 0, .m_tag = 245}, .m_fun = (void*)lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_instConvertibleBoolNat___lam__0___boxed, .m_arity = 1, .m_num_fixed = 0, .m_objs = {} };
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_instConvertibleBoolNat___closed__0 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_instConvertibleBoolNat___closed__0_value;
LEAN_EXPORT const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_instConvertibleBoolNat = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_instConvertibleBoolNat___closed__0_value;
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_convertExample___redArg(lean_object*, lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_convertExample(lean_object*, lean_object*, lean_object*, lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_convertExample___at___00Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_nat__to__string_spec__0(lean_object*);
LEAN_EXPORT const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_nat__to__string = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_print__nat___closed__0_value;
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_convertExample___at___00Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_bool__to__nat_spec__0(uint8_t);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_convertExample___at___00Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_bool__to__nat_spec__0___boxed(lean_object*);
static lean_once_cell_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_bool__to__nat___closed__0_once = LEAN_ONCE_CELL_INITIALIZER;
static lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_bool__to__nat___closed__0;
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_bool__to__nat;
static const lean_array_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_takeN___closed__0_value = {.m_header = {.m_rc = 0, .m_cs_sz = sizeof(lean_array_object) + sizeof(void*)*0, .m_other = 0, .m_tag = 246}, .m_size = 0, .m_capacity = 0, .m_data = {}};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_takeN___closed__0 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_takeN___closed__0_value;
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_takeN(lean_object*, lean_object*);
static const lean_string_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_instReprPerson_repr___redArg___closed__0_value = {.m_header = {.m_rc = 0, .m_cs_sz = 0, .m_other = 0, .m_tag = 249}, .m_size = 3, .m_capacity = 3, .m_length = 2, .m_data = "{ "};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_instReprPerson_repr___redArg___closed__0 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_instReprPerson_repr___redArg___closed__0_value;
static const lean_string_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_instReprPerson_repr___redArg___closed__1_value = {.m_header = {.m_rc = 0, .m_cs_sz = 0, .m_other = 0, .m_tag = 249}, .m_size = 11, .m_capacity = 11, .m_length = 10, .m_data = "personName"};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_instReprPerson_repr___redArg___closed__1 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_instReprPerson_repr___redArg___closed__1_value;
static const lean_ctor_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_instReprPerson_repr___redArg___closed__2_value = {.m_header = {.m_rc = 0, .m_cs_sz = sizeof(lean_ctor_object) + sizeof(void*)*1 + 0, .m_other = 1, .m_tag = 3}, .m_objs = {((lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_instReprPerson_repr___redArg___closed__1_value)}};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_instReprPerson_repr___redArg___closed__2 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_instReprPerson_repr___redArg___closed__2_value;
static const lean_ctor_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_instReprPerson_repr___redArg___closed__3_value = {.m_header = {.m_rc = 0, .m_cs_sz = sizeof(lean_ctor_object) + sizeof(void*)*2 + 0, .m_other = 2, .m_tag = 5}, .m_objs = {((lean_object*)(((size_t)(0) << 1) | 1)),((lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_instReprPerson_repr___redArg___closed__2_value)}};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_instReprPerson_repr___redArg___closed__3 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_instReprPerson_repr___redArg___closed__3_value;
static const lean_string_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_instReprPerson_repr___redArg___closed__4_value = {.m_header = {.m_rc = 0, .m_cs_sz = 0, .m_other = 0, .m_tag = 249}, .m_size = 5, .m_capacity = 5, .m_length = 4, .m_data = " := "};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_instReprPerson_repr___redArg___closed__4 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_instReprPerson_repr___redArg___closed__4_value;
static const lean_ctor_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_instReprPerson_repr___redArg___closed__5_value = {.m_header = {.m_rc = 0, .m_cs_sz = sizeof(lean_ctor_object) + sizeof(void*)*1 + 0, .m_other = 1, .m_tag = 3}, .m_objs = {((lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_instReprPerson_repr___redArg___closed__4_value)}};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_instReprPerson_repr___redArg___closed__5 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_instReprPerson_repr___redArg___closed__5_value;
static const lean_ctor_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_instReprPerson_repr___redArg___closed__6_value = {.m_header = {.m_rc = 0, .m_cs_sz = sizeof(lean_ctor_object) + sizeof(void*)*2 + 0, .m_other = 2, .m_tag = 5}, .m_objs = {((lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_instReprPerson_repr___redArg___closed__3_value),((lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_instReprPerson_repr___redArg___closed__5_value)}};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_instReprPerson_repr___redArg___closed__6 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_instReprPerson_repr___redArg___closed__6_value;
static lean_once_cell_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_instReprPerson_repr___redArg___closed__7_once = LEAN_ONCE_CELL_INITIALIZER;
static lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_instReprPerson_repr___redArg___closed__7;
static const lean_string_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_instReprPerson_repr___redArg___closed__8_value = {.m_header = {.m_rc = 0, .m_cs_sz = 0, .m_other = 0, .m_tag = 249}, .m_size = 2, .m_capacity = 2, .m_length = 1, .m_data = ","};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_instReprPerson_repr___redArg___closed__8 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_instReprPerson_repr___redArg___closed__8_value;
static const lean_ctor_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_instReprPerson_repr___redArg___closed__9_value = {.m_header = {.m_rc = 0, .m_cs_sz = sizeof(lean_ctor_object) + sizeof(void*)*1 + 0, .m_other = 1, .m_tag = 3}, .m_objs = {((lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_instReprPerson_repr___redArg___closed__8_value)}};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_instReprPerson_repr___redArg___closed__9 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_instReprPerson_repr___redArg___closed__9_value;
static const lean_string_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_instReprPerson_repr___redArg___closed__10_value = {.m_header = {.m_rc = 0, .m_cs_sz = 0, .m_other = 0, .m_tag = 249}, .m_size = 4, .m_capacity = 4, .m_length = 3, .m_data = "age"};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_instReprPerson_repr___redArg___closed__10 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_instReprPerson_repr___redArg___closed__10_value;
static const lean_ctor_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_instReprPerson_repr___redArg___closed__11_value = {.m_header = {.m_rc = 0, .m_cs_sz = sizeof(lean_ctor_object) + sizeof(void*)*1 + 0, .m_other = 1, .m_tag = 3}, .m_objs = {((lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_instReprPerson_repr___redArg___closed__10_value)}};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_instReprPerson_repr___redArg___closed__11 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_instReprPerson_repr___redArg___closed__11_value;
static lean_once_cell_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_instReprPerson_repr___redArg___closed__12_once = LEAN_ONCE_CELL_INITIALIZER;
static lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_instReprPerson_repr___redArg___closed__12;
static const lean_string_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_instReprPerson_repr___redArg___closed__13_value = {.m_header = {.m_rc = 0, .m_cs_sz = 0, .m_other = 0, .m_tag = 249}, .m_size = 3, .m_capacity = 3, .m_length = 2, .m_data = " }"};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_instReprPerson_repr___redArg___closed__13 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_instReprPerson_repr___redArg___closed__13_value;
static lean_once_cell_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_instReprPerson_repr___redArg___closed__14_once = LEAN_ONCE_CELL_INITIALIZER;
static lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_instReprPerson_repr___redArg___closed__14;
static lean_once_cell_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_instReprPerson_repr___redArg___closed__15_once = LEAN_ONCE_CELL_INITIALIZER;
static lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_instReprPerson_repr___redArg___closed__15;
static const lean_ctor_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_instReprPerson_repr___redArg___closed__16_value = {.m_header = {.m_rc = 0, .m_cs_sz = sizeof(lean_ctor_object) + sizeof(void*)*1 + 0, .m_other = 1, .m_tag = 3}, .m_objs = {((lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_instReprPerson_repr___redArg___closed__0_value)}};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_instReprPerson_repr___redArg___closed__16 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_instReprPerson_repr___redArg___closed__16_value;
static const lean_ctor_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_instReprPerson_repr___redArg___closed__17_value = {.m_header = {.m_rc = 0, .m_cs_sz = sizeof(lean_ctor_object) + sizeof(void*)*1 + 0, .m_other = 1, .m_tag = 3}, .m_objs = {((lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_instReprPerson_repr___redArg___closed__13_value)}};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_instReprPerson_repr___redArg___closed__17 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_instReprPerson_repr___redArg___closed__17_value;
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_instReprPerson_repr___redArg(lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_instReprPerson_repr(lean_object*, lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_instReprPerson_repr___boxed(lean_object*, lean_object*);
static const lean_closure_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_instReprPerson___closed__0_value = {.m_header = {.m_rc = 0, .m_cs_sz = sizeof(lean_closure_object) + sizeof(void*)*0, .m_other = 0, .m_tag = 245}, .m_fun = (void*)lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_instReprPerson_repr___boxed, .m_arity = 2, .m_num_fixed = 0, .m_objs = {} };
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_instReprPerson___closed__0 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_instReprPerson___closed__0_value;
LEAN_EXPORT const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_instReprPerson = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_instReprPerson___closed__0_value;
static const lean_string_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_instDescribablePerson___lam__0___closed__0_value = {.m_header = {.m_rc = 0, .m_cs_sz = 0, .m_other = 0, .m_tag = 249}, .m_size = 13, .m_capacity = 13, .m_length = 12, .m_data = "Person(name="};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_instDescribablePerson___lam__0___closed__0 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_instDescribablePerson___lam__0___closed__0_value;
static const lean_string_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_instDescribablePerson___lam__0___closed__1_value = {.m_header = {.m_rc = 0, .m_cs_sz = 0, .m_other = 0, .m_tag = 249}, .m_size = 7, .m_capacity = 7, .m_length = 6, .m_data = ", age="};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_instDescribablePerson___lam__0___closed__1 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_instDescribablePerson___lam__0___closed__1_value;
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_instDescribablePerson___lam__0(lean_object*);
static const lean_string_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_instDescribablePerson___lam__1___closed__0_value = {.m_header = {.m_rc = 0, .m_cs_sz = 0, .m_other = 0, .m_tag = 249}, .m_size = 4, .m_capacity = 4, .m_length = 3, .m_data = "..."};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_instDescribablePerson___lam__1___closed__0 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_instDescribablePerson___lam__1___closed__0_value;
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_instDescribablePerson___lam__1(lean_object*);
static const lean_closure_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_instDescribablePerson___closed__0_value = {.m_header = {.m_rc = 0, .m_cs_sz = sizeof(lean_closure_object) + sizeof(void*)*0, .m_other = 0, .m_tag = 245}, .m_fun = (void*)lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_instDescribablePerson___lam__0, .m_arity = 1, .m_num_fixed = 0, .m_objs = {} };
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_instDescribablePerson___closed__0 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_instDescribablePerson___closed__0_value;
static const lean_closure_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_instDescribablePerson___closed__1_value = {.m_header = {.m_rc = 0, .m_cs_sz = sizeof(lean_closure_object) + sizeof(void*)*0, .m_other = 0, .m_tag = 245}, .m_fun = (void*)lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_instDescribablePerson___lam__1, .m_arity = 1, .m_num_fixed = 0, .m_objs = {} };
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_instDescribablePerson___closed__1 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_instDescribablePerson___closed__1_value;
static const lean_ctor_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_instDescribablePerson___closed__2_value = {.m_header = {.m_rc = 0, .m_cs_sz = sizeof(lean_ctor_object) + sizeof(void*)*2 + 0, .m_other = 2, .m_tag = 0}, .m_objs = {((lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_instDescribablePerson___closed__0_value),((lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_instDescribablePerson___closed__1_value)}};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_instDescribablePerson___closed__2 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_instDescribablePerson___closed__2_value;
LEAN_EXPORT const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_instDescribablePerson = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_instDescribablePerson___closed__2_value;
static const lean_string_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_alice___closed__0_value = {.m_header = {.m_rc = 0, .m_cs_sz = 0, .m_other = 0, .m_tag = 249}, .m_size = 6, .m_capacity = 6, .m_length = 5, .m_data = "Alice"};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_alice___closed__0 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_alice___closed__0_value;
static const lean_ctor_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_alice___closed__1_value = {.m_header = {.m_rc = 0, .m_cs_sz = sizeof(lean_ctor_object) + sizeof(void*)*2 + 0, .m_other = 2, .m_tag = 0}, .m_objs = {((lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_alice___closed__0_value),((lean_object*)(((size_t)(30) << 1) | 1))}};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_alice___closed__1 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_alice___closed__1_value;
LEAN_EXPORT const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_alice = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_alice___closed__1_value;
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_describe__alice;
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_name__alice;
static const lean_string_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_instDescribableBook___lam__0___closed__0_value = {.m_header = {.m_rc = 0, .m_cs_sz = 0, .m_other = 0, .m_tag = 249}, .m_size = 4, .m_capacity = 4, .m_length = 1, .m_data = "《"};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_instDescribableBook___lam__0___closed__0 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_instDescribableBook___lam__0___closed__0_value;
static const lean_string_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_instDescribableBook___lam__0___closed__1_value = {.m_header = {.m_rc = 0, .m_cs_sz = 0, .m_other = 0, .m_tag = 249}, .m_size = 7, .m_capacity = 7, .m_length = 4, .m_data = "》by "};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_instDescribableBook___lam__0___closed__1 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_instDescribableBook___lam__0___closed__1_value;
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_instDescribableBook___lam__0(lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_instDescribableBook___lam__0___boxed(lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_instDescribableBook___lam__1(lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_instDescribableBook___lam__1___boxed(lean_object*);
static const lean_closure_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_instDescribableBook___closed__0_value = {.m_header = {.m_rc = 0, .m_cs_sz = sizeof(lean_closure_object) + sizeof(void*)*0, .m_other = 0, .m_tag = 245}, .m_fun = (void*)lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_instDescribableBook___lam__0___boxed, .m_arity = 1, .m_num_fixed = 0, .m_objs = {} };
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_instDescribableBook___closed__0 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_instDescribableBook___closed__0_value;
static const lean_closure_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_instDescribableBook___closed__1_value = {.m_header = {.m_rc = 0, .m_cs_sz = sizeof(lean_closure_object) + sizeof(void*)*0, .m_other = 0, .m_tag = 245}, .m_fun = (void*)lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_instDescribableBook___lam__1___boxed, .m_arity = 1, .m_num_fixed = 0, .m_objs = {} };
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_instDescribableBook___closed__1 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_instDescribableBook___closed__1_value;
static const lean_ctor_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_instDescribableBook___closed__2_value = {.m_header = {.m_rc = 0, .m_cs_sz = sizeof(lean_ctor_object) + sizeof(void*)*2 + 0, .m_other = 2, .m_tag = 0}, .m_objs = {((lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_instDescribableBook___closed__0_value),((lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_instDescribableBook___closed__1_value)}};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_instDescribableBook___closed__2 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_instDescribableBook___closed__2_value;
LEAN_EXPORT const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_instDescribableBook = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_instDescribableBook___closed__2_value;
static const lean_string_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_book___closed__0_value = {.m_header = {.m_rc = 0, .m_cs_sz = 0, .m_other = 0, .m_tag = 249}, .m_size = 14, .m_capacity = 14, .m_length = 9, .m_data = "Lean 4 教程"};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_book___closed__0 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_book___closed__0_value;
static const lean_string_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_book___closed__1_value = {.m_header = {.m_rc = 0, .m_cs_sz = 0, .m_other = 0, .m_tag = 249}, .m_size = 7, .m_capacity = 7, .m_length = 2, .m_data = "张三"};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_book___closed__1 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_book___closed__1_value;
static const lean_ctor_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_book___closed__2_value = {.m_header = {.m_rc = 0, .m_cs_sz = sizeof(lean_ctor_object) + sizeof(void*)*2 + 0, .m_other = 2, .m_tag = 0}, .m_objs = {((lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_book___closed__0_value),((lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_book___closed__1_value)}};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_book___closed__2 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_book___closed__2_value;
LEAN_EXPORT const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_book = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_book___closed__2_value;
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_describe__book;
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_name__book;
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_printList_printListTail___redArg(lean_object*, lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_printList_printListTail(lean_object*, lean_object*, lean_object*);
static const lean_string_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_printList___redArg___closed__0_value = {.m_header = {.m_rc = 0, .m_cs_sz = 0, .m_other = 0, .m_tag = 249}, .m_size = 3, .m_capacity = 3, .m_length = 2, .m_data = "[]"};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_printList___redArg___closed__0 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_printList___redArg___closed__0_value;
static const lean_string_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_printList___redArg___closed__1_value = {.m_header = {.m_rc = 0, .m_cs_sz = 0, .m_other = 0, .m_tag = 249}, .m_size = 2, .m_capacity = 2, .m_length = 1, .m_data = "["};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_printList___redArg___closed__1 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_printList___redArg___closed__1_value;
static const lean_string_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_printList___redArg___closed__2_value = {.m_header = {.m_rc = 0, .m_cs_sz = 0, .m_other = 0, .m_tag = 249}, .m_size = 2, .m_capacity = 2, .m_length = 1, .m_data = "]"};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_printList___redArg___closed__2 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_printList___redArg___closed__2_value;
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_printList___redArg(lean_object*, lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_printList(lean_object*, lean_object*, lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_printList_printListTail___at___00Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_printList___at___00Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_print__nat__list_spec__0_spec__0(lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_printList___at___00Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_print__nat__list_spec__0(lean_object*);
static const lean_ctor_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_print__nat__list___closed__0_value = {.m_header = {.m_rc = 0, .m_cs_sz = sizeof(lean_ctor_object) + sizeof(void*)*2 + 0, .m_other = 2, .m_tag = 1}, .m_objs = {((lean_object*)(((size_t)(5) << 1) | 1)),((lean_object*)(((size_t)(0) << 1) | 1))}};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_print__nat__list___closed__0 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_print__nat__list___closed__0_value;
static const lean_ctor_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_print__nat__list___closed__1_value = {.m_header = {.m_rc = 0, .m_cs_sz = sizeof(lean_ctor_object) + sizeof(void*)*2 + 0, .m_other = 2, .m_tag = 1}, .m_objs = {((lean_object*)(((size_t)(4) << 1) | 1)),((lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_print__nat__list___closed__0_value)}};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_print__nat__list___closed__1 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_print__nat__list___closed__1_value;
static const lean_ctor_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_print__nat__list___closed__2_value = {.m_header = {.m_rc = 0, .m_cs_sz = sizeof(lean_ctor_object) + sizeof(void*)*2 + 0, .m_other = 2, .m_tag = 1}, .m_objs = {((lean_object*)(((size_t)(3) << 1) | 1)),((lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_print__nat__list___closed__1_value)}};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_print__nat__list___closed__2 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_print__nat__list___closed__2_value;
static const lean_ctor_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_print__nat__list___closed__3_value = {.m_header = {.m_rc = 0, .m_cs_sz = sizeof(lean_ctor_object) + sizeof(void*)*2 + 0, .m_other = 2, .m_tag = 1}, .m_objs = {((lean_object*)(((size_t)(2) << 1) | 1)),((lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_print__nat__list___closed__2_value)}};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_print__nat__list___closed__3 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_print__nat__list___closed__3_value;
static const lean_ctor_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_print__nat__list___closed__4_value = {.m_header = {.m_rc = 0, .m_cs_sz = sizeof(lean_ctor_object) + sizeof(void*)*2 + 0, .m_other = 2, .m_tag = 1}, .m_objs = {((lean_object*)(((size_t)(1) << 1) | 1)),((lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_print__nat__list___closed__3_value)}};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_print__nat__list___closed__4 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_print__nat__list___closed__4_value;
static lean_once_cell_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_print__nat__list___closed__5_once = LEAN_ONCE_CELL_INITIALIZER;
static lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_print__nat__list___closed__5;
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_print__nat__list;
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_printList_printListTail___at___00Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_printList___at___00Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_print__bool__list_spec__0_spec__0(lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_printList_printListTail___at___00Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_printList___at___00Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_print__bool__list_spec__0_spec__0___boxed(lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_printList___at___00Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_print__bool__list_spec__0(lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_printList___at___00Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_print__bool__list_spec__0___boxed(lean_object*);
static const lean_ctor_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_print__bool__list___closed__0_value = {.m_header = {.m_rc = 0, .m_cs_sz = sizeof(lean_ctor_object) + sizeof(void*)*2 + 0, .m_other = 2, .m_tag = 1}, .m_objs = {((lean_object*)(((size_t)(1) << 1) | 1)),((lean_object*)(((size_t)(0) << 1) | 1))}};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_print__bool__list___closed__0 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_print__bool__list___closed__0_value;
static const lean_ctor_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_print__bool__list___closed__1_value = {.m_header = {.m_rc = 0, .m_cs_sz = sizeof(lean_ctor_object) + sizeof(void*)*2 + 0, .m_other = 2, .m_tag = 1}, .m_objs = {((lean_object*)(((size_t)(0) << 1) | 1)),((lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_print__bool__list___closed__0_value)}};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_print__bool__list___closed__1 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_print__bool__list___closed__1_value;
static const lean_ctor_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_print__bool__list___closed__2_value = {.m_header = {.m_rc = 0, .m_cs_sz = sizeof(lean_ctor_object) + sizeof(void*)*2 + 0, .m_other = 2, .m_tag = 1}, .m_objs = {((lean_object*)(((size_t)(1) << 1) | 1)),((lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_print__bool__list___closed__1_value)}};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_print__bool__list___closed__2 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_print__bool__list___closed__2_value;
static lean_once_cell_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_print__bool__list___closed__3_once = LEAN_ONCE_CELL_INITIALIZER;
static lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_print__bool__list___closed__3;
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_print__bool__list;
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_instPrintableProd___redArg___lam__0(lean_object*, lean_object*, lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_instPrintableProd___redArg(lean_object*, lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_instPrintableProd(lean_object*, lean_object*, lean_object*, lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_printIt___at___00Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_print__pair_x27_spec__0(lean_object*);
static const lean_ctor_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_print__pair_x27___closed__0_value = {.m_header = {.m_rc = 0, .m_cs_sz = sizeof(lean_ctor_object) + sizeof(void*)*2 + 0, .m_other = 2, .m_tag = 0}, .m_objs = {((lean_object*)(((size_t)(42) << 1) | 1)),((lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_print__string___closed__0_value)}};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_print__pair_x27___closed__0 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_print__pair_x27___closed__0_value;
static lean_once_cell_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_print__pair_x27___closed__1_once = LEAN_ONCE_CELL_INITIALIZER;
static lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_print__pair_x27___closed__1;
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_print__pair_x27;
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_printIt___at___00Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_printIt___at___00Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_print__nested_spec__0_spec__0(lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_printIt___at___00Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_print__nested_spec__0(lean_object*);
static const lean_ctor_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_print__nested___closed__0_value = {.m_header = {.m_rc = 0, .m_cs_sz = sizeof(lean_ctor_object) + sizeof(void*)*2 + 0, .m_other = 2, .m_tag = 0}, .m_objs = {((lean_object*)(((size_t)(1) << 1) | 1)),((lean_object*)(((size_t)(2) << 1) | 1))}};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_print__nested___closed__0 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_print__nested___closed__0_value;
static const lean_ctor_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_print__nested___closed__1_value = {.m_header = {.m_rc = 0, .m_cs_sz = sizeof(lean_ctor_object) + sizeof(void*)*2 + 0, .m_other = 2, .m_tag = 0}, .m_objs = {((lean_object*)(((size_t)(3) << 1) | 1)),((lean_object*)(((size_t)(4) << 1) | 1))}};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_print__nested___closed__1 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_print__nested___closed__1_value;
static const lean_ctor_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_print__nested___closed__2_value = {.m_header = {.m_rc = 0, .m_cs_sz = sizeof(lean_ctor_object) + sizeof(void*)*2 + 0, .m_other = 2, .m_tag = 0}, .m_objs = {((lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_print__nested___closed__0_value),((lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_print__nested___closed__1_value)}};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_print__nested___closed__2 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_print__nested___closed__2_value;
static lean_once_cell_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_print__nested___closed__3_once = LEAN_ONCE_CELL_INITIALIZER;
static lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_print__nested___closed__3;
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_print__nested;
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_instPrintableList___redArg___lam__0(lean_object*, lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_instPrintableList___redArg(lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_instPrintableList(lean_object*, lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_printList_printListTail___at___00Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_printList___at___00Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_printIt___at___00Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_print__list__of__lists_spec__0_spec__0_spec__2(lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_printList___at___00Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_printIt___at___00Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_print__list__of__lists_spec__0_spec__0(lean_object*);
static const lean_ctor_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_print__list__of__lists___closed__0_value = {.m_header = {.m_rc = 0, .m_cs_sz = sizeof(lean_ctor_object) + sizeof(void*)*2 + 0, .m_other = 2, .m_tag = 1}, .m_objs = {((lean_object*)(((size_t)(2) << 1) | 1)),((lean_object*)(((size_t)(0) << 1) | 1))}};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_print__list__of__lists___closed__0 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_print__list__of__lists___closed__0_value;
static const lean_ctor_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_print__list__of__lists___closed__1_value = {.m_header = {.m_rc = 0, .m_cs_sz = sizeof(lean_ctor_object) + sizeof(void*)*2 + 0, .m_other = 2, .m_tag = 1}, .m_objs = {((lean_object*)(((size_t)(1) << 1) | 1)),((lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_print__list__of__lists___closed__0_value)}};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_print__list__of__lists___closed__1 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_print__list__of__lists___closed__1_value;
static const lean_ctor_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_print__list__of__lists___closed__2_value = {.m_header = {.m_rc = 0, .m_cs_sz = sizeof(lean_ctor_object) + sizeof(void*)*2 + 0, .m_other = 2, .m_tag = 1}, .m_objs = {((lean_object*)(((size_t)(4) << 1) | 1)),((lean_object*)(((size_t)(0) << 1) | 1))}};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_print__list__of__lists___closed__2 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_print__list__of__lists___closed__2_value;
static const lean_ctor_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_print__list__of__lists___closed__3_value = {.m_header = {.m_rc = 0, .m_cs_sz = sizeof(lean_ctor_object) + sizeof(void*)*2 + 0, .m_other = 2, .m_tag = 1}, .m_objs = {((lean_object*)(((size_t)(3) << 1) | 1)),((lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_print__list__of__lists___closed__2_value)}};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_print__list__of__lists___closed__3 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_print__list__of__lists___closed__3_value;
static const lean_ctor_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_print__list__of__lists___closed__4_value = {.m_header = {.m_rc = 0, .m_cs_sz = sizeof(lean_ctor_object) + sizeof(void*)*2 + 0, .m_other = 2, .m_tag = 1}, .m_objs = {((lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_print__nat__list___closed__0_value),((lean_object*)(((size_t)(0) << 1) | 1))}};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_print__list__of__lists___closed__4 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_print__list__of__lists___closed__4_value;
static const lean_ctor_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_print__list__of__lists___closed__5_value = {.m_header = {.m_rc = 0, .m_cs_sz = sizeof(lean_ctor_object) + sizeof(void*)*2 + 0, .m_other = 2, .m_tag = 1}, .m_objs = {((lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_print__list__of__lists___closed__3_value),((lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_print__list__of__lists___closed__4_value)}};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_print__list__of__lists___closed__5 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_print__list__of__lists___closed__5_value;
static const lean_ctor_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_print__list__of__lists___closed__6_value = {.m_header = {.m_rc = 0, .m_cs_sz = sizeof(lean_ctor_object) + sizeof(void*)*2 + 0, .m_other = 2, .m_tag = 1}, .m_objs = {((lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_print__list__of__lists___closed__1_value),((lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_print__list__of__lists___closed__5_value)}};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_print__list__of__lists___closed__6 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_print__list__of__lists___closed__6_value;
static lean_once_cell_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_print__list__of__lists___closed__7_once = LEAN_ONCE_CELL_INITIALIZER;
static lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_print__list__of__lists___closed__7;
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_print__list__of__lists;
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_printIt___at___00Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_print__list__of__lists_spec__0(lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_printIt___at___00Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_printList___at___00Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_printIt___at___00Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_print__list__of__lists_spec__0_spec__0_spec__1(lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_instReadablePrintableNat___lam__0(lean_object*);
static const lean_closure_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_instReadablePrintableNat___closed__0_value = {.m_header = {.m_rc = 0, .m_cs_sz = sizeof(lean_closure_object) + sizeof(void*)*0, .m_other = 0, .m_tag = 245}, .m_fun = (void*)lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_instReadablePrintableNat___lam__0, .m_arity = 1, .m_num_fixed = 0, .m_objs = {} };
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_instReadablePrintableNat___closed__0 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_instReadablePrintableNat___closed__0_value;
static const lean_ctor_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_instReadablePrintableNat___closed__1_value = {.m_header = {.m_rc = 0, .m_cs_sz = sizeof(lean_ctor_object) + sizeof(void*)*2 + 0, .m_other = 2, .m_tag = 0}, .m_objs = {((lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_instPrintableNat___closed__0_value),((lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_instReadablePrintableNat___closed__0_value)}};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_instReadablePrintableNat___closed__1 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_instReadablePrintableNat___closed__1_value;
LEAN_EXPORT const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_instReadablePrintableNat = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_instReadablePrintableNat___closed__1_value;
static lean_once_cell_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_parse__nat___closed__0_once = LEAN_ONCE_CELL_INITIALIZER;
static lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_parse__nat___closed__0;
static lean_once_cell_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_parse__nat___closed__1_once = LEAN_ONCE_CELL_INITIALIZER;
static lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_parse__nat___closed__1;
static lean_once_cell_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_parse__nat___closed__2_once = LEAN_ONCE_CELL_INITIALIZER;
static lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_parse__nat___closed__2;
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_parse__nat;
static const lean_string_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_parse__fail___closed__0_value = {.m_header = {.m_rc = 0, .m_cs_sz = 0, .m_other = 0, .m_tag = 249}, .m_size = 4, .m_capacity = 4, .m_length = 3, .m_data = "abc"};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_parse__fail___closed__0 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_parse__fail___closed__0_value;
static lean_once_cell_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_parse__fail___closed__1_once = LEAN_ONCE_CELL_INITIALIZER;
static lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_parse__fail___closed__1;
static lean_once_cell_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_parse__fail___closed__2_once = LEAN_ONCE_CELL_INITIALIZER;
static lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_parse__fail___closed__2;
static lean_once_cell_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_parse__fail___closed__3_once = LEAN_ONCE_CELL_INITIALIZER;
static lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_parse__fail___closed__3;
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_parse__fail;
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_print__via__readable___redArg(lean_object*, lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_print__via__readable(lean_object*, lean_object*, lean_object*);
LEAN_EXPORT const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_print__42 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_print__nat___closed__0_value;
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_printIt___at___00Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_print__via__readable___at___00Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_print__42_spec__0_spec__0(lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_print__via__readable___at___00Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_print__42_spec__0(lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_direct__print___redArg(lean_object*, lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_direct__print(lean_object*, lean_object*, lean_object*);
LEAN_EXPORT uint8_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_comparePrint___redArg(lean_object*, lean_object*, lean_object*, lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_comparePrint___redArg___boxed(lean_object*, lean_object*, lean_object*, lean_object*);
LEAN_EXPORT uint8_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_comparePrint(lean_object*, lean_object*, lean_object*, lean_object*, lean_object*, lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_comparePrint___boxed(lean_object*, lean_object*, lean_object*, lean_object*, lean_object*, lean_object*);
LEAN_EXPORT uint8_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_comparePrint___at___00Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_cmp__result_spec__0(lean_object*, lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_comparePrint___at___00Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_cmp__result_spec__0___boxed(lean_object*, lean_object*);
static lean_once_cell_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_cmp__result___closed__0_once = LEAN_ONCE_CELL_INITIALIZER;
static uint8_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_cmp__result___closed__0;
LEAN_EXPORT uint8_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_cmp__result;
LEAN_EXPORT uint8_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_instComparableNat___lam__0(lean_object*, lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_instComparableNat___lam__0___boxed(lean_object*, lean_object*);
static const lean_closure_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_instComparableNat___closed__0_value = {.m_header = {.m_rc = 0, .m_cs_sz = sizeof(lean_closure_object) + sizeof(void*)*0, .m_other = 0, .m_tag = 245}, .m_fun = (void*)lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_instComparableNat___lam__0___boxed, .m_arity = 2, .m_num_fixed = 0, .m_objs = {} };
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_instComparableNat___closed__0 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_instComparableNat___closed__0_value;
LEAN_EXPORT const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_instComparableNat = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_instComparableNat___closed__0_value;
LEAN_EXPORT uint8_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_cmp__nat;
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_instPrintableBool___lam__0(uint8_t v_b_5_){
_start:
{
if (v_b_5_ == 0)
{
lean_object* v___x_6_; 
v___x_6_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_instPrintableBool___lam__0___closed__0));
return v___x_6_;
}
else
{
lean_object* v___x_7_; 
v___x_7_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_instPrintableBool___lam__0___closed__1));
return v___x_7_;
}
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_instPrintableBool___lam__0___boxed(lean_object* v_b_8_){
_start:
{
uint8_t v_b_boxed_9_; lean_object* v_res_10_; 
v_b_boxed_9_ = lean_unbox(v_b_8_);
v_res_10_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_instPrintableBool___lam__0(v_b_boxed_9_);
return v_res_10_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_instPrintableString___lam__0(lean_object* v_s_13_){
_start:
{
lean_inc_ref(v_s_13_);
return v_s_13_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_instPrintableString___lam__0___boxed(lean_object* v_s_14_){
_start:
{
lean_object* v_res_15_; 
v_res_15_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_instPrintableString___lam__0(v_s_14_);
lean_dec_ref(v_s_14_);
return v_res_15_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_instPrintableChar___lam__0(uint32_t v_c_19_){
_start:
{
lean_object* v___x_20_; lean_object* v___x_21_; 
v___x_20_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_instPrintableChar___lam__0___closed__0));
v___x_21_ = lean_string_push(v___x_20_, v_c_19_);
return v___x_21_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_instPrintableChar___lam__0___boxed(lean_object* v_c_22_){
_start:
{
uint32_t v_c_boxed_23_; lean_object* v_res_24_; 
v_c_boxed_23_ = lean_unbox_uint32(v_c_22_);
lean_dec(v_c_22_);
v_res_24_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_instPrintableChar___lam__0(v_c_boxed_23_);
return v_res_24_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_printIt___redArg(lean_object* v_inst_27_, lean_object* v_x_28_){
_start:
{
lean_object* v___x_29_; 
v___x_29_ = lean_apply_1(v_inst_27_, v_x_28_);
return v___x_29_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_printIt(lean_object* v_00_u03b1_30_, lean_object* v_inst_31_, lean_object* v_x_32_){
_start:
{
lean_object* v___x_33_; 
v___x_33_ = lean_apply_1(v_inst_31_, v_x_32_);
return v___x_33_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_printIt___at___00Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_print__nat_spec__0(lean_object* v_x_34_){
_start:
{
lean_object* v___x_35_; 
v___x_35_ = l_Nat_reprFast(v_x_34_);
return v___x_35_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_printIt___at___00Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_print__bool_spec__0(uint8_t v_x_38_){
_start:
{
if (v_x_38_ == 0)
{
lean_object* v___x_39_; 
v___x_39_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_instPrintableBool___lam__0___closed__0));
return v___x_39_;
}
else
{
lean_object* v___x_40_; 
v___x_40_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_instPrintableBool___lam__0___closed__1));
return v___x_40_;
}
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_printIt___at___00Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_print__bool_spec__0___boxed(lean_object* v_x_41_){
_start:
{
uint8_t v_x_boxed_42_; lean_object* v_res_43_; 
v_x_boxed_42_ = lean_unbox(v_x_41_);
v_res_43_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_printIt___at___00Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_print__bool_spec__0(v_x_boxed_42_);
return v_res_43_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_print__bool___closed__0(void){
_start:
{
uint8_t v___x_44_; lean_object* v___x_45_; 
v___x_44_ = 1;
v___x_45_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_printIt___at___00Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_print__bool_spec__0(v___x_44_);
return v___x_45_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_print__bool(void){
_start:
{
lean_object* v___x_46_; 
v___x_46_ = lean_obj_once(&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_print__bool___closed__0, &lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_print__bool___closed__0_once, _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_print__bool___closed__0);
return v___x_46_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_printIt___at___00Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_print__string_spec__0(lean_object* v_x_47_){
_start:
{
lean_inc_ref(v_x_47_);
return v_x_47_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_printIt___at___00Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_print__string_spec__0___boxed(lean_object* v_x_48_){
_start:
{
lean_object* v_res_49_; 
v_res_49_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_printIt___at___00Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_print__string_spec__0(v_x_48_);
lean_dec_ref(v_x_48_);
return v_res_49_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_printIt___at___00Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_print__char_spec__0(uint32_t v_x_52_){
_start:
{
lean_object* v___x_53_; lean_object* v___x_54_; 
v___x_53_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_instPrintableChar___lam__0___closed__0));
v___x_54_ = lean_string_push(v___x_53_, v_x_52_);
return v___x_54_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_printIt___at___00Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_print__char_spec__0___boxed(lean_object* v_x_55_){
_start:
{
uint32_t v_x_boxed_56_; lean_object* v_res_57_; 
v_x_boxed_56_ = lean_unbox_uint32(v_x_55_);
lean_dec(v_x_55_);
v_res_57_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_printIt___at___00Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_print__char_spec__0(v_x_boxed_56_);
return v_res_57_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_print__char___closed__0(void){
_start:
{
uint32_t v___x_58_; lean_object* v___x_59_; 
v___x_58_ = 97;
v___x_59_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_printIt___at___00Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_print__char_spec__0(v___x_58_);
return v___x_59_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_print__char(void){
_start:
{
lean_object* v___x_60_; 
v___x_60_ = lean_obj_once(&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_print__char___closed__0, &lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_print__char___closed__0_once, _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_print__char___closed__0);
return v___x_60_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_printPair___redArg(lean_object* v_inst_64_, lean_object* v_inst_65_, lean_object* v_p_66_){
_start:
{
lean_object* v_fst_67_; lean_object* v_snd_68_; lean_object* v___x_69_; lean_object* v___x_70_; lean_object* v___x_71_; lean_object* v___x_72_; lean_object* v___x_73_; lean_object* v___x_74_; lean_object* v___x_75_; lean_object* v___x_76_; lean_object* v___x_77_; 
v_fst_67_ = lean_ctor_get(v_p_66_, 0);
lean_inc(v_fst_67_);
v_snd_68_ = lean_ctor_get(v_p_66_, 1);
lean_inc(v_snd_68_);
lean_dec_ref(v_p_66_);
v___x_69_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_printPair___redArg___closed__0));
v___x_70_ = lean_apply_1(v_inst_64_, v_fst_67_);
v___x_71_ = lean_string_append(v___x_69_, v___x_70_);
lean_dec_ref(v___x_70_);
v___x_72_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_printPair___redArg___closed__1));
v___x_73_ = lean_string_append(v___x_71_, v___x_72_);
v___x_74_ = lean_apply_1(v_inst_65_, v_snd_68_);
v___x_75_ = lean_string_append(v___x_73_, v___x_74_);
lean_dec_ref(v___x_74_);
v___x_76_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_printPair___redArg___closed__2));
v___x_77_ = lean_string_append(v___x_75_, v___x_76_);
return v___x_77_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_printPair(lean_object* v_00_u03b1_78_, lean_object* v_00_u03b2_79_, lean_object* v_inst_80_, lean_object* v_inst_81_, lean_object* v_p_82_){
_start:
{
lean_object* v___x_83_; 
v___x_83_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_printPair___redArg(v_inst_80_, v_inst_81_, v_p_82_);
return v___x_83_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_printPair___at___00Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_print__pair_spec__0(lean_object* v_p_84_){
_start:
{
lean_object* v_fst_85_; lean_object* v_snd_86_; lean_object* v___x_87_; lean_object* v___x_88_; lean_object* v___x_89_; lean_object* v___x_90_; lean_object* v___x_91_; uint8_t v___x_92_; lean_object* v___x_93_; lean_object* v___x_94_; lean_object* v___x_95_; lean_object* v___x_96_; 
v_fst_85_ = lean_ctor_get(v_p_84_, 0);
lean_inc(v_fst_85_);
v_snd_86_ = lean_ctor_get(v_p_84_, 1);
lean_inc(v_snd_86_);
lean_dec_ref(v_p_84_);
v___x_87_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_printPair___redArg___closed__0));
v___x_88_ = l_Nat_reprFast(v_fst_85_);
v___x_89_ = lean_string_append(v___x_87_, v___x_88_);
lean_dec_ref(v___x_88_);
v___x_90_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_printPair___redArg___closed__1));
v___x_91_ = lean_string_append(v___x_89_, v___x_90_);
v___x_92_ = lean_unbox(v_snd_86_);
lean_dec(v_snd_86_);
v___x_93_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_printIt___at___00Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_print__bool_spec__0(v___x_92_);
v___x_94_ = lean_string_append(v___x_91_, v___x_93_);
lean_dec_ref(v___x_93_);
v___x_95_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_printPair___redArg___closed__2));
v___x_96_ = lean_string_append(v___x_94_, v___x_95_);
return v___x_96_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_print__pair___closed__1(void){
_start:
{
lean_object* v___x_101_; lean_object* v___x_102_; 
v___x_101_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_print__pair___closed__0));
v___x_102_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_printPair___at___00Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_print__pair_spec__0(v___x_101_);
return v___x_102_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_print__pair(void){
_start:
{
lean_object* v___x_103_; 
v___x_103_ = lean_obj_once(&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_print__pair___closed__1, &lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_print__pair___closed__1_once, _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_print__pair___closed__1);
return v___x_103_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_instConvertibleBoolNat___lam__0(uint8_t v_b_105_){
_start:
{
if (v_b_105_ == 0)
{
lean_object* v___x_106_; 
v___x_106_ = lean_unsigned_to_nat(0u);
return v___x_106_;
}
else
{
lean_object* v___x_107_; 
v___x_107_ = lean_unsigned_to_nat(1u);
return v___x_107_;
}
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_instConvertibleBoolNat___lam__0___boxed(lean_object* v_b_108_){
_start:
{
uint8_t v_b_boxed_109_; lean_object* v_res_110_; 
v_b_boxed_109_ = lean_unbox(v_b_108_);
v_res_110_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_instConvertibleBoolNat___lam__0(v_b_boxed_109_);
return v_res_110_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_convertExample___redArg(lean_object* v_inst_113_, lean_object* v_x_114_){
_start:
{
lean_object* v___x_115_; 
v___x_115_ = lean_apply_1(v_inst_113_, v_x_114_);
return v___x_115_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_convertExample(lean_object* v_00_u03b1_116_, lean_object* v_00_u03b2_117_, lean_object* v_inst_118_, lean_object* v_x_119_){
_start:
{
lean_object* v___x_120_; 
v___x_120_ = lean_apply_1(v_inst_118_, v_x_119_);
return v___x_120_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_convertExample___at___00Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_nat__to__string_spec__0(lean_object* v_x_121_){
_start:
{
lean_object* v___x_122_; 
v___x_122_ = l_Nat_reprFast(v_x_121_);
return v___x_122_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_convertExample___at___00Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_bool__to__nat_spec__0(uint8_t v_x_124_){
_start:
{
if (v_x_124_ == 0)
{
lean_object* v___x_125_; 
v___x_125_ = lean_unsigned_to_nat(0u);
return v___x_125_;
}
else
{
lean_object* v___x_126_; 
v___x_126_ = lean_unsigned_to_nat(1u);
return v___x_126_;
}
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_convertExample___at___00Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_bool__to__nat_spec__0___boxed(lean_object* v_x_127_){
_start:
{
uint8_t v_x_boxed_128_; lean_object* v_res_129_; 
v_x_boxed_128_ = lean_unbox(v_x_127_);
v_res_129_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_convertExample___at___00Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_bool__to__nat_spec__0(v_x_boxed_128_);
return v_res_129_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_bool__to__nat___closed__0(void){
_start:
{
uint8_t v___x_130_; lean_object* v___x_131_; 
v___x_130_ = 1;
v___x_131_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_convertExample___at___00Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_bool__to__nat_spec__0(v___x_130_);
return v___x_131_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_bool__to__nat(void){
_start:
{
lean_object* v___x_132_; 
v___x_132_ = lean_obj_once(&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_bool__to__nat___closed__0, &lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_bool__to__nat___closed__0_once, _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_bool__to__nat___closed__0);
return v___x_132_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_takeN(lean_object* v_s_135_, lean_object* v_n_136_){
_start:
{
lean_object* v___x_137_; lean_object* v___x_138_; lean_object* v___x_139_; lean_object* v___x_140_; 
v___x_137_ = lean_string_data(v_s_135_);
v___x_138_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_takeN___closed__0));
lean_inc(v___x_137_);
v___x_139_ = l___private_Init_Data_List_Impl_0__List_takeTR_go___redArg(v___x_137_, v___x_137_, v_n_136_, v___x_138_);
lean_dec(v___x_137_);
v___x_140_ = lean_string_mk(v___x_139_);
return v___x_140_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_instReprPerson_repr___redArg___closed__7(void){
_start:
{
lean_object* v___x_154_; lean_object* v___x_155_; 
v___x_154_ = lean_unsigned_to_nat(14u);
v___x_155_ = lean_nat_to_int(v___x_154_);
return v___x_155_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_instReprPerson_repr___redArg___closed__12(void){
_start:
{
lean_object* v___x_162_; lean_object* v___x_163_; 
v___x_162_ = lean_unsigned_to_nat(7u);
v___x_163_ = lean_nat_to_int(v___x_162_);
return v___x_163_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_instReprPerson_repr___redArg___closed__14(void){
_start:
{
lean_object* v___x_165_; lean_object* v___x_166_; 
v___x_165_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_instReprPerson_repr___redArg___closed__0));
v___x_166_ = lean_string_length(v___x_165_);
return v___x_166_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_instReprPerson_repr___redArg___closed__15(void){
_start:
{
lean_object* v___x_167_; lean_object* v___x_168_; 
v___x_167_ = lean_obj_once(&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_instReprPerson_repr___redArg___closed__14, &lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_instReprPerson_repr___redArg___closed__14_once, _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_instReprPerson_repr___redArg___closed__14);
v___x_168_ = lean_nat_to_int(v___x_167_);
return v___x_168_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_instReprPerson_repr___redArg(lean_object* v_x_173_){
_start:
{
lean_object* v_personName_174_; lean_object* v_age_175_; lean_object* v___x_177_; uint8_t v_isShared_178_; uint8_t v_isSharedCheck_210_; 
v_personName_174_ = lean_ctor_get(v_x_173_, 0);
v_age_175_ = lean_ctor_get(v_x_173_, 1);
v_isSharedCheck_210_ = !lean_is_exclusive(v_x_173_);
if (v_isSharedCheck_210_ == 0)
{
v___x_177_ = v_x_173_;
v_isShared_178_ = v_isSharedCheck_210_;
goto v_resetjp_176_;
}
else
{
lean_inc(v_age_175_);
lean_inc(v_personName_174_);
lean_dec(v_x_173_);
v___x_177_ = lean_box(0);
v_isShared_178_ = v_isSharedCheck_210_;
goto v_resetjp_176_;
}
v_resetjp_176_:
{
lean_object* v___x_179_; lean_object* v___x_180_; lean_object* v___x_181_; lean_object* v___x_182_; lean_object* v___x_183_; lean_object* v___x_185_; 
v___x_179_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_instReprPerson_repr___redArg___closed__5));
v___x_180_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_instReprPerson_repr___redArg___closed__6));
v___x_181_ = lean_obj_once(&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_instReprPerson_repr___redArg___closed__7, &lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_instReprPerson_repr___redArg___closed__7_once, _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_instReprPerson_repr___redArg___closed__7);
v___x_182_ = l_String_quote(v_personName_174_);
v___x_183_ = lean_alloc_ctor(3, 1, 0);
lean_ctor_set(v___x_183_, 0, v___x_182_);
if (v_isShared_178_ == 0)
{
lean_ctor_set_tag(v___x_177_, 4);
lean_ctor_set(v___x_177_, 1, v___x_183_);
lean_ctor_set(v___x_177_, 0, v___x_181_);
v___x_185_ = v___x_177_;
goto v_reusejp_184_;
}
else
{
lean_object* v_reuseFailAlloc_209_; 
v_reuseFailAlloc_209_ = lean_alloc_ctor(4, 2, 0);
lean_ctor_set(v_reuseFailAlloc_209_, 0, v___x_181_);
lean_ctor_set(v_reuseFailAlloc_209_, 1, v___x_183_);
v___x_185_ = v_reuseFailAlloc_209_;
goto v_reusejp_184_;
}
v_reusejp_184_:
{
uint8_t v___x_186_; lean_object* v___x_187_; lean_object* v___x_188_; lean_object* v___x_189_; lean_object* v___x_190_; lean_object* v___x_191_; lean_object* v___x_192_; lean_object* v___x_193_; lean_object* v___x_194_; lean_object* v___x_195_; lean_object* v___x_196_; lean_object* v___x_197_; lean_object* v___x_198_; lean_object* v___x_199_; lean_object* v___x_200_; lean_object* v___x_201_; lean_object* v___x_202_; lean_object* v___x_203_; lean_object* v___x_204_; lean_object* v___x_205_; lean_object* v___x_206_; lean_object* v___x_207_; lean_object* v___x_208_; 
v___x_186_ = 0;
v___x_187_ = lean_alloc_ctor(6, 1, 1);
lean_ctor_set(v___x_187_, 0, v___x_185_);
lean_ctor_set_uint8(v___x_187_, sizeof(void*)*1, v___x_186_);
v___x_188_ = lean_alloc_ctor(5, 2, 0);
lean_ctor_set(v___x_188_, 0, v___x_180_);
lean_ctor_set(v___x_188_, 1, v___x_187_);
v___x_189_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_instReprPerson_repr___redArg___closed__9));
v___x_190_ = lean_alloc_ctor(5, 2, 0);
lean_ctor_set(v___x_190_, 0, v___x_188_);
lean_ctor_set(v___x_190_, 1, v___x_189_);
v___x_191_ = lean_box(1);
v___x_192_ = lean_alloc_ctor(5, 2, 0);
lean_ctor_set(v___x_192_, 0, v___x_190_);
lean_ctor_set(v___x_192_, 1, v___x_191_);
v___x_193_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_instReprPerson_repr___redArg___closed__11));
v___x_194_ = lean_alloc_ctor(5, 2, 0);
lean_ctor_set(v___x_194_, 0, v___x_192_);
lean_ctor_set(v___x_194_, 1, v___x_193_);
v___x_195_ = lean_alloc_ctor(5, 2, 0);
lean_ctor_set(v___x_195_, 0, v___x_194_);
lean_ctor_set(v___x_195_, 1, v___x_179_);
v___x_196_ = lean_obj_once(&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_instReprPerson_repr___redArg___closed__12, &lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_instReprPerson_repr___redArg___closed__12_once, _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_instReprPerson_repr___redArg___closed__12);
v___x_197_ = l_Nat_reprFast(v_age_175_);
v___x_198_ = lean_alloc_ctor(3, 1, 0);
lean_ctor_set(v___x_198_, 0, v___x_197_);
v___x_199_ = lean_alloc_ctor(4, 2, 0);
lean_ctor_set(v___x_199_, 0, v___x_196_);
lean_ctor_set(v___x_199_, 1, v___x_198_);
v___x_200_ = lean_alloc_ctor(6, 1, 1);
lean_ctor_set(v___x_200_, 0, v___x_199_);
lean_ctor_set_uint8(v___x_200_, sizeof(void*)*1, v___x_186_);
v___x_201_ = lean_alloc_ctor(5, 2, 0);
lean_ctor_set(v___x_201_, 0, v___x_195_);
lean_ctor_set(v___x_201_, 1, v___x_200_);
v___x_202_ = lean_obj_once(&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_instReprPerson_repr___redArg___closed__15, &lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_instReprPerson_repr___redArg___closed__15_once, _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_instReprPerson_repr___redArg___closed__15);
v___x_203_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_instReprPerson_repr___redArg___closed__16));
v___x_204_ = lean_alloc_ctor(5, 2, 0);
lean_ctor_set(v___x_204_, 0, v___x_203_);
lean_ctor_set(v___x_204_, 1, v___x_201_);
v___x_205_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_instReprPerson_repr___redArg___closed__17));
v___x_206_ = lean_alloc_ctor(5, 2, 0);
lean_ctor_set(v___x_206_, 0, v___x_204_);
lean_ctor_set(v___x_206_, 1, v___x_205_);
v___x_207_ = lean_alloc_ctor(4, 2, 0);
lean_ctor_set(v___x_207_, 0, v___x_202_);
lean_ctor_set(v___x_207_, 1, v___x_206_);
v___x_208_ = lean_alloc_ctor(6, 1, 1);
lean_ctor_set(v___x_208_, 0, v___x_207_);
lean_ctor_set_uint8(v___x_208_, sizeof(void*)*1, v___x_186_);
return v___x_208_;
}
}
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_instReprPerson_repr(lean_object* v_x_211_, lean_object* v_prec_212_){
_start:
{
lean_object* v___x_213_; 
v___x_213_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_instReprPerson_repr___redArg(v_x_211_);
return v___x_213_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_instReprPerson_repr___boxed(lean_object* v_x_214_, lean_object* v_prec_215_){
_start:
{
lean_object* v_res_216_; 
v_res_216_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_instReprPerson_repr(v_x_214_, v_prec_215_);
lean_dec(v_prec_215_);
return v_res_216_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_instDescribablePerson___lam__0(lean_object* v_p_221_){
_start:
{
lean_object* v_personName_222_; lean_object* v_age_223_; lean_object* v___x_224_; lean_object* v___x_225_; lean_object* v___x_226_; lean_object* v___x_227_; lean_object* v___x_228_; lean_object* v___x_229_; lean_object* v___x_230_; lean_object* v___x_231_; 
v_personName_222_ = lean_ctor_get(v_p_221_, 0);
lean_inc_ref(v_personName_222_);
v_age_223_ = lean_ctor_get(v_p_221_, 1);
lean_inc(v_age_223_);
lean_dec_ref(v_p_221_);
v___x_224_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_instDescribablePerson___lam__0___closed__0));
v___x_225_ = lean_string_append(v___x_224_, v_personName_222_);
lean_dec_ref(v_personName_222_);
v___x_226_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_instDescribablePerson___lam__0___closed__1));
v___x_227_ = lean_string_append(v___x_225_, v___x_226_);
v___x_228_ = l_Nat_reprFast(v_age_223_);
v___x_229_ = lean_string_append(v___x_227_, v___x_228_);
lean_dec_ref(v___x_228_);
v___x_230_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_printPair___redArg___closed__2));
v___x_231_ = lean_string_append(v___x_229_, v___x_230_);
return v___x_231_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_instDescribablePerson___lam__1(lean_object* v_p_233_){
_start:
{
lean_object* v_personName_234_; lean_object* v_age_235_; lean_object* v___x_236_; lean_object* v___x_237_; lean_object* v___x_238_; lean_object* v___x_239_; lean_object* v___x_240_; lean_object* v___x_241_; lean_object* v___x_242_; lean_object* v_s_243_; lean_object* v___x_244_; lean_object* v___x_245_; uint8_t v___x_246_; 
v_personName_234_ = lean_ctor_get(v_p_233_, 0);
lean_inc_ref(v_personName_234_);
v_age_235_ = lean_ctor_get(v_p_233_, 1);
lean_inc(v_age_235_);
lean_dec_ref(v_p_233_);
v___x_236_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_instDescribablePerson___lam__0___closed__0));
v___x_237_ = lean_string_append(v___x_236_, v_personName_234_);
lean_dec_ref(v_personName_234_);
v___x_238_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_instDescribablePerson___lam__0___closed__1));
v___x_239_ = lean_string_append(v___x_237_, v___x_238_);
v___x_240_ = l_Nat_reprFast(v_age_235_);
v___x_241_ = lean_string_append(v___x_239_, v___x_240_);
lean_dec_ref(v___x_240_);
v___x_242_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_printPair___redArg___closed__2));
v_s_243_ = lean_string_append(v___x_241_, v___x_242_);
v___x_244_ = lean_string_length(v_s_243_);
v___x_245_ = lean_unsigned_to_nat(10u);
v___x_246_ = lean_nat_dec_le(v___x_244_, v___x_245_);
if (v___x_246_ == 0)
{
lean_object* v___x_247_; lean_object* v___x_248_; lean_object* v___x_249_; 
v___x_247_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_takeN(v_s_243_, v___x_245_);
v___x_248_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_instDescribablePerson___lam__1___closed__0));
v___x_249_ = lean_string_append(v___x_247_, v___x_248_);
return v___x_249_;
}
else
{
return v_s_243_;
}
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_describe__alice(void){
_start:
{
lean_object* v___x_261_; lean_object* v_personName_262_; lean_object* v_age_263_; lean_object* v___x_264_; lean_object* v___x_265_; lean_object* v___x_266_; lean_object* v___x_267_; lean_object* v___x_268_; lean_object* v___x_269_; lean_object* v___x_270_; lean_object* v___x_271_; 
v___x_261_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_alice));
v_personName_262_ = lean_ctor_get(v___x_261_, 0);
v_age_263_ = lean_ctor_get(v___x_261_, 1);
v___x_264_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_instDescribablePerson___lam__0___closed__0));
v___x_265_ = lean_string_append(v___x_264_, v_personName_262_);
v___x_266_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_instDescribablePerson___lam__0___closed__1));
v___x_267_ = lean_string_append(v___x_265_, v___x_266_);
lean_inc(v_age_263_);
v___x_268_ = l_Nat_reprFast(v_age_263_);
v___x_269_ = lean_string_append(v___x_267_, v___x_268_);
lean_dec_ref(v___x_268_);
v___x_270_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_printPair___redArg___closed__2));
v___x_271_ = lean_string_append(v___x_269_, v___x_270_);
return v___x_271_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_name__alice(void){
_start:
{
lean_object* v___x_272_; lean_object* v_personName_273_; lean_object* v_age_274_; lean_object* v___x_275_; lean_object* v___x_276_; lean_object* v___x_277_; lean_object* v___x_278_; lean_object* v___x_279_; lean_object* v___x_280_; lean_object* v___x_281_; lean_object* v_s_282_; lean_object* v___x_283_; lean_object* v___x_284_; uint8_t v___x_285_; 
v___x_272_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_alice));
v_personName_273_ = lean_ctor_get(v___x_272_, 0);
v_age_274_ = lean_ctor_get(v___x_272_, 1);
v___x_275_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_instDescribablePerson___lam__0___closed__0));
v___x_276_ = lean_string_append(v___x_275_, v_personName_273_);
v___x_277_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_instDescribablePerson___lam__0___closed__1));
v___x_278_ = lean_string_append(v___x_276_, v___x_277_);
lean_inc(v_age_274_);
v___x_279_ = l_Nat_reprFast(v_age_274_);
v___x_280_ = lean_string_append(v___x_278_, v___x_279_);
lean_dec_ref(v___x_279_);
v___x_281_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_printPair___redArg___closed__2));
v_s_282_ = lean_string_append(v___x_280_, v___x_281_);
v___x_283_ = lean_string_length(v_s_282_);
v___x_284_ = lean_unsigned_to_nat(10u);
v___x_285_ = lean_nat_dec_le(v___x_283_, v___x_284_);
if (v___x_285_ == 0)
{
lean_object* v___x_286_; lean_object* v___x_287_; lean_object* v___x_288_; 
v___x_286_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_takeN(v_s_282_, v___x_284_);
v___x_287_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_instDescribablePerson___lam__1___closed__0));
v___x_288_ = lean_string_append(v___x_286_, v___x_287_);
return v___x_288_;
}
else
{
return v_s_282_;
}
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_instDescribableBook___lam__0(lean_object* v_b_291_){
_start:
{
lean_object* v_title_292_; lean_object* v_author_293_; lean_object* v___x_294_; lean_object* v___x_295_; lean_object* v___x_296_; lean_object* v___x_297_; lean_object* v___x_298_; 
v_title_292_ = lean_ctor_get(v_b_291_, 0);
v_author_293_ = lean_ctor_get(v_b_291_, 1);
v___x_294_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_instDescribableBook___lam__0___closed__0));
v___x_295_ = lean_string_append(v___x_294_, v_title_292_);
v___x_296_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_instDescribableBook___lam__0___closed__1));
v___x_297_ = lean_string_append(v___x_295_, v___x_296_);
v___x_298_ = lean_string_append(v___x_297_, v_author_293_);
return v___x_298_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_instDescribableBook___lam__0___boxed(lean_object* v_b_299_){
_start:
{
lean_object* v_res_300_; 
v_res_300_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_instDescribableBook___lam__0(v_b_299_);
lean_dec_ref(v_b_299_);
return v_res_300_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_instDescribableBook___lam__1(lean_object* v_b_301_){
_start:
{
lean_object* v_title_302_; 
v_title_302_ = lean_ctor_get(v_b_301_, 0);
lean_inc_ref(v_title_302_);
return v_title_302_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_instDescribableBook___lam__1___boxed(lean_object* v_b_303_){
_start:
{
lean_object* v_res_304_; 
v_res_304_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_instDescribableBook___lam__1(v_b_303_);
lean_dec_ref(v_b_303_);
return v_res_304_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_describe__book(void){
_start:
{
lean_object* v___x_317_; lean_object* v_title_318_; lean_object* v_author_319_; lean_object* v___x_320_; lean_object* v___x_321_; lean_object* v___x_322_; lean_object* v___x_323_; lean_object* v___x_324_; 
v___x_317_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_book));
v_title_318_ = lean_ctor_get(v___x_317_, 0);
v_author_319_ = lean_ctor_get(v___x_317_, 1);
v___x_320_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_instDescribableBook___lam__0___closed__0));
v___x_321_ = lean_string_append(v___x_320_, v_title_318_);
v___x_322_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_instDescribableBook___lam__0___closed__1));
v___x_323_ = lean_string_append(v___x_321_, v___x_322_);
v___x_324_ = lean_string_append(v___x_323_, v_author_319_);
return v___x_324_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_name__book(void){
_start:
{
lean_object* v___x_325_; lean_object* v_title_326_; 
v___x_325_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_book));
v_title_326_ = lean_ctor_get(v___x_325_, 0);
lean_inc_ref(v_title_326_);
return v_title_326_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_printList_printListTail___redArg(lean_object* v_inst_327_, lean_object* v_a_328_){
_start:
{
if (lean_obj_tag(v_a_328_) == 0)
{
lean_object* v___x_329_; 
lean_dec_ref(v_inst_327_);
v___x_329_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_instPrintableChar___lam__0___closed__0));
return v___x_329_;
}
else
{
lean_object* v_tail_330_; 
v_tail_330_ = lean_ctor_get(v_a_328_, 1);
if (lean_obj_tag(v_tail_330_) == 0)
{
lean_object* v_head_331_; lean_object* v___x_332_; 
v_head_331_ = lean_ctor_get(v_a_328_, 0);
lean_inc(v_head_331_);
lean_dec_ref_known(v_a_328_, 2);
v___x_332_ = lean_apply_1(v_inst_327_, v_head_331_);
return v___x_332_;
}
else
{
lean_object* v_head_333_; lean_object* v___x_334_; lean_object* v___x_335_; lean_object* v___x_336_; lean_object* v___x_337_; lean_object* v___x_338_; 
lean_inc(v_tail_330_);
v_head_333_ = lean_ctor_get(v_a_328_, 0);
lean_inc(v_head_333_);
lean_dec_ref_known(v_a_328_, 2);
lean_inc_ref(v_inst_327_);
v___x_334_ = lean_apply_1(v_inst_327_, v_head_333_);
v___x_335_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_printPair___redArg___closed__1));
v___x_336_ = lean_string_append(v___x_334_, v___x_335_);
v___x_337_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_printList_printListTail___redArg(v_inst_327_, v_tail_330_);
v___x_338_ = lean_string_append(v___x_336_, v___x_337_);
lean_dec_ref(v___x_337_);
return v___x_338_;
}
}
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_printList_printListTail(lean_object* v_00_u03b1_339_, lean_object* v_inst_340_, lean_object* v_a_341_){
_start:
{
lean_object* v___x_342_; 
v___x_342_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_printList_printListTail___redArg(v_inst_340_, v_a_341_);
return v___x_342_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_printList___redArg(lean_object* v_inst_346_, lean_object* v_l_347_){
_start:
{
if (lean_obj_tag(v_l_347_) == 0)
{
lean_object* v___x_348_; 
lean_dec_ref(v_inst_346_);
v___x_348_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_printList___redArg___closed__0));
return v___x_348_;
}
else
{
lean_object* v_tail_349_; 
v_tail_349_ = lean_ctor_get(v_l_347_, 1);
if (lean_obj_tag(v_tail_349_) == 0)
{
lean_object* v_head_350_; lean_object* v___x_351_; lean_object* v___x_352_; lean_object* v___x_353_; lean_object* v___x_354_; lean_object* v___x_355_; 
v_head_350_ = lean_ctor_get(v_l_347_, 0);
lean_inc(v_head_350_);
lean_dec_ref_known(v_l_347_, 2);
v___x_351_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_printList___redArg___closed__1));
v___x_352_ = lean_apply_1(v_inst_346_, v_head_350_);
v___x_353_ = lean_string_append(v___x_351_, v___x_352_);
lean_dec_ref(v___x_352_);
v___x_354_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_printList___redArg___closed__2));
v___x_355_ = lean_string_append(v___x_353_, v___x_354_);
return v___x_355_;
}
else
{
lean_object* v_head_356_; lean_object* v___x_357_; lean_object* v___x_358_; lean_object* v___x_359_; lean_object* v___x_360_; lean_object* v___x_361_; lean_object* v___x_362_; lean_object* v___x_363_; lean_object* v___x_364_; lean_object* v___x_365_; 
lean_inc(v_tail_349_);
v_head_356_ = lean_ctor_get(v_l_347_, 0);
lean_inc(v_head_356_);
lean_dec_ref_known(v_l_347_, 2);
v___x_357_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_printList___redArg___closed__1));
lean_inc_ref(v_inst_346_);
v___x_358_ = lean_apply_1(v_inst_346_, v_head_356_);
v___x_359_ = lean_string_append(v___x_357_, v___x_358_);
lean_dec_ref(v___x_358_);
v___x_360_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_printPair___redArg___closed__1));
v___x_361_ = lean_string_append(v___x_359_, v___x_360_);
v___x_362_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_printList_printListTail___redArg(v_inst_346_, v_tail_349_);
v___x_363_ = lean_string_append(v___x_361_, v___x_362_);
lean_dec_ref(v___x_362_);
v___x_364_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_printList___redArg___closed__2));
v___x_365_ = lean_string_append(v___x_363_, v___x_364_);
return v___x_365_;
}
}
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_printList(lean_object* v_00_u03b1_366_, lean_object* v_inst_367_, lean_object* v_l_368_){
_start:
{
lean_object* v___x_369_; 
v___x_369_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_printList___redArg(v_inst_367_, v_l_368_);
return v___x_369_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_printList_printListTail___at___00Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_printList___at___00Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_print__nat__list_spec__0_spec__0(lean_object* v_a_370_){
_start:
{
if (lean_obj_tag(v_a_370_) == 0)
{
lean_object* v___x_371_; 
v___x_371_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_instPrintableChar___lam__0___closed__0));
return v___x_371_;
}
else
{
lean_object* v_tail_372_; 
v_tail_372_ = lean_ctor_get(v_a_370_, 1);
if (lean_obj_tag(v_tail_372_) == 0)
{
lean_object* v_head_373_; lean_object* v___x_374_; 
v_head_373_ = lean_ctor_get(v_a_370_, 0);
lean_inc(v_head_373_);
lean_dec_ref_known(v_a_370_, 2);
v___x_374_ = l_Nat_reprFast(v_head_373_);
return v___x_374_;
}
else
{
lean_object* v_head_375_; lean_object* v___x_376_; lean_object* v___x_377_; lean_object* v___x_378_; lean_object* v___x_379_; lean_object* v___x_380_; 
lean_inc(v_tail_372_);
v_head_375_ = lean_ctor_get(v_a_370_, 0);
lean_inc(v_head_375_);
lean_dec_ref_known(v_a_370_, 2);
v___x_376_ = l_Nat_reprFast(v_head_375_);
v___x_377_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_printPair___redArg___closed__1));
v___x_378_ = lean_string_append(v___x_376_, v___x_377_);
v___x_379_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_printList_printListTail___at___00Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_printList___at___00Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_print__nat__list_spec__0_spec__0(v_tail_372_);
v___x_380_ = lean_string_append(v___x_378_, v___x_379_);
lean_dec_ref(v___x_379_);
return v___x_380_;
}
}
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_printList___at___00Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_print__nat__list_spec__0(lean_object* v_l_381_){
_start:
{
if (lean_obj_tag(v_l_381_) == 0)
{
lean_object* v___x_382_; 
v___x_382_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_printList___redArg___closed__0));
return v___x_382_;
}
else
{
lean_object* v_tail_383_; 
v_tail_383_ = lean_ctor_get(v_l_381_, 1);
if (lean_obj_tag(v_tail_383_) == 0)
{
lean_object* v_head_384_; lean_object* v___x_385_; lean_object* v___x_386_; lean_object* v___x_387_; lean_object* v___x_388_; lean_object* v___x_389_; 
v_head_384_ = lean_ctor_get(v_l_381_, 0);
lean_inc(v_head_384_);
lean_dec_ref_known(v_l_381_, 2);
v___x_385_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_printList___redArg___closed__1));
v___x_386_ = l_Nat_reprFast(v_head_384_);
v___x_387_ = lean_string_append(v___x_385_, v___x_386_);
lean_dec_ref(v___x_386_);
v___x_388_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_printList___redArg___closed__2));
v___x_389_ = lean_string_append(v___x_387_, v___x_388_);
return v___x_389_;
}
else
{
lean_object* v_head_390_; lean_object* v___x_391_; lean_object* v___x_392_; lean_object* v___x_393_; lean_object* v___x_394_; lean_object* v___x_395_; lean_object* v___x_396_; lean_object* v___x_397_; lean_object* v___x_398_; lean_object* v___x_399_; 
lean_inc(v_tail_383_);
v_head_390_ = lean_ctor_get(v_l_381_, 0);
lean_inc(v_head_390_);
lean_dec_ref_known(v_l_381_, 2);
v___x_391_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_printList___redArg___closed__1));
v___x_392_ = l_Nat_reprFast(v_head_390_);
v___x_393_ = lean_string_append(v___x_391_, v___x_392_);
lean_dec_ref(v___x_392_);
v___x_394_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_printPair___redArg___closed__1));
v___x_395_ = lean_string_append(v___x_393_, v___x_394_);
v___x_396_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_printList_printListTail___at___00Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_printList___at___00Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_print__nat__list_spec__0_spec__0(v_tail_383_);
v___x_397_ = lean_string_append(v___x_395_, v___x_396_);
lean_dec_ref(v___x_396_);
v___x_398_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_printList___redArg___closed__2));
v___x_399_ = lean_string_append(v___x_397_, v___x_398_);
return v___x_399_;
}
}
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_print__nat__list___closed__5(void){
_start:
{
lean_object* v___x_415_; lean_object* v___x_416_; 
v___x_415_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_print__nat__list___closed__4));
v___x_416_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_printList___at___00Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_print__nat__list_spec__0(v___x_415_);
return v___x_416_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_print__nat__list(void){
_start:
{
lean_object* v___x_417_; 
v___x_417_ = lean_obj_once(&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_print__nat__list___closed__5, &lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_print__nat__list___closed__5_once, _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_print__nat__list___closed__5);
return v___x_417_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_printList_printListTail___at___00Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_printList___at___00Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_print__bool__list_spec__0_spec__0(lean_object* v_a_418_){
_start:
{
if (lean_obj_tag(v_a_418_) == 0)
{
lean_object* v___x_419_; 
v___x_419_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_instPrintableChar___lam__0___closed__0));
return v___x_419_;
}
else
{
lean_object* v_tail_420_; 
v_tail_420_ = lean_ctor_get(v_a_418_, 1);
if (lean_obj_tag(v_tail_420_) == 0)
{
lean_object* v_head_421_; uint8_t v___x_422_; lean_object* v___x_423_; 
v_head_421_ = lean_ctor_get(v_a_418_, 0);
v___x_422_ = lean_unbox(v_head_421_);
v___x_423_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_printIt___at___00Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_print__bool_spec__0(v___x_422_);
return v___x_423_;
}
else
{
lean_object* v_head_424_; uint8_t v___x_425_; lean_object* v___x_426_; lean_object* v___x_427_; lean_object* v___x_428_; lean_object* v___x_429_; lean_object* v___x_430_; 
v_head_424_ = lean_ctor_get(v_a_418_, 0);
v___x_425_ = lean_unbox(v_head_424_);
v___x_426_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_printIt___at___00Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_print__bool_spec__0(v___x_425_);
v___x_427_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_printPair___redArg___closed__1));
v___x_428_ = lean_string_append(v___x_426_, v___x_427_);
v___x_429_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_printList_printListTail___at___00Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_printList___at___00Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_print__bool__list_spec__0_spec__0(v_tail_420_);
v___x_430_ = lean_string_append(v___x_428_, v___x_429_);
lean_dec_ref(v___x_429_);
return v___x_430_;
}
}
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_printList_printListTail___at___00Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_printList___at___00Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_print__bool__list_spec__0_spec__0___boxed(lean_object* v_a_431_){
_start:
{
lean_object* v_res_432_; 
v_res_432_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_printList_printListTail___at___00Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_printList___at___00Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_print__bool__list_spec__0_spec__0(v_a_431_);
lean_dec(v_a_431_);
return v_res_432_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_printList___at___00Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_print__bool__list_spec__0(lean_object* v_l_433_){
_start:
{
if (lean_obj_tag(v_l_433_) == 0)
{
lean_object* v___x_434_; 
v___x_434_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_printList___redArg___closed__0));
return v___x_434_;
}
else
{
lean_object* v_tail_435_; 
v_tail_435_ = lean_ctor_get(v_l_433_, 1);
if (lean_obj_tag(v_tail_435_) == 0)
{
lean_object* v_head_436_; lean_object* v___x_437_; uint8_t v___x_438_; lean_object* v___x_439_; lean_object* v___x_440_; lean_object* v___x_441_; lean_object* v___x_442_; 
v_head_436_ = lean_ctor_get(v_l_433_, 0);
v___x_437_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_printList___redArg___closed__1));
v___x_438_ = lean_unbox(v_head_436_);
v___x_439_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_printIt___at___00Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_print__bool_spec__0(v___x_438_);
v___x_440_ = lean_string_append(v___x_437_, v___x_439_);
lean_dec_ref(v___x_439_);
v___x_441_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_printList___redArg___closed__2));
v___x_442_ = lean_string_append(v___x_440_, v___x_441_);
return v___x_442_;
}
else
{
lean_object* v_head_443_; lean_object* v___x_444_; uint8_t v___x_445_; lean_object* v___x_446_; lean_object* v___x_447_; lean_object* v___x_448_; lean_object* v___x_449_; lean_object* v___x_450_; lean_object* v___x_451_; lean_object* v___x_452_; lean_object* v___x_453_; 
v_head_443_ = lean_ctor_get(v_l_433_, 0);
v___x_444_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_printList___redArg___closed__1));
v___x_445_ = lean_unbox(v_head_443_);
v___x_446_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_printIt___at___00Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_print__bool_spec__0(v___x_445_);
v___x_447_ = lean_string_append(v___x_444_, v___x_446_);
lean_dec_ref(v___x_446_);
v___x_448_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_printPair___redArg___closed__1));
v___x_449_ = lean_string_append(v___x_447_, v___x_448_);
v___x_450_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_printList_printListTail___at___00Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_printList___at___00Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_print__bool__list_spec__0_spec__0(v_tail_435_);
v___x_451_ = lean_string_append(v___x_449_, v___x_450_);
lean_dec_ref(v___x_450_);
v___x_452_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_printList___redArg___closed__2));
v___x_453_ = lean_string_append(v___x_451_, v___x_452_);
return v___x_453_;
}
}
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_printList___at___00Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_print__bool__list_spec__0___boxed(lean_object* v_l_454_){
_start:
{
lean_object* v_res_455_; 
v_res_455_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_printList___at___00Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_print__bool__list_spec__0(v_l_454_);
lean_dec(v_l_454_);
return v_res_455_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_print__bool__list___closed__3(void){
_start:
{
lean_object* v___x_468_; lean_object* v___x_469_; 
v___x_468_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_print__bool__list___closed__2));
v___x_469_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_printList___at___00Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_print__bool__list_spec__0(v___x_468_);
return v___x_469_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_print__bool__list(void){
_start:
{
lean_object* v___x_470_; 
v___x_470_ = lean_obj_once(&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_print__bool__list___closed__3, &lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_print__bool__list___closed__3_once, _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_print__bool__list___closed__3);
return v___x_470_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_instPrintableProd___redArg___lam__0(lean_object* v_inst_471_, lean_object* v_inst_472_, lean_object* v_p_473_){
_start:
{
lean_object* v_fst_474_; lean_object* v_snd_475_; lean_object* v___x_476_; lean_object* v___x_477_; lean_object* v___x_478_; lean_object* v___x_479_; lean_object* v___x_480_; lean_object* v___x_481_; lean_object* v___x_482_; lean_object* v___x_483_; lean_object* v___x_484_; 
v_fst_474_ = lean_ctor_get(v_p_473_, 0);
lean_inc(v_fst_474_);
v_snd_475_ = lean_ctor_get(v_p_473_, 1);
lean_inc(v_snd_475_);
lean_dec_ref(v_p_473_);
v___x_476_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_printPair___redArg___closed__0));
v___x_477_ = lean_apply_1(v_inst_471_, v_fst_474_);
v___x_478_ = lean_string_append(v___x_476_, v___x_477_);
lean_dec_ref(v___x_477_);
v___x_479_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_printPair___redArg___closed__1));
v___x_480_ = lean_string_append(v___x_478_, v___x_479_);
v___x_481_ = lean_apply_1(v_inst_472_, v_snd_475_);
v___x_482_ = lean_string_append(v___x_480_, v___x_481_);
lean_dec_ref(v___x_481_);
v___x_483_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_printPair___redArg___closed__2));
v___x_484_ = lean_string_append(v___x_482_, v___x_483_);
return v___x_484_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_instPrintableProd___redArg(lean_object* v_inst_485_, lean_object* v_inst_486_){
_start:
{
lean_object* v___f_487_; 
v___f_487_ = lean_alloc_closure((void*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_instPrintableProd___redArg___lam__0), 3, 2);
lean_closure_set(v___f_487_, 0, v_inst_485_);
lean_closure_set(v___f_487_, 1, v_inst_486_);
return v___f_487_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_instPrintableProd(lean_object* v_00_u03b1_488_, lean_object* v_00_u03b2_489_, lean_object* v_inst_490_, lean_object* v_inst_491_){
_start:
{
lean_object* v___f_492_; 
v___f_492_ = lean_alloc_closure((void*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_instPrintableProd___redArg___lam__0), 3, 2);
lean_closure_set(v___f_492_, 0, v_inst_490_);
lean_closure_set(v___f_492_, 1, v_inst_491_);
return v___f_492_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_printIt___at___00Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_print__pair_x27_spec__0(lean_object* v_x_493_){
_start:
{
lean_object* v_fst_494_; lean_object* v_snd_495_; lean_object* v___x_496_; lean_object* v___x_497_; lean_object* v___x_498_; lean_object* v___x_499_; lean_object* v___x_500_; lean_object* v___x_501_; lean_object* v___x_502_; lean_object* v___x_503_; 
v_fst_494_ = lean_ctor_get(v_x_493_, 0);
lean_inc(v_fst_494_);
v_snd_495_ = lean_ctor_get(v_x_493_, 1);
lean_inc(v_snd_495_);
lean_dec_ref(v_x_493_);
v___x_496_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_printPair___redArg___closed__0));
v___x_497_ = l_Nat_reprFast(v_fst_494_);
v___x_498_ = lean_string_append(v___x_496_, v___x_497_);
lean_dec_ref(v___x_497_);
v___x_499_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_printPair___redArg___closed__1));
v___x_500_ = lean_string_append(v___x_498_, v___x_499_);
v___x_501_ = lean_string_append(v___x_500_, v_snd_495_);
lean_dec(v_snd_495_);
v___x_502_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_printPair___redArg___closed__2));
v___x_503_ = lean_string_append(v___x_501_, v___x_502_);
return v___x_503_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_print__pair_x27___closed__1(void){
_start:
{
lean_object* v___x_507_; lean_object* v___x_508_; 
v___x_507_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_print__pair_x27___closed__0));
v___x_508_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_printIt___at___00Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_print__pair_x27_spec__0(v___x_507_);
return v___x_508_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_print__pair_x27(void){
_start:
{
lean_object* v___x_509_; 
v___x_509_ = lean_obj_once(&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_print__pair_x27___closed__1, &lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_print__pair_x27___closed__1_once, _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_print__pair_x27___closed__1);
return v___x_509_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_printIt___at___00Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_printIt___at___00Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_print__nested_spec__0_spec__0(lean_object* v_x_510_){
_start:
{
lean_object* v_fst_511_; lean_object* v_snd_512_; lean_object* v___x_513_; lean_object* v___x_514_; lean_object* v___x_515_; lean_object* v___x_516_; lean_object* v___x_517_; lean_object* v___x_518_; lean_object* v___x_519_; lean_object* v___x_520_; lean_object* v___x_521_; 
v_fst_511_ = lean_ctor_get(v_x_510_, 0);
lean_inc(v_fst_511_);
v_snd_512_ = lean_ctor_get(v_x_510_, 1);
lean_inc(v_snd_512_);
lean_dec_ref(v_x_510_);
v___x_513_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_printPair___redArg___closed__0));
v___x_514_ = l_Nat_reprFast(v_fst_511_);
v___x_515_ = lean_string_append(v___x_513_, v___x_514_);
lean_dec_ref(v___x_514_);
v___x_516_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_printPair___redArg___closed__1));
v___x_517_ = lean_string_append(v___x_515_, v___x_516_);
v___x_518_ = l_Nat_reprFast(v_snd_512_);
v___x_519_ = lean_string_append(v___x_517_, v___x_518_);
lean_dec_ref(v___x_518_);
v___x_520_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_printPair___redArg___closed__2));
v___x_521_ = lean_string_append(v___x_519_, v___x_520_);
return v___x_521_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_printIt___at___00Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_print__nested_spec__0(lean_object* v_x_522_){
_start:
{
lean_object* v_fst_523_; lean_object* v_snd_524_; lean_object* v___x_525_; lean_object* v___x_526_; lean_object* v___x_527_; lean_object* v___x_528_; lean_object* v___x_529_; lean_object* v___x_530_; lean_object* v___x_531_; lean_object* v___x_532_; lean_object* v___x_533_; 
v_fst_523_ = lean_ctor_get(v_x_522_, 0);
lean_inc(v_fst_523_);
v_snd_524_ = lean_ctor_get(v_x_522_, 1);
lean_inc(v_snd_524_);
lean_dec_ref(v_x_522_);
v___x_525_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_printPair___redArg___closed__0));
v___x_526_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_printIt___at___00Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_printIt___at___00Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_print__nested_spec__0_spec__0(v_fst_523_);
v___x_527_ = lean_string_append(v___x_525_, v___x_526_);
lean_dec_ref(v___x_526_);
v___x_528_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_printPair___redArg___closed__1));
v___x_529_ = lean_string_append(v___x_527_, v___x_528_);
v___x_530_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_printIt___at___00Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_printIt___at___00Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_print__nested_spec__0_spec__0(v_snd_524_);
v___x_531_ = lean_string_append(v___x_529_, v___x_530_);
lean_dec_ref(v___x_530_);
v___x_532_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_printPair___redArg___closed__2));
v___x_533_ = lean_string_append(v___x_531_, v___x_532_);
return v___x_533_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_print__nested___closed__3(void){
_start:
{
lean_object* v___x_543_; lean_object* v___x_544_; 
v___x_543_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_print__nested___closed__2));
v___x_544_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_printIt___at___00Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_print__nested_spec__0(v___x_543_);
return v___x_544_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_print__nested(void){
_start:
{
lean_object* v___x_545_; 
v___x_545_ = lean_obj_once(&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_print__nested___closed__3, &lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_print__nested___closed__3_once, _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_print__nested___closed__3);
return v___x_545_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_instPrintableList___redArg___lam__0(lean_object* v_inst_546_, lean_object* v_l_547_){
_start:
{
lean_object* v___x_548_; 
v___x_548_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_printList___redArg(v_inst_546_, v_l_547_);
return v___x_548_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_instPrintableList___redArg(lean_object* v_inst_549_){
_start:
{
lean_object* v___f_550_; 
v___f_550_ = lean_alloc_closure((void*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_instPrintableList___redArg___lam__0), 2, 1);
lean_closure_set(v___f_550_, 0, v_inst_549_);
return v___f_550_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_instPrintableList(lean_object* v_00_u03b1_551_, lean_object* v_inst_552_){
_start:
{
lean_object* v___f_553_; 
v___f_553_ = lean_alloc_closure((void*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_instPrintableList___redArg___lam__0), 2, 1);
lean_closure_set(v___f_553_, 0, v_inst_552_);
return v___f_553_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_printList_printListTail___at___00Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_printList___at___00Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_printIt___at___00Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_print__list__of__lists_spec__0_spec__0_spec__2(lean_object* v_a_554_){
_start:
{
if (lean_obj_tag(v_a_554_) == 0)
{
lean_object* v___x_555_; 
v___x_555_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_instPrintableChar___lam__0___closed__0));
return v___x_555_;
}
else
{
lean_object* v_tail_556_; 
v_tail_556_ = lean_ctor_get(v_a_554_, 1);
if (lean_obj_tag(v_tail_556_) == 0)
{
lean_object* v_head_557_; lean_object* v___x_558_; 
v_head_557_ = lean_ctor_get(v_a_554_, 0);
lean_inc(v_head_557_);
lean_dec_ref_known(v_a_554_, 2);
v___x_558_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_printList___at___00Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_print__nat__list_spec__0(v_head_557_);
return v___x_558_;
}
else
{
lean_object* v_head_559_; lean_object* v___x_560_; lean_object* v___x_561_; lean_object* v___x_562_; lean_object* v___x_563_; lean_object* v___x_564_; 
lean_inc(v_tail_556_);
v_head_559_ = lean_ctor_get(v_a_554_, 0);
lean_inc(v_head_559_);
lean_dec_ref_known(v_a_554_, 2);
v___x_560_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_printList___at___00Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_print__nat__list_spec__0(v_head_559_);
v___x_561_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_printPair___redArg___closed__1));
v___x_562_ = lean_string_append(v___x_560_, v___x_561_);
v___x_563_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_printList_printListTail___at___00Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_printList___at___00Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_printIt___at___00Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_print__list__of__lists_spec__0_spec__0_spec__2(v_tail_556_);
v___x_564_ = lean_string_append(v___x_562_, v___x_563_);
lean_dec_ref(v___x_563_);
return v___x_564_;
}
}
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_printList___at___00Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_printIt___at___00Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_print__list__of__lists_spec__0_spec__0(lean_object* v_l_565_){
_start:
{
if (lean_obj_tag(v_l_565_) == 0)
{
lean_object* v___x_566_; 
v___x_566_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_printList___redArg___closed__0));
return v___x_566_;
}
else
{
lean_object* v_tail_567_; 
v_tail_567_ = lean_ctor_get(v_l_565_, 1);
if (lean_obj_tag(v_tail_567_) == 0)
{
lean_object* v_head_568_; lean_object* v___x_569_; lean_object* v___x_570_; lean_object* v___x_571_; lean_object* v___x_572_; lean_object* v___x_573_; 
v_head_568_ = lean_ctor_get(v_l_565_, 0);
lean_inc(v_head_568_);
lean_dec_ref_known(v_l_565_, 2);
v___x_569_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_printList___redArg___closed__1));
v___x_570_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_printList___at___00Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_print__nat__list_spec__0(v_head_568_);
v___x_571_ = lean_string_append(v___x_569_, v___x_570_);
lean_dec_ref(v___x_570_);
v___x_572_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_printList___redArg___closed__2));
v___x_573_ = lean_string_append(v___x_571_, v___x_572_);
return v___x_573_;
}
else
{
lean_object* v_head_574_; lean_object* v___x_575_; lean_object* v___x_576_; lean_object* v___x_577_; lean_object* v___x_578_; lean_object* v___x_579_; lean_object* v___x_580_; lean_object* v___x_581_; lean_object* v___x_582_; lean_object* v___x_583_; 
lean_inc(v_tail_567_);
v_head_574_ = lean_ctor_get(v_l_565_, 0);
lean_inc(v_head_574_);
lean_dec_ref_known(v_l_565_, 2);
v___x_575_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_printList___redArg___closed__1));
v___x_576_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_printList___at___00Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_print__nat__list_spec__0(v_head_574_);
v___x_577_ = lean_string_append(v___x_575_, v___x_576_);
lean_dec_ref(v___x_576_);
v___x_578_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_printPair___redArg___closed__1));
v___x_579_ = lean_string_append(v___x_577_, v___x_578_);
v___x_580_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_printList_printListTail___at___00Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_printList___at___00Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_printIt___at___00Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_print__list__of__lists_spec__0_spec__0_spec__2(v_tail_567_);
v___x_581_ = lean_string_append(v___x_579_, v___x_580_);
lean_dec_ref(v___x_580_);
v___x_582_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_printList___redArg___closed__2));
v___x_583_ = lean_string_append(v___x_581_, v___x_582_);
return v___x_583_;
}
}
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_print__list__of__lists___closed__7(void){
_start:
{
lean_object* v___x_605_; lean_object* v___x_606_; 
v___x_605_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_print__list__of__lists___closed__6));
v___x_606_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_printList___at___00Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_printIt___at___00Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_print__list__of__lists_spec__0_spec__0(v___x_605_);
return v___x_606_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_print__list__of__lists(void){
_start:
{
lean_object* v___x_607_; 
v___x_607_ = lean_obj_once(&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_print__list__of__lists___closed__7, &lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_print__list__of__lists___closed__7_once, _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_print__list__of__lists___closed__7);
return v___x_607_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_printIt___at___00Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_print__list__of__lists_spec__0(lean_object* v_x_608_){
_start:
{
lean_object* v___x_609_; 
v___x_609_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_printList___at___00Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_printIt___at___00Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_print__list__of__lists_spec__0_spec__0(v_x_608_);
return v___x_609_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_printIt___at___00Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_printList___at___00Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_printIt___at___00Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_print__list__of__lists_spec__0_spec__0_spec__1(lean_object* v_x_610_){
_start:
{
lean_object* v___x_611_; 
v___x_611_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_printList___at___00Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_print__nat__list_spec__0(v_x_610_);
return v___x_611_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_instReadablePrintableNat___lam__0(lean_object* v_s_612_){
_start:
{
lean_object* v___x_613_; lean_object* v___x_614_; lean_object* v___x_615_; lean_object* v___x_616_; 
v___x_613_ = lean_unsigned_to_nat(0u);
v___x_614_ = lean_string_utf8_byte_size(v_s_612_);
v___x_615_ = lean_alloc_ctor(0, 3, 0);
lean_ctor_set(v___x_615_, 0, v_s_612_);
lean_ctor_set(v___x_615_, 1, v___x_613_);
lean_ctor_set(v___x_615_, 2, v___x_614_);
v___x_616_ = l_String_Slice_toNat_x3f(v___x_615_);
lean_dec_ref_known(v___x_615_, 3);
return v___x_616_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_parse__nat___closed__0(void){
_start:
{
lean_object* v___x_622_; lean_object* v___x_623_; 
v___x_622_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_print__nat___closed__0));
v___x_623_ = lean_string_utf8_byte_size(v___x_622_);
return v___x_623_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_parse__nat___closed__1(void){
_start:
{
lean_object* v___x_624_; lean_object* v___x_625_; lean_object* v___x_626_; lean_object* v___x_627_; 
v___x_624_ = lean_obj_once(&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_parse__nat___closed__0, &lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_parse__nat___closed__0_once, _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_parse__nat___closed__0);
v___x_625_ = lean_unsigned_to_nat(0u);
v___x_626_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_print__nat___closed__0));
v___x_627_ = lean_alloc_ctor(0, 3, 0);
lean_ctor_set(v___x_627_, 0, v___x_626_);
lean_ctor_set(v___x_627_, 1, v___x_625_);
lean_ctor_set(v___x_627_, 2, v___x_624_);
return v___x_627_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_parse__nat___closed__2(void){
_start:
{
lean_object* v___x_628_; lean_object* v___x_629_; 
v___x_628_ = lean_obj_once(&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_parse__nat___closed__1, &lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_parse__nat___closed__1_once, _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_parse__nat___closed__1);
v___x_629_ = l_String_Slice_toNat_x3f(v___x_628_);
return v___x_629_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_parse__nat(void){
_start:
{
lean_object* v___x_630_; 
v___x_630_ = lean_obj_once(&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_parse__nat___closed__2, &lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_parse__nat___closed__2_once, _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_parse__nat___closed__2);
return v___x_630_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_parse__fail___closed__1(void){
_start:
{
lean_object* v___x_632_; lean_object* v___x_633_; 
v___x_632_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_parse__fail___closed__0));
v___x_633_ = lean_string_utf8_byte_size(v___x_632_);
return v___x_633_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_parse__fail___closed__2(void){
_start:
{
lean_object* v___x_634_; lean_object* v___x_635_; lean_object* v___x_636_; lean_object* v___x_637_; 
v___x_634_ = lean_obj_once(&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_parse__fail___closed__1, &lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_parse__fail___closed__1_once, _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_parse__fail___closed__1);
v___x_635_ = lean_unsigned_to_nat(0u);
v___x_636_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_parse__fail___closed__0));
v___x_637_ = lean_alloc_ctor(0, 3, 0);
lean_ctor_set(v___x_637_, 0, v___x_636_);
lean_ctor_set(v___x_637_, 1, v___x_635_);
lean_ctor_set(v___x_637_, 2, v___x_634_);
return v___x_637_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_parse__fail___closed__3(void){
_start:
{
lean_object* v___x_638_; lean_object* v___x_639_; 
v___x_638_ = lean_obj_once(&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_parse__fail___closed__2, &lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_parse__fail___closed__2_once, _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_parse__fail___closed__2);
v___x_639_ = l_String_Slice_toNat_x3f(v___x_638_);
return v___x_639_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_parse__fail(void){
_start:
{
lean_object* v___x_640_; 
v___x_640_ = lean_obj_once(&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_parse__fail___closed__3, &lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_parse__fail___closed__3_once, _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_parse__fail___closed__3);
return v___x_640_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_print__via__readable___redArg(lean_object* v_inst_641_, lean_object* v_x_642_){
_start:
{
lean_object* v_toPrintable_643_; lean_object* v___x_644_; 
v_toPrintable_643_ = lean_ctor_get(v_inst_641_, 0);
lean_inc_ref(v_toPrintable_643_);
lean_dec_ref(v_inst_641_);
v___x_644_ = lean_apply_1(v_toPrintable_643_, v_x_642_);
return v___x_644_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_print__via__readable(lean_object* v_00_u03b1_645_, lean_object* v_inst_646_, lean_object* v_x_647_){
_start:
{
lean_object* v___x_648_; 
v___x_648_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_print__via__readable___redArg(v_inst_646_, v_x_647_);
return v___x_648_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_printIt___at___00Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_print__via__readable___at___00Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_print__42_spec__0_spec__0(lean_object* v_x_650_){
_start:
{
lean_object* v___x_651_; 
v___x_651_ = l_Nat_reprFast(v_x_650_);
return v___x_651_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_print__via__readable___at___00Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_print__42_spec__0(lean_object* v_x_652_){
_start:
{
lean_object* v___x_653_; 
v___x_653_ = l_Nat_reprFast(v_x_652_);
return v___x_653_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_direct__print___redArg(lean_object* v_inst_654_, lean_object* v_x_655_){
_start:
{
lean_object* v___x_656_; 
v___x_656_ = lean_apply_1(v_inst_654_, v_x_655_);
return v___x_656_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_direct__print(lean_object* v_00_u03b1_657_, lean_object* v_inst_658_, lean_object* v_x_659_){
_start:
{
lean_object* v___x_660_; 
v___x_660_ = lean_apply_1(v_inst_658_, v_x_659_);
return v___x_660_;
}
}
LEAN_EXPORT uint8_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_comparePrint___redArg(lean_object* v_inst_661_, lean_object* v_inst_662_, lean_object* v_x_663_, lean_object* v_y_664_){
_start:
{
lean_object* v___x_665_; lean_object* v___x_666_; uint8_t v___x_667_; 
v___x_665_ = lean_apply_1(v_inst_661_, v_x_663_);
v___x_666_ = lean_apply_1(v_inst_662_, v_y_664_);
v___x_667_ = lean_string_compare(v___x_665_, v___x_666_);
lean_dec_ref(v___x_666_);
lean_dec_ref(v___x_665_);
return v___x_667_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_comparePrint___redArg___boxed(lean_object* v_inst_668_, lean_object* v_inst_669_, lean_object* v_x_670_, lean_object* v_y_671_){
_start:
{
uint8_t v_res_672_; lean_object* v_r_673_; 
v_res_672_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_comparePrint___redArg(v_inst_668_, v_inst_669_, v_x_670_, v_y_671_);
v_r_673_ = lean_box(v_res_672_);
return v_r_673_;
}
}
LEAN_EXPORT uint8_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_comparePrint(lean_object* v_00_u03b1_674_, lean_object* v_00_u03b2_675_, lean_object* v_inst_676_, lean_object* v_inst_677_, lean_object* v_x_678_, lean_object* v_y_679_){
_start:
{
uint8_t v___x_680_; 
v___x_680_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_comparePrint___redArg(v_inst_676_, v_inst_677_, v_x_678_, v_y_679_);
return v___x_680_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_comparePrint___boxed(lean_object* v_00_u03b1_681_, lean_object* v_00_u03b2_682_, lean_object* v_inst_683_, lean_object* v_inst_684_, lean_object* v_x_685_, lean_object* v_y_686_){
_start:
{
uint8_t v_res_687_; lean_object* v_r_688_; 
v_res_687_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_comparePrint(v_00_u03b1_681_, v_00_u03b2_682_, v_inst_683_, v_inst_684_, v_x_685_, v_y_686_);
v_r_688_ = lean_box(v_res_687_);
return v_r_688_;
}
}
LEAN_EXPORT uint8_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_comparePrint___at___00Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_cmp__result_spec__0(lean_object* v_x_689_, lean_object* v_y_690_){
_start:
{
lean_object* v___x_691_; lean_object* v___x_692_; uint8_t v___x_693_; 
v___x_691_ = l_Nat_reprFast(v_x_689_);
v___x_692_ = l_Nat_reprFast(v_y_690_);
v___x_693_ = lean_string_compare(v___x_691_, v___x_692_);
lean_dec_ref(v___x_692_);
lean_dec_ref(v___x_691_);
return v___x_693_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_comparePrint___at___00Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_cmp__result_spec__0___boxed(lean_object* v_x_694_, lean_object* v_y_695_){
_start:
{
uint8_t v_res_696_; lean_object* v_r_697_; 
v_res_696_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_comparePrint___at___00Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_cmp__result_spec__0(v_x_694_, v_y_695_);
v_r_697_ = lean_box(v_res_696_);
return v_r_697_;
}
}
static uint8_t _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_cmp__result___closed__0(void){
_start:
{
lean_object* v___x_698_; lean_object* v___x_699_; uint8_t v___x_700_; 
v___x_698_ = lean_unsigned_to_nat(2u);
v___x_699_ = lean_unsigned_to_nat(10u);
v___x_700_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_comparePrint___at___00Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_cmp__result_spec__0(v___x_699_, v___x_698_);
return v___x_700_;
}
}
static uint8_t _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_cmp__result(void){
_start:
{
uint8_t v___x_701_; 
v___x_701_ = lean_uint8_once(&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_cmp__result___closed__0, &lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_cmp__result___closed__0_once, _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_cmp__result___closed__0);
return v___x_701_;
}
}
LEAN_EXPORT uint8_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_instComparableNat___lam__0(lean_object* v_x_702_, lean_object* v_y_703_){
_start:
{
uint8_t v___x_704_; 
v___x_704_ = lean_nat_dec_lt(v_x_702_, v_y_703_);
if (v___x_704_ == 0)
{
uint8_t v___x_705_; 
v___x_705_ = lean_nat_dec_lt(v_y_703_, v_x_702_);
if (v___x_705_ == 0)
{
uint8_t v___x_706_; 
v___x_706_ = 1;
return v___x_706_;
}
else
{
uint8_t v___x_707_; 
v___x_707_ = 2;
return v___x_707_;
}
}
else
{
uint8_t v___x_708_; 
v___x_708_ = 0;
return v___x_708_;
}
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_instComparableNat___lam__0___boxed(lean_object* v_x_709_, lean_object* v_y_710_){
_start:
{
uint8_t v_res_711_; lean_object* v_r_712_; 
v_res_711_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_instComparableNat___lam__0(v_x_709_, v_y_710_);
lean_dec(v_y_710_);
lean_dec(v_x_709_);
v_r_712_ = lean_box(v_res_711_);
return v_r_712_;
}
}
static uint8_t _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_cmp__nat(void){
_start:
{
uint8_t v___x_715_; 
v___x_715_ = 0;
return v___x_715_;
}
}
lean_object* initialize_Init(uint8_t builtin);
lean_object* initialize_Init(uint8_t builtin);
static bool _G_initialized = false;
LEAN_EXPORT lean_object* initialize_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics(uint8_t builtin) {
lean_object * res;
if (_G_initialized) return lean_io_result_mk_ok(lean_box(0));
_G_initialized = true;
res = initialize_Init(builtin);
if (lean_io_result_is_error(res)) return res;
lean_dec_ref(res);
res = initialize_Init(builtin);
if (lean_io_result_is_error(res)) return res;
lean_dec_ref(res);
lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_print__bool = _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_print__bool();
lean_mark_persistent(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_print__bool);
lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_print__char = _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_print__char();
lean_mark_persistent(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_print__char);
lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_print__pair = _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_print__pair();
lean_mark_persistent(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_print__pair);
lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_bool__to__nat = _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_bool__to__nat();
lean_mark_persistent(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_bool__to__nat);
lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_describe__alice = _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_describe__alice();
lean_mark_persistent(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_describe__alice);
lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_name__alice = _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_name__alice();
lean_mark_persistent(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_name__alice);
lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_describe__book = _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_describe__book();
lean_mark_persistent(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_describe__book);
lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_name__book = _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_name__book();
lean_mark_persistent(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_name__book);
lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_print__nat__list = _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_print__nat__list();
lean_mark_persistent(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_print__nat__list);
lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_print__bool__list = _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_print__bool__list();
lean_mark_persistent(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_print__bool__list);
lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_print__pair_x27 = _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_print__pair_x27();
lean_mark_persistent(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_print__pair_x27);
lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_print__nested = _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_print__nested();
lean_mark_persistent(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_print__nested);
lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_print__list__of__lists = _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_print__list__of__lists();
lean_mark_persistent(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_print__list__of__lists);
lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_parse__nat = _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_parse__nat();
lean_mark_persistent(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_parse__nat);
lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_parse__fail = _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_parse__fail();
lean_mark_persistent(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_parse__fail);
lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_cmp__result = _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_cmp__result();
lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_cmp__nat = _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Typeclasses_TypeclassBasics_cmp__nat();
return lean_io_result_mk_ok(lean_box(0));
}
#ifdef __cplusplus
}
#endif
