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
 * @file Options.hh
 *
 * Declaration of Options class.
 *
 * @author Jari M�ntyneva 2005 (jari.mantyneva-no.spam-tut.fi)
 * @note rating: red
 */

#ifndef TTA_OPTIONS_HH
#define TTA_OPTIONS_HH

#include <string>
#include <map>
#include <vector>

#include "Exception.hh"

class OptionValue;

using std::map;
using std::string;
using std::vector;

/**
 * Generic container of option values.
 */
class Options {
public:
    Options();
    virtual ~Options();
    void addOptionValue(const string& name, OptionValue* option)
	throw (TypeMismatch);

    // index for lists of options
    OptionValue& optionValue(const string& name, int index = 0)
	throw (OutOfRange, KeyNotFound);
    int valueCount(const string& name)
	throw (KeyNotFound);

private:
    map<string, vector<OptionValue*> > options_;
};

#endif
