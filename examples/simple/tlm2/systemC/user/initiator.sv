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


class initiator extends uvm_component;
   `uvm_component_utils(initiator);

   uvm_tlm_b_initiator_socket #(payload) socket;
   local bit done;

   function new(string name, uvm_component parent);
      super.new(name,parent);
      socket = new("initiator_socket",this);
      done = 0;
   endfunction

   task run_phase(uvm_phase phase);
      payload trans; 
      int i;
      uvm_tlm_time delay = new;
      int fail = 0;
      
      for(i = 0; i< 5; i++)
      begin
         trans = new();
         trans.addr = 400 + i;
         trans.data = 100 + i;
         trans.response = 0;

         $display("SV Initiator Sends Transaction...");
         $display("Addr: %d , Data: %d ", trans.addr, trans.data);

         socket.b_transport(trans, delay);
         if(trans.response ==  0) begin
            $display("RESPONSE FAILED for transaction %d !!!",i);
            fail++;
         end
      end
      
      if(fail == 0)
         $display("SV --> SC transactions sucessful");

      done = 1;
   endtask
endclass
