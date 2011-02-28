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


`include "uvm_macros.svh"
`include "payload.sv"


class target extends uvm_component;
   `uvm_component_utils(target);
   uvm_tlm_b_target_socket #(target, payload) socket;   

   function new(string name, uvm_component parent);
      super.new(name, parent);
      socket = new("target_socket",this,this);
   endfunction
   
   task b_transport(payload t, uvm_tlm_time delay);
      #5;
      $display("SV Target Executed Transaction...");
      $display("Addr: %d , Data: %d ", t.addr, t.data);
      t.response = 1;
   endtask

endclass
