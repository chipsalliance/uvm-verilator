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


#ifndef MY_PAYLOAD_TYPES_
#define MY_PAYLOAD_TYPES_

#include "tlm.h"

// User-defined protocol traits class
class my_payload
{
public:
   unsigned int data;
   unsigned int addr;
   bool         response;	

   // User defined payload requires the dummy implementation for
   // the following three functions
   void acquire(){};
   void release(){};
   void reset(){};
};


// This structure is necessary to use TLM2.0 interface with other payloads
struct my_payload_types
{
   // define the user payload with tlm_payload_type (according to TLM2.0)
   typedef my_payload      tlm_payload_type;

   // define the type of phase with tlm_phase_type (according to TLM2.0)
   // Here phase type is from TLM2.0
   typedef tlm::tlm_phase  tlm_phase_type;
};

#endif
