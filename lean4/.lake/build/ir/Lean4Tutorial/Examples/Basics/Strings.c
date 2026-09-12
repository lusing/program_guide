// Lean compiler output
// Module: Lean4Tutorial.Examples.Basics.Strings
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
lean_object* lean_string_utf8_byte_size(lean_object*);
lean_object* l_List_replicateTR___redArg(lean_object*, lean_object*);
lean_object* lean_string_append(lean_object*, lean_object*);
lean_object* lean_string_data(lean_object*);
lean_object* l_List_reverse___redArg(lean_object*);
uint8_t lean_uint32_dec_eq(uint32_t, uint32_t);
lean_object* l_List_lengthTR___redArg(lean_object*);
lean_object* lean_string_mk(lean_object*);
lean_object* l_String_mapAux___at___00__private_Init_System_Uri_0__System_Uri_UriEscape_uriEscapeAsciiChar_uInt8ToHex_spec__0(lean_object*, lean_object*);
lean_object* l_List_drop___redArg(lean_object*, lean_object*);
lean_object* lean_mk_empty_array_with_capacity(lean_object*);
lean_object* l___private_Init_Data_List_Impl_0__List_takeTR_go___redArg(lean_object*, lean_object*, lean_object*, lean_object*);
lean_object* l_String_Slice_toNat_x3f(lean_object*);
uint8_t lean_nat_dec_eq(lean_object*, lean_object*);
lean_object* lean_nat_sub(lean_object*, lean_object*);
lean_object* lean_int_neg(lean_object*);
lean_object* l_Int_repr(lean_object*);
lean_object* lean_nat_add(lean_object*, lean_object*);
lean_object* lean_string_utf8_next_fast(lean_object*, lean_object*);
uint8_t lean_nat_dec_le(lean_object*, lean_object*);
uint8_t lean_nat_dec_lt(lean_object*, lean_object*);
uint8_t lean_string_get_byte_fast(lean_object*, lean_object*);
uint8_t lean_uint8_dec_eq(uint8_t, uint8_t);
lean_object* lean_array_fget_borrowed(lean_object*, lean_object*);
lean_object* l_String_Slice_posGE___redArg(lean_object*, lean_object*);
lean_object* l_String_Slice_Pattern_ForwardSliceSearcher_buildTable(lean_object*);
uint8_t lean_string_memcmp(lean_object*, lean_object*, lean_object*, lean_object*, lean_object*);
uint8_t l_List_isEmpty___redArg(lean_object*);
lean_object* lean_string_length(lean_object*);
lean_object* l_Nat_reprFast(lean_object*);
lean_object* lean_string_utf8_set(lean_object*, lean_object*, uint32_t);
lean_object* l_Char_utf8Size(uint32_t);
uint32_t lean_string_utf8_get_fast(lean_object*, lean_object*);
uint8_t lean_uint32_dec_le(uint32_t, uint32_t);
uint32_t lean_uint32_add(uint32_t, uint32_t);
uint8_t l_String_decLE(lean_object*, lean_object*);
uint8_t lean_string_dec_lt(lean_object*, lean_object*);
lean_object* l_String_Slice_Pos_get_x3f(lean_object*, lean_object*);
lean_object* l_String_intercalate(lean_object*, lean_object*);
lean_object* l_String_Slice_Pos_prev_x3f(lean_object*, lean_object*);
static const lean_string_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_hello___closed__0_value = {.m_header = {.m_rc = 0, .m_cs_sz = 0, .m_other = 0, .m_tag = 249}, .m_size = 14, .m_capacity = 14, .m_length = 13, .m_data = "Hello, World!"};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_hello___closed__0 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_hello___closed__0_value;
LEAN_EXPORT const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_hello = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_hello___closed__0_value;
static const lean_string_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_empty___closed__0_value = {.m_header = {.m_rc = 0, .m_cs_sz = 0, .m_other = 0, .m_tag = 249}, .m_size = 1, .m_capacity = 1, .m_length = 0, .m_data = ""};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_empty___closed__0 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_empty___closed__0_value;
LEAN_EXPORT const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_empty = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_empty___closed__0_value;
static const lean_string_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_single__char___closed__0_value = {.m_header = {.m_rc = 0, .m_cs_sz = 0, .m_other = 0, .m_tag = 249}, .m_size = 2, .m_capacity = 2, .m_length = 1, .m_data = "a"};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_single__char___closed__0 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_single__char___closed__0_value;
LEAN_EXPORT const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_single__char = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_single__char___closed__0_value;
static const lean_string_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_greeting___closed__0_value = {.m_header = {.m_rc = 0, .m_cs_sz = 0, .m_other = 0, .m_tag = 249}, .m_size = 15, .m_capacity = 15, .m_length = 14, .m_data = "Hello, Lean 4!"};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_greeting___closed__0 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_greeting___closed__0_value;
LEAN_EXPORT const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_greeting = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_greeting___closed__0_value;
static const lean_string_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_sentence___closed__0_value = {.m_header = {.m_rc = 0, .m_cs_sz = 0, .m_other = 0, .m_tag = 249}, .m_size = 12, .m_capacity = 12, .m_length = 11, .m_data = "I love Lean"};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_sentence___closed__0 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_sentence___closed__0_value;
LEAN_EXPORT const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_sentence = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_sentence___closed__0_value;
static const lean_string_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_words___closed__0_value = {.m_header = {.m_rc = 0, .m_cs_sz = 0, .m_other = 0, .m_tag = 249}, .m_size = 5, .m_capacity = 5, .m_length = 4, .m_data = "Lean"};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_words___closed__0 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_words___closed__0_value;
static const lean_string_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_words___closed__1_value = {.m_header = {.m_rc = 0, .m_cs_sz = 0, .m_other = 0, .m_tag = 249}, .m_size = 3, .m_capacity = 3, .m_length = 2, .m_data = "is"};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_words___closed__1 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_words___closed__1_value;
static const lean_string_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_words___closed__2_value = {.m_header = {.m_rc = 0, .m_cs_sz = 0, .m_other = 0, .m_tag = 249}, .m_size = 4, .m_capacity = 4, .m_length = 3, .m_data = "fun"};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_words___closed__2 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_words___closed__2_value;
static const lean_ctor_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_words___closed__3_value = {.m_header = {.m_rc = 0, .m_cs_sz = sizeof(lean_ctor_object) + sizeof(void*)*2 + 0, .m_other = 2, .m_tag = 1}, .m_objs = {((lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_words___closed__2_value),((lean_object*)(((size_t)(0) << 1) | 1))}};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_words___closed__3 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_words___closed__3_value;
static const lean_ctor_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_words___closed__4_value = {.m_header = {.m_rc = 0, .m_cs_sz = sizeof(lean_ctor_object) + sizeof(void*)*2 + 0, .m_other = 2, .m_tag = 1}, .m_objs = {((lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_words___closed__1_value),((lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_words___closed__3_value)}};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_words___closed__4 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_words___closed__4_value;
static const lean_ctor_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_words___closed__5_value = {.m_header = {.m_rc = 0, .m_cs_sz = sizeof(lean_ctor_object) + sizeof(void*)*2 + 0, .m_other = 2, .m_tag = 1}, .m_objs = {((lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_words___closed__0_value),((lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_words___closed__4_value)}};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_words___closed__5 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_words___closed__5_value;
LEAN_EXPORT const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_words = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_words___closed__5_value;
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_List_foldl___at___00Lean4Tutorial_Examples_Basics_Strings_joined_spec__0(lean_object*, lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_List_foldl___at___00Lean4Tutorial_Examples_Basics_Strings_joined_spec__0___boxed(lean_object*, lean_object*);
static lean_once_cell_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_joined___closed__0_once = LEAN_ONCE_CELL_INITIALIZER;
static lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_joined___closed__0;
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_joined;
static const lean_string_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_with__spaces___closed__0_value = {.m_header = {.m_rc = 0, .m_cs_sz = 0, .m_other = 0, .m_tag = 249}, .m_size = 2, .m_capacity = 2, .m_length = 1, .m_data = " "};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_with__spaces___closed__0 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_with__spaces___closed__0_value;
static lean_once_cell_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_with__spaces___closed__1_once = LEAN_ONCE_CELL_INITIALIZER;
static lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_with__spaces___closed__1;
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_with__spaces;
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_len1;
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_len2;
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_len3;
static lean_once_cell_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_is__empty1___closed__0_once = LEAN_ONCE_CELL_INITIALIZER;
static lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_is__empty1___closed__0;
static lean_once_cell_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_is__empty1___closed__1_once = LEAN_ONCE_CELL_INITIALIZER;
static uint8_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_is__empty1___closed__1;
LEAN_EXPORT uint8_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_is__empty1;
static const lean_string_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_is__empty2___closed__0_value = {.m_header = {.m_rc = 0, .m_cs_sz = 0, .m_other = 0, .m_tag = 249}, .m_size = 6, .m_capacity = 6, .m_length = 5, .m_data = "hello"};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_is__empty2___closed__0 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_is__empty2___closed__0_value;
static lean_once_cell_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_is__empty2___closed__1_once = LEAN_ONCE_CELL_INITIALIZER;
static lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_is__empty2___closed__1;
static lean_once_cell_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_is__empty2___closed__2_once = LEAN_ONCE_CELL_INITIALIZER;
static uint8_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_is__empty2___closed__2;
LEAN_EXPORT uint8_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_is__empty2;
static const lean_string_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_name___closed__0_value = {.m_header = {.m_rc = 0, .m_cs_sz = 0, .m_other = 0, .m_tag = 249}, .m_size = 6, .m_capacity = 6, .m_length = 5, .m_data = "Alice"};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_name___closed__0 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_name___closed__0_value;
LEAN_EXPORT const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_name = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_name___closed__0_value;
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_age;
static const lean_string_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_intro1___closed__0_value = {.m_header = {.m_rc = 0, .m_cs_sz = 0, .m_other = 0, .m_tag = 249}, .m_size = 18, .m_capacity = 18, .m_length = 17, .m_data = "My name is Alice."};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_intro1___closed__0 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_intro1___closed__0_value;
LEAN_EXPORT const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_intro1 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_intro1___closed__0_value;
static const lean_string_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_intro2___closed__0_value = {.m_header = {.m_rc = 0, .m_cs_sz = 0, .m_other = 0, .m_tag = 249}, .m_size = 23, .m_capacity = 23, .m_length = 22, .m_data = "Alice is 30 years old."};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_intro2___closed__0 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_intro2___closed__0_value;
LEAN_EXPORT const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_intro2 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_intro2___closed__0_value;
static const lean_string_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_intro3___closed__0_value = {.m_header = {.m_rc = 0, .m_cs_sz = 0, .m_other = 0, .m_tag = 249}, .m_size = 29, .m_capacity = 29, .m_length = 28, .m_data = "Next year, Alice will be 31."};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_intro3___closed__0 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_intro3___closed__0_value;
LEAN_EXPORT const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_intro3 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_intro3___closed__0_value;
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_name__length;
static const lean_string_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_intro4___closed__0_value = {.m_header = {.m_rc = 0, .m_cs_sz = 0, .m_other = 0, .m_tag = 249}, .m_size = 21, .m_capacity = 21, .m_length = 20, .m_data = "Alice has 5 letters."};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_intro4___closed__0 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_intro4___closed__0_value;
LEAN_EXPORT const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_intro4 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_intro4___closed__0_value;
LEAN_EXPORT uint8_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_eq1;
LEAN_EXPORT uint8_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_eq2;
LEAN_EXPORT uint8_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_ne1;
static const lean_string_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_lt1___closed__0_value = {.m_header = {.m_rc = 0, .m_cs_sz = 0, .m_other = 0, .m_tag = 249}, .m_size = 6, .m_capacity = 6, .m_length = 5, .m_data = "apple"};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_lt1___closed__0 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_lt1___closed__0_value;
static const lean_string_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_lt1___closed__1_value = {.m_header = {.m_rc = 0, .m_cs_sz = 0, .m_other = 0, .m_tag = 249}, .m_size = 7, .m_capacity = 7, .m_length = 6, .m_data = "banana"};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_lt1___closed__1 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_lt1___closed__1_value;
static lean_once_cell_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_lt1___closed__2_once = LEAN_ONCE_CELL_INITIALIZER;
static uint8_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_lt1___closed__2;
LEAN_EXPORT uint8_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_lt1;
static lean_once_cell_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_le1___closed__0_once = LEAN_ONCE_CELL_INITIALIZER;
static uint8_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_le1___closed__0;
LEAN_EXPORT uint8_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_le1;
static const lean_string_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_gt1___closed__0_value = {.m_header = {.m_rc = 0, .m_cs_sz = 0, .m_other = 0, .m_tag = 249}, .m_size = 4, .m_capacity = 4, .m_length = 3, .m_data = "zoo"};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_gt1___closed__0 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_gt1___closed__0_value;
static lean_once_cell_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_gt1___closed__1_once = LEAN_ONCE_CELL_INITIALIZER;
static uint8_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_gt1___closed__1;
LEAN_EXPORT uint8_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_gt1;
static const lean_string_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_chars___closed__0_value = {.m_header = {.m_rc = 0, .m_cs_sz = 0, .m_other = 0, .m_tag = 249}, .m_size = 6, .m_capacity = 6, .m_length = 5, .m_data = "Hello"};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_chars___closed__0 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_chars___closed__0_value;
static lean_once_cell_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_chars___closed__1_once = LEAN_ONCE_CELL_INITIALIZER;
static lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_chars___closed__1;
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_chars;
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_from__chars___closed__0___boxed__const__1;
static lean_once_cell_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_from__chars___closed__0_once = LEAN_ONCE_CELL_INITIALIZER;
static lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_from__chars___closed__0;
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_from__chars___closed__1___boxed__const__1;
static lean_once_cell_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_from__chars___closed__1_once = LEAN_ONCE_CELL_INITIALIZER;
static lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_from__chars___closed__1;
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_from__chars___closed__2___boxed__const__1;
static lean_once_cell_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_from__chars___closed__2_once = LEAN_ONCE_CELL_INITIALIZER;
static lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_from__chars___closed__2;
static lean_once_cell_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_from__chars___closed__3_once = LEAN_ONCE_CELL_INITIALIZER;
static lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_from__chars___closed__3;
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_from__chars;
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_stringReverse(lean_object*);
static lean_once_cell_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_reversed___closed__0_once = LEAN_ONCE_CELL_INITIALIZER;
static lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_reversed___closed__0;
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_reversed;
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_charAt_getAt(lean_object*, lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_charAt_getAt___boxed(lean_object*, lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_charAt(lean_object*, lean_object*);
static lean_once_cell_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_first__char___closed__0_once = LEAN_ONCE_CELL_INITIALIZER;
static lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_first__char___closed__0;
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_first__char;
static lean_once_cell_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_fifth__char___closed__0_once = LEAN_ONCE_CELL_INITIALIZER;
static lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_fifth__char___closed__0;
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_fifth__char;
static lean_once_cell_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_out__of__bounds___closed__0_once = LEAN_ONCE_CELL_INITIALIZER;
static lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_out__of__bounds___closed__0;
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_out__of__bounds;
static lean_once_cell_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_front__char___closed__0_once = LEAN_ONCE_CELL_INITIALIZER;
static lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_front__char___closed__0;
static lean_once_cell_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_front__char___closed__1_once = LEAN_ONCE_CELL_INITIALIZER;
static lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_front__char___closed__1;
static lean_once_cell_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_front__char___closed__2_once = LEAN_ONCE_CELL_INITIALIZER;
static lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_front__char___closed__2;
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_front__char;
static lean_once_cell_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_back__char___closed__0_once = LEAN_ONCE_CELL_INITIALIZER;
static lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_back__char___closed__0;
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_back__char;
LEAN_EXPORT uint32_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_getOrDefault(lean_object*, lean_object*, uint32_t);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_getOrDefault___boxed(lean_object*, lean_object*, lean_object*);
static lean_once_cell_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_get__or__default___closed__0_once = LEAN_ONCE_CELL_INITIALIZER;
static uint32_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_get__or__default___closed__0;
LEAN_EXPORT uint32_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_get__or__default;
static lean_once_cell_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_get__default___closed__0_once = LEAN_ONCE_CELL_INITIALIZER;
static uint32_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_get__default___closed__0;
LEAN_EXPORT uint32_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_get__default;
static const lean_array_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_takeChars___closed__0_value = {.m_header = {.m_rc = 0, .m_cs_sz = sizeof(lean_array_object) + sizeof(void*)*0, .m_other = 0, .m_tag = 246}, .m_size = 0, .m_capacity = 0, .m_data = {}};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_takeChars___closed__0 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_takeChars___closed__0_value;
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_takeChars(lean_object*, lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_dropChars(lean_object*, lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_substr(lean_object*, lean_object*, lean_object*);
static lean_once_cell_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_take5___closed__0_once = LEAN_ONCE_CELL_INITIALIZER;
static lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_take5___closed__0;
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_take5;
static lean_once_cell_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_drop7___closed__0_once = LEAN_ONCE_CELL_INITIALIZER;
static lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_drop7___closed__0;
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_drop7;
static lean_once_cell_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_substr1___closed__0_once = LEAN_ONCE_CELL_INITIALIZER;
static lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_substr1___closed__0;
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_substr1;
static lean_once_cell_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_substr2___closed__0_once = LEAN_ONCE_CELL_INITIALIZER;
static lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_substr2___closed__0;
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_substr2;
static lean_once_cell_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_upper___closed__0_once = LEAN_ONCE_CELL_INITIALIZER;
static lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_upper___closed__0;
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_upper;
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_String_mapAux___at___00Lean4Tutorial_Examples_Basics_Strings_lower_spec__0(lean_object*, lean_object*);
static const lean_string_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_lower___closed__0_value = {.m_header = {.m_rc = 0, .m_cs_sz = 0, .m_other = 0, .m_tag = 249}, .m_size = 6, .m_capacity = 6, .m_length = 5, .m_data = "HELLO"};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_lower___closed__0 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_lower___closed__0_value;
static lean_once_cell_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_lower___closed__1_once = LEAN_ONCE_CELL_INITIALIZER;
static lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_lower___closed__1;
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_lower;
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_trimLeft_dropSpaces(lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_trimLeft(lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_trimRight(lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_trim(lean_object*);
static const lean_string_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_trimmed1___closed__0_value = {.m_header = {.m_rc = 0, .m_cs_sz = 0, .m_other = 0, .m_tag = 249}, .m_size = 10, .m_capacity = 10, .m_length = 9, .m_data = "  hello  "};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_trimmed1___closed__0 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_trimmed1___closed__0_value;
static lean_once_cell_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_trimmed1___closed__1_once = LEAN_ONCE_CELL_INITIALIZER;
static lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_trimmed1___closed__1;
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_trimmed1;
static const lean_string_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_trimmed2___closed__0_value = {.m_header = {.m_rc = 0, .m_cs_sz = 0, .m_other = 0, .m_tag = 249}, .m_size = 12, .m_capacity = 12, .m_length = 11, .m_data = "   hello   "};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_trimmed2___closed__0 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_trimmed2___closed__0_value;
static lean_once_cell_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_trimmed2___closed__1_once = LEAN_ONCE_CELL_INITIALIZER;
static lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_trimmed2___closed__1;
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_trimmed2;
static const lean_string_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_triml___closed__0_value = {.m_header = {.m_rc = 0, .m_cs_sz = 0, .m_other = 0, .m_tag = 249}, .m_size = 8, .m_capacity = 8, .m_length = 7, .m_data = "  hello"};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_triml___closed__0 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_triml___closed__0_value;
static lean_once_cell_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_triml___closed__1_once = LEAN_ONCE_CELL_INITIALIZER;
static lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_triml___closed__1;
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_triml;
static const lean_string_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_trimr___closed__0_value = {.m_header = {.m_rc = 0, .m_cs_sz = 0, .m_other = 0, .m_tag = 249}, .m_size = 8, .m_capacity = 8, .m_length = 7, .m_data = "hello  "};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_trimr___closed__0 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_trimr___closed__0_value;
static lean_once_cell_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_trimr___closed__1_once = LEAN_ONCE_CELL_INITIALIZER;
static lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_trimr___closed__1;
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_trimr;
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_List_mapTR_loop___at___00Lean4Tutorial_Examples_Basics_Strings_replaceChar_spec__0(uint32_t, uint32_t, lean_object*, lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_List_mapTR_loop___at___00Lean4Tutorial_Examples_Basics_Strings_replaceChar_spec__0___boxed(lean_object*, lean_object*, lean_object*, lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_replaceChar(lean_object*, uint32_t, uint32_t);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_replaceChar___boxed(lean_object*, lean_object*, lean_object*);
static lean_once_cell_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_replaced___closed__0_once = LEAN_ONCE_CELL_INITIALIZER;
static lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_replaced___closed__0;
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_replaced;
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_repeatString(lean_object*, lean_object*);
static const lean_string_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_repeated___closed__0_value = {.m_header = {.m_rc = 0, .m_cs_sz = 0, .m_other = 0, .m_tag = 249}, .m_size = 3, .m_capacity = 3, .m_length = 2, .m_data = "ha"};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_repeated___closed__0 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_repeated___closed__0_value;
static lean_once_cell_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_repeated___closed__1_once = LEAN_ONCE_CELL_INITIALIZER;
static lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_repeated___closed__1;
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_repeated;
LEAN_EXPORT uint8_t lp_lean4_x2dtutorial_WellFounded_opaqueFix_u2083___at___00String_Slice_contains___at___00Lean4Tutorial_Examples_Basics_Strings_contains1_spec__0_spec__0___redArg(lean_object*, lean_object*, uint8_t);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_WellFounded_opaqueFix_u2083___at___00String_Slice_contains___at___00Lean4Tutorial_Examples_Basics_Strings_contains1_spec__0_spec__0___redArg___boxed(lean_object*, lean_object*, lean_object*);
static const lean_string_object lp_lean4_x2dtutorial_String_Slice_contains___at___00Lean4Tutorial_Examples_Basics_Strings_contains1_spec__0___closed__0_value = {.m_header = {.m_rc = 0, .m_cs_sz = 0, .m_other = 0, .m_tag = 249}, .m_size = 6, .m_capacity = 6, .m_length = 5, .m_data = "World"};
static const lean_object* lp_lean4_x2dtutorial_String_Slice_contains___at___00Lean4Tutorial_Examples_Basics_Strings_contains1_spec__0___closed__0 = (const lean_object*)&lp_lean4_x2dtutorial_String_Slice_contains___at___00Lean4Tutorial_Examples_Basics_Strings_contains1_spec__0___closed__0_value;
static lean_once_cell_t lp_lean4_x2dtutorial_String_Slice_contains___at___00Lean4Tutorial_Examples_Basics_Strings_contains1_spec__0___closed__1_once = LEAN_ONCE_CELL_INITIALIZER;
static lean_object* lp_lean4_x2dtutorial_String_Slice_contains___at___00Lean4Tutorial_Examples_Basics_Strings_contains1_spec__0___closed__1;
static lean_once_cell_t lp_lean4_x2dtutorial_String_Slice_contains___at___00Lean4Tutorial_Examples_Basics_Strings_contains1_spec__0___closed__2_once = LEAN_ONCE_CELL_INITIALIZER;
static uint8_t lp_lean4_x2dtutorial_String_Slice_contains___at___00Lean4Tutorial_Examples_Basics_Strings_contains1_spec__0___closed__2;
static lean_once_cell_t lp_lean4_x2dtutorial_String_Slice_contains___at___00Lean4Tutorial_Examples_Basics_Strings_contains1_spec__0___closed__3_once = LEAN_ONCE_CELL_INITIALIZER;
static lean_object* lp_lean4_x2dtutorial_String_Slice_contains___at___00Lean4Tutorial_Examples_Basics_Strings_contains1_spec__0___closed__3;
static lean_once_cell_t lp_lean4_x2dtutorial_String_Slice_contains___at___00Lean4Tutorial_Examples_Basics_Strings_contains1_spec__0___closed__4_once = LEAN_ONCE_CELL_INITIALIZER;
static lean_object* lp_lean4_x2dtutorial_String_Slice_contains___at___00Lean4Tutorial_Examples_Basics_Strings_contains1_spec__0___closed__4;
static lean_once_cell_t lp_lean4_x2dtutorial_String_Slice_contains___at___00Lean4Tutorial_Examples_Basics_Strings_contains1_spec__0___closed__5_once = LEAN_ONCE_CELL_INITIALIZER;
static lean_object* lp_lean4_x2dtutorial_String_Slice_contains___at___00Lean4Tutorial_Examples_Basics_Strings_contains1_spec__0___closed__5;
static const lean_ctor_object lp_lean4_x2dtutorial_String_Slice_contains___at___00Lean4Tutorial_Examples_Basics_Strings_contains1_spec__0___closed__6_value = {.m_header = {.m_rc = 0, .m_cs_sz = sizeof(lean_ctor_object) + sizeof(void*)*1 + 0, .m_other = 1, .m_tag = 0}, .m_objs = {((lean_object*)(((size_t)(0) << 1) | 1))}};
static const lean_object* lp_lean4_x2dtutorial_String_Slice_contains___at___00Lean4Tutorial_Examples_Basics_Strings_contains1_spec__0___closed__6 = (const lean_object*)&lp_lean4_x2dtutorial_String_Slice_contains___at___00Lean4Tutorial_Examples_Basics_Strings_contains1_spec__0___closed__6_value;
LEAN_EXPORT uint8_t lp_lean4_x2dtutorial_String_Slice_contains___at___00Lean4Tutorial_Examples_Basics_Strings_contains1_spec__0(lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_String_Slice_contains___at___00Lean4Tutorial_Examples_Basics_Strings_contains1_spec__0___boxed(lean_object*);
static lean_once_cell_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_contains1___closed__0_once = LEAN_ONCE_CELL_INITIALIZER;
static lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_contains1___closed__0;
static lean_once_cell_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_contains1___closed__1_once = LEAN_ONCE_CELL_INITIALIZER;
static lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_contains1___closed__1;
static lean_once_cell_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_contains1___closed__2_once = LEAN_ONCE_CELL_INITIALIZER;
static uint8_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_contains1___closed__2;
LEAN_EXPORT uint8_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_contains1;
LEAN_EXPORT uint8_t lp_lean4_x2dtutorial_WellFounded_opaqueFix_u2083___at___00String_Slice_contains___at___00Lean4Tutorial_Examples_Basics_Strings_contains1_spec__0_spec__0(lean_object*, lean_object*, lean_object*, lean_object*, uint8_t, lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_WellFounded_opaqueFix_u2083___at___00String_Slice_contains___at___00Lean4Tutorial_Examples_Basics_Strings_contains1_spec__0_spec__0___boxed(lean_object*, lean_object*, lean_object*, lean_object*, lean_object*, lean_object*);
static lean_once_cell_t lp_lean4_x2dtutorial_String_Slice_contains___at___00Lean4Tutorial_Examples_Basics_Strings_contains2_spec__0___closed__0_once = LEAN_ONCE_CELL_INITIALIZER;
static lean_object* lp_lean4_x2dtutorial_String_Slice_contains___at___00Lean4Tutorial_Examples_Basics_Strings_contains2_spec__0___closed__0;
static lean_once_cell_t lp_lean4_x2dtutorial_String_Slice_contains___at___00Lean4Tutorial_Examples_Basics_Strings_contains2_spec__0___closed__1_once = LEAN_ONCE_CELL_INITIALIZER;
static lean_object* lp_lean4_x2dtutorial_String_Slice_contains___at___00Lean4Tutorial_Examples_Basics_Strings_contains2_spec__0___closed__1;
static lean_once_cell_t lp_lean4_x2dtutorial_String_Slice_contains___at___00Lean4Tutorial_Examples_Basics_Strings_contains2_spec__0___closed__2_once = LEAN_ONCE_CELL_INITIALIZER;
static lean_object* lp_lean4_x2dtutorial_String_Slice_contains___at___00Lean4Tutorial_Examples_Basics_Strings_contains2_spec__0___closed__2;
LEAN_EXPORT uint8_t lp_lean4_x2dtutorial_String_Slice_contains___at___00Lean4Tutorial_Examples_Basics_Strings_contains2_spec__0(lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_String_Slice_contains___at___00Lean4Tutorial_Examples_Basics_Strings_contains2_spec__0___boxed(lean_object*);
static lean_once_cell_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_contains2___closed__0_once = LEAN_ONCE_CELL_INITIALIZER;
static uint8_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_contains2___closed__0;
LEAN_EXPORT uint8_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_contains2;
static const lean_string_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_prefix1___closed__0_value = {.m_header = {.m_rc = 0, .m_cs_sz = 0, .m_other = 0, .m_tag = 249}, .m_size = 3, .m_capacity = 3, .m_length = 2, .m_data = "He"};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_prefix1___closed__0 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_prefix1___closed__0_value;
static lean_once_cell_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_prefix1___closed__1_once = LEAN_ONCE_CELL_INITIALIZER;
static lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_prefix1___closed__1;
static lean_once_cell_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_prefix1___closed__2_once = LEAN_ONCE_CELL_INITIALIZER;
static uint8_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_prefix1___closed__2;
static lean_once_cell_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_prefix1___closed__3_once = LEAN_ONCE_CELL_INITIALIZER;
static uint8_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_prefix1___closed__3;
LEAN_EXPORT uint8_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_prefix1;
static const lean_string_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_suffix1___closed__0_value = {.m_header = {.m_rc = 0, .m_cs_sz = 0, .m_other = 0, .m_tag = 249}, .m_size = 3, .m_capacity = 3, .m_length = 2, .m_data = "lo"};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_suffix1___closed__0 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_suffix1___closed__0_value;
static lean_once_cell_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_suffix1___closed__1_once = LEAN_ONCE_CELL_INITIALIZER;
static lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_suffix1___closed__1;
static lean_once_cell_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_suffix1___closed__2_once = LEAN_ONCE_CELL_INITIALIZER;
static uint8_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_suffix1___closed__2;
static lean_once_cell_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_suffix1___closed__3_once = LEAN_ONCE_CELL_INITIALIZER;
static lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_suffix1___closed__3;
static lean_once_cell_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_suffix1___closed__4_once = LEAN_ONCE_CELL_INITIALIZER;
static uint8_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_suffix1___closed__4;
LEAN_EXPORT uint8_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_suffix1;
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_findChar_findPos(lean_object*, uint32_t, lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_findChar_findPos___boxed(lean_object*, lean_object*, lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_findChar(lean_object*, uint32_t);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_findChar___boxed(lean_object*, lean_object*);
static lean_once_cell_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_find__h___closed__0_once = LEAN_ONCE_CELL_INITIALIZER;
static lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_find__h___closed__0;
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_find__h;
static lean_once_cell_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_find__l___closed__0_once = LEAN_ONCE_CELL_INITIALIZER;
static lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_find__l___closed__0;
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_find__l;
static lean_once_cell_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_find__z___closed__0_once = LEAN_ONCE_CELL_INITIALIZER;
static lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_find__z___closed__0;
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_find__z;
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_List_filterTR_loop___at___00Lean4Tutorial_Examples_Basics_Strings_countChar_spec__0(uint32_t, lean_object*, lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_List_filterTR_loop___at___00Lean4Tutorial_Examples_Basics_Strings_countChar_spec__0___boxed(lean_object*, lean_object*, lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_countChar(lean_object*, uint32_t);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_countChar___boxed(lean_object*, lean_object*);
static lean_once_cell_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_count__l___closed__0_once = LEAN_ONCE_CELL_INITIALIZER;
static lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_count__l___closed__0;
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_count__l;
static const lean_string_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_parse__nat1___closed__0_value = {.m_header = {.m_rc = 0, .m_cs_sz = 0, .m_other = 0, .m_tag = 249}, .m_size = 3, .m_capacity = 3, .m_length = 2, .m_data = "42"};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_parse__nat1___closed__0 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_parse__nat1___closed__0_value;
static lean_once_cell_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_parse__nat1___closed__1_once = LEAN_ONCE_CELL_INITIALIZER;
static lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_parse__nat1___closed__1;
static lean_once_cell_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_parse__nat1___closed__2_once = LEAN_ONCE_CELL_INITIALIZER;
static lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_parse__nat1___closed__2;
static lean_once_cell_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_parse__nat1___closed__3_once = LEAN_ONCE_CELL_INITIALIZER;
static lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_parse__nat1___closed__3;
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_parse__nat1;
static const lean_string_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_parse__nat2___closed__0_value = {.m_header = {.m_rc = 0, .m_cs_sz = 0, .m_other = 0, .m_tag = 249}, .m_size = 4, .m_capacity = 4, .m_length = 3, .m_data = "abc"};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_parse__nat2___closed__0 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_parse__nat2___closed__0_value;
static lean_once_cell_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_parse__nat2___closed__1_once = LEAN_ONCE_CELL_INITIALIZER;
static lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_parse__nat2___closed__1;
static lean_once_cell_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_parse__nat2___closed__2_once = LEAN_ONCE_CELL_INITIALIZER;
static lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_parse__nat2___closed__2;
static lean_once_cell_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_parse__nat2___closed__3_once = LEAN_ONCE_CELL_INITIALIZER;
static lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_parse__nat2___closed__3;
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_parse__nat2;
LEAN_EXPORT const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_nat__to__string = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_parse__nat1___closed__0_value;
static lean_once_cell_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_int__to__string___closed__0_once = LEAN_ONCE_CELL_INITIALIZER;
static lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_int__to__string___closed__0;
static lean_once_cell_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_int__to__string___closed__1_once = LEAN_ONCE_CELL_INITIALIZER;
static lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_int__to__string___closed__1;
static lean_once_cell_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_int__to__string___closed__2_once = LEAN_ONCE_CELL_INITIALIZER;
static lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_int__to__string___closed__2;
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_int__to__string;
static const lean_string_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_bool__to__string___closed__0_value = {.m_header = {.m_rc = 0, .m_cs_sz = 0, .m_other = 0, .m_tag = 249}, .m_size = 5, .m_capacity = 5, .m_length = 4, .m_data = "true"};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_bool__to__string___closed__0 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_bool__to__string___closed__0_value;
LEAN_EXPORT const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_bool__to__string = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_bool__to__string___closed__0_value;
static const lean_string_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_poem___closed__0_value = {.m_header = {.m_rc = 0, .m_cs_sz = 0, .m_other = 0, .m_tag = 249}, .m_size = 76, .m_capacity = 76, .m_length = 27, .m_data = "床前明月光，\n疑是地上霜。\n举头望明月，\n低头思故乡。"};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_poem___closed__0 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_poem___closed__0_value;
LEAN_EXPORT const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_poem = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_poem___closed__0_value;
static const lean_string_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_code__example___closed__0_value = {.m_header = {.m_rc = 0, .m_cs_sz = 0, .m_other = 0, .m_tag = 249}, .m_size = 42, .m_capacity = 42, .m_length = 41, .m_data = "def hello :=\n  IO.println \"Hello, World!\""};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_code__example___closed__0 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_code__example___closed__0_value;
LEAN_EXPORT const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_code__example = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_code__example___closed__0_value;
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_splitOnChar_splitAux(lean_object*, uint32_t, lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_splitOnChar_splitAux___boxed(lean_object*, lean_object*, lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_splitOnChar(lean_object*, uint32_t);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_splitOnChar___boxed(lean_object*, lean_object*);
static const lean_string_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_split__csv___closed__0_value = {.m_header = {.m_rc = 0, .m_cs_sz = 0, .m_other = 0, .m_tag = 249}, .m_size = 6, .m_capacity = 6, .m_length = 5, .m_data = "a,b,c"};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_split__csv___closed__0 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_split__csv___closed__0_value;
static lean_once_cell_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_split__csv___closed__1_once = LEAN_ONCE_CELL_INITIALIZER;
static lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_split__csv___closed__1;
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_split__csv;
static const lean_string_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_split__space___closed__0_value = {.m_header = {.m_rc = 0, .m_cs_sz = 0, .m_other = 0, .m_tag = 249}, .m_size = 12, .m_capacity = 12, .m_length = 11, .m_data = "hello world"};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_split__space___closed__0 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_split__space___closed__0_value;
static lean_once_cell_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_split__space___closed__1_once = LEAN_ONCE_CELL_INITIALIZER;
static lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_split__space___closed__1;
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_split__space;
static const lean_string_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_format__example___closed__0_value = {.m_header = {.m_rc = 0, .m_cs_sz = 0, .m_other = 0, .m_tag = 249}, .m_size = 3, .m_capacity = 3, .m_length = 2, .m_data = ": "};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_format__example___closed__0 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_format__example___closed__0_value;
static const lean_string_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_format__example___closed__1_value = {.m_header = {.m_rc = 0, .m_cs_sz = 0, .m_other = 0, .m_tag = 249}, .m_size = 5, .m_capacity = 5, .m_length = 2, .m_data = " 分"};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_format__example___closed__1 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_format__example___closed__1_value;
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_format__example(lean_object*, lean_object*);
static lean_once_cell_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_alice__score___closed__0_once = LEAN_ONCE_CELL_INITIALIZER;
static lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_alice__score___closed__0;
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_alice__score;
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_padRight(lean_object*, lean_object*, uint32_t);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_padRight___boxed(lean_object*, lean_object*, lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_padLeft(lean_object*, lean_object*, uint32_t);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_padLeft___boxed(lean_object*, lean_object*, lean_object*);
static const lean_string_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_format__row___closed__0_value = {.m_header = {.m_rc = 0, .m_cs_sz = 0, .m_other = 0, .m_tag = 249}, .m_size = 3, .m_capacity = 3, .m_length = 2, .m_data = "| "};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_format__row___closed__0 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_format__row___closed__0_value;
static const lean_string_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_format__row___closed__1_value = {.m_header = {.m_rc = 0, .m_cs_sz = 0, .m_other = 0, .m_tag = 249}, .m_size = 4, .m_capacity = 4, .m_length = 3, .m_data = " | "};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_format__row___closed__1 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_format__row___closed__1_value;
static const lean_string_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_format__row___closed__2_value = {.m_header = {.m_rc = 0, .m_cs_sz = 0, .m_other = 0, .m_tag = 249}, .m_size = 3, .m_capacity = 3, .m_length = 2, .m_data = " |"};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_format__row___closed__2 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_format__row___closed__2_value;
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_format__row(lean_object*, lean_object*);
static const lean_string_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_table__header___closed__0_value = {.m_header = {.m_rc = 0, .m_cs_sz = 0, .m_other = 0, .m_tag = 249}, .m_size = 7, .m_capacity = 7, .m_length = 2, .m_data = "姓名"};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_table__header___closed__0 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_table__header___closed__0_value;
static lean_once_cell_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_table__header___closed__1_once = LEAN_ONCE_CELL_INITIALIZER;
static lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_table__header___closed__1;
static lean_once_cell_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_table__header___closed__2_once = LEAN_ONCE_CELL_INITIALIZER;
static lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_table__header___closed__2;
static lean_once_cell_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_table__header___closed__3_once = LEAN_ONCE_CELL_INITIALIZER;
static lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_table__header___closed__3;
static const lean_string_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_table__header___closed__4_value = {.m_header = {.m_rc = 0, .m_cs_sz = 0, .m_other = 0, .m_tag = 249}, .m_size = 7, .m_capacity = 7, .m_length = 2, .m_data = "分数"};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_table__header___closed__4 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_table__header___closed__4_value;
static lean_once_cell_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_table__header___closed__5_once = LEAN_ONCE_CELL_INITIALIZER;
static lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_table__header___closed__5;
static lean_once_cell_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_table__header___closed__6_once = LEAN_ONCE_CELL_INITIALIZER;
static lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_table__header___closed__6;
static lean_once_cell_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_table__header___closed__7_once = LEAN_ONCE_CELL_INITIALIZER;
static lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_table__header___closed__7;
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_table__header;
static lean_once_cell_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_table__row1___closed__0_once = LEAN_ONCE_CELL_INITIALIZER;
static lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_table__row1___closed__0;
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_table__row1;
static const lean_string_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_table__row2___closed__0_value = {.m_header = {.m_rc = 0, .m_cs_sz = 0, .m_other = 0, .m_tag = 249}, .m_size = 4, .m_capacity = 4, .m_length = 3, .m_data = "Bob"};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_table__row2___closed__0 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_table__row2___closed__0_value;
static lean_once_cell_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_table__row2___closed__1_once = LEAN_ONCE_CELL_INITIALIZER;
static lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_table__row2___closed__1;
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_table__row2;
static const lean_string_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_table___closed__0_value = {.m_header = {.m_rc = 0, .m_cs_sz = 0, .m_other = 0, .m_tag = 249}, .m_size = 2, .m_capacity = 2, .m_length = 1, .m_data = "\n"};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_table___closed__0 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_table___closed__0_value;
static lean_once_cell_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_table___closed__1_once = LEAN_ONCE_CELL_INITIALIZER;
static lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_table___closed__1;
static lean_once_cell_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_table___closed__2_once = LEAN_ONCE_CELL_INITIALIZER;
static lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_table___closed__2;
static lean_once_cell_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_table___closed__3_once = LEAN_ONCE_CELL_INITIALIZER;
static lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_table___closed__3;
static lean_once_cell_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_table___closed__4_once = LEAN_ONCE_CELL_INITIALIZER;
static lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_table___closed__4;
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_table;
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_List_foldl___at___00Lean4Tutorial_Examples_Basics_Strings_joined_spec__0(lean_object* v_x_24_, lean_object* v_x_25_){
_start:
{
if (lean_obj_tag(v_x_25_) == 0)
{
return v_x_24_;
}
else
{
lean_object* v_head_26_; lean_object* v_tail_27_; lean_object* v___x_28_; 
v_head_26_ = lean_ctor_get(v_x_25_, 0);
v_tail_27_ = lean_ctor_get(v_x_25_, 1);
v___x_28_ = lean_string_append(v_x_24_, v_head_26_);
v_x_24_ = v___x_28_;
v_x_25_ = v_tail_27_;
goto _start;
}
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_List_foldl___at___00Lean4Tutorial_Examples_Basics_Strings_joined_spec__0___boxed(lean_object* v_x_30_, lean_object* v_x_31_){
_start:
{
lean_object* v_res_32_; 
v_res_32_ = lp_lean4_x2dtutorial_List_foldl___at___00Lean4Tutorial_Examples_Basics_Strings_joined_spec__0(v_x_30_, v_x_31_);
lean_dec(v_x_31_);
return v_res_32_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_joined___closed__0(void){
_start:
{
lean_object* v___x_33_; lean_object* v___x_34_; lean_object* v___x_35_; 
v___x_33_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_words));
v___x_34_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_empty___closed__0));
v___x_35_ = lp_lean4_x2dtutorial_List_foldl___at___00Lean4Tutorial_Examples_Basics_Strings_joined_spec__0(v___x_34_, v___x_33_);
return v___x_35_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_joined(void){
_start:
{
lean_object* v___x_36_; 
v___x_36_ = lean_obj_once(&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_joined___closed__0, &lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_joined___closed__0_once, _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_joined___closed__0);
return v___x_36_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_with__spaces___closed__1(void){
_start:
{
lean_object* v___x_38_; lean_object* v___x_39_; lean_object* v___x_40_; 
v___x_38_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_words));
v___x_39_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_with__spaces___closed__0));
v___x_40_ = l_String_intercalate(v___x_39_, v___x_38_);
return v___x_40_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_with__spaces(void){
_start:
{
lean_object* v___x_41_; 
v___x_41_ = lean_obj_once(&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_with__spaces___closed__1, &lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_with__spaces___closed__1_once, _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_with__spaces___closed__1);
return v___x_41_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_len1(void){
_start:
{
lean_object* v___x_42_; 
v___x_42_ = lean_unsigned_to_nat(5u);
return v___x_42_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_len2(void){
_start:
{
lean_object* v___x_43_; 
v___x_43_ = lean_unsigned_to_nat(0u);
return v___x_43_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_len3(void){
_start:
{
lean_object* v___x_44_; 
v___x_44_ = lean_unsigned_to_nat(4u);
return v___x_44_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_is__empty1___closed__0(void){
_start:
{
lean_object* v___x_45_; lean_object* v___x_46_; 
v___x_45_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_empty___closed__0));
v___x_46_ = lean_string_utf8_byte_size(v___x_45_);
return v___x_46_;
}
}
static uint8_t _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_is__empty1___closed__1(void){
_start:
{
lean_object* v___x_47_; lean_object* v___x_48_; uint8_t v___x_49_; 
v___x_47_ = lean_unsigned_to_nat(0u);
v___x_48_ = lean_obj_once(&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_is__empty1___closed__0, &lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_is__empty1___closed__0_once, _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_is__empty1___closed__0);
v___x_49_ = lean_nat_dec_eq(v___x_48_, v___x_47_);
return v___x_49_;
}
}
static uint8_t _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_is__empty1(void){
_start:
{
uint8_t v___x_50_; 
v___x_50_ = lean_uint8_once(&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_is__empty1___closed__1, &lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_is__empty1___closed__1_once, _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_is__empty1___closed__1);
return v___x_50_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_is__empty2___closed__1(void){
_start:
{
lean_object* v___x_52_; lean_object* v___x_53_; 
v___x_52_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_is__empty2___closed__0));
v___x_53_ = lean_string_utf8_byte_size(v___x_52_);
return v___x_53_;
}
}
static uint8_t _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_is__empty2___closed__2(void){
_start:
{
lean_object* v___x_54_; lean_object* v___x_55_; uint8_t v___x_56_; 
v___x_54_ = lean_unsigned_to_nat(0u);
v___x_55_ = lean_obj_once(&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_is__empty2___closed__1, &lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_is__empty2___closed__1_once, _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_is__empty2___closed__1);
v___x_56_ = lean_nat_dec_eq(v___x_55_, v___x_54_);
return v___x_56_;
}
}
static uint8_t _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_is__empty2(void){
_start:
{
uint8_t v___x_57_; 
v___x_57_ = lean_uint8_once(&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_is__empty2___closed__2, &lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_is__empty2___closed__2_once, _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_is__empty2___closed__2);
return v___x_57_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_age(void){
_start:
{
lean_object* v___x_60_; 
v___x_60_ = lean_unsigned_to_nat(30u);
return v___x_60_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_name__length(void){
_start:
{
lean_object* v___x_67_; 
v___x_67_ = lean_unsigned_to_nat(5u);
return v___x_67_;
}
}
static uint8_t _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_eq1(void){
_start:
{
uint8_t v___x_70_; 
v___x_70_ = 1;
return v___x_70_;
}
}
static uint8_t _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_eq2(void){
_start:
{
uint8_t v___x_71_; 
v___x_71_ = 0;
return v___x_71_;
}
}
static uint8_t _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_ne1(void){
_start:
{
uint8_t v___x_72_; 
v___x_72_ = 1;
return v___x_72_;
}
}
static uint8_t _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_lt1___closed__2(void){
_start:
{
lean_object* v___x_75_; lean_object* v___x_76_; uint8_t v___x_77_; 
v___x_75_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_lt1___closed__1));
v___x_76_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_lt1___closed__0));
v___x_77_ = lean_string_dec_lt(v___x_76_, v___x_75_);
return v___x_77_;
}
}
static uint8_t _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_lt1(void){
_start:
{
uint8_t v___x_78_; 
v___x_78_ = lean_uint8_once(&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_lt1___closed__2, &lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_lt1___closed__2_once, _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_lt1___closed__2);
return v___x_78_;
}
}
static uint8_t _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_le1___closed__0(void){
_start:
{
lean_object* v___x_79_; uint8_t v___x_80_; 
v___x_79_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_lt1___closed__0));
v___x_80_ = l_String_decLE(v___x_79_, v___x_79_);
return v___x_80_;
}
}
static uint8_t _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_le1(void){
_start:
{
uint8_t v___x_81_; 
v___x_81_ = lean_uint8_once(&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_le1___closed__0, &lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_le1___closed__0_once, _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_le1___closed__0);
return v___x_81_;
}
}
static uint8_t _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_gt1___closed__1(void){
_start:
{
lean_object* v___x_83_; lean_object* v___x_84_; uint8_t v___x_85_; 
v___x_83_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_gt1___closed__0));
v___x_84_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_lt1___closed__0));
v___x_85_ = lean_string_dec_lt(v___x_84_, v___x_83_);
return v___x_85_;
}
}
static uint8_t _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_gt1(void){
_start:
{
uint8_t v___x_86_; 
v___x_86_ = lean_uint8_once(&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_gt1___closed__1, &lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_gt1___closed__1_once, _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_gt1___closed__1);
return v___x_86_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_chars___closed__1(void){
_start:
{
lean_object* v___x_88_; lean_object* v___x_89_; 
v___x_88_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_chars___closed__0));
v___x_89_ = lean_string_data(v___x_88_);
return v___x_89_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_chars(void){
_start:
{
lean_object* v___x_90_; 
v___x_90_ = lean_obj_once(&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_chars___closed__1, &lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_chars___closed__1_once, _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_chars___closed__1);
return v___x_90_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_from__chars___closed__0___boxed__const__1(void){
_start:
{
uint32_t v___x_91_; lean_object* v___x_92_; 
v___x_91_ = 99;
v___x_92_ = lean_box_uint32(v___x_91_);
return v___x_92_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_from__chars___closed__0(void){
_start:
{
lean_object* v___x_93_; lean_object* v___x_94_; lean_object* v___x_95_; 
v___x_93_ = lean_box(0);
v___x_94_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_from__chars___closed__0___boxed__const__1;
v___x_95_ = lean_alloc_ctor(1, 2, 0);
lean_ctor_set(v___x_95_, 0, v___x_94_);
lean_ctor_set(v___x_95_, 1, v___x_93_);
return v___x_95_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_from__chars___closed__1___boxed__const__1(void){
_start:
{
uint32_t v___x_96_; lean_object* v___x_97_; 
v___x_96_ = 98;
v___x_97_ = lean_box_uint32(v___x_96_);
return v___x_97_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_from__chars___closed__1(void){
_start:
{
lean_object* v___x_98_; lean_object* v___x_99_; lean_object* v___x_100_; 
v___x_98_ = lean_obj_once(&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_from__chars___closed__0, &lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_from__chars___closed__0_once, _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_from__chars___closed__0);
v___x_99_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_from__chars___closed__1___boxed__const__1;
v___x_100_ = lean_alloc_ctor(1, 2, 0);
lean_ctor_set(v___x_100_, 0, v___x_99_);
lean_ctor_set(v___x_100_, 1, v___x_98_);
return v___x_100_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_from__chars___closed__2___boxed__const__1(void){
_start:
{
uint32_t v___x_101_; lean_object* v___x_102_; 
v___x_101_ = 97;
v___x_102_ = lean_box_uint32(v___x_101_);
return v___x_102_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_from__chars___closed__2(void){
_start:
{
lean_object* v___x_103_; lean_object* v___x_104_; lean_object* v___x_105_; 
v___x_103_ = lean_obj_once(&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_from__chars___closed__1, &lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_from__chars___closed__1_once, _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_from__chars___closed__1);
v___x_104_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_from__chars___closed__2___boxed__const__1;
v___x_105_ = lean_alloc_ctor(1, 2, 0);
lean_ctor_set(v___x_105_, 0, v___x_104_);
lean_ctor_set(v___x_105_, 1, v___x_103_);
return v___x_105_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_from__chars___closed__3(void){
_start:
{
lean_object* v___x_106_; lean_object* v___x_107_; 
v___x_106_ = lean_obj_once(&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_from__chars___closed__2, &lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_from__chars___closed__2_once, _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_from__chars___closed__2);
v___x_107_ = lean_string_mk(v___x_106_);
return v___x_107_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_from__chars(void){
_start:
{
lean_object* v___x_108_; 
v___x_108_ = lean_obj_once(&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_from__chars___closed__3, &lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_from__chars___closed__3_once, _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_from__chars___closed__3);
return v___x_108_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_stringReverse(lean_object* v_s_109_){
_start:
{
lean_object* v___x_110_; lean_object* v___x_111_; lean_object* v___x_112_; 
v___x_110_ = lean_string_data(v_s_109_);
v___x_111_ = l_List_reverse___redArg(v___x_110_);
v___x_112_ = lean_string_mk(v___x_111_);
return v___x_112_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_reversed___closed__0(void){
_start:
{
lean_object* v___x_113_; lean_object* v___x_114_; 
v___x_113_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_chars___closed__0));
v___x_114_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_stringReverse(v___x_113_);
return v___x_114_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_reversed(void){
_start:
{
lean_object* v___x_115_; 
v___x_115_ = lean_obj_once(&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_reversed___closed__0, &lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_reversed___closed__0_once, _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_reversed___closed__0);
return v___x_115_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_charAt_getAt(lean_object* v_a_116_, lean_object* v_a_117_){
_start:
{
if (lean_obj_tag(v_a_116_) == 0)
{
lean_object* v___x_118_; 
lean_dec(v_a_117_);
v___x_118_ = lean_box(0);
return v___x_118_;
}
else
{
lean_object* v_head_119_; lean_object* v_tail_120_; lean_object* v_zero_121_; uint8_t v_isZero_122_; 
v_head_119_ = lean_ctor_get(v_a_116_, 0);
v_tail_120_ = lean_ctor_get(v_a_116_, 1);
v_zero_121_ = lean_unsigned_to_nat(0u);
v_isZero_122_ = lean_nat_dec_eq(v_a_117_, v_zero_121_);
if (v_isZero_122_ == 1)
{
lean_object* v___x_123_; 
lean_dec(v_a_117_);
lean_inc(v_head_119_);
v___x_123_ = lean_alloc_ctor(1, 1, 0);
lean_ctor_set(v___x_123_, 0, v_head_119_);
return v___x_123_;
}
else
{
lean_object* v_one_124_; lean_object* v_n_125_; 
v_one_124_ = lean_unsigned_to_nat(1u);
v_n_125_ = lean_nat_sub(v_a_117_, v_one_124_);
lean_dec(v_a_117_);
v_a_116_ = v_tail_120_;
v_a_117_ = v_n_125_;
goto _start;
}
}
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_charAt_getAt___boxed(lean_object* v_a_127_, lean_object* v_a_128_){
_start:
{
lean_object* v_res_129_; 
v_res_129_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_charAt_getAt(v_a_127_, v_a_128_);
lean_dec(v_a_127_);
return v_res_129_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_charAt(lean_object* v_s_130_, lean_object* v_n_131_){
_start:
{
lean_object* v___x_132_; lean_object* v___x_133_; 
v___x_132_ = lean_string_data(v_s_130_);
v___x_133_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_charAt_getAt(v___x_132_, v_n_131_);
lean_dec(v___x_132_);
return v___x_133_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_first__char___closed__0(void){
_start:
{
lean_object* v___x_134_; lean_object* v___x_135_; lean_object* v___x_136_; 
v___x_134_ = lean_unsigned_to_nat(0u);
v___x_135_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_chars___closed__0));
v___x_136_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_charAt(v___x_135_, v___x_134_);
return v___x_136_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_first__char(void){
_start:
{
lean_object* v___x_137_; 
v___x_137_ = lean_obj_once(&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_first__char___closed__0, &lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_first__char___closed__0_once, _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_first__char___closed__0);
return v___x_137_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_fifth__char___closed__0(void){
_start:
{
lean_object* v___x_138_; lean_object* v___x_139_; lean_object* v___x_140_; 
v___x_138_ = lean_unsigned_to_nat(4u);
v___x_139_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_chars___closed__0));
v___x_140_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_charAt(v___x_139_, v___x_138_);
return v___x_140_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_fifth__char(void){
_start:
{
lean_object* v___x_141_; 
v___x_141_ = lean_obj_once(&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_fifth__char___closed__0, &lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_fifth__char___closed__0_once, _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_fifth__char___closed__0);
return v___x_141_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_out__of__bounds___closed__0(void){
_start:
{
lean_object* v___x_142_; lean_object* v___x_143_; lean_object* v___x_144_; 
v___x_142_ = lean_unsigned_to_nat(10u);
v___x_143_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_chars___closed__0));
v___x_144_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_charAt(v___x_143_, v___x_142_);
return v___x_144_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_out__of__bounds(void){
_start:
{
lean_object* v___x_145_; 
v___x_145_ = lean_obj_once(&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_out__of__bounds___closed__0, &lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_out__of__bounds___closed__0_once, _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_out__of__bounds___closed__0);
return v___x_145_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_front__char___closed__0(void){
_start:
{
lean_object* v___x_146_; lean_object* v___x_147_; 
v___x_146_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_chars___closed__0));
v___x_147_ = lean_string_utf8_byte_size(v___x_146_);
return v___x_147_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_front__char___closed__1(void){
_start:
{
lean_object* v___x_148_; lean_object* v___x_149_; lean_object* v___x_150_; lean_object* v___x_151_; 
v___x_148_ = lean_obj_once(&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_front__char___closed__0, &lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_front__char___closed__0_once, _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_front__char___closed__0);
v___x_149_ = lean_unsigned_to_nat(0u);
v___x_150_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_chars___closed__0));
v___x_151_ = lean_alloc_ctor(0, 3, 0);
lean_ctor_set(v___x_151_, 0, v___x_150_);
lean_ctor_set(v___x_151_, 1, v___x_149_);
lean_ctor_set(v___x_151_, 2, v___x_148_);
return v___x_151_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_front__char___closed__2(void){
_start:
{
lean_object* v___x_152_; lean_object* v___x_153_; lean_object* v___x_154_; 
v___x_152_ = lean_unsigned_to_nat(0u);
v___x_153_ = lean_obj_once(&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_front__char___closed__1, &lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_front__char___closed__1_once, _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_front__char___closed__1);
v___x_154_ = l_String_Slice_Pos_get_x3f(v___x_153_, v___x_152_);
return v___x_154_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_front__char(void){
_start:
{
lean_object* v___x_155_; 
v___x_155_ = lean_obj_once(&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_front__char___closed__2, &lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_front__char___closed__2_once, _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_front__char___closed__2);
return v___x_155_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_back__char___closed__0(void){
_start:
{
lean_object* v___x_156_; lean_object* v___x_157_; lean_object* v___x_158_; 
v___x_156_ = lean_obj_once(&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_front__char___closed__0, &lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_front__char___closed__0_once, _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_front__char___closed__0);
v___x_157_ = lean_obj_once(&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_front__char___closed__1, &lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_front__char___closed__1_once, _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_front__char___closed__1);
v___x_158_ = l_String_Slice_Pos_prev_x3f(v___x_157_, v___x_156_);
return v___x_158_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_back__char(void){
_start:
{
lean_object* v___x_159_; lean_object* v___x_160_; 
v___x_159_ = lean_obj_once(&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_front__char___closed__1, &lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_front__char___closed__1_once, _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_front__char___closed__1);
v___x_160_ = lean_obj_once(&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_back__char___closed__0, &lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_back__char___closed__0_once, _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_back__char___closed__0);
if (lean_obj_tag(v___x_160_) == 0)
{
lean_object* v___x_161_; 
v___x_161_ = lean_box(0);
return v___x_161_;
}
else
{
lean_object* v_val_162_; lean_object* v___x_163_; 
v_val_162_ = lean_ctor_get(v___x_160_, 0);
v___x_163_ = l_String_Slice_Pos_get_x3f(v___x_159_, v_val_162_);
return v___x_163_;
}
}
}
LEAN_EXPORT uint32_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_getOrDefault(lean_object* v_s_164_, lean_object* v_n_165_, uint32_t v_default_166_){
_start:
{
lean_object* v___x_167_; 
v___x_167_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_charAt(v_s_164_, v_n_165_);
if (lean_obj_tag(v___x_167_) == 0)
{
return v_default_166_;
}
else
{
lean_object* v_val_168_; uint32_t v___x_169_; 
v_val_168_ = lean_ctor_get(v___x_167_, 0);
lean_inc(v_val_168_);
lean_dec_ref_known(v___x_167_, 1);
v___x_169_ = lean_unbox_uint32(v_val_168_);
lean_dec(v_val_168_);
return v___x_169_;
}
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_getOrDefault___boxed(lean_object* v_s_170_, lean_object* v_n_171_, lean_object* v_default_172_){
_start:
{
uint32_t v_default_boxed_173_; uint32_t v_res_174_; lean_object* v_r_175_; 
v_default_boxed_173_ = lean_unbox_uint32(v_default_172_);
lean_dec(v_default_172_);
v_res_174_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_getOrDefault(v_s_170_, v_n_171_, v_default_boxed_173_);
v_r_175_ = lean_box_uint32(v_res_174_);
return v_r_175_;
}
}
static uint32_t _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_get__or__default___closed__0(void){
_start:
{
uint32_t v___x_176_; lean_object* v___x_177_; lean_object* v___x_178_; uint32_t v___x_179_; 
v___x_176_ = 63;
v___x_177_ = lean_unsigned_to_nat(0u);
v___x_178_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_chars___closed__0));
v___x_179_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_getOrDefault(v___x_178_, v___x_177_, v___x_176_);
return v___x_179_;
}
}
static uint32_t _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_get__or__default(void){
_start:
{
uint32_t v___x_180_; 
v___x_180_ = lean_uint32_once(&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_get__or__default___closed__0, &lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_get__or__default___closed__0_once, _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_get__or__default___closed__0);
return v___x_180_;
}
}
static uint32_t _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_get__default___closed__0(void){
_start:
{
uint32_t v___x_181_; lean_object* v___x_182_; lean_object* v___x_183_; uint32_t v___x_184_; 
v___x_181_ = 63;
v___x_182_ = lean_unsigned_to_nat(10u);
v___x_183_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_chars___closed__0));
v___x_184_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_getOrDefault(v___x_183_, v___x_182_, v___x_181_);
return v___x_184_;
}
}
static uint32_t _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_get__default(void){
_start:
{
uint32_t v___x_185_; 
v___x_185_ = lean_uint32_once(&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_get__default___closed__0, &lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_get__default___closed__0_once, _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_get__default___closed__0);
return v___x_185_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_takeChars(lean_object* v_s_188_, lean_object* v_n_189_){
_start:
{
lean_object* v___x_190_; lean_object* v___x_191_; lean_object* v___x_192_; lean_object* v___x_193_; 
v___x_190_ = lean_string_data(v_s_188_);
v___x_191_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_takeChars___closed__0));
lean_inc(v___x_190_);
v___x_192_ = l___private_Init_Data_List_Impl_0__List_takeTR_go___redArg(v___x_190_, v___x_190_, v_n_189_, v___x_191_);
lean_dec(v___x_190_);
v___x_193_ = lean_string_mk(v___x_192_);
return v___x_193_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_dropChars(lean_object* v_s_194_, lean_object* v_n_195_){
_start:
{
lean_object* v___x_196_; lean_object* v___x_197_; lean_object* v___x_198_; 
v___x_196_ = lean_string_data(v_s_194_);
v___x_197_ = l_List_drop___redArg(v_n_195_, v___x_196_);
lean_dec(v___x_196_);
v___x_198_ = lean_string_mk(v___x_197_);
return v___x_198_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_substr(lean_object* v_s_199_, lean_object* v_start_200_, lean_object* v_len_201_){
_start:
{
lean_object* v___x_202_; lean_object* v___x_203_; 
v___x_202_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_dropChars(v_s_199_, v_start_200_);
v___x_203_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_takeChars(v___x_202_, v_len_201_);
return v___x_203_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_take5___closed__0(void){
_start:
{
lean_object* v___x_204_; lean_object* v___x_205_; lean_object* v___x_206_; 
v___x_204_ = lean_unsigned_to_nat(5u);
v___x_205_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_hello___closed__0));
v___x_206_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_takeChars(v___x_205_, v___x_204_);
return v___x_206_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_take5(void){
_start:
{
lean_object* v___x_207_; 
v___x_207_ = lean_obj_once(&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_take5___closed__0, &lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_take5___closed__0_once, _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_take5___closed__0);
return v___x_207_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_drop7___closed__0(void){
_start:
{
lean_object* v___x_208_; lean_object* v___x_209_; lean_object* v___x_210_; 
v___x_208_ = lean_unsigned_to_nat(7u);
v___x_209_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_hello___closed__0));
v___x_210_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_dropChars(v___x_209_, v___x_208_);
return v___x_210_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_drop7(void){
_start:
{
lean_object* v___x_211_; 
v___x_211_ = lean_obj_once(&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_drop7___closed__0, &lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_drop7___closed__0_once, _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_drop7___closed__0);
return v___x_211_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_substr1___closed__0(void){
_start:
{
lean_object* v___x_212_; lean_object* v___x_213_; lean_object* v___x_214_; lean_object* v___x_215_; 
v___x_212_ = lean_unsigned_to_nat(5u);
v___x_213_ = lean_unsigned_to_nat(0u);
v___x_214_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_hello___closed__0));
v___x_215_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_substr(v___x_214_, v___x_213_, v___x_212_);
return v___x_215_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_substr1(void){
_start:
{
lean_object* v___x_216_; 
v___x_216_ = lean_obj_once(&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_substr1___closed__0, &lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_substr1___closed__0_once, _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_substr1___closed__0);
return v___x_216_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_substr2___closed__0(void){
_start:
{
lean_object* v___x_217_; lean_object* v___x_218_; lean_object* v___x_219_; lean_object* v___x_220_; 
v___x_217_ = lean_unsigned_to_nat(5u);
v___x_218_ = lean_unsigned_to_nat(7u);
v___x_219_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_hello___closed__0));
v___x_220_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_substr(v___x_219_, v___x_218_, v___x_217_);
return v___x_220_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_substr2(void){
_start:
{
lean_object* v___x_221_; 
v___x_221_ = lean_obj_once(&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_substr2___closed__0, &lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_substr2___closed__0_once, _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_substr2___closed__0);
return v___x_221_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_upper___closed__0(void){
_start:
{
lean_object* v___x_222_; lean_object* v___x_223_; lean_object* v___x_224_; 
v___x_222_ = lean_unsigned_to_nat(0u);
v___x_223_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_is__empty2___closed__0));
v___x_224_ = l_String_mapAux___at___00__private_Init_System_Uri_0__System_Uri_UriEscape_uriEscapeAsciiChar_uInt8ToHex_spec__0(v___x_223_, v___x_222_);
return v___x_224_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_upper(void){
_start:
{
lean_object* v___x_225_; 
v___x_225_ = lean_obj_once(&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_upper___closed__0, &lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_upper___closed__0_once, _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_upper___closed__0);
return v___x_225_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_String_mapAux___at___00Lean4Tutorial_Examples_Basics_Strings_lower_spec__0(lean_object* v_s_226_, lean_object* v_p_227_){
_start:
{
uint32_t v___y_229_; lean_object* v___x_234_; uint8_t v___x_235_; 
v___x_234_ = lean_string_utf8_byte_size(v_s_226_);
v___x_235_ = lean_nat_dec_eq(v_p_227_, v___x_234_);
if (v___x_235_ == 0)
{
uint32_t v___x_236_; uint32_t v___x_237_; uint8_t v___x_238_; 
v___x_236_ = lean_string_utf8_get_fast(v_s_226_, v_p_227_);
v___x_237_ = 65;
v___x_238_ = lean_uint32_dec_le(v___x_237_, v___x_236_);
if (v___x_238_ == 0)
{
v___y_229_ = v___x_236_;
goto v___jp_228_;
}
else
{
uint32_t v___x_239_; uint8_t v___x_240_; 
v___x_239_ = 90;
v___x_240_ = lean_uint32_dec_le(v___x_236_, v___x_239_);
if (v___x_240_ == 0)
{
v___y_229_ = v___x_236_;
goto v___jp_228_;
}
else
{
uint32_t v___x_241_; uint32_t v___x_242_; 
v___x_241_ = 32;
v___x_242_ = lean_uint32_add(v___x_236_, v___x_241_);
v___y_229_ = v___x_242_;
goto v___jp_228_;
}
}
}
else
{
lean_dec(v_p_227_);
return v_s_226_;
}
v___jp_228_:
{
lean_object* v___x_230_; lean_object* v___x_231_; lean_object* v___x_232_; 
lean_inc(v_p_227_);
v___x_230_ = lean_string_utf8_set(v_s_226_, v_p_227_, v___y_229_);
v___x_231_ = l_Char_utf8Size(v___y_229_);
v___x_232_ = lean_nat_add(v_p_227_, v___x_231_);
lean_dec(v___x_231_);
lean_dec(v_p_227_);
v_s_226_ = v___x_230_;
v_p_227_ = v___x_232_;
goto _start;
}
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_lower___closed__1(void){
_start:
{
lean_object* v___x_244_; lean_object* v___x_245_; lean_object* v___x_246_; 
v___x_244_ = lean_unsigned_to_nat(0u);
v___x_245_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_lower___closed__0));
v___x_246_ = lp_lean4_x2dtutorial_String_mapAux___at___00Lean4Tutorial_Examples_Basics_Strings_lower_spec__0(v___x_245_, v___x_244_);
return v___x_246_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_lower(void){
_start:
{
lean_object* v___x_247_; 
v___x_247_ = lean_obj_once(&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_lower___closed__1, &lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_lower___closed__1_once, _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_lower___closed__1);
return v___x_247_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_trimLeft_dropSpaces(lean_object* v_a_248_){
_start:
{
if (lean_obj_tag(v_a_248_) == 0)
{
lean_object* v___x_249_; 
v___x_249_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_empty___closed__0));
return v___x_249_;
}
else
{
lean_object* v_head_250_; lean_object* v_tail_251_; uint32_t v___x_252_; uint32_t v___x_253_; uint8_t v___x_254_; 
v_head_250_ = lean_ctor_get(v_a_248_, 0);
v_tail_251_ = lean_ctor_get(v_a_248_, 1);
v___x_252_ = 32;
v___x_253_ = lean_unbox_uint32(v_head_250_);
v___x_254_ = lean_uint32_dec_eq(v___x_253_, v___x_252_);
if (v___x_254_ == 0)
{
lean_object* v___x_255_; 
v___x_255_ = lean_string_mk(v_a_248_);
return v___x_255_;
}
else
{
lean_inc(v_tail_251_);
lean_dec_ref_known(v_a_248_, 2);
v_a_248_ = v_tail_251_;
goto _start;
}
}
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_trimLeft(lean_object* v_s_257_){
_start:
{
lean_object* v___x_258_; lean_object* v___x_259_; 
v___x_258_ = lean_string_data(v_s_257_);
v___x_259_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_trimLeft_dropSpaces(v___x_258_);
return v___x_259_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_trimRight(lean_object* v_s_260_){
_start:
{
lean_object* v___x_261_; lean_object* v___x_262_; lean_object* v_reversed_263_; lean_object* v___x_264_; lean_object* v___x_265_; lean_object* v___x_266_; lean_object* v___x_267_; 
v___x_261_ = lean_string_data(v_s_260_);
v___x_262_ = l_List_reverse___redArg(v___x_261_);
v_reversed_263_ = lean_string_mk(v___x_262_);
v___x_264_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_trimLeft(v_reversed_263_);
v___x_265_ = lean_string_data(v___x_264_);
v___x_266_ = l_List_reverse___redArg(v___x_265_);
v___x_267_ = lean_string_mk(v___x_266_);
return v___x_267_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_trim(lean_object* v_s_268_){
_start:
{
lean_object* v___x_269_; lean_object* v___x_270_; 
v___x_269_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_trimRight(v_s_268_);
v___x_270_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_trimLeft(v___x_269_);
return v___x_270_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_trimmed1___closed__1(void){
_start:
{
lean_object* v___x_272_; lean_object* v___x_273_; 
v___x_272_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_trimmed1___closed__0));
v___x_273_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_trim(v___x_272_);
return v___x_273_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_trimmed1(void){
_start:
{
lean_object* v___x_274_; 
v___x_274_ = lean_obj_once(&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_trimmed1___closed__1, &lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_trimmed1___closed__1_once, _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_trimmed1___closed__1);
return v___x_274_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_trimmed2___closed__1(void){
_start:
{
lean_object* v___x_276_; lean_object* v___x_277_; 
v___x_276_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_trimmed2___closed__0));
v___x_277_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_trim(v___x_276_);
return v___x_277_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_trimmed2(void){
_start:
{
lean_object* v___x_278_; 
v___x_278_ = lean_obj_once(&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_trimmed2___closed__1, &lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_trimmed2___closed__1_once, _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_trimmed2___closed__1);
return v___x_278_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_triml___closed__1(void){
_start:
{
lean_object* v___x_280_; lean_object* v___x_281_; 
v___x_280_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_triml___closed__0));
v___x_281_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_trimLeft(v___x_280_);
return v___x_281_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_triml(void){
_start:
{
lean_object* v___x_282_; 
v___x_282_ = lean_obj_once(&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_triml___closed__1, &lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_triml___closed__1_once, _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_triml___closed__1);
return v___x_282_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_trimr___closed__1(void){
_start:
{
lean_object* v___x_284_; lean_object* v___x_285_; 
v___x_284_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_trimr___closed__0));
v___x_285_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_trimRight(v___x_284_);
return v___x_285_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_trimr(void){
_start:
{
lean_object* v___x_286_; 
v___x_286_ = lean_obj_once(&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_trimr___closed__1, &lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_trimr___closed__1_once, _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_trimr___closed__1);
return v___x_286_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_List_mapTR_loop___at___00Lean4Tutorial_Examples_Basics_Strings_replaceChar_spec__0(uint32_t v_oldChar_287_, uint32_t v_newChar_288_, lean_object* v_a_289_, lean_object* v_a_290_){
_start:
{
if (lean_obj_tag(v_a_289_) == 0)
{
lean_object* v___x_291_; 
v___x_291_ = l_List_reverse___redArg(v_a_290_);
return v___x_291_;
}
else
{
lean_object* v_head_292_; lean_object* v_tail_293_; lean_object* v___x_295_; uint8_t v_isShared_296_; uint8_t v_isSharedCheck_307_; 
v_head_292_ = lean_ctor_get(v_a_289_, 0);
v_tail_293_ = lean_ctor_get(v_a_289_, 1);
v_isSharedCheck_307_ = !lean_is_exclusive(v_a_289_);
if (v_isSharedCheck_307_ == 0)
{
v___x_295_ = v_a_289_;
v_isShared_296_ = v_isSharedCheck_307_;
goto v_resetjp_294_;
}
else
{
lean_inc(v_tail_293_);
lean_inc(v_head_292_);
lean_dec(v_a_289_);
v___x_295_ = lean_box(0);
v_isShared_296_ = v_isSharedCheck_307_;
goto v_resetjp_294_;
}
v_resetjp_294_:
{
uint32_t v___y_298_; uint32_t v___x_304_; uint8_t v___x_305_; 
v___x_304_ = lean_unbox_uint32(v_head_292_);
v___x_305_ = lean_uint32_dec_eq(v___x_304_, v_oldChar_287_);
if (v___x_305_ == 0)
{
uint32_t v___x_306_; 
v___x_306_ = lean_unbox_uint32(v_head_292_);
lean_dec(v_head_292_);
v___y_298_ = v___x_306_;
goto v___jp_297_;
}
else
{
lean_dec(v_head_292_);
v___y_298_ = v_newChar_288_;
goto v___jp_297_;
}
v___jp_297_:
{
lean_object* v___x_299_; lean_object* v___x_301_; 
v___x_299_ = lean_box_uint32(v___y_298_);
if (v_isShared_296_ == 0)
{
lean_ctor_set(v___x_295_, 1, v_a_290_);
lean_ctor_set(v___x_295_, 0, v___x_299_);
v___x_301_ = v___x_295_;
goto v_reusejp_300_;
}
else
{
lean_object* v_reuseFailAlloc_303_; 
v_reuseFailAlloc_303_ = lean_alloc_ctor(1, 2, 0);
lean_ctor_set(v_reuseFailAlloc_303_, 0, v___x_299_);
lean_ctor_set(v_reuseFailAlloc_303_, 1, v_a_290_);
v___x_301_ = v_reuseFailAlloc_303_;
goto v_reusejp_300_;
}
v_reusejp_300_:
{
v_a_289_ = v_tail_293_;
v_a_290_ = v___x_301_;
goto _start;
}
}
}
}
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_List_mapTR_loop___at___00Lean4Tutorial_Examples_Basics_Strings_replaceChar_spec__0___boxed(lean_object* v_oldChar_308_, lean_object* v_newChar_309_, lean_object* v_a_310_, lean_object* v_a_311_){
_start:
{
uint32_t v_oldChar_boxed_312_; uint32_t v_newChar_boxed_313_; lean_object* v_res_314_; 
v_oldChar_boxed_312_ = lean_unbox_uint32(v_oldChar_308_);
lean_dec(v_oldChar_308_);
v_newChar_boxed_313_ = lean_unbox_uint32(v_newChar_309_);
lean_dec(v_newChar_309_);
v_res_314_ = lp_lean4_x2dtutorial_List_mapTR_loop___at___00Lean4Tutorial_Examples_Basics_Strings_replaceChar_spec__0(v_oldChar_boxed_312_, v_newChar_boxed_313_, v_a_310_, v_a_311_);
return v_res_314_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_replaceChar(lean_object* v_s_315_, uint32_t v_oldChar_316_, uint32_t v_newChar_317_){
_start:
{
lean_object* v___x_318_; lean_object* v___x_319_; lean_object* v___x_320_; lean_object* v___x_321_; 
v___x_318_ = lean_string_data(v_s_315_);
v___x_319_ = lean_box(0);
v___x_320_ = lp_lean4_x2dtutorial_List_mapTR_loop___at___00Lean4Tutorial_Examples_Basics_Strings_replaceChar_spec__0(v_oldChar_316_, v_newChar_317_, v___x_318_, v___x_319_);
v___x_321_ = lean_string_mk(v___x_320_);
return v___x_321_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_replaceChar___boxed(lean_object* v_s_322_, lean_object* v_oldChar_323_, lean_object* v_newChar_324_){
_start:
{
uint32_t v_oldChar_boxed_325_; uint32_t v_newChar_boxed_326_; lean_object* v_res_327_; 
v_oldChar_boxed_325_ = lean_unbox_uint32(v_oldChar_323_);
lean_dec(v_oldChar_323_);
v_newChar_boxed_326_ = lean_unbox_uint32(v_newChar_324_);
lean_dec(v_newChar_324_);
v_res_327_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_replaceChar(v_s_322_, v_oldChar_boxed_325_, v_newChar_boxed_326_);
return v_res_327_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_replaced___closed__0(void){
_start:
{
uint32_t v___x_328_; uint32_t v___x_329_; lean_object* v___x_330_; lean_object* v___x_331_; 
v___x_328_ = 120;
v___x_329_ = 108;
v___x_330_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_is__empty2___closed__0));
v___x_331_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_replaceChar(v___x_330_, v___x_329_, v___x_328_);
return v___x_331_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_replaced(void){
_start:
{
lean_object* v___x_332_; 
v___x_332_ = lean_obj_once(&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_replaced___closed__0, &lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_replaced___closed__0_once, _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_replaced___closed__0);
return v___x_332_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_repeatString(lean_object* v_s_333_, lean_object* v_n_334_){
_start:
{
lean_object* v___x_335_; lean_object* v___x_336_; lean_object* v___x_337_; 
v___x_335_ = l_List_replicateTR___redArg(v_n_334_, v_s_333_);
v___x_336_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_empty___closed__0));
v___x_337_ = lp_lean4_x2dtutorial_List_foldl___at___00Lean4Tutorial_Examples_Basics_Strings_joined_spec__0(v___x_336_, v___x_335_);
lean_dec(v___x_335_);
return v___x_337_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_repeated___closed__1(void){
_start:
{
lean_object* v___x_339_; lean_object* v___x_340_; lean_object* v___x_341_; 
v___x_339_ = lean_unsigned_to_nat(3u);
v___x_340_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_repeated___closed__0));
v___x_341_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_repeatString(v___x_340_, v___x_339_);
return v___x_341_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_repeated(void){
_start:
{
lean_object* v___x_342_; 
v___x_342_ = lean_obj_once(&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_repeated___closed__1, &lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_repeated___closed__1_once, _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_repeated___closed__1);
return v___x_342_;
}
}
LEAN_EXPORT uint8_t lp_lean4_x2dtutorial_WellFounded_opaqueFix_u2083___at___00String_Slice_contains___at___00Lean4Tutorial_Examples_Basics_Strings_contains1_spec__0_spec__0___redArg(lean_object* v_s_343_, lean_object* v_a_344_, uint8_t v_b_345_){
_start:
{
uint8_t v___x_346_; 
v___x_346_ = 0;
switch(lean_obj_tag(v_a_344_))
{
case 0:
{
uint8_t v___x_347_; 
lean_dec_ref_known(v_a_344_, 1);
v___x_347_ = 1;
return v___x_347_;
}
case 1:
{
lean_object* v_pos_348_; lean_object* v___x_350_; uint8_t v_isShared_351_; uint8_t v_isSharedCheck_361_; 
v_pos_348_ = lean_ctor_get(v_a_344_, 0);
v_isSharedCheck_361_ = !lean_is_exclusive(v_a_344_);
if (v_isSharedCheck_361_ == 0)
{
v___x_350_ = v_a_344_;
v_isShared_351_ = v_isSharedCheck_361_;
goto v_resetjp_349_;
}
else
{
lean_inc(v_pos_348_);
lean_dec(v_a_344_);
v___x_350_ = lean_box(0);
v_isShared_351_ = v_isSharedCheck_361_;
goto v_resetjp_349_;
}
v_resetjp_349_:
{
lean_object* v_str_352_; lean_object* v_startInclusive_353_; lean_object* v___x_354_; lean_object* v___x_355_; lean_object* v___x_356_; lean_object* v___x_358_; 
v_str_352_ = lean_ctor_get(v_s_343_, 0);
v_startInclusive_353_ = lean_ctor_get(v_s_343_, 1);
v___x_354_ = lean_nat_add(v_startInclusive_353_, v_pos_348_);
lean_dec(v_pos_348_);
v___x_355_ = lean_string_utf8_next_fast(v_str_352_, v___x_354_);
lean_dec(v___x_354_);
v___x_356_ = lean_nat_sub(v___x_355_, v_startInclusive_353_);
if (v_isShared_351_ == 0)
{
lean_ctor_set_tag(v___x_350_, 0);
lean_ctor_set(v___x_350_, 0, v___x_356_);
v___x_358_ = v___x_350_;
goto v_reusejp_357_;
}
else
{
lean_object* v_reuseFailAlloc_360_; 
v_reuseFailAlloc_360_ = lean_alloc_ctor(0, 1, 0);
lean_ctor_set(v_reuseFailAlloc_360_, 0, v___x_356_);
v___x_358_ = v_reuseFailAlloc_360_;
goto v_reusejp_357_;
}
v_reusejp_357_:
{
v_a_344_ = v___x_358_;
v_b_345_ = v___x_346_;
goto _start;
}
}
}
case 2:
{
lean_object* v_needle_362_; lean_object* v_table_363_; lean_object* v_stackPos_364_; lean_object* v_needlePos_365_; lean_object* v___x_367_; uint8_t v_isShared_368_; uint8_t v_isSharedCheck_418_; 
v_needle_362_ = lean_ctor_get(v_a_344_, 0);
v_table_363_ = lean_ctor_get(v_a_344_, 1);
v_stackPos_364_ = lean_ctor_get(v_a_344_, 2);
v_needlePos_365_ = lean_ctor_get(v_a_344_, 3);
v_isSharedCheck_418_ = !lean_is_exclusive(v_a_344_);
if (v_isSharedCheck_418_ == 0)
{
v___x_367_ = v_a_344_;
v_isShared_368_ = v_isSharedCheck_418_;
goto v_resetjp_366_;
}
else
{
lean_inc(v_needlePos_365_);
lean_inc(v_stackPos_364_);
lean_inc(v_table_363_);
lean_inc(v_needle_362_);
lean_dec(v_a_344_);
v___x_367_ = lean_box(0);
v_isShared_368_ = v_isSharedCheck_418_;
goto v_resetjp_366_;
}
v_resetjp_366_:
{
lean_object* v_str_369_; lean_object* v_startInclusive_370_; lean_object* v_endExclusive_371_; lean_object* v_str_372_; lean_object* v_startInclusive_373_; lean_object* v_endExclusive_374_; lean_object* v_basePos_375_; lean_object* v___x_376_; lean_object* v___x_377_; lean_object* v___x_378_; uint8_t v___x_379_; 
v_str_369_ = lean_ctor_get(v_needle_362_, 0);
v_startInclusive_370_ = lean_ctor_get(v_needle_362_, 1);
v_endExclusive_371_ = lean_ctor_get(v_needle_362_, 2);
v_str_372_ = lean_ctor_get(v_s_343_, 0);
v_startInclusive_373_ = lean_ctor_get(v_s_343_, 1);
v_endExclusive_374_ = lean_ctor_get(v_s_343_, 2);
v_basePos_375_ = lean_nat_sub(v_stackPos_364_, v_needlePos_365_);
v___x_376_ = lean_nat_sub(v_endExclusive_371_, v_startInclusive_370_);
v___x_377_ = lean_nat_add(v_basePos_375_, v___x_376_);
v___x_378_ = lean_nat_sub(v_endExclusive_374_, v_startInclusive_373_);
v___x_379_ = lean_nat_dec_le(v___x_377_, v___x_378_);
lean_dec(v___x_377_);
if (v___x_379_ == 0)
{
uint8_t v___x_380_; 
lean_dec(v___x_376_);
lean_del_object(v___x_367_);
lean_dec(v_needlePos_365_);
lean_dec(v_stackPos_364_);
lean_dec_ref(v_table_363_);
lean_dec_ref(v_needle_362_);
v___x_380_ = lean_nat_dec_lt(v_basePos_375_, v___x_378_);
lean_dec(v___x_378_);
lean_dec(v_basePos_375_);
if (v___x_380_ == 0)
{
return v_b_345_;
}
else
{
lean_object* v___x_381_; 
v___x_381_ = lean_box(3);
v_a_344_ = v___x_381_;
v_b_345_ = v___x_346_;
goto _start;
}
}
else
{
lean_object* v___x_383_; uint8_t v_stackByte_384_; lean_object* v___x_385_; uint8_t v_patByte_386_; uint8_t v___x_387_; 
lean_dec(v___x_378_);
lean_dec(v_basePos_375_);
v___x_383_ = lean_nat_add(v_startInclusive_373_, v_stackPos_364_);
v_stackByte_384_ = lean_string_get_byte_fast(v_str_372_, v___x_383_);
v___x_385_ = lean_nat_add(v_startInclusive_370_, v_needlePos_365_);
v_patByte_386_ = lean_string_get_byte_fast(v_str_369_, v___x_385_);
v___x_387_ = lean_uint8_dec_eq(v_stackByte_384_, v_patByte_386_);
if (v___x_387_ == 0)
{
lean_object* v___x_388_; uint8_t v___x_389_; 
lean_dec(v___x_376_);
v___x_388_ = lean_unsigned_to_nat(0u);
v___x_389_ = lean_nat_dec_eq(v_needlePos_365_, v___x_388_);
if (v___x_389_ == 0)
{
lean_object* v___x_390_; lean_object* v___x_391_; lean_object* v_newNeedlePos_392_; uint8_t v___x_393_; 
v___x_390_ = lean_unsigned_to_nat(1u);
v___x_391_ = lean_nat_sub(v_needlePos_365_, v___x_390_);
lean_dec(v_needlePos_365_);
v_newNeedlePos_392_ = lean_array_fget_borrowed(v_table_363_, v___x_391_);
lean_dec(v___x_391_);
v___x_393_ = lean_nat_dec_eq(v_newNeedlePos_392_, v___x_388_);
if (v___x_393_ == 0)
{
lean_object* v___x_395_; 
lean_inc(v_newNeedlePos_392_);
if (v_isShared_368_ == 0)
{
lean_ctor_set(v___x_367_, 3, v_newNeedlePos_392_);
v___x_395_ = v___x_367_;
goto v_reusejp_394_;
}
else
{
lean_object* v_reuseFailAlloc_397_; 
v_reuseFailAlloc_397_ = lean_alloc_ctor(2, 4, 0);
lean_ctor_set(v_reuseFailAlloc_397_, 0, v_needle_362_);
lean_ctor_set(v_reuseFailAlloc_397_, 1, v_table_363_);
lean_ctor_set(v_reuseFailAlloc_397_, 2, v_stackPos_364_);
lean_ctor_set(v_reuseFailAlloc_397_, 3, v_newNeedlePos_392_);
v___x_395_ = v_reuseFailAlloc_397_;
goto v_reusejp_394_;
}
v_reusejp_394_:
{
v_a_344_ = v___x_395_;
v_b_345_ = v___x_346_;
goto _start;
}
}
else
{
lean_object* v_nextStackPos_398_; lean_object* v___x_400_; 
v_nextStackPos_398_ = l_String_Slice_posGE___redArg(v_s_343_, v_stackPos_364_);
if (v_isShared_368_ == 0)
{
lean_ctor_set(v___x_367_, 3, v___x_388_);
lean_ctor_set(v___x_367_, 2, v_nextStackPos_398_);
v___x_400_ = v___x_367_;
goto v_reusejp_399_;
}
else
{
lean_object* v_reuseFailAlloc_402_; 
v_reuseFailAlloc_402_ = lean_alloc_ctor(2, 4, 0);
lean_ctor_set(v_reuseFailAlloc_402_, 0, v_needle_362_);
lean_ctor_set(v_reuseFailAlloc_402_, 1, v_table_363_);
lean_ctor_set(v_reuseFailAlloc_402_, 2, v_nextStackPos_398_);
lean_ctor_set(v_reuseFailAlloc_402_, 3, v___x_388_);
v___x_400_ = v_reuseFailAlloc_402_;
goto v_reusejp_399_;
}
v_reusejp_399_:
{
v_a_344_ = v___x_400_;
v_b_345_ = v___x_346_;
goto _start;
}
}
}
else
{
lean_object* v___x_403_; lean_object* v___x_404_; lean_object* v_nextStackPos_405_; lean_object* v___x_407_; 
lean_dec(v_needlePos_365_);
v___x_403_ = lean_unsigned_to_nat(1u);
v___x_404_ = lean_nat_add(v_stackPos_364_, v___x_403_);
lean_dec(v_stackPos_364_);
v_nextStackPos_405_ = l_String_Slice_posGE___redArg(v_s_343_, v___x_404_);
if (v_isShared_368_ == 0)
{
lean_ctor_set(v___x_367_, 3, v___x_388_);
lean_ctor_set(v___x_367_, 2, v_nextStackPos_405_);
v___x_407_ = v___x_367_;
goto v_reusejp_406_;
}
else
{
lean_object* v_reuseFailAlloc_409_; 
v_reuseFailAlloc_409_ = lean_alloc_ctor(2, 4, 0);
lean_ctor_set(v_reuseFailAlloc_409_, 0, v_needle_362_);
lean_ctor_set(v_reuseFailAlloc_409_, 1, v_table_363_);
lean_ctor_set(v_reuseFailAlloc_409_, 2, v_nextStackPos_405_);
lean_ctor_set(v_reuseFailAlloc_409_, 3, v___x_388_);
v___x_407_ = v_reuseFailAlloc_409_;
goto v_reusejp_406_;
}
v_reusejp_406_:
{
v_a_344_ = v___x_407_;
v_b_345_ = v___x_346_;
goto _start;
}
}
}
else
{
lean_object* v___x_410_; lean_object* v_nextNeedlePos_411_; uint8_t v___x_412_; 
v___x_410_ = lean_unsigned_to_nat(1u);
v_nextNeedlePos_411_ = lean_nat_add(v_needlePos_365_, v___x_410_);
lean_dec(v_needlePos_365_);
v___x_412_ = lean_nat_dec_eq(v_nextNeedlePos_411_, v___x_376_);
lean_dec(v___x_376_);
if (v___x_412_ == 0)
{
lean_object* v_nextStackPos_413_; lean_object* v___x_415_; 
v_nextStackPos_413_ = lean_nat_add(v_stackPos_364_, v___x_410_);
lean_dec(v_stackPos_364_);
if (v_isShared_368_ == 0)
{
lean_ctor_set(v___x_367_, 3, v_nextNeedlePos_411_);
lean_ctor_set(v___x_367_, 2, v_nextStackPos_413_);
v___x_415_ = v___x_367_;
goto v_reusejp_414_;
}
else
{
lean_object* v_reuseFailAlloc_417_; 
v_reuseFailAlloc_417_ = lean_alloc_ctor(2, 4, 0);
lean_ctor_set(v_reuseFailAlloc_417_, 0, v_needle_362_);
lean_ctor_set(v_reuseFailAlloc_417_, 1, v_table_363_);
lean_ctor_set(v_reuseFailAlloc_417_, 2, v_nextStackPos_413_);
lean_ctor_set(v_reuseFailAlloc_417_, 3, v_nextNeedlePos_411_);
v___x_415_ = v_reuseFailAlloc_417_;
goto v_reusejp_414_;
}
v_reusejp_414_:
{
v_a_344_ = v___x_415_;
goto _start;
}
}
else
{
lean_dec(v_nextNeedlePos_411_);
lean_del_object(v___x_367_);
lean_dec(v_stackPos_364_);
lean_dec_ref(v_table_363_);
lean_dec_ref(v_needle_362_);
return v___x_412_;
}
}
}
}
}
default: 
{
return v_b_345_;
}
}
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_WellFounded_opaqueFix_u2083___at___00String_Slice_contains___at___00Lean4Tutorial_Examples_Basics_Strings_contains1_spec__0_spec__0___redArg___boxed(lean_object* v_s_419_, lean_object* v_a_420_, lean_object* v_b_421_){
_start:
{
uint8_t v_b_boxed_422_; uint8_t v_res_423_; lean_object* v_r_424_; 
v_b_boxed_422_ = lean_unbox(v_b_421_);
v_res_423_ = lp_lean4_x2dtutorial_WellFounded_opaqueFix_u2083___at___00String_Slice_contains___at___00Lean4Tutorial_Examples_Basics_Strings_contains1_spec__0_spec__0___redArg(v_s_419_, v_a_420_, v_b_boxed_422_);
lean_dec_ref(v_s_419_);
v_r_424_ = lean_box(v_res_423_);
return v_r_424_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_String_Slice_contains___at___00Lean4Tutorial_Examples_Basics_Strings_contains1_spec__0___closed__1(void){
_start:
{
lean_object* v___x_426_; lean_object* v___x_427_; 
v___x_426_ = ((lean_object*)(lp_lean4_x2dtutorial_String_Slice_contains___at___00Lean4Tutorial_Examples_Basics_Strings_contains1_spec__0___closed__0));
v___x_427_ = lean_string_utf8_byte_size(v___x_426_);
return v___x_427_;
}
}
static uint8_t _init_lp_lean4_x2dtutorial_String_Slice_contains___at___00Lean4Tutorial_Examples_Basics_Strings_contains1_spec__0___closed__2(void){
_start:
{
lean_object* v___x_428_; lean_object* v___x_429_; uint8_t v___x_430_; 
v___x_428_ = lean_unsigned_to_nat(0u);
v___x_429_ = lean_obj_once(&lp_lean4_x2dtutorial_String_Slice_contains___at___00Lean4Tutorial_Examples_Basics_Strings_contains1_spec__0___closed__1, &lp_lean4_x2dtutorial_String_Slice_contains___at___00Lean4Tutorial_Examples_Basics_Strings_contains1_spec__0___closed__1_once, _init_lp_lean4_x2dtutorial_String_Slice_contains___at___00Lean4Tutorial_Examples_Basics_Strings_contains1_spec__0___closed__1);
v___x_430_ = lean_nat_dec_eq(v___x_429_, v___x_428_);
return v___x_430_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_String_Slice_contains___at___00Lean4Tutorial_Examples_Basics_Strings_contains1_spec__0___closed__3(void){
_start:
{
lean_object* v___x_431_; lean_object* v___x_432_; lean_object* v___x_433_; lean_object* v___x_434_; 
v___x_431_ = lean_obj_once(&lp_lean4_x2dtutorial_String_Slice_contains___at___00Lean4Tutorial_Examples_Basics_Strings_contains1_spec__0___closed__1, &lp_lean4_x2dtutorial_String_Slice_contains___at___00Lean4Tutorial_Examples_Basics_Strings_contains1_spec__0___closed__1_once, _init_lp_lean4_x2dtutorial_String_Slice_contains___at___00Lean4Tutorial_Examples_Basics_Strings_contains1_spec__0___closed__1);
v___x_432_ = lean_unsigned_to_nat(0u);
v___x_433_ = ((lean_object*)(lp_lean4_x2dtutorial_String_Slice_contains___at___00Lean4Tutorial_Examples_Basics_Strings_contains1_spec__0___closed__0));
v___x_434_ = lean_alloc_ctor(0, 3, 0);
lean_ctor_set(v___x_434_, 0, v___x_433_);
lean_ctor_set(v___x_434_, 1, v___x_432_);
lean_ctor_set(v___x_434_, 2, v___x_431_);
return v___x_434_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_String_Slice_contains___at___00Lean4Tutorial_Examples_Basics_Strings_contains1_spec__0___closed__4(void){
_start:
{
lean_object* v___x_435_; lean_object* v___x_436_; 
v___x_435_ = lean_obj_once(&lp_lean4_x2dtutorial_String_Slice_contains___at___00Lean4Tutorial_Examples_Basics_Strings_contains1_spec__0___closed__3, &lp_lean4_x2dtutorial_String_Slice_contains___at___00Lean4Tutorial_Examples_Basics_Strings_contains1_spec__0___closed__3_once, _init_lp_lean4_x2dtutorial_String_Slice_contains___at___00Lean4Tutorial_Examples_Basics_Strings_contains1_spec__0___closed__3);
v___x_436_ = l_String_Slice_Pattern_ForwardSliceSearcher_buildTable(v___x_435_);
return v___x_436_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_String_Slice_contains___at___00Lean4Tutorial_Examples_Basics_Strings_contains1_spec__0___closed__5(void){
_start:
{
lean_object* v___x_437_; lean_object* v___x_438_; lean_object* v___x_439_; lean_object* v___x_440_; 
v___x_437_ = lean_unsigned_to_nat(0u);
v___x_438_ = lean_obj_once(&lp_lean4_x2dtutorial_String_Slice_contains___at___00Lean4Tutorial_Examples_Basics_Strings_contains1_spec__0___closed__4, &lp_lean4_x2dtutorial_String_Slice_contains___at___00Lean4Tutorial_Examples_Basics_Strings_contains1_spec__0___closed__4_once, _init_lp_lean4_x2dtutorial_String_Slice_contains___at___00Lean4Tutorial_Examples_Basics_Strings_contains1_spec__0___closed__4);
v___x_439_ = lean_obj_once(&lp_lean4_x2dtutorial_String_Slice_contains___at___00Lean4Tutorial_Examples_Basics_Strings_contains1_spec__0___closed__3, &lp_lean4_x2dtutorial_String_Slice_contains___at___00Lean4Tutorial_Examples_Basics_Strings_contains1_spec__0___closed__3_once, _init_lp_lean4_x2dtutorial_String_Slice_contains___at___00Lean4Tutorial_Examples_Basics_Strings_contains1_spec__0___closed__3);
v___x_440_ = lean_alloc_ctor(2, 4, 0);
lean_ctor_set(v___x_440_, 0, v___x_439_);
lean_ctor_set(v___x_440_, 1, v___x_438_);
lean_ctor_set(v___x_440_, 2, v___x_437_);
lean_ctor_set(v___x_440_, 3, v___x_437_);
return v___x_440_;
}
}
LEAN_EXPORT uint8_t lp_lean4_x2dtutorial_String_Slice_contains___at___00Lean4Tutorial_Examples_Basics_Strings_contains1_spec__0(lean_object* v_s_443_){
_start:
{
lean_object* v___y_445_; uint8_t v___x_448_; 
v___x_448_ = lean_uint8_once(&lp_lean4_x2dtutorial_String_Slice_contains___at___00Lean4Tutorial_Examples_Basics_Strings_contains1_spec__0___closed__2, &lp_lean4_x2dtutorial_String_Slice_contains___at___00Lean4Tutorial_Examples_Basics_Strings_contains1_spec__0___closed__2_once, _init_lp_lean4_x2dtutorial_String_Slice_contains___at___00Lean4Tutorial_Examples_Basics_Strings_contains1_spec__0___closed__2);
if (v___x_448_ == 0)
{
lean_object* v___x_449_; 
v___x_449_ = lean_obj_once(&lp_lean4_x2dtutorial_String_Slice_contains___at___00Lean4Tutorial_Examples_Basics_Strings_contains1_spec__0___closed__5, &lp_lean4_x2dtutorial_String_Slice_contains___at___00Lean4Tutorial_Examples_Basics_Strings_contains1_spec__0___closed__5_once, _init_lp_lean4_x2dtutorial_String_Slice_contains___at___00Lean4Tutorial_Examples_Basics_Strings_contains1_spec__0___closed__5);
v___y_445_ = v___x_449_;
goto v___jp_444_;
}
else
{
lean_object* v___x_450_; 
v___x_450_ = ((lean_object*)(lp_lean4_x2dtutorial_String_Slice_contains___at___00Lean4Tutorial_Examples_Basics_Strings_contains1_spec__0___closed__6));
v___y_445_ = v___x_450_;
goto v___jp_444_;
}
v___jp_444_:
{
uint8_t v___x_446_; uint8_t v___x_447_; 
v___x_446_ = 0;
lean_inc(v___y_445_);
v___x_447_ = lp_lean4_x2dtutorial_WellFounded_opaqueFix_u2083___at___00String_Slice_contains___at___00Lean4Tutorial_Examples_Basics_Strings_contains1_spec__0_spec__0___redArg(v_s_443_, v___y_445_, v___x_446_);
return v___x_447_;
}
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_String_Slice_contains___at___00Lean4Tutorial_Examples_Basics_Strings_contains1_spec__0___boxed(lean_object* v_s_451_){
_start:
{
uint8_t v_res_452_; lean_object* v_r_453_; 
v_res_452_ = lp_lean4_x2dtutorial_String_Slice_contains___at___00Lean4Tutorial_Examples_Basics_Strings_contains1_spec__0(v_s_451_);
lean_dec_ref(v_s_451_);
v_r_453_ = lean_box(v_res_452_);
return v_r_453_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_contains1___closed__0(void){
_start:
{
lean_object* v___x_454_; lean_object* v___x_455_; 
v___x_454_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_hello___closed__0));
v___x_455_ = lean_string_utf8_byte_size(v___x_454_);
return v___x_455_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_contains1___closed__1(void){
_start:
{
lean_object* v___x_456_; lean_object* v___x_457_; lean_object* v___x_458_; lean_object* v___x_459_; 
v___x_456_ = lean_obj_once(&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_contains1___closed__0, &lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_contains1___closed__0_once, _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_contains1___closed__0);
v___x_457_ = lean_unsigned_to_nat(0u);
v___x_458_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_hello___closed__0));
v___x_459_ = lean_alloc_ctor(0, 3, 0);
lean_ctor_set(v___x_459_, 0, v___x_458_);
lean_ctor_set(v___x_459_, 1, v___x_457_);
lean_ctor_set(v___x_459_, 2, v___x_456_);
return v___x_459_;
}
}
static uint8_t _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_contains1___closed__2(void){
_start:
{
lean_object* v___x_460_; uint8_t v___x_461_; 
v___x_460_ = lean_obj_once(&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_contains1___closed__1, &lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_contains1___closed__1_once, _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_contains1___closed__1);
v___x_461_ = lp_lean4_x2dtutorial_String_Slice_contains___at___00Lean4Tutorial_Examples_Basics_Strings_contains1_spec__0(v___x_460_);
return v___x_461_;
}
}
static uint8_t _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_contains1(void){
_start:
{
uint8_t v___x_462_; 
v___x_462_ = lean_uint8_once(&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_contains1___closed__2, &lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_contains1___closed__2_once, _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_contains1___closed__2);
return v___x_462_;
}
}
LEAN_EXPORT uint8_t lp_lean4_x2dtutorial_WellFounded_opaqueFix_u2083___at___00String_Slice_contains___at___00Lean4Tutorial_Examples_Basics_Strings_contains1_spec__0_spec__0(lean_object* v_s_463_, lean_object* v_inst_464_, lean_object* v_R_465_, lean_object* v_a_466_, uint8_t v_b_467_, lean_object* v_c_468_){
_start:
{
uint8_t v___x_469_; 
v___x_469_ = lp_lean4_x2dtutorial_WellFounded_opaqueFix_u2083___at___00String_Slice_contains___at___00Lean4Tutorial_Examples_Basics_Strings_contains1_spec__0_spec__0___redArg(v_s_463_, v_a_466_, v_b_467_);
return v___x_469_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_WellFounded_opaqueFix_u2083___at___00String_Slice_contains___at___00Lean4Tutorial_Examples_Basics_Strings_contains1_spec__0_spec__0___boxed(lean_object* v_s_470_, lean_object* v_inst_471_, lean_object* v_R_472_, lean_object* v_a_473_, lean_object* v_b_474_, lean_object* v_c_475_){
_start:
{
uint8_t v_b_boxed_476_; uint8_t v_res_477_; lean_object* v_r_478_; 
v_b_boxed_476_ = lean_unbox(v_b_474_);
v_res_477_ = lp_lean4_x2dtutorial_WellFounded_opaqueFix_u2083___at___00String_Slice_contains___at___00Lean4Tutorial_Examples_Basics_Strings_contains1_spec__0_spec__0(v_s_470_, v_inst_471_, v_R_472_, v_a_473_, v_b_boxed_476_, v_c_475_);
lean_dec_ref(v_s_470_);
v_r_478_ = lean_box(v_res_477_);
return v_r_478_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_String_Slice_contains___at___00Lean4Tutorial_Examples_Basics_Strings_contains2_spec__0___closed__0(void){
_start:
{
lean_object* v___x_479_; lean_object* v___x_480_; lean_object* v___x_481_; lean_object* v___x_482_; 
v___x_479_ = lean_obj_once(&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_is__empty2___closed__1, &lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_is__empty2___closed__1_once, _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_is__empty2___closed__1);
v___x_480_ = lean_unsigned_to_nat(0u);
v___x_481_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_is__empty2___closed__0));
v___x_482_ = lean_alloc_ctor(0, 3, 0);
lean_ctor_set(v___x_482_, 0, v___x_481_);
lean_ctor_set(v___x_482_, 1, v___x_480_);
lean_ctor_set(v___x_482_, 2, v___x_479_);
return v___x_482_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_String_Slice_contains___at___00Lean4Tutorial_Examples_Basics_Strings_contains2_spec__0___closed__1(void){
_start:
{
lean_object* v___x_483_; lean_object* v___x_484_; 
v___x_483_ = lean_obj_once(&lp_lean4_x2dtutorial_String_Slice_contains___at___00Lean4Tutorial_Examples_Basics_Strings_contains2_spec__0___closed__0, &lp_lean4_x2dtutorial_String_Slice_contains___at___00Lean4Tutorial_Examples_Basics_Strings_contains2_spec__0___closed__0_once, _init_lp_lean4_x2dtutorial_String_Slice_contains___at___00Lean4Tutorial_Examples_Basics_Strings_contains2_spec__0___closed__0);
v___x_484_ = l_String_Slice_Pattern_ForwardSliceSearcher_buildTable(v___x_483_);
return v___x_484_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_String_Slice_contains___at___00Lean4Tutorial_Examples_Basics_Strings_contains2_spec__0___closed__2(void){
_start:
{
lean_object* v___x_485_; lean_object* v___x_486_; lean_object* v___x_487_; lean_object* v___x_488_; 
v___x_485_ = lean_unsigned_to_nat(0u);
v___x_486_ = lean_obj_once(&lp_lean4_x2dtutorial_String_Slice_contains___at___00Lean4Tutorial_Examples_Basics_Strings_contains2_spec__0___closed__1, &lp_lean4_x2dtutorial_String_Slice_contains___at___00Lean4Tutorial_Examples_Basics_Strings_contains2_spec__0___closed__1_once, _init_lp_lean4_x2dtutorial_String_Slice_contains___at___00Lean4Tutorial_Examples_Basics_Strings_contains2_spec__0___closed__1);
v___x_487_ = lean_obj_once(&lp_lean4_x2dtutorial_String_Slice_contains___at___00Lean4Tutorial_Examples_Basics_Strings_contains2_spec__0___closed__0, &lp_lean4_x2dtutorial_String_Slice_contains___at___00Lean4Tutorial_Examples_Basics_Strings_contains2_spec__0___closed__0_once, _init_lp_lean4_x2dtutorial_String_Slice_contains___at___00Lean4Tutorial_Examples_Basics_Strings_contains2_spec__0___closed__0);
v___x_488_ = lean_alloc_ctor(2, 4, 0);
lean_ctor_set(v___x_488_, 0, v___x_487_);
lean_ctor_set(v___x_488_, 1, v___x_486_);
lean_ctor_set(v___x_488_, 2, v___x_485_);
lean_ctor_set(v___x_488_, 3, v___x_485_);
return v___x_488_;
}
}
LEAN_EXPORT uint8_t lp_lean4_x2dtutorial_String_Slice_contains___at___00Lean4Tutorial_Examples_Basics_Strings_contains2_spec__0(lean_object* v_s_489_){
_start:
{
lean_object* v___y_491_; uint8_t v___x_494_; 
v___x_494_ = lean_uint8_once(&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_is__empty2___closed__2, &lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_is__empty2___closed__2_once, _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_is__empty2___closed__2);
if (v___x_494_ == 0)
{
lean_object* v___x_495_; 
v___x_495_ = lean_obj_once(&lp_lean4_x2dtutorial_String_Slice_contains___at___00Lean4Tutorial_Examples_Basics_Strings_contains2_spec__0___closed__2, &lp_lean4_x2dtutorial_String_Slice_contains___at___00Lean4Tutorial_Examples_Basics_Strings_contains2_spec__0___closed__2_once, _init_lp_lean4_x2dtutorial_String_Slice_contains___at___00Lean4Tutorial_Examples_Basics_Strings_contains2_spec__0___closed__2);
v___y_491_ = v___x_495_;
goto v___jp_490_;
}
else
{
lean_object* v___x_496_; 
v___x_496_ = ((lean_object*)(lp_lean4_x2dtutorial_String_Slice_contains___at___00Lean4Tutorial_Examples_Basics_Strings_contains1_spec__0___closed__6));
v___y_491_ = v___x_496_;
goto v___jp_490_;
}
v___jp_490_:
{
uint8_t v___x_492_; uint8_t v___x_493_; 
v___x_492_ = 0;
lean_inc(v___y_491_);
v___x_493_ = lp_lean4_x2dtutorial_WellFounded_opaqueFix_u2083___at___00String_Slice_contains___at___00Lean4Tutorial_Examples_Basics_Strings_contains1_spec__0_spec__0___redArg(v_s_489_, v___y_491_, v___x_492_);
return v___x_493_;
}
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_String_Slice_contains___at___00Lean4Tutorial_Examples_Basics_Strings_contains2_spec__0___boxed(lean_object* v_s_497_){
_start:
{
uint8_t v_res_498_; lean_object* v_r_499_; 
v_res_498_ = lp_lean4_x2dtutorial_String_Slice_contains___at___00Lean4Tutorial_Examples_Basics_Strings_contains2_spec__0(v_s_497_);
lean_dec_ref(v_s_497_);
v_r_499_ = lean_box(v_res_498_);
return v_r_499_;
}
}
static uint8_t _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_contains2___closed__0(void){
_start:
{
lean_object* v___x_500_; uint8_t v___x_501_; 
v___x_500_ = lean_obj_once(&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_contains1___closed__1, &lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_contains1___closed__1_once, _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_contains1___closed__1);
v___x_501_ = lp_lean4_x2dtutorial_String_Slice_contains___at___00Lean4Tutorial_Examples_Basics_Strings_contains2_spec__0(v___x_500_);
return v___x_501_;
}
}
static uint8_t _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_contains2(void){
_start:
{
uint8_t v___x_502_; 
v___x_502_ = lean_uint8_once(&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_contains2___closed__0, &lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_contains2___closed__0_once, _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_contains2___closed__0);
return v___x_502_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_prefix1___closed__1(void){
_start:
{
lean_object* v___x_504_; lean_object* v___x_505_; 
v___x_504_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_prefix1___closed__0));
v___x_505_ = lean_string_utf8_byte_size(v___x_504_);
return v___x_505_;
}
}
static uint8_t _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_prefix1___closed__2(void){
_start:
{
lean_object* v___x_506_; lean_object* v___x_507_; uint8_t v___x_508_; 
v___x_506_ = lean_obj_once(&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_front__char___closed__0, &lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_front__char___closed__0_once, _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_front__char___closed__0);
v___x_507_ = lean_obj_once(&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_prefix1___closed__1, &lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_prefix1___closed__1_once, _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_prefix1___closed__1);
v___x_508_ = lean_nat_dec_le(v___x_507_, v___x_506_);
return v___x_508_;
}
}
static uint8_t _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_prefix1___closed__3(void){
_start:
{
lean_object* v___x_509_; lean_object* v___x_510_; lean_object* v___x_511_; lean_object* v___x_512_; uint8_t v___x_513_; 
v___x_509_ = lean_obj_once(&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_prefix1___closed__1, &lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_prefix1___closed__1_once, _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_prefix1___closed__1);
v___x_510_ = lean_unsigned_to_nat(0u);
v___x_511_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_prefix1___closed__0));
v___x_512_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_chars___closed__0));
v___x_513_ = lean_string_memcmp(v___x_512_, v___x_511_, v___x_510_, v___x_510_, v___x_509_);
return v___x_513_;
}
}
static uint8_t _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_prefix1(void){
_start:
{
uint8_t v___x_514_; 
v___x_514_ = lean_uint8_once(&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_prefix1___closed__2, &lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_prefix1___closed__2_once, _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_prefix1___closed__2);
if (v___x_514_ == 0)
{
return v___x_514_;
}
else
{
uint8_t v___x_515_; 
v___x_515_ = lean_uint8_once(&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_prefix1___closed__3, &lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_prefix1___closed__3_once, _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_prefix1___closed__3);
return v___x_515_;
}
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_suffix1___closed__1(void){
_start:
{
lean_object* v___x_517_; lean_object* v___x_518_; 
v___x_517_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_suffix1___closed__0));
v___x_518_ = lean_string_utf8_byte_size(v___x_517_);
return v___x_518_;
}
}
static uint8_t _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_suffix1___closed__2(void){
_start:
{
lean_object* v___x_519_; lean_object* v___x_520_; uint8_t v___x_521_; 
v___x_519_ = lean_obj_once(&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_front__char___closed__0, &lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_front__char___closed__0_once, _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_front__char___closed__0);
v___x_520_ = lean_obj_once(&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_suffix1___closed__1, &lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_suffix1___closed__1_once, _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_suffix1___closed__1);
v___x_521_ = lean_nat_dec_le(v___x_520_, v___x_519_);
return v___x_521_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_suffix1___closed__3(void){
_start:
{
lean_object* v___x_522_; lean_object* v___x_523_; lean_object* v___x_524_; 
v___x_522_ = lean_obj_once(&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_suffix1___closed__1, &lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_suffix1___closed__1_once, _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_suffix1___closed__1);
v___x_523_ = lean_obj_once(&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_front__char___closed__0, &lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_front__char___closed__0_once, _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_front__char___closed__0);
v___x_524_ = lean_nat_sub(v___x_523_, v___x_522_);
return v___x_524_;
}
}
static uint8_t _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_suffix1___closed__4(void){
_start:
{
lean_object* v___x_525_; lean_object* v___x_526_; lean_object* v___x_527_; lean_object* v___x_528_; lean_object* v___x_529_; uint8_t v___x_530_; 
v___x_525_ = lean_obj_once(&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_suffix1___closed__1, &lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_suffix1___closed__1_once, _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_suffix1___closed__1);
v___x_526_ = lean_unsigned_to_nat(0u);
v___x_527_ = lean_obj_once(&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_suffix1___closed__3, &lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_suffix1___closed__3_once, _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_suffix1___closed__3);
v___x_528_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_suffix1___closed__0));
v___x_529_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_chars___closed__0));
v___x_530_ = lean_string_memcmp(v___x_529_, v___x_528_, v___x_527_, v___x_526_, v___x_525_);
return v___x_530_;
}
}
static uint8_t _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_suffix1(void){
_start:
{
uint8_t v___x_531_; 
v___x_531_ = lean_uint8_once(&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_suffix1___closed__2, &lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_suffix1___closed__2_once, _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_suffix1___closed__2);
if (v___x_531_ == 0)
{
return v___x_531_;
}
else
{
uint8_t v___x_532_; 
v___x_532_ = lean_uint8_once(&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_suffix1___closed__4, &lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_suffix1___closed__4_once, _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_suffix1___closed__4);
return v___x_532_;
}
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_findChar_findPos(lean_object* v_a_533_, uint32_t v_a_534_, lean_object* v_a_535_){
_start:
{
if (lean_obj_tag(v_a_533_) == 0)
{
lean_object* v___x_536_; 
lean_dec(v_a_535_);
v___x_536_ = lean_box(0);
return v___x_536_;
}
else
{
lean_object* v_head_537_; lean_object* v_tail_538_; uint32_t v___x_539_; uint8_t v___x_540_; 
v_head_537_ = lean_ctor_get(v_a_533_, 0);
v_tail_538_ = lean_ctor_get(v_a_533_, 1);
v___x_539_ = lean_unbox_uint32(v_head_537_);
v___x_540_ = lean_uint32_dec_eq(v___x_539_, v_a_534_);
if (v___x_540_ == 0)
{
lean_object* v___x_541_; lean_object* v___x_542_; 
v___x_541_ = lean_unsigned_to_nat(1u);
v___x_542_ = lean_nat_add(v_a_535_, v___x_541_);
lean_dec(v_a_535_);
v_a_533_ = v_tail_538_;
v_a_535_ = v___x_542_;
goto _start;
}
else
{
lean_object* v___x_544_; 
v___x_544_ = lean_alloc_ctor(1, 1, 0);
lean_ctor_set(v___x_544_, 0, v_a_535_);
return v___x_544_;
}
}
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_findChar_findPos___boxed(lean_object* v_a_545_, lean_object* v_a_546_, lean_object* v_a_547_){
_start:
{
uint32_t v_a_49__boxed_548_; lean_object* v_res_549_; 
v_a_49__boxed_548_ = lean_unbox_uint32(v_a_546_);
lean_dec(v_a_546_);
v_res_549_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_findChar_findPos(v_a_545_, v_a_49__boxed_548_, v_a_547_);
lean_dec(v_a_545_);
return v_res_549_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_findChar(lean_object* v_s_550_, uint32_t v_c_551_){
_start:
{
lean_object* v___x_552_; lean_object* v___x_553_; lean_object* v___x_554_; 
v___x_552_ = lean_string_data(v_s_550_);
v___x_553_ = lean_unsigned_to_nat(0u);
v___x_554_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_findChar_findPos(v___x_552_, v_c_551_, v___x_553_);
lean_dec(v___x_552_);
return v___x_554_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_findChar___boxed(lean_object* v_s_555_, lean_object* v_c_556_){
_start:
{
uint32_t v_c_boxed_557_; lean_object* v_res_558_; 
v_c_boxed_557_ = lean_unbox_uint32(v_c_556_);
lean_dec(v_c_556_);
v_res_558_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_findChar(v_s_555_, v_c_boxed_557_);
return v_res_558_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_find__h___closed__0(void){
_start:
{
uint32_t v___x_559_; lean_object* v___x_560_; lean_object* v___x_561_; 
v___x_559_ = 104;
v___x_560_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_is__empty2___closed__0));
v___x_561_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_findChar(v___x_560_, v___x_559_);
return v___x_561_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_find__h(void){
_start:
{
lean_object* v___x_562_; 
v___x_562_ = lean_obj_once(&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_find__h___closed__0, &lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_find__h___closed__0_once, _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_find__h___closed__0);
return v___x_562_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_find__l___closed__0(void){
_start:
{
uint32_t v___x_563_; lean_object* v___x_564_; lean_object* v___x_565_; 
v___x_563_ = 108;
v___x_564_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_is__empty2___closed__0));
v___x_565_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_findChar(v___x_564_, v___x_563_);
return v___x_565_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_find__l(void){
_start:
{
lean_object* v___x_566_; 
v___x_566_ = lean_obj_once(&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_find__l___closed__0, &lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_find__l___closed__0_once, _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_find__l___closed__0);
return v___x_566_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_find__z___closed__0(void){
_start:
{
uint32_t v___x_567_; lean_object* v___x_568_; lean_object* v___x_569_; 
v___x_567_ = 122;
v___x_568_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_is__empty2___closed__0));
v___x_569_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_findChar(v___x_568_, v___x_567_);
return v___x_569_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_find__z(void){
_start:
{
lean_object* v___x_570_; 
v___x_570_ = lean_obj_once(&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_find__z___closed__0, &lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_find__z___closed__0_once, _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_find__z___closed__0);
return v___x_570_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_List_filterTR_loop___at___00Lean4Tutorial_Examples_Basics_Strings_countChar_spec__0(uint32_t v_c_571_, lean_object* v_a_572_, lean_object* v_a_573_){
_start:
{
if (lean_obj_tag(v_a_572_) == 0)
{
lean_object* v___x_574_; 
v___x_574_ = l_List_reverse___redArg(v_a_573_);
return v___x_574_;
}
else
{
lean_object* v_head_575_; lean_object* v_tail_576_; lean_object* v___x_578_; uint8_t v_isShared_579_; uint8_t v_isSharedCheck_587_; 
v_head_575_ = lean_ctor_get(v_a_572_, 0);
v_tail_576_ = lean_ctor_get(v_a_572_, 1);
v_isSharedCheck_587_ = !lean_is_exclusive(v_a_572_);
if (v_isSharedCheck_587_ == 0)
{
v___x_578_ = v_a_572_;
v_isShared_579_ = v_isSharedCheck_587_;
goto v_resetjp_577_;
}
else
{
lean_inc(v_tail_576_);
lean_inc(v_head_575_);
lean_dec(v_a_572_);
v___x_578_ = lean_box(0);
v_isShared_579_ = v_isSharedCheck_587_;
goto v_resetjp_577_;
}
v_resetjp_577_:
{
uint32_t v___x_580_; uint8_t v___x_581_; 
v___x_580_ = lean_unbox_uint32(v_head_575_);
v___x_581_ = lean_uint32_dec_eq(v___x_580_, v_c_571_);
if (v___x_581_ == 0)
{
lean_del_object(v___x_578_);
lean_dec(v_head_575_);
v_a_572_ = v_tail_576_;
goto _start;
}
else
{
lean_object* v___x_584_; 
if (v_isShared_579_ == 0)
{
lean_ctor_set(v___x_578_, 1, v_a_573_);
v___x_584_ = v___x_578_;
goto v_reusejp_583_;
}
else
{
lean_object* v_reuseFailAlloc_586_; 
v_reuseFailAlloc_586_ = lean_alloc_ctor(1, 2, 0);
lean_ctor_set(v_reuseFailAlloc_586_, 0, v_head_575_);
lean_ctor_set(v_reuseFailAlloc_586_, 1, v_a_573_);
v___x_584_ = v_reuseFailAlloc_586_;
goto v_reusejp_583_;
}
v_reusejp_583_:
{
v_a_572_ = v_tail_576_;
v_a_573_ = v___x_584_;
goto _start;
}
}
}
}
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_List_filterTR_loop___at___00Lean4Tutorial_Examples_Basics_Strings_countChar_spec__0___boxed(lean_object* v_c_588_, lean_object* v_a_589_, lean_object* v_a_590_){
_start:
{
uint32_t v_c_boxed_591_; lean_object* v_res_592_; 
v_c_boxed_591_ = lean_unbox_uint32(v_c_588_);
lean_dec(v_c_588_);
v_res_592_ = lp_lean4_x2dtutorial_List_filterTR_loop___at___00Lean4Tutorial_Examples_Basics_Strings_countChar_spec__0(v_c_boxed_591_, v_a_589_, v_a_590_);
return v_res_592_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_countChar(lean_object* v_s_593_, uint32_t v_c_594_){
_start:
{
lean_object* v___x_595_; lean_object* v___x_596_; lean_object* v___x_597_; lean_object* v___x_598_; 
v___x_595_ = lean_string_data(v_s_593_);
v___x_596_ = lean_box(0);
v___x_597_ = lp_lean4_x2dtutorial_List_filterTR_loop___at___00Lean4Tutorial_Examples_Basics_Strings_countChar_spec__0(v_c_594_, v___x_595_, v___x_596_);
v___x_598_ = l_List_lengthTR___redArg(v___x_597_);
lean_dec(v___x_597_);
return v___x_598_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_countChar___boxed(lean_object* v_s_599_, lean_object* v_c_600_){
_start:
{
uint32_t v_c_boxed_601_; lean_object* v_res_602_; 
v_c_boxed_601_ = lean_unbox_uint32(v_c_600_);
lean_dec(v_c_600_);
v_res_602_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_countChar(v_s_599_, v_c_boxed_601_);
return v_res_602_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_count__l___closed__0(void){
_start:
{
uint32_t v___x_603_; lean_object* v___x_604_; lean_object* v___x_605_; 
v___x_603_ = 108;
v___x_604_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_is__empty2___closed__0));
v___x_605_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_countChar(v___x_604_, v___x_603_);
return v___x_605_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_count__l(void){
_start:
{
lean_object* v___x_606_; 
v___x_606_ = lean_obj_once(&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_count__l___closed__0, &lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_count__l___closed__0_once, _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_count__l___closed__0);
return v___x_606_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_parse__nat1___closed__1(void){
_start:
{
lean_object* v___x_608_; lean_object* v___x_609_; 
v___x_608_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_parse__nat1___closed__0));
v___x_609_ = lean_string_utf8_byte_size(v___x_608_);
return v___x_609_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_parse__nat1___closed__2(void){
_start:
{
lean_object* v___x_610_; lean_object* v___x_611_; lean_object* v___x_612_; lean_object* v___x_613_; 
v___x_610_ = lean_obj_once(&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_parse__nat1___closed__1, &lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_parse__nat1___closed__1_once, _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_parse__nat1___closed__1);
v___x_611_ = lean_unsigned_to_nat(0u);
v___x_612_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_parse__nat1___closed__0));
v___x_613_ = lean_alloc_ctor(0, 3, 0);
lean_ctor_set(v___x_613_, 0, v___x_612_);
lean_ctor_set(v___x_613_, 1, v___x_611_);
lean_ctor_set(v___x_613_, 2, v___x_610_);
return v___x_613_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_parse__nat1___closed__3(void){
_start:
{
lean_object* v___x_614_; lean_object* v___x_615_; 
v___x_614_ = lean_obj_once(&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_parse__nat1___closed__2, &lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_parse__nat1___closed__2_once, _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_parse__nat1___closed__2);
v___x_615_ = l_String_Slice_toNat_x3f(v___x_614_);
return v___x_615_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_parse__nat1(void){
_start:
{
lean_object* v___x_616_; 
v___x_616_ = lean_obj_once(&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_parse__nat1___closed__3, &lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_parse__nat1___closed__3_once, _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_parse__nat1___closed__3);
return v___x_616_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_parse__nat2___closed__1(void){
_start:
{
lean_object* v___x_618_; lean_object* v___x_619_; 
v___x_618_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_parse__nat2___closed__0));
v___x_619_ = lean_string_utf8_byte_size(v___x_618_);
return v___x_619_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_parse__nat2___closed__2(void){
_start:
{
lean_object* v___x_620_; lean_object* v___x_621_; lean_object* v___x_622_; lean_object* v___x_623_; 
v___x_620_ = lean_obj_once(&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_parse__nat2___closed__1, &lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_parse__nat2___closed__1_once, _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_parse__nat2___closed__1);
v___x_621_ = lean_unsigned_to_nat(0u);
v___x_622_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_parse__nat2___closed__0));
v___x_623_ = lean_alloc_ctor(0, 3, 0);
lean_ctor_set(v___x_623_, 0, v___x_622_);
lean_ctor_set(v___x_623_, 1, v___x_621_);
lean_ctor_set(v___x_623_, 2, v___x_620_);
return v___x_623_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_parse__nat2___closed__3(void){
_start:
{
lean_object* v___x_624_; lean_object* v___x_625_; 
v___x_624_ = lean_obj_once(&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_parse__nat2___closed__2, &lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_parse__nat2___closed__2_once, _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_parse__nat2___closed__2);
v___x_625_ = l_String_Slice_toNat_x3f(v___x_624_);
return v___x_625_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_parse__nat2(void){
_start:
{
lean_object* v___x_626_; 
v___x_626_ = lean_obj_once(&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_parse__nat2___closed__3, &lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_parse__nat2___closed__3_once, _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_parse__nat2___closed__3);
return v___x_626_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_int__to__string___closed__0(void){
_start:
{
lean_object* v___x_628_; lean_object* v___x_629_; 
v___x_628_ = lean_unsigned_to_nat(7u);
v___x_629_ = lean_nat_to_int(v___x_628_);
return v___x_629_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_int__to__string___closed__1(void){
_start:
{
lean_object* v___x_630_; lean_object* v___x_631_; 
v___x_630_ = lean_obj_once(&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_int__to__string___closed__0, &lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_int__to__string___closed__0_once, _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_int__to__string___closed__0);
v___x_631_ = lean_int_neg(v___x_630_);
return v___x_631_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_int__to__string___closed__2(void){
_start:
{
lean_object* v___x_632_; lean_object* v___x_633_; 
v___x_632_ = lean_obj_once(&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_int__to__string___closed__1, &lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_int__to__string___closed__1_once, _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_int__to__string___closed__1);
v___x_633_ = l_Int_repr(v___x_632_);
return v___x_633_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_int__to__string(void){
_start:
{
lean_object* v___x_634_; 
v___x_634_ = lean_obj_once(&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_int__to__string___closed__2, &lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_int__to__string___closed__2_once, _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_int__to__string___closed__2);
return v___x_634_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_splitOnChar_splitAux(lean_object* v_a_641_, uint32_t v_a_642_, lean_object* v_a_643_){
_start:
{
if (lean_obj_tag(v_a_641_) == 0)
{
uint8_t v___x_644_; 
v___x_644_ = l_List_isEmpty___redArg(v_a_643_);
if (v___x_644_ == 0)
{
lean_object* v___x_645_; lean_object* v___x_646_; lean_object* v___x_647_; lean_object* v___x_648_; 
v___x_645_ = l_List_reverse___redArg(v_a_643_);
v___x_646_ = lean_string_mk(v___x_645_);
v___x_647_ = lean_box(0);
v___x_648_ = lean_alloc_ctor(1, 2, 0);
lean_ctor_set(v___x_648_, 0, v___x_646_);
lean_ctor_set(v___x_648_, 1, v___x_647_);
return v___x_648_;
}
else
{
lean_object* v___x_649_; 
lean_dec(v_a_643_);
v___x_649_ = lean_box(0);
return v___x_649_;
}
}
else
{
lean_object* v_head_650_; lean_object* v_tail_651_; lean_object* v___x_653_; uint8_t v_isShared_654_; uint8_t v_isSharedCheck_668_; 
v_head_650_ = lean_ctor_get(v_a_641_, 0);
v_tail_651_ = lean_ctor_get(v_a_641_, 1);
v_isSharedCheck_668_ = !lean_is_exclusive(v_a_641_);
if (v_isSharedCheck_668_ == 0)
{
v___x_653_ = v_a_641_;
v_isShared_654_ = v_isSharedCheck_668_;
goto v_resetjp_652_;
}
else
{
lean_inc(v_tail_651_);
lean_inc(v_head_650_);
lean_dec(v_a_641_);
v___x_653_ = lean_box(0);
v_isShared_654_ = v_isSharedCheck_668_;
goto v_resetjp_652_;
}
v_resetjp_652_:
{
uint32_t v___x_655_; uint8_t v___x_656_; 
v___x_655_ = lean_unbox_uint32(v_head_650_);
v___x_656_ = lean_uint32_dec_eq(v___x_655_, v_a_642_);
if (v___x_656_ == 0)
{
lean_object* v___x_658_; 
if (v_isShared_654_ == 0)
{
lean_ctor_set(v___x_653_, 1, v_a_643_);
v___x_658_ = v___x_653_;
goto v_reusejp_657_;
}
else
{
lean_object* v_reuseFailAlloc_660_; 
v_reuseFailAlloc_660_ = lean_alloc_ctor(1, 2, 0);
lean_ctor_set(v_reuseFailAlloc_660_, 0, v_head_650_);
lean_ctor_set(v_reuseFailAlloc_660_, 1, v_a_643_);
v___x_658_ = v_reuseFailAlloc_660_;
goto v_reusejp_657_;
}
v_reusejp_657_:
{
v_a_641_ = v_tail_651_;
v_a_643_ = v___x_658_;
goto _start;
}
}
else
{
lean_object* v___x_661_; lean_object* v___x_662_; lean_object* v___x_663_; lean_object* v___x_664_; lean_object* v___x_666_; 
lean_dec(v_head_650_);
v___x_661_ = l_List_reverse___redArg(v_a_643_);
v___x_662_ = lean_string_mk(v___x_661_);
v___x_663_ = lean_box(0);
v___x_664_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_splitOnChar_splitAux(v_tail_651_, v_a_642_, v___x_663_);
if (v_isShared_654_ == 0)
{
lean_ctor_set(v___x_653_, 1, v___x_664_);
lean_ctor_set(v___x_653_, 0, v___x_662_);
v___x_666_ = v___x_653_;
goto v_reusejp_665_;
}
else
{
lean_object* v_reuseFailAlloc_667_; 
v_reuseFailAlloc_667_ = lean_alloc_ctor(1, 2, 0);
lean_ctor_set(v_reuseFailAlloc_667_, 0, v___x_662_);
lean_ctor_set(v_reuseFailAlloc_667_, 1, v___x_664_);
v___x_666_ = v_reuseFailAlloc_667_;
goto v_reusejp_665_;
}
v_reusejp_665_:
{
return v___x_666_;
}
}
}
}
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_splitOnChar_splitAux___boxed(lean_object* v_a_669_, lean_object* v_a_670_, lean_object* v_a_671_){
_start:
{
uint32_t v_a_84__boxed_672_; lean_object* v_res_673_; 
v_a_84__boxed_672_ = lean_unbox_uint32(v_a_670_);
lean_dec(v_a_670_);
v_res_673_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_splitOnChar_splitAux(v_a_669_, v_a_84__boxed_672_, v_a_671_);
return v_res_673_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_splitOnChar(lean_object* v_s_674_, uint32_t v_c_675_){
_start:
{
lean_object* v___x_676_; lean_object* v___x_677_; lean_object* v___x_678_; 
v___x_676_ = lean_string_data(v_s_674_);
v___x_677_ = lean_box(0);
v___x_678_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_splitOnChar_splitAux(v___x_676_, v_c_675_, v___x_677_);
return v___x_678_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_splitOnChar___boxed(lean_object* v_s_679_, lean_object* v_c_680_){
_start:
{
uint32_t v_c_boxed_681_; lean_object* v_res_682_; 
v_c_boxed_681_ = lean_unbox_uint32(v_c_680_);
lean_dec(v_c_680_);
v_res_682_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_splitOnChar(v_s_679_, v_c_boxed_681_);
return v_res_682_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_split__csv___closed__1(void){
_start:
{
uint32_t v___x_684_; lean_object* v___x_685_; lean_object* v___x_686_; 
v___x_684_ = 44;
v___x_685_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_split__csv___closed__0));
v___x_686_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_splitOnChar(v___x_685_, v___x_684_);
return v___x_686_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_split__csv(void){
_start:
{
lean_object* v___x_687_; 
v___x_687_ = lean_obj_once(&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_split__csv___closed__1, &lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_split__csv___closed__1_once, _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_split__csv___closed__1);
return v___x_687_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_split__space___closed__1(void){
_start:
{
uint32_t v___x_689_; lean_object* v___x_690_; lean_object* v___x_691_; 
v___x_689_ = 32;
v___x_690_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_split__space___closed__0));
v___x_691_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_splitOnChar(v___x_690_, v___x_689_);
return v___x_691_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_split__space(void){
_start:
{
lean_object* v___x_692_; 
v___x_692_ = lean_obj_once(&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_split__space___closed__1, &lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_split__space___closed__1_once, _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_split__space___closed__1);
return v___x_692_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_format__example(lean_object* v_name_695_, lean_object* v_score_696_){
_start:
{
lean_object* v___x_697_; lean_object* v___x_698_; lean_object* v___x_699_; lean_object* v___x_700_; lean_object* v___x_701_; lean_object* v___x_702_; 
v___x_697_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_format__example___closed__0));
v___x_698_ = lean_string_append(v_name_695_, v___x_697_);
v___x_699_ = l_Nat_reprFast(v_score_696_);
v___x_700_ = lean_string_append(v___x_698_, v___x_699_);
lean_dec_ref(v___x_699_);
v___x_701_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_format__example___closed__1));
v___x_702_ = lean_string_append(v___x_700_, v___x_701_);
return v___x_702_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_alice__score___closed__0(void){
_start:
{
lean_object* v___x_703_; lean_object* v___x_704_; lean_object* v___x_705_; 
v___x_703_ = lean_unsigned_to_nat(95u);
v___x_704_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_name___closed__0));
v___x_705_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_format__example(v___x_704_, v___x_703_);
return v___x_705_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_alice__score(void){
_start:
{
lean_object* v___x_706_; 
v___x_706_ = lean_obj_once(&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_alice__score___closed__0, &lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_alice__score___closed__0_once, _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_alice__score___closed__0);
return v___x_706_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_padRight(lean_object* v_s_707_, lean_object* v_width_708_, uint32_t v_padChar_709_){
_start:
{
lean_object* v___x_710_; uint8_t v___x_711_; 
v___x_710_ = lean_string_length(v_s_707_);
v___x_711_ = lean_nat_dec_le(v_width_708_, v___x_710_);
if (v___x_711_ == 0)
{
lean_object* v___x_712_; lean_object* v___x_713_; lean_object* v___x_714_; lean_object* v___x_715_; lean_object* v___x_716_; 
v___x_712_ = lean_nat_sub(v_width_708_, v___x_710_);
v___x_713_ = lean_box_uint32(v_padChar_709_);
v___x_714_ = l_List_replicateTR___redArg(v___x_712_, v___x_713_);
v___x_715_ = lean_string_mk(v___x_714_);
v___x_716_ = lean_string_append(v_s_707_, v___x_715_);
lean_dec_ref(v___x_715_);
return v___x_716_;
}
else
{
return v_s_707_;
}
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_padRight___boxed(lean_object* v_s_717_, lean_object* v_width_718_, lean_object* v_padChar_719_){
_start:
{
uint32_t v_padChar_boxed_720_; lean_object* v_res_721_; 
v_padChar_boxed_720_ = lean_unbox_uint32(v_padChar_719_);
lean_dec(v_padChar_719_);
v_res_721_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_padRight(v_s_717_, v_width_718_, v_padChar_boxed_720_);
lean_dec(v_width_718_);
return v_res_721_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_padLeft(lean_object* v_s_722_, lean_object* v_width_723_, uint32_t v_padChar_724_){
_start:
{
lean_object* v___x_725_; uint8_t v___x_726_; 
v___x_725_ = lean_string_length(v_s_722_);
v___x_726_ = lean_nat_dec_le(v_width_723_, v___x_725_);
if (v___x_726_ == 0)
{
lean_object* v___x_727_; lean_object* v___x_728_; lean_object* v___x_729_; lean_object* v___x_730_; lean_object* v___x_731_; 
v___x_727_ = lean_nat_sub(v_width_723_, v___x_725_);
v___x_728_ = lean_box_uint32(v_padChar_724_);
v___x_729_ = l_List_replicateTR___redArg(v___x_727_, v___x_728_);
v___x_730_ = lean_string_mk(v___x_729_);
v___x_731_ = lean_string_append(v___x_730_, v_s_722_);
return v___x_731_;
}
else
{
lean_inc_ref(v_s_722_);
return v_s_722_;
}
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_padLeft___boxed(lean_object* v_s_732_, lean_object* v_width_733_, lean_object* v_padChar_734_){
_start:
{
uint32_t v_padChar_boxed_735_; lean_object* v_res_736_; 
v_padChar_boxed_735_ = lean_unbox_uint32(v_padChar_734_);
lean_dec(v_padChar_734_);
v_res_736_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_padLeft(v_s_732_, v_width_733_, v_padChar_boxed_735_);
lean_dec(v_width_733_);
lean_dec_ref(v_s_732_);
return v_res_736_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_format__row(lean_object* v_name_740_, lean_object* v_score_741_){
_start:
{
lean_object* v___x_742_; lean_object* v___x_743_; uint32_t v___x_744_; lean_object* v___x_745_; lean_object* v___x_746_; lean_object* v___x_747_; lean_object* v___x_748_; lean_object* v___x_749_; lean_object* v___x_750_; lean_object* v___x_751_; lean_object* v___x_752_; lean_object* v___x_753_; lean_object* v___x_754_; 
v___x_742_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_format__row___closed__0));
v___x_743_ = lean_unsigned_to_nat(10u);
v___x_744_ = 32;
v___x_745_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_padRight(v_name_740_, v___x_743_, v___x_744_);
v___x_746_ = lean_string_append(v___x_742_, v___x_745_);
lean_dec_ref(v___x_745_);
v___x_747_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_format__row___closed__1));
v___x_748_ = lean_string_append(v___x_746_, v___x_747_);
v___x_749_ = l_Nat_reprFast(v_score_741_);
v___x_750_ = lean_unsigned_to_nat(5u);
v___x_751_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_padLeft(v___x_749_, v___x_750_, v___x_744_);
lean_dec_ref(v___x_749_);
v___x_752_ = lean_string_append(v___x_748_, v___x_751_);
lean_dec_ref(v___x_751_);
v___x_753_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_format__row___closed__2));
v___x_754_ = lean_string_append(v___x_752_, v___x_753_);
return v___x_754_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_table__header___closed__1(void){
_start:
{
uint32_t v___x_756_; lean_object* v___x_757_; lean_object* v___x_758_; lean_object* v___x_759_; 
v___x_756_ = 32;
v___x_757_ = lean_unsigned_to_nat(10u);
v___x_758_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_table__header___closed__0));
v___x_759_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_padRight(v___x_758_, v___x_757_, v___x_756_);
return v___x_759_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_table__header___closed__2(void){
_start:
{
lean_object* v___x_760_; lean_object* v___x_761_; lean_object* v___x_762_; 
v___x_760_ = lean_obj_once(&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_table__header___closed__1, &lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_table__header___closed__1_once, _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_table__header___closed__1);
v___x_761_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_format__row___closed__0));
v___x_762_ = lean_string_append(v___x_761_, v___x_760_);
return v___x_762_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_table__header___closed__3(void){
_start:
{
lean_object* v___x_763_; lean_object* v___x_764_; lean_object* v___x_765_; 
v___x_763_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_format__row___closed__1));
v___x_764_ = lean_obj_once(&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_table__header___closed__2, &lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_table__header___closed__2_once, _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_table__header___closed__2);
v___x_765_ = lean_string_append(v___x_764_, v___x_763_);
return v___x_765_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_table__header___closed__5(void){
_start:
{
uint32_t v___x_767_; lean_object* v___x_768_; lean_object* v___x_769_; lean_object* v___x_770_; 
v___x_767_ = 32;
v___x_768_ = lean_unsigned_to_nat(5u);
v___x_769_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_table__header___closed__4));
v___x_770_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_padLeft(v___x_769_, v___x_768_, v___x_767_);
return v___x_770_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_table__header___closed__6(void){
_start:
{
lean_object* v___x_771_; lean_object* v___x_772_; lean_object* v___x_773_; 
v___x_771_ = lean_obj_once(&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_table__header___closed__5, &lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_table__header___closed__5_once, _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_table__header___closed__5);
v___x_772_ = lean_obj_once(&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_table__header___closed__3, &lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_table__header___closed__3_once, _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_table__header___closed__3);
v___x_773_ = lean_string_append(v___x_772_, v___x_771_);
return v___x_773_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_table__header___closed__7(void){
_start:
{
lean_object* v___x_774_; lean_object* v___x_775_; lean_object* v___x_776_; 
v___x_774_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_format__row___closed__2));
v___x_775_ = lean_obj_once(&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_table__header___closed__6, &lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_table__header___closed__6_once, _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_table__header___closed__6);
v___x_776_ = lean_string_append(v___x_775_, v___x_774_);
return v___x_776_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_table__header(void){
_start:
{
lean_object* v___x_777_; 
v___x_777_ = lean_obj_once(&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_table__header___closed__7, &lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_table__header___closed__7_once, _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_table__header___closed__7);
return v___x_777_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_table__row1___closed__0(void){
_start:
{
lean_object* v___x_778_; lean_object* v___x_779_; lean_object* v___x_780_; 
v___x_778_ = lean_unsigned_to_nat(95u);
v___x_779_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_name___closed__0));
v___x_780_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_format__row(v___x_779_, v___x_778_);
return v___x_780_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_table__row1(void){
_start:
{
lean_object* v___x_781_; 
v___x_781_ = lean_obj_once(&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_table__row1___closed__0, &lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_table__row1___closed__0_once, _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_table__row1___closed__0);
return v___x_781_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_table__row2___closed__1(void){
_start:
{
lean_object* v___x_783_; lean_object* v___x_784_; lean_object* v___x_785_; 
v___x_783_ = lean_unsigned_to_nat(87u);
v___x_784_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_table__row2___closed__0));
v___x_785_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_format__row(v___x_784_, v___x_783_);
return v___x_785_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_table__row2(void){
_start:
{
lean_object* v___x_786_; 
v___x_786_ = lean_obj_once(&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_table__row2___closed__1, &lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_table__row2___closed__1_once, _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_table__row2___closed__1);
return v___x_786_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_table___closed__1(void){
_start:
{
lean_object* v___x_788_; lean_object* v___x_789_; lean_object* v___x_790_; 
v___x_788_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_table___closed__0));
v___x_789_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_table__header;
v___x_790_ = lean_string_append(v___x_789_, v___x_788_);
return v___x_790_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_table___closed__2(void){
_start:
{
lean_object* v___x_791_; lean_object* v___x_792_; lean_object* v___x_793_; 
v___x_791_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_table__row1;
v___x_792_ = lean_obj_once(&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_table___closed__1, &lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_table___closed__1_once, _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_table___closed__1);
v___x_793_ = lean_string_append(v___x_792_, v___x_791_);
return v___x_793_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_table___closed__3(void){
_start:
{
lean_object* v___x_794_; lean_object* v___x_795_; lean_object* v___x_796_; 
v___x_794_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_table___closed__0));
v___x_795_ = lean_obj_once(&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_table___closed__2, &lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_table___closed__2_once, _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_table___closed__2);
v___x_796_ = lean_string_append(v___x_795_, v___x_794_);
return v___x_796_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_table___closed__4(void){
_start:
{
lean_object* v___x_797_; lean_object* v___x_798_; lean_object* v___x_799_; 
v___x_797_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_table__row2;
v___x_798_ = lean_obj_once(&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_table___closed__3, &lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_table___closed__3_once, _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_table___closed__3);
v___x_799_ = lean_string_append(v___x_798_, v___x_797_);
return v___x_799_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_table(void){
_start:
{
lean_object* v___x_800_; 
v___x_800_ = lean_obj_once(&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_table___closed__4, &lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_table___closed__4_once, _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_table___closed__4);
return v___x_800_;
}
}
lean_object* initialize_Init(uint8_t builtin);
lean_object* initialize_Init(uint8_t builtin);
static bool _G_initialized = false;
LEAN_EXPORT lean_object* initialize_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings(uint8_t builtin) {
lean_object * res;
if (_G_initialized) return lean_io_result_mk_ok(lean_box(0));
_G_initialized = true;
res = initialize_Init(builtin);
if (lean_io_result_is_error(res)) return res;
lean_dec_ref(res);
res = initialize_Init(builtin);
if (lean_io_result_is_error(res)) return res;
lean_dec_ref(res);
lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_joined = _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_joined();
lean_mark_persistent(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_joined);
lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_with__spaces = _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_with__spaces();
lean_mark_persistent(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_with__spaces);
lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_len1 = _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_len1();
lean_mark_persistent(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_len1);
lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_len2 = _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_len2();
lean_mark_persistent(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_len2);
lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_len3 = _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_len3();
lean_mark_persistent(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_len3);
lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_is__empty1 = _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_is__empty1();
lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_is__empty2 = _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_is__empty2();
lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_age = _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_age();
lean_mark_persistent(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_age);
lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_name__length = _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_name__length();
lean_mark_persistent(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_name__length);
lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_eq1 = _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_eq1();
lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_eq2 = _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_eq2();
lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_ne1 = _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_ne1();
lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_lt1 = _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_lt1();
lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_le1 = _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_le1();
lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_gt1 = _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_gt1();
lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_chars = _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_chars();
lean_mark_persistent(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_chars);
lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_from__chars___closed__0___boxed__const__1 = _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_from__chars___closed__0___boxed__const__1();
lean_mark_persistent(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_from__chars___closed__0___boxed__const__1);
lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_from__chars___closed__1___boxed__const__1 = _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_from__chars___closed__1___boxed__const__1();
lean_mark_persistent(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_from__chars___closed__1___boxed__const__1);
lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_from__chars___closed__2___boxed__const__1 = _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_from__chars___closed__2___boxed__const__1();
lean_mark_persistent(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_from__chars___closed__2___boxed__const__1);
lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_from__chars = _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_from__chars();
lean_mark_persistent(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_from__chars);
lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_reversed = _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_reversed();
lean_mark_persistent(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_reversed);
lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_first__char = _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_first__char();
lean_mark_persistent(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_first__char);
lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_fifth__char = _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_fifth__char();
lean_mark_persistent(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_fifth__char);
lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_out__of__bounds = _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_out__of__bounds();
lean_mark_persistent(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_out__of__bounds);
lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_front__char = _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_front__char();
lean_mark_persistent(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_front__char);
lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_back__char = _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_back__char();
lean_mark_persistent(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_back__char);
lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_get__or__default = _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_get__or__default();
lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_get__default = _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_get__default();
lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_take5 = _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_take5();
lean_mark_persistent(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_take5);
lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_drop7 = _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_drop7();
lean_mark_persistent(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_drop7);
lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_substr1 = _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_substr1();
lean_mark_persistent(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_substr1);
lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_substr2 = _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_substr2();
lean_mark_persistent(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_substr2);
lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_upper = _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_upper();
lean_mark_persistent(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_upper);
lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_lower = _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_lower();
lean_mark_persistent(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_lower);
lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_trimmed1 = _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_trimmed1();
lean_mark_persistent(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_trimmed1);
lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_trimmed2 = _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_trimmed2();
lean_mark_persistent(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_trimmed2);
lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_triml = _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_triml();
lean_mark_persistent(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_triml);
lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_trimr = _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_trimr();
lean_mark_persistent(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_trimr);
lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_replaced = _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_replaced();
lean_mark_persistent(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_replaced);
lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_repeated = _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_repeated();
lean_mark_persistent(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_repeated);
lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_contains1 = _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_contains1();
lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_contains2 = _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_contains2();
lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_prefix1 = _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_prefix1();
lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_suffix1 = _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_suffix1();
lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_find__h = _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_find__h();
lean_mark_persistent(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_find__h);
lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_find__l = _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_find__l();
lean_mark_persistent(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_find__l);
lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_find__z = _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_find__z();
lean_mark_persistent(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_find__z);
lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_count__l = _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_count__l();
lean_mark_persistent(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_count__l);
lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_parse__nat1 = _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_parse__nat1();
lean_mark_persistent(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_parse__nat1);
lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_parse__nat2 = _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_parse__nat2();
lean_mark_persistent(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_parse__nat2);
lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_int__to__string = _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_int__to__string();
lean_mark_persistent(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_int__to__string);
lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_split__csv = _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_split__csv();
lean_mark_persistent(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_split__csv);
lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_split__space = _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_split__space();
lean_mark_persistent(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_split__space);
lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_alice__score = _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_alice__score();
lean_mark_persistent(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_alice__score);
lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_table__header = _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_table__header();
lean_mark_persistent(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_table__header);
lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_table__row1 = _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_table__row1();
lean_mark_persistent(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_table__row1);
lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_table__row2 = _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_table__row2();
lean_mark_persistent(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_table__row2);
lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_table = _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_table();
lean_mark_persistent(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Strings_table);
return lean_io_result_mk_ok(lean_box(0));
}
#ifdef __cplusplus
}
#endif
