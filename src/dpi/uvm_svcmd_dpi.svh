//
//------------------------------------------------------------------------------
//   Copyright 2011 Mentor Graphics Corporation
//   Copyright 2011 Cadence Design Systems, Inc. 
//   Copyright 2011 Synopsys, Inc.
//   All Rights Reserved Worldwide
//
//   Licensed under the Apache License, Version 2.0 (the
//   "License"); you may not use this file except in
//   compliance with the License.  You may obtain a copy of
//   the License at
//
//       http://www.apache.org/licenses/LICENSE-2.0
//
//   Unless required by applicable law or agreed to in
//   writing, software distributed under the License is
//   distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
//   CONDITIONS OF ANY KIND, either express or implied.  See
//   the License for the specific language governing
//   permissions and limitations under the License.
//------------------------------------------------------------------------------

// Import DPI functions used by the interface to generate the
// lists.

`ifndef UVM_CMDLINE_NO_DPI
import "DPI-C" function string dpi_get_next_arg_c ();
import "DPI-C" function string dpi_get_tool_name_c ();
import "DPI-C" function string dpi_get_tool_version_c ();

function string dpi_get_next_arg();
  return dpi_get_next_arg_c();
endfunction

function string dpi_get_tool_name();
  return dpi_get_tool_name_c();
endfunction

function string dpi_get_tool_version();
  return dpi_get_tool_version_c();
endfunction

import "DPI-C" function chandle dpi_regcomp(string regex);
import "DPI-C" function int dpi_regexec(chandle preg, string str);
import "DPI-C" function void dpi_regfree(chandle preg);

`else
function string dpi_get_next_arg();
  return "";
endfunction

function string dpi_get_tool_name();
  return "?";
endfunction

function string dpi_get_tool_version();
  return "?";
endfunction

`endif
