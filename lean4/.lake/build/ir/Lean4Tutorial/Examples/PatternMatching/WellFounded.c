// Lean compiler output
// Module: Lean4Tutorial.Examples.PatternMatching.WellFounded
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
uint8_t lean_nat_dec_eq(lean_object*, lean_object*);
lean_object* lean_nat_add(lean_object*, lean_object*);
lean_object* lean_nat_sub(lean_object*, lean_object*);
lean_object* lean_nat_mod(lean_object*, lean_object*);
lean_object* l_List_reverse___redArg(lean_object*);
uint8_t lean_nat_dec_le(lean_object*, lean_object*);
uint8_t lean_nat_dec_lt(lean_object*, lean_object*);
lean_object* l_List_appendTR___redArg(lean_object*, lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_WellFounded_ackermann(lean_object*, lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial___private_Lean4Tutorial_Examples_PatternMatching_WellFounded_0__Lean4Tutorial_Examples_PatternMatching_WellFounded_ackermann_match__1_splitter___redArg(lean_object*, lean_object*, lean_object*, lean_object*, lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial___private_Lean4Tutorial_Examples_PatternMatching_WellFounded_0__Lean4Tutorial_Examples_PatternMatching_WellFounded_ackermann_match__1_splitter___redArg___boxed(lean_object*, lean_object*, lean_object*, lean_object*, lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial___private_Lean4Tutorial_Examples_PatternMatching_WellFounded_0__Lean4Tutorial_Examples_PatternMatching_WellFounded_ackermann_match__1_splitter(lean_object*, lean_object*, lean_object*, lean_object*, lean_object*, lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial___private_Lean4Tutorial_Examples_PatternMatching_WellFounded_0__Lean4Tutorial_Examples_PatternMatching_WellFounded_ackermann_match__1_splitter___boxed(lean_object*, lean_object*, lean_object*, lean_object*, lean_object*, lean_object*);
static lean_once_cell_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_WellFounded_ack__0__5___closed__0_once = LEAN_ONCE_CELL_INITIALIZER;
static lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_WellFounded_ack__0__5___closed__0;
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_WellFounded_ack__0__5;
static lean_once_cell_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_WellFounded_ack__1__5___closed__0_once = LEAN_ONCE_CELL_INITIALIZER;
static lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_WellFounded_ack__1__5___closed__0;
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_WellFounded_ack__1__5;
static lean_once_cell_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_WellFounded_ack__2__3___closed__0_once = LEAN_ONCE_CELL_INITIALIZER;
static lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_WellFounded_ack__2__3___closed__0;
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_WellFounded_ack__2__3;
static lean_once_cell_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_WellFounded_ack__3__2___closed__0_once = LEAN_ONCE_CELL_INITIALIZER;
static lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_WellFounded_ack__3__2___closed__0;
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_WellFounded_ack__3__2;
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_WellFounded_gcd(lean_object*, lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial___private_Lean4Tutorial_Examples_PatternMatching_WellFounded_0__Lean4Tutorial_Examples_PatternMatching_WellFounded_gcd_match__1_splitter___redArg(lean_object*, lean_object*, lean_object*, lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial___private_Lean4Tutorial_Examples_PatternMatching_WellFounded_0__Lean4Tutorial_Examples_PatternMatching_WellFounded_gcd_match__1_splitter___redArg___boxed(lean_object*, lean_object*, lean_object*, lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial___private_Lean4Tutorial_Examples_PatternMatching_WellFounded_0__Lean4Tutorial_Examples_PatternMatching_WellFounded_gcd_match__1_splitter(lean_object*, lean_object*, lean_object*, lean_object*, lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial___private_Lean4Tutorial_Examples_PatternMatching_WellFounded_0__Lean4Tutorial_Examples_PatternMatching_WellFounded_gcd_match__1_splitter___boxed(lean_object*, lean_object*, lean_object*, lean_object*, lean_object*);
static lean_once_cell_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_WellFounded_gcd__48__18___closed__0_once = LEAN_ONCE_CELL_INITIALIZER;
static lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_WellFounded_gcd__48__18___closed__0;
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_WellFounded_gcd__48__18;
static lean_once_cell_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_WellFounded_gcd__100__75___closed__0_once = LEAN_ONCE_CELL_INITIALIZER;
static lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_WellFounded_gcd__100__75___closed__0;
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_WellFounded_gcd__100__75;
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_List_filterTR_loop___at___00Lean4Tutorial_Examples_PatternMatching_WellFounded_quicksort_spec__0(lean_object*, lean_object*, lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_List_filterTR_loop___at___00Lean4Tutorial_Examples_PatternMatching_WellFounded_quicksort_spec__0___boxed(lean_object*, lean_object*, lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_List_filterTR_loop___at___00Lean4Tutorial_Examples_PatternMatching_WellFounded_quicksort_spec__1(lean_object*, lean_object*, lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_List_filterTR_loop___at___00Lean4Tutorial_Examples_PatternMatching_WellFounded_quicksort_spec__1___boxed(lean_object*, lean_object*, lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_WellFounded_quicksort(lean_object*);
static const lean_ctor_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_WellFounded_qsort__example___closed__0_value = {.m_header = {.m_rc = 0, .m_cs_sz = sizeof(lean_ctor_object) + sizeof(void*)*2 + 0, .m_other = 2, .m_tag = 1}, .m_objs = {((lean_object*)(((size_t)(6) << 1) | 1)),((lean_object*)(((size_t)(0) << 1) | 1))}};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_WellFounded_qsort__example___closed__0 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_WellFounded_qsort__example___closed__0_value;
static const lean_ctor_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_WellFounded_qsort__example___closed__1_value = {.m_header = {.m_rc = 0, .m_cs_sz = sizeof(lean_ctor_object) + sizeof(void*)*2 + 0, .m_other = 2, .m_tag = 1}, .m_objs = {((lean_object*)(((size_t)(2) << 1) | 1)),((lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_WellFounded_qsort__example___closed__0_value)}};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_WellFounded_qsort__example___closed__1 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_WellFounded_qsort__example___closed__1_value;
static const lean_ctor_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_WellFounded_qsort__example___closed__2_value = {.m_header = {.m_rc = 0, .m_cs_sz = sizeof(lean_ctor_object) + sizeof(void*)*2 + 0, .m_other = 2, .m_tag = 1}, .m_objs = {((lean_object*)(((size_t)(9) << 1) | 1)),((lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_WellFounded_qsort__example___closed__1_value)}};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_WellFounded_qsort__example___closed__2 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_WellFounded_qsort__example___closed__2_value;
static const lean_ctor_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_WellFounded_qsort__example___closed__3_value = {.m_header = {.m_rc = 0, .m_cs_sz = sizeof(lean_ctor_object) + sizeof(void*)*2 + 0, .m_other = 2, .m_tag = 1}, .m_objs = {((lean_object*)(((size_t)(5) << 1) | 1)),((lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_WellFounded_qsort__example___closed__2_value)}};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_WellFounded_qsort__example___closed__3 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_WellFounded_qsort__example___closed__3_value;
static const lean_ctor_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_WellFounded_qsort__example___closed__4_value = {.m_header = {.m_rc = 0, .m_cs_sz = sizeof(lean_ctor_object) + sizeof(void*)*2 + 0, .m_other = 2, .m_tag = 1}, .m_objs = {((lean_object*)(((size_t)(1) << 1) | 1)),((lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_WellFounded_qsort__example___closed__3_value)}};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_WellFounded_qsort__example___closed__4 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_WellFounded_qsort__example___closed__4_value;
static const lean_ctor_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_WellFounded_qsort__example___closed__5_value = {.m_header = {.m_rc = 0, .m_cs_sz = sizeof(lean_ctor_object) + sizeof(void*)*2 + 0, .m_other = 2, .m_tag = 1}, .m_objs = {((lean_object*)(((size_t)(4) << 1) | 1)),((lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_WellFounded_qsort__example___closed__4_value)}};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_WellFounded_qsort__example___closed__5 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_WellFounded_qsort__example___closed__5_value;
static const lean_ctor_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_WellFounded_qsort__example___closed__6_value = {.m_header = {.m_rc = 0, .m_cs_sz = sizeof(lean_ctor_object) + sizeof(void*)*2 + 0, .m_other = 2, .m_tag = 1}, .m_objs = {((lean_object*)(((size_t)(1) << 1) | 1)),((lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_WellFounded_qsort__example___closed__5_value)}};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_WellFounded_qsort__example___closed__6 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_WellFounded_qsort__example___closed__6_value;
static const lean_ctor_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_WellFounded_qsort__example___closed__7_value = {.m_header = {.m_rc = 0, .m_cs_sz = sizeof(lean_ctor_object) + sizeof(void*)*2 + 0, .m_other = 2, .m_tag = 1}, .m_objs = {((lean_object*)(((size_t)(3) << 1) | 1)),((lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_WellFounded_qsort__example___closed__6_value)}};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_WellFounded_qsort__example___closed__7 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_WellFounded_qsort__example___closed__7_value;
static lean_once_cell_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_WellFounded_qsort__example___closed__8_once = LEAN_ONCE_CELL_INITIALIZER;
static lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_WellFounded_qsort__example___closed__8;
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_WellFounded_qsort__example;
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_WellFounded_fastFib_go(lean_object*, lean_object*, lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_WellFounded_fastFib(lean_object*);
static lean_once_cell_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_WellFounded_fast__fib__10___closed__0_once = LEAN_ONCE_CELL_INITIALIZER;
static lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_WellFounded_fast__fib__10___closed__0;
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_WellFounded_fast__fib__10;
static lean_once_cell_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_WellFounded_fast__fib__20___closed__0_once = LEAN_ONCE_CELL_INITIALIZER;
static lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_WellFounded_fast__fib__20___closed__0;
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_WellFounded_fast__fib__20;
static lean_once_cell_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_WellFounded_fast__fib__30___closed__0_once = LEAN_ONCE_CELL_INITIALIZER;
static lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_WellFounded_fast__fib__30___closed__0;
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_WellFounded_fast__fib__30;
LEAN_EXPORT uint8_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_WellFounded_isOdd(lean_object*);
LEAN_EXPORT uint8_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_WellFounded_isEven(lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_WellFounded_isEven___boxed(lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_WellFounded_isOdd___boxed(lean_object*);
static lean_once_cell_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_WellFounded_even__0___closed__0_once = LEAN_ONCE_CELL_INITIALIZER;
static uint8_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_WellFounded_even__0___closed__0;
LEAN_EXPORT uint8_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_WellFounded_even__0;
static lean_once_cell_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_WellFounded_even__4___closed__0_once = LEAN_ONCE_CELL_INITIALIZER;
static uint8_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_WellFounded_even__4___closed__0;
LEAN_EXPORT uint8_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_WellFounded_even__4;
static lean_once_cell_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_WellFounded_odd__5___closed__0_once = LEAN_ONCE_CELL_INITIALIZER;
static uint8_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_WellFounded_odd__5___closed__0;
LEAN_EXPORT uint8_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_WellFounded_odd__5;
static lean_once_cell_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_WellFounded_odd__4___closed__0_once = LEAN_ONCE_CELL_INITIALIZER;
static uint8_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_WellFounded_odd__4___closed__0;
LEAN_EXPORT uint8_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_WellFounded_odd__4;
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_WellFounded_ackermann(lean_object* v_x_1_, lean_object* v_x_2_){
_start:
{
lean_object* v_zero_3_; uint8_t v_isZero_4_; 
v_zero_3_ = lean_unsigned_to_nat(0u);
v_isZero_4_ = lean_nat_dec_eq(v_x_1_, v_zero_3_);
if (v_isZero_4_ == 1)
{
lean_object* v___x_5_; lean_object* v___x_6_; 
lean_dec(v_x_1_);
v___x_5_ = lean_unsigned_to_nat(1u);
v___x_6_ = lean_nat_add(v_x_2_, v___x_5_);
lean_dec(v_x_2_);
return v___x_6_;
}
else
{
lean_object* v_one_7_; lean_object* v_n_8_; uint8_t v_isZero_9_; 
v_one_7_ = lean_unsigned_to_nat(1u);
v_n_8_ = lean_nat_sub(v_x_1_, v_one_7_);
lean_dec(v_x_1_);
v_isZero_9_ = lean_nat_dec_eq(v_x_2_, v_zero_3_);
if (v_isZero_9_ == 1)
{
lean_dec(v_x_2_);
v_x_1_ = v_n_8_;
v_x_2_ = v_one_7_;
goto _start;
}
else
{
lean_object* v_n_11_; lean_object* v___x_12_; lean_object* v___x_13_; 
v_n_11_ = lean_nat_sub(v_x_2_, v_one_7_);
lean_dec(v_x_2_);
v___x_12_ = lean_nat_add(v_n_8_, v_one_7_);
v___x_13_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_WellFounded_ackermann(v___x_12_, v_n_11_);
v_x_1_ = v_n_8_;
v_x_2_ = v___x_13_;
goto _start;
}
}
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial___private_Lean4Tutorial_Examples_PatternMatching_WellFounded_0__Lean4Tutorial_Examples_PatternMatching_WellFounded_ackermann_match__1_splitter___redArg(lean_object* v_x_15_, lean_object* v_x_16_, lean_object* v_h__1_17_, lean_object* v_h__2_18_, lean_object* v_h__3_19_){
_start:
{
lean_object* v_zero_20_; uint8_t v_isZero_21_; 
v_zero_20_ = lean_unsigned_to_nat(0u);
v_isZero_21_ = lean_nat_dec_eq(v_x_15_, v_zero_20_);
if (v_isZero_21_ == 1)
{
lean_object* v___x_22_; 
lean_dec(v_h__3_19_);
lean_dec(v_h__2_18_);
v___x_22_ = lean_apply_1(v_h__1_17_, v_x_16_);
return v___x_22_;
}
else
{
lean_object* v_one_23_; lean_object* v_n_24_; uint8_t v_isZero_25_; 
lean_dec(v_h__1_17_);
v_one_23_ = lean_unsigned_to_nat(1u);
v_n_24_ = lean_nat_sub(v_x_15_, v_one_23_);
v_isZero_25_ = lean_nat_dec_eq(v_x_16_, v_zero_20_);
if (v_isZero_25_ == 1)
{
lean_object* v___x_26_; 
lean_dec(v_h__3_19_);
lean_dec(v_x_16_);
v___x_26_ = lean_apply_1(v_h__2_18_, v_n_24_);
return v___x_26_;
}
else
{
lean_object* v_n_27_; lean_object* v___x_28_; 
lean_dec(v_h__2_18_);
v_n_27_ = lean_nat_sub(v_x_16_, v_one_23_);
lean_dec(v_x_16_);
v___x_28_ = lean_apply_2(v_h__3_19_, v_n_24_, v_n_27_);
return v___x_28_;
}
}
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial___private_Lean4Tutorial_Examples_PatternMatching_WellFounded_0__Lean4Tutorial_Examples_PatternMatching_WellFounded_ackermann_match__1_splitter___redArg___boxed(lean_object* v_x_29_, lean_object* v_x_30_, lean_object* v_h__1_31_, lean_object* v_h__2_32_, lean_object* v_h__3_33_){
_start:
{
lean_object* v_res_34_; 
v_res_34_ = lp_lean4_x2dtutorial___private_Lean4Tutorial_Examples_PatternMatching_WellFounded_0__Lean4Tutorial_Examples_PatternMatching_WellFounded_ackermann_match__1_splitter___redArg(v_x_29_, v_x_30_, v_h__1_31_, v_h__2_32_, v_h__3_33_);
lean_dec(v_x_29_);
return v_res_34_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial___private_Lean4Tutorial_Examples_PatternMatching_WellFounded_0__Lean4Tutorial_Examples_PatternMatching_WellFounded_ackermann_match__1_splitter(lean_object* v_motive_35_, lean_object* v_x_36_, lean_object* v_x_37_, lean_object* v_h__1_38_, lean_object* v_h__2_39_, lean_object* v_h__3_40_){
_start:
{
lean_object* v_zero_41_; uint8_t v_isZero_42_; 
v_zero_41_ = lean_unsigned_to_nat(0u);
v_isZero_42_ = lean_nat_dec_eq(v_x_36_, v_zero_41_);
if (v_isZero_42_ == 1)
{
lean_object* v___x_43_; 
lean_dec(v_h__3_40_);
lean_dec(v_h__2_39_);
v___x_43_ = lean_apply_1(v_h__1_38_, v_x_37_);
return v___x_43_;
}
else
{
lean_object* v_one_44_; lean_object* v_n_45_; uint8_t v_isZero_46_; 
lean_dec(v_h__1_38_);
v_one_44_ = lean_unsigned_to_nat(1u);
v_n_45_ = lean_nat_sub(v_x_36_, v_one_44_);
v_isZero_46_ = lean_nat_dec_eq(v_x_37_, v_zero_41_);
if (v_isZero_46_ == 1)
{
lean_object* v___x_47_; 
lean_dec(v_h__3_40_);
lean_dec(v_x_37_);
v___x_47_ = lean_apply_1(v_h__2_39_, v_n_45_);
return v___x_47_;
}
else
{
lean_object* v_n_48_; lean_object* v___x_49_; 
lean_dec(v_h__2_39_);
v_n_48_ = lean_nat_sub(v_x_37_, v_one_44_);
lean_dec(v_x_37_);
v___x_49_ = lean_apply_2(v_h__3_40_, v_n_45_, v_n_48_);
return v___x_49_;
}
}
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial___private_Lean4Tutorial_Examples_PatternMatching_WellFounded_0__Lean4Tutorial_Examples_PatternMatching_WellFounded_ackermann_match__1_splitter___boxed(lean_object* v_motive_50_, lean_object* v_x_51_, lean_object* v_x_52_, lean_object* v_h__1_53_, lean_object* v_h__2_54_, lean_object* v_h__3_55_){
_start:
{
lean_object* v_res_56_; 
v_res_56_ = lp_lean4_x2dtutorial___private_Lean4Tutorial_Examples_PatternMatching_WellFounded_0__Lean4Tutorial_Examples_PatternMatching_WellFounded_ackermann_match__1_splitter(v_motive_50_, v_x_51_, v_x_52_, v_h__1_53_, v_h__2_54_, v_h__3_55_);
lean_dec(v_x_51_);
return v_res_56_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_WellFounded_ack__0__5___closed__0(void){
_start:
{
lean_object* v___x_57_; lean_object* v___x_58_; lean_object* v___x_59_; 
v___x_57_ = lean_unsigned_to_nat(5u);
v___x_58_ = lean_unsigned_to_nat(0u);
v___x_59_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_WellFounded_ackermann(v___x_58_, v___x_57_);
return v___x_59_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_WellFounded_ack__0__5(void){
_start:
{
lean_object* v___x_60_; 
v___x_60_ = lean_obj_once(&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_WellFounded_ack__0__5___closed__0, &lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_WellFounded_ack__0__5___closed__0_once, _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_WellFounded_ack__0__5___closed__0);
return v___x_60_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_WellFounded_ack__1__5___closed__0(void){
_start:
{
lean_object* v___x_61_; lean_object* v___x_62_; lean_object* v___x_63_; 
v___x_61_ = lean_unsigned_to_nat(5u);
v___x_62_ = lean_unsigned_to_nat(1u);
v___x_63_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_WellFounded_ackermann(v___x_62_, v___x_61_);
return v___x_63_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_WellFounded_ack__1__5(void){
_start:
{
lean_object* v___x_64_; 
v___x_64_ = lean_obj_once(&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_WellFounded_ack__1__5___closed__0, &lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_WellFounded_ack__1__5___closed__0_once, _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_WellFounded_ack__1__5___closed__0);
return v___x_64_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_WellFounded_ack__2__3___closed__0(void){
_start:
{
lean_object* v___x_65_; lean_object* v___x_66_; lean_object* v___x_67_; 
v___x_65_ = lean_unsigned_to_nat(3u);
v___x_66_ = lean_unsigned_to_nat(2u);
v___x_67_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_WellFounded_ackermann(v___x_66_, v___x_65_);
return v___x_67_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_WellFounded_ack__2__3(void){
_start:
{
lean_object* v___x_68_; 
v___x_68_ = lean_obj_once(&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_WellFounded_ack__2__3___closed__0, &lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_WellFounded_ack__2__3___closed__0_once, _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_WellFounded_ack__2__3___closed__0);
return v___x_68_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_WellFounded_ack__3__2___closed__0(void){
_start:
{
lean_object* v___x_69_; lean_object* v___x_70_; lean_object* v___x_71_; 
v___x_69_ = lean_unsigned_to_nat(2u);
v___x_70_ = lean_unsigned_to_nat(3u);
v___x_71_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_WellFounded_ackermann(v___x_70_, v___x_69_);
return v___x_71_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_WellFounded_ack__3__2(void){
_start:
{
lean_object* v___x_72_; 
v___x_72_ = lean_obj_once(&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_WellFounded_ack__3__2___closed__0, &lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_WellFounded_ack__3__2___closed__0_once, _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_WellFounded_ack__3__2___closed__0);
return v___x_72_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_WellFounded_gcd(lean_object* v_x_73_, lean_object* v_x_74_){
_start:
{
lean_object* v_zero_75_; uint8_t v_isZero_76_; 
v_zero_75_ = lean_unsigned_to_nat(0u);
v_isZero_76_ = lean_nat_dec_eq(v_x_74_, v_zero_75_);
if (v_isZero_76_ == 1)
{
lean_dec(v_x_74_);
return v_x_73_;
}
else
{
lean_object* v_one_77_; lean_object* v_n_78_; lean_object* v___x_79_; lean_object* v___x_80_; 
v_one_77_ = lean_unsigned_to_nat(1u);
v_n_78_ = lean_nat_sub(v_x_74_, v_one_77_);
lean_dec(v_x_74_);
v___x_79_ = lean_nat_add(v_n_78_, v_one_77_);
lean_dec(v_n_78_);
v___x_80_ = lean_nat_mod(v_x_73_, v___x_79_);
lean_dec(v_x_73_);
v_x_73_ = v___x_79_;
v_x_74_ = v___x_80_;
goto _start;
}
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial___private_Lean4Tutorial_Examples_PatternMatching_WellFounded_0__Lean4Tutorial_Examples_PatternMatching_WellFounded_gcd_match__1_splitter___redArg(lean_object* v_x_82_, lean_object* v_x_83_, lean_object* v_h__1_84_, lean_object* v_h__2_85_){
_start:
{
lean_object* v_zero_86_; uint8_t v_isZero_87_; 
v_zero_86_ = lean_unsigned_to_nat(0u);
v_isZero_87_ = lean_nat_dec_eq(v_x_83_, v_zero_86_);
if (v_isZero_87_ == 1)
{
lean_object* v___x_88_; 
lean_dec(v_h__2_85_);
v___x_88_ = lean_apply_1(v_h__1_84_, v_x_82_);
return v___x_88_;
}
else
{
lean_object* v_one_89_; lean_object* v_n_90_; lean_object* v___x_91_; 
lean_dec(v_h__1_84_);
v_one_89_ = lean_unsigned_to_nat(1u);
v_n_90_ = lean_nat_sub(v_x_83_, v_one_89_);
v___x_91_ = lean_apply_2(v_h__2_85_, v_x_82_, v_n_90_);
return v___x_91_;
}
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial___private_Lean4Tutorial_Examples_PatternMatching_WellFounded_0__Lean4Tutorial_Examples_PatternMatching_WellFounded_gcd_match__1_splitter___redArg___boxed(lean_object* v_x_92_, lean_object* v_x_93_, lean_object* v_h__1_94_, lean_object* v_h__2_95_){
_start:
{
lean_object* v_res_96_; 
v_res_96_ = lp_lean4_x2dtutorial___private_Lean4Tutorial_Examples_PatternMatching_WellFounded_0__Lean4Tutorial_Examples_PatternMatching_WellFounded_gcd_match__1_splitter___redArg(v_x_92_, v_x_93_, v_h__1_94_, v_h__2_95_);
lean_dec(v_x_93_);
return v_res_96_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial___private_Lean4Tutorial_Examples_PatternMatching_WellFounded_0__Lean4Tutorial_Examples_PatternMatching_WellFounded_gcd_match__1_splitter(lean_object* v_motive_97_, lean_object* v_x_98_, lean_object* v_x_99_, lean_object* v_h__1_100_, lean_object* v_h__2_101_){
_start:
{
lean_object* v_zero_102_; uint8_t v_isZero_103_; 
v_zero_102_ = lean_unsigned_to_nat(0u);
v_isZero_103_ = lean_nat_dec_eq(v_x_99_, v_zero_102_);
if (v_isZero_103_ == 1)
{
lean_object* v___x_104_; 
lean_dec(v_h__2_101_);
v___x_104_ = lean_apply_1(v_h__1_100_, v_x_98_);
return v___x_104_;
}
else
{
lean_object* v_one_105_; lean_object* v_n_106_; lean_object* v___x_107_; 
lean_dec(v_h__1_100_);
v_one_105_ = lean_unsigned_to_nat(1u);
v_n_106_ = lean_nat_sub(v_x_99_, v_one_105_);
v___x_107_ = lean_apply_2(v_h__2_101_, v_x_98_, v_n_106_);
return v___x_107_;
}
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial___private_Lean4Tutorial_Examples_PatternMatching_WellFounded_0__Lean4Tutorial_Examples_PatternMatching_WellFounded_gcd_match__1_splitter___boxed(lean_object* v_motive_108_, lean_object* v_x_109_, lean_object* v_x_110_, lean_object* v_h__1_111_, lean_object* v_h__2_112_){
_start:
{
lean_object* v_res_113_; 
v_res_113_ = lp_lean4_x2dtutorial___private_Lean4Tutorial_Examples_PatternMatching_WellFounded_0__Lean4Tutorial_Examples_PatternMatching_WellFounded_gcd_match__1_splitter(v_motive_108_, v_x_109_, v_x_110_, v_h__1_111_, v_h__2_112_);
lean_dec(v_x_110_);
return v_res_113_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_WellFounded_gcd__48__18___closed__0(void){
_start:
{
lean_object* v___x_114_; lean_object* v___x_115_; lean_object* v___x_116_; 
v___x_114_ = lean_unsigned_to_nat(18u);
v___x_115_ = lean_unsigned_to_nat(48u);
v___x_116_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_WellFounded_gcd(v___x_115_, v___x_114_);
return v___x_116_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_WellFounded_gcd__48__18(void){
_start:
{
lean_object* v___x_117_; 
v___x_117_ = lean_obj_once(&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_WellFounded_gcd__48__18___closed__0, &lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_WellFounded_gcd__48__18___closed__0_once, _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_WellFounded_gcd__48__18___closed__0);
return v___x_117_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_WellFounded_gcd__100__75___closed__0(void){
_start:
{
lean_object* v___x_118_; lean_object* v___x_119_; lean_object* v___x_120_; 
v___x_118_ = lean_unsigned_to_nat(75u);
v___x_119_ = lean_unsigned_to_nat(100u);
v___x_120_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_WellFounded_gcd(v___x_119_, v___x_118_);
return v___x_120_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_WellFounded_gcd__100__75(void){
_start:
{
lean_object* v___x_121_; 
v___x_121_ = lean_obj_once(&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_WellFounded_gcd__100__75___closed__0, &lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_WellFounded_gcd__100__75___closed__0_once, _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_WellFounded_gcd__100__75___closed__0);
return v___x_121_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_List_filterTR_loop___at___00Lean4Tutorial_Examples_PatternMatching_WellFounded_quicksort_spec__0(lean_object* v_head_122_, lean_object* v_a_123_, lean_object* v_a_124_){
_start:
{
if (lean_obj_tag(v_a_123_) == 0)
{
lean_object* v___x_125_; 
v___x_125_ = l_List_reverse___redArg(v_a_124_);
return v___x_125_;
}
else
{
lean_object* v_head_126_; lean_object* v_tail_127_; lean_object* v___x_129_; uint8_t v_isShared_130_; uint8_t v_isSharedCheck_137_; 
v_head_126_ = lean_ctor_get(v_a_123_, 0);
v_tail_127_ = lean_ctor_get(v_a_123_, 1);
v_isSharedCheck_137_ = !lean_is_exclusive(v_a_123_);
if (v_isSharedCheck_137_ == 0)
{
v___x_129_ = v_a_123_;
v_isShared_130_ = v_isSharedCheck_137_;
goto v_resetjp_128_;
}
else
{
lean_inc(v_tail_127_);
lean_inc(v_head_126_);
lean_dec(v_a_123_);
v___x_129_ = lean_box(0);
v_isShared_130_ = v_isSharedCheck_137_;
goto v_resetjp_128_;
}
v_resetjp_128_:
{
uint8_t v___x_131_; 
v___x_131_ = lean_nat_dec_le(v_head_126_, v_head_122_);
if (v___x_131_ == 0)
{
lean_del_object(v___x_129_);
lean_dec(v_head_126_);
v_a_123_ = v_tail_127_;
goto _start;
}
else
{
lean_object* v___x_134_; 
if (v_isShared_130_ == 0)
{
lean_ctor_set(v___x_129_, 1, v_a_124_);
v___x_134_ = v___x_129_;
goto v_reusejp_133_;
}
else
{
lean_object* v_reuseFailAlloc_136_; 
v_reuseFailAlloc_136_ = lean_alloc_ctor(1, 2, 0);
lean_ctor_set(v_reuseFailAlloc_136_, 0, v_head_126_);
lean_ctor_set(v_reuseFailAlloc_136_, 1, v_a_124_);
v___x_134_ = v_reuseFailAlloc_136_;
goto v_reusejp_133_;
}
v_reusejp_133_:
{
v_a_123_ = v_tail_127_;
v_a_124_ = v___x_134_;
goto _start;
}
}
}
}
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_List_filterTR_loop___at___00Lean4Tutorial_Examples_PatternMatching_WellFounded_quicksort_spec__0___boxed(lean_object* v_head_138_, lean_object* v_a_139_, lean_object* v_a_140_){
_start:
{
lean_object* v_res_141_; 
v_res_141_ = lp_lean4_x2dtutorial_List_filterTR_loop___at___00Lean4Tutorial_Examples_PatternMatching_WellFounded_quicksort_spec__0(v_head_138_, v_a_139_, v_a_140_);
lean_dec(v_head_138_);
return v_res_141_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_List_filterTR_loop___at___00Lean4Tutorial_Examples_PatternMatching_WellFounded_quicksort_spec__1(lean_object* v_head_142_, lean_object* v_a_143_, lean_object* v_a_144_){
_start:
{
if (lean_obj_tag(v_a_143_) == 0)
{
lean_object* v___x_145_; 
v___x_145_ = l_List_reverse___redArg(v_a_144_);
return v___x_145_;
}
else
{
lean_object* v_head_146_; lean_object* v_tail_147_; lean_object* v___x_149_; uint8_t v_isShared_150_; uint8_t v_isSharedCheck_157_; 
v_head_146_ = lean_ctor_get(v_a_143_, 0);
v_tail_147_ = lean_ctor_get(v_a_143_, 1);
v_isSharedCheck_157_ = !lean_is_exclusive(v_a_143_);
if (v_isSharedCheck_157_ == 0)
{
v___x_149_ = v_a_143_;
v_isShared_150_ = v_isSharedCheck_157_;
goto v_resetjp_148_;
}
else
{
lean_inc(v_tail_147_);
lean_inc(v_head_146_);
lean_dec(v_a_143_);
v___x_149_ = lean_box(0);
v_isShared_150_ = v_isSharedCheck_157_;
goto v_resetjp_148_;
}
v_resetjp_148_:
{
uint8_t v___x_151_; 
v___x_151_ = lean_nat_dec_lt(v_head_142_, v_head_146_);
if (v___x_151_ == 0)
{
lean_del_object(v___x_149_);
lean_dec(v_head_146_);
v_a_143_ = v_tail_147_;
goto _start;
}
else
{
lean_object* v___x_154_; 
if (v_isShared_150_ == 0)
{
lean_ctor_set(v___x_149_, 1, v_a_144_);
v___x_154_ = v___x_149_;
goto v_reusejp_153_;
}
else
{
lean_object* v_reuseFailAlloc_156_; 
v_reuseFailAlloc_156_ = lean_alloc_ctor(1, 2, 0);
lean_ctor_set(v_reuseFailAlloc_156_, 0, v_head_146_);
lean_ctor_set(v_reuseFailAlloc_156_, 1, v_a_144_);
v___x_154_ = v_reuseFailAlloc_156_;
goto v_reusejp_153_;
}
v_reusejp_153_:
{
v_a_143_ = v_tail_147_;
v_a_144_ = v___x_154_;
goto _start;
}
}
}
}
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_List_filterTR_loop___at___00Lean4Tutorial_Examples_PatternMatching_WellFounded_quicksort_spec__1___boxed(lean_object* v_head_158_, lean_object* v_a_159_, lean_object* v_a_160_){
_start:
{
lean_object* v_res_161_; 
v_res_161_ = lp_lean4_x2dtutorial_List_filterTR_loop___at___00Lean4Tutorial_Examples_PatternMatching_WellFounded_quicksort_spec__1(v_head_158_, v_a_159_, v_a_160_);
lean_dec(v_head_158_);
return v_res_161_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_WellFounded_quicksort(lean_object* v_x_162_){
_start:
{
if (lean_obj_tag(v_x_162_) == 0)
{
return v_x_162_;
}
else
{
lean_object* v_head_163_; lean_object* v_tail_164_; lean_object* v___x_166_; uint8_t v_isShared_167_; uint8_t v_isSharedCheck_178_; 
v_head_163_ = lean_ctor_get(v_x_162_, 0);
v_tail_164_ = lean_ctor_get(v_x_162_, 1);
v_isSharedCheck_178_ = !lean_is_exclusive(v_x_162_);
if (v_isSharedCheck_178_ == 0)
{
v___x_166_ = v_x_162_;
v_isShared_167_ = v_isSharedCheck_178_;
goto v_resetjp_165_;
}
else
{
lean_inc(v_tail_164_);
lean_inc(v_head_163_);
lean_dec(v_x_162_);
v___x_166_ = lean_box(0);
v_isShared_167_ = v_isSharedCheck_178_;
goto v_resetjp_165_;
}
v_resetjp_165_:
{
lean_object* v___x_168_; lean_object* v_left_169_; lean_object* v_right_170_; lean_object* v___x_171_; lean_object* v___x_173_; 
v___x_168_ = lean_box(0);
lean_inc(v_tail_164_);
v_left_169_ = lp_lean4_x2dtutorial_List_filterTR_loop___at___00Lean4Tutorial_Examples_PatternMatching_WellFounded_quicksort_spec__0(v_head_163_, v_tail_164_, v___x_168_);
v_right_170_ = lp_lean4_x2dtutorial_List_filterTR_loop___at___00Lean4Tutorial_Examples_PatternMatching_WellFounded_quicksort_spec__1(v_head_163_, v_tail_164_, v___x_168_);
v___x_171_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_WellFounded_quicksort(v_left_169_);
if (v_isShared_167_ == 0)
{
lean_ctor_set(v___x_166_, 1, v___x_168_);
v___x_173_ = v___x_166_;
goto v_reusejp_172_;
}
else
{
lean_object* v_reuseFailAlloc_177_; 
v_reuseFailAlloc_177_ = lean_alloc_ctor(1, 2, 0);
lean_ctor_set(v_reuseFailAlloc_177_, 0, v_head_163_);
lean_ctor_set(v_reuseFailAlloc_177_, 1, v___x_168_);
v___x_173_ = v_reuseFailAlloc_177_;
goto v_reusejp_172_;
}
v_reusejp_172_:
{
lean_object* v___x_174_; lean_object* v___x_175_; lean_object* v___x_176_; 
v___x_174_ = l_List_appendTR___redArg(v___x_171_, v___x_173_);
v___x_175_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_WellFounded_quicksort(v_right_170_);
v___x_176_ = l_List_appendTR___redArg(v___x_174_, v___x_175_);
return v___x_176_;
}
}
}
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_WellFounded_qsort__example___closed__8(void){
_start:
{
lean_object* v___x_203_; lean_object* v___x_204_; 
v___x_203_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_WellFounded_qsort__example___closed__7));
v___x_204_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_WellFounded_quicksort(v___x_203_);
return v___x_204_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_WellFounded_qsort__example(void){
_start:
{
lean_object* v___x_205_; 
v___x_205_ = lean_obj_once(&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_WellFounded_qsort__example___closed__8, &lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_WellFounded_qsort__example___closed__8_once, _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_WellFounded_qsort__example___closed__8);
return v___x_205_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_WellFounded_fastFib_go(lean_object* v_a_206_, lean_object* v_a_207_, lean_object* v_a_208_){
_start:
{
lean_object* v_zero_209_; uint8_t v_isZero_210_; 
v_zero_209_ = lean_unsigned_to_nat(0u);
v_isZero_210_ = lean_nat_dec_eq(v_a_206_, v_zero_209_);
if (v_isZero_210_ == 1)
{
lean_dec(v_a_208_);
lean_dec(v_a_206_);
return v_a_207_;
}
else
{
lean_object* v_one_211_; lean_object* v_n_212_; lean_object* v___x_213_; 
v_one_211_ = lean_unsigned_to_nat(1u);
v_n_212_ = lean_nat_sub(v_a_206_, v_one_211_);
lean_dec(v_a_206_);
v___x_213_ = lean_nat_add(v_a_207_, v_a_208_);
lean_dec(v_a_207_);
v_a_206_ = v_n_212_;
v_a_207_ = v_a_208_;
v_a_208_ = v___x_213_;
goto _start;
}
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_WellFounded_fastFib(lean_object* v_n_215_){
_start:
{
lean_object* v___x_216_; lean_object* v___x_217_; lean_object* v___x_218_; 
v___x_216_ = lean_unsigned_to_nat(0u);
v___x_217_ = lean_unsigned_to_nat(1u);
v___x_218_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_WellFounded_fastFib_go(v_n_215_, v___x_216_, v___x_217_);
return v___x_218_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_WellFounded_fast__fib__10___closed__0(void){
_start:
{
lean_object* v___x_219_; lean_object* v___x_220_; 
v___x_219_ = lean_unsigned_to_nat(10u);
v___x_220_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_WellFounded_fastFib(v___x_219_);
return v___x_220_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_WellFounded_fast__fib__10(void){
_start:
{
lean_object* v___x_221_; 
v___x_221_ = lean_obj_once(&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_WellFounded_fast__fib__10___closed__0, &lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_WellFounded_fast__fib__10___closed__0_once, _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_WellFounded_fast__fib__10___closed__0);
return v___x_221_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_WellFounded_fast__fib__20___closed__0(void){
_start:
{
lean_object* v___x_222_; lean_object* v___x_223_; 
v___x_222_ = lean_unsigned_to_nat(20u);
v___x_223_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_WellFounded_fastFib(v___x_222_);
return v___x_223_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_WellFounded_fast__fib__20(void){
_start:
{
lean_object* v___x_224_; 
v___x_224_ = lean_obj_once(&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_WellFounded_fast__fib__20___closed__0, &lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_WellFounded_fast__fib__20___closed__0_once, _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_WellFounded_fast__fib__20___closed__0);
return v___x_224_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_WellFounded_fast__fib__30___closed__0(void){
_start:
{
lean_object* v___x_225_; lean_object* v___x_226_; 
v___x_225_ = lean_unsigned_to_nat(30u);
v___x_226_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_WellFounded_fastFib(v___x_225_);
return v___x_226_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_WellFounded_fast__fib__30(void){
_start:
{
lean_object* v___x_227_; 
v___x_227_ = lean_obj_once(&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_WellFounded_fast__fib__30___closed__0, &lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_WellFounded_fast__fib__30___closed__0_once, _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_WellFounded_fast__fib__30___closed__0);
return v___x_227_;
}
}
LEAN_EXPORT uint8_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_WellFounded_isOdd(lean_object* v_x_228_){
_start:
{
lean_object* v_zero_229_; uint8_t v_isZero_230_; 
v_zero_229_ = lean_unsigned_to_nat(0u);
v_isZero_230_ = lean_nat_dec_eq(v_x_228_, v_zero_229_);
if (v_isZero_230_ == 1)
{
uint8_t v___x_231_; 
v___x_231_ = 0;
return v___x_231_;
}
else
{
lean_object* v_one_232_; lean_object* v_n_233_; uint8_t v___x_234_; 
v_one_232_ = lean_unsigned_to_nat(1u);
v_n_233_ = lean_nat_sub(v_x_228_, v_one_232_);
v___x_234_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_WellFounded_isEven(v_n_233_);
lean_dec(v_n_233_);
return v___x_234_;
}
}
}
LEAN_EXPORT uint8_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_WellFounded_isEven(lean_object* v_x_235_){
_start:
{
lean_object* v_zero_236_; uint8_t v_isZero_237_; 
v_zero_236_ = lean_unsigned_to_nat(0u);
v_isZero_237_ = lean_nat_dec_eq(v_x_235_, v_zero_236_);
if (v_isZero_237_ == 1)
{
return v_isZero_237_;
}
else
{
lean_object* v_one_238_; lean_object* v_n_239_; uint8_t v___x_240_; 
v_one_238_ = lean_unsigned_to_nat(1u);
v_n_239_ = lean_nat_sub(v_x_235_, v_one_238_);
v___x_240_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_WellFounded_isOdd(v_n_239_);
lean_dec(v_n_239_);
return v___x_240_;
}
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_WellFounded_isEven___boxed(lean_object* v_x_241_){
_start:
{
uint8_t v_res_242_; lean_object* v_r_243_; 
v_res_242_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_WellFounded_isEven(v_x_241_);
lean_dec(v_x_241_);
v_r_243_ = lean_box(v_res_242_);
return v_r_243_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_WellFounded_isOdd___boxed(lean_object* v_x_244_){
_start:
{
uint8_t v_res_245_; lean_object* v_r_246_; 
v_res_245_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_WellFounded_isOdd(v_x_244_);
lean_dec(v_x_244_);
v_r_246_ = lean_box(v_res_245_);
return v_r_246_;
}
}
static uint8_t _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_WellFounded_even__0___closed__0(void){
_start:
{
lean_object* v___x_247_; uint8_t v___x_248_; 
v___x_247_ = lean_unsigned_to_nat(0u);
v___x_248_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_WellFounded_isEven(v___x_247_);
return v___x_248_;
}
}
static uint8_t _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_WellFounded_even__0(void){
_start:
{
uint8_t v___x_249_; 
v___x_249_ = lean_uint8_once(&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_WellFounded_even__0___closed__0, &lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_WellFounded_even__0___closed__0_once, _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_WellFounded_even__0___closed__0);
return v___x_249_;
}
}
static uint8_t _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_WellFounded_even__4___closed__0(void){
_start:
{
lean_object* v___x_250_; uint8_t v___x_251_; 
v___x_250_ = lean_unsigned_to_nat(4u);
v___x_251_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_WellFounded_isEven(v___x_250_);
return v___x_251_;
}
}
static uint8_t _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_WellFounded_even__4(void){
_start:
{
uint8_t v___x_252_; 
v___x_252_ = lean_uint8_once(&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_WellFounded_even__4___closed__0, &lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_WellFounded_even__4___closed__0_once, _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_WellFounded_even__4___closed__0);
return v___x_252_;
}
}
static uint8_t _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_WellFounded_odd__5___closed__0(void){
_start:
{
lean_object* v___x_253_; uint8_t v___x_254_; 
v___x_253_ = lean_unsigned_to_nat(5u);
v___x_254_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_WellFounded_isOdd(v___x_253_);
return v___x_254_;
}
}
static uint8_t _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_WellFounded_odd__5(void){
_start:
{
uint8_t v___x_255_; 
v___x_255_ = lean_uint8_once(&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_WellFounded_odd__5___closed__0, &lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_WellFounded_odd__5___closed__0_once, _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_WellFounded_odd__5___closed__0);
return v___x_255_;
}
}
static uint8_t _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_WellFounded_odd__4___closed__0(void){
_start:
{
lean_object* v___x_256_; uint8_t v___x_257_; 
v___x_256_ = lean_unsigned_to_nat(4u);
v___x_257_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_WellFounded_isOdd(v___x_256_);
return v___x_257_;
}
}
static uint8_t _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_WellFounded_odd__4(void){
_start:
{
uint8_t v___x_258_; 
v___x_258_ = lean_uint8_once(&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_WellFounded_odd__4___closed__0, &lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_WellFounded_odd__4___closed__0_once, _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_WellFounded_odd__4___closed__0);
return v___x_258_;
}
}
lean_object* initialize_Init(uint8_t builtin);
lean_object* initialize_Init(uint8_t builtin);
static bool _G_initialized = false;
LEAN_EXPORT lean_object* initialize_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_WellFounded(uint8_t builtin) {
lean_object * res;
if (_G_initialized) return lean_io_result_mk_ok(lean_box(0));
_G_initialized = true;
res = initialize_Init(builtin);
if (lean_io_result_is_error(res)) return res;
lean_dec_ref(res);
res = initialize_Init(builtin);
if (lean_io_result_is_error(res)) return res;
lean_dec_ref(res);
lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_WellFounded_ack__0__5 = _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_WellFounded_ack__0__5();
lean_mark_persistent(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_WellFounded_ack__0__5);
lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_WellFounded_ack__1__5 = _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_WellFounded_ack__1__5();
lean_mark_persistent(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_WellFounded_ack__1__5);
lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_WellFounded_ack__2__3 = _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_WellFounded_ack__2__3();
lean_mark_persistent(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_WellFounded_ack__2__3);
lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_WellFounded_ack__3__2 = _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_WellFounded_ack__3__2();
lean_mark_persistent(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_WellFounded_ack__3__2);
lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_WellFounded_gcd__48__18 = _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_WellFounded_gcd__48__18();
lean_mark_persistent(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_WellFounded_gcd__48__18);
lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_WellFounded_gcd__100__75 = _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_WellFounded_gcd__100__75();
lean_mark_persistent(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_WellFounded_gcd__100__75);
lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_WellFounded_qsort__example = _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_WellFounded_qsort__example();
lean_mark_persistent(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_WellFounded_qsort__example);
lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_WellFounded_fast__fib__10 = _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_WellFounded_fast__fib__10();
lean_mark_persistent(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_WellFounded_fast__fib__10);
lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_WellFounded_fast__fib__20 = _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_WellFounded_fast__fib__20();
lean_mark_persistent(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_WellFounded_fast__fib__20);
lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_WellFounded_fast__fib__30 = _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_WellFounded_fast__fib__30();
lean_mark_persistent(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_WellFounded_fast__fib__30);
lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_WellFounded_even__0 = _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_WellFounded_even__0();
lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_WellFounded_even__4 = _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_WellFounded_even__4();
lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_WellFounded_odd__5 = _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_WellFounded_odd__5();
lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_WellFounded_odd__4 = _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_WellFounded_odd__4();
return lean_io_result_mk_ok(lean_box(0));
}
#ifdef __cplusplus
}
#endif
