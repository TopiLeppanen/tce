/*
    Copyright (c) 2002-2009 Tampere University of Technology.

    This file is part of TTA-Based Codesign Environment (TCE).

    Permission is hereby granted, free of charge, to any person obtaining a
    copy of this software and associated documentation files (the "Software"),
    to deal in the Software without restriction, including without limitation
    the rights to use, copy, modify, merge, publish, distribute, sublicense,
    and/or sell copies of the Software, and to permit persons to whom the
    Software is furnished to do so, subject to the following conditions:

    The above copyright notice and this permission notice shall be included in
    all copies or substantial portions of the Software.

    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
    IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
    FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
    THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
    LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
    FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
    DEALINGS IN THE SOFTWARE.
 */
/**
 * @file TCEDAGToDAGISel.cpp
 *
 * TCE DAG to DAG instruction selector implementation.
 *
 * @author Veli-Pekka J��skel�inen 2007 (vjaaskel-no.spam-cs.tut.fi)
 * @author Mikael Lepist� 2009 (mikael.lepisto-no.spam-tut.fi)
 */

#include <llvm/Intrinsics.h>
#include <llvm/Support/Debug.h>
#include <llvm/Support/Compiler.h>
#include <llvm/Support/raw_ostream.h>

#include "TCEDAGToDAGISel.hh"
#include "TCETargetMachine.hh"
#include "TCESubtarget.hh"
#include "TCEISelLowering.hh"

using namespace llvm;

class TCEDAGToDAGISel : public llvm::SelectionDAGISel {
public:
    explicit TCEDAGToDAGISel(llvm::TCETargetMachine& tm);
    virtual ~TCEDAGToDAGISel();

#if defined(LLVM_2_7) || defined(LLVM_2_8)
    bool SelectADDRrr(
        llvm::SDNode* op, llvm::SDValue addr,
        llvm::SDValue& r1, llvm::SDValue& r2);
    bool SelectADDRri(
        llvm::SDNode* op, llvm::SDValue addr,
        llvm::SDValue& base, llvm::SDValue& offset);
#else // LLVM_29-svn
    bool SelectADDRrr(SDValue N, SDValue &R1, SDValue &R2);
    bool SelectADDRri(SDValue N, SDValue &Base, SDValue &Offset);
#endif

    llvm::SDNode* Select(llvm::SDNode* op);

    virtual const char* getPassName() const {
        return "TCE DAG->DAG Pattern Instruction Selection";
    }

private:
    llvm::TCETargetLowering& lowering_;
    const llvm::TCESubtarget& subtarget_;

    #include "TCEGenDAGISel.inc"
};

/**
 * Constructor.
 */
TCEDAGToDAGISel::TCEDAGToDAGISel(TCETargetMachine& tm):
    SelectionDAGISel(tm), 
    lowering_(*static_cast<TCETargetLowering*>(tm.getTargetLowering())),
    subtarget_(tm.getSubtarget<TCESubtarget>()) {
}

/**
 * Destructor.
 */
TCEDAGToDAGISel::~TCEDAGToDAGISel() {
}

// from Sparc backend:
//void TCEDAGToDAGISel::InstructionSelect() {
    //DEBUG(BB->dump());
//  SelectRoot(*CurDAG);
//  CurDAG->RemoveDeadNodes();
//}

/**
 * Handles custom instruction selections.
 *
 * @param op Operation to select.
 */
