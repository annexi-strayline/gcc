#!/usr/bin/env python3

# Copyright (C) 2024-2025 Free Software Foundation, Inc.
#
# This file is part of GCC.
#
# GCC is free software; you can redistribute it and/or modify it under
# the terms of the GNU General Public License as published by the Free
# Software Foundation; either version 3, or (at your option) any later
# version.
#
# GCC is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or
# FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# for more details.
#
# You should have received a copy of the GNU General Public License
# along with GCC; see the file COPYING3.  If not see
# <http://www.gnu.org/licenses/>.

# Unfortunately the SARIF 2.1.0 spec doesn't have memorable anchors
# for its subsections
# (filed as https://github.com/oasis-tcs/sarif-spec/issues/533)
#
# In the meantime, use this script to generate a table mapping subsections
# to anchors.

from pprint import pprint
import re

spec_url = 'https://docs.oasis-open.org/sarif/sarif/v2.1.0/errata01/os/sarif-v2.1.0-errata01-os-complete.html'
filename_in = 'sarif-v2.1.0-errata01-os-complete.html'

d = {}
with open(filename_in, encoding='windows-1252') as infile:
    for line in infile:
        m = re.match(r'<p class=MsoToc[0-9]+><a href="#(.*)">(.*)<span.*\n', line)
        if m:
            #print('MATCH')
            #print(repr(line))
            #print(m.groups())
            m2 = re.match(r'([0-9.]+) .*', m.group(2))
            if m2:
                #print(m2.groups())
                d[m2.group(1)] = m.group(1)

filename_out = '../gcc/sarif-spec-urls.def'
with open(filename_out, 'w') as outfile:
    outfile.write('/* Generated by regenerate-sarif-spec-index.py.  */\n\n')

    outfile.write(f'static const char * const sarif_spec_base_url\n  = "{spec_url}";\n\n')

    outfile.write('static const struct ref_anchor\n'
                  '{\n'
                  '  const char *m_ref;\n'
                  '  const char *m_anchor;\n'
                  '} sarif_spec_anchor_arr[] = {\n');
    for ref, anchor in d.items():
        outfile.write(f'  {{ "{ref}", "{anchor}" }},\n')
    outfile.write('};')
