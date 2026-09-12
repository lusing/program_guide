// Lean compiler output
// Module: Lean4Tutorial.Examples.Basics.Polymorphism
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
lean_object* lean_int_neg(lean_object*);
lean_object* l_Nat_add___boxed(lean_object*, lean_object*);
lean_object* lean_nat_mul(lean_object*, lean_object*);
lean_object* lean_string_append(lean_object*, lean_object*);
lean_object* l_String_length___boxed(lean_object*);
lean_object* lean_nat_add(lean_object*, lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Polymorphism_id___redArg(lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Polymorphism_id___redArg___boxed(lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Polymorphism_id(lean_object*, lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Polymorphism_id___boxed(lean_object*, lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Polymorphism_id__nat;
static const lean_string_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Polymorphism_id__string___closed__0_value = {.m_header = {.m_rc = 0, .m_cs_sz = 0, .m_other = 0, .m_tag = 249}, .m_size = 6, .m_capacity = 6, .m_length = 5, .m_data = "hello"};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Polymorphism_id__string___closed__0 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Polymorphism_id__string___closed__0_value;
LEAN_EXPORT const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Polymorphism_id__string = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Polymorphism_id__string___closed__0_value;
LEAN_EXPORT uint8_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Polymorphism_id__bool;
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Polymorphism_id__explicit;
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Polymorphism_id__with__type;
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Polymorphism_pair___redArg(lean_object*, lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Polymorphism_pair(lean_object*, lean_object*, lean_object*, lean_object*);
static const lean_string_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Polymorphism_nat__string__pair___closed__0_value = {.m_header = {.m_rc = 0, .m_cs_sz = 0, .m_other = 0, .m_tag = 249}, .m_size = 7, .m_capacity = 7, .m_length = 6, .m_data = "answer"};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Polymorphism_nat__string__pair___closed__0 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Polymorphism_nat__string__pair___closed__0_value;
static const lean_ctor_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Polymorphism_nat__string__pair___closed__1_value = {.m_header = {.m_rc = 0, .m_cs_sz = sizeof(lean_ctor_object) + sizeof(void*)*2 + 0, .m_other = 2, .m_tag = 0}, .m_objs = {((lean_object*)(((size_t)(42) << 1) | 1)),((lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Polymorphism_nat__string__pair___closed__0_value)}};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Polymorphism_nat__string__pair___closed__1 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Polymorphism_nat__string__pair___closed__1_value;
LEAN_EXPORT const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Polymorphism_nat__string__pair = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Polymorphism_nat__string__pair___closed__1_value;
static lean_once_cell_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Polymorphism_bool__int__pair___closed__0_once = LEAN_ONCE_CELL_INITIALIZER;
static lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Polymorphism_bool__int__pair___closed__0;
static lean_once_cell_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Polymorphism_bool__int__pair___closed__1_once = LEAN_ONCE_CELL_INITIALIZER;
static lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Polymorphism_bool__int__pair___closed__1;
static lean_once_cell_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Polymorphism_bool__int__pair___closed__2_once = LEAN_ONCE_CELL_INITIALIZER;
static lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Polymorphism_bool__int__pair___closed__2;
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Polymorphism_bool__int__pair;
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Polymorphism_swap___redArg(lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Polymorphism_swap(lean_object*, lean_object*, lean_object*);
static lean_once_cell_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Polymorphism_swapped___closed__0_once = LEAN_ONCE_CELL_INITIALIZER;
static lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Polymorphism_swapped___closed__0;
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Polymorphism_swapped;
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Polymorphism_triple(lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Polymorphism_triple___boxed(lean_object*);
static const lean_string_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Polymorphism_greet___closed__0_value = {.m_header = {.m_rc = 0, .m_cs_sz = 0, .m_other = 0, .m_tag = 249}, .m_size = 8, .m_capacity = 8, .m_length = 7, .m_data = "Hello, "};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Polymorphism_greet___closed__0 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Polymorphism_greet___closed__0_value;
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Polymorphism_greet(lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Polymorphism_greet___boxed(lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Polymorphism_first___redArg(lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Polymorphism_first___redArg___boxed(lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Polymorphism_first(lean_object*, lean_object*, lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Polymorphism_first___boxed(lean_object*, lean_object*, lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Polymorphism_second___redArg(lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Polymorphism_second___redArg___boxed(lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Polymorphism_second(lean_object*, lean_object*, lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Polymorphism_second___boxed(lean_object*, lean_object*, lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Polymorphism_fst__val;
LEAN_EXPORT const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Polymorphism_snd__val = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Polymorphism_id__string___closed__0_value;
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Polymorphism_implicit__id___redArg(lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Polymorphism_implicit__id___redArg___boxed(lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Polymorphism_implicit__id(lean_object*, lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Polymorphism_implicit__id___boxed(lean_object*, lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Polymorphism_explicit__id___redArg(lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Polymorphism_explicit__id___redArg___boxed(lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Polymorphism_explicit__id(lean_object*, lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Polymorphism_explicit__id___boxed(lean_object*, lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Polymorphism_imp1;
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Polymorphism_exp1;
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Polymorphism_exp2;
static const lean_ctor_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Polymorphism_point2d___closed__0_value = {.m_header = {.m_rc = 0, .m_cs_sz = sizeof(lean_ctor_object) + sizeof(void*)*2 + 0, .m_other = 2, .m_tag = 0}, .m_objs = {((lean_object*)(((size_t)(3) << 1) | 1)),((lean_object*)(((size_t)(4) << 1) | 1))}};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Polymorphism_point2d___closed__0 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Polymorphism_point2d___closed__0_value;
LEAN_EXPORT const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Polymorphism_point2d = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Polymorphism_point2d___closed__0_value;
static const lean_string_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Polymorphism_name__age___closed__0_value = {.m_header = {.m_rc = 0, .m_cs_sz = 0, .m_other = 0, .m_tag = 249}, .m_size = 6, .m_capacity = 6, .m_length = 5, .m_data = "Alice"};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Polymorphism_name__age___closed__0 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Polymorphism_name__age___closed__0_value;
static const lean_ctor_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Polymorphism_name__age___closed__1_value = {.m_header = {.m_rc = 0, .m_cs_sz = sizeof(lean_ctor_object) + sizeof(void*)*2 + 0, .m_other = 2, .m_tag = 0}, .m_objs = {((lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Polymorphism_name__age___closed__0_value),((lean_object*)(((size_t)(30) << 1) | 1))}};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Polymorphism_name__age___closed__1 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Polymorphism_name__age___closed__1_value;
LEAN_EXPORT const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Polymorphism_name__age = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Polymorphism_name__age___closed__1_value;
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Polymorphism_x__coord;
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Polymorphism_y__coord;
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Polymorphism_person__name;
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Polymorphism_person__age;
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Polymorphism_fst__example;
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Polymorphism_snd__example;
static const lean_ctor_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Polymorphism_triple__val___closed__0_value = {.m_header = {.m_rc = 0, .m_cs_sz = sizeof(lean_ctor_object) + sizeof(void*)*2 + 0, .m_other = 2, .m_tag = 0}, .m_objs = {((lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Polymorphism_id__string___closed__0_value),((lean_object*)(((size_t)(1) << 1) | 1))}};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Polymorphism_triple__val___closed__0 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Polymorphism_triple__val___closed__0_value;
static const lean_ctor_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Polymorphism_triple__val___closed__1_value = {.m_header = {.m_rc = 0, .m_cs_sz = sizeof(lean_ctor_object) + sizeof(void*)*2 + 0, .m_other = 2, .m_tag = 0}, .m_objs = {((lean_object*)(((size_t)(42) << 1) | 1)),((lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Polymorphism_triple__val___closed__0_value)}};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Polymorphism_triple__val___closed__1 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Polymorphism_triple__val___closed__1_value;
LEAN_EXPORT const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Polymorphism_triple__val = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Polymorphism_triple__val___closed__1_value;
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Polymorphism_tri__fst;
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Polymorphism_tri__snd;
LEAN_EXPORT uint8_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Polymorphism_tri__thr;
LEAN_EXPORT const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Polymorphism_triple2 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Polymorphism_triple__val___closed__1_value;
static const lean_ctor_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Polymorphism_nested___closed__0_value = {.m_header = {.m_rc = 0, .m_cs_sz = sizeof(lean_ctor_object) + sizeof(void*)*2 + 0, .m_other = 2, .m_tag = 0}, .m_objs = {((lean_object*)(((size_t)(1) << 1) | 1)),((lean_object*)(((size_t)(2) << 1) | 1))}};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Polymorphism_nested___closed__0 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Polymorphism_nested___closed__0_value;
static const lean_string_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Polymorphism_nested___closed__1_value = {.m_header = {.m_rc = 0, .m_cs_sz = 0, .m_other = 0, .m_tag = 249}, .m_size = 6, .m_capacity = 6, .m_length = 5, .m_data = "first"};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Polymorphism_nested___closed__1 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Polymorphism_nested___closed__1_value;
static const lean_string_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Polymorphism_nested___closed__2_value = {.m_header = {.m_rc = 0, .m_cs_sz = 0, .m_other = 0, .m_tag = 249}, .m_size = 7, .m_capacity = 7, .m_length = 6, .m_data = "second"};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Polymorphism_nested___closed__2 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Polymorphism_nested___closed__2_value;
static const lean_ctor_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Polymorphism_nested___closed__3_value = {.m_header = {.m_rc = 0, .m_cs_sz = sizeof(lean_ctor_object) + sizeof(void*)*2 + 0, .m_other = 2, .m_tag = 0}, .m_objs = {((lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Polymorphism_nested___closed__1_value),((lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Polymorphism_nested___closed__2_value)}};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Polymorphism_nested___closed__3 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Polymorphism_nested___closed__3_value;
static const lean_ctor_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Polymorphism_nested___closed__4_value = {.m_header = {.m_rc = 0, .m_cs_sz = sizeof(lean_ctor_object) + sizeof(void*)*2 + 0, .m_other = 2, .m_tag = 0}, .m_objs = {((lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Polymorphism_nested___closed__0_value),((lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Polymorphism_nested___closed__3_value)}};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Polymorphism_nested___closed__4 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Polymorphism_nested___closed__4_value;
LEAN_EXPORT const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Polymorphism_nested = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Polymorphism_nested___closed__4_value;
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Polymorphism_mapFirst___redArg(lean_object*, lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Polymorphism_mapFirst(lean_object*, lean_object*, lean_object*, lean_object*, lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Polymorphism_mapSecond___redArg(lean_object*, lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Polymorphism_mapSecond(lean_object*, lean_object*, lean_object*, lean_object*, lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Polymorphism_map__first__result___lam__0(lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Polymorphism_map__first__result___lam__0___boxed(lean_object*);
static const lean_closure_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Polymorphism_map__first__result___closed__0_value = {.m_header = {.m_rc = 0, .m_cs_sz = sizeof(lean_closure_object) + sizeof(void*)*0, .m_other = 0, .m_tag = 245}, .m_fun = (void*)lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Polymorphism_map__first__result___lam__0___boxed, .m_arity = 1, .m_num_fixed = 0, .m_objs = {} };
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Polymorphism_map__first__result___closed__0 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Polymorphism_map__first__result___closed__0_value;
static const lean_ctor_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Polymorphism_map__first__result___closed__1_value = {.m_header = {.m_rc = 0, .m_cs_sz = sizeof(lean_ctor_object) + sizeof(void*)*2 + 0, .m_other = 2, .m_tag = 0}, .m_objs = {((lean_object*)(((size_t)(5) << 1) | 1)),((lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Polymorphism_id__string___closed__0_value)}};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Polymorphism_map__first__result___closed__1 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Polymorphism_map__first__result___closed__1_value;
static lean_once_cell_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Polymorphism_map__first__result___closed__2_once = LEAN_ONCE_CELL_INITIALIZER;
static lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Polymorphism_map__first__result___closed__2;
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Polymorphism_map__first__result;
static const lean_closure_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Polymorphism_map__second__result___closed__0_value = {.m_header = {.m_rc = 0, .m_cs_sz = sizeof(lean_closure_object) + sizeof(void*)*0, .m_other = 0, .m_tag = 245}, .m_fun = (void*)l_String_length___boxed, .m_arity = 1, .m_num_fixed = 0, .m_objs = {} };
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Polymorphism_map__second__result___closed__0 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Polymorphism_map__second__result___closed__0_value;
static lean_once_cell_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Polymorphism_map__second__result___closed__1_once = LEAN_ONCE_CELL_INITIALIZER;
static lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Polymorphism_map__second__result___closed__1;
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Polymorphism_map__second__result;
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Polymorphism_zipWith___redArg(lean_object*, lean_object*, lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Polymorphism_zipWith(lean_object*, lean_object*, lean_object*, lean_object*, lean_object*, lean_object*);
static const lean_closure_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Polymorphism_add__points___closed__0_value = {.m_header = {.m_rc = 0, .m_cs_sz = sizeof(lean_closure_object) + sizeof(void*)*0, .m_other = 0, .m_tag = 245}, .m_fun = (void*)l_Nat_add___boxed, .m_arity = 2, .m_num_fixed = 0, .m_objs = {} };
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Polymorphism_add__points___closed__0 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Polymorphism_add__points___closed__0_value;
static lean_once_cell_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Polymorphism_add__points___closed__1_once = LEAN_ONCE_CELL_INITIALIZER;
static lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Polymorphism_add__points___closed__1;
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Polymorphism_add__points;
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Polymorphism_unit__val;
static const lean_ctor_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Polymorphism_origin___closed__0_value = {.m_header = {.m_rc = 0, .m_cs_sz = sizeof(lean_ctor_object) + sizeof(void*)*2 + 0, .m_other = 2, .m_tag = 0}, .m_objs = {((lean_object*)(((size_t)(0) << 1) | 1)),((lean_object*)(((size_t)(0) << 1) | 1))}};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Polymorphism_origin___closed__0 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Polymorphism_origin___closed__0_value;
LEAN_EXPORT const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Polymorphism_origin = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Polymorphism_origin___closed__0_value;
LEAN_EXPORT const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Polymorphism_alice = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Polymorphism_name__age___closed__1_value;
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Polymorphism_boxed__int;
LEAN_EXPORT const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Polymorphism_boxed__string = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Polymorphism_id__string___closed__0_value;
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Polymorphism_unbox___redArg(lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Polymorphism_unbox___redArg___boxed(lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Polymorphism_unbox(lean_object*, lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Polymorphism_unbox___boxed(lean_object*, lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Polymorphism_unboxed__nat;
LEAN_EXPORT const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Polymorphism_unboxed__string = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Polymorphism_id__string___closed__0_value;
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Polymorphism_mapBox___redArg(lean_object*, lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Polymorphism_mapBox(lean_object*, lean_object*, lean_object*, lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Polymorphism_mapped__box;
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Polymorphism_id___redArg(lean_object* v_x_1_){
_start:
{
lean_inc(v_x_1_);
return v_x_1_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Polymorphism_id___redArg___boxed(lean_object* v_x_2_){
_start:
{
lean_object* v_res_3_; 
v_res_3_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Polymorphism_id___redArg(v_x_2_);
lean_dec(v_x_2_);
return v_res_3_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Polymorphism_id(lean_object* v_00_u03b1_4_, lean_object* v_x_5_){
_start:
{
lean_inc(v_x_5_);
return v_x_5_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Polymorphism_id___boxed(lean_object* v_00_u03b1_6_, lean_object* v_x_7_){
_start:
{
lean_object* v_res_8_; 
v_res_8_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Polymorphism_id(v_00_u03b1_6_, v_x_7_);
lean_dec(v_x_7_);
return v_res_8_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Polymorphism_id__nat(void){
_start:
{
lean_object* v___x_9_; 
v___x_9_ = lean_unsigned_to_nat(5u);
return v___x_9_;
}
}
static uint8_t _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Polymorphism_id__bool(void){
_start:
{
uint8_t v___x_12_; 
v___x_12_ = 1;
return v___x_12_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Polymorphism_id__explicit(void){
_start:
{
lean_object* v___x_13_; 
v___x_13_ = lean_unsigned_to_nat(5u);
return v___x_13_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Polymorphism_id__with__type(void){
_start:
{
lean_object* v___x_14_; 
v___x_14_ = lean_unsigned_to_nat(5u);
return v___x_14_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Polymorphism_pair___redArg(lean_object* v_x_15_, lean_object* v_y_16_){
_start:
{
lean_object* v___x_17_; 
v___x_17_ = lean_alloc_ctor(0, 2, 0);
lean_ctor_set(v___x_17_, 0, v_x_15_);
lean_ctor_set(v___x_17_, 1, v_y_16_);
return v___x_17_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Polymorphism_pair(lean_object* v_00_u03b1_18_, lean_object* v_00_u03b2_19_, lean_object* v_x_20_, lean_object* v_y_21_){
_start:
{
lean_object* v___x_22_; 
v___x_22_ = lean_alloc_ctor(0, 2, 0);
lean_ctor_set(v___x_22_, 0, v_x_20_);
lean_ctor_set(v___x_22_, 1, v_y_21_);
return v___x_22_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Polymorphism_bool__int__pair___closed__0(void){
_start:
{
lean_object* v___x_28_; lean_object* v___x_29_; 
v___x_28_ = lean_unsigned_to_nat(3u);
v___x_29_ = lean_nat_to_int(v___x_28_);
return v___x_29_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Polymorphism_bool__int__pair___closed__1(void){
_start:
{
lean_object* v___x_30_; lean_object* v___x_31_; 
v___x_30_ = lean_obj_once(&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Polymorphism_bool__int__pair___closed__0, &lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Polymorphism_bool__int__pair___closed__0_once, _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Polymorphism_bool__int__pair___closed__0);
v___x_31_ = lean_int_neg(v___x_30_);
return v___x_31_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Polymorphism_bool__int__pair___closed__2(void){
_start:
{
lean_object* v___x_32_; uint8_t v___x_33_; lean_object* v___x_34_; lean_object* v___x_35_; 
v___x_32_ = lean_obj_once(&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Polymorphism_bool__int__pair___closed__1, &lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Polymorphism_bool__int__pair___closed__1_once, _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Polymorphism_bool__int__pair___closed__1);
v___x_33_ = 1;
v___x_34_ = lean_box(v___x_33_);
v___x_35_ = lean_alloc_ctor(0, 2, 0);
lean_ctor_set(v___x_35_, 0, v___x_34_);
lean_ctor_set(v___x_35_, 1, v___x_32_);
return v___x_35_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Polymorphism_bool__int__pair(void){
_start:
{
lean_object* v___x_36_; 
v___x_36_ = lean_obj_once(&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Polymorphism_bool__int__pair___closed__2, &lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Polymorphism_bool__int__pair___closed__2_once, _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Polymorphism_bool__int__pair___closed__2);
return v___x_36_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Polymorphism_swap___redArg(lean_object* v_p_37_){
_start:
{
lean_object* v_fst_38_; lean_object* v_snd_39_; lean_object* v___x_41_; uint8_t v_isShared_42_; uint8_t v_isSharedCheck_46_; 
v_fst_38_ = lean_ctor_get(v_p_37_, 0);
v_snd_39_ = lean_ctor_get(v_p_37_, 1);
v_isSharedCheck_46_ = !lean_is_exclusive(v_p_37_);
if (v_isSharedCheck_46_ == 0)
{
v___x_41_ = v_p_37_;
v_isShared_42_ = v_isSharedCheck_46_;
goto v_resetjp_40_;
}
else
{
lean_inc(v_snd_39_);
lean_inc(v_fst_38_);
lean_dec(v_p_37_);
v___x_41_ = lean_box(0);
v_isShared_42_ = v_isSharedCheck_46_;
goto v_resetjp_40_;
}
v_resetjp_40_:
{
lean_object* v___x_44_; 
if (v_isShared_42_ == 0)
{
lean_ctor_set(v___x_41_, 1, v_fst_38_);
lean_ctor_set(v___x_41_, 0, v_snd_39_);
v___x_44_ = v___x_41_;
goto v_reusejp_43_;
}
else
{
lean_object* v_reuseFailAlloc_45_; 
v_reuseFailAlloc_45_ = lean_alloc_ctor(0, 2, 0);
lean_ctor_set(v_reuseFailAlloc_45_, 0, v_snd_39_);
lean_ctor_set(v_reuseFailAlloc_45_, 1, v_fst_38_);
v___x_44_ = v_reuseFailAlloc_45_;
goto v_reusejp_43_;
}
v_reusejp_43_:
{
return v___x_44_;
}
}
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Polymorphism_swap(lean_object* v_00_u03b1_47_, lean_object* v_00_u03b2_48_, lean_object* v_p_49_){
_start:
{
lean_object* v___x_50_; 
v___x_50_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Polymorphism_swap___redArg(v_p_49_);
return v___x_50_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Polymorphism_swapped___closed__0(void){
_start:
{
lean_object* v___x_51_; lean_object* v___x_52_; 
v___x_51_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Polymorphism_nat__string__pair));
v___x_52_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Polymorphism_swap___redArg(v___x_51_);
return v___x_52_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Polymorphism_swapped(void){
_start:
{
lean_object* v___x_53_; 
v___x_53_ = lean_obj_once(&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Polymorphism_swapped___closed__0, &lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Polymorphism_swapped___closed__0_once, _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Polymorphism_swapped___closed__0);
return v___x_53_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Polymorphism_triple(lean_object* v_x_54_){
_start:
{
lean_object* v___x_55_; lean_object* v___x_56_; 
v___x_55_ = lean_nat_add(v_x_54_, v_x_54_);
v___x_56_ = lean_nat_add(v___x_55_, v_x_54_);
lean_dec(v___x_55_);
return v___x_56_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Polymorphism_triple___boxed(lean_object* v_x_57_){
_start:
{
lean_object* v_res_58_; 
v_res_58_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Polymorphism_triple(v_x_57_);
lean_dec(v_x_57_);
return v_res_58_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Polymorphism_greet(lean_object* v_name_60_){
_start:
{
lean_object* v___x_61_; lean_object* v___x_62_; 
v___x_61_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Polymorphism_greet___closed__0));
v___x_62_ = lean_string_append(v___x_61_, v_name_60_);
return v___x_62_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Polymorphism_greet___boxed(lean_object* v_name_63_){
_start:
{
lean_object* v_res_64_; 
v_res_64_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Polymorphism_greet(v_name_63_);
lean_dec_ref(v_name_63_);
return v_res_64_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Polymorphism_first___redArg(lean_object* v_p_65_){
_start:
{
lean_object* v_fst_66_; 
v_fst_66_ = lean_ctor_get(v_p_65_, 0);
lean_inc(v_fst_66_);
return v_fst_66_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Polymorphism_first___redArg___boxed(lean_object* v_p_67_){
_start:
{
lean_object* v_res_68_; 
v_res_68_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Polymorphism_first___redArg(v_p_67_);
lean_dec_ref(v_p_67_);
return v_res_68_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Polymorphism_first(lean_object* v_00_u03b1_69_, lean_object* v_00_u03b2_70_, lean_object* v_p_71_){
_start:
{
lean_object* v_fst_72_; 
v_fst_72_ = lean_ctor_get(v_p_71_, 0);
lean_inc(v_fst_72_);
return v_fst_72_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Polymorphism_first___boxed(lean_object* v_00_u03b1_73_, lean_object* v_00_u03b2_74_, lean_object* v_p_75_){
_start:
{
lean_object* v_res_76_; 
v_res_76_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Polymorphism_first(v_00_u03b1_73_, v_00_u03b2_74_, v_p_75_);
lean_dec_ref(v_p_75_);
return v_res_76_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Polymorphism_second___redArg(lean_object* v_p_77_){
_start:
{
lean_object* v_snd_78_; 
v_snd_78_ = lean_ctor_get(v_p_77_, 1);
lean_inc(v_snd_78_);
return v_snd_78_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Polymorphism_second___redArg___boxed(lean_object* v_p_79_){
_start:
{
lean_object* v_res_80_; 
v_res_80_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Polymorphism_second___redArg(v_p_79_);
lean_dec_ref(v_p_79_);
return v_res_80_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Polymorphism_second(lean_object* v_00_u03b1_81_, lean_object* v_00_u03b2_82_, lean_object* v_p_83_){
_start:
{
lean_object* v_snd_84_; 
v_snd_84_ = lean_ctor_get(v_p_83_, 1);
lean_inc(v_snd_84_);
return v_snd_84_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Polymorphism_second___boxed(lean_object* v_00_u03b1_85_, lean_object* v_00_u03b2_86_, lean_object* v_p_87_){
_start:
{
lean_object* v_res_88_; 
v_res_88_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Polymorphism_second(v_00_u03b1_85_, v_00_u03b2_86_, v_p_87_);
lean_dec_ref(v_p_87_);
return v_res_88_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Polymorphism_fst__val(void){
_start:
{
lean_object* v___x_89_; 
v___x_89_ = lean_unsigned_to_nat(3u);
return v___x_89_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Polymorphism_implicit__id___redArg(lean_object* v_x_91_){
_start:
{
lean_inc(v_x_91_);
return v_x_91_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Polymorphism_implicit__id___redArg___boxed(lean_object* v_x_92_){
_start:
{
lean_object* v_res_93_; 
v_res_93_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Polymorphism_implicit__id___redArg(v_x_92_);
lean_dec(v_x_92_);
return v_res_93_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Polymorphism_implicit__id(lean_object* v_00_u03b1_94_, lean_object* v_x_95_){
_start:
{
lean_inc(v_x_95_);
return v_x_95_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Polymorphism_implicit__id___boxed(lean_object* v_00_u03b1_96_, lean_object* v_x_97_){
_start:
{
lean_object* v_res_98_; 
v_res_98_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Polymorphism_implicit__id(v_00_u03b1_96_, v_x_97_);
lean_dec(v_x_97_);
return v_res_98_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Polymorphism_explicit__id___redArg(lean_object* v_x_99_){
_start:
{
lean_inc(v_x_99_);
return v_x_99_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Polymorphism_explicit__id___redArg___boxed(lean_object* v_x_100_){
_start:
{
lean_object* v_res_101_; 
v_res_101_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Polymorphism_explicit__id___redArg(v_x_100_);
lean_dec(v_x_100_);
return v_res_101_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Polymorphism_explicit__id(lean_object* v_00_u03b1_102_, lean_object* v_x_103_){
_start:
{
lean_inc(v_x_103_);
return v_x_103_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Polymorphism_explicit__id___boxed(lean_object* v_00_u03b1_104_, lean_object* v_x_105_){
_start:
{
lean_object* v_res_106_; 
v_res_106_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Polymorphism_explicit__id(v_00_u03b1_104_, v_x_105_);
lean_dec(v_x_105_);
return v_res_106_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Polymorphism_imp1(void){
_start:
{
lean_object* v___x_107_; 
v___x_107_ = lean_unsigned_to_nat(42u);
return v___x_107_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Polymorphism_exp1(void){
_start:
{
lean_object* v___x_108_; 
v___x_108_ = lean_unsigned_to_nat(42u);
return v___x_108_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Polymorphism_exp2(void){
_start:
{
lean_object* v___x_109_; 
v___x_109_ = lean_unsigned_to_nat(42u);
return v___x_109_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Polymorphism_x__coord(void){
_start:
{
lean_object* v___x_119_; lean_object* v_fst_120_; 
v___x_119_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Polymorphism_point2d));
v_fst_120_ = lean_ctor_get(v___x_119_, 0);
lean_inc(v_fst_120_);
return v_fst_120_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Polymorphism_y__coord(void){
_start:
{
lean_object* v___x_121_; lean_object* v_snd_122_; 
v___x_121_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Polymorphism_point2d));
v_snd_122_ = lean_ctor_get(v___x_121_, 1);
lean_inc(v_snd_122_);
return v_snd_122_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Polymorphism_person__name(void){
_start:
{
lean_object* v___x_123_; lean_object* v_fst_124_; 
v___x_123_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Polymorphism_name__age));
v_fst_124_ = lean_ctor_get(v___x_123_, 0);
lean_inc(v_fst_124_);
return v_fst_124_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Polymorphism_person__age(void){
_start:
{
lean_object* v___x_125_; lean_object* v_snd_126_; 
v___x_125_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Polymorphism_name__age));
v_snd_126_ = lean_ctor_get(v___x_125_, 1);
lean_inc(v_snd_126_);
return v_snd_126_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Polymorphism_fst__example(void){
_start:
{
lean_object* v___x_127_; lean_object* v_fst_128_; 
v___x_127_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Polymorphism_point2d));
v_fst_128_ = lean_ctor_get(v___x_127_, 0);
lean_inc(v_fst_128_);
return v_fst_128_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Polymorphism_snd__example(void){
_start:
{
lean_object* v___x_129_; lean_object* v_snd_130_; 
v___x_129_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Polymorphism_point2d));
v_snd_130_ = lean_ctor_get(v___x_129_, 1);
lean_inc(v_snd_130_);
return v_snd_130_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Polymorphism_tri__fst(void){
_start:
{
lean_object* v___x_139_; lean_object* v_fst_140_; 
v___x_139_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Polymorphism_triple__val));
v_fst_140_ = lean_ctor_get(v___x_139_, 0);
lean_inc(v_fst_140_);
return v_fst_140_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Polymorphism_tri__snd(void){
_start:
{
lean_object* v___x_141_; lean_object* v_snd_142_; lean_object* v_fst_143_; 
v___x_141_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Polymorphism_triple__val));
v_snd_142_ = lean_ctor_get(v___x_141_, 1);
v_fst_143_ = lean_ctor_get(v_snd_142_, 0);
lean_inc(v_fst_143_);
return v_fst_143_;
}
}
static uint8_t _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Polymorphism_tri__thr(void){
_start:
{
uint8_t v___x_144_; 
v___x_144_ = 1;
return v___x_144_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Polymorphism_mapFirst___redArg(lean_object* v_f_158_, lean_object* v_p_159_){
_start:
{
lean_object* v_fst_160_; lean_object* v_snd_161_; lean_object* v___x_163_; uint8_t v_isShared_164_; uint8_t v_isSharedCheck_169_; 
v_fst_160_ = lean_ctor_get(v_p_159_, 0);
v_snd_161_ = lean_ctor_get(v_p_159_, 1);
v_isSharedCheck_169_ = !lean_is_exclusive(v_p_159_);
if (v_isSharedCheck_169_ == 0)
{
v___x_163_ = v_p_159_;
v_isShared_164_ = v_isSharedCheck_169_;
goto v_resetjp_162_;
}
else
{
lean_inc(v_snd_161_);
lean_inc(v_fst_160_);
lean_dec(v_p_159_);
v___x_163_ = lean_box(0);
v_isShared_164_ = v_isSharedCheck_169_;
goto v_resetjp_162_;
}
v_resetjp_162_:
{
lean_object* v___x_165_; lean_object* v___x_167_; 
v___x_165_ = lean_apply_1(v_f_158_, v_fst_160_);
if (v_isShared_164_ == 0)
{
lean_ctor_set(v___x_163_, 0, v___x_165_);
v___x_167_ = v___x_163_;
goto v_reusejp_166_;
}
else
{
lean_object* v_reuseFailAlloc_168_; 
v_reuseFailAlloc_168_ = lean_alloc_ctor(0, 2, 0);
lean_ctor_set(v_reuseFailAlloc_168_, 0, v___x_165_);
lean_ctor_set(v_reuseFailAlloc_168_, 1, v_snd_161_);
v___x_167_ = v_reuseFailAlloc_168_;
goto v_reusejp_166_;
}
v_reusejp_166_:
{
return v___x_167_;
}
}
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Polymorphism_mapFirst(lean_object* v_00_u03b1_170_, lean_object* v_00_u03b2_171_, lean_object* v_00_u03b3_172_, lean_object* v_f_173_, lean_object* v_p_174_){
_start:
{
lean_object* v___x_175_; 
v___x_175_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Polymorphism_mapFirst___redArg(v_f_173_, v_p_174_);
return v___x_175_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Polymorphism_mapSecond___redArg(lean_object* v_f_176_, lean_object* v_p_177_){
_start:
{
lean_object* v_fst_178_; lean_object* v_snd_179_; lean_object* v___x_181_; uint8_t v_isShared_182_; uint8_t v_isSharedCheck_187_; 
v_fst_178_ = lean_ctor_get(v_p_177_, 0);
v_snd_179_ = lean_ctor_get(v_p_177_, 1);
v_isSharedCheck_187_ = !lean_is_exclusive(v_p_177_);
if (v_isSharedCheck_187_ == 0)
{
v___x_181_ = v_p_177_;
v_isShared_182_ = v_isSharedCheck_187_;
goto v_resetjp_180_;
}
else
{
lean_inc(v_snd_179_);
lean_inc(v_fst_178_);
lean_dec(v_p_177_);
v___x_181_ = lean_box(0);
v_isShared_182_ = v_isSharedCheck_187_;
goto v_resetjp_180_;
}
v_resetjp_180_:
{
lean_object* v___x_183_; lean_object* v___x_185_; 
v___x_183_ = lean_apply_1(v_f_176_, v_snd_179_);
if (v_isShared_182_ == 0)
{
lean_ctor_set(v___x_181_, 1, v___x_183_);
v___x_185_ = v___x_181_;
goto v_reusejp_184_;
}
else
{
lean_object* v_reuseFailAlloc_186_; 
v_reuseFailAlloc_186_ = lean_alloc_ctor(0, 2, 0);
lean_ctor_set(v_reuseFailAlloc_186_, 0, v_fst_178_);
lean_ctor_set(v_reuseFailAlloc_186_, 1, v___x_183_);
v___x_185_ = v_reuseFailAlloc_186_;
goto v_reusejp_184_;
}
v_reusejp_184_:
{
return v___x_185_;
}
}
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Polymorphism_mapSecond(lean_object* v_00_u03b1_188_, lean_object* v_00_u03b2_189_, lean_object* v_00_u03b3_190_, lean_object* v_f_191_, lean_object* v_p_192_){
_start:
{
lean_object* v___x_193_; 
v___x_193_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Polymorphism_mapSecond___redArg(v_f_191_, v_p_192_);
return v___x_193_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Polymorphism_map__first__result___lam__0(lean_object* v_x_194_){
_start:
{
lean_object* v___x_195_; lean_object* v___x_196_; 
v___x_195_ = lean_unsigned_to_nat(2u);
v___x_196_ = lean_nat_mul(v_x_194_, v___x_195_);
return v___x_196_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Polymorphism_map__first__result___lam__0___boxed(lean_object* v_x_197_){
_start:
{
lean_object* v_res_198_; 
v_res_198_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Polymorphism_map__first__result___lam__0(v_x_197_);
lean_dec(v_x_197_);
return v_res_198_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Polymorphism_map__first__result___closed__2(void){
_start:
{
lean_object* v___x_203_; lean_object* v___f_204_; lean_object* v___x_205_; 
v___x_203_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Polymorphism_map__first__result___closed__1));
v___f_204_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Polymorphism_map__first__result___closed__0));
v___x_205_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Polymorphism_mapFirst___redArg(v___f_204_, v___x_203_);
return v___x_205_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Polymorphism_map__first__result(void){
_start:
{
lean_object* v___x_206_; 
v___x_206_ = lean_obj_once(&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Polymorphism_map__first__result___closed__2, &lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Polymorphism_map__first__result___closed__2_once, _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Polymorphism_map__first__result___closed__2);
return v___x_206_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Polymorphism_map__second__result___closed__1(void){
_start:
{
lean_object* v___x_208_; lean_object* v___x_209_; lean_object* v___x_210_; 
v___x_208_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Polymorphism_map__first__result___closed__1));
v___x_209_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Polymorphism_map__second__result___closed__0));
v___x_210_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Polymorphism_mapSecond___redArg(v___x_209_, v___x_208_);
return v___x_210_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Polymorphism_map__second__result(void){
_start:
{
lean_object* v___x_211_; 
v___x_211_ = lean_obj_once(&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Polymorphism_map__second__result___closed__1, &lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Polymorphism_map__second__result___closed__1_once, _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Polymorphism_map__second__result___closed__1);
return v___x_211_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Polymorphism_zipWith___redArg(lean_object* v_f_212_, lean_object* v_p1_213_, lean_object* v_p2_214_){
_start:
{
lean_object* v_fst_215_; lean_object* v_snd_216_; lean_object* v_fst_217_; lean_object* v_snd_218_; lean_object* v___x_220_; uint8_t v_isShared_221_; uint8_t v_isSharedCheck_227_; 
v_fst_215_ = lean_ctor_get(v_p1_213_, 0);
lean_inc(v_fst_215_);
v_snd_216_ = lean_ctor_get(v_p1_213_, 1);
lean_inc(v_snd_216_);
lean_dec_ref(v_p1_213_);
v_fst_217_ = lean_ctor_get(v_p2_214_, 0);
v_snd_218_ = lean_ctor_get(v_p2_214_, 1);
v_isSharedCheck_227_ = !lean_is_exclusive(v_p2_214_);
if (v_isSharedCheck_227_ == 0)
{
v___x_220_ = v_p2_214_;
v_isShared_221_ = v_isSharedCheck_227_;
goto v_resetjp_219_;
}
else
{
lean_inc(v_snd_218_);
lean_inc(v_fst_217_);
lean_dec(v_p2_214_);
v___x_220_ = lean_box(0);
v_isShared_221_ = v_isSharedCheck_227_;
goto v_resetjp_219_;
}
v_resetjp_219_:
{
lean_object* v___x_222_; lean_object* v___x_223_; lean_object* v___x_225_; 
lean_inc(v_f_212_);
v___x_222_ = lean_apply_2(v_f_212_, v_fst_215_, v_fst_217_);
v___x_223_ = lean_apply_2(v_f_212_, v_snd_216_, v_snd_218_);
if (v_isShared_221_ == 0)
{
lean_ctor_set(v___x_220_, 1, v___x_223_);
lean_ctor_set(v___x_220_, 0, v___x_222_);
v___x_225_ = v___x_220_;
goto v_reusejp_224_;
}
else
{
lean_object* v_reuseFailAlloc_226_; 
v_reuseFailAlloc_226_ = lean_alloc_ctor(0, 2, 0);
lean_ctor_set(v_reuseFailAlloc_226_, 0, v___x_222_);
lean_ctor_set(v_reuseFailAlloc_226_, 1, v___x_223_);
v___x_225_ = v_reuseFailAlloc_226_;
goto v_reusejp_224_;
}
v_reusejp_224_:
{
return v___x_225_;
}
}
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Polymorphism_zipWith(lean_object* v_00_u03b1_228_, lean_object* v_00_u03b2_229_, lean_object* v_00_u03b3_230_, lean_object* v_f_231_, lean_object* v_p1_232_, lean_object* v_p2_233_){
_start:
{
lean_object* v___x_234_; 
v___x_234_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Polymorphism_zipWith___redArg(v_f_231_, v_p1_232_, v_p2_233_);
return v___x_234_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Polymorphism_add__points___closed__1(void){
_start:
{
lean_object* v___x_236_; lean_object* v___x_237_; lean_object* v___f_238_; lean_object* v___x_239_; 
v___x_236_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Polymorphism_point2d___closed__0));
v___x_237_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Polymorphism_nested___closed__0));
v___f_238_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Polymorphism_add__points___closed__0));
v___x_239_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Polymorphism_zipWith___redArg(v___f_238_, v___x_237_, v___x_236_);
return v___x_239_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Polymorphism_add__points(void){
_start:
{
lean_object* v___x_240_; 
v___x_240_ = lean_obj_once(&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Polymorphism_add__points___closed__1, &lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Polymorphism_add__points___closed__1_once, _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Polymorphism_add__points___closed__1);
return v___x_240_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Polymorphism_unit__val(void){
_start:
{
lean_object* v___x_241_; 
v___x_241_ = lean_box(0);
return v___x_241_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Polymorphism_boxed__int(void){
_start:
{
lean_object* v___x_246_; 
v___x_246_ = lean_unsigned_to_nat(42u);
return v___x_246_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Polymorphism_unbox___redArg(lean_object* v_b_248_){
_start:
{
lean_inc(v_b_248_);
return v_b_248_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Polymorphism_unbox___redArg___boxed(lean_object* v_b_249_){
_start:
{
lean_object* v_res_250_; 
v_res_250_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Polymorphism_unbox___redArg(v_b_249_);
lean_dec(v_b_249_);
return v_res_250_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Polymorphism_unbox(lean_object* v_00_u03b1_251_, lean_object* v_b_252_){
_start:
{
lean_inc(v_b_252_);
return v_b_252_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Polymorphism_unbox___boxed(lean_object* v_00_u03b1_253_, lean_object* v_b_254_){
_start:
{
lean_object* v_res_255_; 
v_res_255_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Polymorphism_unbox(v_00_u03b1_253_, v_b_254_);
lean_dec(v_b_254_);
return v_res_255_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Polymorphism_unboxed__nat(void){
_start:
{
lean_object* v_content_256_; 
v_content_256_ = lean_unsigned_to_nat(42u);
return v_content_256_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Polymorphism_mapBox___redArg(lean_object* v_f_258_, lean_object* v_b_259_){
_start:
{
lean_object* v___x_260_; 
v___x_260_ = lean_apply_1(v_f_258_, v_b_259_);
return v___x_260_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Polymorphism_mapBox(lean_object* v_00_u03b1_261_, lean_object* v_00_u03b2_262_, lean_object* v_f_263_, lean_object* v_b_264_){
_start:
{
lean_object* v___x_265_; 
v___x_265_ = lean_apply_1(v_f_263_, v_b_264_);
return v___x_265_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Polymorphism_mapped__box(void){
_start:
{
lean_object* v___x_266_; 
v___x_266_ = lean_unsigned_to_nat(84u);
return v___x_266_;
}
}
lean_object* initialize_Init(uint8_t builtin);
lean_object* initialize_Init(uint8_t builtin);
static bool _G_initialized = false;
LEAN_EXPORT lean_object* initialize_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Polymorphism(uint8_t builtin) {
lean_object * res;
if (_G_initialized) return lean_io_result_mk_ok(lean_box(0));
_G_initialized = true;
res = initialize_Init(builtin);
if (lean_io_result_is_error(res)) return res;
lean_dec_ref(res);
res = initialize_Init(builtin);
if (lean_io_result_is_error(res)) return res;
lean_dec_ref(res);
lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Polymorphism_id__nat = _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Polymorphism_id__nat();
lean_mark_persistent(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Polymorphism_id__nat);
lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Polymorphism_id__bool = _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Polymorphism_id__bool();
lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Polymorphism_id__explicit = _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Polymorphism_id__explicit();
lean_mark_persistent(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Polymorphism_id__explicit);
lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Polymorphism_id__with__type = _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Polymorphism_id__with__type();
lean_mark_persistent(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Polymorphism_id__with__type);
lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Polymorphism_bool__int__pair = _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Polymorphism_bool__int__pair();
lean_mark_persistent(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Polymorphism_bool__int__pair);
lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Polymorphism_swapped = _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Polymorphism_swapped();
lean_mark_persistent(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Polymorphism_swapped);
lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Polymorphism_fst__val = _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Polymorphism_fst__val();
lean_mark_persistent(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Polymorphism_fst__val);
lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Polymorphism_imp1 = _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Polymorphism_imp1();
lean_mark_persistent(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Polymorphism_imp1);
lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Polymorphism_exp1 = _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Polymorphism_exp1();
lean_mark_persistent(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Polymorphism_exp1);
lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Polymorphism_exp2 = _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Polymorphism_exp2();
lean_mark_persistent(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Polymorphism_exp2);
lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Polymorphism_x__coord = _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Polymorphism_x__coord();
lean_mark_persistent(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Polymorphism_x__coord);
lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Polymorphism_y__coord = _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Polymorphism_y__coord();
lean_mark_persistent(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Polymorphism_y__coord);
lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Polymorphism_person__name = _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Polymorphism_person__name();
lean_mark_persistent(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Polymorphism_person__name);
lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Polymorphism_person__age = _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Polymorphism_person__age();
lean_mark_persistent(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Polymorphism_person__age);
lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Polymorphism_fst__example = _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Polymorphism_fst__example();
lean_mark_persistent(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Polymorphism_fst__example);
lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Polymorphism_snd__example = _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Polymorphism_snd__example();
lean_mark_persistent(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Polymorphism_snd__example);
lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Polymorphism_tri__fst = _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Polymorphism_tri__fst();
lean_mark_persistent(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Polymorphism_tri__fst);
lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Polymorphism_tri__snd = _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Polymorphism_tri__snd();
lean_mark_persistent(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Polymorphism_tri__snd);
lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Polymorphism_tri__thr = _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Polymorphism_tri__thr();
lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Polymorphism_map__first__result = _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Polymorphism_map__first__result();
lean_mark_persistent(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Polymorphism_map__first__result);
lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Polymorphism_map__second__result = _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Polymorphism_map__second__result();
lean_mark_persistent(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Polymorphism_map__second__result);
lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Polymorphism_add__points = _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Polymorphism_add__points();
lean_mark_persistent(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Polymorphism_add__points);
lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Polymorphism_unit__val = _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Polymorphism_unit__val();
lean_mark_persistent(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Polymorphism_unit__val);
lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Polymorphism_boxed__int = _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Polymorphism_boxed__int();
lean_mark_persistent(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Polymorphism_boxed__int);
lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Polymorphism_unboxed__nat = _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Polymorphism_unboxed__nat();
lean_mark_persistent(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Polymorphism_unboxed__nat);
lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Polymorphism_mapped__box = _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Polymorphism_mapped__box();
lean_mark_persistent(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Basics_Polymorphism_mapped__box);
return lean_io_result_mk_ok(lean_box(0));
}
#ifdef __cplusplus
}
#endif
