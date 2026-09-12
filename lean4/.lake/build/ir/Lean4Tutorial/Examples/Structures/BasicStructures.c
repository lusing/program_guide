// Lean compiler output
// Module: Lean4Tutorial.Examples.Structures.BasicStructures
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
lean_object* l_String_quote(lean_object*);
lean_object* l_Nat_reprFast(lean_object*);
lean_object* lean_string_length(lean_object*);
double l_Float_ofScientific(lean_object*, uint8_t, lean_object*);
lean_object* lean_string_append(lean_object*, lean_object*);
lean_object* lean_nat_add(lean_object*, lean_object*);
uint8_t lean_nat_dec_eq(lean_object*, lean_object*);
uint8_t lean_nat_dec_le(lean_object*, lean_object*);
uint8_t lean_string_dec_eq(lean_object*, lean_object*);
lean_object* l_Float_repr(double, lean_object*);
static const lean_string_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_instReprPerson_repr___redArg___closed__0_value = {.m_header = {.m_rc = 0, .m_cs_sz = 0, .m_other = 0, .m_tag = 249}, .m_size = 3, .m_capacity = 3, .m_length = 2, .m_data = "{ "};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_instReprPerson_repr___redArg___closed__0 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_instReprPerson_repr___redArg___closed__0_value;
static const lean_string_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_instReprPerson_repr___redArg___closed__1_value = {.m_header = {.m_rc = 0, .m_cs_sz = 0, .m_other = 0, .m_tag = 249}, .m_size = 5, .m_capacity = 5, .m_length = 4, .m_data = "name"};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_instReprPerson_repr___redArg___closed__1 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_instReprPerson_repr___redArg___closed__1_value;
static const lean_ctor_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_instReprPerson_repr___redArg___closed__2_value = {.m_header = {.m_rc = 0, .m_cs_sz = sizeof(lean_ctor_object) + sizeof(void*)*1 + 0, .m_other = 1, .m_tag = 3}, .m_objs = {((lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_instReprPerson_repr___redArg___closed__1_value)}};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_instReprPerson_repr___redArg___closed__2 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_instReprPerson_repr___redArg___closed__2_value;
static const lean_ctor_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_instReprPerson_repr___redArg___closed__3_value = {.m_header = {.m_rc = 0, .m_cs_sz = sizeof(lean_ctor_object) + sizeof(void*)*2 + 0, .m_other = 2, .m_tag = 5}, .m_objs = {((lean_object*)(((size_t)(0) << 1) | 1)),((lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_instReprPerson_repr___redArg___closed__2_value)}};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_instReprPerson_repr___redArg___closed__3 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_instReprPerson_repr___redArg___closed__3_value;
static const lean_string_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_instReprPerson_repr___redArg___closed__4_value = {.m_header = {.m_rc = 0, .m_cs_sz = 0, .m_other = 0, .m_tag = 249}, .m_size = 5, .m_capacity = 5, .m_length = 4, .m_data = " := "};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_instReprPerson_repr___redArg___closed__4 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_instReprPerson_repr___redArg___closed__4_value;
static const lean_ctor_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_instReprPerson_repr___redArg___closed__5_value = {.m_header = {.m_rc = 0, .m_cs_sz = sizeof(lean_ctor_object) + sizeof(void*)*1 + 0, .m_other = 1, .m_tag = 3}, .m_objs = {((lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_instReprPerson_repr___redArg___closed__4_value)}};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_instReprPerson_repr___redArg___closed__5 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_instReprPerson_repr___redArg___closed__5_value;
static const lean_ctor_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_instReprPerson_repr___redArg___closed__6_value = {.m_header = {.m_rc = 0, .m_cs_sz = sizeof(lean_ctor_object) + sizeof(void*)*2 + 0, .m_other = 2, .m_tag = 5}, .m_objs = {((lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_instReprPerson_repr___redArg___closed__3_value),((lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_instReprPerson_repr___redArg___closed__5_value)}};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_instReprPerson_repr___redArg___closed__6 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_instReprPerson_repr___redArg___closed__6_value;
static lean_once_cell_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_instReprPerson_repr___redArg___closed__7_once = LEAN_ONCE_CELL_INITIALIZER;
static lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_instReprPerson_repr___redArg___closed__7;
static const lean_string_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_instReprPerson_repr___redArg___closed__8_value = {.m_header = {.m_rc = 0, .m_cs_sz = 0, .m_other = 0, .m_tag = 249}, .m_size = 2, .m_capacity = 2, .m_length = 1, .m_data = ","};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_instReprPerson_repr___redArg___closed__8 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_instReprPerson_repr___redArg___closed__8_value;
static const lean_ctor_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_instReprPerson_repr___redArg___closed__9_value = {.m_header = {.m_rc = 0, .m_cs_sz = sizeof(lean_ctor_object) + sizeof(void*)*1 + 0, .m_other = 1, .m_tag = 3}, .m_objs = {((lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_instReprPerson_repr___redArg___closed__8_value)}};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_instReprPerson_repr___redArg___closed__9 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_instReprPerson_repr___redArg___closed__9_value;
static const lean_string_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_instReprPerson_repr___redArg___closed__10_value = {.m_header = {.m_rc = 0, .m_cs_sz = 0, .m_other = 0, .m_tag = 249}, .m_size = 4, .m_capacity = 4, .m_length = 3, .m_data = "age"};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_instReprPerson_repr___redArg___closed__10 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_instReprPerson_repr___redArg___closed__10_value;
static const lean_ctor_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_instReprPerson_repr___redArg___closed__11_value = {.m_header = {.m_rc = 0, .m_cs_sz = sizeof(lean_ctor_object) + sizeof(void*)*1 + 0, .m_other = 1, .m_tag = 3}, .m_objs = {((lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_instReprPerson_repr___redArg___closed__10_value)}};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_instReprPerson_repr___redArg___closed__11 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_instReprPerson_repr___redArg___closed__11_value;
static lean_once_cell_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_instReprPerson_repr___redArg___closed__12_once = LEAN_ONCE_CELL_INITIALIZER;
static lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_instReprPerson_repr___redArg___closed__12;
static const lean_string_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_instReprPerson_repr___redArg___closed__13_value = {.m_header = {.m_rc = 0, .m_cs_sz = 0, .m_other = 0, .m_tag = 249}, .m_size = 3, .m_capacity = 3, .m_length = 2, .m_data = " }"};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_instReprPerson_repr___redArg___closed__13 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_instReprPerson_repr___redArg___closed__13_value;
static lean_once_cell_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_instReprPerson_repr___redArg___closed__14_once = LEAN_ONCE_CELL_INITIALIZER;
static lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_instReprPerson_repr___redArg___closed__14;
static lean_once_cell_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_instReprPerson_repr___redArg___closed__15_once = LEAN_ONCE_CELL_INITIALIZER;
static lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_instReprPerson_repr___redArg___closed__15;
static const lean_ctor_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_instReprPerson_repr___redArg___closed__16_value = {.m_header = {.m_rc = 0, .m_cs_sz = sizeof(lean_ctor_object) + sizeof(void*)*1 + 0, .m_other = 1, .m_tag = 3}, .m_objs = {((lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_instReprPerson_repr___redArg___closed__0_value)}};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_instReprPerson_repr___redArg___closed__16 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_instReprPerson_repr___redArg___closed__16_value;
static const lean_ctor_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_instReprPerson_repr___redArg___closed__17_value = {.m_header = {.m_rc = 0, .m_cs_sz = sizeof(lean_ctor_object) + sizeof(void*)*1 + 0, .m_other = 1, .m_tag = 3}, .m_objs = {((lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_instReprPerson_repr___redArg___closed__13_value)}};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_instReprPerson_repr___redArg___closed__17 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_instReprPerson_repr___redArg___closed__17_value;
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_instReprPerson_repr___redArg(lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_instReprPerson_repr(lean_object*, lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_instReprPerson_repr___boxed(lean_object*, lean_object*);
static const lean_closure_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_instReprPerson___closed__0_value = {.m_header = {.m_rc = 0, .m_cs_sz = sizeof(lean_closure_object) + sizeof(void*)*0, .m_other = 0, .m_tag = 245}, .m_fun = (void*)lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_instReprPerson_repr___boxed, .m_arity = 2, .m_num_fixed = 0, .m_objs = {} };
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_instReprPerson___closed__0 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_instReprPerson___closed__0_value;
LEAN_EXPORT const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_instReprPerson = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_instReprPerson___closed__0_value;
LEAN_EXPORT uint8_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_instDecidableEqPerson_decEq(lean_object*, lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_instDecidableEqPerson_decEq___boxed(lean_object*, lean_object*);
LEAN_EXPORT uint8_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_instDecidableEqPerson(lean_object*, lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_instDecidableEqPerson___boxed(lean_object*, lean_object*);
static const lean_string_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_alice___closed__0_value = {.m_header = {.m_rc = 0, .m_cs_sz = 0, .m_other = 0, .m_tag = 249}, .m_size = 6, .m_capacity = 6, .m_length = 5, .m_data = "Alice"};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_alice___closed__0 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_alice___closed__0_value;
static const lean_ctor_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_alice___closed__1_value = {.m_header = {.m_rc = 0, .m_cs_sz = sizeof(lean_ctor_object) + sizeof(void*)*2 + 0, .m_other = 2, .m_tag = 0}, .m_objs = {((lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_alice___closed__0_value),((lean_object*)(((size_t)(30) << 1) | 1))}};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_alice___closed__1 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_alice___closed__1_value;
LEAN_EXPORT const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_alice = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_alice___closed__1_value;
static const lean_string_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_bob___closed__0_value = {.m_header = {.m_rc = 0, .m_cs_sz = 0, .m_other = 0, .m_tag = 249}, .m_size = 4, .m_capacity = 4, .m_length = 3, .m_data = "Bob"};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_bob___closed__0 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_bob___closed__0_value;
static const lean_ctor_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_bob___closed__1_value = {.m_header = {.m_rc = 0, .m_cs_sz = sizeof(lean_ctor_object) + sizeof(void*)*2 + 0, .m_other = 2, .m_tag = 0}, .m_objs = {((lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_bob___closed__0_value),((lean_object*)(((size_t)(25) << 1) | 1))}};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_bob___closed__1 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_bob___closed__1_value;
LEAN_EXPORT const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_bob = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_bob___closed__1_value;
static const lean_string_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_charlie___closed__0_value = {.m_header = {.m_rc = 0, .m_cs_sz = 0, .m_other = 0, .m_tag = 249}, .m_size = 8, .m_capacity = 8, .m_length = 7, .m_data = "Charlie"};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_charlie___closed__0 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_charlie___closed__0_value;
static const lean_ctor_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_charlie___closed__1_value = {.m_header = {.m_rc = 0, .m_cs_sz = sizeof(lean_ctor_object) + sizeof(void*)*2 + 0, .m_other = 2, .m_tag = 0}, .m_objs = {((lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_charlie___closed__0_value),((lean_object*)(((size_t)(35) << 1) | 1))}};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_charlie___closed__1 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_charlie___closed__1_value;
LEAN_EXPORT const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_charlie = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_charlie___closed__1_value;
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_alice__name;
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_alice__age;
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_bob__name;
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_bob__age;
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_birthday(lean_object*);
static lean_once_cell_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_alice__next__year___closed__0_once = LEAN_ONCE_CELL_INITIALIZER;
static lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_alice__next__year___closed__0;
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_alice__next__year;
static const lean_string_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_greet___closed__0_value = {.m_header = {.m_rc = 0, .m_cs_sz = 0, .m_other = 0, .m_tag = 249}, .m_size = 19, .m_capacity = 19, .m_length = 18, .m_data = "Hello, my name is "};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_greet___closed__0 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_greet___closed__0_value;
static const lean_string_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_greet___closed__1_value = {.m_header = {.m_rc = 0, .m_cs_sz = 0, .m_other = 0, .m_tag = 249}, .m_size = 11, .m_capacity = 11, .m_length = 10, .m_data = " and I am "};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_greet___closed__1 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_greet___closed__1_value;
static const lean_string_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_greet___closed__2_value = {.m_header = {.m_rc = 0, .m_cs_sz = 0, .m_other = 0, .m_tag = 249}, .m_size = 12, .m_capacity = 12, .m_length = 11, .m_data = " years old."};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_greet___closed__2 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_greet___closed__2_value;
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_greet(lean_object*);
static lean_once_cell_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_alice__greet___closed__0_once = LEAN_ONCE_CELL_INITIALIZER;
static lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_alice__greet___closed__0;
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_alice__greet;
LEAN_EXPORT uint8_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_isAdult(lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_isAdult___boxed(lean_object*);
static lean_once_cell_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_alice__adult___closed__0_once = LEAN_ONCE_CELL_INITIALIZER;
static uint8_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_alice__adult___closed__0;
LEAN_EXPORT uint8_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_alice__adult;
static const lean_string_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_instReprPoint_repr___redArg___closed__0_value = {.m_header = {.m_rc = 0, .m_cs_sz = 0, .m_other = 0, .m_tag = 249}, .m_size = 2, .m_capacity = 2, .m_length = 1, .m_data = "x"};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_instReprPoint_repr___redArg___closed__0 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_instReprPoint_repr___redArg___closed__0_value;
static const lean_ctor_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_instReprPoint_repr___redArg___closed__1_value = {.m_header = {.m_rc = 0, .m_cs_sz = sizeof(lean_ctor_object) + sizeof(void*)*1 + 0, .m_other = 1, .m_tag = 3}, .m_objs = {((lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_instReprPoint_repr___redArg___closed__0_value)}};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_instReprPoint_repr___redArg___closed__1 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_instReprPoint_repr___redArg___closed__1_value;
static const lean_ctor_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_instReprPoint_repr___redArg___closed__2_value = {.m_header = {.m_rc = 0, .m_cs_sz = sizeof(lean_ctor_object) + sizeof(void*)*2 + 0, .m_other = 2, .m_tag = 5}, .m_objs = {((lean_object*)(((size_t)(0) << 1) | 1)),((lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_instReprPoint_repr___redArg___closed__1_value)}};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_instReprPoint_repr___redArg___closed__2 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_instReprPoint_repr___redArg___closed__2_value;
static const lean_ctor_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_instReprPoint_repr___redArg___closed__3_value = {.m_header = {.m_rc = 0, .m_cs_sz = sizeof(lean_ctor_object) + sizeof(void*)*2 + 0, .m_other = 2, .m_tag = 5}, .m_objs = {((lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_instReprPoint_repr___redArg___closed__2_value),((lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_instReprPerson_repr___redArg___closed__5_value)}};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_instReprPoint_repr___redArg___closed__3 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_instReprPoint_repr___redArg___closed__3_value;
static lean_once_cell_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_instReprPoint_repr___redArg___closed__4_once = LEAN_ONCE_CELL_INITIALIZER;
static lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_instReprPoint_repr___redArg___closed__4;
static const lean_string_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_instReprPoint_repr___redArg___closed__5_value = {.m_header = {.m_rc = 0, .m_cs_sz = 0, .m_other = 0, .m_tag = 249}, .m_size = 2, .m_capacity = 2, .m_length = 1, .m_data = "y"};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_instReprPoint_repr___redArg___closed__5 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_instReprPoint_repr___redArg___closed__5_value;
static const lean_ctor_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_instReprPoint_repr___redArg___closed__6_value = {.m_header = {.m_rc = 0, .m_cs_sz = sizeof(lean_ctor_object) + sizeof(void*)*1 + 0, .m_other = 1, .m_tag = 3}, .m_objs = {((lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_instReprPoint_repr___redArg___closed__5_value)}};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_instReprPoint_repr___redArg___closed__6 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_instReprPoint_repr___redArg___closed__6_value;
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_instReprPoint_repr___redArg(lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_instReprPoint_repr(lean_object*, lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_instReprPoint_repr___boxed(lean_object*, lean_object*);
static const lean_closure_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_instReprPoint___closed__0_value = {.m_header = {.m_rc = 0, .m_cs_sz = sizeof(lean_closure_object) + sizeof(void*)*0, .m_other = 0, .m_tag = 245}, .m_fun = (void*)lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_instReprPoint_repr___boxed, .m_arity = 2, .m_num_fixed = 0, .m_objs = {} };
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_instReprPoint___closed__0 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_instReprPoint___closed__0_value;
LEAN_EXPORT const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_instReprPoint = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_instReprPoint___closed__0_value;
LEAN_EXPORT uint8_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_instDecidableEqPoint_decEq(lean_object*, lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_instDecidableEqPoint_decEq___boxed(lean_object*, lean_object*);
LEAN_EXPORT uint8_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_instDecidableEqPoint(lean_object*, lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_instDecidableEqPoint___boxed(lean_object*, lean_object*);
static const lean_ctor_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_origin___closed__0_value = {.m_header = {.m_rc = 0, .m_cs_sz = sizeof(lean_ctor_object) + sizeof(void*)*2 + 0, .m_other = 2, .m_tag = 0}, .m_objs = {((lean_object*)(((size_t)(0) << 1) | 1)),((lean_object*)(((size_t)(0) << 1) | 1))}};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_origin___closed__0 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_origin___closed__0_value;
LEAN_EXPORT const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_origin = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_origin___closed__0_value;
static const lean_ctor_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_point__x___closed__0_value = {.m_header = {.m_rc = 0, .m_cs_sz = sizeof(lean_ctor_object) + sizeof(void*)*2 + 0, .m_other = 2, .m_tag = 0}, .m_objs = {((lean_object*)(((size_t)(5) << 1) | 1)),((lean_object*)(((size_t)(0) << 1) | 1))}};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_point__x___closed__0 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_point__x___closed__0_value;
LEAN_EXPORT const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_point__x = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_point__x___closed__0_value;
static const lean_ctor_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_point__y___closed__0_value = {.m_header = {.m_rc = 0, .m_cs_sz = sizeof(lean_ctor_object) + sizeof(void*)*2 + 0, .m_other = 2, .m_tag = 0}, .m_objs = {((lean_object*)(((size_t)(0) << 1) | 1)),((lean_object*)(((size_t)(10) << 1) | 1))}};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_point__y___closed__0 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_point__y___closed__0_value;
LEAN_EXPORT const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_point__y = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_point__y___closed__0_value;
static const lean_ctor_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_point__full___closed__0_value = {.m_header = {.m_rc = 0, .m_cs_sz = sizeof(lean_ctor_object) + sizeof(void*)*2 + 0, .m_other = 2, .m_tag = 0}, .m_objs = {((lean_object*)(((size_t)(3) << 1) | 1)),((lean_object*)(((size_t)(4) << 1) | 1))}};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_point__full___closed__0 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_point__full___closed__0_value;
LEAN_EXPORT const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_point__full = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_point__full___closed__0_value;
static const lean_string_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_instReprStudent_repr___redArg___closed__0_value = {.m_header = {.m_rc = 0, .m_cs_sz = 0, .m_other = 0, .m_tag = 249}, .m_size = 3, .m_capacity = 3, .m_length = 2, .m_data = "id"};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_instReprStudent_repr___redArg___closed__0 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_instReprStudent_repr___redArg___closed__0_value;
static const lean_ctor_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_instReprStudent_repr___redArg___closed__1_value = {.m_header = {.m_rc = 0, .m_cs_sz = sizeof(lean_ctor_object) + sizeof(void*)*1 + 0, .m_other = 1, .m_tag = 3}, .m_objs = {((lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_instReprStudent_repr___redArg___closed__0_value)}};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_instReprStudent_repr___redArg___closed__1 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_instReprStudent_repr___redArg___closed__1_value;
static lean_once_cell_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_instReprStudent_repr___redArg___closed__2_once = LEAN_ONCE_CELL_INITIALIZER;
static lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_instReprStudent_repr___redArg___closed__2;
static const lean_string_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_instReprStudent_repr___redArg___closed__3_value = {.m_header = {.m_rc = 0, .m_cs_sz = 0, .m_other = 0, .m_tag = 249}, .m_size = 6, .m_capacity = 6, .m_length = 5, .m_data = "major"};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_instReprStudent_repr___redArg___closed__3 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_instReprStudent_repr___redArg___closed__3_value;
static const lean_ctor_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_instReprStudent_repr___redArg___closed__4_value = {.m_header = {.m_rc = 0, .m_cs_sz = sizeof(lean_ctor_object) + sizeof(void*)*1 + 0, .m_other = 1, .m_tag = 3}, .m_objs = {((lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_instReprStudent_repr___redArg___closed__3_value)}};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_instReprStudent_repr___redArg___closed__4 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_instReprStudent_repr___redArg___closed__4_value;
static lean_once_cell_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_instReprStudent_repr___redArg___closed__5_once = LEAN_ONCE_CELL_INITIALIZER;
static lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_instReprStudent_repr___redArg___closed__5;
static const lean_string_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_instReprStudent_repr___redArg___closed__6_value = {.m_header = {.m_rc = 0, .m_cs_sz = 0, .m_other = 0, .m_tag = 249}, .m_size = 4, .m_capacity = 4, .m_length = 3, .m_data = "gpa"};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_instReprStudent_repr___redArg___closed__6 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_instReprStudent_repr___redArg___closed__6_value;
static const lean_ctor_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_instReprStudent_repr___redArg___closed__7_value = {.m_header = {.m_rc = 0, .m_cs_sz = sizeof(lean_ctor_object) + sizeof(void*)*1 + 0, .m_other = 1, .m_tag = 3}, .m_objs = {((lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_instReprStudent_repr___redArg___closed__6_value)}};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_instReprStudent_repr___redArg___closed__7 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_instReprStudent_repr___redArg___closed__7_value;
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_instReprStudent_repr___redArg(lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_instReprStudent_repr(lean_object*, lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_instReprStudent_repr___boxed(lean_object*, lean_object*);
static const lean_closure_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_instReprStudent___closed__0_value = {.m_header = {.m_rc = 0, .m_cs_sz = sizeof(lean_closure_object) + sizeof(void*)*0, .m_other = 0, .m_tag = 245}, .m_fun = (void*)lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_instReprStudent_repr___boxed, .m_arity = 2, .m_num_fixed = 0, .m_objs = {} };
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_instReprStudent___closed__0 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_instReprStudent___closed__0_value;
LEAN_EXPORT const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_instReprStudent = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_instReprStudent___closed__0_value;
static const lean_string_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_student1___closed__0_value = {.m_header = {.m_rc = 0, .m_cs_sz = 0, .m_other = 0, .m_tag = 249}, .m_size = 17, .m_capacity = 17, .m_length = 16, .m_data = "Computer Science"};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_student1___closed__0 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_student1___closed__0_value;
static lean_once_cell_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_student1___closed__1_once = LEAN_ONCE_CELL_INITIALIZER;
static double lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_student1___closed__1;
static lean_once_cell_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_student1___closed__2_once = LEAN_ONCE_CELL_INITIALIZER;
static lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_student1___closed__2;
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_student1;
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_student__name;
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_student__major;
static const lean_string_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_instReprAddress_repr___redArg___closed__0_value = {.m_header = {.m_rc = 0, .m_cs_sz = 0, .m_other = 0, .m_tag = 249}, .m_size = 7, .m_capacity = 7, .m_length = 6, .m_data = "street"};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_instReprAddress_repr___redArg___closed__0 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_instReprAddress_repr___redArg___closed__0_value;
static const lean_ctor_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_instReprAddress_repr___redArg___closed__1_value = {.m_header = {.m_rc = 0, .m_cs_sz = sizeof(lean_ctor_object) + sizeof(void*)*1 + 0, .m_other = 1, .m_tag = 3}, .m_objs = {((lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_instReprAddress_repr___redArg___closed__0_value)}};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_instReprAddress_repr___redArg___closed__1 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_instReprAddress_repr___redArg___closed__1_value;
static const lean_ctor_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_instReprAddress_repr___redArg___closed__2_value = {.m_header = {.m_rc = 0, .m_cs_sz = sizeof(lean_ctor_object) + sizeof(void*)*2 + 0, .m_other = 2, .m_tag = 5}, .m_objs = {((lean_object*)(((size_t)(0) << 1) | 1)),((lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_instReprAddress_repr___redArg___closed__1_value)}};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_instReprAddress_repr___redArg___closed__2 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_instReprAddress_repr___redArg___closed__2_value;
static const lean_ctor_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_instReprAddress_repr___redArg___closed__3_value = {.m_header = {.m_rc = 0, .m_cs_sz = sizeof(lean_ctor_object) + sizeof(void*)*2 + 0, .m_other = 2, .m_tag = 5}, .m_objs = {((lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_instReprAddress_repr___redArg___closed__2_value),((lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_instReprPerson_repr___redArg___closed__5_value)}};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_instReprAddress_repr___redArg___closed__3 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_instReprAddress_repr___redArg___closed__3_value;
static lean_once_cell_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_instReprAddress_repr___redArg___closed__4_once = LEAN_ONCE_CELL_INITIALIZER;
static lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_instReprAddress_repr___redArg___closed__4;
static const lean_string_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_instReprAddress_repr___redArg___closed__5_value = {.m_header = {.m_rc = 0, .m_cs_sz = 0, .m_other = 0, .m_tag = 249}, .m_size = 5, .m_capacity = 5, .m_length = 4, .m_data = "city"};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_instReprAddress_repr___redArg___closed__5 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_instReprAddress_repr___redArg___closed__5_value;
static const lean_ctor_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_instReprAddress_repr___redArg___closed__6_value = {.m_header = {.m_rc = 0, .m_cs_sz = sizeof(lean_ctor_object) + sizeof(void*)*1 + 0, .m_other = 1, .m_tag = 3}, .m_objs = {((lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_instReprAddress_repr___redArg___closed__5_value)}};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_instReprAddress_repr___redArg___closed__6 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_instReprAddress_repr___redArg___closed__6_value;
static const lean_string_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_instReprAddress_repr___redArg___closed__7_value = {.m_header = {.m_rc = 0, .m_cs_sz = 0, .m_other = 0, .m_tag = 249}, .m_size = 4, .m_capacity = 4, .m_length = 3, .m_data = "zip"};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_instReprAddress_repr___redArg___closed__7 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_instReprAddress_repr___redArg___closed__7_value;
static const lean_ctor_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_instReprAddress_repr___redArg___closed__8_value = {.m_header = {.m_rc = 0, .m_cs_sz = sizeof(lean_ctor_object) + sizeof(void*)*1 + 0, .m_other = 1, .m_tag = 3}, .m_objs = {((lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_instReprAddress_repr___redArg___closed__7_value)}};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_instReprAddress_repr___redArg___closed__8 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_instReprAddress_repr___redArg___closed__8_value;
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_instReprAddress_repr___redArg(lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_instReprAddress_repr(lean_object*, lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_instReprAddress_repr___boxed(lean_object*, lean_object*);
static const lean_closure_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_instReprAddress___closed__0_value = {.m_header = {.m_rc = 0, .m_cs_sz = sizeof(lean_closure_object) + sizeof(void*)*0, .m_other = 0, .m_tag = 245}, .m_fun = (void*)lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_instReprAddress_repr___boxed, .m_arity = 2, .m_num_fixed = 0, .m_objs = {} };
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_instReprAddress___closed__0 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_instReprAddress___closed__0_value;
LEAN_EXPORT const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_instReprAddress = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_instReprAddress___closed__0_value;
static const lean_string_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_instReprPersonWithAddress_repr___redArg___closed__0_value = {.m_header = {.m_rc = 0, .m_cs_sz = 0, .m_other = 0, .m_tag = 249}, .m_size = 8, .m_capacity = 8, .m_length = 7, .m_data = "address"};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_instReprPersonWithAddress_repr___redArg___closed__0 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_instReprPersonWithAddress_repr___redArg___closed__0_value;
static const lean_ctor_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_instReprPersonWithAddress_repr___redArg___closed__1_value = {.m_header = {.m_rc = 0, .m_cs_sz = sizeof(lean_ctor_object) + sizeof(void*)*1 + 0, .m_other = 1, .m_tag = 3}, .m_objs = {((lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_instReprPersonWithAddress_repr___redArg___closed__0_value)}};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_instReprPersonWithAddress_repr___redArg___closed__1 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_instReprPersonWithAddress_repr___redArg___closed__1_value;
static lean_once_cell_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_instReprPersonWithAddress_repr___redArg___closed__2_once = LEAN_ONCE_CELL_INITIALIZER;
static lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_instReprPersonWithAddress_repr___redArg___closed__2;
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_instReprPersonWithAddress_repr___redArg(lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_instReprPersonWithAddress_repr(lean_object*, lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_instReprPersonWithAddress_repr___boxed(lean_object*, lean_object*);
static const lean_closure_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_instReprPersonWithAddress___closed__0_value = {.m_header = {.m_rc = 0, .m_cs_sz = sizeof(lean_closure_object) + sizeof(void*)*0, .m_other = 0, .m_tag = 245}, .m_fun = (void*)lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_instReprPersonWithAddress_repr___boxed, .m_arity = 2, .m_num_fixed = 0, .m_objs = {} };
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_instReprPersonWithAddress___closed__0 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_instReprPersonWithAddress___closed__0_value;
LEAN_EXPORT const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_instReprPersonWithAddress = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_instReprPersonWithAddress___closed__0_value;
static const lean_string_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_person__with__addr___closed__0_value = {.m_header = {.m_rc = 0, .m_cs_sz = 0, .m_other = 0, .m_tag = 249}, .m_size = 12, .m_capacity = 12, .m_length = 11, .m_data = "123 Main St"};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_person__with__addr___closed__0 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_person__with__addr___closed__0_value;
static const lean_string_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_person__with__addr___closed__1_value = {.m_header = {.m_rc = 0, .m_cs_sz = 0, .m_other = 0, .m_tag = 249}, .m_size = 8, .m_capacity = 8, .m_length = 7, .m_data = "Beijing"};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_person__with__addr___closed__1 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_person__with__addr___closed__1_value;
static const lean_ctor_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_person__with__addr___closed__2_value = {.m_header = {.m_rc = 0, .m_cs_sz = sizeof(lean_ctor_object) + sizeof(void*)*3 + 0, .m_other = 3, .m_tag = 0}, .m_objs = {((lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_person__with__addr___closed__0_value),((lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_person__with__addr___closed__1_value),((lean_object*)(((size_t)(100000) << 1) | 1))}};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_person__with__addr___closed__2 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_person__with__addr___closed__2_value;
static const lean_ctor_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_person__with__addr___closed__3_value = {.m_header = {.m_rc = 0, .m_cs_sz = sizeof(lean_ctor_object) + sizeof(void*)*3 + 0, .m_other = 3, .m_tag = 0}, .m_objs = {((lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_alice___closed__0_value),((lean_object*)(((size_t)(30) << 1) | 1)),((lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_person__with__addr___closed__2_value)}};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_person__with__addr___closed__3 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_person__with__addr___closed__3_value;
LEAN_EXPORT const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_person__with__addr = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_person__with__addr___closed__3_value;
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_person__city;
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_person__zip;
static const lean_string_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_Person_toString___closed__0_value = {.m_header = {.m_rc = 0, .m_cs_sz = 0, .m_other = 0, .m_tag = 249}, .m_size = 13, .m_capacity = 13, .m_length = 12, .m_data = "Person(name="};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_Person_toString___closed__0 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_Person_toString___closed__0_value;
static const lean_string_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_Person_toString___closed__1_value = {.m_header = {.m_rc = 0, .m_cs_sz = 0, .m_other = 0, .m_tag = 249}, .m_size = 7, .m_capacity = 7, .m_length = 6, .m_data = ", age="};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_Person_toString___closed__1 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_Person_toString___closed__1_value;
static const lean_string_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_Person_toString___closed__2_value = {.m_header = {.m_rc = 0, .m_cs_sz = 0, .m_other = 0, .m_tag = 249}, .m_size = 2, .m_capacity = 2, .m_length = 1, .m_data = ")"};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_Person_toString___closed__2 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_Person_toString___closed__2_value;
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_Person_toString(lean_object*);
static lean_once_cell_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_alice__str___closed__0_once = LEAN_ONCE_CELL_INITIALIZER;
static lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_alice__str___closed__0;
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_alice__str;
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_instAddPoint___lam__0(lean_object*, lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_instAddPoint___lam__0___boxed(lean_object*, lean_object*);
static const lean_closure_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_instAddPoint___closed__0_value = {.m_header = {.m_rc = 0, .m_cs_sz = sizeof(lean_closure_object) + sizeof(void*)*0, .m_other = 0, .m_tag = 245}, .m_fun = (void*)lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_instAddPoint___lam__0___boxed, .m_arity = 2, .m_num_fixed = 0, .m_objs = {} };
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_instAddPoint___closed__0 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_instAddPoint___closed__0_value;
LEAN_EXPORT const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_instAddPoint = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_instAddPoint___closed__0_value;
static const lean_ctor_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_point__add___closed__0_value = {.m_header = {.m_rc = 0, .m_cs_sz = sizeof(lean_ctor_object) + sizeof(void*)*2 + 0, .m_other = 2, .m_tag = 0}, .m_objs = {((lean_object*)(((size_t)(4) << 1) | 1)),((lean_object*)(((size_t)(6) << 1) | 1))}};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_point__add___closed__0 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_point__add___closed__0_value;
LEAN_EXPORT const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_point__add = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_point__add___closed__0_value;
LEAN_EXPORT const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_instZeroPoint = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_origin___closed__0_value;
LEAN_EXPORT const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_point__zero = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_origin___closed__0_value;
static const lean_string_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_instReprPosNat_repr___redArg___closed__0_value = {.m_header = {.m_rc = 0, .m_cs_sz = 0, .m_other = 0, .m_tag = 249}, .m_size = 4, .m_capacity = 4, .m_length = 3, .m_data = "val"};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_instReprPosNat_repr___redArg___closed__0 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_instReprPosNat_repr___redArg___closed__0_value;
static const lean_ctor_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_instReprPosNat_repr___redArg___closed__1_value = {.m_header = {.m_rc = 0, .m_cs_sz = sizeof(lean_ctor_object) + sizeof(void*)*1 + 0, .m_other = 1, .m_tag = 3}, .m_objs = {((lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_instReprPosNat_repr___redArg___closed__0_value)}};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_instReprPosNat_repr___redArg___closed__1 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_instReprPosNat_repr___redArg___closed__1_value;
static const lean_ctor_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_instReprPosNat_repr___redArg___closed__2_value = {.m_header = {.m_rc = 0, .m_cs_sz = sizeof(lean_ctor_object) + sizeof(void*)*2 + 0, .m_other = 2, .m_tag = 5}, .m_objs = {((lean_object*)(((size_t)(0) << 1) | 1)),((lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_instReprPosNat_repr___redArg___closed__1_value)}};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_instReprPosNat_repr___redArg___closed__2 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_instReprPosNat_repr___redArg___closed__2_value;
static const lean_ctor_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_instReprPosNat_repr___redArg___closed__3_value = {.m_header = {.m_rc = 0, .m_cs_sz = sizeof(lean_ctor_object) + sizeof(void*)*2 + 0, .m_other = 2, .m_tag = 5}, .m_objs = {((lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_instReprPosNat_repr___redArg___closed__2_value),((lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_instReprPerson_repr___redArg___closed__5_value)}};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_instReprPosNat_repr___redArg___closed__3 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_instReprPosNat_repr___redArg___closed__3_value;
static const lean_string_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_instReprPosNat_repr___redArg___closed__4_value = {.m_header = {.m_rc = 0, .m_cs_sz = 0, .m_other = 0, .m_tag = 249}, .m_size = 4, .m_capacity = 4, .m_length = 3, .m_data = "pos"};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_instReprPosNat_repr___redArg___closed__4 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_instReprPosNat_repr___redArg___closed__4_value;
static const lean_ctor_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_instReprPosNat_repr___redArg___closed__5_value = {.m_header = {.m_rc = 0, .m_cs_sz = sizeof(lean_ctor_object) + sizeof(void*)*1 + 0, .m_other = 1, .m_tag = 3}, .m_objs = {((lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_instReprPosNat_repr___redArg___closed__4_value)}};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_instReprPosNat_repr___redArg___closed__5 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_instReprPosNat_repr___redArg___closed__5_value;
static const lean_string_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_instReprPosNat_repr___redArg___closed__6_value = {.m_header = {.m_rc = 0, .m_cs_sz = 0, .m_other = 0, .m_tag = 249}, .m_size = 2, .m_capacity = 2, .m_length = 1, .m_data = "_"};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_instReprPosNat_repr___redArg___closed__6 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_instReprPosNat_repr___redArg___closed__6_value;
static const lean_ctor_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_instReprPosNat_repr___redArg___closed__7_value = {.m_header = {.m_rc = 0, .m_cs_sz = sizeof(lean_ctor_object) + sizeof(void*)*1 + 0, .m_other = 1, .m_tag = 3}, .m_objs = {((lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_instReprPosNat_repr___redArg___closed__6_value)}};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_instReprPosNat_repr___redArg___closed__7 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_instReprPosNat_repr___redArg___closed__7_value;
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_instReprPosNat_repr___redArg(lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_instReprPosNat_repr(lean_object*, lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_instReprPosNat_repr___boxed(lean_object*, lean_object*);
static const lean_closure_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_instReprPosNat___closed__0_value = {.m_header = {.m_rc = 0, .m_cs_sz = sizeof(lean_closure_object) + sizeof(void*)*0, .m_other = 0, .m_tag = 245}, .m_fun = (void*)lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_instReprPosNat_repr___boxed, .m_arity = 2, .m_num_fixed = 0, .m_objs = {} };
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_instReprPosNat___closed__0 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_instReprPosNat___closed__0_value;
LEAN_EXPORT const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_instReprPosNat = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_instReprPosNat___closed__0_value;
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_five__pos;
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_ten__pos;
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_five__val;
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_PosNat_add(lean_object*, lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_PosNat_add___boxed(lean_object*, lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_five__plus__ten;
static const lean_ctor_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_vec3___closed__0_value = {.m_header = {.m_rc = 0, .m_cs_sz = sizeof(lean_ctor_object) + sizeof(void*)*2 + 0, .m_other = 2, .m_tag = 1}, .m_objs = {((lean_object*)(((size_t)(3) << 1) | 1)),((lean_object*)(((size_t)(0) << 1) | 1))}};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_vec3___closed__0 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_vec3___closed__0_value;
static const lean_ctor_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_vec3___closed__1_value = {.m_header = {.m_rc = 0, .m_cs_sz = sizeof(lean_ctor_object) + sizeof(void*)*2 + 0, .m_other = 2, .m_tag = 1}, .m_objs = {((lean_object*)(((size_t)(2) << 1) | 1)),((lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_vec3___closed__0_value)}};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_vec3___closed__1 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_vec3___closed__1_value;
static const lean_ctor_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_vec3___closed__2_value = {.m_header = {.m_rc = 0, .m_cs_sz = sizeof(lean_ctor_object) + sizeof(void*)*2 + 0, .m_other = 2, .m_tag = 1}, .m_objs = {((lean_object*)(((size_t)(1) << 1) | 1)),((lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_vec3___closed__1_value)}};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_vec3___closed__2 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_vec3___closed__2_value;
LEAN_EXPORT const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_vec3 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_vec3___closed__2_value;
LEAN_EXPORT const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_vec3__data = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_vec3___closed__2_value;
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_instReprPerson_repr___redArg___closed__7(void){
_start:
{
lean_object* v___x_14_; lean_object* v___x_15_; 
v___x_14_ = lean_unsigned_to_nat(8u);
v___x_15_ = lean_nat_to_int(v___x_14_);
return v___x_15_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_instReprPerson_repr___redArg___closed__12(void){
_start:
{
lean_object* v___x_22_; lean_object* v___x_23_; 
v___x_22_ = lean_unsigned_to_nat(7u);
v___x_23_ = lean_nat_to_int(v___x_22_);
return v___x_23_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_instReprPerson_repr___redArg___closed__14(void){
_start:
{
lean_object* v___x_25_; lean_object* v___x_26_; 
v___x_25_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_instReprPerson_repr___redArg___closed__0));
v___x_26_ = lean_string_length(v___x_25_);
return v___x_26_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_instReprPerson_repr___redArg___closed__15(void){
_start:
{
lean_object* v___x_27_; lean_object* v___x_28_; 
v___x_27_ = lean_obj_once(&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_instReprPerson_repr___redArg___closed__14, &lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_instReprPerson_repr___redArg___closed__14_once, _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_instReprPerson_repr___redArg___closed__14);
v___x_28_ = lean_nat_to_int(v___x_27_);
return v___x_28_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_instReprPerson_repr___redArg(lean_object* v_x_33_){
_start:
{
lean_object* v_name_34_; lean_object* v_age_35_; lean_object* v___x_37_; uint8_t v_isShared_38_; uint8_t v_isSharedCheck_70_; 
v_name_34_ = lean_ctor_get(v_x_33_, 0);
v_age_35_ = lean_ctor_get(v_x_33_, 1);
v_isSharedCheck_70_ = !lean_is_exclusive(v_x_33_);
if (v_isSharedCheck_70_ == 0)
{
v___x_37_ = v_x_33_;
v_isShared_38_ = v_isSharedCheck_70_;
goto v_resetjp_36_;
}
else
{
lean_inc(v_age_35_);
lean_inc(v_name_34_);
lean_dec(v_x_33_);
v___x_37_ = lean_box(0);
v_isShared_38_ = v_isSharedCheck_70_;
goto v_resetjp_36_;
}
v_resetjp_36_:
{
lean_object* v___x_39_; lean_object* v___x_40_; lean_object* v___x_41_; lean_object* v___x_42_; lean_object* v___x_43_; lean_object* v___x_45_; 
v___x_39_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_instReprPerson_repr___redArg___closed__5));
v___x_40_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_instReprPerson_repr___redArg___closed__6));
v___x_41_ = lean_obj_once(&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_instReprPerson_repr___redArg___closed__7, &lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_instReprPerson_repr___redArg___closed__7_once, _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_instReprPerson_repr___redArg___closed__7);
v___x_42_ = l_String_quote(v_name_34_);
v___x_43_ = lean_alloc_ctor(3, 1, 0);
lean_ctor_set(v___x_43_, 0, v___x_42_);
if (v_isShared_38_ == 0)
{
lean_ctor_set_tag(v___x_37_, 4);
lean_ctor_set(v___x_37_, 1, v___x_43_);
lean_ctor_set(v___x_37_, 0, v___x_41_);
v___x_45_ = v___x_37_;
goto v_reusejp_44_;
}
else
{
lean_object* v_reuseFailAlloc_69_; 
v_reuseFailAlloc_69_ = lean_alloc_ctor(4, 2, 0);
lean_ctor_set(v_reuseFailAlloc_69_, 0, v___x_41_);
lean_ctor_set(v_reuseFailAlloc_69_, 1, v___x_43_);
v___x_45_ = v_reuseFailAlloc_69_;
goto v_reusejp_44_;
}
v_reusejp_44_:
{
uint8_t v___x_46_; lean_object* v___x_47_; lean_object* v___x_48_; lean_object* v___x_49_; lean_object* v___x_50_; lean_object* v___x_51_; lean_object* v___x_52_; lean_object* v___x_53_; lean_object* v___x_54_; lean_object* v___x_55_; lean_object* v___x_56_; lean_object* v___x_57_; lean_object* v___x_58_; lean_object* v___x_59_; lean_object* v___x_60_; lean_object* v___x_61_; lean_object* v___x_62_; lean_object* v___x_63_; lean_object* v___x_64_; lean_object* v___x_65_; lean_object* v___x_66_; lean_object* v___x_67_; lean_object* v___x_68_; 
v___x_46_ = 0;
v___x_47_ = lean_alloc_ctor(6, 1, 1);
lean_ctor_set(v___x_47_, 0, v___x_45_);
lean_ctor_set_uint8(v___x_47_, sizeof(void*)*1, v___x_46_);
v___x_48_ = lean_alloc_ctor(5, 2, 0);
lean_ctor_set(v___x_48_, 0, v___x_40_);
lean_ctor_set(v___x_48_, 1, v___x_47_);
v___x_49_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_instReprPerson_repr___redArg___closed__9));
v___x_50_ = lean_alloc_ctor(5, 2, 0);
lean_ctor_set(v___x_50_, 0, v___x_48_);
lean_ctor_set(v___x_50_, 1, v___x_49_);
v___x_51_ = lean_box(1);
v___x_52_ = lean_alloc_ctor(5, 2, 0);
lean_ctor_set(v___x_52_, 0, v___x_50_);
lean_ctor_set(v___x_52_, 1, v___x_51_);
v___x_53_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_instReprPerson_repr___redArg___closed__11));
v___x_54_ = lean_alloc_ctor(5, 2, 0);
lean_ctor_set(v___x_54_, 0, v___x_52_);
lean_ctor_set(v___x_54_, 1, v___x_53_);
v___x_55_ = lean_alloc_ctor(5, 2, 0);
lean_ctor_set(v___x_55_, 0, v___x_54_);
lean_ctor_set(v___x_55_, 1, v___x_39_);
v___x_56_ = lean_obj_once(&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_instReprPerson_repr___redArg___closed__12, &lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_instReprPerson_repr___redArg___closed__12_once, _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_instReprPerson_repr___redArg___closed__12);
v___x_57_ = l_Nat_reprFast(v_age_35_);
v___x_58_ = lean_alloc_ctor(3, 1, 0);
lean_ctor_set(v___x_58_, 0, v___x_57_);
v___x_59_ = lean_alloc_ctor(4, 2, 0);
lean_ctor_set(v___x_59_, 0, v___x_56_);
lean_ctor_set(v___x_59_, 1, v___x_58_);
v___x_60_ = lean_alloc_ctor(6, 1, 1);
lean_ctor_set(v___x_60_, 0, v___x_59_);
lean_ctor_set_uint8(v___x_60_, sizeof(void*)*1, v___x_46_);
v___x_61_ = lean_alloc_ctor(5, 2, 0);
lean_ctor_set(v___x_61_, 0, v___x_55_);
lean_ctor_set(v___x_61_, 1, v___x_60_);
v___x_62_ = lean_obj_once(&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_instReprPerson_repr___redArg___closed__15, &lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_instReprPerson_repr___redArg___closed__15_once, _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_instReprPerson_repr___redArg___closed__15);
v___x_63_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_instReprPerson_repr___redArg___closed__16));
v___x_64_ = lean_alloc_ctor(5, 2, 0);
lean_ctor_set(v___x_64_, 0, v___x_63_);
lean_ctor_set(v___x_64_, 1, v___x_61_);
v___x_65_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_instReprPerson_repr___redArg___closed__17));
v___x_66_ = lean_alloc_ctor(5, 2, 0);
lean_ctor_set(v___x_66_, 0, v___x_64_);
lean_ctor_set(v___x_66_, 1, v___x_65_);
v___x_67_ = lean_alloc_ctor(4, 2, 0);
lean_ctor_set(v___x_67_, 0, v___x_62_);
lean_ctor_set(v___x_67_, 1, v___x_66_);
v___x_68_ = lean_alloc_ctor(6, 1, 1);
lean_ctor_set(v___x_68_, 0, v___x_67_);
lean_ctor_set_uint8(v___x_68_, sizeof(void*)*1, v___x_46_);
return v___x_68_;
}
}
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_instReprPerson_repr(lean_object* v_x_71_, lean_object* v_prec_72_){
_start:
{
lean_object* v___x_73_; 
v___x_73_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_instReprPerson_repr___redArg(v_x_71_);
return v___x_73_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_instReprPerson_repr___boxed(lean_object* v_x_74_, lean_object* v_prec_75_){
_start:
{
lean_object* v_res_76_; 
v_res_76_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_instReprPerson_repr(v_x_74_, v_prec_75_);
lean_dec(v_prec_75_);
return v_res_76_;
}
}
LEAN_EXPORT uint8_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_instDecidableEqPerson_decEq(lean_object* v_x_79_, lean_object* v_x_80_){
_start:
{
lean_object* v_name_81_; lean_object* v_age_82_; lean_object* v_name_83_; lean_object* v_age_84_; uint8_t v___x_85_; 
v_name_81_ = lean_ctor_get(v_x_79_, 0);
v_age_82_ = lean_ctor_get(v_x_79_, 1);
v_name_83_ = lean_ctor_get(v_x_80_, 0);
v_age_84_ = lean_ctor_get(v_x_80_, 1);
v___x_85_ = lean_string_dec_eq(v_name_81_, v_name_83_);
if (v___x_85_ == 0)
{
return v___x_85_;
}
else
{
uint8_t v___x_86_; 
v___x_86_ = lean_nat_dec_eq(v_age_82_, v_age_84_);
return v___x_86_;
}
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_instDecidableEqPerson_decEq___boxed(lean_object* v_x_87_, lean_object* v_x_88_){
_start:
{
uint8_t v_res_89_; lean_object* v_r_90_; 
v_res_89_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_instDecidableEqPerson_decEq(v_x_87_, v_x_88_);
lean_dec_ref(v_x_88_);
lean_dec_ref(v_x_87_);
v_r_90_ = lean_box(v_res_89_);
return v_r_90_;
}
}
LEAN_EXPORT uint8_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_instDecidableEqPerson(lean_object* v_x_91_, lean_object* v_x_92_){
_start:
{
uint8_t v___x_93_; 
v___x_93_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_instDecidableEqPerson_decEq(v_x_91_, v_x_92_);
return v___x_93_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_instDecidableEqPerson___boxed(lean_object* v_x_94_, lean_object* v_x_95_){
_start:
{
uint8_t v_res_96_; lean_object* v_r_97_; 
v_res_96_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_instDecidableEqPerson(v_x_94_, v_x_95_);
lean_dec_ref(v_x_95_);
lean_dec_ref(v_x_94_);
v_r_97_ = lean_box(v_res_96_);
return v_r_97_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_alice__name(void){
_start:
{
lean_object* v___x_113_; lean_object* v_name_114_; 
v___x_113_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_alice));
v_name_114_ = lean_ctor_get(v___x_113_, 0);
lean_inc_ref(v_name_114_);
return v_name_114_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_alice__age(void){
_start:
{
lean_object* v___x_115_; lean_object* v_age_116_; 
v___x_115_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_alice));
v_age_116_ = lean_ctor_get(v___x_115_, 1);
lean_inc(v_age_116_);
return v_age_116_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_bob__name(void){
_start:
{
lean_object* v___x_117_; lean_object* v_name_118_; 
v___x_117_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_bob));
v_name_118_ = lean_ctor_get(v___x_117_, 0);
lean_inc_ref(v_name_118_);
return v_name_118_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_bob__age(void){
_start:
{
lean_object* v___x_119_; lean_object* v_age_120_; 
v___x_119_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_bob));
v_age_120_ = lean_ctor_get(v___x_119_, 1);
lean_inc(v_age_120_);
return v_age_120_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_birthday(lean_object* v_p_121_){
_start:
{
lean_object* v_name_122_; lean_object* v_age_123_; lean_object* v___x_125_; uint8_t v_isShared_126_; uint8_t v_isSharedCheck_132_; 
v_name_122_ = lean_ctor_get(v_p_121_, 0);
v_age_123_ = lean_ctor_get(v_p_121_, 1);
v_isSharedCheck_132_ = !lean_is_exclusive(v_p_121_);
if (v_isSharedCheck_132_ == 0)
{
v___x_125_ = v_p_121_;
v_isShared_126_ = v_isSharedCheck_132_;
goto v_resetjp_124_;
}
else
{
lean_inc(v_age_123_);
lean_inc(v_name_122_);
lean_dec(v_p_121_);
v___x_125_ = lean_box(0);
v_isShared_126_ = v_isSharedCheck_132_;
goto v_resetjp_124_;
}
v_resetjp_124_:
{
lean_object* v___x_127_; lean_object* v___x_128_; lean_object* v___x_130_; 
v___x_127_ = lean_unsigned_to_nat(1u);
v___x_128_ = lean_nat_add(v_age_123_, v___x_127_);
lean_dec(v_age_123_);
if (v_isShared_126_ == 0)
{
lean_ctor_set(v___x_125_, 1, v___x_128_);
v___x_130_ = v___x_125_;
goto v_reusejp_129_;
}
else
{
lean_object* v_reuseFailAlloc_131_; 
v_reuseFailAlloc_131_ = lean_alloc_ctor(0, 2, 0);
lean_ctor_set(v_reuseFailAlloc_131_, 0, v_name_122_);
lean_ctor_set(v_reuseFailAlloc_131_, 1, v___x_128_);
v___x_130_ = v_reuseFailAlloc_131_;
goto v_reusejp_129_;
}
v_reusejp_129_:
{
return v___x_130_;
}
}
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_alice__next__year___closed__0(void){
_start:
{
lean_object* v___x_133_; lean_object* v___x_134_; 
v___x_133_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_alice));
v___x_134_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_birthday(v___x_133_);
return v___x_134_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_alice__next__year(void){
_start:
{
lean_object* v___x_135_; 
v___x_135_ = lean_obj_once(&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_alice__next__year___closed__0, &lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_alice__next__year___closed__0_once, _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_alice__next__year___closed__0);
return v___x_135_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_greet(lean_object* v_p_139_){
_start:
{
lean_object* v_name_140_; lean_object* v_age_141_; lean_object* v___x_142_; lean_object* v___x_143_; lean_object* v___x_144_; lean_object* v___x_145_; lean_object* v___x_146_; lean_object* v___x_147_; lean_object* v___x_148_; lean_object* v___x_149_; 
v_name_140_ = lean_ctor_get(v_p_139_, 0);
lean_inc_ref(v_name_140_);
v_age_141_ = lean_ctor_get(v_p_139_, 1);
lean_inc(v_age_141_);
lean_dec_ref(v_p_139_);
v___x_142_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_greet___closed__0));
v___x_143_ = lean_string_append(v___x_142_, v_name_140_);
lean_dec_ref(v_name_140_);
v___x_144_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_greet___closed__1));
v___x_145_ = lean_string_append(v___x_143_, v___x_144_);
v___x_146_ = l_Nat_reprFast(v_age_141_);
v___x_147_ = lean_string_append(v___x_145_, v___x_146_);
lean_dec_ref(v___x_146_);
v___x_148_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_greet___closed__2));
v___x_149_ = lean_string_append(v___x_147_, v___x_148_);
return v___x_149_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_alice__greet___closed__0(void){
_start:
{
lean_object* v___x_150_; lean_object* v___x_151_; 
v___x_150_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_alice));
v___x_151_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_greet(v___x_150_);
return v___x_151_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_alice__greet(void){
_start:
{
lean_object* v___x_152_; 
v___x_152_ = lean_obj_once(&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_alice__greet___closed__0, &lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_alice__greet___closed__0_once, _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_alice__greet___closed__0);
return v___x_152_;
}
}
LEAN_EXPORT uint8_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_isAdult(lean_object* v_p_153_){
_start:
{
lean_object* v_age_154_; lean_object* v___x_155_; uint8_t v___x_156_; 
v_age_154_ = lean_ctor_get(v_p_153_, 1);
v___x_155_ = lean_unsigned_to_nat(18u);
v___x_156_ = lean_nat_dec_le(v___x_155_, v_age_154_);
return v___x_156_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_isAdult___boxed(lean_object* v_p_157_){
_start:
{
uint8_t v_res_158_; lean_object* v_r_159_; 
v_res_158_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_isAdult(v_p_157_);
lean_dec_ref(v_p_157_);
v_r_159_ = lean_box(v_res_158_);
return v_r_159_;
}
}
static uint8_t _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_alice__adult___closed__0(void){
_start:
{
lean_object* v___x_160_; uint8_t v___x_161_; 
v___x_160_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_alice));
v___x_161_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_isAdult(v___x_160_);
return v___x_161_;
}
}
static uint8_t _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_alice__adult(void){
_start:
{
uint8_t v___x_162_; 
v___x_162_ = lean_uint8_once(&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_alice__adult___closed__0, &lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_alice__adult___closed__0_once, _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_alice__adult___closed__0);
return v___x_162_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_instReprPoint_repr___redArg___closed__4(void){
_start:
{
lean_object* v___x_172_; lean_object* v___x_173_; 
v___x_172_ = lean_unsigned_to_nat(5u);
v___x_173_ = lean_nat_to_int(v___x_172_);
return v___x_173_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_instReprPoint_repr___redArg(lean_object* v_x_177_){
_start:
{
lean_object* v_x_178_; lean_object* v_y_179_; lean_object* v___x_181_; uint8_t v_isShared_182_; uint8_t v_isSharedCheck_213_; 
v_x_178_ = lean_ctor_get(v_x_177_, 0);
v_y_179_ = lean_ctor_get(v_x_177_, 1);
v_isSharedCheck_213_ = !lean_is_exclusive(v_x_177_);
if (v_isSharedCheck_213_ == 0)
{
v___x_181_ = v_x_177_;
v_isShared_182_ = v_isSharedCheck_213_;
goto v_resetjp_180_;
}
else
{
lean_inc(v_y_179_);
lean_inc(v_x_178_);
lean_dec(v_x_177_);
v___x_181_ = lean_box(0);
v_isShared_182_ = v_isSharedCheck_213_;
goto v_resetjp_180_;
}
v_resetjp_180_:
{
lean_object* v___x_183_; lean_object* v___x_184_; lean_object* v___x_185_; lean_object* v___x_186_; lean_object* v___x_187_; lean_object* v___x_189_; 
v___x_183_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_instReprPerson_repr___redArg___closed__5));
v___x_184_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_instReprPoint_repr___redArg___closed__3));
v___x_185_ = lean_obj_once(&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_instReprPoint_repr___redArg___closed__4, &lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_instReprPoint_repr___redArg___closed__4_once, _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_instReprPoint_repr___redArg___closed__4);
v___x_186_ = l_Nat_reprFast(v_x_178_);
v___x_187_ = lean_alloc_ctor(3, 1, 0);
lean_ctor_set(v___x_187_, 0, v___x_186_);
if (v_isShared_182_ == 0)
{
lean_ctor_set_tag(v___x_181_, 4);
lean_ctor_set(v___x_181_, 1, v___x_187_);
lean_ctor_set(v___x_181_, 0, v___x_185_);
v___x_189_ = v___x_181_;
goto v_reusejp_188_;
}
else
{
lean_object* v_reuseFailAlloc_212_; 
v_reuseFailAlloc_212_ = lean_alloc_ctor(4, 2, 0);
lean_ctor_set(v_reuseFailAlloc_212_, 0, v___x_185_);
lean_ctor_set(v_reuseFailAlloc_212_, 1, v___x_187_);
v___x_189_ = v_reuseFailAlloc_212_;
goto v_reusejp_188_;
}
v_reusejp_188_:
{
uint8_t v___x_190_; lean_object* v___x_191_; lean_object* v___x_192_; lean_object* v___x_193_; lean_object* v___x_194_; lean_object* v___x_195_; lean_object* v___x_196_; lean_object* v___x_197_; lean_object* v___x_198_; lean_object* v___x_199_; lean_object* v___x_200_; lean_object* v___x_201_; lean_object* v___x_202_; lean_object* v___x_203_; lean_object* v___x_204_; lean_object* v___x_205_; lean_object* v___x_206_; lean_object* v___x_207_; lean_object* v___x_208_; lean_object* v___x_209_; lean_object* v___x_210_; lean_object* v___x_211_; 
v___x_190_ = 0;
v___x_191_ = lean_alloc_ctor(6, 1, 1);
lean_ctor_set(v___x_191_, 0, v___x_189_);
lean_ctor_set_uint8(v___x_191_, sizeof(void*)*1, v___x_190_);
v___x_192_ = lean_alloc_ctor(5, 2, 0);
lean_ctor_set(v___x_192_, 0, v___x_184_);
lean_ctor_set(v___x_192_, 1, v___x_191_);
v___x_193_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_instReprPerson_repr___redArg___closed__9));
v___x_194_ = lean_alloc_ctor(5, 2, 0);
lean_ctor_set(v___x_194_, 0, v___x_192_);
lean_ctor_set(v___x_194_, 1, v___x_193_);
v___x_195_ = lean_box(1);
v___x_196_ = lean_alloc_ctor(5, 2, 0);
lean_ctor_set(v___x_196_, 0, v___x_194_);
lean_ctor_set(v___x_196_, 1, v___x_195_);
v___x_197_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_instReprPoint_repr___redArg___closed__6));
v___x_198_ = lean_alloc_ctor(5, 2, 0);
lean_ctor_set(v___x_198_, 0, v___x_196_);
lean_ctor_set(v___x_198_, 1, v___x_197_);
v___x_199_ = lean_alloc_ctor(5, 2, 0);
lean_ctor_set(v___x_199_, 0, v___x_198_);
lean_ctor_set(v___x_199_, 1, v___x_183_);
v___x_200_ = l_Nat_reprFast(v_y_179_);
v___x_201_ = lean_alloc_ctor(3, 1, 0);
lean_ctor_set(v___x_201_, 0, v___x_200_);
v___x_202_ = lean_alloc_ctor(4, 2, 0);
lean_ctor_set(v___x_202_, 0, v___x_185_);
lean_ctor_set(v___x_202_, 1, v___x_201_);
v___x_203_ = lean_alloc_ctor(6, 1, 1);
lean_ctor_set(v___x_203_, 0, v___x_202_);
lean_ctor_set_uint8(v___x_203_, sizeof(void*)*1, v___x_190_);
v___x_204_ = lean_alloc_ctor(5, 2, 0);
lean_ctor_set(v___x_204_, 0, v___x_199_);
lean_ctor_set(v___x_204_, 1, v___x_203_);
v___x_205_ = lean_obj_once(&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_instReprPerson_repr___redArg___closed__15, &lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_instReprPerson_repr___redArg___closed__15_once, _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_instReprPerson_repr___redArg___closed__15);
v___x_206_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_instReprPerson_repr___redArg___closed__16));
v___x_207_ = lean_alloc_ctor(5, 2, 0);
lean_ctor_set(v___x_207_, 0, v___x_206_);
lean_ctor_set(v___x_207_, 1, v___x_204_);
v___x_208_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_instReprPerson_repr___redArg___closed__17));
v___x_209_ = lean_alloc_ctor(5, 2, 0);
lean_ctor_set(v___x_209_, 0, v___x_207_);
lean_ctor_set(v___x_209_, 1, v___x_208_);
v___x_210_ = lean_alloc_ctor(4, 2, 0);
lean_ctor_set(v___x_210_, 0, v___x_205_);
lean_ctor_set(v___x_210_, 1, v___x_209_);
v___x_211_ = lean_alloc_ctor(6, 1, 1);
lean_ctor_set(v___x_211_, 0, v___x_210_);
lean_ctor_set_uint8(v___x_211_, sizeof(void*)*1, v___x_190_);
return v___x_211_;
}
}
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_instReprPoint_repr(lean_object* v_x_214_, lean_object* v_prec_215_){
_start:
{
lean_object* v___x_216_; 
v___x_216_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_instReprPoint_repr___redArg(v_x_214_);
return v___x_216_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_instReprPoint_repr___boxed(lean_object* v_x_217_, lean_object* v_prec_218_){
_start:
{
lean_object* v_res_219_; 
v_res_219_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_instReprPoint_repr(v_x_217_, v_prec_218_);
lean_dec(v_prec_218_);
return v_res_219_;
}
}
LEAN_EXPORT uint8_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_instDecidableEqPoint_decEq(lean_object* v_x_222_, lean_object* v_x_223_){
_start:
{
lean_object* v_x_224_; lean_object* v_y_225_; lean_object* v_x_226_; lean_object* v_y_227_; uint8_t v___x_228_; 
v_x_224_ = lean_ctor_get(v_x_222_, 0);
v_y_225_ = lean_ctor_get(v_x_222_, 1);
v_x_226_ = lean_ctor_get(v_x_223_, 0);
v_y_227_ = lean_ctor_get(v_x_223_, 1);
v___x_228_ = lean_nat_dec_eq(v_x_224_, v_x_226_);
if (v___x_228_ == 0)
{
return v___x_228_;
}
else
{
uint8_t v___x_229_; 
v___x_229_ = lean_nat_dec_eq(v_y_225_, v_y_227_);
return v___x_229_;
}
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_instDecidableEqPoint_decEq___boxed(lean_object* v_x_230_, lean_object* v_x_231_){
_start:
{
uint8_t v_res_232_; lean_object* v_r_233_; 
v_res_232_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_instDecidableEqPoint_decEq(v_x_230_, v_x_231_);
lean_dec_ref(v_x_231_);
lean_dec_ref(v_x_230_);
v_r_233_ = lean_box(v_res_232_);
return v_r_233_;
}
}
LEAN_EXPORT uint8_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_instDecidableEqPoint(lean_object* v_x_234_, lean_object* v_x_235_){
_start:
{
uint8_t v___x_236_; 
v___x_236_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_instDecidableEqPoint_decEq(v_x_234_, v_x_235_);
return v___x_236_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_instDecidableEqPoint___boxed(lean_object* v_x_237_, lean_object* v_x_238_){
_start:
{
uint8_t v_res_239_; lean_object* v_r_240_; 
v_res_239_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_instDecidableEqPoint(v_x_237_, v_x_238_);
lean_dec_ref(v_x_238_);
lean_dec_ref(v_x_237_);
v_r_240_ = lean_box(v_res_239_);
return v_r_240_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_instReprStudent_repr___redArg___closed__2(void){
_start:
{
lean_object* v___x_259_; lean_object* v___x_260_; 
v___x_259_ = lean_unsigned_to_nat(6u);
v___x_260_ = lean_nat_to_int(v___x_259_);
return v___x_260_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_instReprStudent_repr___redArg___closed__5(void){
_start:
{
lean_object* v___x_264_; lean_object* v___x_265_; 
v___x_264_ = lean_unsigned_to_nat(9u);
v___x_265_ = lean_nat_to_int(v___x_264_);
return v___x_265_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_instReprStudent_repr___redArg(lean_object* v_x_269_){
_start:
{
lean_object* v_name_270_; lean_object* v_age_271_; lean_object* v_id_272_; lean_object* v_major_273_; double v_gpa_274_; lean_object* v___x_275_; lean_object* v___x_276_; lean_object* v___x_277_; lean_object* v___x_278_; lean_object* v___x_279_; lean_object* v___x_280_; uint8_t v___x_281_; lean_object* v___x_282_; lean_object* v___x_283_; lean_object* v___x_284_; lean_object* v___x_285_; lean_object* v___x_286_; lean_object* v___x_287_; lean_object* v___x_288_; lean_object* v___x_289_; lean_object* v___x_290_; lean_object* v___x_291_; lean_object* v___x_292_; lean_object* v___x_293_; lean_object* v___x_294_; lean_object* v___x_295_; lean_object* v___x_296_; lean_object* v___x_297_; lean_object* v___x_298_; lean_object* v___x_299_; lean_object* v___x_300_; lean_object* v___x_301_; lean_object* v___x_302_; lean_object* v___x_303_; lean_object* v___x_304_; lean_object* v___x_305_; lean_object* v___x_306_; lean_object* v___x_307_; lean_object* v___x_308_; lean_object* v___x_309_; lean_object* v___x_310_; lean_object* v___x_311_; lean_object* v___x_312_; lean_object* v___x_313_; lean_object* v___x_314_; lean_object* v___x_315_; lean_object* v___x_316_; lean_object* v___x_317_; lean_object* v___x_318_; lean_object* v___x_319_; lean_object* v___x_320_; lean_object* v___x_321_; lean_object* v___x_322_; lean_object* v___x_323_; lean_object* v___x_324_; lean_object* v___x_325_; lean_object* v___x_326_; lean_object* v___x_327_; lean_object* v___x_328_; lean_object* v___x_329_; lean_object* v___x_330_; lean_object* v___x_331_; lean_object* v___x_332_; lean_object* v___x_333_; lean_object* v___x_334_; lean_object* v___x_335_; 
v_name_270_ = lean_ctor_get(v_x_269_, 0);
lean_inc_ref(v_name_270_);
v_age_271_ = lean_ctor_get(v_x_269_, 1);
lean_inc(v_age_271_);
v_id_272_ = lean_ctor_get(v_x_269_, 2);
lean_inc(v_id_272_);
v_major_273_ = lean_ctor_get(v_x_269_, 3);
lean_inc_ref(v_major_273_);
v_gpa_274_ = lean_ctor_get_float(v_x_269_, sizeof(void*)*4);
lean_dec_ref(v_x_269_);
v___x_275_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_instReprPerson_repr___redArg___closed__5));
v___x_276_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_instReprPerson_repr___redArg___closed__6));
v___x_277_ = lean_obj_once(&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_instReprPerson_repr___redArg___closed__7, &lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_instReprPerson_repr___redArg___closed__7_once, _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_instReprPerson_repr___redArg___closed__7);
v___x_278_ = l_String_quote(v_name_270_);
v___x_279_ = lean_alloc_ctor(3, 1, 0);
lean_ctor_set(v___x_279_, 0, v___x_278_);
v___x_280_ = lean_alloc_ctor(4, 2, 0);
lean_ctor_set(v___x_280_, 0, v___x_277_);
lean_ctor_set(v___x_280_, 1, v___x_279_);
v___x_281_ = 0;
v___x_282_ = lean_alloc_ctor(6, 1, 1);
lean_ctor_set(v___x_282_, 0, v___x_280_);
lean_ctor_set_uint8(v___x_282_, sizeof(void*)*1, v___x_281_);
v___x_283_ = lean_alloc_ctor(5, 2, 0);
lean_ctor_set(v___x_283_, 0, v___x_276_);
lean_ctor_set(v___x_283_, 1, v___x_282_);
v___x_284_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_instReprPerson_repr___redArg___closed__9));
v___x_285_ = lean_alloc_ctor(5, 2, 0);
lean_ctor_set(v___x_285_, 0, v___x_283_);
lean_ctor_set(v___x_285_, 1, v___x_284_);
v___x_286_ = lean_box(1);
v___x_287_ = lean_alloc_ctor(5, 2, 0);
lean_ctor_set(v___x_287_, 0, v___x_285_);
lean_ctor_set(v___x_287_, 1, v___x_286_);
v___x_288_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_instReprPerson_repr___redArg___closed__11));
v___x_289_ = lean_alloc_ctor(5, 2, 0);
lean_ctor_set(v___x_289_, 0, v___x_287_);
lean_ctor_set(v___x_289_, 1, v___x_288_);
v___x_290_ = lean_alloc_ctor(5, 2, 0);
lean_ctor_set(v___x_290_, 0, v___x_289_);
lean_ctor_set(v___x_290_, 1, v___x_275_);
v___x_291_ = lean_obj_once(&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_instReprPerson_repr___redArg___closed__12, &lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_instReprPerson_repr___redArg___closed__12_once, _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_instReprPerson_repr___redArg___closed__12);
v___x_292_ = l_Nat_reprFast(v_age_271_);
v___x_293_ = lean_alloc_ctor(3, 1, 0);
lean_ctor_set(v___x_293_, 0, v___x_292_);
v___x_294_ = lean_alloc_ctor(4, 2, 0);
lean_ctor_set(v___x_294_, 0, v___x_291_);
lean_ctor_set(v___x_294_, 1, v___x_293_);
v___x_295_ = lean_alloc_ctor(6, 1, 1);
lean_ctor_set(v___x_295_, 0, v___x_294_);
lean_ctor_set_uint8(v___x_295_, sizeof(void*)*1, v___x_281_);
v___x_296_ = lean_alloc_ctor(5, 2, 0);
lean_ctor_set(v___x_296_, 0, v___x_290_);
lean_ctor_set(v___x_296_, 1, v___x_295_);
v___x_297_ = lean_alloc_ctor(5, 2, 0);
lean_ctor_set(v___x_297_, 0, v___x_296_);
lean_ctor_set(v___x_297_, 1, v___x_284_);
v___x_298_ = lean_alloc_ctor(5, 2, 0);
lean_ctor_set(v___x_298_, 0, v___x_297_);
lean_ctor_set(v___x_298_, 1, v___x_286_);
v___x_299_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_instReprStudent_repr___redArg___closed__1));
v___x_300_ = lean_alloc_ctor(5, 2, 0);
lean_ctor_set(v___x_300_, 0, v___x_298_);
lean_ctor_set(v___x_300_, 1, v___x_299_);
v___x_301_ = lean_alloc_ctor(5, 2, 0);
lean_ctor_set(v___x_301_, 0, v___x_300_);
lean_ctor_set(v___x_301_, 1, v___x_275_);
v___x_302_ = lean_obj_once(&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_instReprStudent_repr___redArg___closed__2, &lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_instReprStudent_repr___redArg___closed__2_once, _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_instReprStudent_repr___redArg___closed__2);
v___x_303_ = l_Nat_reprFast(v_id_272_);
v___x_304_ = lean_alloc_ctor(3, 1, 0);
lean_ctor_set(v___x_304_, 0, v___x_303_);
v___x_305_ = lean_alloc_ctor(4, 2, 0);
lean_ctor_set(v___x_305_, 0, v___x_302_);
lean_ctor_set(v___x_305_, 1, v___x_304_);
v___x_306_ = lean_alloc_ctor(6, 1, 1);
lean_ctor_set(v___x_306_, 0, v___x_305_);
lean_ctor_set_uint8(v___x_306_, sizeof(void*)*1, v___x_281_);
v___x_307_ = lean_alloc_ctor(5, 2, 0);
lean_ctor_set(v___x_307_, 0, v___x_301_);
lean_ctor_set(v___x_307_, 1, v___x_306_);
v___x_308_ = lean_alloc_ctor(5, 2, 0);
lean_ctor_set(v___x_308_, 0, v___x_307_);
lean_ctor_set(v___x_308_, 1, v___x_284_);
v___x_309_ = lean_alloc_ctor(5, 2, 0);
lean_ctor_set(v___x_309_, 0, v___x_308_);
lean_ctor_set(v___x_309_, 1, v___x_286_);
v___x_310_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_instReprStudent_repr___redArg___closed__4));
v___x_311_ = lean_alloc_ctor(5, 2, 0);
lean_ctor_set(v___x_311_, 0, v___x_309_);
lean_ctor_set(v___x_311_, 1, v___x_310_);
v___x_312_ = lean_alloc_ctor(5, 2, 0);
lean_ctor_set(v___x_312_, 0, v___x_311_);
lean_ctor_set(v___x_312_, 1, v___x_275_);
v___x_313_ = lean_obj_once(&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_instReprStudent_repr___redArg___closed__5, &lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_instReprStudent_repr___redArg___closed__5_once, _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_instReprStudent_repr___redArg___closed__5);
v___x_314_ = l_String_quote(v_major_273_);
v___x_315_ = lean_alloc_ctor(3, 1, 0);
lean_ctor_set(v___x_315_, 0, v___x_314_);
v___x_316_ = lean_alloc_ctor(4, 2, 0);
lean_ctor_set(v___x_316_, 0, v___x_313_);
lean_ctor_set(v___x_316_, 1, v___x_315_);
v___x_317_ = lean_alloc_ctor(6, 1, 1);
lean_ctor_set(v___x_317_, 0, v___x_316_);
lean_ctor_set_uint8(v___x_317_, sizeof(void*)*1, v___x_281_);
v___x_318_ = lean_alloc_ctor(5, 2, 0);
lean_ctor_set(v___x_318_, 0, v___x_312_);
lean_ctor_set(v___x_318_, 1, v___x_317_);
v___x_319_ = lean_alloc_ctor(5, 2, 0);
lean_ctor_set(v___x_319_, 0, v___x_318_);
lean_ctor_set(v___x_319_, 1, v___x_284_);
v___x_320_ = lean_alloc_ctor(5, 2, 0);
lean_ctor_set(v___x_320_, 0, v___x_319_);
lean_ctor_set(v___x_320_, 1, v___x_286_);
v___x_321_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_instReprStudent_repr___redArg___closed__7));
v___x_322_ = lean_alloc_ctor(5, 2, 0);
lean_ctor_set(v___x_322_, 0, v___x_320_);
lean_ctor_set(v___x_322_, 1, v___x_321_);
v___x_323_ = lean_alloc_ctor(5, 2, 0);
lean_ctor_set(v___x_323_, 0, v___x_322_);
lean_ctor_set(v___x_323_, 1, v___x_275_);
v___x_324_ = lean_unsigned_to_nat(0u);
v___x_325_ = l_Float_repr(v_gpa_274_, v___x_324_);
v___x_326_ = lean_alloc_ctor(4, 2, 0);
lean_ctor_set(v___x_326_, 0, v___x_291_);
lean_ctor_set(v___x_326_, 1, v___x_325_);
v___x_327_ = lean_alloc_ctor(6, 1, 1);
lean_ctor_set(v___x_327_, 0, v___x_326_);
lean_ctor_set_uint8(v___x_327_, sizeof(void*)*1, v___x_281_);
v___x_328_ = lean_alloc_ctor(5, 2, 0);
lean_ctor_set(v___x_328_, 0, v___x_323_);
lean_ctor_set(v___x_328_, 1, v___x_327_);
v___x_329_ = lean_obj_once(&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_instReprPerson_repr___redArg___closed__15, &lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_instReprPerson_repr___redArg___closed__15_once, _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_instReprPerson_repr___redArg___closed__15);
v___x_330_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_instReprPerson_repr___redArg___closed__16));
v___x_331_ = lean_alloc_ctor(5, 2, 0);
lean_ctor_set(v___x_331_, 0, v___x_330_);
lean_ctor_set(v___x_331_, 1, v___x_328_);
v___x_332_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_instReprPerson_repr___redArg___closed__17));
v___x_333_ = lean_alloc_ctor(5, 2, 0);
lean_ctor_set(v___x_333_, 0, v___x_331_);
lean_ctor_set(v___x_333_, 1, v___x_332_);
v___x_334_ = lean_alloc_ctor(4, 2, 0);
lean_ctor_set(v___x_334_, 0, v___x_329_);
lean_ctor_set(v___x_334_, 1, v___x_333_);
v___x_335_ = lean_alloc_ctor(6, 1, 1);
lean_ctor_set(v___x_335_, 0, v___x_334_);
lean_ctor_set_uint8(v___x_335_, sizeof(void*)*1, v___x_281_);
return v___x_335_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_instReprStudent_repr(lean_object* v_x_336_, lean_object* v_prec_337_){
_start:
{
lean_object* v___x_338_; 
v___x_338_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_instReprStudent_repr___redArg(v_x_336_);
return v___x_338_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_instReprStudent_repr___boxed(lean_object* v_x_339_, lean_object* v_prec_340_){
_start:
{
lean_object* v_res_341_; 
v_res_341_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_instReprStudent_repr(v_x_339_, v_prec_340_);
lean_dec(v_prec_340_);
return v_res_341_;
}
}
static double _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_student1___closed__1(void){
_start:
{
lean_object* v___x_345_; uint8_t v___x_346_; lean_object* v___x_347_; double v___x_348_; 
v___x_345_ = lean_unsigned_to_nat(1u);
v___x_346_ = 1;
v___x_347_ = lean_unsigned_to_nat(38u);
v___x_348_ = l_Float_ofScientific(v___x_347_, v___x_346_, v___x_345_);
return v___x_348_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_student1___closed__2(void){
_start:
{
double v___x_349_; lean_object* v___x_350_; lean_object* v___x_351_; lean_object* v___x_352_; lean_object* v___x_353_; lean_object* v___x_354_; 
v___x_349_ = lean_float_once(&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_student1___closed__1, &lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_student1___closed__1_once, _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_student1___closed__1);
v___x_350_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_student1___closed__0));
v___x_351_ = lean_unsigned_to_nat(2023001u);
v___x_352_ = lean_unsigned_to_nat(20u);
v___x_353_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_alice___closed__0));
v___x_354_ = lean_alloc_ctor(0, 4, 8);
lean_ctor_set(v___x_354_, 0, v___x_353_);
lean_ctor_set(v___x_354_, 1, v___x_352_);
lean_ctor_set(v___x_354_, 2, v___x_351_);
lean_ctor_set(v___x_354_, 3, v___x_350_);
lean_ctor_set_float(v___x_354_, sizeof(void*)*4, v___x_349_);
return v___x_354_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_student1(void){
_start:
{
lean_object* v___x_355_; 
v___x_355_ = lean_obj_once(&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_student1___closed__2, &lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_student1___closed__2_once, _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_student1___closed__2);
return v___x_355_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_student__name(void){
_start:
{
lean_object* v___x_356_; lean_object* v_name_357_; 
v___x_356_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_student1;
v_name_357_ = lean_ctor_get(v___x_356_, 0);
lean_inc_ref(v_name_357_);
return v_name_357_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_student__major(void){
_start:
{
lean_object* v___x_358_; lean_object* v_major_359_; 
v___x_358_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_student1;
v_major_359_ = lean_ctor_get(v___x_358_, 3);
lean_inc_ref(v_major_359_);
return v_major_359_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_instReprAddress_repr___redArg___closed__4(void){
_start:
{
lean_object* v___x_369_; lean_object* v___x_370_; 
v___x_369_ = lean_unsigned_to_nat(10u);
v___x_370_ = lean_nat_to_int(v___x_369_);
return v___x_370_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_instReprAddress_repr___redArg(lean_object* v_x_377_){
_start:
{
lean_object* v_street_378_; lean_object* v_city_379_; lean_object* v_zip_380_; lean_object* v___x_381_; lean_object* v___x_382_; lean_object* v___x_383_; lean_object* v___x_384_; lean_object* v___x_385_; lean_object* v___x_386_; uint8_t v___x_387_; lean_object* v___x_388_; lean_object* v___x_389_; lean_object* v___x_390_; lean_object* v___x_391_; lean_object* v___x_392_; lean_object* v___x_393_; lean_object* v___x_394_; lean_object* v___x_395_; lean_object* v___x_396_; lean_object* v___x_397_; lean_object* v___x_398_; lean_object* v___x_399_; lean_object* v___x_400_; lean_object* v___x_401_; lean_object* v___x_402_; lean_object* v___x_403_; lean_object* v___x_404_; lean_object* v___x_405_; lean_object* v___x_406_; lean_object* v___x_407_; lean_object* v___x_408_; lean_object* v___x_409_; lean_object* v___x_410_; lean_object* v___x_411_; lean_object* v___x_412_; lean_object* v___x_413_; lean_object* v___x_414_; lean_object* v___x_415_; lean_object* v___x_416_; lean_object* v___x_417_; lean_object* v___x_418_; lean_object* v___x_419_; lean_object* v___x_420_; 
v_street_378_ = lean_ctor_get(v_x_377_, 0);
lean_inc_ref(v_street_378_);
v_city_379_ = lean_ctor_get(v_x_377_, 1);
lean_inc_ref(v_city_379_);
v_zip_380_ = lean_ctor_get(v_x_377_, 2);
lean_inc(v_zip_380_);
lean_dec_ref(v_x_377_);
v___x_381_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_instReprPerson_repr___redArg___closed__5));
v___x_382_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_instReprAddress_repr___redArg___closed__3));
v___x_383_ = lean_obj_once(&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_instReprAddress_repr___redArg___closed__4, &lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_instReprAddress_repr___redArg___closed__4_once, _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_instReprAddress_repr___redArg___closed__4);
v___x_384_ = l_String_quote(v_street_378_);
v___x_385_ = lean_alloc_ctor(3, 1, 0);
lean_ctor_set(v___x_385_, 0, v___x_384_);
v___x_386_ = lean_alloc_ctor(4, 2, 0);
lean_ctor_set(v___x_386_, 0, v___x_383_);
lean_ctor_set(v___x_386_, 1, v___x_385_);
v___x_387_ = 0;
v___x_388_ = lean_alloc_ctor(6, 1, 1);
lean_ctor_set(v___x_388_, 0, v___x_386_);
lean_ctor_set_uint8(v___x_388_, sizeof(void*)*1, v___x_387_);
v___x_389_ = lean_alloc_ctor(5, 2, 0);
lean_ctor_set(v___x_389_, 0, v___x_382_);
lean_ctor_set(v___x_389_, 1, v___x_388_);
v___x_390_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_instReprPerson_repr___redArg___closed__9));
v___x_391_ = lean_alloc_ctor(5, 2, 0);
lean_ctor_set(v___x_391_, 0, v___x_389_);
lean_ctor_set(v___x_391_, 1, v___x_390_);
v___x_392_ = lean_box(1);
v___x_393_ = lean_alloc_ctor(5, 2, 0);
lean_ctor_set(v___x_393_, 0, v___x_391_);
lean_ctor_set(v___x_393_, 1, v___x_392_);
v___x_394_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_instReprAddress_repr___redArg___closed__6));
v___x_395_ = lean_alloc_ctor(5, 2, 0);
lean_ctor_set(v___x_395_, 0, v___x_393_);
lean_ctor_set(v___x_395_, 1, v___x_394_);
v___x_396_ = lean_alloc_ctor(5, 2, 0);
lean_ctor_set(v___x_396_, 0, v___x_395_);
lean_ctor_set(v___x_396_, 1, v___x_381_);
v___x_397_ = lean_obj_once(&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_instReprPerson_repr___redArg___closed__7, &lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_instReprPerson_repr___redArg___closed__7_once, _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_instReprPerson_repr___redArg___closed__7);
v___x_398_ = l_String_quote(v_city_379_);
v___x_399_ = lean_alloc_ctor(3, 1, 0);
lean_ctor_set(v___x_399_, 0, v___x_398_);
v___x_400_ = lean_alloc_ctor(4, 2, 0);
lean_ctor_set(v___x_400_, 0, v___x_397_);
lean_ctor_set(v___x_400_, 1, v___x_399_);
v___x_401_ = lean_alloc_ctor(6, 1, 1);
lean_ctor_set(v___x_401_, 0, v___x_400_);
lean_ctor_set_uint8(v___x_401_, sizeof(void*)*1, v___x_387_);
v___x_402_ = lean_alloc_ctor(5, 2, 0);
lean_ctor_set(v___x_402_, 0, v___x_396_);
lean_ctor_set(v___x_402_, 1, v___x_401_);
v___x_403_ = lean_alloc_ctor(5, 2, 0);
lean_ctor_set(v___x_403_, 0, v___x_402_);
lean_ctor_set(v___x_403_, 1, v___x_390_);
v___x_404_ = lean_alloc_ctor(5, 2, 0);
lean_ctor_set(v___x_404_, 0, v___x_403_);
lean_ctor_set(v___x_404_, 1, v___x_392_);
v___x_405_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_instReprAddress_repr___redArg___closed__8));
v___x_406_ = lean_alloc_ctor(5, 2, 0);
lean_ctor_set(v___x_406_, 0, v___x_404_);
lean_ctor_set(v___x_406_, 1, v___x_405_);
v___x_407_ = lean_alloc_ctor(5, 2, 0);
lean_ctor_set(v___x_407_, 0, v___x_406_);
lean_ctor_set(v___x_407_, 1, v___x_381_);
v___x_408_ = lean_obj_once(&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_instReprPerson_repr___redArg___closed__12, &lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_instReprPerson_repr___redArg___closed__12_once, _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_instReprPerson_repr___redArg___closed__12);
v___x_409_ = l_Nat_reprFast(v_zip_380_);
v___x_410_ = lean_alloc_ctor(3, 1, 0);
lean_ctor_set(v___x_410_, 0, v___x_409_);
v___x_411_ = lean_alloc_ctor(4, 2, 0);
lean_ctor_set(v___x_411_, 0, v___x_408_);
lean_ctor_set(v___x_411_, 1, v___x_410_);
v___x_412_ = lean_alloc_ctor(6, 1, 1);
lean_ctor_set(v___x_412_, 0, v___x_411_);
lean_ctor_set_uint8(v___x_412_, sizeof(void*)*1, v___x_387_);
v___x_413_ = lean_alloc_ctor(5, 2, 0);
lean_ctor_set(v___x_413_, 0, v___x_407_);
lean_ctor_set(v___x_413_, 1, v___x_412_);
v___x_414_ = lean_obj_once(&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_instReprPerson_repr___redArg___closed__15, &lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_instReprPerson_repr___redArg___closed__15_once, _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_instReprPerson_repr___redArg___closed__15);
v___x_415_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_instReprPerson_repr___redArg___closed__16));
v___x_416_ = lean_alloc_ctor(5, 2, 0);
lean_ctor_set(v___x_416_, 0, v___x_415_);
lean_ctor_set(v___x_416_, 1, v___x_413_);
v___x_417_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_instReprPerson_repr___redArg___closed__17));
v___x_418_ = lean_alloc_ctor(5, 2, 0);
lean_ctor_set(v___x_418_, 0, v___x_416_);
lean_ctor_set(v___x_418_, 1, v___x_417_);
v___x_419_ = lean_alloc_ctor(4, 2, 0);
lean_ctor_set(v___x_419_, 0, v___x_414_);
lean_ctor_set(v___x_419_, 1, v___x_418_);
v___x_420_ = lean_alloc_ctor(6, 1, 1);
lean_ctor_set(v___x_420_, 0, v___x_419_);
lean_ctor_set_uint8(v___x_420_, sizeof(void*)*1, v___x_387_);
return v___x_420_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_instReprAddress_repr(lean_object* v_x_421_, lean_object* v_prec_422_){
_start:
{
lean_object* v___x_423_; 
v___x_423_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_instReprAddress_repr___redArg(v_x_421_);
return v___x_423_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_instReprAddress_repr___boxed(lean_object* v_x_424_, lean_object* v_prec_425_){
_start:
{
lean_object* v_res_426_; 
v_res_426_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_instReprAddress_repr(v_x_424_, v_prec_425_);
lean_dec(v_prec_425_);
return v_res_426_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_instReprPersonWithAddress_repr___redArg___closed__2(void){
_start:
{
lean_object* v___x_432_; lean_object* v___x_433_; 
v___x_432_ = lean_unsigned_to_nat(11u);
v___x_433_ = lean_nat_to_int(v___x_432_);
return v___x_433_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_instReprPersonWithAddress_repr___redArg(lean_object* v_x_434_){
_start:
{
lean_object* v_name_435_; lean_object* v_age_436_; lean_object* v_address_437_; lean_object* v___x_438_; lean_object* v___x_439_; lean_object* v___x_440_; lean_object* v___x_441_; lean_object* v___x_442_; lean_object* v___x_443_; uint8_t v___x_444_; lean_object* v___x_445_; lean_object* v___x_446_; lean_object* v___x_447_; lean_object* v___x_448_; lean_object* v___x_449_; lean_object* v___x_450_; lean_object* v___x_451_; lean_object* v___x_452_; lean_object* v___x_453_; lean_object* v___x_454_; lean_object* v___x_455_; lean_object* v___x_456_; lean_object* v___x_457_; lean_object* v___x_458_; lean_object* v___x_459_; lean_object* v___x_460_; lean_object* v___x_461_; lean_object* v___x_462_; lean_object* v___x_463_; lean_object* v___x_464_; lean_object* v___x_465_; lean_object* v___x_466_; lean_object* v___x_467_; lean_object* v___x_468_; lean_object* v___x_469_; lean_object* v___x_470_; lean_object* v___x_471_; lean_object* v___x_472_; lean_object* v___x_473_; lean_object* v___x_474_; lean_object* v___x_475_; lean_object* v___x_476_; 
v_name_435_ = lean_ctor_get(v_x_434_, 0);
lean_inc_ref(v_name_435_);
v_age_436_ = lean_ctor_get(v_x_434_, 1);
lean_inc(v_age_436_);
v_address_437_ = lean_ctor_get(v_x_434_, 2);
lean_inc_ref(v_address_437_);
lean_dec_ref(v_x_434_);
v___x_438_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_instReprPerson_repr___redArg___closed__5));
v___x_439_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_instReprPerson_repr___redArg___closed__6));
v___x_440_ = lean_obj_once(&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_instReprPerson_repr___redArg___closed__7, &lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_instReprPerson_repr___redArg___closed__7_once, _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_instReprPerson_repr___redArg___closed__7);
v___x_441_ = l_String_quote(v_name_435_);
v___x_442_ = lean_alloc_ctor(3, 1, 0);
lean_ctor_set(v___x_442_, 0, v___x_441_);
v___x_443_ = lean_alloc_ctor(4, 2, 0);
lean_ctor_set(v___x_443_, 0, v___x_440_);
lean_ctor_set(v___x_443_, 1, v___x_442_);
v___x_444_ = 0;
v___x_445_ = lean_alloc_ctor(6, 1, 1);
lean_ctor_set(v___x_445_, 0, v___x_443_);
lean_ctor_set_uint8(v___x_445_, sizeof(void*)*1, v___x_444_);
v___x_446_ = lean_alloc_ctor(5, 2, 0);
lean_ctor_set(v___x_446_, 0, v___x_439_);
lean_ctor_set(v___x_446_, 1, v___x_445_);
v___x_447_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_instReprPerson_repr___redArg___closed__9));
v___x_448_ = lean_alloc_ctor(5, 2, 0);
lean_ctor_set(v___x_448_, 0, v___x_446_);
lean_ctor_set(v___x_448_, 1, v___x_447_);
v___x_449_ = lean_box(1);
v___x_450_ = lean_alloc_ctor(5, 2, 0);
lean_ctor_set(v___x_450_, 0, v___x_448_);
lean_ctor_set(v___x_450_, 1, v___x_449_);
v___x_451_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_instReprPerson_repr___redArg___closed__11));
v___x_452_ = lean_alloc_ctor(5, 2, 0);
lean_ctor_set(v___x_452_, 0, v___x_450_);
lean_ctor_set(v___x_452_, 1, v___x_451_);
v___x_453_ = lean_alloc_ctor(5, 2, 0);
lean_ctor_set(v___x_453_, 0, v___x_452_);
lean_ctor_set(v___x_453_, 1, v___x_438_);
v___x_454_ = lean_obj_once(&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_instReprPerson_repr___redArg___closed__12, &lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_instReprPerson_repr___redArg___closed__12_once, _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_instReprPerson_repr___redArg___closed__12);
v___x_455_ = l_Nat_reprFast(v_age_436_);
v___x_456_ = lean_alloc_ctor(3, 1, 0);
lean_ctor_set(v___x_456_, 0, v___x_455_);
v___x_457_ = lean_alloc_ctor(4, 2, 0);
lean_ctor_set(v___x_457_, 0, v___x_454_);
lean_ctor_set(v___x_457_, 1, v___x_456_);
v___x_458_ = lean_alloc_ctor(6, 1, 1);
lean_ctor_set(v___x_458_, 0, v___x_457_);
lean_ctor_set_uint8(v___x_458_, sizeof(void*)*1, v___x_444_);
v___x_459_ = lean_alloc_ctor(5, 2, 0);
lean_ctor_set(v___x_459_, 0, v___x_453_);
lean_ctor_set(v___x_459_, 1, v___x_458_);
v___x_460_ = lean_alloc_ctor(5, 2, 0);
lean_ctor_set(v___x_460_, 0, v___x_459_);
lean_ctor_set(v___x_460_, 1, v___x_447_);
v___x_461_ = lean_alloc_ctor(5, 2, 0);
lean_ctor_set(v___x_461_, 0, v___x_460_);
lean_ctor_set(v___x_461_, 1, v___x_449_);
v___x_462_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_instReprPersonWithAddress_repr___redArg___closed__1));
v___x_463_ = lean_alloc_ctor(5, 2, 0);
lean_ctor_set(v___x_463_, 0, v___x_461_);
lean_ctor_set(v___x_463_, 1, v___x_462_);
v___x_464_ = lean_alloc_ctor(5, 2, 0);
lean_ctor_set(v___x_464_, 0, v___x_463_);
lean_ctor_set(v___x_464_, 1, v___x_438_);
v___x_465_ = lean_obj_once(&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_instReprPersonWithAddress_repr___redArg___closed__2, &lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_instReprPersonWithAddress_repr___redArg___closed__2_once, _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_instReprPersonWithAddress_repr___redArg___closed__2);
v___x_466_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_instReprAddress_repr___redArg(v_address_437_);
v___x_467_ = lean_alloc_ctor(4, 2, 0);
lean_ctor_set(v___x_467_, 0, v___x_465_);
lean_ctor_set(v___x_467_, 1, v___x_466_);
v___x_468_ = lean_alloc_ctor(6, 1, 1);
lean_ctor_set(v___x_468_, 0, v___x_467_);
lean_ctor_set_uint8(v___x_468_, sizeof(void*)*1, v___x_444_);
v___x_469_ = lean_alloc_ctor(5, 2, 0);
lean_ctor_set(v___x_469_, 0, v___x_464_);
lean_ctor_set(v___x_469_, 1, v___x_468_);
v___x_470_ = lean_obj_once(&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_instReprPerson_repr___redArg___closed__15, &lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_instReprPerson_repr___redArg___closed__15_once, _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_instReprPerson_repr___redArg___closed__15);
v___x_471_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_instReprPerson_repr___redArg___closed__16));
v___x_472_ = lean_alloc_ctor(5, 2, 0);
lean_ctor_set(v___x_472_, 0, v___x_471_);
lean_ctor_set(v___x_472_, 1, v___x_469_);
v___x_473_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_instReprPerson_repr___redArg___closed__17));
v___x_474_ = lean_alloc_ctor(5, 2, 0);
lean_ctor_set(v___x_474_, 0, v___x_472_);
lean_ctor_set(v___x_474_, 1, v___x_473_);
v___x_475_ = lean_alloc_ctor(4, 2, 0);
lean_ctor_set(v___x_475_, 0, v___x_470_);
lean_ctor_set(v___x_475_, 1, v___x_474_);
v___x_476_ = lean_alloc_ctor(6, 1, 1);
lean_ctor_set(v___x_476_, 0, v___x_475_);
lean_ctor_set_uint8(v___x_476_, sizeof(void*)*1, v___x_444_);
return v___x_476_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_instReprPersonWithAddress_repr(lean_object* v_x_477_, lean_object* v_prec_478_){
_start:
{
lean_object* v___x_479_; 
v___x_479_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_instReprPersonWithAddress_repr___redArg(v_x_477_);
return v___x_479_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_instReprPersonWithAddress_repr___boxed(lean_object* v_x_480_, lean_object* v_prec_481_){
_start:
{
lean_object* v_res_482_; 
v_res_482_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_instReprPersonWithAddress_repr(v_x_480_, v_prec_481_);
lean_dec(v_prec_481_);
return v_res_482_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_person__city(void){
_start:
{
lean_object* v___x_496_; lean_object* v_address_497_; lean_object* v_city_498_; 
v___x_496_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_person__with__addr));
v_address_497_ = lean_ctor_get(v___x_496_, 2);
v_city_498_ = lean_ctor_get(v_address_497_, 1);
lean_inc_ref(v_city_498_);
return v_city_498_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_person__zip(void){
_start:
{
lean_object* v___x_499_; lean_object* v_address_500_; lean_object* v_zip_501_; 
v___x_499_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_person__with__addr));
v_address_500_ = lean_ctor_get(v___x_499_, 2);
v_zip_501_ = lean_ctor_get(v_address_500_, 2);
lean_inc(v_zip_501_);
return v_zip_501_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_Person_toString(lean_object* v_p_505_){
_start:
{
lean_object* v_name_506_; lean_object* v_age_507_; lean_object* v___x_508_; lean_object* v___x_509_; lean_object* v___x_510_; lean_object* v___x_511_; lean_object* v___x_512_; lean_object* v___x_513_; lean_object* v___x_514_; lean_object* v___x_515_; 
v_name_506_ = lean_ctor_get(v_p_505_, 0);
lean_inc_ref(v_name_506_);
v_age_507_ = lean_ctor_get(v_p_505_, 1);
lean_inc(v_age_507_);
lean_dec_ref(v_p_505_);
v___x_508_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_Person_toString___closed__0));
v___x_509_ = lean_string_append(v___x_508_, v_name_506_);
lean_dec_ref(v_name_506_);
v___x_510_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_Person_toString___closed__1));
v___x_511_ = lean_string_append(v___x_509_, v___x_510_);
v___x_512_ = l_Nat_reprFast(v_age_507_);
v___x_513_ = lean_string_append(v___x_511_, v___x_512_);
lean_dec_ref(v___x_512_);
v___x_514_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_Person_toString___closed__2));
v___x_515_ = lean_string_append(v___x_513_, v___x_514_);
return v___x_515_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_alice__str___closed__0(void){
_start:
{
lean_object* v___x_516_; lean_object* v___x_517_; 
v___x_516_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_alice));
v___x_517_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_Person_toString(v___x_516_);
return v___x_517_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_alice__str(void){
_start:
{
lean_object* v___x_518_; 
v___x_518_ = lean_obj_once(&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_alice__str___closed__0, &lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_alice__str___closed__0_once, _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_alice__str___closed__0);
return v___x_518_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_instAddPoint___lam__0(lean_object* v_p1_519_, lean_object* v_p2_520_){
_start:
{
lean_object* v_x_521_; lean_object* v_y_522_; lean_object* v_x_523_; lean_object* v_y_524_; lean_object* v___x_526_; uint8_t v_isShared_527_; uint8_t v_isSharedCheck_533_; 
v_x_521_ = lean_ctor_get(v_p1_519_, 0);
v_y_522_ = lean_ctor_get(v_p1_519_, 1);
v_x_523_ = lean_ctor_get(v_p2_520_, 0);
v_y_524_ = lean_ctor_get(v_p2_520_, 1);
v_isSharedCheck_533_ = !lean_is_exclusive(v_p2_520_);
if (v_isSharedCheck_533_ == 0)
{
v___x_526_ = v_p2_520_;
v_isShared_527_ = v_isSharedCheck_533_;
goto v_resetjp_525_;
}
else
{
lean_inc(v_y_524_);
lean_inc(v_x_523_);
lean_dec(v_p2_520_);
v___x_526_ = lean_box(0);
v_isShared_527_ = v_isSharedCheck_533_;
goto v_resetjp_525_;
}
v_resetjp_525_:
{
lean_object* v___x_528_; lean_object* v___x_529_; lean_object* v___x_531_; 
v___x_528_ = lean_nat_add(v_x_521_, v_x_523_);
lean_dec(v_x_523_);
v___x_529_ = lean_nat_add(v_y_522_, v_y_524_);
lean_dec(v_y_524_);
if (v_isShared_527_ == 0)
{
lean_ctor_set(v___x_526_, 1, v___x_529_);
lean_ctor_set(v___x_526_, 0, v___x_528_);
v___x_531_ = v___x_526_;
goto v_reusejp_530_;
}
else
{
lean_object* v_reuseFailAlloc_532_; 
v_reuseFailAlloc_532_ = lean_alloc_ctor(0, 2, 0);
lean_ctor_set(v_reuseFailAlloc_532_, 0, v___x_528_);
lean_ctor_set(v_reuseFailAlloc_532_, 1, v___x_529_);
v___x_531_ = v_reuseFailAlloc_532_;
goto v_reusejp_530_;
}
v_reusejp_530_:
{
return v___x_531_;
}
}
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_instAddPoint___lam__0___boxed(lean_object* v_p1_534_, lean_object* v_p2_535_){
_start:
{
lean_object* v_res_536_; 
v_res_536_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_instAddPoint___lam__0(v_p1_534_, v_p2_535_);
lean_dec_ref(v_p1_534_);
return v_res_536_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_instReprPosNat_repr___redArg(lean_object* v_x_560_){
_start:
{
lean_object* v___x_561_; lean_object* v___x_562_; lean_object* v___x_563_; lean_object* v___x_564_; lean_object* v___x_565_; lean_object* v___x_566_; uint8_t v___x_567_; lean_object* v___x_568_; lean_object* v___x_569_; lean_object* v___x_570_; lean_object* v___x_571_; lean_object* v___x_572_; lean_object* v___x_573_; lean_object* v___x_574_; lean_object* v___x_575_; lean_object* v___x_576_; lean_object* v___x_577_; lean_object* v___x_578_; lean_object* v___x_579_; lean_object* v___x_580_; lean_object* v___x_581_; lean_object* v___x_582_; lean_object* v___x_583_; lean_object* v___x_584_; lean_object* v___x_585_; 
v___x_561_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_instReprPerson_repr___redArg___closed__5));
v___x_562_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_instReprPosNat_repr___redArg___closed__3));
v___x_563_ = lean_obj_once(&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_instReprPerson_repr___redArg___closed__12, &lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_instReprPerson_repr___redArg___closed__12_once, _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_instReprPerson_repr___redArg___closed__12);
v___x_564_ = l_Nat_reprFast(v_x_560_);
v___x_565_ = lean_alloc_ctor(3, 1, 0);
lean_ctor_set(v___x_565_, 0, v___x_564_);
v___x_566_ = lean_alloc_ctor(4, 2, 0);
lean_ctor_set(v___x_566_, 0, v___x_563_);
lean_ctor_set(v___x_566_, 1, v___x_565_);
v___x_567_ = 0;
v___x_568_ = lean_alloc_ctor(6, 1, 1);
lean_ctor_set(v___x_568_, 0, v___x_566_);
lean_ctor_set_uint8(v___x_568_, sizeof(void*)*1, v___x_567_);
v___x_569_ = lean_alloc_ctor(5, 2, 0);
lean_ctor_set(v___x_569_, 0, v___x_562_);
lean_ctor_set(v___x_569_, 1, v___x_568_);
v___x_570_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_instReprPerson_repr___redArg___closed__9));
v___x_571_ = lean_alloc_ctor(5, 2, 0);
lean_ctor_set(v___x_571_, 0, v___x_569_);
lean_ctor_set(v___x_571_, 1, v___x_570_);
v___x_572_ = lean_box(1);
v___x_573_ = lean_alloc_ctor(5, 2, 0);
lean_ctor_set(v___x_573_, 0, v___x_571_);
lean_ctor_set(v___x_573_, 1, v___x_572_);
v___x_574_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_instReprPosNat_repr___redArg___closed__5));
v___x_575_ = lean_alloc_ctor(5, 2, 0);
lean_ctor_set(v___x_575_, 0, v___x_573_);
lean_ctor_set(v___x_575_, 1, v___x_574_);
v___x_576_ = lean_alloc_ctor(5, 2, 0);
lean_ctor_set(v___x_576_, 0, v___x_575_);
lean_ctor_set(v___x_576_, 1, v___x_561_);
v___x_577_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_instReprPosNat_repr___redArg___closed__7));
v___x_578_ = lean_alloc_ctor(5, 2, 0);
lean_ctor_set(v___x_578_, 0, v___x_576_);
lean_ctor_set(v___x_578_, 1, v___x_577_);
v___x_579_ = lean_obj_once(&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_instReprPerson_repr___redArg___closed__15, &lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_instReprPerson_repr___redArg___closed__15_once, _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_instReprPerson_repr___redArg___closed__15);
v___x_580_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_instReprPerson_repr___redArg___closed__16));
v___x_581_ = lean_alloc_ctor(5, 2, 0);
lean_ctor_set(v___x_581_, 0, v___x_580_);
lean_ctor_set(v___x_581_, 1, v___x_578_);
v___x_582_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_instReprPerson_repr___redArg___closed__17));
v___x_583_ = lean_alloc_ctor(5, 2, 0);
lean_ctor_set(v___x_583_, 0, v___x_581_);
lean_ctor_set(v___x_583_, 1, v___x_582_);
v___x_584_ = lean_alloc_ctor(4, 2, 0);
lean_ctor_set(v___x_584_, 0, v___x_579_);
lean_ctor_set(v___x_584_, 1, v___x_583_);
v___x_585_ = lean_alloc_ctor(6, 1, 1);
lean_ctor_set(v___x_585_, 0, v___x_584_);
lean_ctor_set_uint8(v___x_585_, sizeof(void*)*1, v___x_567_);
return v___x_585_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_instReprPosNat_repr(lean_object* v_x_586_, lean_object* v_prec_587_){
_start:
{
lean_object* v___x_588_; 
v___x_588_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_instReprPosNat_repr___redArg(v_x_586_);
return v___x_588_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_instReprPosNat_repr___boxed(lean_object* v_x_589_, lean_object* v_prec_590_){
_start:
{
lean_object* v_res_591_; 
v_res_591_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_instReprPosNat_repr(v_x_589_, v_prec_590_);
lean_dec(v_prec_590_);
return v_res_591_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_five__pos(void){
_start:
{
lean_object* v___x_594_; 
v___x_594_ = lean_unsigned_to_nat(5u);
return v___x_594_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_ten__pos(void){
_start:
{
lean_object* v___x_595_; 
v___x_595_ = lean_unsigned_to_nat(10u);
return v___x_595_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_five__val(void){
_start:
{
lean_object* v___x_596_; 
v___x_596_ = lean_unsigned_to_nat(5u);
return v___x_596_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_PosNat_add(lean_object* v_a_597_, lean_object* v_b_598_){
_start:
{
lean_object* v___x_599_; 
v___x_599_ = lean_nat_add(v_a_597_, v_b_598_);
return v___x_599_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_PosNat_add___boxed(lean_object* v_a_600_, lean_object* v_b_601_){
_start:
{
lean_object* v_res_602_; 
v_res_602_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_PosNat_add(v_a_600_, v_b_601_);
lean_dec(v_b_601_);
lean_dec(v_a_600_);
return v_res_602_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_five__plus__ten(void){
_start:
{
lean_object* v___x_603_; 
v___x_603_ = lean_unsigned_to_nat(15u);
return v___x_603_;
}
}
lean_object* initialize_Init(uint8_t builtin);
lean_object* initialize_Init(uint8_t builtin);
static bool _G_initialized = false;
LEAN_EXPORT lean_object* initialize_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures(uint8_t builtin) {
lean_object * res;
if (_G_initialized) return lean_io_result_mk_ok(lean_box(0));
_G_initialized = true;
res = initialize_Init(builtin);
if (lean_io_result_is_error(res)) return res;
lean_dec_ref(res);
res = initialize_Init(builtin);
if (lean_io_result_is_error(res)) return res;
lean_dec_ref(res);
lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_alice__name = _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_alice__name();
lean_mark_persistent(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_alice__name);
lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_alice__age = _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_alice__age();
lean_mark_persistent(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_alice__age);
lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_bob__name = _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_bob__name();
lean_mark_persistent(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_bob__name);
lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_bob__age = _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_bob__age();
lean_mark_persistent(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_bob__age);
lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_alice__next__year = _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_alice__next__year();
lean_mark_persistent(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_alice__next__year);
lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_alice__greet = _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_alice__greet();
lean_mark_persistent(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_alice__greet);
lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_alice__adult = _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_alice__adult();
lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_student1 = _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_student1();
lean_mark_persistent(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_student1);
lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_student__name = _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_student__name();
lean_mark_persistent(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_student__name);
lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_student__major = _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_student__major();
lean_mark_persistent(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_student__major);
lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_person__city = _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_person__city();
lean_mark_persistent(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_person__city);
lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_person__zip = _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_person__zip();
lean_mark_persistent(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_person__zip);
lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_alice__str = _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_alice__str();
lean_mark_persistent(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_alice__str);
lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_five__pos = _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_five__pos();
lean_mark_persistent(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_five__pos);
lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_ten__pos = _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_ten__pos();
lean_mark_persistent(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_ten__pos);
lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_five__val = _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_five__val();
lean_mark_persistent(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_five__val);
lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_five__plus__ten = _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_five__plus__ten();
lean_mark_persistent(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Structures_BasicStructures_five__plus__ten);
return lean_io_result_mk_ok(lean_box(0));
}
#ifdef __cplusplus
}
#endif
