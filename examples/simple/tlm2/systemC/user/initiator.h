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

#ifndef __INITIATOR_H_
#define __INITIATOR_H_

#include <systemc.h>
#include "tlm.h"
#include "payload.h"

class initiator: public sc_module
            , public tlm::tlm_bw_transport_if<my_payload_types>
{
public:
   tlm::tlm_initiator_socket<32,my_payload_types> initiator_socket;

   SC_CTOR(initiator): initiator_socket("initiator_socket")
   {
      initiator_socket.bind(*this);
      SC_THREAD(main);
   }

   void main();

   // Dummy implementations required for interface
   virtual tlm::tlm_sync_enum nb_transport_bw(
                        my_payload_types::tlm_payload_type& trans,
                        my_payload_types::tlm_phase_type& phase,
                        sc_core::sc_time& t){
      return tlm::TLM_COMPLETED;
   }

   virtual void invalidate_direct_mem_ptr(sc_dt::uint64,sc_dt::uint64)
   {
      // do nothing
   }

}; 

#endif
