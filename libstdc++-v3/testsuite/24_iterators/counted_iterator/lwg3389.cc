// Copyright (C) 2020-2025 Free Software Foundation, Inc.
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

// { dg-do compile { target c++20 } }

#include <iterator>

#include <testsuite_iterators.h>

using __gnu_test::test_range;
using __gnu_test::input_iterator_wrapper_nocopy;

// LWG 3389
void
test01()
{
  int x[] = {1,2,3,4};
  test_range<int, input_iterator_wrapper_nocopy> rx(x);
  auto it = std::counted_iterator(rx.begin(), 2);
}
