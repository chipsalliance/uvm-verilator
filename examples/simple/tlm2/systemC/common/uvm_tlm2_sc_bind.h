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


#ifndef _UVM_INTERFACE_BASE_H_
#define _UVM_INTERFACE_BASE_H_

#include <systemc>
#include "tlm.h"

enum uvm_tlm_socket_typ {UVM_TLM_B, UVM_TLM_NB};

// This is called when SC has target socket
template<
   unsigned int BUSWIDTH,
   typename TYPES,
   int N,
   sc_core::sc_port_policy POL
   >
void uvm_tlm2_bind_sc_target(
    tlm::tlm_target_socket<BUSWIDTH,TYPES,N,POL>& tgt,
    uvm_tlm_socket_typ type, 
    std::string uniq_id)
{
    cout << "Error: Vendor implementation for uvm_tlm2_bind_sc_target is needed." << endl;

    return;
}


// This is called when SC has initiator socket
template<
   unsigned int BUSWIDTH,
   typename TYPES,
   int N,
   sc_core::sc_port_policy POL
   >
void uvm_tlm2_bind_sc_initiator(
    tlm::tlm_initiator_socket<BUSWIDTH,TYPES,N,POL>& init,
    uvm_tlm_socket_typ type, 
    std::string uniq_id)
{
    cout << "Error: Vendor implementation for uvm_tlm2_bind_sc_initiator is needed." << endl;

    return;
}


// This is called when SC is analysis port 
template< typename TRANS >
void uvm_tlm2_bind_sc_analysis_port(
    tlm::tlm_analysis_port<TRANS>& conn,
    std::string uniq_id)
{
    cout << "Error: Vendor implementation for uvm_tlm2_bind_sc_analysis_port is needed." << endl;

    return;
}


// This is called when SC is analysis export (subscriber)
template< typename TRANS >
void uvm_tlm2_bind_sc_analysis_export(
    tlm::tlm_analysis_if<TRANS>& conn,
    std::string uniq_id)
{
    cout << "Error: Vendor implementation for uvm_tlm2_bind_sc_analysis_export is needed." << endl;

    return;
}

#endif