SDNode*
TCEDAGToDAGISel::Select(SDNode* n) {

    DebugLoc dl = n->getDebugLoc();

    if (n->getOpcode() >= ISD::BUILTIN_OP_END &&
        n->getOpcode() < TCEISD::FIRST_NUMBER) {
        // Already selected.
        return NULL;
    } else if (n->getOpcode() == ISD::BRCOND) {

        // TODO: Check this. Following IA64 example..
        SDValue chain = n->getOperand(0);
        SDValue cc = n->getOperand(1);

        MachineBasicBlock* dest =
            cast<BasicBlockSDNode>(n->getOperand(2))->getBasicBlock();

        // FIXME? - this creates long branches all the time
        return CurDAG->SelectNodeTo(
            n, TCE::TCEBRCOND, MVT::Other, cc,
            CurDAG->getBasicBlock(dest), chain);
        //} else if (n->getOpcode() == ISD::SETCC) {
        //SDValue op1 = n->getOperand(0);
        //SDValue op1 = n->getOperand(1);
        //ISD::CondCode cc = cast<CondCodeSDNode>(op.getOperand(2))->get();
        //switch (cc) {
        //default: assert(false && "Unhandled CC");
        //case ISD::SETEQ: {
        //    return dag.getNode(TCE::EQ
        //}
        //}
    } else if (n->getOpcode() == ISD::BR) {
        SDValue chain = n->getOperand(0);

        MachineBasicBlock* dest =
            cast<BasicBlockSDNode>(n->getOperand(1))->getBasicBlock();
        return CurDAG->SelectNodeTo(
	    n, TCE::TCEBR, MVT::Other, CurDAG->getBasicBlock(dest), chain);
    } else if (n->getOpcode() == ISD::FrameIndex) {
        int fi = cast<FrameIndexSDNode>(n)->getIndex();
        if (n->hasOneUse()) {
            return CurDAG->SelectNodeTo(
                n, TCE::MOVI32ri, MVT::i32,
                CurDAG->getTargetFrameIndex(fi, MVT::i32));
        } else {
            return CurDAG->getMachineNode(
                TCE::MOVI32ri, dl, MVT::i32,
                CurDAG->getTargetFrameIndex(fi, MVT::i32));
        }
    }

   
    SDNode* res =  SelectCode(n);
    return res;
}

/**
 * Handles ADDRri operands.
 */
#if defined(LLVM_2_7) || defined(LLVM_2_8)
bool
TCEDAGToDAGISel::SelectADDRri(
    SDNode* op, SDValue addr, SDValue& base, SDValue& offset) {
#else // LLVM_29-svn
bool
TCEDAGToDAGISel::SelectADDRri(
    SDValue addr, SDValue& base, SDValue& offset) {
#endif

    if (FrameIndexSDNode* fin = dyn_cast<FrameIndexSDNode>(addr)) {
        base = CurDAG->getTargetFrameIndex(fin->getIndex(), MVT::i32);
        offset = CurDAG->getTargetConstant(0, MVT::i32);
        return true;
    } else if (addr.getOpcode() == ISD::TargetExternalSymbol ||
               addr.getOpcode() == ISD::TargetGlobalAddress) {

        return false;  // direct calls.
        /*
    } else if (addr.getOpcode() == ISD::ADD) {

        if (ConstantSDNode* cn =
            dyn_cast<ConstantSDNode>(addr.getOperand(1))) {

            if (FrameIndexSDNode* fin = 
                dyn_cast<FrameIndexSDNode>(addr.getOperand(0))) {

                base = CurDAG->getTargetFrameIndex(fin->getIndex(), MVT::i32);
                offset = CurDAG->getTargetConstant(cn->getValue(), MVT::i32);
                return true;
            }
        }
        */
    }
    base = addr;
    offset = CurDAG->getTargetConstant(0, MVT::i32);
    return true;
}

/**
 * Handles ADDRrr operands.
 */
#if defined(LLVM_2_7) || defined(LLVM_2_8)
bool
TCEDAGToDAGISel::SelectADDRrr(
    SDNode* op, SDValue addr, SDValue& r1, SDValue& r2) {
#else // LLVM_29-svn
bool
TCEDAGToDAGISel::SelectADDRrr(
    SDValue addr, SDValue& r1, SDValue& r2) {
#endif

    if (addr.getOpcode() == ISD::TargetGlobalAddress) {
        //r1 = addr.getOperand(0);
        //r2 = CurDAG->getTargetConstant(cn->getValue(), MVT::i32);
        //return true:
        return false;
    } else if (addr.getOpcode() == ISD::TargetExternalSymbol) {
        return false;
    } else if (addr.getOpcode() == ISD::FrameIndex) {
        return false;
    }

    r1 = addr;
    r2 = CurDAG->getTargetConstant(0, MVT::i32);
    return true;
}

/**
 * Returns an instance of the instruction selector.
 *
 * @param tm Target machine description.
 */
FunctionPass*
llvm::createTCEISelDag(TCETargetMachine& tm) {
    return new TCEDAGToDAGISel(tm);
}
