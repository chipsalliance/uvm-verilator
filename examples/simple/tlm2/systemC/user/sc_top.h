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


#ifndef TOP__H__
#define TOP__H__

#include <systemc.h>
#include "target.h"
#include "initiator.h"
#include "uvm_tlm2_sc_bind.h"

class sc_top : public sc_module
{
public:
   initiator  init1;
   target     trgt0;

   SC_CTOR(sc_top) : trgt0("trgt0")
                      ,init1("init1") 
   {
      uvm_tlm2_bind_sc_target(trgt0.target_socket,UVM_TLM_B,"port0");
      uvm_tlm2_bind_sc_initiator(init1.initiator_socket,UVM_TLM_B,"port1");

   }

};
#endif
