//----------------------------------------------------------------------
//   Copyright 2010 Mentor Graphics Corporation
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
//----------------------------------------------------------------------
  
class uvm_type_utils #(type TYPE=int);  
  static function string typename(TYPE val);
    `ifdef UVM_USE_TYPENAME
       `ifdef UVM_EXTRA_TYPENAME_ARG
          return $typename(val,39);
       `else
          return $typename(val);
       `endif
    `else
      `ifdef INCA
         string r;
         $uvm_type_name(r,val);
         return r;
      `else
         return "<unknown_typename>";
       `endif
    `endif
  endfunction
endclass

