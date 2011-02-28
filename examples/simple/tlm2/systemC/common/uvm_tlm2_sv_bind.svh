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


`ifndef UVM_TLM2_SV_BIND
`define UVM_TLM2_SV_BIND

package uvm_tlm2_sv_bind_pkg;

import uvm_pkg::*;

   typedef enum {UVM_TLM_B_INITIATOR,
                 UVM_TLM_B_TARGET,
                 UVM_TLM_NB_INITIATOR,
                 UVM_TLM_NB_TARGET,
                 UVM_TLM_ANALYSIS_PORT,
                 UVM_TLM_ANALYSIS_EXPORT
                 } uvm_tlm_typ_e;


class uvm_tlm2_sv_bind #(type T = uvm_tlm_gp);
   
   static function void connect(uvm_port_base #(uvm_tlm_if #(T)) tlm_intf,
                                uvm_tlm_typ_e port_type,
                                string port_name);

      `uvm_fatal("uvm_tlm2_sv_bind",
                 "Vendor implementation for uvm_tlm2_sv_bind::connect() is needed")
   endfunction
   
endclass

endpackage

`endif
