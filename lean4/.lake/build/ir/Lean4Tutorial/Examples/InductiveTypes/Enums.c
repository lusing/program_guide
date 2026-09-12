// Lean compiler output
// Module: Lean4Tutorial.Examples.InductiveTypes.Enums
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
lean_object* l_Repr_addAppParen(lean_object*, lean_object*);
uint8_t lean_nat_dec_le(lean_object*, lean_object*);
lean_object* lean_nat_to_int(lean_object*);
lean_object* lean_nat_mul(lean_object*, lean_object*);
uint8_t lean_nat_dec_le(lean_object*, lean_object*);
lean_object* l_Nat_reprFast(lean_object*);
uint8_t lean_nat_dec_eq(lean_object*, lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_Weekday_ctorIdx(uint8_t);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_Weekday_ctorIdx___boxed(lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_Weekday_toCtorIdx(uint8_t);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_Weekday_toCtorIdx___boxed(lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_Weekday_ctorElim___redArg(lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_Weekday_ctorElim___redArg___boxed(lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_Weekday_ctorElim(lean_object*, lean_object*, uint8_t, lean_object*, lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_Weekday_ctorElim___boxed(lean_object*, lean_object*, lean_object*, lean_object*, lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_Weekday_monday_elim___redArg(lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_Weekday_monday_elim___redArg___boxed(lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_Weekday_monday_elim(lean_object*, uint8_t, lean_object*, lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_Weekday_monday_elim___boxed(lean_object*, lean_object*, lean_object*, lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_Weekday_tuesday_elim___redArg(lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_Weekday_tuesday_elim___redArg___boxed(lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_Weekday_tuesday_elim(lean_object*, uint8_t, lean_object*, lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_Weekday_tuesday_elim___boxed(lean_object*, lean_object*, lean_object*, lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_Weekday_wednesday_elim___redArg(lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_Weekday_wednesday_elim___redArg___boxed(lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_Weekday_wednesday_elim(lean_object*, uint8_t, lean_object*, lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_Weekday_wednesday_elim___boxed(lean_object*, lean_object*, lean_object*, lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_Weekday_thursday_elim___redArg(lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_Weekday_thursday_elim___redArg___boxed(lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_Weekday_thursday_elim(lean_object*, uint8_t, lean_object*, lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_Weekday_thursday_elim___boxed(lean_object*, lean_object*, lean_object*, lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_Weekday_friday_elim___redArg(lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_Weekday_friday_elim___redArg___boxed(lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_Weekday_friday_elim(lean_object*, uint8_t, lean_object*, lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_Weekday_friday_elim___boxed(lean_object*, lean_object*, lean_object*, lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_Weekday_saturday_elim___redArg(lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_Weekday_saturday_elim___redArg___boxed(lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_Weekday_saturday_elim(lean_object*, uint8_t, lean_object*, lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_Weekday_saturday_elim___boxed(lean_object*, lean_object*, lean_object*, lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_Weekday_sunday_elim___redArg(lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_Weekday_sunday_elim___redArg___boxed(lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_Weekday_sunday_elim(lean_object*, uint8_t, lean_object*, lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_Weekday_sunday_elim___boxed(lean_object*, lean_object*, lean_object*, lean_object*);
static const lean_string_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_instReprWeekday_repr___closed__0_value = {.m_header = {.m_rc = 0, .m_cs_sz = 0, .m_other = 0, .m_tag = 249}, .m_size = 59, .m_capacity = 59, .m_length = 58, .m_data = "Lean4Tutorial.Examples.InductiveTypes.Enums.Weekday.monday"};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_instReprWeekday_repr___closed__0 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_instReprWeekday_repr___closed__0_value;
static const lean_ctor_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_instReprWeekday_repr___closed__1_value = {.m_header = {.m_rc = 0, .m_cs_sz = sizeof(lean_ctor_object) + sizeof(void*)*1 + 0, .m_other = 1, .m_tag = 3}, .m_objs = {((lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_instReprWeekday_repr___closed__0_value)}};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_instReprWeekday_repr___closed__1 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_instReprWeekday_repr___closed__1_value;
static const lean_string_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_instReprWeekday_repr___closed__2_value = {.m_header = {.m_rc = 0, .m_cs_sz = 0, .m_other = 0, .m_tag = 249}, .m_size = 60, .m_capacity = 60, .m_length = 59, .m_data = "Lean4Tutorial.Examples.InductiveTypes.Enums.Weekday.tuesday"};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_instReprWeekday_repr___closed__2 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_instReprWeekday_repr___closed__2_value;
static const lean_ctor_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_instReprWeekday_repr___closed__3_value = {.m_header = {.m_rc = 0, .m_cs_sz = sizeof(lean_ctor_object) + sizeof(void*)*1 + 0, .m_other = 1, .m_tag = 3}, .m_objs = {((lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_instReprWeekday_repr___closed__2_value)}};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_instReprWeekday_repr___closed__3 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_instReprWeekday_repr___closed__3_value;
static const lean_string_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_instReprWeekday_repr___closed__4_value = {.m_header = {.m_rc = 0, .m_cs_sz = 0, .m_other = 0, .m_tag = 249}, .m_size = 62, .m_capacity = 62, .m_length = 61, .m_data = "Lean4Tutorial.Examples.InductiveTypes.Enums.Weekday.wednesday"};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_instReprWeekday_repr___closed__4 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_instReprWeekday_repr___closed__4_value;
static const lean_ctor_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_instReprWeekday_repr___closed__5_value = {.m_header = {.m_rc = 0, .m_cs_sz = sizeof(lean_ctor_object) + sizeof(void*)*1 + 0, .m_other = 1, .m_tag = 3}, .m_objs = {((lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_instReprWeekday_repr___closed__4_value)}};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_instReprWeekday_repr___closed__5 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_instReprWeekday_repr___closed__5_value;
static const lean_string_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_instReprWeekday_repr___closed__6_value = {.m_header = {.m_rc = 0, .m_cs_sz = 0, .m_other = 0, .m_tag = 249}, .m_size = 61, .m_capacity = 61, .m_length = 60, .m_data = "Lean4Tutorial.Examples.InductiveTypes.Enums.Weekday.thursday"};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_instReprWeekday_repr___closed__6 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_instReprWeekday_repr___closed__6_value;
static const lean_ctor_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_instReprWeekday_repr___closed__7_value = {.m_header = {.m_rc = 0, .m_cs_sz = sizeof(lean_ctor_object) + sizeof(void*)*1 + 0, .m_other = 1, .m_tag = 3}, .m_objs = {((lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_instReprWeekday_repr___closed__6_value)}};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_instReprWeekday_repr___closed__7 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_instReprWeekday_repr___closed__7_value;
static const lean_string_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_instReprWeekday_repr___closed__8_value = {.m_header = {.m_rc = 0, .m_cs_sz = 0, .m_other = 0, .m_tag = 249}, .m_size = 59, .m_capacity = 59, .m_length = 58, .m_data = "Lean4Tutorial.Examples.InductiveTypes.Enums.Weekday.friday"};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_instReprWeekday_repr___closed__8 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_instReprWeekday_repr___closed__8_value;
static const lean_ctor_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_instReprWeekday_repr___closed__9_value = {.m_header = {.m_rc = 0, .m_cs_sz = sizeof(lean_ctor_object) + sizeof(void*)*1 + 0, .m_other = 1, .m_tag = 3}, .m_objs = {((lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_instReprWeekday_repr___closed__8_value)}};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_instReprWeekday_repr___closed__9 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_instReprWeekday_repr___closed__9_value;
static const lean_string_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_instReprWeekday_repr___closed__10_value = {.m_header = {.m_rc = 0, .m_cs_sz = 0, .m_other = 0, .m_tag = 249}, .m_size = 61, .m_capacity = 61, .m_length = 60, .m_data = "Lean4Tutorial.Examples.InductiveTypes.Enums.Weekday.saturday"};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_instReprWeekday_repr___closed__10 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_instReprWeekday_repr___closed__10_value;
static const lean_ctor_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_instReprWeekday_repr___closed__11_value = {.m_header = {.m_rc = 0, .m_cs_sz = sizeof(lean_ctor_object) + sizeof(void*)*1 + 0, .m_other = 1, .m_tag = 3}, .m_objs = {((lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_instReprWeekday_repr___closed__10_value)}};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_instReprWeekday_repr___closed__11 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_instReprWeekday_repr___closed__11_value;
static const lean_string_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_instReprWeekday_repr___closed__12_value = {.m_header = {.m_rc = 0, .m_cs_sz = 0, .m_other = 0, .m_tag = 249}, .m_size = 59, .m_capacity = 59, .m_length = 58, .m_data = "Lean4Tutorial.Examples.InductiveTypes.Enums.Weekday.sunday"};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_instReprWeekday_repr___closed__12 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_instReprWeekday_repr___closed__12_value;
static const lean_ctor_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_instReprWeekday_repr___closed__13_value = {.m_header = {.m_rc = 0, .m_cs_sz = sizeof(lean_ctor_object) + sizeof(void*)*1 + 0, .m_other = 1, .m_tag = 3}, .m_objs = {((lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_instReprWeekday_repr___closed__12_value)}};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_instReprWeekday_repr___closed__13 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_instReprWeekday_repr___closed__13_value;
static lean_once_cell_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_instReprWeekday_repr___closed__14_once = LEAN_ONCE_CELL_INITIALIZER;
static lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_instReprWeekday_repr___closed__14;
static lean_once_cell_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_instReprWeekday_repr___closed__15_once = LEAN_ONCE_CELL_INITIALIZER;
static lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_instReprWeekday_repr___closed__15;
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_instReprWeekday_repr(uint8_t, lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_instReprWeekday_repr___boxed(lean_object*, lean_object*);
static const lean_closure_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_instReprWeekday___closed__0_value = {.m_header = {.m_rc = 0, .m_cs_sz = sizeof(lean_closure_object) + sizeof(void*)*0, .m_other = 0, .m_tag = 245}, .m_fun = (void*)lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_instReprWeekday_repr___boxed, .m_arity = 2, .m_num_fixed = 0, .m_objs = {} };
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_instReprWeekday___closed__0 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_instReprWeekday___closed__0_value;
LEAN_EXPORT const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_instReprWeekday = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_instReprWeekday___closed__0_value;
LEAN_EXPORT uint8_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_Weekday_ofNat(lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_Weekday_ofNat___boxed(lean_object*);
LEAN_EXPORT uint8_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_instDecidableEqWeekday(uint8_t, uint8_t);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_instDecidableEqWeekday___boxed(lean_object*, lean_object*);
LEAN_EXPORT uint8_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_today;
LEAN_EXPORT uint8_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_weekend__start;
LEAN_EXPORT uint8_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_isWeekday(uint8_t);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_isWeekday___boxed(lean_object*);
LEAN_EXPORT uint8_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_isWeekend(uint8_t);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_isWeekend___boxed(lean_object*);
LEAN_EXPORT uint8_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_nextDay(uint8_t);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_nextDay___boxed(lean_object*);
LEAN_EXPORT uint8_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_prevDay(uint8_t);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_prevDay___boxed(lean_object*);
static lean_once_cell_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_monday__is__weekday___closed__0_once = LEAN_ONCE_CELL_INITIALIZER;
static uint8_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_monday__is__weekday___closed__0;
LEAN_EXPORT uint8_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_monday__is__weekday;
static lean_once_cell_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_saturday__is__weekend___closed__0_once = LEAN_ONCE_CELL_INITIALIZER;
static uint8_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_saturday__is__weekend___closed__0;
LEAN_EXPORT uint8_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_saturday__is__weekend;
static lean_once_cell_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_next__monday___closed__0_once = LEAN_ONCE_CELL_INITIALIZER;
static uint8_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_next__monday___closed__0;
LEAN_EXPORT uint8_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_next__monday;
static lean_once_cell_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_prev__monday___closed__0_once = LEAN_ONCE_CELL_INITIALIZER;
static uint8_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_prev__monday___closed__0;
LEAN_EXPORT uint8_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_prev__monday;
LEAN_EXPORT uint8_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_three__days__later(uint8_t);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_three__days__later___boxed(lean_object*);
static lean_once_cell_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_wed__plus__three___closed__0_once = LEAN_ONCE_CELL_INITIALIZER;
static uint8_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_wed__plus__three___closed__0;
LEAN_EXPORT uint8_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_wed__plus__three;
static const lean_string_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_Weekday_toString___closed__0_value = {.m_header = {.m_rc = 0, .m_cs_sz = 0, .m_other = 0, .m_tag = 249}, .m_size = 10, .m_capacity = 10, .m_length = 3, .m_data = "星期一"};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_Weekday_toString___closed__0 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_Weekday_toString___closed__0_value;
static const lean_string_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_Weekday_toString___closed__1_value = {.m_header = {.m_rc = 0, .m_cs_sz = 0, .m_other = 0, .m_tag = 249}, .m_size = 10, .m_capacity = 10, .m_length = 3, .m_data = "星期二"};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_Weekday_toString___closed__1 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_Weekday_toString___closed__1_value;
static const lean_string_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_Weekday_toString___closed__2_value = {.m_header = {.m_rc = 0, .m_cs_sz = 0, .m_other = 0, .m_tag = 249}, .m_size = 10, .m_capacity = 10, .m_length = 3, .m_data = "星期三"};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_Weekday_toString___closed__2 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_Weekday_toString___closed__2_value;
static const lean_string_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_Weekday_toString___closed__3_value = {.m_header = {.m_rc = 0, .m_cs_sz = 0, .m_other = 0, .m_tag = 249}, .m_size = 10, .m_capacity = 10, .m_length = 3, .m_data = "星期四"};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_Weekday_toString___closed__3 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_Weekday_toString___closed__3_value;
static const lean_string_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_Weekday_toString___closed__4_value = {.m_header = {.m_rc = 0, .m_cs_sz = 0, .m_other = 0, .m_tag = 249}, .m_size = 10, .m_capacity = 10, .m_length = 3, .m_data = "星期五"};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_Weekday_toString___closed__4 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_Weekday_toString___closed__4_value;
static const lean_string_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_Weekday_toString___closed__5_value = {.m_header = {.m_rc = 0, .m_cs_sz = 0, .m_other = 0, .m_tag = 249}, .m_size = 10, .m_capacity = 10, .m_length = 3, .m_data = "星期六"};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_Weekday_toString___closed__5 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_Weekday_toString___closed__5_value;
static const lean_string_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_Weekday_toString___closed__6_value = {.m_header = {.m_rc = 0, .m_cs_sz = 0, .m_other = 0, .m_tag = 249}, .m_size = 10, .m_capacity = 10, .m_length = 3, .m_data = "星期日"};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_Weekday_toString___closed__6 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_Weekday_toString___closed__6_value;
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_Weekday_toString(uint8_t);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_Weekday_toString___boxed(lean_object*);
static lean_once_cell_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_print__monday___closed__0_once = LEAN_ONCE_CELL_INITIALIZER;
static lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_print__monday___closed__0;
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_print__monday;
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_TrafficLight_ctorIdx(uint8_t);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_TrafficLight_ctorIdx___boxed(lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_TrafficLight_toCtorIdx(uint8_t);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_TrafficLight_toCtorIdx___boxed(lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_TrafficLight_ctorElim___redArg(lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_TrafficLight_ctorElim___redArg___boxed(lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_TrafficLight_ctorElim(lean_object*, lean_object*, uint8_t, lean_object*, lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_TrafficLight_ctorElim___boxed(lean_object*, lean_object*, lean_object*, lean_object*, lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_TrafficLight_red_elim___redArg(lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_TrafficLight_red_elim___redArg___boxed(lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_TrafficLight_red_elim(lean_object*, uint8_t, lean_object*, lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_TrafficLight_red_elim___boxed(lean_object*, lean_object*, lean_object*, lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_TrafficLight_yellow_elim___redArg(lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_TrafficLight_yellow_elim___redArg___boxed(lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_TrafficLight_yellow_elim(lean_object*, uint8_t, lean_object*, lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_TrafficLight_yellow_elim___boxed(lean_object*, lean_object*, lean_object*, lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_TrafficLight_green_elim___redArg(lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_TrafficLight_green_elim___redArg___boxed(lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_TrafficLight_green_elim(lean_object*, uint8_t, lean_object*, lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_TrafficLight_green_elim___boxed(lean_object*, lean_object*, lean_object*, lean_object*);
static const lean_string_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_instReprTrafficLight_repr___closed__0_value = {.m_header = {.m_rc = 0, .m_cs_sz = 0, .m_other = 0, .m_tag = 249}, .m_size = 61, .m_capacity = 61, .m_length = 60, .m_data = "Lean4Tutorial.Examples.InductiveTypes.Enums.TrafficLight.red"};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_instReprTrafficLight_repr___closed__0 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_instReprTrafficLight_repr___closed__0_value;
static const lean_ctor_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_instReprTrafficLight_repr___closed__1_value = {.m_header = {.m_rc = 0, .m_cs_sz = sizeof(lean_ctor_object) + sizeof(void*)*1 + 0, .m_other = 1, .m_tag = 3}, .m_objs = {((lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_instReprTrafficLight_repr___closed__0_value)}};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_instReprTrafficLight_repr___closed__1 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_instReprTrafficLight_repr___closed__1_value;
static const lean_string_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_instReprTrafficLight_repr___closed__2_value = {.m_header = {.m_rc = 0, .m_cs_sz = 0, .m_other = 0, .m_tag = 249}, .m_size = 64, .m_capacity = 64, .m_length = 63, .m_data = "Lean4Tutorial.Examples.InductiveTypes.Enums.TrafficLight.yellow"};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_instReprTrafficLight_repr___closed__2 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_instReprTrafficLight_repr___closed__2_value;
static const lean_ctor_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_instReprTrafficLight_repr___closed__3_value = {.m_header = {.m_rc = 0, .m_cs_sz = sizeof(lean_ctor_object) + sizeof(void*)*1 + 0, .m_other = 1, .m_tag = 3}, .m_objs = {((lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_instReprTrafficLight_repr___closed__2_value)}};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_instReprTrafficLight_repr___closed__3 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_instReprTrafficLight_repr___closed__3_value;
static const lean_string_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_instReprTrafficLight_repr___closed__4_value = {.m_header = {.m_rc = 0, .m_cs_sz = 0, .m_other = 0, .m_tag = 249}, .m_size = 63, .m_capacity = 63, .m_length = 62, .m_data = "Lean4Tutorial.Examples.InductiveTypes.Enums.TrafficLight.green"};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_instReprTrafficLight_repr___closed__4 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_instReprTrafficLight_repr___closed__4_value;
static const lean_ctor_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_instReprTrafficLight_repr___closed__5_value = {.m_header = {.m_rc = 0, .m_cs_sz = sizeof(lean_ctor_object) + sizeof(void*)*1 + 0, .m_other = 1, .m_tag = 3}, .m_objs = {((lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_instReprTrafficLight_repr___closed__4_value)}};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_instReprTrafficLight_repr___closed__5 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_instReprTrafficLight_repr___closed__5_value;
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_instReprTrafficLight_repr(uint8_t, lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_instReprTrafficLight_repr___boxed(lean_object*, lean_object*);
static const lean_closure_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_instReprTrafficLight___closed__0_value = {.m_header = {.m_rc = 0, .m_cs_sz = sizeof(lean_closure_object) + sizeof(void*)*0, .m_other = 0, .m_tag = 245}, .m_fun = (void*)lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_instReprTrafficLight_repr___boxed, .m_arity = 2, .m_num_fixed = 0, .m_objs = {} };
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_instReprTrafficLight___closed__0 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_instReprTrafficLight___closed__0_value;
LEAN_EXPORT const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_instReprTrafficLight = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_instReprTrafficLight___closed__0_value;
LEAN_EXPORT uint8_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_TrafficLight_ofNat(lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_TrafficLight_ofNat___boxed(lean_object*);
LEAN_EXPORT uint8_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_instDecidableEqTrafficLight(uint8_t, uint8_t);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_instDecidableEqTrafficLight___boxed(lean_object*, lean_object*);
LEAN_EXPORT uint8_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_canGo(uint8_t);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_canGo___boxed(lean_object*);
LEAN_EXPORT uint8_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_nextLight(uint8_t);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_nextLight___boxed(lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_Direction_ctorIdx(uint8_t);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_Direction_ctorIdx___boxed(lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_Direction_toCtorIdx(uint8_t);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_Direction_toCtorIdx___boxed(lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_Direction_ctorElim___redArg(lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_Direction_ctorElim___redArg___boxed(lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_Direction_ctorElim(lean_object*, lean_object*, uint8_t, lean_object*, lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_Direction_ctorElim___boxed(lean_object*, lean_object*, lean_object*, lean_object*, lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_Direction_north_elim___redArg(lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_Direction_north_elim___redArg___boxed(lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_Direction_north_elim(lean_object*, uint8_t, lean_object*, lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_Direction_north_elim___boxed(lean_object*, lean_object*, lean_object*, lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_Direction_south_elim___redArg(lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_Direction_south_elim___redArg___boxed(lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_Direction_south_elim(lean_object*, uint8_t, lean_object*, lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_Direction_south_elim___boxed(lean_object*, lean_object*, lean_object*, lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_Direction_east_elim___redArg(lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_Direction_east_elim___redArg___boxed(lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_Direction_east_elim(lean_object*, uint8_t, lean_object*, lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_Direction_east_elim___boxed(lean_object*, lean_object*, lean_object*, lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_Direction_west_elim___redArg(lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_Direction_west_elim___redArg___boxed(lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_Direction_west_elim(lean_object*, uint8_t, lean_object*, lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_Direction_west_elim___boxed(lean_object*, lean_object*, lean_object*, lean_object*);
static const lean_string_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_instReprDirection_repr___closed__0_value = {.m_header = {.m_rc = 0, .m_cs_sz = 0, .m_other = 0, .m_tag = 249}, .m_size = 60, .m_capacity = 60, .m_length = 59, .m_data = "Lean4Tutorial.Examples.InductiveTypes.Enums.Direction.north"};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_instReprDirection_repr___closed__0 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_instReprDirection_repr___closed__0_value;
static const lean_ctor_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_instReprDirection_repr___closed__1_value = {.m_header = {.m_rc = 0, .m_cs_sz = sizeof(lean_ctor_object) + sizeof(void*)*1 + 0, .m_other = 1, .m_tag = 3}, .m_objs = {((lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_instReprDirection_repr___closed__0_value)}};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_instReprDirection_repr___closed__1 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_instReprDirection_repr___closed__1_value;
static const lean_string_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_instReprDirection_repr___closed__2_value = {.m_header = {.m_rc = 0, .m_cs_sz = 0, .m_other = 0, .m_tag = 249}, .m_size = 60, .m_capacity = 60, .m_length = 59, .m_data = "Lean4Tutorial.Examples.InductiveTypes.Enums.Direction.south"};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_instReprDirection_repr___closed__2 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_instReprDirection_repr___closed__2_value;
static const lean_ctor_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_instReprDirection_repr___closed__3_value = {.m_header = {.m_rc = 0, .m_cs_sz = sizeof(lean_ctor_object) + sizeof(void*)*1 + 0, .m_other = 1, .m_tag = 3}, .m_objs = {((lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_instReprDirection_repr___closed__2_value)}};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_instReprDirection_repr___closed__3 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_instReprDirection_repr___closed__3_value;
static const lean_string_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_instReprDirection_repr___closed__4_value = {.m_header = {.m_rc = 0, .m_cs_sz = 0, .m_other = 0, .m_tag = 249}, .m_size = 59, .m_capacity = 59, .m_length = 58, .m_data = "Lean4Tutorial.Examples.InductiveTypes.Enums.Direction.east"};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_instReprDirection_repr___closed__4 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_instReprDirection_repr___closed__4_value;
static const lean_ctor_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_instReprDirection_repr___closed__5_value = {.m_header = {.m_rc = 0, .m_cs_sz = sizeof(lean_ctor_object) + sizeof(void*)*1 + 0, .m_other = 1, .m_tag = 3}, .m_objs = {((lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_instReprDirection_repr___closed__4_value)}};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_instReprDirection_repr___closed__5 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_instReprDirection_repr___closed__5_value;
static const lean_string_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_instReprDirection_repr___closed__6_value = {.m_header = {.m_rc = 0, .m_cs_sz = 0, .m_other = 0, .m_tag = 249}, .m_size = 59, .m_capacity = 59, .m_length = 58, .m_data = "Lean4Tutorial.Examples.InductiveTypes.Enums.Direction.west"};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_instReprDirection_repr___closed__6 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_instReprDirection_repr___closed__6_value;
static const lean_ctor_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_instReprDirection_repr___closed__7_value = {.m_header = {.m_rc = 0, .m_cs_sz = sizeof(lean_ctor_object) + sizeof(void*)*1 + 0, .m_other = 1, .m_tag = 3}, .m_objs = {((lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_instReprDirection_repr___closed__6_value)}};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_instReprDirection_repr___closed__7 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_instReprDirection_repr___closed__7_value;
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_instReprDirection_repr(uint8_t, lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_instReprDirection_repr___boxed(lean_object*, lean_object*);
static const lean_closure_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_instReprDirection___closed__0_value = {.m_header = {.m_rc = 0, .m_cs_sz = sizeof(lean_closure_object) + sizeof(void*)*0, .m_other = 0, .m_tag = 245}, .m_fun = (void*)lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_instReprDirection_repr___boxed, .m_arity = 2, .m_num_fixed = 0, .m_objs = {} };
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_instReprDirection___closed__0 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_instReprDirection___closed__0_value;
LEAN_EXPORT const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_instReprDirection = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_instReprDirection___closed__0_value;
LEAN_EXPORT uint8_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_Direction_ofNat(lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_Direction_ofNat___boxed(lean_object*);
LEAN_EXPORT uint8_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_instDecidableEqDirection(uint8_t, uint8_t);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_instDecidableEqDirection___boxed(lean_object*, lean_object*);
LEAN_EXPORT uint8_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_opposite(uint8_t);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_opposite___boxed(lean_object*);
LEAN_EXPORT uint8_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_turnLeft(uint8_t);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_turnLeft___boxed(lean_object*);
LEAN_EXPORT uint8_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_turnRight(uint8_t);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_turnRight___boxed(lean_object*);
LEAN_EXPORT uint8_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_my__not(uint8_t);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_my__not___boxed(lean_object*);
LEAN_EXPORT uint8_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_my__and(uint8_t, uint8_t);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_my__and___boxed(lean_object*, lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_Shape_ctorIdx(lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_Shape_ctorIdx___boxed(lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_Shape_ctorElim___redArg(lean_object*, lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_Shape_ctorElim(lean_object*, lean_object*, lean_object*, lean_object*, lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_Shape_ctorElim___boxed(lean_object*, lean_object*, lean_object*, lean_object*, lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_Shape_circle_elim___redArg(lean_object*, lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_Shape_circle_elim(lean_object*, lean_object*, lean_object*, lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_Shape_rectangle_elim___redArg(lean_object*, lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_Shape_rectangle_elim(lean_object*, lean_object*, lean_object*, lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_Shape_square_elim___redArg(lean_object*, lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_Shape_square_elim(lean_object*, lean_object*, lean_object*, lean_object*);
static const lean_string_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_instReprShape_repr___closed__0_value = {.m_header = {.m_rc = 0, .m_cs_sz = 0, .m_other = 0, .m_tag = 249}, .m_size = 57, .m_capacity = 57, .m_length = 56, .m_data = "Lean4Tutorial.Examples.InductiveTypes.Enums.Shape.circle"};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_instReprShape_repr___closed__0 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_instReprShape_repr___closed__0_value;
static const lean_ctor_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_instReprShape_repr___closed__1_value = {.m_header = {.m_rc = 0, .m_cs_sz = sizeof(lean_ctor_object) + sizeof(void*)*1 + 0, .m_other = 1, .m_tag = 3}, .m_objs = {((lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_instReprShape_repr___closed__0_value)}};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_instReprShape_repr___closed__1 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_instReprShape_repr___closed__1_value;
static const lean_ctor_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_instReprShape_repr___closed__2_value = {.m_header = {.m_rc = 0, .m_cs_sz = sizeof(lean_ctor_object) + sizeof(void*)*2 + 0, .m_other = 2, .m_tag = 5}, .m_objs = {((lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_instReprShape_repr___closed__1_value),((lean_object*)(((size_t)(1) << 1) | 1))}};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_instReprShape_repr___closed__2 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_instReprShape_repr___closed__2_value;
static const lean_string_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_instReprShape_repr___closed__3_value = {.m_header = {.m_rc = 0, .m_cs_sz = 0, .m_other = 0, .m_tag = 249}, .m_size = 60, .m_capacity = 60, .m_length = 59, .m_data = "Lean4Tutorial.Examples.InductiveTypes.Enums.Shape.rectangle"};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_instReprShape_repr___closed__3 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_instReprShape_repr___closed__3_value;
static const lean_ctor_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_instReprShape_repr___closed__4_value = {.m_header = {.m_rc = 0, .m_cs_sz = sizeof(lean_ctor_object) + sizeof(void*)*1 + 0, .m_other = 1, .m_tag = 3}, .m_objs = {((lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_instReprShape_repr___closed__3_value)}};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_instReprShape_repr___closed__4 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_instReprShape_repr___closed__4_value;
static const lean_ctor_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_instReprShape_repr___closed__5_value = {.m_header = {.m_rc = 0, .m_cs_sz = sizeof(lean_ctor_object) + sizeof(void*)*2 + 0, .m_other = 2, .m_tag = 5}, .m_objs = {((lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_instReprShape_repr___closed__4_value),((lean_object*)(((size_t)(1) << 1) | 1))}};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_instReprShape_repr___closed__5 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_instReprShape_repr___closed__5_value;
static const lean_string_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_instReprShape_repr___closed__6_value = {.m_header = {.m_rc = 0, .m_cs_sz = 0, .m_other = 0, .m_tag = 249}, .m_size = 57, .m_capacity = 57, .m_length = 56, .m_data = "Lean4Tutorial.Examples.InductiveTypes.Enums.Shape.square"};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_instReprShape_repr___closed__6 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_instReprShape_repr___closed__6_value;
static const lean_ctor_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_instReprShape_repr___closed__7_value = {.m_header = {.m_rc = 0, .m_cs_sz = sizeof(lean_ctor_object) + sizeof(void*)*1 + 0, .m_other = 1, .m_tag = 3}, .m_objs = {((lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_instReprShape_repr___closed__6_value)}};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_instReprShape_repr___closed__7 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_instReprShape_repr___closed__7_value;
static const lean_ctor_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_instReprShape_repr___closed__8_value = {.m_header = {.m_rc = 0, .m_cs_sz = sizeof(lean_ctor_object) + sizeof(void*)*2 + 0, .m_other = 2, .m_tag = 5}, .m_objs = {((lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_instReprShape_repr___closed__7_value),((lean_object*)(((size_t)(1) << 1) | 1))}};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_instReprShape_repr___closed__8 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_instReprShape_repr___closed__8_value;
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_instReprShape_repr(lean_object*, lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_instReprShape_repr___boxed(lean_object*, lean_object*);
static const lean_closure_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_instReprShape___closed__0_value = {.m_header = {.m_rc = 0, .m_cs_sz = sizeof(lean_closure_object) + sizeof(void*)*0, .m_other = 0, .m_tag = 245}, .m_fun = (void*)lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_instReprShape_repr___boxed, .m_arity = 2, .m_num_fixed = 0, .m_objs = {} };
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_instReprShape___closed__0 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_instReprShape___closed__0_value;
LEAN_EXPORT const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_instReprShape = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_instReprShape___closed__0_value;
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_area(lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_area___boxed(lean_object*);
static const lean_ctor_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_circle__area___closed__0_value = {.m_header = {.m_rc = 0, .m_cs_sz = sizeof(lean_ctor_object) + sizeof(void*)*1 + 0, .m_other = 1, .m_tag = 0}, .m_objs = {((lean_object*)(((size_t)(5) << 1) | 1))}};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_circle__area___closed__0 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_circle__area___closed__0_value;
static lean_once_cell_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_circle__area___closed__1_once = LEAN_ONCE_CELL_INITIALIZER;
static lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_circle__area___closed__1;
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_circle__area;
static const lean_ctor_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_rect__area___closed__0_value = {.m_header = {.m_rc = 0, .m_cs_sz = sizeof(lean_ctor_object) + sizeof(void*)*2 + 0, .m_other = 2, .m_tag = 1}, .m_objs = {((lean_object*)(((size_t)(4) << 1) | 1)),((lean_object*)(((size_t)(6) << 1) | 1))}};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_rect__area___closed__0 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_rect__area___closed__0_value;
static lean_once_cell_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_rect__area___closed__1_once = LEAN_ONCE_CELL_INITIALIZER;
static lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_rect__area___closed__1;
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_rect__area;
static const lean_ctor_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_square__area___closed__0_value = {.m_header = {.m_rc = 0, .m_cs_sz = sizeof(lean_ctor_object) + sizeof(void*)*1 + 0, .m_other = 1, .m_tag = 2}, .m_objs = {((lean_object*)(((size_t)(5) << 1) | 1))}};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_square__area___closed__0 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_square__area___closed__0_value;
static lean_once_cell_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_square__area___closed__1_once = LEAN_ONCE_CELL_INITIALIZER;
static lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_square__area___closed__1;
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_square__area;
static const lean_ctor_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_allWeekdays___closed__0_value = {.m_header = {.m_rc = 0, .m_cs_sz = sizeof(lean_ctor_object) + sizeof(void*)*2 + 0, .m_other = 2, .m_tag = 1}, .m_objs = {((lean_object*)(((size_t)(6) << 1) | 1)),((lean_object*)(((size_t)(0) << 1) | 1))}};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_allWeekdays___closed__0 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_allWeekdays___closed__0_value;
static const lean_ctor_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_allWeekdays___closed__1_value = {.m_header = {.m_rc = 0, .m_cs_sz = sizeof(lean_ctor_object) + sizeof(void*)*2 + 0, .m_other = 2, .m_tag = 1}, .m_objs = {((lean_object*)(((size_t)(5) << 1) | 1)),((lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_allWeekdays___closed__0_value)}};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_allWeekdays___closed__1 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_allWeekdays___closed__1_value;
static const lean_ctor_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_allWeekdays___closed__2_value = {.m_header = {.m_rc = 0, .m_cs_sz = sizeof(lean_ctor_object) + sizeof(void*)*2 + 0, .m_other = 2, .m_tag = 1}, .m_objs = {((lean_object*)(((size_t)(4) << 1) | 1)),((lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_allWeekdays___closed__1_value)}};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_allWeekdays___closed__2 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_allWeekdays___closed__2_value;
static const lean_ctor_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_allWeekdays___closed__3_value = {.m_header = {.m_rc = 0, .m_cs_sz = sizeof(lean_ctor_object) + sizeof(void*)*2 + 0, .m_other = 2, .m_tag = 1}, .m_objs = {((lean_object*)(((size_t)(3) << 1) | 1)),((lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_allWeekdays___closed__2_value)}};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_allWeekdays___closed__3 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_allWeekdays___closed__3_value;
static const lean_ctor_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_allWeekdays___closed__4_value = {.m_header = {.m_rc = 0, .m_cs_sz = sizeof(lean_ctor_object) + sizeof(void*)*2 + 0, .m_other = 2, .m_tag = 1}, .m_objs = {((lean_object*)(((size_t)(2) << 1) | 1)),((lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_allWeekdays___closed__3_value)}};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_allWeekdays___closed__4 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_allWeekdays___closed__4_value;
static const lean_ctor_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_allWeekdays___closed__5_value = {.m_header = {.m_rc = 0, .m_cs_sz = sizeof(lean_ctor_object) + sizeof(void*)*2 + 0, .m_other = 2, .m_tag = 1}, .m_objs = {((lean_object*)(((size_t)(1) << 1) | 1)),((lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_allWeekdays___closed__4_value)}};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_allWeekdays___closed__5 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_allWeekdays___closed__5_value;
static const lean_ctor_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_allWeekdays___closed__6_value = {.m_header = {.m_rc = 0, .m_cs_sz = sizeof(lean_ctor_object) + sizeof(void*)*2 + 0, .m_other = 2, .m_tag = 1}, .m_objs = {((lean_object*)(((size_t)(0) << 1) | 1)),((lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_allWeekdays___closed__5_value)}};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_allWeekdays___closed__6 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_allWeekdays___closed__6_value;
LEAN_EXPORT const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_allWeekdays = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_allWeekdays___closed__6_value;
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_Weekday_ctorIdx(uint8_t v_x_1_){
_start:
{
switch(v_x_1_)
{
case 0:
{
lean_object* v___x_2_; 
v___x_2_ = lean_unsigned_to_nat(0u);
return v___x_2_;
}
case 1:
{
lean_object* v___x_3_; 
v___x_3_ = lean_unsigned_to_nat(1u);
return v___x_3_;
}
case 2:
{
lean_object* v___x_4_; 
v___x_4_ = lean_unsigned_to_nat(2u);
return v___x_4_;
}
case 3:
{
lean_object* v___x_5_; 
v___x_5_ = lean_unsigned_to_nat(3u);
return v___x_5_;
}
case 4:
{
lean_object* v___x_6_; 
v___x_6_ = lean_unsigned_to_nat(4u);
return v___x_6_;
}
case 5:
{
lean_object* v___x_7_; 
v___x_7_ = lean_unsigned_to_nat(5u);
return v___x_7_;
}
default: 
{
lean_object* v___x_8_; 
v___x_8_ = lean_unsigned_to_nat(6u);
return v___x_8_;
}
}
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_Weekday_ctorIdx___boxed(lean_object* v_x_9_){
_start:
{
uint8_t v_x_boxed_10_; lean_object* v_res_11_; 
v_x_boxed_10_ = lean_unbox(v_x_9_);
v_res_11_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_Weekday_ctorIdx(v_x_boxed_10_);
return v_res_11_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_Weekday_toCtorIdx(uint8_t v_x_12_){
_start:
{
lean_object* v___x_13_; 
v___x_13_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_Weekday_ctorIdx(v_x_12_);
return v___x_13_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_Weekday_toCtorIdx___boxed(lean_object* v_x_14_){
_start:
{
uint8_t v_x_4__boxed_15_; lean_object* v_res_16_; 
v_x_4__boxed_15_ = lean_unbox(v_x_14_);
v_res_16_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_Weekday_toCtorIdx(v_x_4__boxed_15_);
return v_res_16_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_Weekday_ctorElim___redArg(lean_object* v_k_17_){
_start:
{
lean_inc(v_k_17_);
return v_k_17_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_Weekday_ctorElim___redArg___boxed(lean_object* v_k_18_){
_start:
{
lean_object* v_res_19_; 
v_res_19_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_Weekday_ctorElim___redArg(v_k_18_);
lean_dec(v_k_18_);
return v_res_19_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_Weekday_ctorElim(lean_object* v_motive_20_, lean_object* v_ctorIdx_21_, uint8_t v_t_22_, lean_object* v_h_23_, lean_object* v_k_24_){
_start:
{
lean_inc(v_k_24_);
return v_k_24_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_Weekday_ctorElim___boxed(lean_object* v_motive_25_, lean_object* v_ctorIdx_26_, lean_object* v_t_27_, lean_object* v_h_28_, lean_object* v_k_29_){
_start:
{
uint8_t v_t_boxed_30_; lean_object* v_res_31_; 
v_t_boxed_30_ = lean_unbox(v_t_27_);
v_res_31_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_Weekday_ctorElim(v_motive_25_, v_ctorIdx_26_, v_t_boxed_30_, v_h_28_, v_k_29_);
lean_dec(v_k_29_);
lean_dec(v_ctorIdx_26_);
return v_res_31_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_Weekday_monday_elim___redArg(lean_object* v_monday_32_){
_start:
{
lean_inc(v_monday_32_);
return v_monday_32_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_Weekday_monday_elim___redArg___boxed(lean_object* v_monday_33_){
_start:
{
lean_object* v_res_34_; 
v_res_34_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_Weekday_monday_elim___redArg(v_monday_33_);
lean_dec(v_monday_33_);
return v_res_34_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_Weekday_monday_elim(lean_object* v_motive_35_, uint8_t v_t_36_, lean_object* v_h_37_, lean_object* v_monday_38_){
_start:
{
lean_inc(v_monday_38_);
return v_monday_38_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_Weekday_monday_elim___boxed(lean_object* v_motive_39_, lean_object* v_t_40_, lean_object* v_h_41_, lean_object* v_monday_42_){
_start:
{
uint8_t v_t_boxed_43_; lean_object* v_res_44_; 
v_t_boxed_43_ = lean_unbox(v_t_40_);
v_res_44_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_Weekday_monday_elim(v_motive_39_, v_t_boxed_43_, v_h_41_, v_monday_42_);
lean_dec(v_monday_42_);
return v_res_44_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_Weekday_tuesday_elim___redArg(lean_object* v_tuesday_45_){
_start:
{
lean_inc(v_tuesday_45_);
return v_tuesday_45_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_Weekday_tuesday_elim___redArg___boxed(lean_object* v_tuesday_46_){
_start:
{
lean_object* v_res_47_; 
v_res_47_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_Weekday_tuesday_elim___redArg(v_tuesday_46_);
lean_dec(v_tuesday_46_);
return v_res_47_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_Weekday_tuesday_elim(lean_object* v_motive_48_, uint8_t v_t_49_, lean_object* v_h_50_, lean_object* v_tuesday_51_){
_start:
{
lean_inc(v_tuesday_51_);
return v_tuesday_51_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_Weekday_tuesday_elim___boxed(lean_object* v_motive_52_, lean_object* v_t_53_, lean_object* v_h_54_, lean_object* v_tuesday_55_){
_start:
{
uint8_t v_t_boxed_56_; lean_object* v_res_57_; 
v_t_boxed_56_ = lean_unbox(v_t_53_);
v_res_57_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_Weekday_tuesday_elim(v_motive_52_, v_t_boxed_56_, v_h_54_, v_tuesday_55_);
lean_dec(v_tuesday_55_);
return v_res_57_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_Weekday_wednesday_elim___redArg(lean_object* v_wednesday_58_){
_start:
{
lean_inc(v_wednesday_58_);
return v_wednesday_58_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_Weekday_wednesday_elim___redArg___boxed(lean_object* v_wednesday_59_){
_start:
{
lean_object* v_res_60_; 
v_res_60_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_Weekday_wednesday_elim___redArg(v_wednesday_59_);
lean_dec(v_wednesday_59_);
return v_res_60_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_Weekday_wednesday_elim(lean_object* v_motive_61_, uint8_t v_t_62_, lean_object* v_h_63_, lean_object* v_wednesday_64_){
_start:
{
lean_inc(v_wednesday_64_);
return v_wednesday_64_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_Weekday_wednesday_elim___boxed(lean_object* v_motive_65_, lean_object* v_t_66_, lean_object* v_h_67_, lean_object* v_wednesday_68_){
_start:
{
uint8_t v_t_boxed_69_; lean_object* v_res_70_; 
v_t_boxed_69_ = lean_unbox(v_t_66_);
v_res_70_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_Weekday_wednesday_elim(v_motive_65_, v_t_boxed_69_, v_h_67_, v_wednesday_68_);
lean_dec(v_wednesday_68_);
return v_res_70_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_Weekday_thursday_elim___redArg(lean_object* v_thursday_71_){
_start:
{
lean_inc(v_thursday_71_);
return v_thursday_71_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_Weekday_thursday_elim___redArg___boxed(lean_object* v_thursday_72_){
_start:
{
lean_object* v_res_73_; 
v_res_73_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_Weekday_thursday_elim___redArg(v_thursday_72_);
lean_dec(v_thursday_72_);
return v_res_73_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_Weekday_thursday_elim(lean_object* v_motive_74_, uint8_t v_t_75_, lean_object* v_h_76_, lean_object* v_thursday_77_){
_start:
{
lean_inc(v_thursday_77_);
return v_thursday_77_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_Weekday_thursday_elim___boxed(lean_object* v_motive_78_, lean_object* v_t_79_, lean_object* v_h_80_, lean_object* v_thursday_81_){
_start:
{
uint8_t v_t_boxed_82_; lean_object* v_res_83_; 
v_t_boxed_82_ = lean_unbox(v_t_79_);
v_res_83_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_Weekday_thursday_elim(v_motive_78_, v_t_boxed_82_, v_h_80_, v_thursday_81_);
lean_dec(v_thursday_81_);
return v_res_83_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_Weekday_friday_elim___redArg(lean_object* v_friday_84_){
_start:
{
lean_inc(v_friday_84_);
return v_friday_84_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_Weekday_friday_elim___redArg___boxed(lean_object* v_friday_85_){
_start:
{
lean_object* v_res_86_; 
v_res_86_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_Weekday_friday_elim___redArg(v_friday_85_);
lean_dec(v_friday_85_);
return v_res_86_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_Weekday_friday_elim(lean_object* v_motive_87_, uint8_t v_t_88_, lean_object* v_h_89_, lean_object* v_friday_90_){
_start:
{
lean_inc(v_friday_90_);
return v_friday_90_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_Weekday_friday_elim___boxed(lean_object* v_motive_91_, lean_object* v_t_92_, lean_object* v_h_93_, lean_object* v_friday_94_){
_start:
{
uint8_t v_t_boxed_95_; lean_object* v_res_96_; 
v_t_boxed_95_ = lean_unbox(v_t_92_);
v_res_96_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_Weekday_friday_elim(v_motive_91_, v_t_boxed_95_, v_h_93_, v_friday_94_);
lean_dec(v_friday_94_);
return v_res_96_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_Weekday_saturday_elim___redArg(lean_object* v_saturday_97_){
_start:
{
lean_inc(v_saturday_97_);
return v_saturday_97_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_Weekday_saturday_elim___redArg___boxed(lean_object* v_saturday_98_){
_start:
{
lean_object* v_res_99_; 
v_res_99_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_Weekday_saturday_elim___redArg(v_saturday_98_);
lean_dec(v_saturday_98_);
return v_res_99_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_Weekday_saturday_elim(lean_object* v_motive_100_, uint8_t v_t_101_, lean_object* v_h_102_, lean_object* v_saturday_103_){
_start:
{
lean_inc(v_saturday_103_);
return v_saturday_103_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_Weekday_saturday_elim___boxed(lean_object* v_motive_104_, lean_object* v_t_105_, lean_object* v_h_106_, lean_object* v_saturday_107_){
_start:
{
uint8_t v_t_boxed_108_; lean_object* v_res_109_; 
v_t_boxed_108_ = lean_unbox(v_t_105_);
v_res_109_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_Weekday_saturday_elim(v_motive_104_, v_t_boxed_108_, v_h_106_, v_saturday_107_);
lean_dec(v_saturday_107_);
return v_res_109_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_Weekday_sunday_elim___redArg(lean_object* v_sunday_110_){
_start:
{
lean_inc(v_sunday_110_);
return v_sunday_110_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_Weekday_sunday_elim___redArg___boxed(lean_object* v_sunday_111_){
_start:
{
lean_object* v_res_112_; 
v_res_112_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_Weekday_sunday_elim___redArg(v_sunday_111_);
lean_dec(v_sunday_111_);
return v_res_112_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_Weekday_sunday_elim(lean_object* v_motive_113_, uint8_t v_t_114_, lean_object* v_h_115_, lean_object* v_sunday_116_){
_start:
{
lean_inc(v_sunday_116_);
return v_sunday_116_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_Weekday_sunday_elim___boxed(lean_object* v_motive_117_, lean_object* v_t_118_, lean_object* v_h_119_, lean_object* v_sunday_120_){
_start:
{
uint8_t v_t_boxed_121_; lean_object* v_res_122_; 
v_t_boxed_121_ = lean_unbox(v_t_118_);
v_res_122_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_Weekday_sunday_elim(v_motive_117_, v_t_boxed_121_, v_h_119_, v_sunday_120_);
lean_dec(v_sunday_120_);
return v_res_122_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_instReprWeekday_repr___closed__14(void){
_start:
{
lean_object* v___x_144_; lean_object* v___x_145_; 
v___x_144_ = lean_unsigned_to_nat(2u);
v___x_145_ = lean_nat_to_int(v___x_144_);
return v___x_145_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_instReprWeekday_repr___closed__15(void){
_start:
{
lean_object* v___x_146_; lean_object* v___x_147_; 
v___x_146_ = lean_unsigned_to_nat(1u);
v___x_147_ = lean_nat_to_int(v___x_146_);
return v___x_147_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_instReprWeekday_repr(uint8_t v_x_148_, lean_object* v_prec_149_){
_start:
{
lean_object* v___y_151_; lean_object* v___y_158_; lean_object* v___y_165_; lean_object* v___y_172_; lean_object* v___y_179_; lean_object* v___y_186_; lean_object* v___y_193_; 
switch(v_x_148_)
{
case 0:
{
lean_object* v___x_199_; uint8_t v___x_200_; 
v___x_199_ = lean_unsigned_to_nat(1024u);
v___x_200_ = lean_nat_dec_le(v___x_199_, v_prec_149_);
if (v___x_200_ == 0)
{
lean_object* v___x_201_; 
v___x_201_ = lean_obj_once(&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_instReprWeekday_repr___closed__14, &lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_instReprWeekday_repr___closed__14_once, _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_instReprWeekday_repr___closed__14);
v___y_151_ = v___x_201_;
goto v___jp_150_;
}
else
{
lean_object* v___x_202_; 
v___x_202_ = lean_obj_once(&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_instReprWeekday_repr___closed__15, &lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_instReprWeekday_repr___closed__15_once, _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_instReprWeekday_repr___closed__15);
v___y_151_ = v___x_202_;
goto v___jp_150_;
}
}
case 1:
{
lean_object* v___x_203_; uint8_t v___x_204_; 
v___x_203_ = lean_unsigned_to_nat(1024u);
v___x_204_ = lean_nat_dec_le(v___x_203_, v_prec_149_);
if (v___x_204_ == 0)
{
lean_object* v___x_205_; 
v___x_205_ = lean_obj_once(&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_instReprWeekday_repr___closed__14, &lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_instReprWeekday_repr___closed__14_once, _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_instReprWeekday_repr___closed__14);
v___y_158_ = v___x_205_;
goto v___jp_157_;
}
else
{
lean_object* v___x_206_; 
v___x_206_ = lean_obj_once(&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_instReprWeekday_repr___closed__15, &lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_instReprWeekday_repr___closed__15_once, _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_instReprWeekday_repr___closed__15);
v___y_158_ = v___x_206_;
goto v___jp_157_;
}
}
case 2:
{
lean_object* v___x_207_; uint8_t v___x_208_; 
v___x_207_ = lean_unsigned_to_nat(1024u);
v___x_208_ = lean_nat_dec_le(v___x_207_, v_prec_149_);
if (v___x_208_ == 0)
{
lean_object* v___x_209_; 
v___x_209_ = lean_obj_once(&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_instReprWeekday_repr___closed__14, &lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_instReprWeekday_repr___closed__14_once, _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_instReprWeekday_repr___closed__14);
v___y_165_ = v___x_209_;
goto v___jp_164_;
}
else
{
lean_object* v___x_210_; 
v___x_210_ = lean_obj_once(&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_instReprWeekday_repr___closed__15, &lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_instReprWeekday_repr___closed__15_once, _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_instReprWeekday_repr___closed__15);
v___y_165_ = v___x_210_;
goto v___jp_164_;
}
}
case 3:
{
lean_object* v___x_211_; uint8_t v___x_212_; 
v___x_211_ = lean_unsigned_to_nat(1024u);
v___x_212_ = lean_nat_dec_le(v___x_211_, v_prec_149_);
if (v___x_212_ == 0)
{
lean_object* v___x_213_; 
v___x_213_ = lean_obj_once(&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_instReprWeekday_repr___closed__14, &lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_instReprWeekday_repr___closed__14_once, _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_instReprWeekday_repr___closed__14);
v___y_172_ = v___x_213_;
goto v___jp_171_;
}
else
{
lean_object* v___x_214_; 
v___x_214_ = lean_obj_once(&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_instReprWeekday_repr___closed__15, &lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_instReprWeekday_repr___closed__15_once, _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_instReprWeekday_repr___closed__15);
v___y_172_ = v___x_214_;
goto v___jp_171_;
}
}
case 4:
{
lean_object* v___x_215_; uint8_t v___x_216_; 
v___x_215_ = lean_unsigned_to_nat(1024u);
v___x_216_ = lean_nat_dec_le(v___x_215_, v_prec_149_);
if (v___x_216_ == 0)
{
lean_object* v___x_217_; 
v___x_217_ = lean_obj_once(&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_instReprWeekday_repr___closed__14, &lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_instReprWeekday_repr___closed__14_once, _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_instReprWeekday_repr___closed__14);
v___y_179_ = v___x_217_;
goto v___jp_178_;
}
else
{
lean_object* v___x_218_; 
v___x_218_ = lean_obj_once(&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_instReprWeekday_repr___closed__15, &lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_instReprWeekday_repr___closed__15_once, _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_instReprWeekday_repr___closed__15);
v___y_179_ = v___x_218_;
goto v___jp_178_;
}
}
case 5:
{
lean_object* v___x_219_; uint8_t v___x_220_; 
v___x_219_ = lean_unsigned_to_nat(1024u);
v___x_220_ = lean_nat_dec_le(v___x_219_, v_prec_149_);
if (v___x_220_ == 0)
{
lean_object* v___x_221_; 
v___x_221_ = lean_obj_once(&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_instReprWeekday_repr___closed__14, &lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_instReprWeekday_repr___closed__14_once, _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_instReprWeekday_repr___closed__14);
v___y_186_ = v___x_221_;
goto v___jp_185_;
}
else
{
lean_object* v___x_222_; 
v___x_222_ = lean_obj_once(&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_instReprWeekday_repr___closed__15, &lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_instReprWeekday_repr___closed__15_once, _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_instReprWeekday_repr___closed__15);
v___y_186_ = v___x_222_;
goto v___jp_185_;
}
}
default: 
{
lean_object* v___x_223_; uint8_t v___x_224_; 
v___x_223_ = lean_unsigned_to_nat(1024u);
v___x_224_ = lean_nat_dec_le(v___x_223_, v_prec_149_);
if (v___x_224_ == 0)
{
lean_object* v___x_225_; 
v___x_225_ = lean_obj_once(&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_instReprWeekday_repr___closed__14, &lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_instReprWeekday_repr___closed__14_once, _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_instReprWeekday_repr___closed__14);
v___y_193_ = v___x_225_;
goto v___jp_192_;
}
else
{
lean_object* v___x_226_; 
v___x_226_ = lean_obj_once(&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_instReprWeekday_repr___closed__15, &lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_instReprWeekday_repr___closed__15_once, _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_instReprWeekday_repr___closed__15);
v___y_193_ = v___x_226_;
goto v___jp_192_;
}
}
}
v___jp_150_:
{
lean_object* v___x_152_; lean_object* v___x_153_; uint8_t v___x_154_; lean_object* v___x_155_; lean_object* v___x_156_; 
v___x_152_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_instReprWeekday_repr___closed__1));
lean_inc(v___y_151_);
v___x_153_ = lean_alloc_ctor(4, 2, 0);
lean_ctor_set(v___x_153_, 0, v___y_151_);
lean_ctor_set(v___x_153_, 1, v___x_152_);
v___x_154_ = 0;
v___x_155_ = lean_alloc_ctor(6, 1, 1);
lean_ctor_set(v___x_155_, 0, v___x_153_);
lean_ctor_set_uint8(v___x_155_, sizeof(void*)*1, v___x_154_);
v___x_156_ = l_Repr_addAppParen(v___x_155_, v_prec_149_);
return v___x_156_;
}
v___jp_157_:
{
lean_object* v___x_159_; lean_object* v___x_160_; uint8_t v___x_161_; lean_object* v___x_162_; lean_object* v___x_163_; 
v___x_159_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_instReprWeekday_repr___closed__3));
lean_inc(v___y_158_);
v___x_160_ = lean_alloc_ctor(4, 2, 0);
lean_ctor_set(v___x_160_, 0, v___y_158_);
lean_ctor_set(v___x_160_, 1, v___x_159_);
v___x_161_ = 0;
v___x_162_ = lean_alloc_ctor(6, 1, 1);
lean_ctor_set(v___x_162_, 0, v___x_160_);
lean_ctor_set_uint8(v___x_162_, sizeof(void*)*1, v___x_161_);
v___x_163_ = l_Repr_addAppParen(v___x_162_, v_prec_149_);
return v___x_163_;
}
v___jp_164_:
{
lean_object* v___x_166_; lean_object* v___x_167_; uint8_t v___x_168_; lean_object* v___x_169_; lean_object* v___x_170_; 
v___x_166_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_instReprWeekday_repr___closed__5));
lean_inc(v___y_165_);
v___x_167_ = lean_alloc_ctor(4, 2, 0);
lean_ctor_set(v___x_167_, 0, v___y_165_);
lean_ctor_set(v___x_167_, 1, v___x_166_);
v___x_168_ = 0;
v___x_169_ = lean_alloc_ctor(6, 1, 1);
lean_ctor_set(v___x_169_, 0, v___x_167_);
lean_ctor_set_uint8(v___x_169_, sizeof(void*)*1, v___x_168_);
v___x_170_ = l_Repr_addAppParen(v___x_169_, v_prec_149_);
return v___x_170_;
}
v___jp_171_:
{
lean_object* v___x_173_; lean_object* v___x_174_; uint8_t v___x_175_; lean_object* v___x_176_; lean_object* v___x_177_; 
v___x_173_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_instReprWeekday_repr___closed__7));
lean_inc(v___y_172_);
v___x_174_ = lean_alloc_ctor(4, 2, 0);
lean_ctor_set(v___x_174_, 0, v___y_172_);
lean_ctor_set(v___x_174_, 1, v___x_173_);
v___x_175_ = 0;
v___x_176_ = lean_alloc_ctor(6, 1, 1);
lean_ctor_set(v___x_176_, 0, v___x_174_);
lean_ctor_set_uint8(v___x_176_, sizeof(void*)*1, v___x_175_);
v___x_177_ = l_Repr_addAppParen(v___x_176_, v_prec_149_);
return v___x_177_;
}
v___jp_178_:
{
lean_object* v___x_180_; lean_object* v___x_181_; uint8_t v___x_182_; lean_object* v___x_183_; lean_object* v___x_184_; 
v___x_180_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_instReprWeekday_repr___closed__9));
lean_inc(v___y_179_);
v___x_181_ = lean_alloc_ctor(4, 2, 0);
lean_ctor_set(v___x_181_, 0, v___y_179_);
lean_ctor_set(v___x_181_, 1, v___x_180_);
v___x_182_ = 0;
v___x_183_ = lean_alloc_ctor(6, 1, 1);
lean_ctor_set(v___x_183_, 0, v___x_181_);
lean_ctor_set_uint8(v___x_183_, sizeof(void*)*1, v___x_182_);
v___x_184_ = l_Repr_addAppParen(v___x_183_, v_prec_149_);
return v___x_184_;
}
v___jp_185_:
{
lean_object* v___x_187_; lean_object* v___x_188_; uint8_t v___x_189_; lean_object* v___x_190_; lean_object* v___x_191_; 
v___x_187_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_instReprWeekday_repr___closed__11));
lean_inc(v___y_186_);
v___x_188_ = lean_alloc_ctor(4, 2, 0);
lean_ctor_set(v___x_188_, 0, v___y_186_);
lean_ctor_set(v___x_188_, 1, v___x_187_);
v___x_189_ = 0;
v___x_190_ = lean_alloc_ctor(6, 1, 1);
lean_ctor_set(v___x_190_, 0, v___x_188_);
lean_ctor_set_uint8(v___x_190_, sizeof(void*)*1, v___x_189_);
v___x_191_ = l_Repr_addAppParen(v___x_190_, v_prec_149_);
return v___x_191_;
}
v___jp_192_:
{
lean_object* v___x_194_; lean_object* v___x_195_; uint8_t v___x_196_; lean_object* v___x_197_; lean_object* v___x_198_; 
v___x_194_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_instReprWeekday_repr___closed__13));
lean_inc(v___y_193_);
v___x_195_ = lean_alloc_ctor(4, 2, 0);
lean_ctor_set(v___x_195_, 0, v___y_193_);
lean_ctor_set(v___x_195_, 1, v___x_194_);
v___x_196_ = 0;
v___x_197_ = lean_alloc_ctor(6, 1, 1);
lean_ctor_set(v___x_197_, 0, v___x_195_);
lean_ctor_set_uint8(v___x_197_, sizeof(void*)*1, v___x_196_);
v___x_198_ = l_Repr_addAppParen(v___x_197_, v_prec_149_);
return v___x_198_;
}
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_instReprWeekday_repr___boxed(lean_object* v_x_227_, lean_object* v_prec_228_){
_start:
{
uint8_t v_x_401__boxed_229_; lean_object* v_res_230_; 
v_x_401__boxed_229_ = lean_unbox(v_x_227_);
v_res_230_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_instReprWeekday_repr(v_x_401__boxed_229_, v_prec_228_);
lean_dec(v_prec_228_);
return v_res_230_;
}
}
LEAN_EXPORT uint8_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_Weekday_ofNat(lean_object* v_n_233_){
_start:
{
lean_object* v___x_234_; uint8_t v___x_235_; 
v___x_234_ = lean_unsigned_to_nat(2u);
v___x_235_ = lean_nat_dec_le(v_n_233_, v___x_234_);
if (v___x_235_ == 0)
{
lean_object* v___x_236_; uint8_t v___x_237_; 
v___x_236_ = lean_unsigned_to_nat(4u);
v___x_237_ = lean_nat_dec_le(v_n_233_, v___x_236_);
if (v___x_237_ == 0)
{
lean_object* v___x_238_; uint8_t v___x_239_; 
v___x_238_ = lean_unsigned_to_nat(5u);
v___x_239_ = lean_nat_dec_le(v_n_233_, v___x_238_);
if (v___x_239_ == 0)
{
uint8_t v___x_240_; 
v___x_240_ = 6;
return v___x_240_;
}
else
{
uint8_t v___x_241_; 
v___x_241_ = 5;
return v___x_241_;
}
}
else
{
lean_object* v___x_242_; uint8_t v___x_243_; 
v___x_242_ = lean_unsigned_to_nat(3u);
v___x_243_ = lean_nat_dec_le(v_n_233_, v___x_242_);
if (v___x_243_ == 0)
{
uint8_t v___x_244_; 
v___x_244_ = 4;
return v___x_244_;
}
else
{
uint8_t v___x_245_; 
v___x_245_ = 3;
return v___x_245_;
}
}
}
else
{
lean_object* v___x_246_; uint8_t v___x_247_; 
v___x_246_ = lean_unsigned_to_nat(0u);
v___x_247_ = lean_nat_dec_le(v_n_233_, v___x_246_);
if (v___x_247_ == 0)
{
lean_object* v___x_248_; uint8_t v___x_249_; 
v___x_248_ = lean_unsigned_to_nat(1u);
v___x_249_ = lean_nat_dec_le(v_n_233_, v___x_248_);
if (v___x_249_ == 0)
{
uint8_t v___x_250_; 
v___x_250_ = 2;
return v___x_250_;
}
else
{
uint8_t v___x_251_; 
v___x_251_ = 1;
return v___x_251_;
}
}
else
{
uint8_t v___x_252_; 
v___x_252_ = 0;
return v___x_252_;
}
}
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_Weekday_ofNat___boxed(lean_object* v_n_253_){
_start:
{
uint8_t v_res_254_; lean_object* v_r_255_; 
v_res_254_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_Weekday_ofNat(v_n_253_);
lean_dec(v_n_253_);
v_r_255_ = lean_box(v_res_254_);
return v_r_255_;
}
}
LEAN_EXPORT uint8_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_instDecidableEqWeekday(uint8_t v_x_256_, uint8_t v_y_257_){
_start:
{
lean_object* v___x_258_; lean_object* v___x_259_; uint8_t v___x_260_; 
v___x_258_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_Weekday_ctorIdx(v_x_256_);
v___x_259_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_Weekday_ctorIdx(v_y_257_);
v___x_260_ = lean_nat_dec_eq(v___x_258_, v___x_259_);
lean_dec(v___x_259_);
lean_dec(v___x_258_);
return v___x_260_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_instDecidableEqWeekday___boxed(lean_object* v_x_261_, lean_object* v_y_262_){
_start:
{
uint8_t v_x_13__boxed_263_; uint8_t v_y_14__boxed_264_; uint8_t v_res_265_; lean_object* v_r_266_; 
v_x_13__boxed_263_ = lean_unbox(v_x_261_);
v_y_14__boxed_264_ = lean_unbox(v_y_262_);
v_res_265_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_instDecidableEqWeekday(v_x_13__boxed_263_, v_y_14__boxed_264_);
v_r_266_ = lean_box(v_res_265_);
return v_r_266_;
}
}
static uint8_t _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_today(void){
_start:
{
uint8_t v___x_267_; 
v___x_267_ = 0;
return v___x_267_;
}
}
static uint8_t _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_weekend__start(void){
_start:
{
uint8_t v___x_268_; 
v___x_268_ = 5;
return v___x_268_;
}
}
LEAN_EXPORT uint8_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_isWeekday(uint8_t v_d_269_){
_start:
{
switch(v_d_269_)
{
case 5:
{
uint8_t v___x_270_; 
v___x_270_ = 0;
return v___x_270_;
}
case 6:
{
uint8_t v___x_271_; 
v___x_271_ = 0;
return v___x_271_;
}
default: 
{
uint8_t v___x_272_; 
v___x_272_ = 1;
return v___x_272_;
}
}
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_isWeekday___boxed(lean_object* v_d_273_){
_start:
{
uint8_t v_d_boxed_274_; uint8_t v_res_275_; lean_object* v_r_276_; 
v_d_boxed_274_ = lean_unbox(v_d_273_);
v_res_275_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_isWeekday(v_d_boxed_274_);
v_r_276_ = lean_box(v_res_275_);
return v_r_276_;
}
}
LEAN_EXPORT uint8_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_isWeekend(uint8_t v_d_277_){
_start:
{
switch(v_d_277_)
{
case 5:
{
uint8_t v___x_278_; 
v___x_278_ = 1;
return v___x_278_;
}
case 6:
{
uint8_t v___x_279_; 
v___x_279_ = 1;
return v___x_279_;
}
default: 
{
uint8_t v___x_280_; 
v___x_280_ = 0;
return v___x_280_;
}
}
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_isWeekend___boxed(lean_object* v_d_281_){
_start:
{
uint8_t v_d_boxed_282_; uint8_t v_res_283_; lean_object* v_r_284_; 
v_d_boxed_282_ = lean_unbox(v_d_281_);
v_res_283_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_isWeekend(v_d_boxed_282_);
v_r_284_ = lean_box(v_res_283_);
return v_r_284_;
}
}
LEAN_EXPORT uint8_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_nextDay(uint8_t v_d_285_){
_start:
{
switch(v_d_285_)
{
case 0:
{
uint8_t v___x_286_; 
v___x_286_ = 1;
return v___x_286_;
}
case 1:
{
uint8_t v___x_287_; 
v___x_287_ = 2;
return v___x_287_;
}
case 2:
{
uint8_t v___x_288_; 
v___x_288_ = 3;
return v___x_288_;
}
case 3:
{
uint8_t v___x_289_; 
v___x_289_ = 4;
return v___x_289_;
}
case 4:
{
uint8_t v___x_290_; 
v___x_290_ = 5;
return v___x_290_;
}
case 5:
{
uint8_t v___x_291_; 
v___x_291_ = 6;
return v___x_291_;
}
default: 
{
uint8_t v___x_292_; 
v___x_292_ = 0;
return v___x_292_;
}
}
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_nextDay___boxed(lean_object* v_d_293_){
_start:
{
uint8_t v_d_boxed_294_; uint8_t v_res_295_; lean_object* v_r_296_; 
v_d_boxed_294_ = lean_unbox(v_d_293_);
v_res_295_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_nextDay(v_d_boxed_294_);
v_r_296_ = lean_box(v_res_295_);
return v_r_296_;
}
}
LEAN_EXPORT uint8_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_prevDay(uint8_t v_d_297_){
_start:
{
switch(v_d_297_)
{
case 0:
{
uint8_t v___x_298_; 
v___x_298_ = 6;
return v___x_298_;
}
case 1:
{
uint8_t v___x_299_; 
v___x_299_ = 0;
return v___x_299_;
}
case 2:
{
uint8_t v___x_300_; 
v___x_300_ = 1;
return v___x_300_;
}
case 3:
{
uint8_t v___x_301_; 
v___x_301_ = 2;
return v___x_301_;
}
case 4:
{
uint8_t v___x_302_; 
v___x_302_ = 3;
return v___x_302_;
}
case 5:
{
uint8_t v___x_303_; 
v___x_303_ = 4;
return v___x_303_;
}
default: 
{
uint8_t v___x_304_; 
v___x_304_ = 5;
return v___x_304_;
}
}
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_prevDay___boxed(lean_object* v_d_305_){
_start:
{
uint8_t v_d_boxed_306_; uint8_t v_res_307_; lean_object* v_r_308_; 
v_d_boxed_306_ = lean_unbox(v_d_305_);
v_res_307_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_prevDay(v_d_boxed_306_);
v_r_308_ = lean_box(v_res_307_);
return v_r_308_;
}
}
static uint8_t _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_monday__is__weekday___closed__0(void){
_start:
{
uint8_t v___x_309_; uint8_t v___x_310_; 
v___x_309_ = 0;
v___x_310_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_isWeekday(v___x_309_);
return v___x_310_;
}
}
static uint8_t _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_monday__is__weekday(void){
_start:
{
uint8_t v___x_311_; 
v___x_311_ = lean_uint8_once(&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_monday__is__weekday___closed__0, &lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_monday__is__weekday___closed__0_once, _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_monday__is__weekday___closed__0);
return v___x_311_;
}
}
static uint8_t _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_saturday__is__weekend___closed__0(void){
_start:
{
uint8_t v___x_312_; uint8_t v___x_313_; 
v___x_312_ = 5;
v___x_313_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_isWeekend(v___x_312_);
return v___x_313_;
}
}
static uint8_t _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_saturday__is__weekend(void){
_start:
{
uint8_t v___x_314_; 
v___x_314_ = lean_uint8_once(&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_saturday__is__weekend___closed__0, &lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_saturday__is__weekend___closed__0_once, _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_saturday__is__weekend___closed__0);
return v___x_314_;
}
}
static uint8_t _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_next__monday___closed__0(void){
_start:
{
uint8_t v___x_315_; uint8_t v___x_316_; 
v___x_315_ = 0;
v___x_316_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_nextDay(v___x_315_);
return v___x_316_;
}
}
static uint8_t _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_next__monday(void){
_start:
{
uint8_t v___x_317_; 
v___x_317_ = lean_uint8_once(&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_next__monday___closed__0, &lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_next__monday___closed__0_once, _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_next__monday___closed__0);
return v___x_317_;
}
}
static uint8_t _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_prev__monday___closed__0(void){
_start:
{
uint8_t v___x_318_; uint8_t v___x_319_; 
v___x_318_ = 0;
v___x_319_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_prevDay(v___x_318_);
return v___x_319_;
}
}
static uint8_t _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_prev__monday(void){
_start:
{
uint8_t v___x_320_; 
v___x_320_ = lean_uint8_once(&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_prev__monday___closed__0, &lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_prev__monday___closed__0_once, _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_prev__monday___closed__0);
return v___x_320_;
}
}
LEAN_EXPORT uint8_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_three__days__later(uint8_t v_d_321_){
_start:
{
uint8_t v___x_322_; uint8_t v___x_323_; uint8_t v___x_324_; 
v___x_322_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_nextDay(v_d_321_);
v___x_323_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_nextDay(v___x_322_);
v___x_324_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_nextDay(v___x_323_);
return v___x_324_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_three__days__later___boxed(lean_object* v_d_325_){
_start:
{
uint8_t v_d_boxed_326_; uint8_t v_res_327_; lean_object* v_r_328_; 
v_d_boxed_326_ = lean_unbox(v_d_325_);
v_res_327_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_three__days__later(v_d_boxed_326_);
v_r_328_ = lean_box(v_res_327_);
return v_r_328_;
}
}
static uint8_t _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_wed__plus__three___closed__0(void){
_start:
{
uint8_t v___x_329_; uint8_t v___x_330_; 
v___x_329_ = 2;
v___x_330_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_three__days__later(v___x_329_);
return v___x_330_;
}
}
static uint8_t _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_wed__plus__three(void){
_start:
{
uint8_t v___x_331_; 
v___x_331_ = lean_uint8_once(&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_wed__plus__three___closed__0, &lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_wed__plus__three___closed__0_once, _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_wed__plus__three___closed__0);
return v___x_331_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_Weekday_toString(uint8_t v_d_339_){
_start:
{
switch(v_d_339_)
{
case 0:
{
lean_object* v___x_340_; 
v___x_340_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_Weekday_toString___closed__0));
return v___x_340_;
}
case 1:
{
lean_object* v___x_341_; 
v___x_341_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_Weekday_toString___closed__1));
return v___x_341_;
}
case 2:
{
lean_object* v___x_342_; 
v___x_342_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_Weekday_toString___closed__2));
return v___x_342_;
}
case 3:
{
lean_object* v___x_343_; 
v___x_343_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_Weekday_toString___closed__3));
return v___x_343_;
}
case 4:
{
lean_object* v___x_344_; 
v___x_344_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_Weekday_toString___closed__4));
return v___x_344_;
}
case 5:
{
lean_object* v___x_345_; 
v___x_345_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_Weekday_toString___closed__5));
return v___x_345_;
}
default: 
{
lean_object* v___x_346_; 
v___x_346_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_Weekday_toString___closed__6));
return v___x_346_;
}
}
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_Weekday_toString___boxed(lean_object* v_d_347_){
_start:
{
uint8_t v_d_boxed_348_; lean_object* v_res_349_; 
v_d_boxed_348_ = lean_unbox(v_d_347_);
v_res_349_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_Weekday_toString(v_d_boxed_348_);
return v_res_349_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_print__monday___closed__0(void){
_start:
{
uint8_t v___x_350_; lean_object* v___x_351_; 
v___x_350_ = 0;
v___x_351_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_Weekday_toString(v___x_350_);
return v___x_351_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_print__monday(void){
_start:
{
lean_object* v___x_352_; 
v___x_352_ = lean_obj_once(&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_print__monday___closed__0, &lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_print__monday___closed__0_once, _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_print__monday___closed__0);
return v___x_352_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_TrafficLight_ctorIdx(uint8_t v_x_353_){
_start:
{
switch(v_x_353_)
{
case 0:
{
lean_object* v___x_354_; 
v___x_354_ = lean_unsigned_to_nat(0u);
return v___x_354_;
}
case 1:
{
lean_object* v___x_355_; 
v___x_355_ = lean_unsigned_to_nat(1u);
return v___x_355_;
}
default: 
{
lean_object* v___x_356_; 
v___x_356_ = lean_unsigned_to_nat(2u);
return v___x_356_;
}
}
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_TrafficLight_ctorIdx___boxed(lean_object* v_x_357_){
_start:
{
uint8_t v_x_boxed_358_; lean_object* v_res_359_; 
v_x_boxed_358_ = lean_unbox(v_x_357_);
v_res_359_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_TrafficLight_ctorIdx(v_x_boxed_358_);
return v_res_359_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_TrafficLight_toCtorIdx(uint8_t v_x_360_){
_start:
{
lean_object* v___x_361_; 
v___x_361_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_TrafficLight_ctorIdx(v_x_360_);
return v___x_361_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_TrafficLight_toCtorIdx___boxed(lean_object* v_x_362_){
_start:
{
uint8_t v_x_4__boxed_363_; lean_object* v_res_364_; 
v_x_4__boxed_363_ = lean_unbox(v_x_362_);
v_res_364_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_TrafficLight_toCtorIdx(v_x_4__boxed_363_);
return v_res_364_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_TrafficLight_ctorElim___redArg(lean_object* v_k_365_){
_start:
{
lean_inc(v_k_365_);
return v_k_365_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_TrafficLight_ctorElim___redArg___boxed(lean_object* v_k_366_){
_start:
{
lean_object* v_res_367_; 
v_res_367_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_TrafficLight_ctorElim___redArg(v_k_366_);
lean_dec(v_k_366_);
return v_res_367_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_TrafficLight_ctorElim(lean_object* v_motive_368_, lean_object* v_ctorIdx_369_, uint8_t v_t_370_, lean_object* v_h_371_, lean_object* v_k_372_){
_start:
{
lean_inc(v_k_372_);
return v_k_372_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_TrafficLight_ctorElim___boxed(lean_object* v_motive_373_, lean_object* v_ctorIdx_374_, lean_object* v_t_375_, lean_object* v_h_376_, lean_object* v_k_377_){
_start:
{
uint8_t v_t_boxed_378_; lean_object* v_res_379_; 
v_t_boxed_378_ = lean_unbox(v_t_375_);
v_res_379_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_TrafficLight_ctorElim(v_motive_373_, v_ctorIdx_374_, v_t_boxed_378_, v_h_376_, v_k_377_);
lean_dec(v_k_377_);
lean_dec(v_ctorIdx_374_);
return v_res_379_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_TrafficLight_red_elim___redArg(lean_object* v_red_380_){
_start:
{
lean_inc(v_red_380_);
return v_red_380_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_TrafficLight_red_elim___redArg___boxed(lean_object* v_red_381_){
_start:
{
lean_object* v_res_382_; 
v_res_382_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_TrafficLight_red_elim___redArg(v_red_381_);
lean_dec(v_red_381_);
return v_res_382_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_TrafficLight_red_elim(lean_object* v_motive_383_, uint8_t v_t_384_, lean_object* v_h_385_, lean_object* v_red_386_){
_start:
{
lean_inc(v_red_386_);
return v_red_386_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_TrafficLight_red_elim___boxed(lean_object* v_motive_387_, lean_object* v_t_388_, lean_object* v_h_389_, lean_object* v_red_390_){
_start:
{
uint8_t v_t_boxed_391_; lean_object* v_res_392_; 
v_t_boxed_391_ = lean_unbox(v_t_388_);
v_res_392_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_TrafficLight_red_elim(v_motive_387_, v_t_boxed_391_, v_h_389_, v_red_390_);
lean_dec(v_red_390_);
return v_res_392_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_TrafficLight_yellow_elim___redArg(lean_object* v_yellow_393_){
_start:
{
lean_inc(v_yellow_393_);
return v_yellow_393_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_TrafficLight_yellow_elim___redArg___boxed(lean_object* v_yellow_394_){
_start:
{
lean_object* v_res_395_; 
v_res_395_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_TrafficLight_yellow_elim___redArg(v_yellow_394_);
lean_dec(v_yellow_394_);
return v_res_395_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_TrafficLight_yellow_elim(lean_object* v_motive_396_, uint8_t v_t_397_, lean_object* v_h_398_, lean_object* v_yellow_399_){
_start:
{
lean_inc(v_yellow_399_);
return v_yellow_399_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_TrafficLight_yellow_elim___boxed(lean_object* v_motive_400_, lean_object* v_t_401_, lean_object* v_h_402_, lean_object* v_yellow_403_){
_start:
{
uint8_t v_t_boxed_404_; lean_object* v_res_405_; 
v_t_boxed_404_ = lean_unbox(v_t_401_);
v_res_405_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_TrafficLight_yellow_elim(v_motive_400_, v_t_boxed_404_, v_h_402_, v_yellow_403_);
lean_dec(v_yellow_403_);
return v_res_405_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_TrafficLight_green_elim___redArg(lean_object* v_green_406_){
_start:
{
lean_inc(v_green_406_);
return v_green_406_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_TrafficLight_green_elim___redArg___boxed(lean_object* v_green_407_){
_start:
{
lean_object* v_res_408_; 
v_res_408_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_TrafficLight_green_elim___redArg(v_green_407_);
lean_dec(v_green_407_);
return v_res_408_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_TrafficLight_green_elim(lean_object* v_motive_409_, uint8_t v_t_410_, lean_object* v_h_411_, lean_object* v_green_412_){
_start:
{
lean_inc(v_green_412_);
return v_green_412_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_TrafficLight_green_elim___boxed(lean_object* v_motive_413_, lean_object* v_t_414_, lean_object* v_h_415_, lean_object* v_green_416_){
_start:
{
uint8_t v_t_boxed_417_; lean_object* v_res_418_; 
v_t_boxed_417_ = lean_unbox(v_t_414_);
v_res_418_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_TrafficLight_green_elim(v_motive_413_, v_t_boxed_417_, v_h_415_, v_green_416_);
lean_dec(v_green_416_);
return v_res_418_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_instReprTrafficLight_repr(uint8_t v_x_428_, lean_object* v_prec_429_){
_start:
{
lean_object* v___y_431_; lean_object* v___y_438_; lean_object* v___y_445_; 
switch(v_x_428_)
{
case 0:
{
lean_object* v___x_451_; uint8_t v___x_452_; 
v___x_451_ = lean_unsigned_to_nat(1024u);
v___x_452_ = lean_nat_dec_le(v___x_451_, v_prec_429_);
if (v___x_452_ == 0)
{
lean_object* v___x_453_; 
v___x_453_ = lean_obj_once(&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_instReprWeekday_repr___closed__14, &lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_instReprWeekday_repr___closed__14_once, _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_instReprWeekday_repr___closed__14);
v___y_431_ = v___x_453_;
goto v___jp_430_;
}
else
{
lean_object* v___x_454_; 
v___x_454_ = lean_obj_once(&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_instReprWeekday_repr___closed__15, &lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_instReprWeekday_repr___closed__15_once, _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_instReprWeekday_repr___closed__15);
v___y_431_ = v___x_454_;
goto v___jp_430_;
}
}
case 1:
{
lean_object* v___x_455_; uint8_t v___x_456_; 
v___x_455_ = lean_unsigned_to_nat(1024u);
v___x_456_ = lean_nat_dec_le(v___x_455_, v_prec_429_);
if (v___x_456_ == 0)
{
lean_object* v___x_457_; 
v___x_457_ = lean_obj_once(&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_instReprWeekday_repr___closed__14, &lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_instReprWeekday_repr___closed__14_once, _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_instReprWeekday_repr___closed__14);
v___y_438_ = v___x_457_;
goto v___jp_437_;
}
else
{
lean_object* v___x_458_; 
v___x_458_ = lean_obj_once(&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_instReprWeekday_repr___closed__15, &lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_instReprWeekday_repr___closed__15_once, _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_instReprWeekday_repr___closed__15);
v___y_438_ = v___x_458_;
goto v___jp_437_;
}
}
default: 
{
lean_object* v___x_459_; uint8_t v___x_460_; 
v___x_459_ = lean_unsigned_to_nat(1024u);
v___x_460_ = lean_nat_dec_le(v___x_459_, v_prec_429_);
if (v___x_460_ == 0)
{
lean_object* v___x_461_; 
v___x_461_ = lean_obj_once(&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_instReprWeekday_repr___closed__14, &lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_instReprWeekday_repr___closed__14_once, _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_instReprWeekday_repr___closed__14);
v___y_445_ = v___x_461_;
goto v___jp_444_;
}
else
{
lean_object* v___x_462_; 
v___x_462_ = lean_obj_once(&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_instReprWeekday_repr___closed__15, &lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_instReprWeekday_repr___closed__15_once, _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_instReprWeekday_repr___closed__15);
v___y_445_ = v___x_462_;
goto v___jp_444_;
}
}
}
v___jp_430_:
{
lean_object* v___x_432_; lean_object* v___x_433_; uint8_t v___x_434_; lean_object* v___x_435_; lean_object* v___x_436_; 
v___x_432_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_instReprTrafficLight_repr___closed__1));
lean_inc(v___y_431_);
v___x_433_ = lean_alloc_ctor(4, 2, 0);
lean_ctor_set(v___x_433_, 0, v___y_431_);
lean_ctor_set(v___x_433_, 1, v___x_432_);
v___x_434_ = 0;
v___x_435_ = lean_alloc_ctor(6, 1, 1);
lean_ctor_set(v___x_435_, 0, v___x_433_);
lean_ctor_set_uint8(v___x_435_, sizeof(void*)*1, v___x_434_);
v___x_436_ = l_Repr_addAppParen(v___x_435_, v_prec_429_);
return v___x_436_;
}
v___jp_437_:
{
lean_object* v___x_439_; lean_object* v___x_440_; uint8_t v___x_441_; lean_object* v___x_442_; lean_object* v___x_443_; 
v___x_439_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_instReprTrafficLight_repr___closed__3));
lean_inc(v___y_438_);
v___x_440_ = lean_alloc_ctor(4, 2, 0);
lean_ctor_set(v___x_440_, 0, v___y_438_);
lean_ctor_set(v___x_440_, 1, v___x_439_);
v___x_441_ = 0;
v___x_442_ = lean_alloc_ctor(6, 1, 1);
lean_ctor_set(v___x_442_, 0, v___x_440_);
lean_ctor_set_uint8(v___x_442_, sizeof(void*)*1, v___x_441_);
v___x_443_ = l_Repr_addAppParen(v___x_442_, v_prec_429_);
return v___x_443_;
}
v___jp_444_:
{
lean_object* v___x_446_; lean_object* v___x_447_; uint8_t v___x_448_; lean_object* v___x_449_; lean_object* v___x_450_; 
v___x_446_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_instReprTrafficLight_repr___closed__5));
lean_inc(v___y_445_);
v___x_447_ = lean_alloc_ctor(4, 2, 0);
lean_ctor_set(v___x_447_, 0, v___y_445_);
lean_ctor_set(v___x_447_, 1, v___x_446_);
v___x_448_ = 0;
v___x_449_ = lean_alloc_ctor(6, 1, 1);
lean_ctor_set(v___x_449_, 0, v___x_447_);
lean_ctor_set_uint8(v___x_449_, sizeof(void*)*1, v___x_448_);
v___x_450_ = l_Repr_addAppParen(v___x_449_, v_prec_429_);
return v___x_450_;
}
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_instReprTrafficLight_repr___boxed(lean_object* v_x_463_, lean_object* v_prec_464_){
_start:
{
uint8_t v_x_173__boxed_465_; lean_object* v_res_466_; 
v_x_173__boxed_465_ = lean_unbox(v_x_463_);
v_res_466_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_instReprTrafficLight_repr(v_x_173__boxed_465_, v_prec_464_);
lean_dec(v_prec_464_);
return v_res_466_;
}
}
LEAN_EXPORT uint8_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_TrafficLight_ofNat(lean_object* v_n_469_){
_start:
{
lean_object* v___x_470_; uint8_t v___x_471_; 
v___x_470_ = lean_unsigned_to_nat(0u);
v___x_471_ = lean_nat_dec_le(v_n_469_, v___x_470_);
if (v___x_471_ == 0)
{
lean_object* v___x_472_; uint8_t v___x_473_; 
v___x_472_ = lean_unsigned_to_nat(1u);
v___x_473_ = lean_nat_dec_le(v_n_469_, v___x_472_);
if (v___x_473_ == 0)
{
uint8_t v___x_474_; 
v___x_474_ = 2;
return v___x_474_;
}
else
{
uint8_t v___x_475_; 
v___x_475_ = 1;
return v___x_475_;
}
}
else
{
uint8_t v___x_476_; 
v___x_476_ = 0;
return v___x_476_;
}
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_TrafficLight_ofNat___boxed(lean_object* v_n_477_){
_start:
{
uint8_t v_res_478_; lean_object* v_r_479_; 
v_res_478_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_TrafficLight_ofNat(v_n_477_);
lean_dec(v_n_477_);
v_r_479_ = lean_box(v_res_478_);
return v_r_479_;
}
}
LEAN_EXPORT uint8_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_instDecidableEqTrafficLight(uint8_t v_x_480_, uint8_t v_y_481_){
_start:
{
lean_object* v___x_482_; lean_object* v___x_483_; uint8_t v___x_484_; 
v___x_482_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_TrafficLight_ctorIdx(v_x_480_);
v___x_483_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_TrafficLight_ctorIdx(v_y_481_);
v___x_484_ = lean_nat_dec_eq(v___x_482_, v___x_483_);
lean_dec(v___x_483_);
lean_dec(v___x_482_);
return v___x_484_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_instDecidableEqTrafficLight___boxed(lean_object* v_x_485_, lean_object* v_y_486_){
_start:
{
uint8_t v_x_13__boxed_487_; uint8_t v_y_14__boxed_488_; uint8_t v_res_489_; lean_object* v_r_490_; 
v_x_13__boxed_487_ = lean_unbox(v_x_485_);
v_y_14__boxed_488_ = lean_unbox(v_y_486_);
v_res_489_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_instDecidableEqTrafficLight(v_x_13__boxed_487_, v_y_14__boxed_488_);
v_r_490_ = lean_box(v_res_489_);
return v_r_490_;
}
}
LEAN_EXPORT uint8_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_canGo(uint8_t v_light_491_){
_start:
{
if (v_light_491_ == 2)
{
uint8_t v___x_492_; 
v___x_492_ = 1;
return v___x_492_;
}
else
{
uint8_t v___x_493_; 
v___x_493_ = 0;
return v___x_493_;
}
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_canGo___boxed(lean_object* v_light_494_){
_start:
{
uint8_t v_light_boxed_495_; uint8_t v_res_496_; lean_object* v_r_497_; 
v_light_boxed_495_ = lean_unbox(v_light_494_);
v_res_496_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_canGo(v_light_boxed_495_);
v_r_497_ = lean_box(v_res_496_);
return v_r_497_;
}
}
LEAN_EXPORT uint8_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_nextLight(uint8_t v_light_498_){
_start:
{
switch(v_light_498_)
{
case 0:
{
uint8_t v___x_499_; 
v___x_499_ = 2;
return v___x_499_;
}
case 1:
{
uint8_t v___x_500_; 
v___x_500_ = 0;
return v___x_500_;
}
default: 
{
uint8_t v___x_501_; 
v___x_501_ = 1;
return v___x_501_;
}
}
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_nextLight___boxed(lean_object* v_light_502_){
_start:
{
uint8_t v_light_boxed_503_; uint8_t v_res_504_; lean_object* v_r_505_; 
v_light_boxed_503_ = lean_unbox(v_light_502_);
v_res_504_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_nextLight(v_light_boxed_503_);
v_r_505_ = lean_box(v_res_504_);
return v_r_505_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_Direction_ctorIdx(uint8_t v_x_506_){
_start:
{
switch(v_x_506_)
{
case 0:
{
lean_object* v___x_507_; 
v___x_507_ = lean_unsigned_to_nat(0u);
return v___x_507_;
}
case 1:
{
lean_object* v___x_508_; 
v___x_508_ = lean_unsigned_to_nat(1u);
return v___x_508_;
}
case 2:
{
lean_object* v___x_509_; 
v___x_509_ = lean_unsigned_to_nat(2u);
return v___x_509_;
}
default: 
{
lean_object* v___x_510_; 
v___x_510_ = lean_unsigned_to_nat(3u);
return v___x_510_;
}
}
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_Direction_ctorIdx___boxed(lean_object* v_x_511_){
_start:
{
uint8_t v_x_boxed_512_; lean_object* v_res_513_; 
v_x_boxed_512_ = lean_unbox(v_x_511_);
v_res_513_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_Direction_ctorIdx(v_x_boxed_512_);
return v_res_513_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_Direction_toCtorIdx(uint8_t v_x_514_){
_start:
{
lean_object* v___x_515_; 
v___x_515_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_Direction_ctorIdx(v_x_514_);
return v___x_515_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_Direction_toCtorIdx___boxed(lean_object* v_x_516_){
_start:
{
uint8_t v_x_4__boxed_517_; lean_object* v_res_518_; 
v_x_4__boxed_517_ = lean_unbox(v_x_516_);
v_res_518_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_Direction_toCtorIdx(v_x_4__boxed_517_);
return v_res_518_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_Direction_ctorElim___redArg(lean_object* v_k_519_){
_start:
{
lean_inc(v_k_519_);
return v_k_519_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_Direction_ctorElim___redArg___boxed(lean_object* v_k_520_){
_start:
{
lean_object* v_res_521_; 
v_res_521_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_Direction_ctorElim___redArg(v_k_520_);
lean_dec(v_k_520_);
return v_res_521_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_Direction_ctorElim(lean_object* v_motive_522_, lean_object* v_ctorIdx_523_, uint8_t v_t_524_, lean_object* v_h_525_, lean_object* v_k_526_){
_start:
{
lean_inc(v_k_526_);
return v_k_526_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_Direction_ctorElim___boxed(lean_object* v_motive_527_, lean_object* v_ctorIdx_528_, lean_object* v_t_529_, lean_object* v_h_530_, lean_object* v_k_531_){
_start:
{
uint8_t v_t_boxed_532_; lean_object* v_res_533_; 
v_t_boxed_532_ = lean_unbox(v_t_529_);
v_res_533_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_Direction_ctorElim(v_motive_527_, v_ctorIdx_528_, v_t_boxed_532_, v_h_530_, v_k_531_);
lean_dec(v_k_531_);
lean_dec(v_ctorIdx_528_);
return v_res_533_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_Direction_north_elim___redArg(lean_object* v_north_534_){
_start:
{
lean_inc(v_north_534_);
return v_north_534_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_Direction_north_elim___redArg___boxed(lean_object* v_north_535_){
_start:
{
lean_object* v_res_536_; 
v_res_536_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_Direction_north_elim___redArg(v_north_535_);
lean_dec(v_north_535_);
return v_res_536_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_Direction_north_elim(lean_object* v_motive_537_, uint8_t v_t_538_, lean_object* v_h_539_, lean_object* v_north_540_){
_start:
{
lean_inc(v_north_540_);
return v_north_540_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_Direction_north_elim___boxed(lean_object* v_motive_541_, lean_object* v_t_542_, lean_object* v_h_543_, lean_object* v_north_544_){
_start:
{
uint8_t v_t_boxed_545_; lean_object* v_res_546_; 
v_t_boxed_545_ = lean_unbox(v_t_542_);
v_res_546_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_Direction_north_elim(v_motive_541_, v_t_boxed_545_, v_h_543_, v_north_544_);
lean_dec(v_north_544_);
return v_res_546_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_Direction_south_elim___redArg(lean_object* v_south_547_){
_start:
{
lean_inc(v_south_547_);
return v_south_547_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_Direction_south_elim___redArg___boxed(lean_object* v_south_548_){
_start:
{
lean_object* v_res_549_; 
v_res_549_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_Direction_south_elim___redArg(v_south_548_);
lean_dec(v_south_548_);
return v_res_549_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_Direction_south_elim(lean_object* v_motive_550_, uint8_t v_t_551_, lean_object* v_h_552_, lean_object* v_south_553_){
_start:
{
lean_inc(v_south_553_);
return v_south_553_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_Direction_south_elim___boxed(lean_object* v_motive_554_, lean_object* v_t_555_, lean_object* v_h_556_, lean_object* v_south_557_){
_start:
{
uint8_t v_t_boxed_558_; lean_object* v_res_559_; 
v_t_boxed_558_ = lean_unbox(v_t_555_);
v_res_559_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_Direction_south_elim(v_motive_554_, v_t_boxed_558_, v_h_556_, v_south_557_);
lean_dec(v_south_557_);
return v_res_559_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_Direction_east_elim___redArg(lean_object* v_east_560_){
_start:
{
lean_inc(v_east_560_);
return v_east_560_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_Direction_east_elim___redArg___boxed(lean_object* v_east_561_){
_start:
{
lean_object* v_res_562_; 
v_res_562_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_Direction_east_elim___redArg(v_east_561_);
lean_dec(v_east_561_);
return v_res_562_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_Direction_east_elim(lean_object* v_motive_563_, uint8_t v_t_564_, lean_object* v_h_565_, lean_object* v_east_566_){
_start:
{
lean_inc(v_east_566_);
return v_east_566_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_Direction_east_elim___boxed(lean_object* v_motive_567_, lean_object* v_t_568_, lean_object* v_h_569_, lean_object* v_east_570_){
_start:
{
uint8_t v_t_boxed_571_; lean_object* v_res_572_; 
v_t_boxed_571_ = lean_unbox(v_t_568_);
v_res_572_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_Direction_east_elim(v_motive_567_, v_t_boxed_571_, v_h_569_, v_east_570_);
lean_dec(v_east_570_);
return v_res_572_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_Direction_west_elim___redArg(lean_object* v_west_573_){
_start:
{
lean_inc(v_west_573_);
return v_west_573_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_Direction_west_elim___redArg___boxed(lean_object* v_west_574_){
_start:
{
lean_object* v_res_575_; 
v_res_575_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_Direction_west_elim___redArg(v_west_574_);
lean_dec(v_west_574_);
return v_res_575_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_Direction_west_elim(lean_object* v_motive_576_, uint8_t v_t_577_, lean_object* v_h_578_, lean_object* v_west_579_){
_start:
{
lean_inc(v_west_579_);
return v_west_579_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_Direction_west_elim___boxed(lean_object* v_motive_580_, lean_object* v_t_581_, lean_object* v_h_582_, lean_object* v_west_583_){
_start:
{
uint8_t v_t_boxed_584_; lean_object* v_res_585_; 
v_t_boxed_584_ = lean_unbox(v_t_581_);
v_res_585_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_Direction_west_elim(v_motive_580_, v_t_boxed_584_, v_h_582_, v_west_583_);
lean_dec(v_west_583_);
return v_res_585_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_instReprDirection_repr(uint8_t v_x_598_, lean_object* v_prec_599_){
_start:
{
lean_object* v___y_601_; lean_object* v___y_608_; lean_object* v___y_615_; lean_object* v___y_622_; 
switch(v_x_598_)
{
case 0:
{
lean_object* v___x_628_; uint8_t v___x_629_; 
v___x_628_ = lean_unsigned_to_nat(1024u);
v___x_629_ = lean_nat_dec_le(v___x_628_, v_prec_599_);
if (v___x_629_ == 0)
{
lean_object* v___x_630_; 
v___x_630_ = lean_obj_once(&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_instReprWeekday_repr___closed__14, &lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_instReprWeekday_repr___closed__14_once, _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_instReprWeekday_repr___closed__14);
v___y_601_ = v___x_630_;
goto v___jp_600_;
}
else
{
lean_object* v___x_631_; 
v___x_631_ = lean_obj_once(&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_instReprWeekday_repr___closed__15, &lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_instReprWeekday_repr___closed__15_once, _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_instReprWeekday_repr___closed__15);
v___y_601_ = v___x_631_;
goto v___jp_600_;
}
}
case 1:
{
lean_object* v___x_632_; uint8_t v___x_633_; 
v___x_632_ = lean_unsigned_to_nat(1024u);
v___x_633_ = lean_nat_dec_le(v___x_632_, v_prec_599_);
if (v___x_633_ == 0)
{
lean_object* v___x_634_; 
v___x_634_ = lean_obj_once(&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_instReprWeekday_repr___closed__14, &lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_instReprWeekday_repr___closed__14_once, _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_instReprWeekday_repr___closed__14);
v___y_608_ = v___x_634_;
goto v___jp_607_;
}
else
{
lean_object* v___x_635_; 
v___x_635_ = lean_obj_once(&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_instReprWeekday_repr___closed__15, &lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_instReprWeekday_repr___closed__15_once, _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_instReprWeekday_repr___closed__15);
v___y_608_ = v___x_635_;
goto v___jp_607_;
}
}
case 2:
{
lean_object* v___x_636_; uint8_t v___x_637_; 
v___x_636_ = lean_unsigned_to_nat(1024u);
v___x_637_ = lean_nat_dec_le(v___x_636_, v_prec_599_);
if (v___x_637_ == 0)
{
lean_object* v___x_638_; 
v___x_638_ = lean_obj_once(&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_instReprWeekday_repr___closed__14, &lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_instReprWeekday_repr___closed__14_once, _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_instReprWeekday_repr___closed__14);
v___y_615_ = v___x_638_;
goto v___jp_614_;
}
else
{
lean_object* v___x_639_; 
v___x_639_ = lean_obj_once(&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_instReprWeekday_repr___closed__15, &lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_instReprWeekday_repr___closed__15_once, _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_instReprWeekday_repr___closed__15);
v___y_615_ = v___x_639_;
goto v___jp_614_;
}
}
default: 
{
lean_object* v___x_640_; uint8_t v___x_641_; 
v___x_640_ = lean_unsigned_to_nat(1024u);
v___x_641_ = lean_nat_dec_le(v___x_640_, v_prec_599_);
if (v___x_641_ == 0)
{
lean_object* v___x_642_; 
v___x_642_ = lean_obj_once(&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_instReprWeekday_repr___closed__14, &lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_instReprWeekday_repr___closed__14_once, _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_instReprWeekday_repr___closed__14);
v___y_622_ = v___x_642_;
goto v___jp_621_;
}
else
{
lean_object* v___x_643_; 
v___x_643_ = lean_obj_once(&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_instReprWeekday_repr___closed__15, &lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_instReprWeekday_repr___closed__15_once, _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_instReprWeekday_repr___closed__15);
v___y_622_ = v___x_643_;
goto v___jp_621_;
}
}
}
v___jp_600_:
{
lean_object* v___x_602_; lean_object* v___x_603_; uint8_t v___x_604_; lean_object* v___x_605_; lean_object* v___x_606_; 
v___x_602_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_instReprDirection_repr___closed__1));
lean_inc(v___y_601_);
v___x_603_ = lean_alloc_ctor(4, 2, 0);
lean_ctor_set(v___x_603_, 0, v___y_601_);
lean_ctor_set(v___x_603_, 1, v___x_602_);
v___x_604_ = 0;
v___x_605_ = lean_alloc_ctor(6, 1, 1);
lean_ctor_set(v___x_605_, 0, v___x_603_);
lean_ctor_set_uint8(v___x_605_, sizeof(void*)*1, v___x_604_);
v___x_606_ = l_Repr_addAppParen(v___x_605_, v_prec_599_);
return v___x_606_;
}
v___jp_607_:
{
lean_object* v___x_609_; lean_object* v___x_610_; uint8_t v___x_611_; lean_object* v___x_612_; lean_object* v___x_613_; 
v___x_609_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_instReprDirection_repr___closed__3));
lean_inc(v___y_608_);
v___x_610_ = lean_alloc_ctor(4, 2, 0);
lean_ctor_set(v___x_610_, 0, v___y_608_);
lean_ctor_set(v___x_610_, 1, v___x_609_);
v___x_611_ = 0;
v___x_612_ = lean_alloc_ctor(6, 1, 1);
lean_ctor_set(v___x_612_, 0, v___x_610_);
lean_ctor_set_uint8(v___x_612_, sizeof(void*)*1, v___x_611_);
v___x_613_ = l_Repr_addAppParen(v___x_612_, v_prec_599_);
return v___x_613_;
}
v___jp_614_:
{
lean_object* v___x_616_; lean_object* v___x_617_; uint8_t v___x_618_; lean_object* v___x_619_; lean_object* v___x_620_; 
v___x_616_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_instReprDirection_repr___closed__5));
lean_inc(v___y_615_);
v___x_617_ = lean_alloc_ctor(4, 2, 0);
lean_ctor_set(v___x_617_, 0, v___y_615_);
lean_ctor_set(v___x_617_, 1, v___x_616_);
v___x_618_ = 0;
v___x_619_ = lean_alloc_ctor(6, 1, 1);
lean_ctor_set(v___x_619_, 0, v___x_617_);
lean_ctor_set_uint8(v___x_619_, sizeof(void*)*1, v___x_618_);
v___x_620_ = l_Repr_addAppParen(v___x_619_, v_prec_599_);
return v___x_620_;
}
v___jp_621_:
{
lean_object* v___x_623_; lean_object* v___x_624_; uint8_t v___x_625_; lean_object* v___x_626_; lean_object* v___x_627_; 
v___x_623_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_instReprDirection_repr___closed__7));
lean_inc(v___y_622_);
v___x_624_ = lean_alloc_ctor(4, 2, 0);
lean_ctor_set(v___x_624_, 0, v___y_622_);
lean_ctor_set(v___x_624_, 1, v___x_623_);
v___x_625_ = 0;
v___x_626_ = lean_alloc_ctor(6, 1, 1);
lean_ctor_set(v___x_626_, 0, v___x_624_);
lean_ctor_set_uint8(v___x_626_, sizeof(void*)*1, v___x_625_);
v___x_627_ = l_Repr_addAppParen(v___x_626_, v_prec_599_);
return v___x_627_;
}
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_instReprDirection_repr___boxed(lean_object* v_x_644_, lean_object* v_prec_645_){
_start:
{
uint8_t v_x_229__boxed_646_; lean_object* v_res_647_; 
v_x_229__boxed_646_ = lean_unbox(v_x_644_);
v_res_647_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_instReprDirection_repr(v_x_229__boxed_646_, v_prec_645_);
lean_dec(v_prec_645_);
return v_res_647_;
}
}
LEAN_EXPORT uint8_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_Direction_ofNat(lean_object* v_n_650_){
_start:
{
lean_object* v___x_651_; uint8_t v___x_652_; 
v___x_651_ = lean_unsigned_to_nat(1u);
v___x_652_ = lean_nat_dec_le(v_n_650_, v___x_651_);
if (v___x_652_ == 0)
{
lean_object* v___x_653_; uint8_t v___x_654_; 
v___x_653_ = lean_unsigned_to_nat(2u);
v___x_654_ = lean_nat_dec_le(v_n_650_, v___x_653_);
if (v___x_654_ == 0)
{
uint8_t v___x_655_; 
v___x_655_ = 3;
return v___x_655_;
}
else
{
uint8_t v___x_656_; 
v___x_656_ = 2;
return v___x_656_;
}
}
else
{
lean_object* v___x_657_; uint8_t v___x_658_; 
v___x_657_ = lean_unsigned_to_nat(0u);
v___x_658_ = lean_nat_dec_le(v_n_650_, v___x_657_);
if (v___x_658_ == 0)
{
uint8_t v___x_659_; 
v___x_659_ = 1;
return v___x_659_;
}
else
{
uint8_t v___x_660_; 
v___x_660_ = 0;
return v___x_660_;
}
}
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_Direction_ofNat___boxed(lean_object* v_n_661_){
_start:
{
uint8_t v_res_662_; lean_object* v_r_663_; 
v_res_662_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_Direction_ofNat(v_n_661_);
lean_dec(v_n_661_);
v_r_663_ = lean_box(v_res_662_);
return v_r_663_;
}
}
LEAN_EXPORT uint8_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_instDecidableEqDirection(uint8_t v_x_664_, uint8_t v_y_665_){
_start:
{
lean_object* v___x_666_; lean_object* v___x_667_; uint8_t v___x_668_; 
v___x_666_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_Direction_ctorIdx(v_x_664_);
v___x_667_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_Direction_ctorIdx(v_y_665_);
v___x_668_ = lean_nat_dec_eq(v___x_666_, v___x_667_);
lean_dec(v___x_667_);
lean_dec(v___x_666_);
return v___x_668_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_instDecidableEqDirection___boxed(lean_object* v_x_669_, lean_object* v_y_670_){
_start:
{
uint8_t v_x_13__boxed_671_; uint8_t v_y_14__boxed_672_; uint8_t v_res_673_; lean_object* v_r_674_; 
v_x_13__boxed_671_ = lean_unbox(v_x_669_);
v_y_14__boxed_672_ = lean_unbox(v_y_670_);
v_res_673_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_instDecidableEqDirection(v_x_13__boxed_671_, v_y_14__boxed_672_);
v_r_674_ = lean_box(v_res_673_);
return v_r_674_;
}
}
LEAN_EXPORT uint8_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_opposite(uint8_t v_dir_675_){
_start:
{
switch(v_dir_675_)
{
case 0:
{
uint8_t v___x_676_; 
v___x_676_ = 1;
return v___x_676_;
}
case 1:
{
uint8_t v___x_677_; 
v___x_677_ = 0;
return v___x_677_;
}
case 2:
{
uint8_t v___x_678_; 
v___x_678_ = 3;
return v___x_678_;
}
default: 
{
uint8_t v___x_679_; 
v___x_679_ = 2;
return v___x_679_;
}
}
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_opposite___boxed(lean_object* v_dir_680_){
_start:
{
uint8_t v_dir_boxed_681_; uint8_t v_res_682_; lean_object* v_r_683_; 
v_dir_boxed_681_ = lean_unbox(v_dir_680_);
v_res_682_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_opposite(v_dir_boxed_681_);
v_r_683_ = lean_box(v_res_682_);
return v_r_683_;
}
}
LEAN_EXPORT uint8_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_turnLeft(uint8_t v_dir_684_){
_start:
{
switch(v_dir_684_)
{
case 0:
{
uint8_t v___x_685_; 
v___x_685_ = 3;
return v___x_685_;
}
case 1:
{
uint8_t v___x_686_; 
v___x_686_ = 2;
return v___x_686_;
}
case 2:
{
uint8_t v___x_687_; 
v___x_687_ = 0;
return v___x_687_;
}
default: 
{
uint8_t v___x_688_; 
v___x_688_ = 1;
return v___x_688_;
}
}
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_turnLeft___boxed(lean_object* v_dir_689_){
_start:
{
uint8_t v_dir_boxed_690_; uint8_t v_res_691_; lean_object* v_r_692_; 
v_dir_boxed_690_ = lean_unbox(v_dir_689_);
v_res_691_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_turnLeft(v_dir_boxed_690_);
v_r_692_ = lean_box(v_res_691_);
return v_r_692_;
}
}
LEAN_EXPORT uint8_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_turnRight(uint8_t v_dir_693_){
_start:
{
switch(v_dir_693_)
{
case 0:
{
uint8_t v___x_694_; 
v___x_694_ = 2;
return v___x_694_;
}
case 1:
{
uint8_t v___x_695_; 
v___x_695_ = 3;
return v___x_695_;
}
case 2:
{
uint8_t v___x_696_; 
v___x_696_ = 1;
return v___x_696_;
}
default: 
{
uint8_t v___x_697_; 
v___x_697_ = 0;
return v___x_697_;
}
}
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_turnRight___boxed(lean_object* v_dir_698_){
_start:
{
uint8_t v_dir_boxed_699_; uint8_t v_res_700_; lean_object* v_r_701_; 
v_dir_boxed_699_ = lean_unbox(v_dir_698_);
v_res_700_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_turnRight(v_dir_boxed_699_);
v_r_701_ = lean_box(v_res_700_);
return v_r_701_;
}
}
LEAN_EXPORT uint8_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_my__not(uint8_t v_b_702_){
_start:
{
if (v_b_702_ == 0)
{
uint8_t v___x_703_; 
v___x_703_ = 1;
return v___x_703_;
}
else
{
uint8_t v___x_704_; 
v___x_704_ = 0;
return v___x_704_;
}
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_my__not___boxed(lean_object* v_b_705_){
_start:
{
uint8_t v_b_boxed_706_; uint8_t v_res_707_; lean_object* v_r_708_; 
v_b_boxed_706_ = lean_unbox(v_b_705_);
v_res_707_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_my__not(v_b_boxed_706_);
v_r_708_ = lean_box(v_res_707_);
return v_r_708_;
}
}
LEAN_EXPORT uint8_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_my__and(uint8_t v_a_709_, uint8_t v_b_710_){
_start:
{
if (v_a_709_ == 0)
{
return v_a_709_;
}
else
{
return v_b_710_;
}
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_my__and___boxed(lean_object* v_a_711_, lean_object* v_b_712_){
_start:
{
uint8_t v_a_boxed_713_; uint8_t v_b_boxed_714_; uint8_t v_res_715_; lean_object* v_r_716_; 
v_a_boxed_713_ = lean_unbox(v_a_711_);
v_b_boxed_714_ = lean_unbox(v_b_712_);
v_res_715_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_my__and(v_a_boxed_713_, v_b_boxed_714_);
v_r_716_ = lean_box(v_res_715_);
return v_r_716_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_Shape_ctorIdx(lean_object* v_x_717_){
_start:
{
switch(lean_obj_tag(v_x_717_))
{
case 0:
{
lean_object* v___x_718_; 
v___x_718_ = lean_unsigned_to_nat(0u);
return v___x_718_;
}
case 1:
{
lean_object* v___x_719_; 
v___x_719_ = lean_unsigned_to_nat(1u);
return v___x_719_;
}
default: 
{
lean_object* v___x_720_; 
v___x_720_ = lean_unsigned_to_nat(2u);
return v___x_720_;
}
}
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_Shape_ctorIdx___boxed(lean_object* v_x_721_){
_start:
{
lean_object* v_res_722_; 
v_res_722_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_Shape_ctorIdx(v_x_721_);
lean_dec_ref(v_x_721_);
return v_res_722_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_Shape_ctorElim___redArg(lean_object* v_t_723_, lean_object* v_k_724_){
_start:
{
if (lean_obj_tag(v_t_723_) == 1)
{
lean_object* v_width_725_; lean_object* v_height_726_; lean_object* v___x_727_; 
v_width_725_ = lean_ctor_get(v_t_723_, 0);
lean_inc(v_width_725_);
v_height_726_ = lean_ctor_get(v_t_723_, 1);
lean_inc(v_height_726_);
lean_dec_ref_known(v_t_723_, 2);
v___x_727_ = lean_apply_2(v_k_724_, v_width_725_, v_height_726_);
return v___x_727_;
}
else
{
lean_object* v_radius_728_; lean_object* v___x_729_; 
v_radius_728_ = lean_ctor_get(v_t_723_, 0);
lean_inc(v_radius_728_);
lean_dec_ref(v_t_723_);
v___x_729_ = lean_apply_1(v_k_724_, v_radius_728_);
return v___x_729_;
}
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_Shape_ctorElim(lean_object* v_motive_730_, lean_object* v_ctorIdx_731_, lean_object* v_t_732_, lean_object* v_h_733_, lean_object* v_k_734_){
_start:
{
lean_object* v___x_735_; 
v___x_735_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_Shape_ctorElim___redArg(v_t_732_, v_k_734_);
return v___x_735_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_Shape_ctorElim___boxed(lean_object* v_motive_736_, lean_object* v_ctorIdx_737_, lean_object* v_t_738_, lean_object* v_h_739_, lean_object* v_k_740_){
_start:
{
lean_object* v_res_741_; 
v_res_741_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_Shape_ctorElim(v_motive_736_, v_ctorIdx_737_, v_t_738_, v_h_739_, v_k_740_);
lean_dec(v_ctorIdx_737_);
return v_res_741_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_Shape_circle_elim___redArg(lean_object* v_t_742_, lean_object* v_circle_743_){
_start:
{
lean_object* v___x_744_; 
v___x_744_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_Shape_ctorElim___redArg(v_t_742_, v_circle_743_);
return v___x_744_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_Shape_circle_elim(lean_object* v_motive_745_, lean_object* v_t_746_, lean_object* v_h_747_, lean_object* v_circle_748_){
_start:
{
lean_object* v___x_749_; 
v___x_749_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_Shape_ctorElim___redArg(v_t_746_, v_circle_748_);
return v___x_749_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_Shape_rectangle_elim___redArg(lean_object* v_t_750_, lean_object* v_rectangle_751_){
_start:
{
lean_object* v___x_752_; 
v___x_752_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_Shape_ctorElim___redArg(v_t_750_, v_rectangle_751_);
return v___x_752_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_Shape_rectangle_elim(lean_object* v_motive_753_, lean_object* v_t_754_, lean_object* v_h_755_, lean_object* v_rectangle_756_){
_start:
{
lean_object* v___x_757_; 
v___x_757_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_Shape_ctorElim___redArg(v_t_754_, v_rectangle_756_);
return v___x_757_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_Shape_square_elim___redArg(lean_object* v_t_758_, lean_object* v_square_759_){
_start:
{
lean_object* v___x_760_; 
v___x_760_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_Shape_ctorElim___redArg(v_t_758_, v_square_759_);
return v___x_760_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_Shape_square_elim(lean_object* v_motive_761_, lean_object* v_t_762_, lean_object* v_h_763_, lean_object* v_square_764_){
_start:
{
lean_object* v___x_765_; 
v___x_765_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_Shape_ctorElim___redArg(v_t_762_, v_square_764_);
return v___x_765_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_instReprShape_repr(lean_object* v_x_784_, lean_object* v_prec_785_){
_start:
{
switch(lean_obj_tag(v_x_784_))
{
case 0:
{
lean_object* v_radius_786_; lean_object* v___x_788_; uint8_t v_isShared_789_; uint8_t v_isSharedCheck_806_; 
v_radius_786_ = lean_ctor_get(v_x_784_, 0);
v_isSharedCheck_806_ = !lean_is_exclusive(v_x_784_);
if (v_isSharedCheck_806_ == 0)
{
v___x_788_ = v_x_784_;
v_isShared_789_ = v_isSharedCheck_806_;
goto v_resetjp_787_;
}
else
{
lean_inc(v_radius_786_);
lean_dec(v_x_784_);
v___x_788_ = lean_box(0);
v_isShared_789_ = v_isSharedCheck_806_;
goto v_resetjp_787_;
}
v_resetjp_787_:
{
lean_object* v___y_791_; lean_object* v___x_802_; uint8_t v___x_803_; 
v___x_802_ = lean_unsigned_to_nat(1024u);
v___x_803_ = lean_nat_dec_le(v___x_802_, v_prec_785_);
if (v___x_803_ == 0)
{
lean_object* v___x_804_; 
v___x_804_ = lean_obj_once(&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_instReprWeekday_repr___closed__14, &lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_instReprWeekday_repr___closed__14_once, _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_instReprWeekday_repr___closed__14);
v___y_791_ = v___x_804_;
goto v___jp_790_;
}
else
{
lean_object* v___x_805_; 
v___x_805_ = lean_obj_once(&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_instReprWeekday_repr___closed__15, &lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_instReprWeekday_repr___closed__15_once, _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_instReprWeekday_repr___closed__15);
v___y_791_ = v___x_805_;
goto v___jp_790_;
}
v___jp_790_:
{
lean_object* v___x_792_; lean_object* v___x_793_; lean_object* v___x_795_; 
v___x_792_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_instReprShape_repr___closed__2));
v___x_793_ = l_Nat_reprFast(v_radius_786_);
if (v_isShared_789_ == 0)
{
lean_ctor_set_tag(v___x_788_, 3);
lean_ctor_set(v___x_788_, 0, v___x_793_);
v___x_795_ = v___x_788_;
goto v_reusejp_794_;
}
else
{
lean_object* v_reuseFailAlloc_801_; 
v_reuseFailAlloc_801_ = lean_alloc_ctor(3, 1, 0);
lean_ctor_set(v_reuseFailAlloc_801_, 0, v___x_793_);
v___x_795_ = v_reuseFailAlloc_801_;
goto v_reusejp_794_;
}
v_reusejp_794_:
{
lean_object* v___x_796_; lean_object* v___x_797_; uint8_t v___x_798_; lean_object* v___x_799_; lean_object* v___x_800_; 
v___x_796_ = lean_alloc_ctor(5, 2, 0);
lean_ctor_set(v___x_796_, 0, v___x_792_);
lean_ctor_set(v___x_796_, 1, v___x_795_);
lean_inc(v___y_791_);
v___x_797_ = lean_alloc_ctor(4, 2, 0);
lean_ctor_set(v___x_797_, 0, v___y_791_);
lean_ctor_set(v___x_797_, 1, v___x_796_);
v___x_798_ = 0;
v___x_799_ = lean_alloc_ctor(6, 1, 1);
lean_ctor_set(v___x_799_, 0, v___x_797_);
lean_ctor_set_uint8(v___x_799_, sizeof(void*)*1, v___x_798_);
v___x_800_ = l_Repr_addAppParen(v___x_799_, v_prec_785_);
return v___x_800_;
}
}
}
}
case 1:
{
lean_object* v_width_807_; lean_object* v_height_808_; lean_object* v___x_810_; uint8_t v_isShared_811_; uint8_t v_isSharedCheck_833_; 
v_width_807_ = lean_ctor_get(v_x_784_, 0);
v_height_808_ = lean_ctor_get(v_x_784_, 1);
v_isSharedCheck_833_ = !lean_is_exclusive(v_x_784_);
if (v_isSharedCheck_833_ == 0)
{
v___x_810_ = v_x_784_;
v_isShared_811_ = v_isSharedCheck_833_;
goto v_resetjp_809_;
}
else
{
lean_inc(v_height_808_);
lean_inc(v_width_807_);
lean_dec(v_x_784_);
v___x_810_ = lean_box(0);
v_isShared_811_ = v_isSharedCheck_833_;
goto v_resetjp_809_;
}
v_resetjp_809_:
{
lean_object* v___y_813_; lean_object* v___x_829_; uint8_t v___x_830_; 
v___x_829_ = lean_unsigned_to_nat(1024u);
v___x_830_ = lean_nat_dec_le(v___x_829_, v_prec_785_);
if (v___x_830_ == 0)
{
lean_object* v___x_831_; 
v___x_831_ = lean_obj_once(&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_instReprWeekday_repr___closed__14, &lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_instReprWeekday_repr___closed__14_once, _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_instReprWeekday_repr___closed__14);
v___y_813_ = v___x_831_;
goto v___jp_812_;
}
else
{
lean_object* v___x_832_; 
v___x_832_ = lean_obj_once(&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_instReprWeekday_repr___closed__15, &lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_instReprWeekday_repr___closed__15_once, _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_instReprWeekday_repr___closed__15);
v___y_813_ = v___x_832_;
goto v___jp_812_;
}
v___jp_812_:
{
lean_object* v___x_814_; lean_object* v___x_815_; lean_object* v___x_816_; lean_object* v___x_817_; lean_object* v___x_819_; 
v___x_814_ = lean_box(1);
v___x_815_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_instReprShape_repr___closed__5));
v___x_816_ = l_Nat_reprFast(v_width_807_);
v___x_817_ = lean_alloc_ctor(3, 1, 0);
lean_ctor_set(v___x_817_, 0, v___x_816_);
if (v_isShared_811_ == 0)
{
lean_ctor_set_tag(v___x_810_, 5);
lean_ctor_set(v___x_810_, 1, v___x_817_);
lean_ctor_set(v___x_810_, 0, v___x_815_);
v___x_819_ = v___x_810_;
goto v_reusejp_818_;
}
else
{
lean_object* v_reuseFailAlloc_828_; 
v_reuseFailAlloc_828_ = lean_alloc_ctor(5, 2, 0);
lean_ctor_set(v_reuseFailAlloc_828_, 0, v___x_815_);
lean_ctor_set(v_reuseFailAlloc_828_, 1, v___x_817_);
v___x_819_ = v_reuseFailAlloc_828_;
goto v_reusejp_818_;
}
v_reusejp_818_:
{
lean_object* v___x_820_; lean_object* v___x_821_; lean_object* v___x_822_; lean_object* v___x_823_; lean_object* v___x_824_; uint8_t v___x_825_; lean_object* v___x_826_; lean_object* v___x_827_; 
v___x_820_ = lean_alloc_ctor(5, 2, 0);
lean_ctor_set(v___x_820_, 0, v___x_819_);
lean_ctor_set(v___x_820_, 1, v___x_814_);
v___x_821_ = l_Nat_reprFast(v_height_808_);
v___x_822_ = lean_alloc_ctor(3, 1, 0);
lean_ctor_set(v___x_822_, 0, v___x_821_);
v___x_823_ = lean_alloc_ctor(5, 2, 0);
lean_ctor_set(v___x_823_, 0, v___x_820_);
lean_ctor_set(v___x_823_, 1, v___x_822_);
lean_inc(v___y_813_);
v___x_824_ = lean_alloc_ctor(4, 2, 0);
lean_ctor_set(v___x_824_, 0, v___y_813_);
lean_ctor_set(v___x_824_, 1, v___x_823_);
v___x_825_ = 0;
v___x_826_ = lean_alloc_ctor(6, 1, 1);
lean_ctor_set(v___x_826_, 0, v___x_824_);
lean_ctor_set_uint8(v___x_826_, sizeof(void*)*1, v___x_825_);
v___x_827_ = l_Repr_addAppParen(v___x_826_, v_prec_785_);
return v___x_827_;
}
}
}
}
default: 
{
lean_object* v_side_834_; lean_object* v___x_836_; uint8_t v_isShared_837_; uint8_t v_isSharedCheck_854_; 
v_side_834_ = lean_ctor_get(v_x_784_, 0);
v_isSharedCheck_854_ = !lean_is_exclusive(v_x_784_);
if (v_isSharedCheck_854_ == 0)
{
v___x_836_ = v_x_784_;
v_isShared_837_ = v_isSharedCheck_854_;
goto v_resetjp_835_;
}
else
{
lean_inc(v_side_834_);
lean_dec(v_x_784_);
v___x_836_ = lean_box(0);
v_isShared_837_ = v_isSharedCheck_854_;
goto v_resetjp_835_;
}
v_resetjp_835_:
{
lean_object* v___y_839_; lean_object* v___x_850_; uint8_t v___x_851_; 
v___x_850_ = lean_unsigned_to_nat(1024u);
v___x_851_ = lean_nat_dec_le(v___x_850_, v_prec_785_);
if (v___x_851_ == 0)
{
lean_object* v___x_852_; 
v___x_852_ = lean_obj_once(&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_instReprWeekday_repr___closed__14, &lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_instReprWeekday_repr___closed__14_once, _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_instReprWeekday_repr___closed__14);
v___y_839_ = v___x_852_;
goto v___jp_838_;
}
else
{
lean_object* v___x_853_; 
v___x_853_ = lean_obj_once(&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_instReprWeekday_repr___closed__15, &lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_instReprWeekday_repr___closed__15_once, _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_instReprWeekday_repr___closed__15);
v___y_839_ = v___x_853_;
goto v___jp_838_;
}
v___jp_838_:
{
lean_object* v___x_840_; lean_object* v___x_841_; lean_object* v___x_843_; 
v___x_840_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_instReprShape_repr___closed__8));
v___x_841_ = l_Nat_reprFast(v_side_834_);
if (v_isShared_837_ == 0)
{
lean_ctor_set_tag(v___x_836_, 3);
lean_ctor_set(v___x_836_, 0, v___x_841_);
v___x_843_ = v___x_836_;
goto v_reusejp_842_;
}
else
{
lean_object* v_reuseFailAlloc_849_; 
v_reuseFailAlloc_849_ = lean_alloc_ctor(3, 1, 0);
lean_ctor_set(v_reuseFailAlloc_849_, 0, v___x_841_);
v___x_843_ = v_reuseFailAlloc_849_;
goto v_reusejp_842_;
}
v_reusejp_842_:
{
lean_object* v___x_844_; lean_object* v___x_845_; uint8_t v___x_846_; lean_object* v___x_847_; lean_object* v___x_848_; 
v___x_844_ = lean_alloc_ctor(5, 2, 0);
lean_ctor_set(v___x_844_, 0, v___x_840_);
lean_ctor_set(v___x_844_, 1, v___x_843_);
lean_inc(v___y_839_);
v___x_845_ = lean_alloc_ctor(4, 2, 0);
lean_ctor_set(v___x_845_, 0, v___y_839_);
lean_ctor_set(v___x_845_, 1, v___x_844_);
v___x_846_ = 0;
v___x_847_ = lean_alloc_ctor(6, 1, 1);
lean_ctor_set(v___x_847_, 0, v___x_845_);
lean_ctor_set_uint8(v___x_847_, sizeof(void*)*1, v___x_846_);
v___x_848_ = l_Repr_addAppParen(v___x_847_, v_prec_785_);
return v___x_848_;
}
}
}
}
}
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_instReprShape_repr___boxed(lean_object* v_x_855_, lean_object* v_prec_856_){
_start:
{
lean_object* v_res_857_; 
v_res_857_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_instReprShape_repr(v_x_855_, v_prec_856_);
lean_dec(v_prec_856_);
return v_res_857_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_area(lean_object* v_s_860_){
_start:
{
switch(lean_obj_tag(v_s_860_))
{
case 0:
{
lean_object* v_radius_861_; lean_object* v___x_862_; lean_object* v___x_863_; lean_object* v___x_864_; 
v_radius_861_ = lean_ctor_get(v_s_860_, 0);
v___x_862_ = lean_nat_mul(v_radius_861_, v_radius_861_);
v___x_863_ = lean_unsigned_to_nat(3u);
v___x_864_ = lean_nat_mul(v___x_862_, v___x_863_);
lean_dec(v___x_862_);
return v___x_864_;
}
case 1:
{
lean_object* v_width_865_; lean_object* v_height_866_; lean_object* v___x_867_; 
v_width_865_ = lean_ctor_get(v_s_860_, 0);
v_height_866_ = lean_ctor_get(v_s_860_, 1);
v___x_867_ = lean_nat_mul(v_width_865_, v_height_866_);
return v___x_867_;
}
default: 
{
lean_object* v_side_868_; lean_object* v___x_869_; 
v_side_868_ = lean_ctor_get(v_s_860_, 0);
v___x_869_ = lean_nat_mul(v_side_868_, v_side_868_);
return v___x_869_;
}
}
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_area___boxed(lean_object* v_s_870_){
_start:
{
lean_object* v_res_871_; 
v_res_871_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_area(v_s_870_);
lean_dec_ref(v_s_870_);
return v_res_871_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_circle__area___closed__1(void){
_start:
{
lean_object* v___x_874_; lean_object* v___x_875_; 
v___x_874_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_circle__area___closed__0));
v___x_875_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_area(v___x_874_);
return v___x_875_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_circle__area(void){
_start:
{
lean_object* v___x_876_; 
v___x_876_ = lean_obj_once(&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_circle__area___closed__1, &lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_circle__area___closed__1_once, _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_circle__area___closed__1);
return v___x_876_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_rect__area___closed__1(void){
_start:
{
lean_object* v___x_880_; lean_object* v___x_881_; 
v___x_880_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_rect__area___closed__0));
v___x_881_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_area(v___x_880_);
return v___x_881_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_rect__area(void){
_start:
{
lean_object* v___x_882_; 
v___x_882_ = lean_obj_once(&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_rect__area___closed__1, &lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_rect__area___closed__1_once, _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_rect__area___closed__1);
return v___x_882_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_square__area___closed__1(void){
_start:
{
lean_object* v___x_885_; lean_object* v___x_886_; 
v___x_885_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_square__area___closed__0));
v___x_886_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_area(v___x_885_);
return v___x_886_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_square__area(void){
_start:
{
lean_object* v___x_887_; 
v___x_887_ = lean_obj_once(&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_square__area___closed__1, &lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_square__area___closed__1_once, _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_square__area___closed__1);
return v___x_887_;
}
}
lean_object* initialize_Init(uint8_t builtin);
lean_object* initialize_Init(uint8_t builtin);
static bool _G_initialized = false;
LEAN_EXPORT lean_object* initialize_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums(uint8_t builtin) {
lean_object * res;
if (_G_initialized) return lean_io_result_mk_ok(lean_box(0));
_G_initialized = true;
res = initialize_Init(builtin);
if (lean_io_result_is_error(res)) return res;
lean_dec_ref(res);
res = initialize_Init(builtin);
if (lean_io_result_is_error(res)) return res;
lean_dec_ref(res);
lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_today = _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_today();
lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_weekend__start = _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_weekend__start();
lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_monday__is__weekday = _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_monday__is__weekday();
lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_saturday__is__weekend = _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_saturday__is__weekend();
lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_next__monday = _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_next__monday();
lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_prev__monday = _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_prev__monday();
lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_wed__plus__three = _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_wed__plus__three();
lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_print__monday = _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_print__monday();
lean_mark_persistent(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_print__monday);
lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_circle__area = _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_circle__area();
lean_mark_persistent(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_circle__area);
lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_rect__area = _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_rect__area();
lean_mark_persistent(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_rect__area);
lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_square__area = _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_square__area();
lean_mark_persistent(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_Enums_square__area);
return lean_io_result_mk_ok(lean_box(0));
}
#ifdef __cplusplus
}
#endif
