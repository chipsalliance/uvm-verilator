// 
// -------------------------------------------------------------
//    Copyright 2010-2011 Synopsys, Inc.
//    All Rights Reserved Worldwide
// 
//    Licensed under the Apache License, Version 2.0 (the
//    "License"); you may not use this file except in
//    compliance with the License.  You may obtain a copy of
//    the License at
// 
//        http://www.apache.org/licenses/LICENSE-2.0
// 
//    Unless required by applicable law or agreed to in
//    writing, software distributed under the License is
//    distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
//    CONDITIONS OF ANY KIND, either express or implied.  See
//    the License for the specific language governing
//    permissions and limitations under the License.
// -------------------------------------------------------------
// 


`include "uvm_tlm2_sv_bind.svh"

module top;

import uvm_pkg::*;
import uvm_tlm2_sv_bind_pkg::*;

`include "tb_env.sv"
`include "test.sv"

   // SystemC models
   sc_top design();  

   initial begin
      tb_env env = new("env");
      run_test("test");
   end

endmodule

