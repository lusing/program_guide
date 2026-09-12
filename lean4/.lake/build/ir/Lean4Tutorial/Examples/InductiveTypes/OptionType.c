// Lean compiler output
// Module: Lean4Tutorial.Examples.InductiveTypes.OptionType
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
lean_object* l_String_mapAux___at___00__private_Init_System_Uri_0__System_Uri_UriEscape_uriEscapeAsciiChar_uInt8ToHex_spec__0(lean_object*, lean_object*);
lean_object* lean_string_utf8_byte_size(lean_object*);
uint8_t lean_nat_dec_eq(lean_object*, lean_object*);
lean_object* l_String_Slice_Pos_get_x3f(lean_object*, lean_object*);
lean_object* l_String_Slice_toNat_x3f(lean_object*);
uint8_t lean_nat_dec_lt(lean_object*, lean_object*);
lean_object* lean_nat_div(lean_object*, lean_object*);
lean_object* lean_nat_sub(lean_object*, lean_object*);
lean_object* lean_nat_mul(lean_object*, lean_object*);
lean_object* lean_nat_to_int(lean_object*);
uint8_t lean_int_dec_lt(lean_object*, lean_object*);
lean_object* l_Nat_add___boxed(lean_object*, lean_object*);
lean_object* l_Nat_reprFast(lean_object*);
lean_object* lean_string_append(lean_object*, lean_object*);
lean_object* lean_int_neg(lean_object*);
static const lean_ctor_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_OptionType_some__number___closed__0_value = {.m_header = {.m_rc = 0, .m_cs_sz = sizeof(lean_ctor_object) + sizeof(void*)*1 + 0, .m_other = 1, .m_tag = 1}, .m_objs = {((lean_object*)(((size_t)(42) << 1) | 1))}};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_OptionType_some__number___closed__0 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_OptionType_some__number___closed__0_value;
LEAN_EXPORT const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_OptionType_some__number = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_OptionType_some__number___closed__0_value;
static const lean_string_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_OptionType_some__string___closed__0_value = {.m_header = {.m_rc = 0, .m_cs_sz = 0, .m_other = 0, .m_tag = 249}, .m_size = 6, .m_capacity = 6, .m_length = 5, .m_data = "hello"};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_OptionType_some__string___closed__0 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_OptionType_some__string___closed__0_value;
static const lean_ctor_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_OptionType_some__string___closed__1_value = {.m_header = {.m_rc = 0, .m_cs_sz = sizeof(lean_ctor_object) + sizeof(void*)*1 + 0, .m_other = 1, .m_tag = 1}, .m_objs = {((lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_OptionType_some__string___closed__0_value)}};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_OptionType_some__string___closed__1 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_OptionType_some__string___closed__1_value;
LEAN_EXPORT const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_OptionType_some__string = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_OptionType_some__string___closed__1_value;
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_OptionType_no__number;
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_OptionType_no__string;
LEAN_EXPORT uint8_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_OptionType_is__some__example;
LEAN_EXPORT uint8_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_OptionType_is__none__example;
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_OptionType_get__or__zero;
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_OptionType_get__default;
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_OptionType_double(lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_OptionType_double___boxed(lean_object*);
static lean_once_cell_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_OptionType_map__some___closed__0_once = LEAN_ONCE_CELL_INITIALIZER;
static lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_OptionType_map__some___closed__0;
static lean_once_cell_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_OptionType_map__some___closed__1_once = LEAN_ONCE_CELL_INITIALIZER;
static lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_OptionType_map__some___closed__1;
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_OptionType_map__some;
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_OptionType_map__none;
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_OptionType_map__some_x27;
static lean_once_cell_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_OptionType_map__string___closed__0_once = LEAN_ONCE_CELL_INITIALIZER;
static lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_OptionType_map__string___closed__0;
static lean_once_cell_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_OptionType_map__string___closed__1_once = LEAN_ONCE_CELL_INITIALIZER;
static lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_OptionType_map__string___closed__1;
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_OptionType_map__string;
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_OptionType_map__none__string;
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_OptionType_safeDiv(lean_object*, lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_OptionType_safeDiv___boxed(lean_object*, lean_object*);
static lean_once_cell_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_OptionType_chain__div___closed__0_once = LEAN_ONCE_CELL_INITIALIZER;
static lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_OptionType_chain__div___closed__0;
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_OptionType_chain__div;
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_OptionType_chain__div__do;
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_OptionType_chain__div__fail;
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_OptionType_listGet_x3f___redArg(lean_object*, lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_OptionType_listGet_x3f___redArg___boxed(lean_object*, lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_OptionType_listGet_x3f(lean_object*, lean_object*, lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_OptionType_listGet_x3f___boxed(lean_object*, lean_object*, lean_object*);
static const lean_ctor_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_OptionType_myList___closed__0_value = {.m_header = {.m_rc = 0, .m_cs_sz = sizeof(lean_ctor_object) + sizeof(void*)*2 + 0, .m_other = 2, .m_tag = 1}, .m_objs = {((lean_object*)(((size_t)(5) << 1) | 1)),((lean_object*)(((size_t)(0) << 1) | 1))}};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_OptionType_myList___closed__0 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_OptionType_myList___closed__0_value;
static const lean_ctor_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_OptionType_myList___closed__1_value = {.m_header = {.m_rc = 0, .m_cs_sz = sizeof(lean_ctor_object) + sizeof(void*)*2 + 0, .m_other = 2, .m_tag = 1}, .m_objs = {((lean_object*)(((size_t)(4) << 1) | 1)),((lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_OptionType_myList___closed__0_value)}};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_OptionType_myList___closed__1 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_OptionType_myList___closed__1_value;
static const lean_ctor_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_OptionType_myList___closed__2_value = {.m_header = {.m_rc = 0, .m_cs_sz = sizeof(lean_ctor_object) + sizeof(void*)*2 + 0, .m_other = 2, .m_tag = 1}, .m_objs = {((lean_object*)(((size_t)(3) << 1) | 1)),((lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_OptionType_myList___closed__1_value)}};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_OptionType_myList___closed__2 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_OptionType_myList___closed__2_value;
static const lean_ctor_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_OptionType_myList___closed__3_value = {.m_header = {.m_rc = 0, .m_cs_sz = sizeof(lean_ctor_object) + sizeof(void*)*2 + 0, .m_other = 2, .m_tag = 1}, .m_objs = {((lean_object*)(((size_t)(2) << 1) | 1)),((lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_OptionType_myList___closed__2_value)}};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_OptionType_myList___closed__3 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_OptionType_myList___closed__3_value;
static const lean_ctor_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_OptionType_myList___closed__4_value = {.m_header = {.m_rc = 0, .m_cs_sz = sizeof(lean_ctor_object) + sizeof(void*)*2 + 0, .m_other = 2, .m_tag = 1}, .m_objs = {((lean_object*)(((size_t)(1) << 1) | 1)),((lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_OptionType_myList___closed__3_value)}};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_OptionType_myList___closed__4 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_OptionType_myList___closed__4_value;
LEAN_EXPORT const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_OptionType_myList = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_OptionType_myList___closed__4_value;
static lean_once_cell_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_OptionType_get__third___closed__0_once = LEAN_ONCE_CELL_INITIALIZER;
static lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_OptionType_get__third___closed__0;
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_OptionType_get__third;
static lean_once_cell_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_OptionType_get__tenth___closed__0_once = LEAN_ONCE_CELL_INITIALIZER;
static lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_OptionType_get__tenth___closed__0;
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_OptionType_get__tenth;
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_OptionType_first__char__of(lean_object*);
static const lean_string_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_OptionType_first__hello___closed__0_value = {.m_header = {.m_rc = 0, .m_cs_sz = 0, .m_other = 0, .m_tag = 249}, .m_size = 6, .m_capacity = 6, .m_length = 5, .m_data = "Hello"};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_OptionType_first__hello___closed__0 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_OptionType_first__hello___closed__0_value;
static lean_once_cell_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_OptionType_first__hello___closed__1_once = LEAN_ONCE_CELL_INITIALIZER;
static lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_OptionType_first__hello___closed__1;
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_OptionType_first__hello;
static const lean_string_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_OptionType_first__empty___closed__0_value = {.m_header = {.m_rc = 0, .m_cs_sz = 0, .m_other = 0, .m_tag = 249}, .m_size = 1, .m_capacity = 1, .m_length = 0, .m_data = ""};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_OptionType_first__empty___closed__0 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_OptionType_first__empty___closed__0_value;
static lean_once_cell_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_OptionType_first__empty___closed__1_once = LEAN_ONCE_CELL_INITIALIZER;
static lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_OptionType_first__empty___closed__1;
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_OptionType_first__empty;
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_OptionType_parseNat(lean_object*);
static const lean_string_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_OptionType_parse__42___closed__0_value = {.m_header = {.m_rc = 0, .m_cs_sz = 0, .m_other = 0, .m_tag = 249}, .m_size = 3, .m_capacity = 3, .m_length = 2, .m_data = "42"};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_OptionType_parse__42___closed__0 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_OptionType_parse__42___closed__0_value;
static lean_once_cell_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_OptionType_parse__42___closed__1_once = LEAN_ONCE_CELL_INITIALIZER;
static lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_OptionType_parse__42___closed__1;
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_OptionType_parse__42;
static const lean_string_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_OptionType_parse__abc___closed__0_value = {.m_header = {.m_rc = 0, .m_cs_sz = 0, .m_other = 0, .m_tag = 249}, .m_size = 4, .m_capacity = 4, .m_length = 3, .m_data = "abc"};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_OptionType_parse__abc___closed__0 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_OptionType_parse__abc___closed__0_value;
static lean_once_cell_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_OptionType_parse__abc___closed__1_once = LEAN_ONCE_CELL_INITIALIZER;
static lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_OptionType_parse__abc___closed__1;
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_OptionType_parse__abc;
static const lean_string_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_OptionType_optionToString___closed__0_value = {.m_header = {.m_rc = 0, .m_cs_sz = 0, .m_other = 0, .m_tag = 249}, .m_size = 10, .m_capacity = 10, .m_length = 3, .m_data = "没有值"};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_OptionType_optionToString___closed__0 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_OptionType_optionToString___closed__0_value;
static const lean_string_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_OptionType_optionToString___closed__1_value = {.m_header = {.m_rc = 0, .m_cs_sz = 0, .m_other = 0, .m_tag = 249}, .m_size = 8, .m_capacity = 8, .m_length = 3, .m_data = "值为 "};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_OptionType_optionToString___closed__1 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_OptionType_optionToString___closed__1_value;
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_OptionType_optionToString(lean_object*);
static lean_once_cell_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_OptionType_str1___closed__0_once = LEAN_ONCE_CELL_INITIALIZER;
static lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_OptionType_str1___closed__0;
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_OptionType_str1;
static lean_once_cell_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_OptionType_str2___closed__0_once = LEAN_ONCE_CELL_INITIALIZER;
static lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_OptionType_str2___closed__0;
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_OptionType_str2;
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_OptionType_doubleOption(lean_object*);
static const lean_ctor_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_OptionType_double__some___closed__0_value = {.m_header = {.m_rc = 0, .m_cs_sz = sizeof(lean_ctor_object) + sizeof(void*)*1 + 0, .m_other = 1, .m_tag = 1}, .m_objs = {((lean_object*)(((size_t)(5) << 1) | 1))}};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_OptionType_double__some___closed__0 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_OptionType_double__some___closed__0_value;
static lean_once_cell_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_OptionType_double__some___closed__1_once = LEAN_ONCE_CELL_INITIALIZER;
static lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_OptionType_double__some___closed__1;
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_OptionType_double__some;
static lean_once_cell_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_OptionType_double__none___closed__0_once = LEAN_ONCE_CELL_INITIALIZER;
static lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_OptionType_double__none___closed__0;
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_OptionType_double__none;
LEAN_EXPORT const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_OptionType_or__else1 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_OptionType_double__some___closed__0_value;
static const lean_ctor_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_OptionType_or__else2___closed__0_value = {.m_header = {.m_rc = 0, .m_cs_sz = sizeof(lean_ctor_object) + sizeof(void*)*1 + 0, .m_other = 1, .m_tag = 1}, .m_objs = {((lean_object*)(((size_t)(10) << 1) | 1))}};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_OptionType_or__else2___closed__0 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_OptionType_or__else2___closed__0_value;
LEAN_EXPORT const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_OptionType_or__else2 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_OptionType_or__else2___closed__0_value;
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_OptionType_or__else3;
LEAN_EXPORT const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_OptionType_or__else__op = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_OptionType_some__number___closed__0_value;
static lean_once_cell_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_OptionType_guard__pos___closed__0_once = LEAN_ONCE_CELL_INITIALIZER;
static lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_OptionType_guard__pos___closed__0;
static const lean_ctor_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_OptionType_guard__pos___closed__1_value = {.m_header = {.m_rc = 0, .m_cs_sz = sizeof(lean_ctor_object) + sizeof(void*)*1 + 0, .m_other = 1, .m_tag = 1}, .m_objs = {((lean_object*)(((size_t)(0) << 1) | 1))}};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_OptionType_guard__pos___closed__1 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_OptionType_guard__pos___closed__1_value;
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_OptionType_guard__pos(lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_OptionType_guard__pos___boxed(lean_object*);
static lean_once_cell_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_OptionType_guard__5___closed__0_once = LEAN_ONCE_CELL_INITIALIZER;
static lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_OptionType_guard__5___closed__0;
static lean_once_cell_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_OptionType_guard__5___closed__1_once = LEAN_ONCE_CELL_INITIALIZER;
static lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_OptionType_guard__5___closed__1;
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_OptionType_guard__5;
static lean_once_cell_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_OptionType_guard__neg___closed__0_once = LEAN_ONCE_CELL_INITIALIZER;
static lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_OptionType_guard__neg___closed__0;
static lean_once_cell_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_OptionType_guard__neg___closed__1_once = LEAN_ONCE_CELL_INITIALIZER;
static lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_OptionType_guard__neg___closed__1;
static lean_once_cell_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_OptionType_guard__neg___closed__2_once = LEAN_ONCE_CELL_INITIALIZER;
static lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_OptionType_guard__neg___closed__2;
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_OptionType_guard__neg;
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_OptionType_map2___redArg(lean_object*, lean_object*, lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_OptionType_map2(lean_object*, lean_object*, lean_object*, lean_object*, lean_object*, lean_object*);
static const lean_closure_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_OptionType_add__options___closed__0_value = {.m_header = {.m_rc = 0, .m_cs_sz = sizeof(lean_closure_object) + sizeof(void*)*0, .m_other = 0, .m_tag = 245}, .m_fun = (void*)l_Nat_add___boxed, .m_arity = 2, .m_num_fixed = 0, .m_objs = {} };
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_OptionType_add__options___closed__0 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_OptionType_add__options___closed__0_value;
static const lean_ctor_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_OptionType_add__options___closed__1_value = {.m_header = {.m_rc = 0, .m_cs_sz = sizeof(lean_ctor_object) + sizeof(void*)*1 + 0, .m_other = 1, .m_tag = 1}, .m_objs = {((lean_object*)(((size_t)(3) << 1) | 1))}};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_OptionType_add__options___closed__1 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_OptionType_add__options___closed__1_value;
static const lean_ctor_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_OptionType_add__options___closed__2_value = {.m_header = {.m_rc = 0, .m_cs_sz = sizeof(lean_ctor_object) + sizeof(void*)*1 + 0, .m_other = 1, .m_tag = 1}, .m_objs = {((lean_object*)(((size_t)(4) << 1) | 1))}};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_OptionType_add__options___closed__2 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_OptionType_add__options___closed__2_value;
static lean_once_cell_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_OptionType_add__options___closed__3_once = LEAN_ONCE_CELL_INITIALIZER;
static lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_OptionType_add__options___closed__3;
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_OptionType_add__options;
static lean_once_cell_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_OptionType_add__none___closed__0_once = LEAN_ONCE_CELL_INITIALIZER;
static lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_OptionType_add__none___closed__0;
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_OptionType_add__none;
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_OptionType_catOptions___redArg(lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_OptionType_catOptions(lean_object*, lean_object*);
static const lean_ctor_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_OptionType_filtered___closed__0_value = {.m_header = {.m_rc = 0, .m_cs_sz = sizeof(lean_ctor_object) + sizeof(void*)*1 + 0, .m_other = 1, .m_tag = 1}, .m_objs = {((lean_object*)(((size_t)(1) << 1) | 1))}};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_OptionType_filtered___closed__0 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_OptionType_filtered___closed__0_value;
static const lean_ctor_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_OptionType_filtered___closed__1_value = {.m_header = {.m_rc = 0, .m_cs_sz = sizeof(lean_ctor_object) + sizeof(void*)*2 + 0, .m_other = 2, .m_tag = 1}, .m_objs = {((lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_OptionType_double__some___closed__0_value),((lean_object*)(((size_t)(0) << 1) | 1))}};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_OptionType_filtered___closed__1 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_OptionType_filtered___closed__1_value;
static const lean_ctor_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_OptionType_filtered___closed__2_value = {.m_header = {.m_rc = 0, .m_cs_sz = sizeof(lean_ctor_object) + sizeof(void*)*2 + 0, .m_other = 2, .m_tag = 1}, .m_objs = {((lean_object*)(((size_t)(0) << 1) | 1)),((lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_OptionType_filtered___closed__1_value)}};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_OptionType_filtered___closed__2 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_OptionType_filtered___closed__2_value;
static const lean_ctor_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_OptionType_filtered___closed__3_value = {.m_header = {.m_rc = 0, .m_cs_sz = sizeof(lean_ctor_object) + sizeof(void*)*2 + 0, .m_other = 2, .m_tag = 1}, .m_objs = {((lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_OptionType_add__options___closed__1_value),((lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_OptionType_filtered___closed__2_value)}};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_OptionType_filtered___closed__3 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_OptionType_filtered___closed__3_value;
static const lean_ctor_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_OptionType_filtered___closed__4_value = {.m_header = {.m_rc = 0, .m_cs_sz = sizeof(lean_ctor_object) + sizeof(void*)*2 + 0, .m_other = 2, .m_tag = 1}, .m_objs = {((lean_object*)(((size_t)(0) << 1) | 1)),((lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_OptionType_filtered___closed__3_value)}};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_OptionType_filtered___closed__4 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_OptionType_filtered___closed__4_value;
static const lean_ctor_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_OptionType_filtered___closed__5_value = {.m_header = {.m_rc = 0, .m_cs_sz = sizeof(lean_ctor_object) + sizeof(void*)*2 + 0, .m_other = 2, .m_tag = 1}, .m_objs = {((lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_OptionType_filtered___closed__0_value),((lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_OptionType_filtered___closed__4_value)}};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_OptionType_filtered___closed__5 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_OptionType_filtered___closed__5_value;
static lean_once_cell_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_OptionType_filtered___closed__6_once = LEAN_ONCE_CELL_INITIALIZER;
static lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_OptionType_filtered___closed__6;
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_OptionType_filtered;
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_OptionType_maxList(lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_OptionType_maxList___boxed(lean_object*);
static const lean_ctor_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_OptionType_max__of__list___closed__0_value = {.m_header = {.m_rc = 0, .m_cs_sz = sizeof(lean_ctor_object) + sizeof(void*)*2 + 0, .m_other = 2, .m_tag = 1}, .m_objs = {((lean_object*)(((size_t)(9) << 1) | 1)),((lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_OptionType_myList___closed__0_value)}};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_OptionType_max__of__list___closed__0 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_OptionType_max__of__list___closed__0_value;
static const lean_ctor_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_OptionType_max__of__list___closed__1_value = {.m_header = {.m_rc = 0, .m_cs_sz = sizeof(lean_ctor_object) + sizeof(void*)*2 + 0, .m_other = 2, .m_tag = 1}, .m_objs = {((lean_object*)(((size_t)(2) << 1) | 1)),((lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_OptionType_max__of__list___closed__0_value)}};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_OptionType_max__of__list___closed__1 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_OptionType_max__of__list___closed__1_value;
static const lean_ctor_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_OptionType_max__of__list___closed__2_value = {.m_header = {.m_rc = 0, .m_cs_sz = sizeof(lean_ctor_object) + sizeof(void*)*2 + 0, .m_other = 2, .m_tag = 1}, .m_objs = {((lean_object*)(((size_t)(7) << 1) | 1)),((lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_OptionType_max__of__list___closed__1_value)}};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_OptionType_max__of__list___closed__2 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_OptionType_max__of__list___closed__2_value;
static const lean_ctor_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_OptionType_max__of__list___closed__3_value = {.m_header = {.m_rc = 0, .m_cs_sz = sizeof(lean_ctor_object) + sizeof(void*)*2 + 0, .m_other = 2, .m_tag = 1}, .m_objs = {((lean_object*)(((size_t)(3) << 1) | 1)),((lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_OptionType_max__of__list___closed__2_value)}};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_OptionType_max__of__list___closed__3 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_OptionType_max__of__list___closed__3_value;
static lean_once_cell_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_OptionType_max__of__list___closed__4_once = LEAN_ONCE_CELL_INITIALIZER;
static lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_OptionType_max__of__list___closed__4;
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_OptionType_max__of__list;
static lean_once_cell_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_OptionType_max__empty___closed__0_once = LEAN_ONCE_CELL_INITIALIZER;
static lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_OptionType_max__empty___closed__0;
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_OptionType_max__empty;
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_OptionType_no__number(void){
_start:
{
lean_object* v___x_8_; 
v___x_8_ = lean_box(0);
return v___x_8_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_OptionType_no__string(void){
_start:
{
lean_object* v___x_9_; 
v___x_9_ = lean_box(0);
return v___x_9_;
}
}
static uint8_t _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_OptionType_is__some__example(void){
_start:
{
uint8_t v___x_10_; 
v___x_10_ = 1;
return v___x_10_;
}
}
static uint8_t _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_OptionType_is__none__example(void){
_start:
{
uint8_t v___x_11_; 
v___x_11_ = 1;
return v___x_11_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_OptionType_get__or__zero(void){
_start:
{
lean_object* v___x_12_; 
v___x_12_ = lean_unsigned_to_nat(42u);
return v___x_12_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_OptionType_get__default(void){
_start:
{
lean_object* v___x_13_; 
v___x_13_ = lean_unsigned_to_nat(0u);
return v___x_13_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_OptionType_double(lean_object* v_x_14_){
_start:
{
lean_object* v___x_15_; lean_object* v___x_16_; 
v___x_15_ = lean_unsigned_to_nat(2u);
v___x_16_ = lean_nat_mul(v_x_14_, v___x_15_);
return v___x_16_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_OptionType_double___boxed(lean_object* v_x_17_){
_start:
{
lean_object* v_res_18_; 
v_res_18_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_OptionType_double(v_x_17_);
lean_dec(v_x_17_);
return v_res_18_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_OptionType_map__some___closed__0(void){
_start:
{
lean_object* v___x_19_; lean_object* v___x_20_; 
v___x_19_ = lean_unsigned_to_nat(5u);
v___x_20_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_OptionType_double(v___x_19_);
return v___x_20_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_OptionType_map__some___closed__1(void){
_start:
{
lean_object* v___x_21_; lean_object* v___x_22_; 
v___x_21_ = lean_obj_once(&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_OptionType_map__some___closed__0, &lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_OptionType_map__some___closed__0_once, _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_OptionType_map__some___closed__0);
v___x_22_ = lean_alloc_ctor(1, 1, 0);
lean_ctor_set(v___x_22_, 0, v___x_21_);
return v___x_22_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_OptionType_map__some(void){
_start:
{
lean_object* v___x_23_; 
v___x_23_ = lean_obj_once(&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_OptionType_map__some___closed__1, &lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_OptionType_map__some___closed__1_once, _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_OptionType_map__some___closed__1);
return v___x_23_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_OptionType_map__none(void){
_start:
{
lean_object* v___x_24_; 
v___x_24_ = lean_box(0);
return v___x_24_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_OptionType_map__some_x27(void){
_start:
{
lean_object* v___x_25_; 
v___x_25_ = lean_obj_once(&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_OptionType_map__some___closed__1, &lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_OptionType_map__some___closed__1_once, _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_OptionType_map__some___closed__1);
return v___x_25_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_OptionType_map__string___closed__0(void){
_start:
{
lean_object* v___x_26_; lean_object* v___x_27_; lean_object* v___x_28_; 
v___x_26_ = lean_unsigned_to_nat(0u);
v___x_27_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_OptionType_some__string___closed__0));
v___x_28_ = l_String_mapAux___at___00__private_Init_System_Uri_0__System_Uri_UriEscape_uriEscapeAsciiChar_uInt8ToHex_spec__0(v___x_27_, v___x_26_);
return v___x_28_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_OptionType_map__string___closed__1(void){
_start:
{
lean_object* v___x_29_; lean_object* v___x_30_; 
v___x_29_ = lean_obj_once(&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_OptionType_map__string___closed__0, &lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_OptionType_map__string___closed__0_once, _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_OptionType_map__string___closed__0);
v___x_30_ = lean_alloc_ctor(1, 1, 0);
lean_ctor_set(v___x_30_, 0, v___x_29_);
return v___x_30_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_OptionType_map__string(void){
_start:
{
lean_object* v___x_31_; 
v___x_31_ = lean_obj_once(&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_OptionType_map__string___closed__1, &lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_OptionType_map__string___closed__1_once, _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_OptionType_map__string___closed__1);
return v___x_31_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_OptionType_map__none__string(void){
_start:
{
lean_object* v___x_32_; 
v___x_32_ = lean_box(0);
return v___x_32_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_OptionType_safeDiv(lean_object* v_x_33_, lean_object* v_y_34_){
_start:
{
lean_object* v___x_35_; uint8_t v___x_36_; 
v___x_35_ = lean_unsigned_to_nat(0u);
v___x_36_ = lean_nat_dec_eq(v_y_34_, v___x_35_);
if (v___x_36_ == 0)
{
lean_object* v___x_37_; lean_object* v___x_38_; 
v___x_37_ = lean_nat_div(v_x_33_, v_y_34_);
v___x_38_ = lean_alloc_ctor(1, 1, 0);
lean_ctor_set(v___x_38_, 0, v___x_37_);
return v___x_38_;
}
else
{
lean_object* v___x_39_; 
v___x_39_ = lean_box(0);
return v___x_39_;
}
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_OptionType_safeDiv___boxed(lean_object* v_x_40_, lean_object* v_y_41_){
_start:
{
lean_object* v_res_42_; 
v_res_42_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_OptionType_safeDiv(v_x_40_, v_y_41_);
lean_dec(v_y_41_);
lean_dec(v_x_40_);
return v_res_42_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_OptionType_chain__div___closed__0(void){
_start:
{
lean_object* v___x_43_; lean_object* v___x_44_; lean_object* v___x_45_; 
v___x_43_ = lean_unsigned_to_nat(5u);
v___x_44_ = lean_unsigned_to_nat(100u);
v___x_45_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_OptionType_safeDiv(v___x_44_, v___x_43_);
return v___x_45_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_OptionType_chain__div(void){
_start:
{
lean_object* v___x_46_; 
v___x_46_ = lean_obj_once(&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_OptionType_chain__div___closed__0, &lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_OptionType_chain__div___closed__0_once, _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_OptionType_chain__div___closed__0);
return v___x_46_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_OptionType_chain__div__do(void){
_start:
{
lean_object* v___x_47_; 
v___x_47_ = lean_obj_once(&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_OptionType_chain__div___closed__0, &lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_OptionType_chain__div___closed__0_once, _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_OptionType_chain__div___closed__0);
return v___x_47_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_OptionType_chain__div__fail(void){
_start:
{
lean_object* v___x_48_; 
v___x_48_ = lean_box(0);
return v___x_48_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_OptionType_listGet_x3f___redArg(lean_object* v_x_49_, lean_object* v_x_50_){
_start:
{
if (lean_obj_tag(v_x_49_) == 0)
{
lean_object* v___x_51_; 
lean_dec(v_x_50_);
v___x_51_ = lean_box(0);
return v___x_51_;
}
else
{
lean_object* v_head_52_; lean_object* v_tail_53_; lean_object* v_zero_54_; uint8_t v_isZero_55_; 
v_head_52_ = lean_ctor_get(v_x_49_, 0);
v_tail_53_ = lean_ctor_get(v_x_49_, 1);
v_zero_54_ = lean_unsigned_to_nat(0u);
v_isZero_55_ = lean_nat_dec_eq(v_x_50_, v_zero_54_);
if (v_isZero_55_ == 1)
{
lean_object* v___x_56_; 
lean_dec(v_x_50_);
lean_inc(v_head_52_);
v___x_56_ = lean_alloc_ctor(1, 1, 0);
lean_ctor_set(v___x_56_, 0, v_head_52_);
return v___x_56_;
}
else
{
lean_object* v_one_57_; lean_object* v_n_58_; 
v_one_57_ = lean_unsigned_to_nat(1u);
v_n_58_ = lean_nat_sub(v_x_50_, v_one_57_);
lean_dec(v_x_50_);
v_x_49_ = v_tail_53_;
v_x_50_ = v_n_58_;
goto _start;
}
}
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_OptionType_listGet_x3f___redArg___boxed(lean_object* v_x_60_, lean_object* v_x_61_){
_start:
{
lean_object* v_res_62_; 
v_res_62_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_OptionType_listGet_x3f___redArg(v_x_60_, v_x_61_);
lean_dec(v_x_60_);
return v_res_62_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_OptionType_listGet_x3f(lean_object* v_00_u03b1_63_, lean_object* v_x_64_, lean_object* v_x_65_){
_start:
{
lean_object* v___x_66_; 
v___x_66_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_OptionType_listGet_x3f___redArg(v_x_64_, v_x_65_);
return v___x_66_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_OptionType_listGet_x3f___boxed(lean_object* v_00_u03b1_67_, lean_object* v_x_68_, lean_object* v_x_69_){
_start:
{
lean_object* v_res_70_; 
v_res_70_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_OptionType_listGet_x3f(v_00_u03b1_67_, v_x_68_, v_x_69_);
lean_dec(v_x_68_);
return v_res_70_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_OptionType_get__third___closed__0(void){
_start:
{
lean_object* v___x_87_; lean_object* v___x_88_; lean_object* v___x_89_; 
v___x_87_ = lean_unsigned_to_nat(2u);
v___x_88_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_OptionType_myList));
v___x_89_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_OptionType_listGet_x3f___redArg(v___x_88_, v___x_87_);
return v___x_89_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_OptionType_get__third(void){
_start:
{
lean_object* v___x_90_; 
v___x_90_ = lean_obj_once(&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_OptionType_get__third___closed__0, &lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_OptionType_get__third___closed__0_once, _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_OptionType_get__third___closed__0);
return v___x_90_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_OptionType_get__tenth___closed__0(void){
_start:
{
lean_object* v___x_91_; lean_object* v___x_92_; lean_object* v___x_93_; 
v___x_91_ = lean_unsigned_to_nat(9u);
v___x_92_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_OptionType_myList));
v___x_93_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_OptionType_listGet_x3f___redArg(v___x_92_, v___x_91_);
return v___x_93_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_OptionType_get__tenth(void){
_start:
{
lean_object* v___x_94_; 
v___x_94_ = lean_obj_once(&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_OptionType_get__tenth___closed__0, &lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_OptionType_get__tenth___closed__0_once, _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_OptionType_get__tenth___closed__0);
return v___x_94_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_OptionType_first__char__of(lean_object* v_s_95_){
_start:
{
lean_object* v___x_96_; lean_object* v___x_97_; uint8_t v___x_98_; 
v___x_96_ = lean_string_utf8_byte_size(v_s_95_);
v___x_97_ = lean_unsigned_to_nat(0u);
v___x_98_ = lean_nat_dec_eq(v___x_96_, v___x_97_);
if (v___x_98_ == 0)
{
lean_object* v___x_99_; lean_object* v___x_100_; 
v___x_99_ = lean_alloc_ctor(0, 3, 0);
lean_ctor_set(v___x_99_, 0, v_s_95_);
lean_ctor_set(v___x_99_, 1, v___x_97_);
lean_ctor_set(v___x_99_, 2, v___x_96_);
v___x_100_ = l_String_Slice_Pos_get_x3f(v___x_99_, v___x_97_);
lean_dec_ref_known(v___x_99_, 3);
return v___x_100_;
}
else
{
lean_object* v___x_101_; 
lean_dec_ref(v_s_95_);
v___x_101_ = lean_box(0);
return v___x_101_;
}
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_OptionType_first__hello___closed__1(void){
_start:
{
lean_object* v___x_103_; lean_object* v___x_104_; 
v___x_103_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_OptionType_first__hello___closed__0));
v___x_104_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_OptionType_first__char__of(v___x_103_);
return v___x_104_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_OptionType_first__hello(void){
_start:
{
lean_object* v___x_105_; 
v___x_105_ = lean_obj_once(&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_OptionType_first__hello___closed__1, &lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_OptionType_first__hello___closed__1_once, _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_OptionType_first__hello___closed__1);
return v___x_105_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_OptionType_first__empty___closed__1(void){
_start:
{
lean_object* v___x_107_; lean_object* v___x_108_; 
v___x_107_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_OptionType_first__empty___closed__0));
v___x_108_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_OptionType_first__char__of(v___x_107_);
return v___x_108_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_OptionType_first__empty(void){
_start:
{
lean_object* v___x_109_; 
v___x_109_ = lean_obj_once(&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_OptionType_first__empty___closed__1, &lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_OptionType_first__empty___closed__1_once, _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_OptionType_first__empty___closed__1);
return v___x_109_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_OptionType_parseNat(lean_object* v_s_110_){
_start:
{
lean_object* v___x_111_; lean_object* v___x_112_; lean_object* v___x_113_; lean_object* v___x_114_; 
v___x_111_ = lean_unsigned_to_nat(0u);
v___x_112_ = lean_string_utf8_byte_size(v_s_110_);
v___x_113_ = lean_alloc_ctor(0, 3, 0);
lean_ctor_set(v___x_113_, 0, v_s_110_);
lean_ctor_set(v___x_113_, 1, v___x_111_);
lean_ctor_set(v___x_113_, 2, v___x_112_);
v___x_114_ = l_String_Slice_toNat_x3f(v___x_113_);
lean_dec_ref_known(v___x_113_, 3);
return v___x_114_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_OptionType_parse__42___closed__1(void){
_start:
{
lean_object* v___x_116_; lean_object* v___x_117_; 
v___x_116_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_OptionType_parse__42___closed__0));
v___x_117_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_OptionType_parseNat(v___x_116_);
return v___x_117_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_OptionType_parse__42(void){
_start:
{
lean_object* v___x_118_; 
v___x_118_ = lean_obj_once(&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_OptionType_parse__42___closed__1, &lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_OptionType_parse__42___closed__1_once, _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_OptionType_parse__42___closed__1);
return v___x_118_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_OptionType_parse__abc___closed__1(void){
_start:
{
lean_object* v___x_120_; lean_object* v___x_121_; 
v___x_120_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_OptionType_parse__abc___closed__0));
v___x_121_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_OptionType_parseNat(v___x_120_);
return v___x_121_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_OptionType_parse__abc(void){
_start:
{
lean_object* v___x_122_; 
v___x_122_ = lean_obj_once(&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_OptionType_parse__abc___closed__1, &lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_OptionType_parse__abc___closed__1_once, _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_OptionType_parse__abc___closed__1);
return v___x_122_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_OptionType_optionToString(lean_object* v_opt_125_){
_start:
{
if (lean_obj_tag(v_opt_125_) == 0)
{
lean_object* v___x_126_; 
v___x_126_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_OptionType_optionToString___closed__0));
return v___x_126_;
}
else
{
lean_object* v_val_127_; lean_object* v___x_128_; lean_object* v___x_129_; lean_object* v___x_130_; 
v_val_127_ = lean_ctor_get(v_opt_125_, 0);
lean_inc(v_val_127_);
lean_dec_ref_known(v_opt_125_, 1);
v___x_128_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_OptionType_optionToString___closed__1));
v___x_129_ = l_Nat_reprFast(v_val_127_);
v___x_130_ = lean_string_append(v___x_128_, v___x_129_);
lean_dec_ref(v___x_129_);
return v___x_130_;
}
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_OptionType_str1___closed__0(void){
_start:
{
lean_object* v___x_131_; lean_object* v___x_132_; 
v___x_131_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_OptionType_some__number___closed__0));
v___x_132_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_OptionType_optionToString(v___x_131_);
return v___x_132_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_OptionType_str1(void){
_start:
{
lean_object* v___x_133_; 
v___x_133_ = lean_obj_once(&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_OptionType_str1___closed__0, &lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_OptionType_str1___closed__0_once, _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_OptionType_str1___closed__0);
return v___x_133_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_OptionType_str2___closed__0(void){
_start:
{
lean_object* v___x_134_; lean_object* v___x_135_; 
v___x_134_ = lean_box(0);
v___x_135_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_OptionType_optionToString(v___x_134_);
return v___x_135_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_OptionType_str2(void){
_start:
{
lean_object* v___x_136_; 
v___x_136_ = lean_obj_once(&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_OptionType_str2___closed__0, &lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_OptionType_str2___closed__0_once, _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_OptionType_str2___closed__0);
return v___x_136_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_OptionType_doubleOption(lean_object* v_opt_137_){
_start:
{
if (lean_obj_tag(v_opt_137_) == 1)
{
lean_object* v_val_138_; lean_object* v___x_140_; uint8_t v_isShared_141_; uint8_t v_isSharedCheck_147_; 
v_val_138_ = lean_ctor_get(v_opt_137_, 0);
v_isSharedCheck_147_ = !lean_is_exclusive(v_opt_137_);
if (v_isSharedCheck_147_ == 0)
{
v___x_140_ = v_opt_137_;
v_isShared_141_ = v_isSharedCheck_147_;
goto v_resetjp_139_;
}
else
{
lean_inc(v_val_138_);
lean_dec(v_opt_137_);
v___x_140_ = lean_box(0);
v_isShared_141_ = v_isSharedCheck_147_;
goto v_resetjp_139_;
}
v_resetjp_139_:
{
lean_object* v___x_142_; lean_object* v___x_143_; lean_object* v___x_145_; 
v___x_142_ = lean_unsigned_to_nat(2u);
v___x_143_ = lean_nat_mul(v_val_138_, v___x_142_);
lean_dec(v_val_138_);
if (v_isShared_141_ == 0)
{
lean_ctor_set(v___x_140_, 0, v___x_143_);
v___x_145_ = v___x_140_;
goto v_reusejp_144_;
}
else
{
lean_object* v_reuseFailAlloc_146_; 
v_reuseFailAlloc_146_ = lean_alloc_ctor(1, 1, 0);
lean_ctor_set(v_reuseFailAlloc_146_, 0, v___x_143_);
v___x_145_ = v_reuseFailAlloc_146_;
goto v_reusejp_144_;
}
v_reusejp_144_:
{
return v___x_145_;
}
}
}
else
{
lean_object* v___x_148_; 
lean_dec(v_opt_137_);
v___x_148_ = lean_box(0);
return v___x_148_;
}
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_OptionType_double__some___closed__1(void){
_start:
{
lean_object* v___x_151_; lean_object* v___x_152_; 
v___x_151_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_OptionType_double__some___closed__0));
v___x_152_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_OptionType_doubleOption(v___x_151_);
return v___x_152_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_OptionType_double__some(void){
_start:
{
lean_object* v___x_153_; 
v___x_153_ = lean_obj_once(&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_OptionType_double__some___closed__1, &lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_OptionType_double__some___closed__1_once, _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_OptionType_double__some___closed__1);
return v___x_153_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_OptionType_double__none___closed__0(void){
_start:
{
lean_object* v___x_154_; lean_object* v___x_155_; 
v___x_154_ = lean_box(0);
v___x_155_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_OptionType_doubleOption(v___x_154_);
return v___x_155_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_OptionType_double__none(void){
_start:
{
lean_object* v___x_156_; 
v___x_156_ = lean_obj_once(&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_OptionType_double__none___closed__0, &lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_OptionType_double__none___closed__0_once, _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_OptionType_double__none___closed__0);
return v___x_156_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_OptionType_or__else3(void){
_start:
{
lean_object* v___x_161_; 
v___x_161_ = lean_box(0);
return v___x_161_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_OptionType_guard__pos___closed__0(void){
_start:
{
lean_object* v___x_163_; lean_object* v___x_164_; 
v___x_163_ = lean_unsigned_to_nat(0u);
v___x_164_ = lean_nat_to_int(v___x_163_);
return v___x_164_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_OptionType_guard__pos(lean_object* v_n_167_){
_start:
{
lean_object* v___x_168_; uint8_t v___x_169_; 
v___x_168_ = lean_obj_once(&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_OptionType_guard__pos___closed__0, &lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_OptionType_guard__pos___closed__0_once, _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_OptionType_guard__pos___closed__0);
v___x_169_ = lean_int_dec_lt(v___x_168_, v_n_167_);
if (v___x_169_ == 0)
{
lean_object* v___x_170_; 
v___x_170_ = lean_box(0);
return v___x_170_;
}
else
{
lean_object* v___x_171_; 
v___x_171_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_OptionType_guard__pos___closed__1));
return v___x_171_;
}
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_OptionType_guard__pos___boxed(lean_object* v_n_172_){
_start:
{
lean_object* v_res_173_; 
v_res_173_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_OptionType_guard__pos(v_n_172_);
lean_dec(v_n_172_);
return v_res_173_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_OptionType_guard__5___closed__0(void){
_start:
{
lean_object* v___x_174_; lean_object* v___x_175_; 
v___x_174_ = lean_unsigned_to_nat(5u);
v___x_175_ = lean_nat_to_int(v___x_174_);
return v___x_175_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_OptionType_guard__5___closed__1(void){
_start:
{
lean_object* v___x_176_; lean_object* v___x_177_; 
v___x_176_ = lean_obj_once(&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_OptionType_guard__5___closed__0, &lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_OptionType_guard__5___closed__0_once, _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_OptionType_guard__5___closed__0);
v___x_177_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_OptionType_guard__pos(v___x_176_);
return v___x_177_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_OptionType_guard__5(void){
_start:
{
lean_object* v___x_178_; 
v___x_178_ = lean_obj_once(&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_OptionType_guard__5___closed__1, &lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_OptionType_guard__5___closed__1_once, _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_OptionType_guard__5___closed__1);
return v___x_178_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_OptionType_guard__neg___closed__0(void){
_start:
{
lean_object* v___x_179_; lean_object* v___x_180_; 
v___x_179_ = lean_unsigned_to_nat(3u);
v___x_180_ = lean_nat_to_int(v___x_179_);
return v___x_180_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_OptionType_guard__neg___closed__1(void){
_start:
{
lean_object* v___x_181_; lean_object* v___x_182_; 
v___x_181_ = lean_obj_once(&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_OptionType_guard__neg___closed__0, &lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_OptionType_guard__neg___closed__0_once, _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_OptionType_guard__neg___closed__0);
v___x_182_ = lean_int_neg(v___x_181_);
return v___x_182_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_OptionType_guard__neg___closed__2(void){
_start:
{
lean_object* v___x_183_; lean_object* v___x_184_; 
v___x_183_ = lean_obj_once(&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_OptionType_guard__neg___closed__1, &lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_OptionType_guard__neg___closed__1_once, _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_OptionType_guard__neg___closed__1);
v___x_184_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_OptionType_guard__pos(v___x_183_);
return v___x_184_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_OptionType_guard__neg(void){
_start:
{
lean_object* v___x_185_; 
v___x_185_ = lean_obj_once(&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_OptionType_guard__neg___closed__2, &lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_OptionType_guard__neg___closed__2_once, _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_OptionType_guard__neg___closed__2);
return v___x_185_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_OptionType_map2___redArg(lean_object* v_f_186_, lean_object* v_oa_187_, lean_object* v_ob_188_){
_start:
{
if (lean_obj_tag(v_oa_187_) == 1)
{
if (lean_obj_tag(v_ob_188_) == 1)
{
lean_object* v_val_189_; lean_object* v_val_190_; lean_object* v___x_192_; uint8_t v_isShared_193_; uint8_t v_isSharedCheck_198_; 
v_val_189_ = lean_ctor_get(v_oa_187_, 0);
lean_inc(v_val_189_);
lean_dec_ref_known(v_oa_187_, 1);
v_val_190_ = lean_ctor_get(v_ob_188_, 0);
v_isSharedCheck_198_ = !lean_is_exclusive(v_ob_188_);
if (v_isSharedCheck_198_ == 0)
{
v___x_192_ = v_ob_188_;
v_isShared_193_ = v_isSharedCheck_198_;
goto v_resetjp_191_;
}
else
{
lean_inc(v_val_190_);
lean_dec(v_ob_188_);
v___x_192_ = lean_box(0);
v_isShared_193_ = v_isSharedCheck_198_;
goto v_resetjp_191_;
}
v_resetjp_191_:
{
lean_object* v___x_194_; lean_object* v___x_196_; 
v___x_194_ = lean_apply_2(v_f_186_, v_val_189_, v_val_190_);
if (v_isShared_193_ == 0)
{
lean_ctor_set(v___x_192_, 0, v___x_194_);
v___x_196_ = v___x_192_;
goto v_reusejp_195_;
}
else
{
lean_object* v_reuseFailAlloc_197_; 
v_reuseFailAlloc_197_ = lean_alloc_ctor(1, 1, 0);
lean_ctor_set(v_reuseFailAlloc_197_, 0, v___x_194_);
v___x_196_ = v_reuseFailAlloc_197_;
goto v_reusejp_195_;
}
v_reusejp_195_:
{
return v___x_196_;
}
}
}
else
{
lean_object* v___x_199_; 
lean_dec_ref_known(v_oa_187_, 1);
lean_dec(v_ob_188_);
lean_dec(v_f_186_);
v___x_199_ = lean_box(0);
return v___x_199_;
}
}
else
{
lean_object* v___x_200_; 
lean_dec(v_ob_188_);
lean_dec(v_oa_187_);
lean_dec(v_f_186_);
v___x_200_ = lean_box(0);
return v___x_200_;
}
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_OptionType_map2(lean_object* v_00_u03b1_201_, lean_object* v_00_u03b2_202_, lean_object* v_00_u03b3_203_, lean_object* v_f_204_, lean_object* v_oa_205_, lean_object* v_ob_206_){
_start:
{
lean_object* v___x_207_; 
v___x_207_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_OptionType_map2___redArg(v_f_204_, v_oa_205_, v_ob_206_);
return v___x_207_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_OptionType_add__options___closed__3(void){
_start:
{
lean_object* v___x_213_; lean_object* v___x_214_; lean_object* v___f_215_; lean_object* v___x_216_; 
v___x_213_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_OptionType_add__options___closed__2));
v___x_214_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_OptionType_add__options___closed__1));
v___f_215_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_OptionType_add__options___closed__0));
v___x_216_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_OptionType_map2___redArg(v___f_215_, v___x_214_, v___x_213_);
return v___x_216_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_OptionType_add__options(void){
_start:
{
lean_object* v___x_217_; 
v___x_217_ = lean_obj_once(&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_OptionType_add__options___closed__3, &lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_OptionType_add__options___closed__3_once, _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_OptionType_add__options___closed__3);
return v___x_217_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_OptionType_add__none___closed__0(void){
_start:
{
lean_object* v___x_218_; lean_object* v___x_219_; lean_object* v___f_220_; lean_object* v___x_221_; 
v___x_218_ = lean_box(0);
v___x_219_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_OptionType_add__options___closed__1));
v___f_220_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_OptionType_add__options___closed__0));
v___x_221_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_OptionType_map2___redArg(v___f_220_, v___x_219_, v___x_218_);
return v___x_221_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_OptionType_add__none(void){
_start:
{
lean_object* v___x_222_; 
v___x_222_ = lean_obj_once(&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_OptionType_add__none___closed__0, &lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_OptionType_add__none___closed__0_once, _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_OptionType_add__none___closed__0);
return v___x_222_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_OptionType_catOptions___redArg(lean_object* v_l_223_){
_start:
{
if (lean_obj_tag(v_l_223_) == 0)
{
lean_object* v___x_224_; 
v___x_224_ = lean_box(0);
return v___x_224_;
}
else
{
lean_object* v_head_225_; 
v_head_225_ = lean_ctor_get(v_l_223_, 0);
if (lean_obj_tag(v_head_225_) == 0)
{
lean_object* v_tail_226_; 
v_tail_226_ = lean_ctor_get(v_l_223_, 1);
lean_inc(v_tail_226_);
lean_dec_ref_known(v_l_223_, 2);
v_l_223_ = v_tail_226_;
goto _start;
}
else
{
lean_object* v_tail_228_; lean_object* v___x_230_; uint8_t v_isShared_231_; uint8_t v_isSharedCheck_237_; 
lean_inc_ref(v_head_225_);
v_tail_228_ = lean_ctor_get(v_l_223_, 1);
v_isSharedCheck_237_ = !lean_is_exclusive(v_l_223_);
if (v_isSharedCheck_237_ == 0)
{
lean_object* v_unused_238_; 
v_unused_238_ = lean_ctor_get(v_l_223_, 0);
lean_dec(v_unused_238_);
v___x_230_ = v_l_223_;
v_isShared_231_ = v_isSharedCheck_237_;
goto v_resetjp_229_;
}
else
{
lean_inc(v_tail_228_);
lean_dec(v_l_223_);
v___x_230_ = lean_box(0);
v_isShared_231_ = v_isSharedCheck_237_;
goto v_resetjp_229_;
}
v_resetjp_229_:
{
lean_object* v_val_232_; lean_object* v___x_233_; lean_object* v___x_235_; 
v_val_232_ = lean_ctor_get(v_head_225_, 0);
lean_inc(v_val_232_);
lean_dec_ref_known(v_head_225_, 1);
v___x_233_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_OptionType_catOptions___redArg(v_tail_228_);
if (v_isShared_231_ == 0)
{
lean_ctor_set(v___x_230_, 1, v___x_233_);
lean_ctor_set(v___x_230_, 0, v_val_232_);
v___x_235_ = v___x_230_;
goto v_reusejp_234_;
}
else
{
lean_object* v_reuseFailAlloc_236_; 
v_reuseFailAlloc_236_ = lean_alloc_ctor(1, 2, 0);
lean_ctor_set(v_reuseFailAlloc_236_, 0, v_val_232_);
lean_ctor_set(v_reuseFailAlloc_236_, 1, v___x_233_);
v___x_235_ = v_reuseFailAlloc_236_;
goto v_reusejp_234_;
}
v_reusejp_234_:
{
return v___x_235_;
}
}
}
}
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_OptionType_catOptions(lean_object* v_00_u03b1_239_, lean_object* v_l_240_){
_start:
{
lean_object* v___x_241_; 
v___x_241_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_OptionType_catOptions___redArg(v_l_240_);
return v___x_241_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_OptionType_filtered___closed__6(void){
_start:
{
lean_object* v___x_259_; lean_object* v___x_260_; 
v___x_259_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_OptionType_filtered___closed__5));
v___x_260_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_OptionType_catOptions___redArg(v___x_259_);
return v___x_260_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_OptionType_filtered(void){
_start:
{
lean_object* v___x_261_; 
v___x_261_ = lean_obj_once(&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_OptionType_filtered___closed__6, &lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_OptionType_filtered___closed__6_once, _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_OptionType_filtered___closed__6);
return v___x_261_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_OptionType_maxList(lean_object* v_l_262_){
_start:
{
if (lean_obj_tag(v_l_262_) == 0)
{
lean_object* v___x_263_; 
v___x_263_ = lean_box(0);
return v___x_263_;
}
else
{
lean_object* v_head_264_; lean_object* v_tail_265_; lean_object* v___x_266_; 
v_head_264_ = lean_ctor_get(v_l_262_, 0);
v_tail_265_ = lean_ctor_get(v_l_262_, 1);
v___x_266_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_OptionType_maxList(v_tail_265_);
if (lean_obj_tag(v___x_266_) == 0)
{
lean_object* v___x_267_; 
lean_inc(v_head_264_);
v___x_267_ = lean_alloc_ctor(1, 1, 0);
lean_ctor_set(v___x_267_, 0, v_head_264_);
return v___x_267_;
}
else
{
lean_object* v_val_268_; uint8_t v___x_269_; 
v_val_268_ = lean_ctor_get(v___x_266_, 0);
lean_inc(v_val_268_);
v___x_269_ = lean_nat_dec_lt(v_val_268_, v_head_264_);
lean_dec(v_val_268_);
if (v___x_269_ == 0)
{
return v___x_266_;
}
else
{
lean_object* v___x_271_; uint8_t v_isShared_272_; uint8_t v_isSharedCheck_276_; 
v_isSharedCheck_276_ = !lean_is_exclusive(v___x_266_);
if (v_isSharedCheck_276_ == 0)
{
lean_object* v_unused_277_; 
v_unused_277_ = lean_ctor_get(v___x_266_, 0);
lean_dec(v_unused_277_);
v___x_271_ = v___x_266_;
v_isShared_272_ = v_isSharedCheck_276_;
goto v_resetjp_270_;
}
else
{
lean_dec(v___x_266_);
v___x_271_ = lean_box(0);
v_isShared_272_ = v_isSharedCheck_276_;
goto v_resetjp_270_;
}
v_resetjp_270_:
{
lean_object* v___x_274_; 
lean_inc(v_head_264_);
if (v_isShared_272_ == 0)
{
lean_ctor_set(v___x_271_, 0, v_head_264_);
v___x_274_ = v___x_271_;
goto v_reusejp_273_;
}
else
{
lean_object* v_reuseFailAlloc_275_; 
v_reuseFailAlloc_275_ = lean_alloc_ctor(1, 1, 0);
lean_ctor_set(v_reuseFailAlloc_275_, 0, v_head_264_);
v___x_274_ = v_reuseFailAlloc_275_;
goto v_reusejp_273_;
}
v_reusejp_273_:
{
return v___x_274_;
}
}
}
}
}
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_OptionType_maxList___boxed(lean_object* v_l_278_){
_start:
{
lean_object* v_res_279_; 
v_res_279_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_OptionType_maxList(v_l_278_);
lean_dec(v_l_278_);
return v_res_279_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_OptionType_max__of__list___closed__4(void){
_start:
{
lean_object* v___x_292_; lean_object* v___x_293_; 
v___x_292_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_OptionType_max__of__list___closed__3));
v___x_293_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_OptionType_maxList(v___x_292_);
return v___x_293_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_OptionType_max__of__list(void){
_start:
{
lean_object* v___x_294_; 
v___x_294_ = lean_obj_once(&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_OptionType_max__of__list___closed__4, &lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_OptionType_max__of__list___closed__4_once, _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_OptionType_max__of__list___closed__4);
return v___x_294_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_OptionType_max__empty___closed__0(void){
_start:
{
lean_object* v___x_295_; lean_object* v___x_296_; 
v___x_295_ = lean_box(0);
v___x_296_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_OptionType_maxList(v___x_295_);
return v___x_296_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_OptionType_max__empty(void){
_start:
{
lean_object* v___x_297_; 
v___x_297_ = lean_obj_once(&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_OptionType_max__empty___closed__0, &lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_OptionType_max__empty___closed__0_once, _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_OptionType_max__empty___closed__0);
return v___x_297_;
}
}
lean_object* initialize_Init(uint8_t builtin);
lean_object* initialize_Init(uint8_t builtin);
static bool _G_initialized = false;
LEAN_EXPORT lean_object* initialize_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_OptionType(uint8_t builtin) {
lean_object * res;
if (_G_initialized) return lean_io_result_mk_ok(lean_box(0));
_G_initialized = true;
res = initialize_Init(builtin);
if (lean_io_result_is_error(res)) return res;
lean_dec_ref(res);
res = initialize_Init(builtin);
if (lean_io_result_is_error(res)) return res;
lean_dec_ref(res);
lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_OptionType_no__number = _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_OptionType_no__number();
lean_mark_persistent(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_OptionType_no__number);
lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_OptionType_no__string = _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_OptionType_no__string();
lean_mark_persistent(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_OptionType_no__string);
lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_OptionType_is__some__example = _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_OptionType_is__some__example();
lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_OptionType_is__none__example = _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_OptionType_is__none__example();
lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_OptionType_get__or__zero = _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_OptionType_get__or__zero();
lean_mark_persistent(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_OptionType_get__or__zero);
lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_OptionType_get__default = _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_OptionType_get__default();
lean_mark_persistent(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_OptionType_get__default);
lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_OptionType_map__some = _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_OptionType_map__some();
lean_mark_persistent(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_OptionType_map__some);
lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_OptionType_map__none = _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_OptionType_map__none();
lean_mark_persistent(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_OptionType_map__none);
lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_OptionType_map__some_x27 = _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_OptionType_map__some_x27();
lean_mark_persistent(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_OptionType_map__some_x27);
lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_OptionType_map__string = _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_OptionType_map__string();
lean_mark_persistent(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_OptionType_map__string);
lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_OptionType_map__none__string = _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_OptionType_map__none__string();
lean_mark_persistent(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_OptionType_map__none__string);
lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_OptionType_chain__div = _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_OptionType_chain__div();
lean_mark_persistent(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_OptionType_chain__div);
lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_OptionType_chain__div__do = _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_OptionType_chain__div__do();
lean_mark_persistent(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_OptionType_chain__div__do);
lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_OptionType_chain__div__fail = _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_OptionType_chain__div__fail();
lean_mark_persistent(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_OptionType_chain__div__fail);
lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_OptionType_get__third = _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_OptionType_get__third();
lean_mark_persistent(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_OptionType_get__third);
lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_OptionType_get__tenth = _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_OptionType_get__tenth();
lean_mark_persistent(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_OptionType_get__tenth);
lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_OptionType_first__hello = _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_OptionType_first__hello();
lean_mark_persistent(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_OptionType_first__hello);
lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_OptionType_first__empty = _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_OptionType_first__empty();
lean_mark_persistent(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_OptionType_first__empty);
lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_OptionType_parse__42 = _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_OptionType_parse__42();
lean_mark_persistent(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_OptionType_parse__42);
lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_OptionType_parse__abc = _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_OptionType_parse__abc();
lean_mark_persistent(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_OptionType_parse__abc);
lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_OptionType_str1 = _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_OptionType_str1();
lean_mark_persistent(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_OptionType_str1);
lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_OptionType_str2 = _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_OptionType_str2();
lean_mark_persistent(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_OptionType_str2);
lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_OptionType_double__some = _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_OptionType_double__some();
lean_mark_persistent(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_OptionType_double__some);
lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_OptionType_double__none = _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_OptionType_double__none();
lean_mark_persistent(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_OptionType_double__none);
lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_OptionType_or__else3 = _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_OptionType_or__else3();
lean_mark_persistent(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_OptionType_or__else3);
lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_OptionType_guard__5 = _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_OptionType_guard__5();
lean_mark_persistent(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_OptionType_guard__5);
lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_OptionType_guard__neg = _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_OptionType_guard__neg();
lean_mark_persistent(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_OptionType_guard__neg);
lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_OptionType_add__options = _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_OptionType_add__options();
lean_mark_persistent(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_OptionType_add__options);
lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_OptionType_add__none = _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_OptionType_add__none();
lean_mark_persistent(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_OptionType_add__none);
lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_OptionType_filtered = _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_OptionType_filtered();
lean_mark_persistent(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_OptionType_filtered);
lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_OptionType_max__of__list = _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_OptionType_max__of__list();
lean_mark_persistent(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_OptionType_max__of__list);
lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_OptionType_max__empty = _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_OptionType_max__empty();
lean_mark_persistent(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_OptionType_max__empty);
return lean_io_result_mk_ok(lean_box(0));
}
#ifdef __cplusplus
}
#endif
