// Lean compiler output
// Module: Lean4Tutorial.Examples.Tactics.Induction
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
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Tactics_Induction_length___redArg(lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Tactics_Induction_length___redArg___boxed(lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Tactics_Induction_length(lean_object*, lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Tactics_Induction_length___boxed(lean_object*, lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial___private_Lean4Tutorial_Examples_Tactics_Induction_0__Lean4Tutorial_Examples_Tactics_Induction_length_match__1_splitter___redArg(lean_object*, lean_object*, lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial___private_Lean4Tutorial_Examples_Tactics_Induction_0__Lean4Tutorial_Examples_Tactics_Induction_length_match__1_splitter(lean_object*, lean_object*, lean_object*, lean_object*, lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Tactics_Induction_length___redArg(lean_object* v_x_1_){
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
lean_object* v_tail_3_; lean_object* v___x_4_; lean_object* v___x_5_; lean_object* v___x_6_; 
v_tail_3_ = lean_ctor_get(v_x_1_, 1);
v___x_4_ = lean_unsigned_to_nat(1u);
v___x_5_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Tactics_Induction_length___redArg(v_tail_3_);
v___x_6_ = lean_nat_add(v___x_4_, v___x_5_);
lean_dec(v___x_5_);
return v___x_6_;
}
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Tactics_Induction_length___redArg___boxed(lean_object* v_x_7_){
_start:
{
lean_object* v_res_8_; 
v_res_8_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Tactics_Induction_length___redArg(v_x_7_);
lean_dec(v_x_7_);
return v_res_8_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Tactics_Induction_length(lean_object* v_00_u03b1_9_, lean_object* v_x_10_){
_start:
{
lean_object* v___x_11_; 
v___x_11_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Tactics_Induction_length___redArg(v_x_10_);
return v___x_11_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Tactics_Induction_length___boxed(lean_object* v_00_u03b1_12_, lean_object* v_x_13_){
_start:
{
lean_object* v_res_14_; 
v_res_14_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_Tactics_Induction_length(v_00_u03b1_12_, v_x_13_);
lean_dec(v_x_13_);
return v_res_14_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial___private_Lean4Tutorial_Examples_Tactics_Induction_0__Lean4Tutorial_Examples_Tactics_Induction_length_match__1_splitter___redArg(lean_object* v_x_15_, lean_object* v_h__1_16_, lean_object* v_h__2_17_){
_start:
{
if (lean_obj_tag(v_x_15_) == 0)
{
lean_object* v___x_18_; lean_object* v___x_19_; 
lean_dec(v_h__2_17_);
v___x_18_ = lean_box(0);
v___x_19_ = lean_apply_1(v_h__1_16_, v___x_18_);
return v___x_19_;
}
else
{
lean_object* v_head_20_; lean_object* v_tail_21_; lean_object* v___x_22_; 
lean_dec(v_h__1_16_);
v_head_20_ = lean_ctor_get(v_x_15_, 0);
lean_inc(v_head_20_);
v_tail_21_ = lean_ctor_get(v_x_15_, 1);
lean_inc(v_tail_21_);
lean_dec_ref_known(v_x_15_, 2);
v___x_22_ = lean_apply_2(v_h__2_17_, v_head_20_, v_tail_21_);
return v___x_22_;
}
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial___private_Lean4Tutorial_Examples_Tactics_Induction_0__Lean4Tutorial_Examples_Tactics_Induction_length_match__1_splitter(lean_object* v_00_u03b1_23_, lean_object* v_motive_24_, lean_object* v_x_25_, lean_object* v_h__1_26_, lean_object* v_h__2_27_){
_start:
{
if (lean_obj_tag(v_x_25_) == 0)
{
lean_object* v___x_28_; lean_object* v___x_29_; 
lean_dec(v_h__2_27_);
v___x_28_ = lean_box(0);
v___x_29_ = lean_apply_1(v_h__1_26_, v___x_28_);
return v___x_29_;
}
else
{
lean_object* v_head_30_; lean_object* v_tail_31_; lean_object* v___x_32_; 
lean_dec(v_h__1_26_);
v_head_30_ = lean_ctor_get(v_x_25_, 0);
lean_inc(v_head_30_);
v_tail_31_ = lean_ctor_get(v_x_25_, 1);
lean_inc(v_tail_31_);
lean_dec_ref_known(v_x_25_, 2);
v___x_32_ = lean_apply_2(v_h__2_27_, v_head_30_, v_tail_31_);
return v___x_32_;
}
}
}
lean_object* initialize_Init(uint8_t builtin);
lean_object* initialize_Init(uint8_t builtin);
static bool _G_initialized = false;
LEAN_EXPORT lean_object* initialize_lean4_x2dtutorial_Lean4Tutorial_Examples_Tactics_Induction(uint8_t builtin) {
lean_object * res;
if (_G_initialized) return lean_io_result_mk_ok(lean_box(0));
_G_initialized = true;
res = initialize_Init(builtin);
if (lean_io_result_is_error(res)) return res;
lean_dec_ref(res);
res = initialize_Init(builtin);
if (lean_io_result_is_error(res)) return res;
lean_dec_ref(res);
return lean_io_result_mk_ok(lean_box(0));
}
#ifdef __cplusplus
}
#endif
