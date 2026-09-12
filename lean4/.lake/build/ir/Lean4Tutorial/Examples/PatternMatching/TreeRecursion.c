// Lean compiler output
// Module: Lean4Tutorial.Examples.PatternMatching.TreeRecursion
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
lean_object* l_Nat_reprFast(lean_object*);
uint8_t lean_nat_dec_eq(lean_object*, lean_object*);
lean_object* lean_nat_sub(lean_object*, lean_object*);
lean_object* l_List_appendTR___redArg(lean_object*, lean_object*);
lean_object* lean_nat_add(lean_object*, lean_object*);
lean_object* l_Repr_addAppParen(lean_object*, lean_object*);
uint8_t lean_nat_dec_le(lean_object*, lean_object*);
lean_object* lean_nat_to_int(lean_object*);
lean_object* lean_nat_mul(lean_object*, lean_object*);
uint8_t l_List_isEmpty___redArg(lean_object*);
uint8_t lean_nat_dec_lt(lean_object*, lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_BinTree_ctorIdx___redArg(lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_BinTree_ctorIdx___redArg___boxed(lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_BinTree_ctorIdx(lean_object*, lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_BinTree_ctorIdx___boxed(lean_object*, lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_BinTree_ctorElim___redArg(lean_object*, lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_BinTree_ctorElim(lean_object*, lean_object*, lean_object*, lean_object*, lean_object*, lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_BinTree_ctorElim___boxed(lean_object*, lean_object*, lean_object*, lean_object*, lean_object*, lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_BinTree_leaf_elim___redArg(lean_object*, lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_BinTree_leaf_elim(lean_object*, lean_object*, lean_object*, lean_object*, lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_BinTree_node_elim___redArg(lean_object*, lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_BinTree_node_elim(lean_object*, lean_object*, lean_object*, lean_object*, lean_object*);
static const lean_string_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_instReprBinTree_repr___redArg___closed__0_value = {.m_header = {.m_rc = 0, .m_cs_sz = 0, .m_other = 0, .m_tag = 249}, .m_size = 66, .m_capacity = 66, .m_length = 65, .m_data = "Lean4Tutorial.Examples.PatternMatching.TreeRecursion.BinTree.leaf"};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_instReprBinTree_repr___redArg___closed__0 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_instReprBinTree_repr___redArg___closed__0_value;
static const lean_ctor_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_instReprBinTree_repr___redArg___closed__1_value = {.m_header = {.m_rc = 0, .m_cs_sz = sizeof(lean_ctor_object) + sizeof(void*)*1 + 0, .m_other = 1, .m_tag = 3}, .m_objs = {((lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_instReprBinTree_repr___redArg___closed__0_value)}};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_instReprBinTree_repr___redArg___closed__1 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_instReprBinTree_repr___redArg___closed__1_value;
static lean_once_cell_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_instReprBinTree_repr___redArg___closed__2_once = LEAN_ONCE_CELL_INITIALIZER;
static lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_instReprBinTree_repr___redArg___closed__2;
static lean_once_cell_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_instReprBinTree_repr___redArg___closed__3_once = LEAN_ONCE_CELL_INITIALIZER;
static lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_instReprBinTree_repr___redArg___closed__3;
static const lean_string_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_instReprBinTree_repr___redArg___closed__4_value = {.m_header = {.m_rc = 0, .m_cs_sz = 0, .m_other = 0, .m_tag = 249}, .m_size = 66, .m_capacity = 66, .m_length = 65, .m_data = "Lean4Tutorial.Examples.PatternMatching.TreeRecursion.BinTree.node"};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_instReprBinTree_repr___redArg___closed__4 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_instReprBinTree_repr___redArg___closed__4_value;
static const lean_ctor_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_instReprBinTree_repr___redArg___closed__5_value = {.m_header = {.m_rc = 0, .m_cs_sz = sizeof(lean_ctor_object) + sizeof(void*)*1 + 0, .m_other = 1, .m_tag = 3}, .m_objs = {((lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_instReprBinTree_repr___redArg___closed__4_value)}};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_instReprBinTree_repr___redArg___closed__5 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_instReprBinTree_repr___redArg___closed__5_value;
static const lean_ctor_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_instReprBinTree_repr___redArg___closed__6_value = {.m_header = {.m_rc = 0, .m_cs_sz = sizeof(lean_ctor_object) + sizeof(void*)*2 + 0, .m_other = 2, .m_tag = 5}, .m_objs = {((lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_instReprBinTree_repr___redArg___closed__5_value),((lean_object*)(((size_t)(1) << 1) | 1))}};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_instReprBinTree_repr___redArg___closed__6 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_instReprBinTree_repr___redArg___closed__6_value;
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_instReprBinTree_repr___redArg(lean_object*, lean_object*, lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_instReprBinTree_repr___redArg___boxed(lean_object*, lean_object*, lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_instReprBinTree_repr(lean_object*, lean_object*, lean_object*, lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_instReprBinTree_repr___boxed(lean_object*, lean_object*, lean_object*, lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_instReprBinTree___redArg(lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_instReprBinTree(lean_object*, lean_object*);
static const lean_ctor_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_example__tree___closed__0_value = {.m_header = {.m_rc = 0, .m_cs_sz = sizeof(lean_ctor_object) + sizeof(void*)*3 + 0, .m_other = 3, .m_tag = 1}, .m_objs = {((lean_object*)(((size_t)(2) << 1) | 1)),((lean_object*)(((size_t)(0) << 1) | 1)),((lean_object*)(((size_t)(0) << 1) | 1))}};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_example__tree___closed__0 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_example__tree___closed__0_value;
static const lean_ctor_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_example__tree___closed__1_value = {.m_header = {.m_rc = 0, .m_cs_sz = sizeof(lean_ctor_object) + sizeof(void*)*3 + 0, .m_other = 3, .m_tag = 1}, .m_objs = {((lean_object*)(((size_t)(1) << 1) | 1)),((lean_object*)(((size_t)(0) << 1) | 1)),((lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_example__tree___closed__0_value)}};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_example__tree___closed__1 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_example__tree___closed__1_value;
static const lean_ctor_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_example__tree___closed__2_value = {.m_header = {.m_rc = 0, .m_cs_sz = sizeof(lean_ctor_object) + sizeof(void*)*3 + 0, .m_other = 3, .m_tag = 1}, .m_objs = {((lean_object*)(((size_t)(7) << 1) | 1)),((lean_object*)(((size_t)(0) << 1) | 1)),((lean_object*)(((size_t)(0) << 1) | 1))}};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_example__tree___closed__2 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_example__tree___closed__2_value;
static const lean_ctor_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_example__tree___closed__3_value = {.m_header = {.m_rc = 0, .m_cs_sz = sizeof(lean_ctor_object) + sizeof(void*)*3 + 0, .m_other = 3, .m_tag = 1}, .m_objs = {((lean_object*)(((size_t)(5) << 1) | 1)),((lean_object*)(((size_t)(0) << 1) | 1)),((lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_example__tree___closed__2_value)}};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_example__tree___closed__3 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_example__tree___closed__3_value;
static const lean_ctor_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_example__tree___closed__4_value = {.m_header = {.m_rc = 0, .m_cs_sz = sizeof(lean_ctor_object) + sizeof(void*)*3 + 0, .m_other = 3, .m_tag = 1}, .m_objs = {((lean_object*)(((size_t)(3) << 1) | 1)),((lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_example__tree___closed__1_value),((lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_example__tree___closed__3_value)}};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_example__tree___closed__4 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_example__tree___closed__4_value;
LEAN_EXPORT const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_example__tree = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_example__tree___closed__4_value;
static const lean_ctor_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_single__node___closed__0_value = {.m_header = {.m_rc = 0, .m_cs_sz = sizeof(lean_ctor_object) + sizeof(void*)*3 + 0, .m_other = 3, .m_tag = 1}, .m_objs = {((lean_object*)(((size_t)(42) << 1) | 1)),((lean_object*)(((size_t)(0) << 1) | 1)),((lean_object*)(((size_t)(0) << 1) | 1))}};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_single__node___closed__0 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_single__node___closed__0_value;
LEAN_EXPORT const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_single__node = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_single__node___closed__0_value;
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_empty__tree;
static const lean_ctor_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_left__skewed___closed__0_value = {.m_header = {.m_rc = 0, .m_cs_sz = sizeof(lean_ctor_object) + sizeof(void*)*3 + 0, .m_other = 3, .m_tag = 1}, .m_objs = {((lean_object*)(((size_t)(3) << 1) | 1)),((lean_object*)(((size_t)(0) << 1) | 1)),((lean_object*)(((size_t)(0) << 1) | 1))}};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_left__skewed___closed__0 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_left__skewed___closed__0_value;
static const lean_ctor_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_left__skewed___closed__1_value = {.m_header = {.m_rc = 0, .m_cs_sz = sizeof(lean_ctor_object) + sizeof(void*)*3 + 0, .m_other = 3, .m_tag = 1}, .m_objs = {((lean_object*)(((size_t)(2) << 1) | 1)),((lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_left__skewed___closed__0_value),((lean_object*)(((size_t)(0) << 1) | 1))}};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_left__skewed___closed__1 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_left__skewed___closed__1_value;
static const lean_ctor_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_left__skewed___closed__2_value = {.m_header = {.m_rc = 0, .m_cs_sz = sizeof(lean_ctor_object) + sizeof(void*)*3 + 0, .m_other = 3, .m_tag = 1}, .m_objs = {((lean_object*)(((size_t)(1) << 1) | 1)),((lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_left__skewed___closed__1_value),((lean_object*)(((size_t)(0) << 1) | 1))}};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_left__skewed___closed__2 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_left__skewed___closed__2_value;
LEAN_EXPORT const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_left__skewed = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_left__skewed___closed__2_value;
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_size___redArg(lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_size___redArg___boxed(lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_size(lean_object*, lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_size___boxed(lean_object*, lean_object*);
static lean_once_cell_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_size__example___closed__0_once = LEAN_ONCE_CELL_INITIALIZER;
static lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_size__example___closed__0;
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_size__example;
static lean_once_cell_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_size__leaf___closed__0_once = LEAN_ONCE_CELL_INITIALIZER;
static lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_size__leaf___closed__0;
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_size__leaf;
static lean_once_cell_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_size__single___closed__0_once = LEAN_ONCE_CELL_INITIALIZER;
static lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_size__single___closed__0;
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_size__single;
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_height___redArg(lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_height___redArg___boxed(lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_height(lean_object*, lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_height___boxed(lean_object*, lean_object*);
static lean_once_cell_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_height__example___closed__0_once = LEAN_ONCE_CELL_INITIALIZER;
static lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_height__example___closed__0;
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_height__example;
static lean_once_cell_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_height__leaf___closed__0_once = LEAN_ONCE_CELL_INITIALIZER;
static lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_height__leaf___closed__0;
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_height__leaf;
static lean_once_cell_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_height__single___closed__0_once = LEAN_ONCE_CELL_INITIALIZER;
static lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_height__single___closed__0;
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_height__single;
LEAN_EXPORT uint8_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_isLeaf___redArg(lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_isLeaf___redArg___boxed(lean_object*);
LEAN_EXPORT uint8_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_isLeaf(lean_object*, lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_isLeaf___boxed(lean_object*, lean_object*);
static lean_once_cell_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_leaf__true___closed__0_once = LEAN_ONCE_CELL_INITIALIZER;
static uint8_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_leaf__true___closed__0;
LEAN_EXPORT uint8_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_leaf__true;
static const lean_ctor_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_leaf__false___closed__0_value = {.m_header = {.m_rc = 0, .m_cs_sz = sizeof(lean_ctor_object) + sizeof(void*)*3 + 0, .m_other = 3, .m_tag = 1}, .m_objs = {((lean_object*)(((size_t)(1) << 1) | 1)),((lean_object*)(((size_t)(0) << 1) | 1)),((lean_object*)(((size_t)(0) << 1) | 1))}};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_leaf__false___closed__0 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_leaf__false___closed__0_value;
static lean_once_cell_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_leaf__false___closed__1_once = LEAN_ONCE_CELL_INITIALIZER;
static uint8_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_leaf__false___closed__1;
LEAN_EXPORT uint8_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_leaf__false;
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_preorder___redArg(lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_preorder___redArg___boxed(lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_preorder(lean_object*, lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_preorder___boxed(lean_object*, lean_object*);
static lean_once_cell_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_preorder__example___closed__0_once = LEAN_ONCE_CELL_INITIALIZER;
static lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_preorder__example___closed__0;
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_preorder__example;
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_inorder___redArg(lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_inorder___redArg___boxed(lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_inorder(lean_object*, lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_inorder___boxed(lean_object*, lean_object*);
static lean_once_cell_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_inorder__example___closed__0_once = LEAN_ONCE_CELL_INITIALIZER;
static lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_inorder__example___closed__0;
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_inorder__example;
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_postorder___redArg(lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_postorder___redArg___boxed(lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_postorder(lean_object*, lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_postorder___boxed(lean_object*, lean_object*);
static lean_once_cell_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_postorder__example___closed__0_once = LEAN_ONCE_CELL_INITIALIZER;
static lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_postorder__example___closed__0;
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_postorder__example;
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_treeMap___redArg(lean_object*, lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_treeMap(lean_object*, lean_object*, lean_object*, lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_doubled__tree___lam__0(lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_doubled__tree___lam__0___boxed(lean_object*);
static const lean_closure_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_doubled__tree___closed__0_value = {.m_header = {.m_rc = 0, .m_cs_sz = sizeof(lean_closure_object) + sizeof(void*)*0, .m_other = 0, .m_tag = 245}, .m_fun = (void*)lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_doubled__tree___lam__0___boxed, .m_arity = 1, .m_num_fixed = 0, .m_objs = {} };
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_doubled__tree___closed__0 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_doubled__tree___closed__0_value;
static lean_once_cell_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_doubled__tree___closed__1_once = LEAN_ONCE_CELL_INITIALIZER;
static lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_doubled__tree___closed__1;
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_doubled__tree;
static const lean_closure_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_string__tree___closed__0_value = {.m_header = {.m_rc = 0, .m_cs_sz = sizeof(lean_closure_object) + sizeof(void*)*0, .m_other = 0, .m_tag = 245}, .m_fun = (void*)l_Nat_reprFast, .m_arity = 1, .m_num_fixed = 0, .m_objs = {} };
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_string__tree___closed__0 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_string__tree___closed__0_value;
static lean_once_cell_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_string__tree___closed__1_once = LEAN_ONCE_CELL_INITIALIZER;
static lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_string__tree___closed__1;
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_string__tree;
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_treeFold___redArg(lean_object*, lean_object*, lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_treeFold___redArg___boxed(lean_object*, lean_object*, lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_treeFold(lean_object*, lean_object*, lean_object*, lean_object*, lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_treeFold___boxed(lean_object*, lean_object*, lean_object*, lean_object*, lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_treeSum___lam__0(lean_object*, lean_object*, lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_treeSum___lam__0___boxed(lean_object*, lean_object*, lean_object*);
static const lean_closure_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_treeSum___closed__0_value = {.m_header = {.m_rc = 0, .m_cs_sz = sizeof(lean_closure_object) + sizeof(void*)*0, .m_other = 0, .m_tag = 245}, .m_fun = (void*)lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_treeSum___lam__0___boxed, .m_arity = 3, .m_num_fixed = 0, .m_objs = {} };
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_treeSum___closed__0 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_treeSum___closed__0_value;
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_treeSum(lean_object*);
static lean_once_cell_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_sum__example___closed__0_once = LEAN_ONCE_CELL_INITIALIZER;
static lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_sum__example___closed__0;
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_sum__example;
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_treeProduct___lam__0(lean_object*, lean_object*, lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_treeProduct___lam__0___boxed(lean_object*, lean_object*, lean_object*);
static const lean_closure_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_treeProduct___closed__0_value = {.m_header = {.m_rc = 0, .m_cs_sz = sizeof(lean_closure_object) + sizeof(void*)*0, .m_other = 0, .m_tag = 245}, .m_fun = (void*)lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_treeProduct___lam__0___boxed, .m_arity = 3, .m_num_fixed = 0, .m_objs = {} };
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_treeProduct___closed__0 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_treeProduct___closed__0_value;
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_treeProduct(lean_object*);
static lean_once_cell_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_product__example___closed__0_once = LEAN_ONCE_CELL_INITIALIZER;
static lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_product__example___closed__0;
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_product__example;
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_treeMax_x3f(lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_treeMax_x3f___boxed(lean_object*);
static lean_once_cell_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_max__example___closed__0_once = LEAN_ONCE_CELL_INITIALIZER;
static lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_max__example___closed__0;
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_max__example;
static lean_once_cell_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_max__leaf___closed__0_once = LEAN_ONCE_CELL_INITIALIZER;
static lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_max__leaf___closed__0;
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_max__leaf;
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_bstInsert(lean_object*, lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_List_foldl___at___00Lean4Tutorial_Examples_PatternMatching_TreeRecursion_bstFromList_spec__0(lean_object*, lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_bstFromList(lean_object*);
static const lean_ctor_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_bst__example___closed__0_value = {.m_header = {.m_rc = 0, .m_cs_sz = sizeof(lean_ctor_object) + sizeof(void*)*2 + 0, .m_other = 2, .m_tag = 1}, .m_objs = {((lean_object*)(((size_t)(7) << 1) | 1)),((lean_object*)(((size_t)(0) << 1) | 1))}};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_bst__example___closed__0 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_bst__example___closed__0_value;
static const lean_ctor_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_bst__example___closed__1_value = {.m_header = {.m_rc = 0, .m_cs_sz = sizeof(lean_ctor_object) + sizeof(void*)*2 + 0, .m_other = 2, .m_tag = 1}, .m_objs = {((lean_object*)(((size_t)(2) << 1) | 1)),((lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_bst__example___closed__0_value)}};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_bst__example___closed__1 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_bst__example___closed__1_value;
static const lean_ctor_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_bst__example___closed__2_value = {.m_header = {.m_rc = 0, .m_cs_sz = sizeof(lean_ctor_object) + sizeof(void*)*2 + 0, .m_other = 2, .m_tag = 1}, .m_objs = {((lean_object*)(((size_t)(5) << 1) | 1)),((lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_bst__example___closed__1_value)}};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_bst__example___closed__2 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_bst__example___closed__2_value;
static const lean_ctor_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_bst__example___closed__3_value = {.m_header = {.m_rc = 0, .m_cs_sz = sizeof(lean_ctor_object) + sizeof(void*)*2 + 0, .m_other = 2, .m_tag = 1}, .m_objs = {((lean_object*)(((size_t)(1) << 1) | 1)),((lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_bst__example___closed__2_value)}};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_bst__example___closed__3 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_bst__example___closed__3_value;
static const lean_ctor_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_bst__example___closed__4_value = {.m_header = {.m_rc = 0, .m_cs_sz = sizeof(lean_ctor_object) + sizeof(void*)*2 + 0, .m_other = 2, .m_tag = 1}, .m_objs = {((lean_object*)(((size_t)(3) << 1) | 1)),((lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_bst__example___closed__3_value)}};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_bst__example___closed__4 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_bst__example___closed__4_value;
static lean_once_cell_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_bst__example___closed__5_once = LEAN_ONCE_CELL_INITIALIZER;
static lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_bst__example___closed__5;
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_bst__example;
LEAN_EXPORT uint8_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_bstSearch(lean_object*, lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_bstSearch___boxed(lean_object*, lean_object*);
static lean_once_cell_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_search__5___closed__0_once = LEAN_ONCE_CELL_INITIALIZER;
static uint8_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_search__5___closed__0;
LEAN_EXPORT uint8_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_search__5;
static lean_once_cell_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_search__4___closed__0_once = LEAN_ONCE_CELL_INITIALIZER;
static uint8_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_search__4___closed__0;
LEAN_EXPORT uint8_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_search__4;
static lean_once_cell_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_search__7___closed__0_once = LEAN_ONCE_CELL_INITIALIZER;
static uint8_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_search__7___closed__0;
LEAN_EXPORT uint8_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_search__7;
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_bstMin(lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_bstMin___boxed(lean_object*);
static lean_once_cell_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_min__example___closed__0_once = LEAN_ONCE_CELL_INITIALIZER;
static lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_min__example___closed__0;
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_min__example;
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_bstMax(lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_bstMax___boxed(lean_object*);
static lean_once_cell_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_max__bst___closed__0_once = LEAN_ONCE_CELL_INITIALIZER;
static lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_max__bst___closed__0;
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_max__bst;
LEAN_EXPORT uint8_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_isBST_check(lean_object*, lean_object*, lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_isBST_check___boxed(lean_object*, lean_object*, lean_object*);
LEAN_EXPORT uint8_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_isBST(lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_isBST___boxed(lean_object*);
static lean_once_cell_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_bst__true___closed__0_once = LEAN_ONCE_CELL_INITIALIZER;
static uint8_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_bst__true___closed__0;
LEAN_EXPORT uint8_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_bst__true;
static const lean_ctor_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_bst__false___closed__0_value = {.m_header = {.m_rc = 0, .m_cs_sz = sizeof(lean_ctor_object) + sizeof(void*)*3 + 0, .m_other = 3, .m_tag = 1}, .m_objs = {((lean_object*)(((size_t)(5) << 1) | 1)),((lean_object*)(((size_t)(0) << 1) | 1)),((lean_object*)(((size_t)(0) << 1) | 1))}};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_bst__false___closed__0 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_bst__false___closed__0_value;
static const lean_ctor_object lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_bst__false___closed__1_value = {.m_header = {.m_rc = 0, .m_cs_sz = sizeof(lean_ctor_object) + sizeof(void*)*3 + 0, .m_other = 3, .m_tag = 1}, .m_objs = {((lean_object*)(((size_t)(3) << 1) | 1)),((lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_bst__false___closed__0_value),((lean_object*)(((size_t)(0) << 1) | 1))}};
static const lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_bst__false___closed__1 = (const lean_object*)&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_bst__false___closed__1_value;
static lean_once_cell_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_bst__false___closed__2_once = LEAN_ONCE_CELL_INITIALIZER;
static uint8_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_bst__false___closed__2;
LEAN_EXPORT uint8_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_bst__false;
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_mirror___redArg(lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_mirror(lean_object*, lean_object*);
static lean_once_cell_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_mirrored___closed__0_once = LEAN_ONCE_CELL_INITIALIZER;
static lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_mirrored___closed__0;
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_mirrored;
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial___private_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_0__Lean4Tutorial_Examples_PatternMatching_TreeRecursion_instReprBinTree_repr_match__1_splitter___redArg(lean_object*, lean_object*, lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial___private_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_0__Lean4Tutorial_Examples_PatternMatching_TreeRecursion_instReprBinTree_repr_match__1_splitter(lean_object*, lean_object*, lean_object*, lean_object*, lean_object*);
LEAN_EXPORT uint8_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_isFull___redArg(lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_isFull___redArg___boxed(lean_object*);
LEAN_EXPORT uint8_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_isFull(lean_object*, lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_isFull___boxed(lean_object*, lean_object*);
LEAN_EXPORT uint8_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_isBalanced___redArg(lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_isBalanced___redArg___boxed(lean_object*);
LEAN_EXPORT uint8_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_isBalanced(lean_object*, lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_isBalanced___boxed(lean_object*, lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_level___redArg(lean_object*, lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_level___redArg___boxed(lean_object*, lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_level(lean_object*, lean_object*, lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_level___boxed(lean_object*, lean_object*, lean_object*);
static lean_once_cell_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_level__0___closed__0_once = LEAN_ONCE_CELL_INITIALIZER;
static lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_level__0___closed__0;
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_level__0;
static lean_once_cell_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_level__1___closed__0_once = LEAN_ONCE_CELL_INITIALIZER;
static lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_level__1___closed__0;
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_level__1;
static lean_once_cell_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_level__2___closed__0_once = LEAN_ONCE_CELL_INITIALIZER;
static lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_level__2___closed__0;
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_level__2;
static lean_once_cell_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_level__3___closed__0_once = LEAN_ONCE_CELL_INITIALIZER;
static lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_level__3___closed__0;
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_level__3;
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_levelOrder_go___redArg(lean_object*, lean_object*, lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_levelOrder_go___redArg___boxed(lean_object*, lean_object*, lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_levelOrder_go(lean_object*, lean_object*, lean_object*, lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_levelOrder_go___boxed(lean_object*, lean_object*, lean_object*, lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_levelOrder___redArg(lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_levelOrder___redArg___boxed(lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_levelOrder(lean_object*, lean_object*);
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_levelOrder___boxed(lean_object*, lean_object*);
static lean_once_cell_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_level__order___closed__0_once = LEAN_ONCE_CELL_INITIALIZER;
static lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_level__order___closed__0;
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_level__order;
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_BinTree_ctorIdx___redArg(lean_object* v_x_1_){
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
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_BinTree_ctorIdx___redArg___boxed(lean_object* v_x_4_){
_start:
{
lean_object* v_res_5_; 
v_res_5_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_BinTree_ctorIdx___redArg(v_x_4_);
lean_dec(v_x_4_);
return v_res_5_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_BinTree_ctorIdx(lean_object* v_00_u03b1_6_, lean_object* v_x_7_){
_start:
{
lean_object* v___x_8_; 
v___x_8_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_BinTree_ctorIdx___redArg(v_x_7_);
return v___x_8_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_BinTree_ctorIdx___boxed(lean_object* v_00_u03b1_9_, lean_object* v_x_10_){
_start:
{
lean_object* v_res_11_; 
v_res_11_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_BinTree_ctorIdx(v_00_u03b1_9_, v_x_10_);
lean_dec(v_x_10_);
return v_res_11_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_BinTree_ctorElim___redArg(lean_object* v_t_12_, lean_object* v_k_13_){
_start:
{
if (lean_obj_tag(v_t_12_) == 0)
{
return v_k_13_;
}
else
{
lean_object* v_value_14_; lean_object* v_left_15_; lean_object* v_right_16_; lean_object* v___x_17_; 
v_value_14_ = lean_ctor_get(v_t_12_, 0);
lean_inc(v_value_14_);
v_left_15_ = lean_ctor_get(v_t_12_, 1);
lean_inc(v_left_15_);
v_right_16_ = lean_ctor_get(v_t_12_, 2);
lean_inc(v_right_16_);
lean_dec_ref_known(v_t_12_, 3);
v___x_17_ = lean_apply_3(v_k_13_, v_value_14_, v_left_15_, v_right_16_);
return v___x_17_;
}
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_BinTree_ctorElim(lean_object* v_00_u03b1_18_, lean_object* v_motive_19_, lean_object* v_ctorIdx_20_, lean_object* v_t_21_, lean_object* v_h_22_, lean_object* v_k_23_){
_start:
{
lean_object* v___x_24_; 
v___x_24_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_BinTree_ctorElim___redArg(v_t_21_, v_k_23_);
return v___x_24_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_BinTree_ctorElim___boxed(lean_object* v_00_u03b1_25_, lean_object* v_motive_26_, lean_object* v_ctorIdx_27_, lean_object* v_t_28_, lean_object* v_h_29_, lean_object* v_k_30_){
_start:
{
lean_object* v_res_31_; 
v_res_31_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_BinTree_ctorElim(v_00_u03b1_25_, v_motive_26_, v_ctorIdx_27_, v_t_28_, v_h_29_, v_k_30_);
lean_dec(v_ctorIdx_27_);
return v_res_31_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_BinTree_leaf_elim___redArg(lean_object* v_t_32_, lean_object* v_leaf_33_){
_start:
{
lean_object* v___x_34_; 
v___x_34_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_BinTree_ctorElim___redArg(v_t_32_, v_leaf_33_);
return v___x_34_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_BinTree_leaf_elim(lean_object* v_00_u03b1_35_, lean_object* v_motive_36_, lean_object* v_t_37_, lean_object* v_h_38_, lean_object* v_leaf_39_){
_start:
{
lean_object* v___x_40_; 
v___x_40_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_BinTree_ctorElim___redArg(v_t_37_, v_leaf_39_);
return v___x_40_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_BinTree_node_elim___redArg(lean_object* v_t_41_, lean_object* v_node_42_){
_start:
{
lean_object* v___x_43_; 
v___x_43_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_BinTree_ctorElim___redArg(v_t_41_, v_node_42_);
return v___x_43_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_BinTree_node_elim(lean_object* v_00_u03b1_44_, lean_object* v_motive_45_, lean_object* v_t_46_, lean_object* v_h_47_, lean_object* v_node_48_){
_start:
{
lean_object* v___x_49_; 
v___x_49_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_BinTree_ctorElim___redArg(v_t_46_, v_node_48_);
return v___x_49_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_instReprBinTree_repr___redArg___closed__2(void){
_start:
{
lean_object* v___x_53_; lean_object* v___x_54_; 
v___x_53_ = lean_unsigned_to_nat(2u);
v___x_54_ = lean_nat_to_int(v___x_53_);
return v___x_54_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_instReprBinTree_repr___redArg___closed__3(void){
_start:
{
lean_object* v___x_55_; lean_object* v___x_56_; 
v___x_55_ = lean_unsigned_to_nat(1u);
v___x_56_ = lean_nat_to_int(v___x_55_);
return v___x_56_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_instReprBinTree_repr___redArg(lean_object* v_inst_63_, lean_object* v_x_64_, lean_object* v_prec_65_){
_start:
{
lean_object* v___y_67_; 
if (lean_obj_tag(v_x_64_) == 0)
{
lean_object* v___x_73_; uint8_t v___x_74_; 
lean_dec_ref(v_inst_63_);
v___x_73_ = lean_unsigned_to_nat(1024u);
v___x_74_ = lean_nat_dec_le(v___x_73_, v_prec_65_);
if (v___x_74_ == 0)
{
lean_object* v___x_75_; 
v___x_75_ = lean_obj_once(&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_instReprBinTree_repr___redArg___closed__2, &lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_instReprBinTree_repr___redArg___closed__2_once, _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_instReprBinTree_repr___redArg___closed__2);
v___y_67_ = v___x_75_;
goto v___jp_66_;
}
else
{
lean_object* v___x_76_; 
v___x_76_ = lean_obj_once(&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_instReprBinTree_repr___redArg___closed__3, &lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_instReprBinTree_repr___redArg___closed__3_once, _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_instReprBinTree_repr___redArg___closed__3);
v___y_67_ = v___x_76_;
goto v___jp_66_;
}
}
else
{
lean_object* v_value_77_; lean_object* v_left_78_; lean_object* v_right_79_; lean_object* v___x_80_; lean_object* v___y_82_; uint8_t v___x_97_; 
v_value_77_ = lean_ctor_get(v_x_64_, 0);
lean_inc(v_value_77_);
v_left_78_ = lean_ctor_get(v_x_64_, 1);
lean_inc(v_left_78_);
v_right_79_ = lean_ctor_get(v_x_64_, 2);
lean_inc(v_right_79_);
lean_dec_ref_known(v_x_64_, 3);
v___x_80_ = lean_unsigned_to_nat(1024u);
v___x_97_ = lean_nat_dec_le(v___x_80_, v_prec_65_);
if (v___x_97_ == 0)
{
lean_object* v___x_98_; 
v___x_98_ = lean_obj_once(&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_instReprBinTree_repr___redArg___closed__2, &lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_instReprBinTree_repr___redArg___closed__2_once, _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_instReprBinTree_repr___redArg___closed__2);
v___y_82_ = v___x_98_;
goto v___jp_81_;
}
else
{
lean_object* v___x_99_; 
v___x_99_ = lean_obj_once(&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_instReprBinTree_repr___redArg___closed__3, &lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_instReprBinTree_repr___redArg___closed__3_once, _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_instReprBinTree_repr___redArg___closed__3);
v___y_82_ = v___x_99_;
goto v___jp_81_;
}
v___jp_81_:
{
lean_object* v___x_83_; lean_object* v___x_84_; lean_object* v___x_85_; lean_object* v___x_86_; lean_object* v___x_87_; lean_object* v___x_88_; lean_object* v___x_89_; lean_object* v___x_90_; lean_object* v___x_91_; lean_object* v___x_92_; lean_object* v___x_93_; uint8_t v___x_94_; lean_object* v___x_95_; lean_object* v___x_96_; 
v___x_83_ = lean_box(1);
v___x_84_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_instReprBinTree_repr___redArg___closed__6));
lean_inc_ref_n(v_inst_63_, 2);
v___x_85_ = lean_apply_2(v_inst_63_, v_value_77_, v___x_80_);
v___x_86_ = lean_alloc_ctor(5, 2, 0);
lean_ctor_set(v___x_86_, 0, v___x_84_);
lean_ctor_set(v___x_86_, 1, v___x_85_);
v___x_87_ = lean_alloc_ctor(5, 2, 0);
lean_ctor_set(v___x_87_, 0, v___x_86_);
lean_ctor_set(v___x_87_, 1, v___x_83_);
v___x_88_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_instReprBinTree_repr___redArg(v_inst_63_, v_left_78_, v___x_80_);
v___x_89_ = lean_alloc_ctor(5, 2, 0);
lean_ctor_set(v___x_89_, 0, v___x_87_);
lean_ctor_set(v___x_89_, 1, v___x_88_);
v___x_90_ = lean_alloc_ctor(5, 2, 0);
lean_ctor_set(v___x_90_, 0, v___x_89_);
lean_ctor_set(v___x_90_, 1, v___x_83_);
v___x_91_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_instReprBinTree_repr___redArg(v_inst_63_, v_right_79_, v___x_80_);
v___x_92_ = lean_alloc_ctor(5, 2, 0);
lean_ctor_set(v___x_92_, 0, v___x_90_);
lean_ctor_set(v___x_92_, 1, v___x_91_);
lean_inc(v___y_82_);
v___x_93_ = lean_alloc_ctor(4, 2, 0);
lean_ctor_set(v___x_93_, 0, v___y_82_);
lean_ctor_set(v___x_93_, 1, v___x_92_);
v___x_94_ = 0;
v___x_95_ = lean_alloc_ctor(6, 1, 1);
lean_ctor_set(v___x_95_, 0, v___x_93_);
lean_ctor_set_uint8(v___x_95_, sizeof(void*)*1, v___x_94_);
v___x_96_ = l_Repr_addAppParen(v___x_95_, v_prec_65_);
return v___x_96_;
}
}
v___jp_66_:
{
lean_object* v___x_68_; lean_object* v___x_69_; uint8_t v___x_70_; lean_object* v___x_71_; lean_object* v___x_72_; 
v___x_68_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_instReprBinTree_repr___redArg___closed__1));
lean_inc(v___y_67_);
v___x_69_ = lean_alloc_ctor(4, 2, 0);
lean_ctor_set(v___x_69_, 0, v___y_67_);
lean_ctor_set(v___x_69_, 1, v___x_68_);
v___x_70_ = 0;
v___x_71_ = lean_alloc_ctor(6, 1, 1);
lean_ctor_set(v___x_71_, 0, v___x_69_);
lean_ctor_set_uint8(v___x_71_, sizeof(void*)*1, v___x_70_);
v___x_72_ = l_Repr_addAppParen(v___x_71_, v_prec_65_);
return v___x_72_;
}
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_instReprBinTree_repr___redArg___boxed(lean_object* v_inst_100_, lean_object* v_x_101_, lean_object* v_prec_102_){
_start:
{
lean_object* v_res_103_; 
v_res_103_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_instReprBinTree_repr___redArg(v_inst_100_, v_x_101_, v_prec_102_);
lean_dec(v_prec_102_);
return v_res_103_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_instReprBinTree_repr(lean_object* v_00_u03b1_104_, lean_object* v_inst_105_, lean_object* v_x_106_, lean_object* v_prec_107_){
_start:
{
lean_object* v___x_108_; 
v___x_108_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_instReprBinTree_repr___redArg(v_inst_105_, v_x_106_, v_prec_107_);
return v___x_108_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_instReprBinTree_repr___boxed(lean_object* v_00_u03b1_109_, lean_object* v_inst_110_, lean_object* v_x_111_, lean_object* v_prec_112_){
_start:
{
lean_object* v_res_113_; 
v_res_113_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_instReprBinTree_repr(v_00_u03b1_109_, v_inst_110_, v_x_111_, v_prec_112_);
lean_dec(v_prec_112_);
return v_res_113_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_instReprBinTree___redArg(lean_object* v_inst_114_){
_start:
{
lean_object* v___x_115_; 
v___x_115_ = lean_alloc_closure((void*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_instReprBinTree_repr___boxed), 4, 2);
lean_closure_set(v___x_115_, 0, lean_box(0));
lean_closure_set(v___x_115_, 1, v_inst_114_);
return v___x_115_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_instReprBinTree(lean_object* v_00_u03b1_116_, lean_object* v_inst_117_){
_start:
{
lean_object* v___x_118_; 
v___x_118_ = lean_alloc_closure((void*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_instReprBinTree_repr___boxed), 4, 2);
lean_closure_set(v___x_118_, 0, lean_box(0));
lean_closure_set(v___x_118_, 1, v_inst_117_);
return v___x_118_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_empty__tree(void){
_start:
{
lean_object* v___x_142_; 
v___x_142_ = lean_box(0);
return v___x_142_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_size___redArg(lean_object* v_x_155_){
_start:
{
if (lean_obj_tag(v_x_155_) == 0)
{
lean_object* v___x_156_; 
v___x_156_ = lean_unsigned_to_nat(0u);
return v___x_156_;
}
else
{
lean_object* v_left_157_; lean_object* v_right_158_; lean_object* v___x_159_; lean_object* v___x_160_; lean_object* v___x_161_; lean_object* v___x_162_; lean_object* v___x_163_; 
v_left_157_ = lean_ctor_get(v_x_155_, 1);
v_right_158_ = lean_ctor_get(v_x_155_, 2);
v___x_159_ = lean_unsigned_to_nat(1u);
v___x_160_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_size___redArg(v_left_157_);
v___x_161_ = lean_nat_add(v___x_159_, v___x_160_);
lean_dec(v___x_160_);
v___x_162_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_size___redArg(v_right_158_);
v___x_163_ = lean_nat_add(v___x_161_, v___x_162_);
lean_dec(v___x_162_);
lean_dec(v___x_161_);
return v___x_163_;
}
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_size___redArg___boxed(lean_object* v_x_164_){
_start:
{
lean_object* v_res_165_; 
v_res_165_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_size___redArg(v_x_164_);
lean_dec(v_x_164_);
return v_res_165_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_size(lean_object* v_00_u03b1_166_, lean_object* v_x_167_){
_start:
{
lean_object* v___x_168_; 
v___x_168_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_size___redArg(v_x_167_);
return v___x_168_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_size___boxed(lean_object* v_00_u03b1_169_, lean_object* v_x_170_){
_start:
{
lean_object* v_res_171_; 
v_res_171_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_size(v_00_u03b1_169_, v_x_170_);
lean_dec(v_x_170_);
return v_res_171_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_size__example___closed__0(void){
_start:
{
lean_object* v___x_172_; lean_object* v___x_173_; 
v___x_172_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_example__tree));
v___x_173_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_size___redArg(v___x_172_);
return v___x_173_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_size__example(void){
_start:
{
lean_object* v___x_174_; 
v___x_174_ = lean_obj_once(&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_size__example___closed__0, &lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_size__example___closed__0_once, _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_size__example___closed__0);
return v___x_174_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_size__leaf___closed__0(void){
_start:
{
lean_object* v___x_175_; lean_object* v___x_176_; 
v___x_175_ = lean_box(0);
v___x_176_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_size___redArg(v___x_175_);
return v___x_176_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_size__leaf(void){
_start:
{
lean_object* v___x_177_; 
v___x_177_ = lean_obj_once(&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_size__leaf___closed__0, &lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_size__leaf___closed__0_once, _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_size__leaf___closed__0);
return v___x_177_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_size__single___closed__0(void){
_start:
{
lean_object* v___x_178_; lean_object* v___x_179_; 
v___x_178_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_single__node));
v___x_179_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_size___redArg(v___x_178_);
return v___x_179_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_size__single(void){
_start:
{
lean_object* v___x_180_; 
v___x_180_ = lean_obj_once(&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_size__single___closed__0, &lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_size__single___closed__0_once, _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_size__single___closed__0);
return v___x_180_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_height___redArg(lean_object* v_x_181_){
_start:
{
if (lean_obj_tag(v_x_181_) == 0)
{
lean_object* v___x_182_; 
v___x_182_ = lean_unsigned_to_nat(0u);
return v___x_182_;
}
else
{
lean_object* v_left_183_; lean_object* v_right_184_; lean_object* v___x_185_; lean_object* v___x_186_; lean_object* v___x_187_; uint8_t v___x_188_; 
v_left_183_ = lean_ctor_get(v_x_181_, 1);
v_right_184_ = lean_ctor_get(v_x_181_, 2);
v___x_185_ = lean_unsigned_to_nat(1u);
v___x_186_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_height___redArg(v_left_183_);
v___x_187_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_height___redArg(v_right_184_);
v___x_188_ = lean_nat_dec_le(v___x_186_, v___x_187_);
if (v___x_188_ == 0)
{
lean_object* v___x_189_; 
lean_dec(v___x_187_);
v___x_189_ = lean_nat_add(v___x_185_, v___x_186_);
lean_dec(v___x_186_);
return v___x_189_;
}
else
{
lean_object* v___x_190_; 
lean_dec(v___x_186_);
v___x_190_ = lean_nat_add(v___x_185_, v___x_187_);
lean_dec(v___x_187_);
return v___x_190_;
}
}
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_height___redArg___boxed(lean_object* v_x_191_){
_start:
{
lean_object* v_res_192_; 
v_res_192_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_height___redArg(v_x_191_);
lean_dec(v_x_191_);
return v_res_192_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_height(lean_object* v_00_u03b1_193_, lean_object* v_x_194_){
_start:
{
lean_object* v___x_195_; 
v___x_195_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_height___redArg(v_x_194_);
return v___x_195_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_height___boxed(lean_object* v_00_u03b1_196_, lean_object* v_x_197_){
_start:
{
lean_object* v_res_198_; 
v_res_198_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_height(v_00_u03b1_196_, v_x_197_);
lean_dec(v_x_197_);
return v_res_198_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_height__example___closed__0(void){
_start:
{
lean_object* v___x_199_; lean_object* v___x_200_; 
v___x_199_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_example__tree));
v___x_200_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_height___redArg(v___x_199_);
return v___x_200_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_height__example(void){
_start:
{
lean_object* v___x_201_; 
v___x_201_ = lean_obj_once(&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_height__example___closed__0, &lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_height__example___closed__0_once, _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_height__example___closed__0);
return v___x_201_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_height__leaf___closed__0(void){
_start:
{
lean_object* v___x_202_; lean_object* v___x_203_; 
v___x_202_ = lean_box(0);
v___x_203_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_height___redArg(v___x_202_);
return v___x_203_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_height__leaf(void){
_start:
{
lean_object* v___x_204_; 
v___x_204_ = lean_obj_once(&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_height__leaf___closed__0, &lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_height__leaf___closed__0_once, _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_height__leaf___closed__0);
return v___x_204_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_height__single___closed__0(void){
_start:
{
lean_object* v___x_205_; lean_object* v___x_206_; 
v___x_205_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_single__node));
v___x_206_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_height___redArg(v___x_205_);
return v___x_206_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_height__single(void){
_start:
{
lean_object* v___x_207_; 
v___x_207_ = lean_obj_once(&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_height__single___closed__0, &lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_height__single___closed__0_once, _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_height__single___closed__0);
return v___x_207_;
}
}
LEAN_EXPORT uint8_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_isLeaf___redArg(lean_object* v_x_208_){
_start:
{
if (lean_obj_tag(v_x_208_) == 0)
{
uint8_t v___x_209_; 
v___x_209_ = 1;
return v___x_209_;
}
else
{
uint8_t v___x_210_; 
v___x_210_ = 0;
return v___x_210_;
}
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_isLeaf___redArg___boxed(lean_object* v_x_211_){
_start:
{
uint8_t v_res_212_; lean_object* v_r_213_; 
v_res_212_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_isLeaf___redArg(v_x_211_);
lean_dec(v_x_211_);
v_r_213_ = lean_box(v_res_212_);
return v_r_213_;
}
}
LEAN_EXPORT uint8_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_isLeaf(lean_object* v_00_u03b1_214_, lean_object* v_x_215_){
_start:
{
uint8_t v___x_216_; 
v___x_216_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_isLeaf___redArg(v_x_215_);
return v___x_216_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_isLeaf___boxed(lean_object* v_00_u03b1_217_, lean_object* v_x_218_){
_start:
{
uint8_t v_res_219_; lean_object* v_r_220_; 
v_res_219_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_isLeaf(v_00_u03b1_217_, v_x_218_);
lean_dec(v_x_218_);
v_r_220_ = lean_box(v_res_219_);
return v_r_220_;
}
}
static uint8_t _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_leaf__true___closed__0(void){
_start:
{
lean_object* v___x_221_; uint8_t v___x_222_; 
v___x_221_ = lean_box(0);
v___x_222_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_isLeaf___redArg(v___x_221_);
return v___x_222_;
}
}
static uint8_t _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_leaf__true(void){
_start:
{
uint8_t v___x_223_; 
v___x_223_ = lean_uint8_once(&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_leaf__true___closed__0, &lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_leaf__true___closed__0_once, _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_leaf__true___closed__0);
return v___x_223_;
}
}
static uint8_t _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_leaf__false___closed__1(void){
_start:
{
lean_object* v___x_227_; uint8_t v___x_228_; 
v___x_227_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_leaf__false___closed__0));
v___x_228_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_isLeaf___redArg(v___x_227_);
return v___x_228_;
}
}
static uint8_t _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_leaf__false(void){
_start:
{
uint8_t v___x_229_; 
v___x_229_ = lean_uint8_once(&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_leaf__false___closed__1, &lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_leaf__false___closed__1_once, _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_leaf__false___closed__1);
return v___x_229_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_preorder___redArg(lean_object* v_x_230_){
_start:
{
if (lean_obj_tag(v_x_230_) == 0)
{
lean_object* v___x_231_; 
v___x_231_ = lean_box(0);
return v___x_231_;
}
else
{
lean_object* v_value_232_; lean_object* v_left_233_; lean_object* v_right_234_; lean_object* v___x_235_; lean_object* v___x_236_; lean_object* v___x_237_; lean_object* v___x_238_; 
v_value_232_ = lean_ctor_get(v_x_230_, 0);
v_left_233_ = lean_ctor_get(v_x_230_, 1);
v_right_234_ = lean_ctor_get(v_x_230_, 2);
v___x_235_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_preorder___redArg(v_left_233_);
lean_inc(v_value_232_);
v___x_236_ = lean_alloc_ctor(1, 2, 0);
lean_ctor_set(v___x_236_, 0, v_value_232_);
lean_ctor_set(v___x_236_, 1, v___x_235_);
v___x_237_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_preorder___redArg(v_right_234_);
v___x_238_ = l_List_appendTR___redArg(v___x_236_, v___x_237_);
return v___x_238_;
}
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_preorder___redArg___boxed(lean_object* v_x_239_){
_start:
{
lean_object* v_res_240_; 
v_res_240_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_preorder___redArg(v_x_239_);
lean_dec(v_x_239_);
return v_res_240_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_preorder(lean_object* v_00_u03b1_241_, lean_object* v_x_242_){
_start:
{
lean_object* v___x_243_; 
v___x_243_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_preorder___redArg(v_x_242_);
return v___x_243_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_preorder___boxed(lean_object* v_00_u03b1_244_, lean_object* v_x_245_){
_start:
{
lean_object* v_res_246_; 
v_res_246_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_preorder(v_00_u03b1_244_, v_x_245_);
lean_dec(v_x_245_);
return v_res_246_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_preorder__example___closed__0(void){
_start:
{
lean_object* v___x_247_; lean_object* v___x_248_; 
v___x_247_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_example__tree));
v___x_248_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_preorder___redArg(v___x_247_);
return v___x_248_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_preorder__example(void){
_start:
{
lean_object* v___x_249_; 
v___x_249_ = lean_obj_once(&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_preorder__example___closed__0, &lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_preorder__example___closed__0_once, _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_preorder__example___closed__0);
return v___x_249_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_inorder___redArg(lean_object* v_x_250_){
_start:
{
if (lean_obj_tag(v_x_250_) == 0)
{
lean_object* v___x_251_; 
v___x_251_ = lean_box(0);
return v___x_251_;
}
else
{
lean_object* v_value_252_; lean_object* v_left_253_; lean_object* v_right_254_; lean_object* v___x_255_; lean_object* v___x_256_; lean_object* v___x_257_; lean_object* v___x_258_; lean_object* v___x_259_; lean_object* v___x_260_; 
v_value_252_ = lean_ctor_get(v_x_250_, 0);
v_left_253_ = lean_ctor_get(v_x_250_, 1);
v_right_254_ = lean_ctor_get(v_x_250_, 2);
v___x_255_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_inorder___redArg(v_left_253_);
v___x_256_ = lean_box(0);
lean_inc(v_value_252_);
v___x_257_ = lean_alloc_ctor(1, 2, 0);
lean_ctor_set(v___x_257_, 0, v_value_252_);
lean_ctor_set(v___x_257_, 1, v___x_256_);
v___x_258_ = l_List_appendTR___redArg(v___x_255_, v___x_257_);
v___x_259_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_inorder___redArg(v_right_254_);
v___x_260_ = l_List_appendTR___redArg(v___x_258_, v___x_259_);
return v___x_260_;
}
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_inorder___redArg___boxed(lean_object* v_x_261_){
_start:
{
lean_object* v_res_262_; 
v_res_262_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_inorder___redArg(v_x_261_);
lean_dec(v_x_261_);
return v_res_262_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_inorder(lean_object* v_00_u03b1_263_, lean_object* v_x_264_){
_start:
{
lean_object* v___x_265_; 
v___x_265_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_inorder___redArg(v_x_264_);
return v___x_265_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_inorder___boxed(lean_object* v_00_u03b1_266_, lean_object* v_x_267_){
_start:
{
lean_object* v_res_268_; 
v_res_268_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_inorder(v_00_u03b1_266_, v_x_267_);
lean_dec(v_x_267_);
return v_res_268_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_inorder__example___closed__0(void){
_start:
{
lean_object* v___x_269_; lean_object* v___x_270_; 
v___x_269_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_example__tree));
v___x_270_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_inorder___redArg(v___x_269_);
return v___x_270_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_inorder__example(void){
_start:
{
lean_object* v___x_271_; 
v___x_271_ = lean_obj_once(&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_inorder__example___closed__0, &lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_inorder__example___closed__0_once, _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_inorder__example___closed__0);
return v___x_271_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_postorder___redArg(lean_object* v_x_272_){
_start:
{
if (lean_obj_tag(v_x_272_) == 0)
{
lean_object* v___x_273_; 
v___x_273_ = lean_box(0);
return v___x_273_;
}
else
{
lean_object* v_value_274_; lean_object* v_left_275_; lean_object* v_right_276_; lean_object* v___x_277_; lean_object* v___x_278_; lean_object* v___x_279_; lean_object* v___x_280_; lean_object* v___x_281_; lean_object* v___x_282_; 
v_value_274_ = lean_ctor_get(v_x_272_, 0);
v_left_275_ = lean_ctor_get(v_x_272_, 1);
v_right_276_ = lean_ctor_get(v_x_272_, 2);
v___x_277_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_postorder___redArg(v_left_275_);
v___x_278_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_postorder___redArg(v_right_276_);
v___x_279_ = l_List_appendTR___redArg(v___x_277_, v___x_278_);
v___x_280_ = lean_box(0);
lean_inc(v_value_274_);
v___x_281_ = lean_alloc_ctor(1, 2, 0);
lean_ctor_set(v___x_281_, 0, v_value_274_);
lean_ctor_set(v___x_281_, 1, v___x_280_);
v___x_282_ = l_List_appendTR___redArg(v___x_279_, v___x_281_);
return v___x_282_;
}
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_postorder___redArg___boxed(lean_object* v_x_283_){
_start:
{
lean_object* v_res_284_; 
v_res_284_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_postorder___redArg(v_x_283_);
lean_dec(v_x_283_);
return v_res_284_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_postorder(lean_object* v_00_u03b1_285_, lean_object* v_x_286_){
_start:
{
lean_object* v___x_287_; 
v___x_287_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_postorder___redArg(v_x_286_);
return v___x_287_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_postorder___boxed(lean_object* v_00_u03b1_288_, lean_object* v_x_289_){
_start:
{
lean_object* v_res_290_; 
v_res_290_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_postorder(v_00_u03b1_288_, v_x_289_);
lean_dec(v_x_289_);
return v_res_290_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_postorder__example___closed__0(void){
_start:
{
lean_object* v___x_291_; lean_object* v___x_292_; 
v___x_291_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_example__tree));
v___x_292_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_postorder___redArg(v___x_291_);
return v___x_292_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_postorder__example(void){
_start:
{
lean_object* v___x_293_; 
v___x_293_ = lean_obj_once(&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_postorder__example___closed__0, &lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_postorder__example___closed__0_once, _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_postorder__example___closed__0);
return v___x_293_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_treeMap___redArg(lean_object* v_f_294_, lean_object* v_x_295_){
_start:
{
if (lean_obj_tag(v_x_295_) == 0)
{
lean_object* v___x_296_; 
lean_dec(v_f_294_);
v___x_296_ = lean_box(0);
return v___x_296_;
}
else
{
lean_object* v_value_297_; lean_object* v_left_298_; lean_object* v_right_299_; lean_object* v___x_301_; uint8_t v_isShared_302_; uint8_t v_isSharedCheck_309_; 
v_value_297_ = lean_ctor_get(v_x_295_, 0);
v_left_298_ = lean_ctor_get(v_x_295_, 1);
v_right_299_ = lean_ctor_get(v_x_295_, 2);
v_isSharedCheck_309_ = !lean_is_exclusive(v_x_295_);
if (v_isSharedCheck_309_ == 0)
{
v___x_301_ = v_x_295_;
v_isShared_302_ = v_isSharedCheck_309_;
goto v_resetjp_300_;
}
else
{
lean_inc(v_right_299_);
lean_inc(v_left_298_);
lean_inc(v_value_297_);
lean_dec(v_x_295_);
v___x_301_ = lean_box(0);
v_isShared_302_ = v_isSharedCheck_309_;
goto v_resetjp_300_;
}
v_resetjp_300_:
{
lean_object* v___x_303_; lean_object* v___x_304_; lean_object* v___x_305_; lean_object* v___x_307_; 
lean_inc_n(v_f_294_, 2);
v___x_303_ = lean_apply_1(v_f_294_, v_value_297_);
v___x_304_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_treeMap___redArg(v_f_294_, v_left_298_);
v___x_305_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_treeMap___redArg(v_f_294_, v_right_299_);
if (v_isShared_302_ == 0)
{
lean_ctor_set(v___x_301_, 2, v___x_305_);
lean_ctor_set(v___x_301_, 1, v___x_304_);
lean_ctor_set(v___x_301_, 0, v___x_303_);
v___x_307_ = v___x_301_;
goto v_reusejp_306_;
}
else
{
lean_object* v_reuseFailAlloc_308_; 
v_reuseFailAlloc_308_ = lean_alloc_ctor(1, 3, 0);
lean_ctor_set(v_reuseFailAlloc_308_, 0, v___x_303_);
lean_ctor_set(v_reuseFailAlloc_308_, 1, v___x_304_);
lean_ctor_set(v_reuseFailAlloc_308_, 2, v___x_305_);
v___x_307_ = v_reuseFailAlloc_308_;
goto v_reusejp_306_;
}
v_reusejp_306_:
{
return v___x_307_;
}
}
}
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_treeMap(lean_object* v_00_u03b1_310_, lean_object* v_00_u03b2_311_, lean_object* v_f_312_, lean_object* v_x_313_){
_start:
{
lean_object* v___x_314_; 
v___x_314_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_treeMap___redArg(v_f_312_, v_x_313_);
return v___x_314_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_doubled__tree___lam__0(lean_object* v_x_315_){
_start:
{
lean_object* v___x_316_; lean_object* v___x_317_; 
v___x_316_ = lean_unsigned_to_nat(2u);
v___x_317_ = lean_nat_mul(v_x_315_, v___x_316_);
return v___x_317_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_doubled__tree___lam__0___boxed(lean_object* v_x_318_){
_start:
{
lean_object* v_res_319_; 
v_res_319_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_doubled__tree___lam__0(v_x_318_);
lean_dec(v_x_318_);
return v_res_319_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_doubled__tree___closed__1(void){
_start:
{
lean_object* v___x_321_; lean_object* v___f_322_; lean_object* v___x_323_; 
v___x_321_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_example__tree));
v___f_322_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_doubled__tree___closed__0));
v___x_323_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_treeMap___redArg(v___f_322_, v___x_321_);
return v___x_323_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_doubled__tree(void){
_start:
{
lean_object* v___x_324_; 
v___x_324_ = lean_obj_once(&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_doubled__tree___closed__1, &lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_doubled__tree___closed__1_once, _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_doubled__tree___closed__1);
return v___x_324_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_string__tree___closed__1(void){
_start:
{
lean_object* v___x_326_; lean_object* v___f_327_; lean_object* v___x_328_; 
v___x_326_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_example__tree));
v___f_327_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_string__tree___closed__0));
v___x_328_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_treeMap___redArg(v___f_327_, v___x_326_);
return v___x_328_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_string__tree(void){
_start:
{
lean_object* v___x_329_; 
v___x_329_ = lean_obj_once(&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_string__tree___closed__1, &lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_string__tree___closed__1_once, _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_string__tree___closed__1);
return v___x_329_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_treeFold___redArg(lean_object* v_f_330_, lean_object* v_init_331_, lean_object* v_x_332_){
_start:
{
if (lean_obj_tag(v_x_332_) == 0)
{
lean_dec(v_f_330_);
lean_inc(v_init_331_);
return v_init_331_;
}
else
{
lean_object* v_value_333_; lean_object* v_left_334_; lean_object* v_right_335_; lean_object* v___x_336_; lean_object* v___x_337_; lean_object* v___x_338_; 
v_value_333_ = lean_ctor_get(v_x_332_, 0);
lean_inc(v_value_333_);
v_left_334_ = lean_ctor_get(v_x_332_, 1);
lean_inc(v_left_334_);
v_right_335_ = lean_ctor_get(v_x_332_, 2);
lean_inc(v_right_335_);
lean_dec_ref_known(v_x_332_, 3);
lean_inc_n(v_f_330_, 2);
v___x_336_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_treeFold___redArg(v_f_330_, v_init_331_, v_left_334_);
v___x_337_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_treeFold___redArg(v_f_330_, v_init_331_, v_right_335_);
v___x_338_ = lean_apply_3(v_f_330_, v_value_333_, v___x_336_, v___x_337_);
return v___x_338_;
}
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_treeFold___redArg___boxed(lean_object* v_f_339_, lean_object* v_init_340_, lean_object* v_x_341_){
_start:
{
lean_object* v_res_342_; 
v_res_342_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_treeFold___redArg(v_f_339_, v_init_340_, v_x_341_);
lean_dec(v_init_340_);
return v_res_342_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_treeFold(lean_object* v_00_u03b1_343_, lean_object* v_00_u03b2_344_, lean_object* v_f_345_, lean_object* v_init_346_, lean_object* v_x_347_){
_start:
{
lean_object* v___x_348_; 
v___x_348_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_treeFold___redArg(v_f_345_, v_init_346_, v_x_347_);
return v___x_348_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_treeFold___boxed(lean_object* v_00_u03b1_349_, lean_object* v_00_u03b2_350_, lean_object* v_f_351_, lean_object* v_init_352_, lean_object* v_x_353_){
_start:
{
lean_object* v_res_354_; 
v_res_354_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_treeFold(v_00_u03b1_349_, v_00_u03b2_350_, v_f_351_, v_init_352_, v_x_353_);
lean_dec(v_init_352_);
return v_res_354_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_treeSum___lam__0(lean_object* v_v_355_, lean_object* v_l_356_, lean_object* v_r_357_){
_start:
{
lean_object* v___x_358_; lean_object* v___x_359_; 
v___x_358_ = lean_nat_add(v_v_355_, v_l_356_);
v___x_359_ = lean_nat_add(v___x_358_, v_r_357_);
lean_dec(v___x_358_);
return v___x_359_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_treeSum___lam__0___boxed(lean_object* v_v_360_, lean_object* v_l_361_, lean_object* v_r_362_){
_start:
{
lean_object* v_res_363_; 
v_res_363_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_treeSum___lam__0(v_v_360_, v_l_361_, v_r_362_);
lean_dec(v_r_362_);
lean_dec(v_l_361_);
lean_dec(v_v_360_);
return v_res_363_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_treeSum(lean_object* v_a_365_){
_start:
{
lean_object* v___f_366_; lean_object* v___x_367_; lean_object* v___x_368_; 
v___f_366_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_treeSum___closed__0));
v___x_367_ = lean_unsigned_to_nat(0u);
v___x_368_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_treeFold___redArg(v___f_366_, v___x_367_, v_a_365_);
return v___x_368_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_sum__example___closed__0(void){
_start:
{
lean_object* v___x_369_; lean_object* v___x_370_; 
v___x_369_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_example__tree));
v___x_370_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_treeSum(v___x_369_);
return v___x_370_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_sum__example(void){
_start:
{
lean_object* v___x_371_; 
v___x_371_ = lean_obj_once(&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_sum__example___closed__0, &lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_sum__example___closed__0_once, _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_sum__example___closed__0);
return v___x_371_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_treeProduct___lam__0(lean_object* v_v_372_, lean_object* v_l_373_, lean_object* v_r_374_){
_start:
{
lean_object* v___x_375_; lean_object* v___x_376_; 
v___x_375_ = lean_nat_mul(v_v_372_, v_l_373_);
v___x_376_ = lean_nat_mul(v___x_375_, v_r_374_);
lean_dec(v___x_375_);
return v___x_376_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_treeProduct___lam__0___boxed(lean_object* v_v_377_, lean_object* v_l_378_, lean_object* v_r_379_){
_start:
{
lean_object* v_res_380_; 
v_res_380_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_treeProduct___lam__0(v_v_377_, v_l_378_, v_r_379_);
lean_dec(v_r_379_);
lean_dec(v_l_378_);
lean_dec(v_v_377_);
return v_res_380_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_treeProduct(lean_object* v_a_382_){
_start:
{
lean_object* v___f_383_; lean_object* v___x_384_; lean_object* v___x_385_; 
v___f_383_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_treeProduct___closed__0));
v___x_384_ = lean_unsigned_to_nat(1u);
v___x_385_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_treeFold___redArg(v___f_383_, v___x_384_, v_a_382_);
return v___x_385_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_product__example___closed__0(void){
_start:
{
lean_object* v___x_386_; lean_object* v___x_387_; 
v___x_386_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_example__tree));
v___x_387_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_treeProduct(v___x_386_);
return v___x_387_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_product__example(void){
_start:
{
lean_object* v___x_388_; 
v___x_388_ = lean_obj_once(&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_product__example___closed__0, &lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_product__example___closed__0_once, _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_product__example___closed__0);
return v___x_388_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_treeMax_x3f(lean_object* v_x_389_){
_start:
{
if (lean_obj_tag(v_x_389_) == 0)
{
lean_object* v___x_390_; 
v___x_390_ = lean_box(0);
return v___x_390_;
}
else
{
lean_object* v_value_391_; lean_object* v_left_392_; lean_object* v_right_393_; lean_object* v___y_395_; lean_object* v_lm_400_; lean_object* v___x_404_; 
v_value_391_ = lean_ctor_get(v_x_389_, 0);
v_left_392_ = lean_ctor_get(v_x_389_, 1);
v_right_393_ = lean_ctor_get(v_x_389_, 2);
v___x_404_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_treeMax_x3f(v_left_392_);
if (lean_obj_tag(v___x_404_) == 0)
{
lean_object* v___x_405_; 
v___x_405_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_treeMax_x3f(v_right_393_);
if (lean_obj_tag(v___x_405_) == 0)
{
lean_object* v___x_406_; 
lean_inc(v_value_391_);
v___x_406_ = lean_alloc_ctor(1, 1, 0);
lean_ctor_set(v___x_406_, 0, v_value_391_);
return v___x_406_;
}
else
{
lean_object* v_val_407_; 
v_val_407_ = lean_ctor_get(v___x_405_, 0);
lean_inc(v_val_407_);
lean_dec_ref_known(v___x_405_, 1);
v_lm_400_ = v_val_407_;
goto v___jp_399_;
}
}
else
{
lean_object* v_val_408_; lean_object* v___x_409_; 
v_val_408_ = lean_ctor_get(v___x_404_, 0);
lean_inc(v_val_408_);
lean_dec_ref_known(v___x_404_, 1);
v___x_409_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_treeMax_x3f(v_right_393_);
if (lean_obj_tag(v___x_409_) == 0)
{
v_lm_400_ = v_val_408_;
goto v___jp_399_;
}
else
{
lean_object* v_val_410_; uint8_t v___x_411_; 
v_val_410_ = lean_ctor_get(v___x_409_, 0);
lean_inc(v_val_410_);
lean_dec_ref_known(v___x_409_, 1);
v___x_411_ = lean_nat_dec_le(v_val_408_, v_val_410_);
if (v___x_411_ == 0)
{
lean_dec(v_val_410_);
v___y_395_ = v_val_408_;
goto v___jp_394_;
}
else
{
lean_dec(v_val_408_);
v___y_395_ = v_val_410_;
goto v___jp_394_;
}
}
}
v___jp_394_:
{
uint8_t v___x_396_; 
v___x_396_ = lean_nat_dec_le(v_value_391_, v___y_395_);
if (v___x_396_ == 0)
{
lean_object* v___x_397_; 
lean_dec(v___y_395_);
lean_inc(v_value_391_);
v___x_397_ = lean_alloc_ctor(1, 1, 0);
lean_ctor_set(v___x_397_, 0, v_value_391_);
return v___x_397_;
}
else
{
lean_object* v___x_398_; 
v___x_398_ = lean_alloc_ctor(1, 1, 0);
lean_ctor_set(v___x_398_, 0, v___y_395_);
return v___x_398_;
}
}
v___jp_399_:
{
uint8_t v___x_401_; 
v___x_401_ = lean_nat_dec_le(v_value_391_, v_lm_400_);
if (v___x_401_ == 0)
{
lean_object* v___x_402_; 
lean_dec(v_lm_400_);
lean_inc(v_value_391_);
v___x_402_ = lean_alloc_ctor(1, 1, 0);
lean_ctor_set(v___x_402_, 0, v_value_391_);
return v___x_402_;
}
else
{
lean_object* v___x_403_; 
v___x_403_ = lean_alloc_ctor(1, 1, 0);
lean_ctor_set(v___x_403_, 0, v_lm_400_);
return v___x_403_;
}
}
}
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_treeMax_x3f___boxed(lean_object* v_x_412_){
_start:
{
lean_object* v_res_413_; 
v_res_413_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_treeMax_x3f(v_x_412_);
lean_dec(v_x_412_);
return v_res_413_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_max__example___closed__0(void){
_start:
{
lean_object* v___x_414_; lean_object* v___x_415_; 
v___x_414_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_example__tree));
v___x_415_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_treeMax_x3f(v___x_414_);
return v___x_415_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_max__example(void){
_start:
{
lean_object* v___x_416_; 
v___x_416_ = lean_obj_once(&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_max__example___closed__0, &lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_max__example___closed__0_once, _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_max__example___closed__0);
return v___x_416_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_max__leaf___closed__0(void){
_start:
{
lean_object* v___x_417_; lean_object* v___x_418_; 
v___x_417_ = lean_box(0);
v___x_418_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_treeMax_x3f(v___x_417_);
return v___x_418_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_max__leaf(void){
_start:
{
lean_object* v___x_419_; 
v___x_419_ = lean_obj_once(&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_max__leaf___closed__0, &lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_max__leaf___closed__0_once, _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_max__leaf___closed__0);
return v___x_419_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_bstInsert(lean_object* v_x_420_, lean_object* v_x_421_){
_start:
{
if (lean_obj_tag(v_x_420_) == 0)
{
lean_object* v___x_422_; 
v___x_422_ = lean_alloc_ctor(1, 3, 0);
lean_ctor_set(v___x_422_, 0, v_x_421_);
lean_ctor_set(v___x_422_, 1, v_x_420_);
lean_ctor_set(v___x_422_, 2, v_x_420_);
return v___x_422_;
}
else
{
lean_object* v_value_423_; lean_object* v_left_424_; lean_object* v_right_425_; uint8_t v___x_426_; 
v_value_423_ = lean_ctor_get(v_x_420_, 0);
v_left_424_ = lean_ctor_get(v_x_420_, 1);
v_right_425_ = lean_ctor_get(v_x_420_, 2);
v___x_426_ = lean_nat_dec_lt(v_x_421_, v_value_423_);
if (v___x_426_ == 0)
{
uint8_t v___x_427_; 
v___x_427_ = lean_nat_dec_lt(v_value_423_, v_x_421_);
if (v___x_427_ == 0)
{
lean_dec(v_x_421_);
return v_x_420_;
}
else
{
lean_object* v___x_429_; uint8_t v_isShared_430_; uint8_t v_isSharedCheck_435_; 
lean_inc(v_right_425_);
lean_inc(v_left_424_);
lean_inc(v_value_423_);
v_isSharedCheck_435_ = !lean_is_exclusive(v_x_420_);
if (v_isSharedCheck_435_ == 0)
{
lean_object* v_unused_436_; lean_object* v_unused_437_; lean_object* v_unused_438_; 
v_unused_436_ = lean_ctor_get(v_x_420_, 2);
lean_dec(v_unused_436_);
v_unused_437_ = lean_ctor_get(v_x_420_, 1);
lean_dec(v_unused_437_);
v_unused_438_ = lean_ctor_get(v_x_420_, 0);
lean_dec(v_unused_438_);
v___x_429_ = v_x_420_;
v_isShared_430_ = v_isSharedCheck_435_;
goto v_resetjp_428_;
}
else
{
lean_dec(v_x_420_);
v___x_429_ = lean_box(0);
v_isShared_430_ = v_isSharedCheck_435_;
goto v_resetjp_428_;
}
v_resetjp_428_:
{
lean_object* v___x_431_; lean_object* v___x_433_; 
v___x_431_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_bstInsert(v_right_425_, v_x_421_);
if (v_isShared_430_ == 0)
{
lean_ctor_set(v___x_429_, 2, v___x_431_);
v___x_433_ = v___x_429_;
goto v_reusejp_432_;
}
else
{
lean_object* v_reuseFailAlloc_434_; 
v_reuseFailAlloc_434_ = lean_alloc_ctor(1, 3, 0);
lean_ctor_set(v_reuseFailAlloc_434_, 0, v_value_423_);
lean_ctor_set(v_reuseFailAlloc_434_, 1, v_left_424_);
lean_ctor_set(v_reuseFailAlloc_434_, 2, v___x_431_);
v___x_433_ = v_reuseFailAlloc_434_;
goto v_reusejp_432_;
}
v_reusejp_432_:
{
return v___x_433_;
}
}
}
}
else
{
lean_object* v___x_440_; uint8_t v_isShared_441_; uint8_t v_isSharedCheck_446_; 
lean_inc(v_right_425_);
lean_inc(v_left_424_);
lean_inc(v_value_423_);
v_isSharedCheck_446_ = !lean_is_exclusive(v_x_420_);
if (v_isSharedCheck_446_ == 0)
{
lean_object* v_unused_447_; lean_object* v_unused_448_; lean_object* v_unused_449_; 
v_unused_447_ = lean_ctor_get(v_x_420_, 2);
lean_dec(v_unused_447_);
v_unused_448_ = lean_ctor_get(v_x_420_, 1);
lean_dec(v_unused_448_);
v_unused_449_ = lean_ctor_get(v_x_420_, 0);
lean_dec(v_unused_449_);
v___x_440_ = v_x_420_;
v_isShared_441_ = v_isSharedCheck_446_;
goto v_resetjp_439_;
}
else
{
lean_dec(v_x_420_);
v___x_440_ = lean_box(0);
v_isShared_441_ = v_isSharedCheck_446_;
goto v_resetjp_439_;
}
v_resetjp_439_:
{
lean_object* v___x_442_; lean_object* v___x_444_; 
v___x_442_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_bstInsert(v_left_424_, v_x_421_);
if (v_isShared_441_ == 0)
{
lean_ctor_set(v___x_440_, 1, v___x_442_);
v___x_444_ = v___x_440_;
goto v_reusejp_443_;
}
else
{
lean_object* v_reuseFailAlloc_445_; 
v_reuseFailAlloc_445_ = lean_alloc_ctor(1, 3, 0);
lean_ctor_set(v_reuseFailAlloc_445_, 0, v_value_423_);
lean_ctor_set(v_reuseFailAlloc_445_, 1, v___x_442_);
lean_ctor_set(v_reuseFailAlloc_445_, 2, v_right_425_);
v___x_444_ = v_reuseFailAlloc_445_;
goto v_reusejp_443_;
}
v_reusejp_443_:
{
return v___x_444_;
}
}
}
}
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_List_foldl___at___00Lean4Tutorial_Examples_PatternMatching_TreeRecursion_bstFromList_spec__0(lean_object* v_x_450_, lean_object* v_x_451_){
_start:
{
if (lean_obj_tag(v_x_451_) == 0)
{
return v_x_450_;
}
else
{
lean_object* v_head_452_; lean_object* v_tail_453_; lean_object* v___x_454_; 
v_head_452_ = lean_ctor_get(v_x_451_, 0);
lean_inc(v_head_452_);
v_tail_453_ = lean_ctor_get(v_x_451_, 1);
lean_inc(v_tail_453_);
lean_dec_ref_known(v_x_451_, 2);
v___x_454_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_bstInsert(v_x_450_, v_head_452_);
v_x_450_ = v___x_454_;
v_x_451_ = v_tail_453_;
goto _start;
}
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_bstFromList(lean_object* v_l_456_){
_start:
{
lean_object* v___x_457_; lean_object* v___x_458_; 
v___x_457_ = lean_box(0);
v___x_458_ = lp_lean4_x2dtutorial_List_foldl___at___00Lean4Tutorial_Examples_PatternMatching_TreeRecursion_bstFromList_spec__0(v___x_457_, v_l_456_);
return v___x_458_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_bst__example___closed__5(void){
_start:
{
lean_object* v___x_474_; lean_object* v___x_475_; 
v___x_474_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_bst__example___closed__4));
v___x_475_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_bstFromList(v___x_474_);
return v___x_475_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_bst__example(void){
_start:
{
lean_object* v___x_476_; 
v___x_476_ = lean_obj_once(&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_bst__example___closed__5, &lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_bst__example___closed__5_once, _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_bst__example___closed__5);
return v___x_476_;
}
}
LEAN_EXPORT uint8_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_bstSearch(lean_object* v_x_477_, lean_object* v_x_478_){
_start:
{
if (lean_obj_tag(v_x_477_) == 0)
{
uint8_t v___x_479_; 
v___x_479_ = 0;
return v___x_479_;
}
else
{
lean_object* v_value_480_; lean_object* v_left_481_; lean_object* v_right_482_; uint8_t v___x_483_; 
v_value_480_ = lean_ctor_get(v_x_477_, 0);
v_left_481_ = lean_ctor_get(v_x_477_, 1);
v_right_482_ = lean_ctor_get(v_x_477_, 2);
v___x_483_ = lean_nat_dec_eq(v_x_478_, v_value_480_);
if (v___x_483_ == 0)
{
uint8_t v___x_484_; 
v___x_484_ = lean_nat_dec_lt(v_x_478_, v_value_480_);
if (v___x_484_ == 0)
{
v_x_477_ = v_right_482_;
goto _start;
}
else
{
v_x_477_ = v_left_481_;
goto _start;
}
}
else
{
return v___x_483_;
}
}
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_bstSearch___boxed(lean_object* v_x_487_, lean_object* v_x_488_){
_start:
{
uint8_t v_res_489_; lean_object* v_r_490_; 
v_res_489_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_bstSearch(v_x_487_, v_x_488_);
lean_dec(v_x_488_);
lean_dec(v_x_487_);
v_r_490_ = lean_box(v_res_489_);
return v_r_490_;
}
}
static uint8_t _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_search__5___closed__0(void){
_start:
{
lean_object* v___x_491_; lean_object* v___x_492_; uint8_t v___x_493_; 
v___x_491_ = lean_unsigned_to_nat(5u);
v___x_492_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_bst__example;
v___x_493_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_bstSearch(v___x_492_, v___x_491_);
return v___x_493_;
}
}
static uint8_t _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_search__5(void){
_start:
{
uint8_t v___x_494_; 
v___x_494_ = lean_uint8_once(&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_search__5___closed__0, &lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_search__5___closed__0_once, _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_search__5___closed__0);
return v___x_494_;
}
}
static uint8_t _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_search__4___closed__0(void){
_start:
{
lean_object* v___x_495_; lean_object* v___x_496_; uint8_t v___x_497_; 
v___x_495_ = lean_unsigned_to_nat(4u);
v___x_496_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_bst__example;
v___x_497_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_bstSearch(v___x_496_, v___x_495_);
return v___x_497_;
}
}
static uint8_t _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_search__4(void){
_start:
{
uint8_t v___x_498_; 
v___x_498_ = lean_uint8_once(&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_search__4___closed__0, &lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_search__4___closed__0_once, _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_search__4___closed__0);
return v___x_498_;
}
}
static uint8_t _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_search__7___closed__0(void){
_start:
{
lean_object* v___x_499_; lean_object* v___x_500_; uint8_t v___x_501_; 
v___x_499_ = lean_unsigned_to_nat(7u);
v___x_500_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_bst__example;
v___x_501_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_bstSearch(v___x_500_, v___x_499_);
return v___x_501_;
}
}
static uint8_t _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_search__7(void){
_start:
{
uint8_t v___x_502_; 
v___x_502_ = lean_uint8_once(&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_search__7___closed__0, &lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_search__7___closed__0_once, _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_search__7___closed__0);
return v___x_502_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_bstMin(lean_object* v_x_503_){
_start:
{
if (lean_obj_tag(v_x_503_) == 0)
{
lean_object* v___x_504_; 
v___x_504_ = lean_box(0);
return v___x_504_;
}
else
{
lean_object* v_left_505_; 
v_left_505_ = lean_ctor_get(v_x_503_, 1);
if (lean_obj_tag(v_left_505_) == 0)
{
lean_object* v_value_506_; lean_object* v___x_507_; 
v_value_506_ = lean_ctor_get(v_x_503_, 0);
lean_inc(v_value_506_);
v___x_507_ = lean_alloc_ctor(1, 1, 0);
lean_ctor_set(v___x_507_, 0, v_value_506_);
return v___x_507_;
}
else
{
v_x_503_ = v_left_505_;
goto _start;
}
}
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_bstMin___boxed(lean_object* v_x_509_){
_start:
{
lean_object* v_res_510_; 
v_res_510_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_bstMin(v_x_509_);
lean_dec(v_x_509_);
return v_res_510_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_min__example___closed__0(void){
_start:
{
lean_object* v___x_511_; lean_object* v___x_512_; 
v___x_511_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_bst__example;
v___x_512_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_bstMin(v___x_511_);
return v___x_512_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_min__example(void){
_start:
{
lean_object* v___x_513_; 
v___x_513_ = lean_obj_once(&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_min__example___closed__0, &lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_min__example___closed__0_once, _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_min__example___closed__0);
return v___x_513_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_bstMax(lean_object* v_x_514_){
_start:
{
if (lean_obj_tag(v_x_514_) == 0)
{
lean_object* v___x_515_; 
v___x_515_ = lean_box(0);
return v___x_515_;
}
else
{
lean_object* v_right_516_; 
v_right_516_ = lean_ctor_get(v_x_514_, 2);
if (lean_obj_tag(v_right_516_) == 0)
{
lean_object* v_value_517_; lean_object* v___x_518_; 
v_value_517_ = lean_ctor_get(v_x_514_, 0);
lean_inc(v_value_517_);
v___x_518_ = lean_alloc_ctor(1, 1, 0);
lean_ctor_set(v___x_518_, 0, v_value_517_);
return v___x_518_;
}
else
{
v_x_514_ = v_right_516_;
goto _start;
}
}
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_bstMax___boxed(lean_object* v_x_520_){
_start:
{
lean_object* v_res_521_; 
v_res_521_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_bstMax(v_x_520_);
lean_dec(v_x_520_);
return v_res_521_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_max__bst___closed__0(void){
_start:
{
lean_object* v___x_522_; lean_object* v___x_523_; 
v___x_522_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_bst__example;
v___x_523_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_bstMax(v___x_522_);
return v___x_523_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_max__bst(void){
_start:
{
lean_object* v___x_524_; 
v___x_524_ = lean_obj_once(&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_max__bst___closed__0, &lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_max__bst___closed__0_once, _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_max__bst___closed__0);
return v___x_524_;
}
}
LEAN_EXPORT uint8_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_isBST_check(lean_object* v_a_525_, lean_object* v_a_526_, lean_object* v_a_527_){
_start:
{
if (lean_obj_tag(v_a_525_) == 0)
{
uint8_t v___x_528_; 
lean_dec(v_a_526_);
v___x_528_ = 1;
return v___x_528_;
}
else
{
lean_object* v_value_529_; lean_object* v_left_530_; lean_object* v_right_531_; 
v_value_529_ = lean_ctor_get(v_a_525_, 0);
v_left_530_ = lean_ctor_get(v_a_525_, 1);
v_right_531_ = lean_ctor_get(v_a_525_, 2);
if (lean_obj_tag(v_a_526_) == 0)
{
goto v___jp_536_;
}
else
{
lean_object* v_val_539_; uint8_t v___x_540_; 
v_val_539_ = lean_ctor_get(v_a_526_, 0);
v___x_540_ = lean_nat_dec_lt(v_val_539_, v_value_529_);
if (v___x_540_ == 0)
{
lean_dec_ref_known(v_a_526_, 1);
return v___x_540_;
}
else
{
goto v___jp_536_;
}
}
v___jp_532_:
{
lean_object* v___x_533_; uint8_t v___x_534_; 
lean_inc(v_value_529_);
v___x_533_ = lean_alloc_ctor(1, 1, 0);
lean_ctor_set(v___x_533_, 0, v_value_529_);
v___x_534_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_isBST_check(v_left_530_, v_a_526_, v___x_533_);
if (v___x_534_ == 0)
{
lean_dec_ref_known(v___x_533_, 1);
return v___x_534_;
}
else
{
v_a_525_ = v_right_531_;
v_a_526_ = v___x_533_;
goto _start;
}
}
v___jp_536_:
{
if (lean_obj_tag(v_a_527_) == 0)
{
goto v___jp_532_;
}
else
{
lean_object* v_val_537_; uint8_t v___x_538_; 
v_val_537_ = lean_ctor_get(v_a_527_, 0);
v___x_538_ = lean_nat_dec_lt(v_value_529_, v_val_537_);
if (v___x_538_ == 0)
{
lean_dec(v_a_526_);
return v___x_538_;
}
else
{
goto v___jp_532_;
}
}
}
}
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_isBST_check___boxed(lean_object* v_a_541_, lean_object* v_a_542_, lean_object* v_a_543_){
_start:
{
uint8_t v_res_544_; lean_object* v_r_545_; 
v_res_544_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_isBST_check(v_a_541_, v_a_542_, v_a_543_);
lean_dec(v_a_543_);
lean_dec(v_a_541_);
v_r_545_ = lean_box(v_res_544_);
return v_r_545_;
}
}
LEAN_EXPORT uint8_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_isBST(lean_object* v_t_546_){
_start:
{
lean_object* v___x_547_; uint8_t v___x_548_; 
v___x_547_ = lean_box(0);
v___x_548_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_isBST_check(v_t_546_, v___x_547_, v___x_547_);
return v___x_548_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_isBST___boxed(lean_object* v_t_549_){
_start:
{
uint8_t v_res_550_; lean_object* v_r_551_; 
v_res_550_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_isBST(v_t_549_);
lean_dec(v_t_549_);
v_r_551_ = lean_box(v_res_550_);
return v_r_551_;
}
}
static uint8_t _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_bst__true___closed__0(void){
_start:
{
lean_object* v___x_552_; uint8_t v___x_553_; 
v___x_552_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_bst__example;
v___x_553_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_isBST(v___x_552_);
return v___x_553_;
}
}
static uint8_t _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_bst__true(void){
_start:
{
uint8_t v___x_554_; 
v___x_554_ = lean_uint8_once(&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_bst__true___closed__0, &lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_bst__true___closed__0_once, _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_bst__true___closed__0);
return v___x_554_;
}
}
static uint8_t _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_bst__false___closed__2(void){
_start:
{
lean_object* v___x_562_; uint8_t v___x_563_; 
v___x_562_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_bst__false___closed__1));
v___x_563_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_isBST(v___x_562_);
return v___x_563_;
}
}
static uint8_t _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_bst__false(void){
_start:
{
uint8_t v___x_564_; 
v___x_564_ = lean_uint8_once(&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_bst__false___closed__2, &lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_bst__false___closed__2_once, _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_bst__false___closed__2);
return v___x_564_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_mirror___redArg(lean_object* v_x_565_){
_start:
{
if (lean_obj_tag(v_x_565_) == 0)
{
return v_x_565_;
}
else
{
lean_object* v_value_566_; lean_object* v_left_567_; lean_object* v_right_568_; lean_object* v___x_570_; uint8_t v_isShared_571_; uint8_t v_isSharedCheck_577_; 
v_value_566_ = lean_ctor_get(v_x_565_, 0);
v_left_567_ = lean_ctor_get(v_x_565_, 1);
v_right_568_ = lean_ctor_get(v_x_565_, 2);
v_isSharedCheck_577_ = !lean_is_exclusive(v_x_565_);
if (v_isSharedCheck_577_ == 0)
{
v___x_570_ = v_x_565_;
v_isShared_571_ = v_isSharedCheck_577_;
goto v_resetjp_569_;
}
else
{
lean_inc(v_right_568_);
lean_inc(v_left_567_);
lean_inc(v_value_566_);
lean_dec(v_x_565_);
v___x_570_ = lean_box(0);
v_isShared_571_ = v_isSharedCheck_577_;
goto v_resetjp_569_;
}
v_resetjp_569_:
{
lean_object* v___x_572_; lean_object* v___x_573_; lean_object* v___x_575_; 
v___x_572_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_mirror___redArg(v_right_568_);
v___x_573_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_mirror___redArg(v_left_567_);
if (v_isShared_571_ == 0)
{
lean_ctor_set(v___x_570_, 2, v___x_573_);
lean_ctor_set(v___x_570_, 1, v___x_572_);
v___x_575_ = v___x_570_;
goto v_reusejp_574_;
}
else
{
lean_object* v_reuseFailAlloc_576_; 
v_reuseFailAlloc_576_ = lean_alloc_ctor(1, 3, 0);
lean_ctor_set(v_reuseFailAlloc_576_, 0, v_value_566_);
lean_ctor_set(v_reuseFailAlloc_576_, 1, v___x_572_);
lean_ctor_set(v_reuseFailAlloc_576_, 2, v___x_573_);
v___x_575_ = v_reuseFailAlloc_576_;
goto v_reusejp_574_;
}
v_reusejp_574_:
{
return v___x_575_;
}
}
}
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_mirror(lean_object* v_00_u03b1_578_, lean_object* v_x_579_){
_start:
{
lean_object* v___x_580_; 
v___x_580_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_mirror___redArg(v_x_579_);
return v___x_580_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_mirrored___closed__0(void){
_start:
{
lean_object* v___x_581_; lean_object* v___x_582_; 
v___x_581_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_example__tree));
v___x_582_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_mirror___redArg(v___x_581_);
return v___x_582_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_mirrored(void){
_start:
{
lean_object* v___x_583_; 
v___x_583_ = lean_obj_once(&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_mirrored___closed__0, &lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_mirrored___closed__0_once, _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_mirrored___closed__0);
return v___x_583_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial___private_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_0__Lean4Tutorial_Examples_PatternMatching_TreeRecursion_instReprBinTree_repr_match__1_splitter___redArg(lean_object* v_x_584_, lean_object* v_h__1_585_, lean_object* v_h__2_586_){
_start:
{
if (lean_obj_tag(v_x_584_) == 0)
{
lean_object* v___x_587_; lean_object* v___x_588_; 
lean_dec(v_h__2_586_);
v___x_587_ = lean_box(0);
v___x_588_ = lean_apply_1(v_h__1_585_, v___x_587_);
return v___x_588_;
}
else
{
lean_object* v_value_589_; lean_object* v_left_590_; lean_object* v_right_591_; lean_object* v___x_592_; 
lean_dec(v_h__1_585_);
v_value_589_ = lean_ctor_get(v_x_584_, 0);
lean_inc(v_value_589_);
v_left_590_ = lean_ctor_get(v_x_584_, 1);
lean_inc(v_left_590_);
v_right_591_ = lean_ctor_get(v_x_584_, 2);
lean_inc(v_right_591_);
lean_dec_ref_known(v_x_584_, 3);
v___x_592_ = lean_apply_3(v_h__2_586_, v_value_589_, v_left_590_, v_right_591_);
return v___x_592_;
}
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial___private_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_0__Lean4Tutorial_Examples_PatternMatching_TreeRecursion_instReprBinTree_repr_match__1_splitter(lean_object* v_00_u03b1_593_, lean_object* v_motive_594_, lean_object* v_x_595_, lean_object* v_h__1_596_, lean_object* v_h__2_597_){
_start:
{
if (lean_obj_tag(v_x_595_) == 0)
{
lean_object* v___x_598_; lean_object* v___x_599_; 
lean_dec(v_h__2_597_);
v___x_598_ = lean_box(0);
v___x_599_ = lean_apply_1(v_h__1_596_, v___x_598_);
return v___x_599_;
}
else
{
lean_object* v_value_600_; lean_object* v_left_601_; lean_object* v_right_602_; lean_object* v___x_603_; 
lean_dec(v_h__1_596_);
v_value_600_ = lean_ctor_get(v_x_595_, 0);
lean_inc(v_value_600_);
v_left_601_ = lean_ctor_get(v_x_595_, 1);
lean_inc(v_left_601_);
v_right_602_ = lean_ctor_get(v_x_595_, 2);
lean_inc(v_right_602_);
lean_dec_ref_known(v_x_595_, 3);
v___x_603_ = lean_apply_3(v_h__2_597_, v_value_600_, v_left_601_, v_right_602_);
return v___x_603_;
}
}
}
LEAN_EXPORT uint8_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_isFull___redArg(lean_object* v_x_604_){
_start:
{
if (lean_obj_tag(v_x_604_) == 0)
{
uint8_t v___x_605_; 
v___x_605_ = 1;
return v___x_605_;
}
else
{
lean_object* v_left_606_; 
v_left_606_ = lean_ctor_get(v_x_604_, 1);
if (lean_obj_tag(v_left_606_) == 0)
{
lean_object* v_right_607_; 
v_right_607_ = lean_ctor_get(v_x_604_, 2);
if (lean_obj_tag(v_right_607_) == 0)
{
uint8_t v___x_608_; 
v___x_608_ = 1;
return v___x_608_;
}
else
{
uint8_t v___x_609_; 
v___x_609_ = 0;
return v___x_609_;
}
}
else
{
lean_object* v_right_610_; 
v_right_610_ = lean_ctor_get(v_x_604_, 2);
if (lean_obj_tag(v_right_610_) == 0)
{
uint8_t v___x_611_; 
v___x_611_ = 0;
return v___x_611_;
}
else
{
uint8_t v___x_612_; 
v___x_612_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_isFull___redArg(v_left_606_);
if (v___x_612_ == 0)
{
return v___x_612_;
}
else
{
v_x_604_ = v_right_610_;
goto _start;
}
}
}
}
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_isFull___redArg___boxed(lean_object* v_x_614_){
_start:
{
uint8_t v_res_615_; lean_object* v_r_616_; 
v_res_615_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_isFull___redArg(v_x_614_);
lean_dec(v_x_614_);
v_r_616_ = lean_box(v_res_615_);
return v_r_616_;
}
}
LEAN_EXPORT uint8_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_isFull(lean_object* v_00_u03b1_617_, lean_object* v_x_618_){
_start:
{
uint8_t v___x_619_; 
v___x_619_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_isFull___redArg(v_x_618_);
return v___x_619_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_isFull___boxed(lean_object* v_00_u03b1_620_, lean_object* v_x_621_){
_start:
{
uint8_t v_res_622_; lean_object* v_r_623_; 
v_res_622_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_isFull(v_00_u03b1_620_, v_x_621_);
lean_dec(v_x_621_);
v_r_623_ = lean_box(v_res_622_);
return v_r_623_;
}
}
LEAN_EXPORT uint8_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_isBalanced___redArg(lean_object* v_x_624_){
_start:
{
if (lean_obj_tag(v_x_624_) == 0)
{
uint8_t v___x_625_; 
v___x_625_ = 1;
return v___x_625_;
}
else
{
lean_object* v_left_626_; lean_object* v_right_627_; uint8_t v___y_629_; uint8_t v___x_637_; 
v_left_626_ = lean_ctor_get(v_x_624_, 1);
v_right_627_ = lean_ctor_get(v_x_624_, 2);
v___x_637_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_isBalanced___redArg(v_left_626_);
if (v___x_637_ == 0)
{
v___y_629_ = v___x_637_;
goto v___jp_628_;
}
else
{
uint8_t v___x_638_; 
v___x_638_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_isBalanced___redArg(v_right_627_);
v___y_629_ = v___x_638_;
goto v___jp_628_;
}
v___jp_628_:
{
if (v___y_629_ == 0)
{
return v___y_629_;
}
else
{
lean_object* v___x_630_; lean_object* v___x_631_; lean_object* v___x_632_; lean_object* v___x_633_; uint8_t v___x_634_; 
v___x_630_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_height___redArg(v_left_626_);
v___x_631_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_height___redArg(v_right_627_);
v___x_632_ = lean_nat_sub(v___x_630_, v___x_631_);
v___x_633_ = lean_unsigned_to_nat(1u);
v___x_634_ = lean_nat_dec_le(v___x_632_, v___x_633_);
lean_dec(v___x_632_);
if (v___x_634_ == 0)
{
lean_dec(v___x_631_);
lean_dec(v___x_630_);
return v___x_634_;
}
else
{
lean_object* v___x_635_; uint8_t v___x_636_; 
v___x_635_ = lean_nat_sub(v___x_631_, v___x_630_);
lean_dec(v___x_630_);
lean_dec(v___x_631_);
v___x_636_ = lean_nat_dec_le(v___x_635_, v___x_633_);
lean_dec(v___x_635_);
return v___x_636_;
}
}
}
}
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_isBalanced___redArg___boxed(lean_object* v_x_639_){
_start:
{
uint8_t v_res_640_; lean_object* v_r_641_; 
v_res_640_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_isBalanced___redArg(v_x_639_);
lean_dec(v_x_639_);
v_r_641_ = lean_box(v_res_640_);
return v_r_641_;
}
}
LEAN_EXPORT uint8_t lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_isBalanced(lean_object* v_00_u03b1_642_, lean_object* v_x_643_){
_start:
{
uint8_t v___x_644_; 
v___x_644_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_isBalanced___redArg(v_x_643_);
return v___x_644_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_isBalanced___boxed(lean_object* v_00_u03b1_645_, lean_object* v_x_646_){
_start:
{
uint8_t v_res_647_; lean_object* v_r_648_; 
v_res_647_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_isBalanced(v_00_u03b1_645_, v_x_646_);
lean_dec(v_x_646_);
v_r_648_ = lean_box(v_res_647_);
return v_r_648_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_level___redArg(lean_object* v_x_649_, lean_object* v_x_650_){
_start:
{
if (lean_obj_tag(v_x_650_) == 0)
{
lean_object* v___x_651_; 
v___x_651_ = lean_box(0);
return v___x_651_;
}
else
{
lean_object* v_value_652_; lean_object* v_left_653_; lean_object* v_right_654_; lean_object* v_zero_655_; uint8_t v_isZero_656_; 
v_value_652_ = lean_ctor_get(v_x_650_, 0);
v_left_653_ = lean_ctor_get(v_x_650_, 1);
v_right_654_ = lean_ctor_get(v_x_650_, 2);
v_zero_655_ = lean_unsigned_to_nat(0u);
v_isZero_656_ = lean_nat_dec_eq(v_x_649_, v_zero_655_);
if (v_isZero_656_ == 1)
{
lean_object* v___x_657_; lean_object* v___x_658_; 
v___x_657_ = lean_box(0);
lean_inc(v_value_652_);
v___x_658_ = lean_alloc_ctor(1, 2, 0);
lean_ctor_set(v___x_658_, 0, v_value_652_);
lean_ctor_set(v___x_658_, 1, v___x_657_);
return v___x_658_;
}
else
{
lean_object* v_one_659_; lean_object* v_n_660_; lean_object* v___x_661_; lean_object* v___x_662_; lean_object* v___x_663_; 
v_one_659_ = lean_unsigned_to_nat(1u);
v_n_660_ = lean_nat_sub(v_x_649_, v_one_659_);
v___x_661_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_level___redArg(v_n_660_, v_left_653_);
v___x_662_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_level___redArg(v_n_660_, v_right_654_);
lean_dec(v_n_660_);
v___x_663_ = l_List_appendTR___redArg(v___x_661_, v___x_662_);
return v___x_663_;
}
}
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_level___redArg___boxed(lean_object* v_x_664_, lean_object* v_x_665_){
_start:
{
lean_object* v_res_666_; 
v_res_666_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_level___redArg(v_x_664_, v_x_665_);
lean_dec(v_x_665_);
lean_dec(v_x_664_);
return v_res_666_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_level(lean_object* v_00_u03b1_667_, lean_object* v_x_668_, lean_object* v_x_669_){
_start:
{
lean_object* v___x_670_; 
v___x_670_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_level___redArg(v_x_668_, v_x_669_);
return v___x_670_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_level___boxed(lean_object* v_00_u03b1_671_, lean_object* v_x_672_, lean_object* v_x_673_){
_start:
{
lean_object* v_res_674_; 
v_res_674_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_level(v_00_u03b1_671_, v_x_672_, v_x_673_);
lean_dec(v_x_673_);
lean_dec(v_x_672_);
return v_res_674_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_level__0___closed__0(void){
_start:
{
lean_object* v___x_675_; lean_object* v___x_676_; lean_object* v___x_677_; 
v___x_675_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_example__tree));
v___x_676_ = lean_unsigned_to_nat(0u);
v___x_677_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_level___redArg(v___x_676_, v___x_675_);
return v___x_677_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_level__0(void){
_start:
{
lean_object* v___x_678_; 
v___x_678_ = lean_obj_once(&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_level__0___closed__0, &lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_level__0___closed__0_once, _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_level__0___closed__0);
return v___x_678_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_level__1___closed__0(void){
_start:
{
lean_object* v___x_679_; lean_object* v___x_680_; lean_object* v___x_681_; 
v___x_679_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_example__tree));
v___x_680_ = lean_unsigned_to_nat(1u);
v___x_681_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_level___redArg(v___x_680_, v___x_679_);
return v___x_681_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_level__1(void){
_start:
{
lean_object* v___x_682_; 
v___x_682_ = lean_obj_once(&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_level__1___closed__0, &lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_level__1___closed__0_once, _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_level__1___closed__0);
return v___x_682_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_level__2___closed__0(void){
_start:
{
lean_object* v___x_683_; lean_object* v___x_684_; lean_object* v___x_685_; 
v___x_683_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_example__tree));
v___x_684_ = lean_unsigned_to_nat(2u);
v___x_685_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_level___redArg(v___x_684_, v___x_683_);
return v___x_685_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_level__2(void){
_start:
{
lean_object* v___x_686_; 
v___x_686_ = lean_obj_once(&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_level__2___closed__0, &lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_level__2___closed__0_once, _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_level__2___closed__0);
return v___x_686_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_level__3___closed__0(void){
_start:
{
lean_object* v___x_687_; lean_object* v___x_688_; lean_object* v___x_689_; 
v___x_687_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_example__tree));
v___x_688_ = lean_unsigned_to_nat(3u);
v___x_689_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_level___redArg(v___x_688_, v___x_687_);
return v___x_689_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_level__3(void){
_start:
{
lean_object* v___x_690_; 
v___x_690_ = lean_obj_once(&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_level__3___closed__0, &lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_level__3___closed__0_once, _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_level__3___closed__0);
return v___x_690_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_levelOrder_go___redArg(lean_object* v_t_691_, lean_object* v_a_692_, lean_object* v_a_693_){
_start:
{
lean_object* v_zero_694_; uint8_t v_isZero_695_; 
v_zero_694_ = lean_unsigned_to_nat(0u);
v_isZero_695_ = lean_nat_dec_eq(v_a_692_, v_zero_694_);
if (v_isZero_695_ == 1)
{
lean_object* v___x_696_; 
v___x_696_ = lean_box(0);
return v___x_696_;
}
else
{
lean_object* v_current_697_; uint8_t v___x_698_; 
v_current_697_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_level___redArg(v_a_693_, v_t_691_);
v___x_698_ = l_List_isEmpty___redArg(v_current_697_);
if (v___x_698_ == 0)
{
lean_object* v_one_699_; lean_object* v_n_700_; lean_object* v___x_701_; lean_object* v___x_702_; lean_object* v___x_703_; 
v_one_699_ = lean_unsigned_to_nat(1u);
v_n_700_ = lean_nat_sub(v_a_692_, v_one_699_);
v___x_701_ = lean_nat_add(v_a_693_, v_one_699_);
v___x_702_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_levelOrder_go___redArg(v_t_691_, v_n_700_, v___x_701_);
lean_dec(v___x_701_);
lean_dec(v_n_700_);
v___x_703_ = l_List_appendTR___redArg(v_current_697_, v___x_702_);
return v___x_703_;
}
else
{
lean_object* v___x_704_; 
lean_dec(v_current_697_);
v___x_704_ = lean_box(0);
return v___x_704_;
}
}
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_levelOrder_go___redArg___boxed(lean_object* v_t_705_, lean_object* v_a_706_, lean_object* v_a_707_){
_start:
{
lean_object* v_res_708_; 
v_res_708_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_levelOrder_go___redArg(v_t_705_, v_a_706_, v_a_707_);
lean_dec(v_a_707_);
lean_dec(v_a_706_);
lean_dec(v_t_705_);
return v_res_708_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_levelOrder_go(lean_object* v_00_u03b1_709_, lean_object* v_t_710_, lean_object* v_a_711_, lean_object* v_a_712_){
_start:
{
lean_object* v___x_713_; 
v___x_713_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_levelOrder_go___redArg(v_t_710_, v_a_711_, v_a_712_);
return v___x_713_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_levelOrder_go___boxed(lean_object* v_00_u03b1_714_, lean_object* v_t_715_, lean_object* v_a_716_, lean_object* v_a_717_){
_start:
{
lean_object* v_res_718_; 
v_res_718_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_levelOrder_go(v_00_u03b1_714_, v_t_715_, v_a_716_, v_a_717_);
lean_dec(v_a_717_);
lean_dec(v_a_716_);
lean_dec(v_t_715_);
return v_res_718_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_levelOrder___redArg(lean_object* v_t_719_){
_start:
{
lean_object* v___x_720_; lean_object* v___x_721_; lean_object* v___x_722_; 
v___x_720_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_height___redArg(v_t_719_);
v___x_721_ = lean_unsigned_to_nat(0u);
v___x_722_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_levelOrder_go___redArg(v_t_719_, v___x_720_, v___x_721_);
lean_dec(v___x_720_);
return v___x_722_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_levelOrder___redArg___boxed(lean_object* v_t_723_){
_start:
{
lean_object* v_res_724_; 
v_res_724_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_levelOrder___redArg(v_t_723_);
lean_dec(v_t_723_);
return v_res_724_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_levelOrder(lean_object* v_00_u03b1_725_, lean_object* v_t_726_){
_start:
{
lean_object* v___x_727_; 
v___x_727_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_levelOrder___redArg(v_t_726_);
return v___x_727_;
}
}
LEAN_EXPORT lean_object* lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_levelOrder___boxed(lean_object* v_00_u03b1_728_, lean_object* v_t_729_){
_start:
{
lean_object* v_res_730_; 
v_res_730_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_levelOrder(v_00_u03b1_728_, v_t_729_);
lean_dec(v_t_729_);
return v_res_730_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_level__order___closed__0(void){
_start:
{
lean_object* v___x_731_; lean_object* v___x_732_; 
v___x_731_ = ((lean_object*)(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_example__tree));
v___x_732_ = lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_levelOrder___redArg(v___x_731_);
return v___x_732_;
}
}
static lean_object* _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_level__order(void){
_start:
{
lean_object* v___x_733_; 
v___x_733_ = lean_obj_once(&lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_level__order___closed__0, &lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_level__order___closed__0_once, _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_level__order___closed__0);
return v___x_733_;
}
}
lean_object* initialize_Init(uint8_t builtin);
lean_object* initialize_Init(uint8_t builtin);
static bool _G_initialized = false;
LEAN_EXPORT lean_object* initialize_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion(uint8_t builtin) {
lean_object * res;
if (_G_initialized) return lean_io_result_mk_ok(lean_box(0));
_G_initialized = true;
res = initialize_Init(builtin);
if (lean_io_result_is_error(res)) return res;
lean_dec_ref(res);
res = initialize_Init(builtin);
if (lean_io_result_is_error(res)) return res;
lean_dec_ref(res);
lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_empty__tree = _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_empty__tree();
lean_mark_persistent(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_empty__tree);
lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_size__example = _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_size__example();
lean_mark_persistent(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_size__example);
lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_size__leaf = _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_size__leaf();
lean_mark_persistent(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_size__leaf);
lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_size__single = _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_size__single();
lean_mark_persistent(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_size__single);
lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_height__example = _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_height__example();
lean_mark_persistent(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_height__example);
lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_height__leaf = _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_height__leaf();
lean_mark_persistent(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_height__leaf);
lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_height__single = _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_height__single();
lean_mark_persistent(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_height__single);
lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_leaf__true = _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_leaf__true();
lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_leaf__false = _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_leaf__false();
lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_preorder__example = _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_preorder__example();
lean_mark_persistent(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_preorder__example);
lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_inorder__example = _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_inorder__example();
lean_mark_persistent(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_inorder__example);
lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_postorder__example = _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_postorder__example();
lean_mark_persistent(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_postorder__example);
lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_doubled__tree = _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_doubled__tree();
lean_mark_persistent(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_doubled__tree);
lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_string__tree = _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_string__tree();
lean_mark_persistent(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_string__tree);
lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_sum__example = _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_sum__example();
lean_mark_persistent(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_sum__example);
lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_product__example = _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_product__example();
lean_mark_persistent(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_product__example);
lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_max__example = _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_max__example();
lean_mark_persistent(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_max__example);
lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_max__leaf = _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_max__leaf();
lean_mark_persistent(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_max__leaf);
lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_bst__example = _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_bst__example();
lean_mark_persistent(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_bst__example);
lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_search__5 = _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_search__5();
lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_search__4 = _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_search__4();
lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_search__7 = _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_search__7();
lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_min__example = _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_min__example();
lean_mark_persistent(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_min__example);
lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_max__bst = _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_max__bst();
lean_mark_persistent(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_max__bst);
lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_bst__true = _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_bst__true();
lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_bst__false = _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_bst__false();
lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_mirrored = _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_mirrored();
lean_mark_persistent(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_mirrored);
lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_level__0 = _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_level__0();
lean_mark_persistent(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_level__0);
lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_level__1 = _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_level__1();
lean_mark_persistent(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_level__1);
lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_level__2 = _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_level__2();
lean_mark_persistent(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_level__2);
lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_level__3 = _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_level__3();
lean_mark_persistent(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_level__3);
lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_level__order = _init_lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_level__order();
lean_mark_persistent(lp_lean4_x2dtutorial_Lean4Tutorial_Examples_PatternMatching_TreeRecursion_level__order);
return lean_io_result_mk_ok(lean_box(0));
}
#ifdef __cplusplus
}
#endif
