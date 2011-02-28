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


#ifndef __CONSUMER__H__
#define __CONSUMER__H__

#include <systemc.h>
#include "tlm.h"
#include "payload.h"

class target : public sc_module
      ,public tlm::tlm_fw_transport_if<my_payload_types> 
{
public:
   tlm::tlm_target_socket<32,my_payload_types> target_socket;

   SC_CTOR(target) : target_socket("target_socket")
   {
      target_socket.bind(*this);
   }

   void b_transport(my_payload &gp, sc_core::sc_time &delay);

   // Dummy implementations required for the interface
   virtual tlm::tlm_sync_enum nb_transport_fw(my_payload&,
                        tlm::tlm_phase&, sc_core::sc_time&t)
   {
      return tlm::TLM_COMPLETED;
   }

   virtual bool get_direct_mem_ptr(my_payload&, tlm::tlm_dmi&)
   {
      return false;
   }

   virtual unsigned int transport_dbg(my_payload&)
   {
   }

};
#endif
