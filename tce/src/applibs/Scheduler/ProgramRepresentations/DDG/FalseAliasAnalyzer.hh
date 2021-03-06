/*
    Copyright (c) 2002-2009 Tampere University.

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
 * @file FalseAliasAnalyzer.hh
 *
 * Declaration of FalseAliasAnalyzer class.
 * 
 * @author Heikki Kultala 2007 (heikki.kultala-no.spam-tut.fi)
 * @note rating: red
 */

#ifndef TTA_FALSE_ALIAS_ANALYZER_HH
#define TTA_FALSE_ALIAS_ANALYZER_HH

#include "MemoryAliasAnalyzer.hh"
#include "InterPassDatum.hh"
#include "AssocTools.hh"

class FalseAliasAnalyzer : public MemoryAliasAnalyzer {
public:
    FalseAliasAnalyzer(FunctionNameList* enabledFuncs = nullptr) :
        funcs_(enabledFuncs) {}

    virtual bool isAddressTraceable(
        DataDependenceGraph& ddg, const ProgramOperation& pop) override;
    virtual AliasingResult analyze(
        DataDependenceGraph& ddg, const ProgramOperation& pop1, 
        const ProgramOperation& pop2, MoveNodeUse::BBRelation bbInfo) override;
    
    ~FalseAliasAnalyzer();

private:
    bool isEnabled(const DataDependenceGraph& ddg) const;
    FunctionNameList* funcs_;
};

#endif
