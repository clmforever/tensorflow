/* Copyright 2024 The OpenXLA Authors.

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
==============================================================================*/

#ifndef XLA_SERVICE_GPU_FUSIONS_MLIR_PASSES_TD_
#define XLA_SERVICE_GPU_FUSIONS_MLIR_PASSES_TD_

include "mlir/Pass/PassBase.td"

def PropagateSliceIndicesPass :
   Pass<"xla-gpu-propagate-slice-indices", "mlir::ModuleOp"> {
  let summary = "Propagates slice indices from the entry function to all callees.";

  let description = [{
      Propagates xla.slice_index attributes from the function with the xla.entry
      attribute to all other functions.
  }];

  let dependentDialects = [
    "mlir::func::FuncDialect"
  ];

  let constructor = "CreatePropagateSliceIndicesPass()";
}

def LowerTensorsPass :
   Pass<"xla-gpu-lower-tensors", "mlir::ModuleOp"> {
  let summary = "Lowers tensors to llvm pointers and loads/stores.";

  let description = [{
      Lowers tensors to LLVM. We cannot use the memref lowerings because they
      are not compatible with XLA's ABI.
  }];

  let dependentDialects = [
    "mlir::func::FuncDialect", "mlir::LLVM::LLVMDialect",
    "mlir::tensor::TensorDialect",
  ];

  let constructor = "CreateLowerTensorsPass()";
}

def MergePointersToSameSlicePass :
   Pass<"xla-gpu-merge-pointers", "mlir::ModuleOp"> {
  let summary = "Merges pointers that share slices.";

  let description = [{
      When a function has multiple pointer arguments with the same slice index,
      merges them.
  }];

  let dependentDialects = [
    "mlir::func::FuncDialect"
  ];

  let constructor = "CreateMergePointersToSameSlicePass()";
}

def SimplifyAffinePass : Pass<"xla-gpu-simplify-affine", "mlir::ModuleOp"> {
  let summary = "Simplifies affine.apply using XLA's range-aware simplifier.";

  let description = [{
      The standard affine canonicalizer cannot simplify all expressions, since
      it is unaware of range information. This pass uses `xla.range` attributes
      on arguments and ops for simplification. It also lowers floordiv and mod
      to simpler expressions than lower-affine. This pass only works for
      expressions for which we can prove the LHS of mod and div is nonnegative.
  }];

  let dependentDialects = [
    "mlir::affine::AffineDialect", "mlir::func::FuncDialect",
    "mlir::scf::SCFDialect",
  ];

  let constructor = "CreateSimplifyAffinePass()";
}

def ExpandFloatConversionsPass : Pass<"xla-gpu-expand-conversions", "mlir::ModuleOp"> {
   let summary = "Expands float conversions that are not natively supported.";

   let description = [{
      Not all float conversions are natively supported, so the ones that aren't
      need to be emulated with bitwise operations.

      Currently, this pass only implements bf16 conversions.
   }];

   let dependentDialects = [
      "mlir::arith::ArithDialect", "mlir::mhlo::MhloDialect"
   ];

  let options = [
    Option<"include_bf16_", "include-bf16", "bool", /*default=*/"false",
           "Enable the BF16 <-> F32 expansion patterns.">,
  ];
}

def LowerToLLVMPass :
   Pass<"xla-gpu-lower-to-llvm", "mlir::ModuleOp"> {
  let summary = "Lowers to LLVM.";

  let description = [{
    Lowers the rest to LLVM
  }];

  let dependentDialects = [
    "mlir::func::FuncDialect", "mlir::LLVM::LLVMDialect"
  ];

  let constructor = "CreateLowerToLLVMPass()";
}

#endif  // XLA_SERVICE_GPU_FUSIONS_MLIR_PASSES_TD_
