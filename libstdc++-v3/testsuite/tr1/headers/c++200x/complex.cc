// { dg-options "-std=gnu++11" }
// { dg-do compile { target c++11 } }

// Copyright (C) 2011-2025 Free Software Foundation, Inc.
//
// This file is part of the GNU ISO C++ Library.  This library is free
// software; you can redistribute it and/or modify it under the
// terms of the GNU General Public License as published by the
// Free Software Foundation; either version 3, or (at your option)
// any later version.

// This library is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License along
// with this library; see the file COPYING3.  If not see
// <http://www.gnu.org/licenses/>.

// check for duplicates of complex overloads of acos, asin, atan and fabs

#include <complex>
using std::fabs;
#include <tr1/cmath>
#include <tr1/complex>

auto c = std::tr1::fabs(std::complex<double>{});
