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


#include "initiator.h"

void initiator::main() {

   my_payload* trans;
   sc_time delay = sc_time(10, SC_NS);
   int fail = 0;

   // Generate a random sequence of reads and writes
   for (int i = 0; i < 5; i++)
   {
      trans = new my_payload; 
      trans->addr =i;
      trans->data = i+10;
      
      cout << "SC Initiator Sending Transaction..."<<endl;
      cout << "Addr:" << trans->addr << " Data:" << trans->data <<endl; 

      initiator_socket->b_transport( *trans, delay );
      
      // Initiator obliged to check response status and delay
      if ( trans->response != 1 ){
         fail++;
         SC_REPORT_ERROR("TLM-2", "Response error from b_transport");
      }

      // Realize the delay annotated onto the transport call
      wait(delay);
    }

    if (fail == 0)
       cout << "SC -> SV transactions succesful" <<endl;
}
