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

class test extends uvm_component;
   `uvm_component_utils(test)

   function new(string name, uvm_component parent = null);
      super.new(name, parent);
   endfunction

  function void end_of_elaboration_phase(uvm_phase phase);
     // Set verbosity for  demo
     set_report_verbosity_level(UVM_FULL);
     begin
        uvm_root top = uvm_root::get();
        top.print_topology();
     end
  endfunction : end_of_elaboration_phase

   task run_phase(uvm_phase phase);
      phase.raise_objection(this);
      #100;
      phase.drop_objection(this);
   endtask // run_phase
   
endclass
