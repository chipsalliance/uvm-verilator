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


#include "target.h"

void target::b_transport(my_payload &gp, 
                         sc_core::sc_time &delay)
{
   wait(2,SC_NS); //consume some delay
   
   cout << "SC Target Received Transaction..."<<endl;
   cout << "Addr:" << gp.addr << " Data:" << gp.data <<endl;
   
   gp.response = 1;
}
