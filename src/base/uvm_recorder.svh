//
//-----------------------------------------------------------------------------
//   Copyright 2007-2011 Mentor Graphics Corporation
//   Copyright 2007-2011 Cadence Design Systems, Inc.
//   Copyright 2010 Synopsys, Inc.
//   All Rights Reserved Worldwide
//
//   Licensed under the Apache License, Version 2.0 (the
//   "License"); you may not use this file except in
//   compliance with the License.  You may obtain a copy of
//   the License at
//
//       http://www.apache.org/licenses/LICENSE-2.0
//
//   Unless required by applicable law or agreed to in
//   writing, software distributed under the License is
//   distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
//   CONDITIONS OF ANY KIND, either express or implied.  See
//   the License for the specific language governing
//   permissions and limitations under the License.
//-----------------------------------------------------------------------------

typedef class uvm_object_registry; 

//------------------------------------------------------------------------------
//
// CLASS: uvm_recorder
//
// The uvm_recorder class provides a policy object for recording <uvm_objects>.
// The policies determine how recording should be done. 
//
// A default recorder instance, <uvm_default_recorder>, is used when the
// <uvm_object::record> is called without specifying a recorder.
//
//------------------------------------------------------------------------------

class uvm_recorder extends uvm_object;

  `uvm_object_utils(uvm_recorder)

  int recording_depth = 0; 
  UVM_FILE file;
  string filename = "tr_db.log";


  // Variable: tr_handle
  //
  // This is an integral handle to a transaction object. Its use is vendor
  // specific. 
  //
  // A handle of 0 indicates there is no active transaction object. 

  integer tr_handle = 0;


  // Variable: default_radix
  //
  // This is the default radix setting if <record_field> is called without
  // a radix.

  uvm_radix_enum default_radix = UVM_HEX;


  // Variable: physical
  //
  // This bit provides a filtering mechanism for fields. 
  //
  // The <abstract> and physical settings allow an object to distinguish between
  // two different classes of fields. 
  //
  // It is up to you, in the <uvm_object::do_record> method, to test the
  // setting of this field if you want to use the physical trait as a filter.

  bit physical = 1;


  // Variable: abstract
  //
  // This bit provides a filtering mechanism for fields. 
  //
  // The abstract and physical settings allow an object to distinguish between
  // two different classes of fields. 
  //
  // It is up to you, in the <uvm_object::do_record> method, to test the
  // setting of this field if you want to use the abstract trait as a filter.

  bit abstract = 1;


  // Variable: identifier
  //
  // This bit is used to specify whether or not an object's reference should be
  // recorded when the object is recorded. 

  bit identifier = 1;


  // Variable: recursion_policy
  //
  // Sets the recursion policy for recording objects. 
  //
  // The default policy is deep (which means to recurse an object).

  uvm_recursion_policy_enum policy = UVM_DEFAULT_POLICY;


  // Function: get_type_name
  //
  // Returns type name of the recorder. Subtypes must override this method
  // to enable the <`uvm_record_field> macro.
  //
  //| virtual function string get_type_name()



  // Function: record_field
  //
  // Records an integral field (less than or equal to 4096 bits). ~name~ is the
  // name of the field. 
  //
  // ~value~ is the value of the field to record. ~size~ is the number of bits
  // of the field which apply. ~radix~ is the <uvm_radix_enum> to use.

  virtual function void record_field (string name, 
                                      uvm_bitstream_t value, 
                                      int size, 
                                      uvm_radix_enum  radix=UVM_NORADIX);
    if(tr_handle==0) return;
    scope.set_arg(name);

    if(!radix)
      radix = default_radix;

    set_attribute(tr_handle, scope.get(), value, radix, size);

  endfunction


  // Function: record_field_real
  //
  // Records an real field. ~value~ is the value of the field to record. 

  virtual function void record_field_real (string name, 
                                           real value);
    bit[63:0] ival = $realtobits(value);
    if(tr_handle==0) return;
    scope.set_arg(name);
    set_attribute(tr_handle, scope.get(), ival, UVM_REAL, 64);
  endfunction


  // Function: record_object
  //
  // Records an object field. ~name~ is the name of the recorded field. 
  //
  // This method uses the <recursion_policy> to determine whether or not to
  // recurse into the object.

  virtual function void record_object (string name, uvm_object value);
     int v;
    string str; 

    if(identifier) begin 
      if(value != null) begin
        $swrite(str, "%0d", value.get_inst_id());
        v = str.atoi(); 
      end
      scope.set_arg(name);
      set_attribute(tr_handle, scope.get(), v, UVM_DEC, 32);
    end
 
    if(policy != UVM_REFERENCE) begin
      if(value!=null) begin
        if(value.__m_uvm_status_container.cycle_check.exists(value)) return;
        value.__m_uvm_status_container.cycle_check[value] = 1;
        scope.down(name);
        value.record(this);
        scope.up();
        value.__m_uvm_status_container.cycle_check.delete(value);
      end
    end

  endfunction


  // Function: record_string
  //
  // Records a string field. ~name~ is the name of the recorded field.
  
  virtual function void record_string (string name, string value);
    scope.set_arg(name);
    set_attribute(tr_handle, scope.get(), uvm_string_to_bits(value),
                   UVM_STRING, 8*value.len());
  endfunction


  // Function: record_time
  //
  // Records a time value. ~name~ is the name to record to the database.
  
  
  virtual function void record_time (string name, time value); 
    scope.set_arg(name);
    set_attribute(tr_handle, scope.get(), value, UVM_TIME, 64);
  endfunction


  // Function: record_generic
  //
  // Records the ~name~-~value~ pair, where ~value~ has been converted
  // to a string. For example:
  //
  //| recorder.record_generic("myvar",$sformatf("%0d",myvar));
  
  virtual function void record_generic (string name, string value);
    scope.set_arg(name);
    set_attribute(tr_handle, scope.get(), uvm_string_to_bits(value),
                   UVM_STRING, 8*value.len());
  endfunction


  uvm_scope_stack scope = new;



  //------------------------------
  // Group- Vendor-Independent API
  //------------------------------


  // UVM provides only a text-based default implementation.
  // Vendors provide subtype implementations and overwrite the
  // <uvm_default_recorder> handle.


  // Function- open_file
  //
  // Opens the file in the <filename> property and assigns to the
  // file descriptor <file>.
  //
  function bit open_file();
    if (file == 0)
      file = $fopen(filename);
    return (file > 0);
  endfunction


  // Function- create_stream
  //
  //
  function integer create_stream (string name,
                                 string t,
                                 string scope);
    return 0;
  endfunction

   
  // Function- m_set_attribute
  //
  //
  function void m_set_attribute (integer txh,
                                 string nm,
                                 string value);
    if (open_file())
      $fdisplay(file,"  SET_ATTR: {TXH:%-5d NAME:%s VALUE:%s}", txh,nm,value);
  endfunction
  
  
  // Function- set_attribute
  //
  //
  function void set_attribute (integer txh,
                               string nm,
                               logic [1023:0] value,
                               uvm_radix_enum radix,
                               integer numbits=1024);
    string rdx=uvm_radix_to_string(radix);
    if (open_file())
      $fdisplay(file,"  SET_ATTR: {TXH:%-5d NAME:%s VALUE:%0d RADIX:%s BITS=%-5d}",
                 txh, nm, (value & ((1<<numbits)-1)),radix.name(),numbits);
  endfunction
  
  
  // Function- check_handle_kind
  //
  //
  function integer check_handle_kind (string htype, integer handle);
    return 1;
  endfunction
  
  
  // Function- begin_tr
  //
  //
  function integer begin_tr(string txtype,
                                     integer stream,
                                     string nm,
                                     string label="",
                                     string desc="",
                                     time begin_time=0);
    static int h = 1;
    if (open_file()) begin
      h++;
      $fdisplay(file,"BEGIN: {TXH:%-5d TYPE:\"%0s\" STREAM:%-5d NAME:%s TIME=%0t LABEL:\"%0s\" DESC=\"%0s\"",
        h,txtype,stream,nm,begin_time,label,desc);
      return h;
    end
    return -1;
  endfunction
  
  
  // Function- end_tr
  //
  //
  function void end_tr (integer handle, time end_time=0);
    if (open_file())
      $fdisplay(file,"END: {TXH:%-5d TIME=%0t}",handle,end_time);
  endfunction
  
  
  // Function- link_tr
  //
  //
  function void link_tr(integer h1,
                                 integer h2,
                                 string relation="");
    if (open_file())
      $fdisplay(file,"  LINK: {TXH1:%-5d TXH2:%-5d RELATION=%0s}", h1,h2,relation);
  endfunction
  
  
  
  // Function- free_tr
  //
  //
  function void free_tr(integer handle);
    if (open_file())
      $fdisplay(file,"  FREE: {TXH:%-5d}", handle);
  endfunction
  

endclass
  
  
  
