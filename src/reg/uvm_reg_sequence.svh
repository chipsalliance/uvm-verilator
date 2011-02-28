//
// -------------------------------------------------------------
//    Copyright 2004-2009 Synopsys, Inc.
//    Copyright 2010-2011 Mentor Graphics Corporation
//    Copyright 2010-2011 Cadence Design Systems, Inc.
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
 
  
//------------------------------------------------------------------------------
// TITLE: Register Sequence and Predictor Classes
//------------------------------------------------------------------------------
//
// This section defines the base classes used for register stimulus generation.
// It also defines a predictor component, which is used to update the register
// model's mirror values based on transactions observed on a physical bus. 
//------------------------------------------------------------------------------

                                                              
//------------------------------------------------------------------------------
//
// CLASS: uvm_reg_sequence
//
// This class provides base functionality for both user-defined RegModel test
// sequences and "register translation sequences".
//
// - When used as a base for user-defined RegModel test sequences, this class
//   provides convenience methods for reading and writing registers and
//   memories. Users implement the body() method to interact directly with
//   the RegModel model (held in the <model> property) or indirectly via the
//   delegation methods in this class. 
//
// - When used as a translation sequence, objects of this class are
//   executed directly on a bus sequencerwhich are used in support of a layered sequencer
//   use model, a pre-defined convert-and-execute algorithm is provided.
//
// Register operations do not require extending this class if none of the above
// services are needed. Register test sequences can be extend from the base
// <uvm_sequence #(REQ,RSP)> base class or even from outside a sequence. 
//
// Note- The convenience API not yet implemented.
//------------------------------------------------------------------------------

