// Lean compiler output
// Module: Lean4Tutorial.Examples.InductiveTypes.DependentTypes
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
lean_object* lean_nat_sub(lean_object*, lean_object*);
lean_object* lean_nat_mul(lean_object*, lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_DependentTypes_fin0__val;
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_DependentTypes_fin1__val;
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_DependentTypes_Vec_ctorIdx___redArg(lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_DependentTypes_Vec_ctorIdx___redArg___boxed(lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_DependentTypes_Vec_ctorIdx(lean_object*, lean_object*, lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_DependentTypes_Vec_ctorIdx___boxed(lean_object*, lean_object*, lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_DependentTypes_Vec_ctorElim___redArg(lean_object*, lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_DependentTypes_Vec_ctorElim(lean_object*, lean_object*, lean_object*, lean_object*, lean_object*, lean_object*, lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_DependentTypes_Vec_ctorElim___boxed(lean_object*, lean_object*, lean_object*, lean_object*, lean_object*, lean_object*, lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_DependentTypes_Vec_nil_elim___redArg(lean_object*, lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_DependentTypes_Vec_nil_elim(lean_object*, lean_object*, lean_object*, lean_object*, lean_object*, lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_DependentTypes_Vec_nil_elim___boxed(lean_object*, lean_object*, lean_object*, lean_object*, lean_object*, lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_DependentTypes_Vec_cons_elim___redArg(lean_object*, lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_DependentTypes_Vec_cons_elim(lean_object*, lean_object*, lean_object*, lean_object*, lean_object*, lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_DependentTypes_Vec_cons_elim___boxed(lean_object*, lean_object*, lean_object*, lean_object*, lean_object*, lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_DependentTypes_vnil;
static const lean_ctor_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_DependentTypes_v1___closed__0_value = {.m_header = {.m_rc = 0, .m_cs_sz = sizeof(lean_ctor_object) + sizeof(void*)*3 + 0, .m_other = 3, .m_tag = 1}, .m_objs = {((lean_object*)(((size_t)(0) << 1) | 1)),((lean_object*)(((size_t)(5) << 1) | 1)),((lean_object*)(((size_t)(0) << 1) | 1))}};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_DependentTypes_v1___closed__0 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_DependentTypes_v1___closed__0_value;
LEAN_EXPORT const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_DependentTypes_v1 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_DependentTypes_v1___closed__0_value;
static const lean_ctor_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_DependentTypes_v2___closed__0_value = {.m_header = {.m_rc = 0, .m_cs_sz = sizeof(lean_ctor_object) + sizeof(void*)*3 + 0, .m_other = 3, .m_tag = 1}, .m_objs = {((lean_object*)(((size_t)(0) << 1) | 1)),((lean_object*)(((size_t)(7) << 1) | 1)),((lean_object*)(((size_t)(0) << 1) | 1))}};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_DependentTypes_v2___closed__0 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_DependentTypes_v2___closed__0_value;
static const lean_ctor_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_DependentTypes_v2___closed__1_value = {.m_header = {.m_rc = 0, .m_cs_sz = sizeof(lean_ctor_object) + sizeof(void*)*3 + 0, .m_other = 3, .m_tag = 1}, .m_objs = {((lean_object*)(((size_t)(1) << 1) | 1)),((lean_object*)(((size_t)(3) << 1) | 1)),((lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_DependentTypes_v2___closed__0_value)}};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_DependentTypes_v2___closed__1 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_DependentTypes_v2___closed__1_value;
LEAN_EXPORT const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_DependentTypes_v2 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_DependentTypes_v2___closed__1_value;
static const lean_ctor_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_DependentTypes_v3___closed__0_value = {.m_header = {.m_rc = 0, .m_cs_sz = sizeof(lean_ctor_object) + sizeof(void*)*3 + 0, .m_other = 3, .m_tag = 1}, .m_objs = {((lean_object*)(((size_t)(0) << 1) | 1)),((lean_object*)(((size_t)(3) << 1) | 1)),((lean_object*)(((size_t)(0) << 1) | 1))}};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_DependentTypes_v3___closed__0 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_DependentTypes_v3___closed__0_value;
static const lean_ctor_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_DependentTypes_v3___closed__1_value = {.m_header = {.m_rc = 0, .m_cs_sz = sizeof(lean_ctor_object) + sizeof(void*)*3 + 0, .m_other = 3, .m_tag = 1}, .m_objs = {((lean_object*)(((size_t)(1) << 1) | 1)),((lean_object*)(((size_t)(2) << 1) | 1)),((lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_DependentTypes_v3___closed__0_value)}};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_DependentTypes_v3___closed__1 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_DependentTypes_v3___closed__1_value;
static const lean_ctor_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_DependentTypes_v3___closed__2_value = {.m_header = {.m_rc = 0, .m_cs_sz = sizeof(lean_ctor_object) + sizeof(void*)*3 + 0, .m_other = 3, .m_tag = 1}, .m_objs = {((lean_object*)(((size_t)(2) << 1) | 1)),((lean_object*)(((size_t)(1) << 1) | 1)),((lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_DependentTypes_v3___closed__1_value)}};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_DependentTypes_v3___closed__2 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_DependentTypes_v3___closed__2_value;
LEAN_EXPORT const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_DependentTypes_v3 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_DependentTypes_v3___closed__2_value;
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_DependentTypes_vlength___redArg(lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_DependentTypes_vlength___redArg___boxed(lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_DependentTypes_vlength(lean_object*, lean_object*, lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_DependentTypes_vlength___boxed(lean_object*, lean_object*, lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_DependentTypes_len3;
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_DependentTypes_vhead___redArg(lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_DependentTypes_vhead___redArg___boxed(lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_DependentTypes_vhead(lean_object*, lean_object*, lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_DependentTypes_vhead___boxed(lean_object*, lean_object*, lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_DependentTypes_head2;
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_DependentTypes_vtail___redArg(lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_DependentTypes_vtail___redArg___boxed(lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_DependentTypes_vtail(lean_object*, lean_object*, lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_DependentTypes_vtail___boxed(lean_object*, lean_object*, lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_DependentTypes_tail2;
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_DependentTypes_vmap___redArg(lean_object*, lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_DependentTypes_vmap(lean_object*, lean_object*, lean_object*, lean_object*, lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_DependentTypes_vmap___boxed(lean_object*, lean_object*, lean_object*, lean_object*, lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_DependentTypes_vdoubled___lam__0(lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_DependentTypes_vdoubled___lam__0___boxed(lean_object*);
static const lean_closure_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_DependentTypes_vdoubled___closed__0_value = {.m_header = {.m_rc = 0, .m_cs_sz = sizeof(lean_closure_object) + sizeof(void*)*0, .m_other = 0, .m_tag = 245}, .m_fun = (void*)lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_DependentTypes_vdoubled___lam__0___boxed, .m_arity = 1, .m_num_fixed = 0, .m_objs = {} };
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_DependentTypes_vdoubled___closed__0 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_DependentTypes_vdoubled___closed__0_value;
static lean_once_cell_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_DependentTypes_vdoubled___closed__1_once = LEAN_ONCE_CELL_INITIALIZER;
static lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_DependentTypes_vdoubled___closed__1;
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_DependentTypes_vdoubled;
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_DependentTypes_vget_x3f___redArg(lean_object*, lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_DependentTypes_vget_x3f___redArg___boxed(lean_object*, lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_DependentTypes_vget_x3f(lean_object*, lean_object*, lean_object*, lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_DependentTypes_vget_x3f___boxed(lean_object*, lean_object*, lean_object*, lean_object*);
static lean_once_cell_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_DependentTypes_get__v3__0___closed__0_once = LEAN_ONCE_CELL_INITIALIZER;
static lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_DependentTypes_get__v3__0___closed__0;
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_DependentTypes_get__v3__0;
static lean_once_cell_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_DependentTypes_get__v3__1___closed__0_once = LEAN_ONCE_CELL_INITIALIZER;
static lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_DependentTypes_get__v3__1___closed__0;
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_DependentTypes_get__v3__1;
static lean_once_cell_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_DependentTypes_get__v3__2___closed__0_once = LEAN_ONCE_CELL_INITIALIZER;
static lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_DependentTypes_get__v3__2___closed__0;
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_DependentTypes_get__v3__2;
static lean_once_cell_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_DependentTypes_get__v3__9___closed__0_once = LEAN_ONCE_CELL_INITIALIZER;
static lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_DependentTypes_get__v3__9___closed__0;
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_DependentTypes_get__v3__9;
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_DependentTypes_f0;
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_DependentTypes_f1;
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_DependentTypes_f2;
static const lean_ctor_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_DependentTypes_dep__pair___closed__0_value = {.m_header = {.m_rc = 0, .m_cs_sz = sizeof(lean_ctor_object) + sizeof(void*)*2 + 0, .m_other = 2, .m_tag = 0}, .m_objs = {((lean_object*)(((size_t)(3) << 1) | 1)),((lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_DependentTypes_v3___closed__2_value)}};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_DependentTypes_dep__pair___closed__0 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_DependentTypes_dep__pair___closed__0_value;
LEAN_EXPORT const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_DependentTypes_dep__pair = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_DependentTypes_dep__pair___closed__0_value;
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_DependentTypes_one__pos;
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_DependentTypes_five__pos;
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_DependentTypes_pos__val;
static const lean_string_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_DependentTypes_hello__nonempty___closed__0_value = {.m_header = {.m_rc = 0, .m_cs_sz = 0, .m_other = 0, .m_tag = 249}, .m_size = 6, .m_capacity = 6, .m_length = 5, .m_data = "hello"};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_DependentTypes_hello__nonempty___closed__0 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_DependentTypes_hello__nonempty___closed__0_value;
LEAN_EXPORT const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_DependentTypes_hello__nonempty = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_DependentTypes_hello__nonempty___closed__0_value;
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_DependentTypes_fin0__val(void){
_start:
{
lean_object* v___x_1_; 
v___x_1_ = lean_unsigned_to_nat(3u);
return v___x_1_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_DependentTypes_fin1__val(void){
_start:
{
lean_object* v___x_2_; 
v___x_2_ = lean_unsigned_to_nat(7u);
return v___x_2_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_DependentTypes_Vec_ctorIdx___redArg(lean_object* v_x_3_){
_start:
{
if (lean_obj_tag(v_x_3_) == 0)
{
lean_object* v___x_4_; 
v___x_4_ = lean_unsigned_to_nat(0u);
return v___x_4_;
}
else
{
lean_object* v___x_5_; 
v___x_5_ = lean_unsigned_to_nat(1u);
return v___x_5_;
}
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_DependentTypes_Vec_ctorIdx___redArg___boxed(lean_object* v_x_6_){
_start:
{
lean_object* v_res_7_; 
v_res_7_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_DependentTypes_Vec_ctorIdx___redArg(v_x_6_);
lean_dec(v_x_6_);
return v_res_7_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_DependentTypes_Vec_ctorIdx(lean_object* v_00_u03b1_8_, lean_object* v_a_9_, lean_object* v_x_10_){
_start:
{
lean_object* v___x_11_; 
v___x_11_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_DependentTypes_Vec_ctorIdx___redArg(v_x_10_);
return v___x_11_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_DependentTypes_Vec_ctorIdx___boxed(lean_object* v_00_u03b1_12_, lean_object* v_a_13_, lean_object* v_x_14_){
_start:
{
lean_object* v_res_15_; 
v_res_15_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_DependentTypes_Vec_ctorIdx(v_00_u03b1_12_, v_a_13_, v_x_14_);
lean_dec(v_x_14_);
lean_dec(v_a_13_);
return v_res_15_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_DependentTypes_Vec_ctorElim___redArg(lean_object* v_t_16_, lean_object* v_k_17_){
_start:
{
if (lean_obj_tag(v_t_16_) == 0)
{
return v_k_17_;
}
else
{
lean_object* v_n_18_; lean_object* v_x_19_; lean_object* v_v_20_; lean_object* v___x_21_; 
v_n_18_ = lean_ctor_get(v_t_16_, 0);
lean_inc(v_n_18_);
v_x_19_ = lean_ctor_get(v_t_16_, 1);
lean_inc(v_x_19_);
v_v_20_ = lean_ctor_get(v_t_16_, 2);
lean_inc(v_v_20_);
lean_dec_ref_known(v_t_16_, 3);
v___x_21_ = lean_apply_3(v_k_17_, v_n_18_, v_x_19_, v_v_20_);
return v___x_21_;
}
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_DependentTypes_Vec_ctorElim(lean_object* v_00_u03b1_22_, lean_object* v_motive_23_, lean_object* v_ctorIdx_24_, lean_object* v_a_25_, lean_object* v_t_26_, lean_object* v_h_27_, lean_object* v_k_28_){
_start:
{
lean_object* v___x_29_; 
v___x_29_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_DependentTypes_Vec_ctorElim___redArg(v_t_26_, v_k_28_);
return v___x_29_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_DependentTypes_Vec_ctorElim___boxed(lean_object* v_00_u03b1_30_, lean_object* v_motive_31_, lean_object* v_ctorIdx_32_, lean_object* v_a_33_, lean_object* v_t_34_, lean_object* v_h_35_, lean_object* v_k_36_){
_start:
{
lean_object* v_res_37_; 
v_res_37_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_DependentTypes_Vec_ctorElim(v_00_u03b1_30_, v_motive_31_, v_ctorIdx_32_, v_a_33_, v_t_34_, v_h_35_, v_k_36_);
lean_dec(v_a_33_);
lean_dec(v_ctorIdx_32_);
return v_res_37_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_DependentTypes_Vec_nil_elim___redArg(lean_object* v_t_38_, lean_object* v_nil_39_){
_start:
{
lean_object* v___x_40_; 
v___x_40_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_DependentTypes_Vec_ctorElim___redArg(v_t_38_, v_nil_39_);
return v___x_40_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_DependentTypes_Vec_nil_elim(lean_object* v_00_u03b1_41_, lean_object* v_motive_42_, lean_object* v_a_43_, lean_object* v_t_44_, lean_object* v_h_45_, lean_object* v_nil_46_){
_start:
{
lean_object* v___x_47_; 
v___x_47_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_DependentTypes_Vec_ctorElim___redArg(v_t_44_, v_nil_46_);
return v___x_47_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_DependentTypes_Vec_nil_elim___boxed(lean_object* v_00_u03b1_48_, lean_object* v_motive_49_, lean_object* v_a_50_, lean_object* v_t_51_, lean_object* v_h_52_, lean_object* v_nil_53_){
_start:
{
lean_object* v_res_54_; 
v_res_54_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_DependentTypes_Vec_nil_elim(v_00_u03b1_48_, v_motive_49_, v_a_50_, v_t_51_, v_h_52_, v_nil_53_);
lean_dec(v_a_50_);
return v_res_54_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_DependentTypes_Vec_cons_elim___redArg(lean_object* v_t_55_, lean_object* v_cons_56_){
_start:
{
lean_object* v___x_57_; 
v___x_57_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_DependentTypes_Vec_ctorElim___redArg(v_t_55_, v_cons_56_);
return v___x_57_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_DependentTypes_Vec_cons_elim(lean_object* v_00_u03b1_58_, lean_object* v_motive_59_, lean_object* v_a_60_, lean_object* v_t_61_, lean_object* v_h_62_, lean_object* v_cons_63_){
_start:
{
lean_object* v___x_64_; 
v___x_64_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_DependentTypes_Vec_ctorElim___redArg(v_t_61_, v_cons_63_);
return v___x_64_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_DependentTypes_Vec_cons_elim___boxed(lean_object* v_00_u03b1_65_, lean_object* v_motive_66_, lean_object* v_a_67_, lean_object* v_t_68_, lean_object* v_h_69_, lean_object* v_cons_70_){
_start:
{
lean_object* v_res_71_; 
v_res_71_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_DependentTypes_Vec_cons_elim(v_00_u03b1_65_, v_motive_66_, v_a_67_, v_t_68_, v_h_69_, v_cons_70_);
lean_dec(v_a_67_);
return v_res_71_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_DependentTypes_vnil(void){
_start:
{
lean_object* v___x_72_; 
v___x_72_ = lean_box(0);
return v___x_72_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_DependentTypes_vlength___redArg(lean_object* v_n_100_){
_start:
{
lean_inc(v_n_100_);
return v_n_100_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_DependentTypes_vlength___redArg___boxed(lean_object* v_n_101_){
_start:
{
lean_object* v_res_102_; 
v_res_102_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_DependentTypes_vlength___redArg(v_n_101_);
lean_dec(v_n_101_);
return v_res_102_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_DependentTypes_vlength(lean_object* v_00_u03b1_103_, lean_object* v_n_104_, lean_object* v___v_105_){
_start:
{
lean_inc(v_n_104_);
return v_n_104_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_DependentTypes_vlength___boxed(lean_object* v_00_u03b1_106_, lean_object* v_n_107_, lean_object* v___v_108_){
_start:
{
lean_object* v_res_109_; 
v_res_109_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_DependentTypes_vlength(v_00_u03b1_106_, v_n_107_, v___v_108_);
lean_dec(v___v_108_);
lean_dec(v_n_107_);
return v_res_109_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_DependentTypes_len3(void){
_start:
{
lean_object* v___x_110_; 
v___x_110_ = lean_unsigned_to_nat(3u);
return v___x_110_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_DependentTypes_vhead___redArg(lean_object* v_v_111_){
_start:
{
lean_object* v_x_112_; 
v_x_112_ = lean_ctor_get(v_v_111_, 1);
lean_inc(v_x_112_);
return v_x_112_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_DependentTypes_vhead___redArg___boxed(lean_object* v_v_113_){
_start:
{
lean_object* v_res_114_; 
v_res_114_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_DependentTypes_vhead___redArg(v_v_113_);
lean_dec(v_v_113_);
return v_res_114_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_DependentTypes_vhead(lean_object* v_00_u03b1_115_, lean_object* v_n_116_, lean_object* v_v_117_){
_start:
{
lean_object* v_x_118_; 
v_x_118_ = lean_ctor_get(v_v_117_, 1);
lean_inc(v_x_118_);
return v_x_118_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_DependentTypes_vhead___boxed(lean_object* v_00_u03b1_119_, lean_object* v_n_120_, lean_object* v_v_121_){
_start:
{
lean_object* v_res_122_; 
v_res_122_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_DependentTypes_vhead(v_00_u03b1_119_, v_n_120_, v_v_121_);
lean_dec(v_v_121_);
lean_dec(v_n_120_);
return v_res_122_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_DependentTypes_head2(void){
_start:
{
lean_object* v___x_123_; lean_object* v_x_124_; 
v___x_123_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_DependentTypes_v2));
v_x_124_ = lean_ctor_get(v___x_123_, 1);
lean_inc(v_x_124_);
return v_x_124_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_DependentTypes_vtail___redArg(lean_object* v_v_125_){
_start:
{
lean_object* v_v_126_; 
v_v_126_ = lean_ctor_get(v_v_125_, 2);
lean_inc(v_v_126_);
return v_v_126_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_DependentTypes_vtail___redArg___boxed(lean_object* v_v_127_){
_start:
{
lean_object* v_res_128_; 
v_res_128_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_DependentTypes_vtail___redArg(v_v_127_);
lean_dec(v_v_127_);
return v_res_128_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_DependentTypes_vtail(lean_object* v_00_u03b1_129_, lean_object* v_n_130_, lean_object* v_v_131_){
_start:
{
lean_object* v_v_132_; 
v_v_132_ = lean_ctor_get(v_v_131_, 2);
lean_inc(v_v_132_);
return v_v_132_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_DependentTypes_vtail___boxed(lean_object* v_00_u03b1_133_, lean_object* v_n_134_, lean_object* v_v_135_){
_start:
{
lean_object* v_res_136_; 
v_res_136_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_DependentTypes_vtail(v_00_u03b1_133_, v_n_134_, v_v_135_);
lean_dec(v_v_135_);
lean_dec(v_n_134_);
return v_res_136_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_DependentTypes_tail2(void){
_start:
{
lean_object* v___x_137_; lean_object* v_v_138_; 
v___x_137_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_DependentTypes_v2));
v_v_138_ = lean_ctor_get(v___x_137_, 2);
lean_inc(v_v_138_);
return v_v_138_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_DependentTypes_vmap___redArg(lean_object* v_f_139_, lean_object* v_x_140_){
_start:
{
if (lean_obj_tag(v_x_140_) == 0)
{
lean_object* v___x_141_; 
lean_dec(v_f_139_);
v___x_141_ = lean_box(0);
return v___x_141_;
}
else
{
lean_object* v_n_142_; lean_object* v_x_143_; lean_object* v_v_144_; lean_object* v___x_146_; uint8_t v_isShared_147_; uint8_t v_isSharedCheck_153_; 
v_n_142_ = lean_ctor_get(v_x_140_, 0);
v_x_143_ = lean_ctor_get(v_x_140_, 1);
v_v_144_ = lean_ctor_get(v_x_140_, 2);
v_isSharedCheck_153_ = !lean_is_exclusive(v_x_140_);
if (v_isSharedCheck_153_ == 0)
{
v___x_146_ = v_x_140_;
v_isShared_147_ = v_isSharedCheck_153_;
goto v_resetjp_145_;
}
else
{
lean_inc(v_v_144_);
lean_inc(v_x_143_);
lean_inc(v_n_142_);
lean_dec(v_x_140_);
v___x_146_ = lean_box(0);
v_isShared_147_ = v_isSharedCheck_153_;
goto v_resetjp_145_;
}
v_resetjp_145_:
{
lean_object* v___x_148_; lean_object* v___x_149_; lean_object* v___x_151_; 
lean_inc(v_f_139_);
v___x_148_ = lean_apply_1(v_f_139_, v_x_143_);
v___x_149_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_DependentTypes_vmap___redArg(v_f_139_, v_v_144_);
if (v_isShared_147_ == 0)
{
lean_ctor_set(v___x_146_, 2, v___x_149_);
lean_ctor_set(v___x_146_, 1, v___x_148_);
v___x_151_ = v___x_146_;
goto v_reusejp_150_;
}
else
{
lean_object* v_reuseFailAlloc_152_; 
v_reuseFailAlloc_152_ = lean_alloc_ctor(1, 3, 0);
lean_ctor_set(v_reuseFailAlloc_152_, 0, v_n_142_);
lean_ctor_set(v_reuseFailAlloc_152_, 1, v___x_148_);
lean_ctor_set(v_reuseFailAlloc_152_, 2, v___x_149_);
v___x_151_ = v_reuseFailAlloc_152_;
goto v_reusejp_150_;
}
v_reusejp_150_:
{
return v___x_151_;
}
}
}
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_DependentTypes_vmap(lean_object* v_00_u03b1_154_, lean_object* v_00_u03b2_155_, lean_object* v_n_156_, lean_object* v_f_157_, lean_object* v_x_158_){
_start:
{
lean_object* v___x_159_; 
v___x_159_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_DependentTypes_vmap___redArg(v_f_157_, v_x_158_);
return v___x_159_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_DependentTypes_vmap___boxed(lean_object* v_00_u03b1_160_, lean_object* v_00_u03b2_161_, lean_object* v_n_162_, lean_object* v_f_163_, lean_object* v_x_164_){
_start:
{
lean_object* v_res_165_; 
v_res_165_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_DependentTypes_vmap(v_00_u03b1_160_, v_00_u03b2_161_, v_n_162_, v_f_163_, v_x_164_);
lean_dec(v_n_162_);
return v_res_165_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_DependentTypes_vdoubled___lam__0(lean_object* v_x_166_){
_start:
{
lean_object* v___x_167_; lean_object* v___x_168_; 
v___x_167_ = lean_unsigned_to_nat(2u);
v___x_168_ = lean_nat_mul(v_x_166_, v___x_167_);
return v___x_168_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_DependentTypes_vdoubled___lam__0___boxed(lean_object* v_x_169_){
_start:
{
lean_object* v_res_170_; 
v_res_170_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_DependentTypes_vdoubled___lam__0(v_x_169_);
lean_dec(v_x_169_);
return v_res_170_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_DependentTypes_vdoubled___closed__1(void){
_start:
{
lean_object* v___x_172_; lean_object* v___f_173_; lean_object* v___x_174_; 
v___x_172_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_DependentTypes_v3));
v___f_173_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_DependentTypes_vdoubled___closed__0));
v___x_174_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_DependentTypes_vmap___redArg(v___f_173_, v___x_172_);
return v___x_174_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_DependentTypes_vdoubled(void){
_start:
{
lean_object* v___x_175_; 
v___x_175_ = lean_obj_once(&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_DependentTypes_vdoubled___closed__1, &lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_DependentTypes_vdoubled___closed__1_once, _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_DependentTypes_vdoubled___closed__1);
return v___x_175_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_DependentTypes_vget_x3f___redArg(lean_object* v_v_176_, lean_object* v_k_177_){
_start:
{
if (lean_obj_tag(v_v_176_) == 0)
{
lean_object* v___x_178_; 
lean_dec(v_k_177_);
v___x_178_ = lean_box(0);
return v___x_178_;
}
else
{
lean_object* v_x_179_; lean_object* v_v_180_; lean_object* v___x_181_; uint8_t v___x_182_; 
v_x_179_ = lean_ctor_get(v_v_176_, 1);
v_v_180_ = lean_ctor_get(v_v_176_, 2);
v___x_181_ = lean_unsigned_to_nat(0u);
v___x_182_ = lean_nat_dec_eq(v_k_177_, v___x_181_);
if (v___x_182_ == 0)
{
lean_object* v___x_183_; lean_object* v___x_184_; 
v___x_183_ = lean_unsigned_to_nat(1u);
v___x_184_ = lean_nat_sub(v_k_177_, v___x_183_);
lean_dec(v_k_177_);
v_v_176_ = v_v_180_;
v_k_177_ = v___x_184_;
goto _start;
}
else
{
lean_object* v___x_186_; 
lean_dec(v_k_177_);
lean_inc(v_x_179_);
v___x_186_ = lean_alloc_ctor(1, 1, 0);
lean_ctor_set(v___x_186_, 0, v_x_179_);
return v___x_186_;
}
}
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_DependentTypes_vget_x3f___redArg___boxed(lean_object* v_v_187_, lean_object* v_k_188_){
_start:
{
lean_object* v_res_189_; 
v_res_189_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_DependentTypes_vget_x3f___redArg(v_v_187_, v_k_188_);
lean_dec(v_v_187_);
return v_res_189_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_DependentTypes_vget_x3f(lean_object* v_00_u03b1_190_, lean_object* v_n_191_, lean_object* v_v_192_, lean_object* v_k_193_){
_start:
{
lean_object* v___x_194_; 
v___x_194_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_DependentTypes_vget_x3f___redArg(v_v_192_, v_k_193_);
return v___x_194_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_DependentTypes_vget_x3f___boxed(lean_object* v_00_u03b1_195_, lean_object* v_n_196_, lean_object* v_v_197_, lean_object* v_k_198_){
_start:
{
lean_object* v_res_199_; 
v_res_199_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_DependentTypes_vget_x3f(v_00_u03b1_195_, v_n_196_, v_v_197_, v_k_198_);
lean_dec(v_v_197_);
lean_dec(v_n_196_);
return v_res_199_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_DependentTypes_get__v3__0___closed__0(void){
_start:
{
lean_object* v___x_200_; lean_object* v___x_201_; lean_object* v___x_202_; 
v___x_200_ = lean_unsigned_to_nat(0u);
v___x_201_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_DependentTypes_v3));
v___x_202_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_DependentTypes_vget_x3f___redArg(v___x_201_, v___x_200_);
return v___x_202_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_DependentTypes_get__v3__0(void){
_start:
{
lean_object* v___x_203_; 
v___x_203_ = lean_obj_once(&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_DependentTypes_get__v3__0___closed__0, &lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_DependentTypes_get__v3__0___closed__0_once, _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_DependentTypes_get__v3__0___closed__0);
return v___x_203_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_DependentTypes_get__v3__1___closed__0(void){
_start:
{
lean_object* v___x_204_; lean_object* v___x_205_; lean_object* v___x_206_; 
v___x_204_ = lean_unsigned_to_nat(1u);
v___x_205_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_DependentTypes_v3));
v___x_206_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_DependentTypes_vget_x3f___redArg(v___x_205_, v___x_204_);
return v___x_206_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_DependentTypes_get__v3__1(void){
_start:
{
lean_object* v___x_207_; 
v___x_207_ = lean_obj_once(&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_DependentTypes_get__v3__1___closed__0, &lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_DependentTypes_get__v3__1___closed__0_once, _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_DependentTypes_get__v3__1___closed__0);
return v___x_207_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_DependentTypes_get__v3__2___closed__0(void){
_start:
{
lean_object* v___x_208_; lean_object* v___x_209_; lean_object* v___x_210_; 
v___x_208_ = lean_unsigned_to_nat(2u);
v___x_209_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_DependentTypes_v3));
v___x_210_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_DependentTypes_vget_x3f___redArg(v___x_209_, v___x_208_);
return v___x_210_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_DependentTypes_get__v3__2(void){
_start:
{
lean_object* v___x_211_; 
v___x_211_ = lean_obj_once(&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_DependentTypes_get__v3__2___closed__0, &lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_DependentTypes_get__v3__2___closed__0_once, _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_DependentTypes_get__v3__2___closed__0);
return v___x_211_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_DependentTypes_get__v3__9___closed__0(void){
_start:
{
lean_object* v___x_212_; lean_object* v___x_213_; lean_object* v___x_214_; 
v___x_212_ = lean_unsigned_to_nat(9u);
v___x_213_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_DependentTypes_v3));
v___x_214_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_DependentTypes_vget_x3f___redArg(v___x_213_, v___x_212_);
return v___x_214_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_DependentTypes_get__v3__9(void){
_start:
{
lean_object* v___x_215_; 
v___x_215_ = lean_obj_once(&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_DependentTypes_get__v3__9___closed__0, &lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_DependentTypes_get__v3__9___closed__0_once, _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_DependentTypes_get__v3__9___closed__0);
return v___x_215_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_DependentTypes_f0(void){
_start:
{
lean_object* v___x_216_; 
v___x_216_ = lean_unsigned_to_nat(0u);
return v___x_216_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_DependentTypes_f1(void){
_start:
{
lean_object* v___x_217_; 
v___x_217_ = lean_unsigned_to_nat(1u);
return v___x_217_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_DependentTypes_f2(void){
_start:
{
lean_object* v___x_218_; 
v___x_218_ = lean_unsigned_to_nat(2u);
return v___x_218_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_DependentTypes_one__pos(void){
_start:
{
lean_object* v___x_223_; 
v___x_223_ = lean_unsigned_to_nat(1u);
return v___x_223_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_DependentTypes_five__pos(void){
_start:
{
lean_object* v___x_224_; 
v___x_224_ = lean_unsigned_to_nat(5u);
return v___x_224_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_DependentTypes_pos__val(void){
_start:
{
lean_object* v___x_225_; 
v___x_225_ = lean_unsigned_to_nat(1u);
return v___x_225_;
}
}
lean_object* initialize_Init(uint8_t builtin);
lean_object* initialize_Init(uint8_t builtin);
static bool _G_initialized = false;
LEAN_EXPORT lean_object* initialize_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_DependentTypes(uint8_t builtin) {
lean_object * res;
if (_G_initialized) return lean_io_result_mk_ok(lean_box(0));
_G_initialized = true;
res = initialize_Init(builtin);
if (lean_io_result_is_error(res)) return res;
lean_dec_ref(res);
res = initialize_Init(builtin);
if (lean_io_result_is_error(res)) return res;
lean_dec_ref(res);
lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_DependentTypes_fin0__val = _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_DependentTypes_fin0__val();
lean_mark_persistent(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_DependentTypes_fin0__val);
lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_DependentTypes_fin1__val = _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_DependentTypes_fin1__val();
lean_mark_persistent(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_DependentTypes_fin1__val);
lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_DependentTypes_vnil = _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_DependentTypes_vnil();
lean_mark_persistent(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_DependentTypes_vnil);
lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_DependentTypes_len3 = _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_DependentTypes_len3();
lean_mark_persistent(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_DependentTypes_len3);
lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_DependentTypes_head2 = _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_DependentTypes_head2();
lean_mark_persistent(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_DependentTypes_head2);
lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_DependentTypes_tail2 = _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_DependentTypes_tail2();
lean_mark_persistent(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_DependentTypes_tail2);
lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_DependentTypes_vdoubled = _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_DependentTypes_vdoubled();
lean_mark_persistent(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_DependentTypes_vdoubled);
lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_DependentTypes_get__v3__0 = _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_DependentTypes_get__v3__0();
lean_mark_persistent(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_DependentTypes_get__v3__0);
lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_DependentTypes_get__v3__1 = _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_DependentTypes_get__v3__1();
lean_mark_persistent(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_DependentTypes_get__v3__1);
lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_DependentTypes_get__v3__2 = _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_DependentTypes_get__v3__2();
lean_mark_persistent(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_DependentTypes_get__v3__2);
lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_DependentTypes_get__v3__9 = _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_DependentTypes_get__v3__9();
lean_mark_persistent(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_DependentTypes_get__v3__9);
lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_DependentTypes_f0 = _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_DependentTypes_f0();
lean_mark_persistent(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_DependentTypes_f0);
lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_DependentTypes_f1 = _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_DependentTypes_f1();
lean_mark_persistent(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_DependentTypes_f1);
lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_DependentTypes_f2 = _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_DependentTypes_f2();
lean_mark_persistent(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_DependentTypes_f2);
lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_DependentTypes_one__pos = _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_DependentTypes_one__pos();
lean_mark_persistent(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_DependentTypes_one__pos);
lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_DependentTypes_five__pos = _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_DependentTypes_five__pos();
lean_mark_persistent(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_DependentTypes_five__pos);
lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_DependentTypes_pos__val = _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_DependentTypes_pos__val();
lean_mark_persistent(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_InductiveTypes_DependentTypes_pos__val);
return lean_io_result_mk_ok(lean_box(0));
}
#ifdef __cplusplus
}
#endif