class uvm_reg_sequence #(type BASE=uvm_sequence #(uvm_reg_item)) extends BASE;

  `uvm_object_param_utils(uvm_reg_sequence #(BASE))

  // Parameter: BASE
  //
  // Specifies the sequence type to extend from.
  //
  // When used as a translation sequence running on a bus sequencer, ~BASE~ must
  // be compatible with the sequence type expected by the bus sequencer.
  //
  // When used as a test sequence running on a particular sequencer, ~BASE~
  // must be compatible with the sequence type expected by that sequencer.
  //
  // When used as a virtual test sequence without a sequencer, ~BASE~ does
  // not need to be specified, i.e. the default specialization is adequate.
  // 
  // To maximize opportunities for reuse, user-defined RegModel sequences should
  // "promote" the BASE parameter.
  //
  // | class my_reg_sequence #(type BASE=uvm_sequence #(uvm_reg_item))
  // |                               extends uvm_reg_sequence #(BASE);
  //
  // This way, the RegModel sequence can be extended from 
  // user-defined base sequences.


  // Variable: model
  //
  // Block abstraction this sequence executes on, defined only when this
  // sequence is a user-defined test sequence.
  //
  uvm_reg_block model;


  // Variable: adapter
  //
  // Adapter to use for translating between abstract register transactions
  // and physical bus transactions, defined only when this sequence is a
  // translation sequence.
  //
  uvm_reg_adapter adapter;


  // Variable: reg_seqr
  //
  // Layered upstream "register" sequencer.
  //
  // Specifies the upstream sequencer between abstract register transactions
  // and physical bus transactions. Defined only when this sequence is a
  // translation sequence, and we want to "pull" from an upstream sequencer.
  //
  uvm_sequencer #(uvm_reg_item) reg_seqr;


  // Function: new
  //
  // Create a new instance, giving it the optional ~name~.
  //
  function new (string name="uvm_reg_sequence_inst");
    super.new(name);
  endfunction


  // Task: body
  //
  // Continually gets a register transaction from the configured upstream
  // sequencer, <reg_seqr>, and executes the corresponding bus transaction
  // via <do_rw_access>. 
  //
  // User-defined RegModel test sequences must override body() and not call
  // super.body(), else a warning will be issued and the calling process
  // not return.
  //
  virtual task body();
    if (m_sequencer == null) begin
      `uvm_fatal("NO_SEQR", {"Sequence executing as translation sequence, ",
         "but is not associated with a sequencer (m_sequencer == null)"})
    end
    if (reg_seqr == null) begin
      `uvm_warning("REG_XLATE_NO_SEQR",
         {"Executing RegModel translation sequence on sequencer ",
       m_sequencer.get_full_name(),"' does not have an upstream sequencer defined. ",
       "Execution of register items available only via direct calls to 'do_rw_access'"})
      wait(0);
    end
    `uvm_info("REG_XLATE_SEQ_START",
       {"Starting RegModel translation sequence on sequencer ",
       m_sequencer.get_full_name(),"'"},UVM_LOW)
    forever begin
      uvm_reg_item reg_item;
      reg_seqr.peek(reg_item);
      do_reg_item(reg_item);
      reg_seqr.get(reg_item);
      #0;
    end
  endtask


  typedef enum { LOCAL, UPSTREAM } seq_parent_e;

  seq_parent_e parent_select = LOCAL;

  uvm_sequence_base upstream_parent;


  // Function: do_reg_item
  //
  // Executes the given register transaction, ~rw~, via the sequencer on
  // which this sequence was started (i.e. m_sequencer). Uses the configured
  // <adapter> to convert the register transaction into the type expected by
  // this sequencer.
  //
  virtual task do_reg_item(uvm_reg_item rw);
    assert(m_sequencer != null);
    assert(adapter != null);
    `uvm_info("DO_RW_ACCESS",{"Doing transaction: ",rw.convert2string()},UVM_HIGH)

    if (parent_select == LOCAL) begin
      upstream_parent = rw.parent;
      rw.parent = this;
    end

    if (rw.kind == UVM_WRITE)
      rw.local_map.do_bus_write(rw, m_sequencer, adapter);
    else
      rw.local_map.do_bus_read(rw, m_sequencer, adapter);
    
    if (parent_select == LOCAL)
       rw.parent = upstream_parent;
  endtask


   //----------------------------------
   // Group: Convenience Write/Read API
   //----------------------------------
   //
   // The following methods delegate to the corresponding method in the 
   // register or memory element. They allow a sequence ~body()~ to do
   // reads and writes without having to explicitly supply itself to
   // ~parent~ sequence argument. Thus, a register write
   //
   //| model.regA.write(status, value, .parent(this));
   //
   // can be written instead as
   //
   //| write_reg(model.regA, status, value);
   //


   // Task: write_reg
   //
   // Writes the given register ~rg~ using <uvm_reg::write>, supplying 'this' as
   // the ~parent~ argument. Thus,
   //
   //| write_reg(model.regA, status, value);
   //
   // is equivalent to
   //
   //| model.regA.write(status, value, .parent(this));
   //
   virtual task write_reg(input  uvm_reg           rg,
                          output uvm_status_e      status,
                          input  uvm_reg_data_t    value,
                          input  uvm_path_e        path = UVM_DEFAULT_PATH,
                          input  uvm_reg_map       map = null,
                          input  int               prior = -1,
                          input  uvm_object        extension = null,
                          input  string            fname = "",
                          input  int               lineno = 0);
      if (rg == null)
        `uvm_error("NO_REG","Register argument is null")
      else
        rg.write(status,value,path,map,this,prior,extension,fname,lineno);
   endtask


   // Task: read_reg
   //
   // Reads the given register ~rg~ using <uvm_reg::read>, supplying 'this' as
   // the ~parent~ argument. Thus,
   //
   //| read_reg(model.regA, status, value);
   //
   // is equivalent to
   //
   //| model.regA.read(status, value, .parent(this));
   //
   //
   virtual task read_reg(input  uvm_reg           rg,
                         output uvm_status_e      status,
                         output uvm_reg_data_t    value,
                         input  uvm_path_e        path = UVM_DEFAULT_PATH,
                         input  uvm_reg_map       map = null,
                         input  int               prior = -1,
                         input  uvm_object        extension = null,
                         input  string            fname = "",
                         input  int               lineno = 0);
      if (rg == null)
        `uvm_error("NO_REG","Register argument is null")
      else
        rg.read(status,value,path,map,this,prior,extension,fname,lineno);
   endtask



   // Task: poke_reg
   //
   // Pokes the given register ~rg~ using <uvm_reg::poke>, supplying 'this' as
   // the ~parent~ argument. Thus,
   //
   //| poke_reg(model.regA, status, value);
   //
   // is equivalent to
   //
   //| model.regA.poke(status, value, .parent(this));
   //
   //
   virtual task poke_reg(input  uvm_reg           rg,
                         output uvm_status_e      status,
                         input  uvm_reg_data_t    value,
                         input  string            kind = "",
                         input  uvm_object        extension = null,
                         input  string            fname = "",
                         input  int               lineno = 0);
      if (rg == null)
        `uvm_error("NO_REG","Register argument is null")
      else
        rg.poke(status,value,kind,this,extension,fname,lineno);
   endtask



   // Task: peek_reg
   //
   // Peeks the given register ~rg~ using <uvm_reg::peek>, supplying 'this' as
   // the ~parent~ argument. Thus,
   //
   //| peek_reg(model.regA, status, value);
   //
   // is equivalent to
   //
   //| model.regA.peek(status, value, .parent(this));
   //
   virtual task peek_reg(input  uvm_reg           rg,
                         output uvm_status_e      status,
                         output uvm_reg_data_t    value,
                         input  string            kind = "",
                         input  uvm_object        extension = null,
                         input  string            fname = "",
                         input  int               lineno = 0);
      if (rg == null)
        `uvm_error("NO_REG","Register argument is null")
      else
        rg.peek(status,value,kind,this,extension,fname,lineno);
   endtask

   
   
   // Task: update_reg
   //
   // Updates the given register ~rg~ using <uvm_reg::update>, supplying 'this' as
   // the ~parent~ argument. Thus,
   //
   //| update_reg(model.regA, status, value);
   //
   // is equivalent to
   //
   //| model.regA.update(status, value, .parent(this));
   //
   virtual task update_reg(input  uvm_reg           rg,
                           output uvm_status_e      status,
                           input  uvm_path_e        path = UVM_DEFAULT_PATH,
                           input  uvm_reg_map       map = null,
                           input  int               prior = -1,
                           input  uvm_object        extension = null,
                           input  string            fname = "",
                           input  int               lineno = 0);
      if (rg == null)
        `uvm_error("NO_REG","Register argument is null")
      else
        rg.update(status,path,map,this,prior,extension,fname,lineno);
   endtask



   // Task: mirror_reg
   //
   // Mirrors the given register ~rg~ using <uvm_reg::mirror>, supplying 'this' as
   // the ~parent~ argument. Thus,
   //
   //| mirror_reg(model.regA, status, UVM_CHECK);
   //
   // is equivalent to
   //
   //| model.regA.mirror(status, UVM_CHECK, .parent(this));
   //
   virtual task mirror_reg(input  uvm_reg       rg,
                           output uvm_status_e  status,
                           input  uvm_check_e   check  = UVM_NO_CHECK,
                           input  uvm_path_e    path = UVM_DEFAULT_PATH,
                           input  uvm_reg_map   map = null,
                           input  int           prior = -1,
                           input  uvm_object    extension = null,
                           input  string        fname = "",
                           input  int           lineno = 0);
      if (rg == null)
        `uvm_error("NO_REG","Register argument is null")
      else
        rg.mirror(status,check,path,map,this,prior,extension,fname,lineno);
   endtask

  

   // Task: write_mem
   //
   // Writes the given memory ~mem~ using <uvm_mem::write>, supplying 'this' as
   // the ~parent~ argument. Thus,
   //
   //| write_mem(model.regA, status, offset, value);
   //
   // is equivalent to
   //
   //| model.regA.write(status, offset, value, .parent(this));
   //
   virtual task write_mem(input  uvm_mem           mem,
                          output uvm_status_e      status,
                          input  uvm_reg_addr_t    offset,
                          input  uvm_reg_data_t    value,
                          input  uvm_path_e        path = UVM_DEFAULT_PATH,
                          input  uvm_reg_map       map = null,
                          input  int               prior = -1,
                          input  uvm_object        extension = null,
                          input  string            fname = "",
                          input  int               lineno = 0);
      if (mem == null)
        `uvm_error("NO_MEM","Memory argument is null")
      else
        mem.write(status,offset,value,path,map,this,prior,extension,fname,lineno);
   endtask


   // Task: read_mem
   //
   // Reads the given memory ~mem~ using <uvm_mem::read>, supplying 'this' as
   // the ~parent~ argument. Thus,
   //
   //| read_mem(model.regA, status, offset, value);
   //
   // is equivalent to
   //
   //| model.regA.read(status, offset, value, .parent(this));
   //
   //
   virtual task read_mem(input  uvm_mem           mem,
                         output uvm_status_e      status,
                         input  uvm_reg_addr_t    offset,
                         output uvm_reg_data_t    value,
                         input  uvm_path_e        path = UVM_DEFAULT_PATH,
                         input  uvm_reg_map       map = null,
                         input  int               prior = -1,
                         input  uvm_object        extension = null,
                         input  string            fname = "",
                         input  int               lineno = 0);
      if (mem == null)
        `uvm_error("NO_MEM","Memory argument is null")
      else
        mem.read(status,offset,value,path,map,this,prior,extension,fname,lineno);
   endtask



   // Task: poke_mem
   //
   // Pokes the given memory ~mem~ using <uvm_mem::poke>, supplying 'this' as
   // the ~parent~ argument. Thus,
   //
   //| poke_mem(model.regA, status, offset, value);
   //
   // is equivalent to
   //
   //| model.regA.poke(status, offset, value, .parent(this));
   //
   //
   virtual task poke_mem(input  uvm_mem           mem,
                         output uvm_status_e      status,
                         input  uvm_reg_addr_t    offset,
                         input  uvm_reg_data_t    value,
                         input  string            kind = "",
                         input  uvm_object        extension = null,
                         input  string            fname = "",
                         input  int               lineno = 0);
      if (mem == null)
        `uvm_error("NO_MEM","Memory argument is null")
      else
        mem.poke(status,offset,value,kind,this,extension,fname,lineno);
   endtask



   // Task: peek_mem
   //
   // Peeks the given memory ~mem~ using <uvm_mem::peek>, supplying 'this' as
   // the ~parent~ argument. Thus,
   //
   //| peek_mem(model.regA, status, offset, value);
   //
   // is equivalent to
   //
   //| model.regA.peek(status, offset, value, .parent(this));
   //
   virtual task peek_mem(input  uvm_mem           mem,
                         output uvm_status_e      status,
                         input  uvm_reg_addr_t    offset,
                         output uvm_reg_data_t    value,
                         input  string            kind = "",
                         input  uvm_object        extension = null,
                         input  string            fname = "",
                         input  int               lineno = 0);
      if (mem == null)
        `uvm_error("NO_MEM","Memory argument is null")
      else
        mem.peek(status,offset,value,kind,this,extension,fname,lineno);
   endtask

   
  // Function- put_response
  //
  // not user visible. Needed to populate this sequence's response
  // queue with any bus item type. 
  //
  virtual function void put_response(uvm_sequence_item response_item);
    put_base_response(response_item);
  endfunction

endclass


//------------------------------------------------------------------------------
// Class: uvm_reg_frontdoor
//
// Facade class for register and memory frontdoor access.
//------------------------------------------------------------------------------
//
// User-defined frontdoor access sequence
//
// Base class for user-defined access to register and memory reads and writes
// through a physical interface.
//
// By default, different registers and memories are mapped to different
// addresses in the address space and are accessed via those exclusively
// through physical addresses.
//
// The frontdoor allows access using a non-linear and/or non-mapped mechanism.
// Users can extend this class to provide the physical access to these registers.
//
virtual class uvm_reg_frontdoor extends uvm_reg_sequence #(uvm_sequence #(uvm_sequence_item));

   // Variable: rw_info
   //
   // Holds information about the register being read or written
   //
   uvm_reg_item rw_info;

   // Variable: sequencer
   //
   // Sequencer executing the operation
   //
   uvm_sequencer_base sequencer;

   // Function: new
   //
   // Constructor, new object givne optional ~name~.
   //
   function new(string name="");
      super.new(name);
   endfunction

   string fname;
   int lineno;

endclass: uvm_reg_frontdoor



class uvm_predict_s;
   bit addr[uvm_reg_addr_t];
   uvm_reg_item reg_item;
endclass


//------------------------------------------------------------------------------
//
// CLASS: uvm_reg_predictor
//
// Updates the register model mirror based on observed bus transactions
//
// This class converts observed bus transactions of type ~BUSTYPE~ to generic
// registers transactions, determines the register being accessed based on the
// bus address, then updates the register's mirror value with the observed bus
// data, subject to the register's access mode. See <uvm_reg::predict> for details.
//
// Memories can be large, so their accesses are not predicted. Users can
// periodically use backdoor peek/poke to update the memory mirror.
//
//------------------------------------------------------------------------------

class uvm_reg_predictor #(type BUSTYPE=int) extends uvm_component;

  `uvm_component_param_utils(uvm_reg_predictor#(BUSTYPE))
  //`uvm_register_cb(uvm_reg_predictor #(BUSTYPE), uvm_reg_cbs)

  // Variable: bus_in
  //
  // Observed bus transactions of type ~BUSTYPE~ are received from this
  // port and processed.
  //
  // For each incoming transaction, the predictor will attempt to get the
  // register or memory handle corresponding to the observed bus address. 
  //
  // If there is a match, the predictor calls the register or memory's
  // predict method, passing in the observed bus data. The register or
  // memory mirror will be updated with this data, subject to its configured
  // access behavior--RW, RO, WO, etc. The predictor will also convert the
  // bus transaction to a generic <uvm_reg_item> and send it out the
  // ~reg_ap~ analysis port.
  //
  // If the register is wider than the bus, the
  // predictor will collect the multiple bus transactions needed to
  // determine the value being read or written.
  //
  uvm_analysis_imp #(BUSTYPE, uvm_reg_predictor #(BUSTYPE)) bus_in;


  // Variable: reg_ap
  //
  // Analysis output port that publishes <uvm_reg_item> transactions
  // converted from bus transactions received on ~bus_in~.
  uvm_analysis_port #(uvm_reg_item) reg_ap;


  // Variable: map
  //
  // The map used to convert a bus address to the corresponding register
  // or memory handle. Must be configured before the run phase.
  // 
  uvm_reg_map map;


  // Variable: adapter
  //
  // The adapter used to convey the parameters of a bus operation in 
  // terms of a canonical <uvm_reg_bus_op> datum.
  // The ~adapter~ must be configured before the run phase.
  //
  uvm_reg_adapter adapter;


  // Function: new
  //
  // Create a new instance of this type, giving it the optional ~name~
  // and ~parent~.
  //
  function new (string name, uvm_component parent);
    super.new(name, parent);
    bus_in = new("bus_in", this);
    reg_ap = new("reg_ap", this);
  endfunction


  // Function: pre_predict
  //
  // Override this method to change the value or re-direct the
  // target register
  //
  virtual function void pre_predict(uvm_reg_item rw);
  endfunction

  local uvm_predict_s m_pending[uvm_reg];


  // Function- write
  //
  // not a user-level method. Do not call directly. See documentation
  // for the ~bus_in~ member.
  //
  virtual function void write(BUSTYPE tr);
     uvm_reg rg;
     uvm_reg_bus_op rw;
     assert(adapter != null);

     // In case they forget to set byte_en
     rw.byte_en = -1;
     adapter.bus2reg(tr,rw);
     rg = map.get_reg_by_offset(rw.addr, (rw.kind == UVM_READ));

     // ToDo: Add memory look-up and call uvm_mem::XsampleX()

     if (rg != null) begin
       bit found;
       uvm_reg_item reg_item;
       uvm_reg_map local_map;
       uvm_reg_map_info map_info;
       uvm_predict_s predict_info;
 
       if (!m_pending.exists(rg)) begin
         uvm_reg_item item = new;
         predict_info =new;
         item.element_kind = UVM_REG;
         item.element      = rg;
         item.path         = UVM_PREDICT;
         item.map          = map;
         item.kind         = rw.kind;
         predict_info.reg_item = item;
         m_pending[rg] = predict_info;
       end
       predict_info = m_pending[rg];
       reg_item = predict_info.reg_item;

       if (predict_info.addr.exists(rw.addr)) begin
          `uvm_error("REG_PREDICT_COLLISION",{"Collision detected for register '",
                     rg.get_full_name(),"'"})
          // TODO: what to do with subsequent collisions?
          m_pending.delete(rg);
       end

       local_map = rg.get_local_map(map,"predictor::write()");
       map_info = local_map.get_reg_map_info(rg);

       foreach (map_info.addr[i]) begin
         if (rw.addr == map_info.addr[i]) begin
            found = 1;
           reg_item.value[0] |= rw.data << (i * map.get_n_bytes()*8);
           predict_info.addr[rw.addr] = 1;
           if (predict_info.addr.num() == map_info.addr.size()) begin
              // We've captured the entire abstract register transaction.
              uvm_predict_e predict_kind = 
                  (reg_item.kind == UVM_WRITE) ? UVM_PREDICT_WRITE : UVM_PREDICT_READ;
              pre_predict(reg_item);

              rg.XsampleX(reg_item.value[0], rw.byte_en,
                          reg_item.kind == UVM_READ, local_map);
              begin
                 uvm_reg_block blk = rg.get_parent();
                 blk.XsampleX(map_info.offset,
                              reg_item.kind == UVM_READ,
                              local_map);
              end

              `uvm_info("REG_PREDICT", {"Observed ",reg_item.kind.name(),
                        " transaction to register ",rg.get_full_name(), ": value='h",
                         $sformatf("%0h",reg_item.value[0])},UVM_HIGH)
              rg.do_predict(reg_item, predict_kind, rw.byte_en);
              reg_ap.write(reg_item);
              m_pending.delete(rg);
           end
           break;
         end
       end
       if (!found)
         `uvm_error("REG_PREDICT_INTERNAL",{"Unexpected failed address lookup for register '",
                  rg.get_full_name(),"'"})
     end
     else begin
       `uvm_info("REG_PREDICT_NOT_FOR_ME",
          {"Observed transaction does not target a register: ",
            $sformatf("%p",tr)},UVM_FULL)
     end
  endfunction

  
  // Function: check_phase
  //
  // Checks that no pending register transactions are still enqueued.

  virtual function void check_phase(uvm_phase phase);
     super.check_phase(phase);
    if (m_pending.num() > 0) begin
      `uvm_error("PENDING REG ITEMS",{"There are ",$sformatf("%0d",m_pending.num()),
                 " incomplete register transactions still pending completion:"})
       foreach (m_pending[l]) begin
          uvm_reg rg=l;
          $display("\n%s",rg.get_full_name());
       end
    end
  endfunction

endclass




