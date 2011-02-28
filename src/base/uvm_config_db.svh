//----------------------------------------------------------------------
//   Copyright 2010-2011 Mentor Graphics Corporation
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
//----------------------------------------------------------------------

//Internal class for config waiters
class m_uvm_waiter;
  string inst_name;
  string field_name;
  event trigger;
  function new (string inst_name, string field_name);
    this.inst_name = inst_name;
    this.field_name = field_name;
  endfunction
endclass

//----------------------------------------------------------------------
// class: uvm_config_db#(T)
//
// The uvm_config_db#(T) class provides a convenience interface 
// on top of the <uvm_resource_db> to simplify the basic interface
// that is used for reading and writing into the resource database.
//
// All of the functions in uvm_config_db#(T) are static, so they
// must be called using the :: operator.  For example:
//
//|  uvm_config_db#(int)::set(this, "*", "A");
//
// The parameter value "int" identifies the configuration type as
// an int property.  
//
// The <set> and <get> methods provide the same api and
// semantics as the set/get_config_* functions in <uvm_component>.
//----------------------------------------------------------------------
class uvm_config_db#(type T=int) extends uvm_resource_db#(T);

  // Internal lookup of config settings so they can be reused
  // The context has a pool that is keyed by the inst/field name.
  static uvm_pool#(string,uvm_resource#(T)) m_rsc[uvm_component];

  // Internal waiter list for wait_modified
  static local uvm_queue#(m_uvm_waiter) m_waiters[string];

  // function: get
  //
  // Get the value ~field_name~ in ~inst_name~, using component ~cntxt~ as 
  // the starting search point. ~inst_name~ is an explicit instance name 
  // relative to ~cntxt~ and may be an empty string if the ~cntxt~ is the
  // instance that the configuration object applies to. ~field_name~
  // is the specific field in the scope that is being searched for.
  //
  // The basic get_config_* methods from <uvm_component> are mapped to 
  // this function as:
  //
  //| get_config_int(...) => uvm_config_db#(uvm_bitstream_t)::get(cntxt,...)
  //| get_config_string(...) => uvm_config_db#(string)::get(cntxt,...)
  //| get_config_object(...) => uvm_config_db#(uvm_object)::get(cntxt,...)

  static function bit get(uvm_component cntxt, string inst_name,
      string field_name, ref T value);
//TBD: add file/line
    int unsigned p=0;
    uvm_resource#(T) r, rt;
    uvm_resource_pool rp = uvm_resource_pool::get();
    uvm_resource_types::rsrc_q_t rq;

    if(cntxt == null) 
      cntxt = uvm_root::get();
    if(inst_name == "") 
      inst_name = cntxt.get_full_name();
    else if(cntxt.get_full_name() != "") 
      inst_name = {cntxt.get_full_name(), ".", inst_name};
 
    rq = rp.lookup_regex_names(inst_name, field_name);
    r = uvm_resource#(T)::get_highest_precedence(rq);
    
    if(r == null)
      return 0;

    value = r.read(cntxt);

    return 1;
  endfunction

  // function: set 
  //
  // Create a new or update an existing configuration setting for
  // ~field_name~ in ~inst_name~ from ~cntxt~.
  // The setting is made at ~cntxt~, with the full name of ~cntxt~ 
  // added to the ~inst_name~. If ~cntxt~ is null then ~inst_name~
  // provides the complete scope information of the setting.
  // ~field_name~ is the target field. Both ~inst_name~ and ~field_name~
  // may be glob style or regular expression style expressions.
  //
  // If a setting is made at build time, the ~cntxt~ hierarchy is
  // used to determine the setting's precedence in the database.
  // Settings from hierarchically higher levels have higher
  // precedence. Settings from the same level of hierarchy have
  // a last setting wins semantic. A precedence setting of 
  // <uvm_resource_base::default_precedence>  is used for uvm_top, and 
  // each hierarcical level below the top is decremented by 1.
  //
  // After build time, all settings use the default precedence and thus
  // have a last wins semantic. So, if at run time, a low level 
  // component makes a runtime setting of some field, that setting 
  // will have precedence over a setting from the test level that was 
  // made earlier in the simulation.
  //
  // The basic set_config_* methods from <uvm_component> are mapped to 
  // this function as:
  //
  //| set_config_int(...) => uvm_config_db#(uvm_bitstream_t)::set(cntxt,...)
  //| set_config_string(...) => uvm_config_db#(string)::set(cntxt,...)
  //| set_config_object(...) => uvm_config_db#(uvm_object)::set(cntxt,...)

  static function void set(uvm_component cntxt,
                           string inst_name,
                           string field_name,
                           T value);

    uvm_root top;
    uvm_phase curr_phase;
    uvm_resource#(T) r;
    bit exists = 0;
    
    //take care of random stability during allocation
    process p = process::self();
    string rstate = p.get_randstate();
    top = uvm_root::get();
    curr_phase = top.m_current_phase;

    if(cntxt == null) 
      cntxt = top;
    if(inst_name == "") 
      inst_name = cntxt.get_full_name();
    else if(cntxt.get_full_name() != "") 
      inst_name = {cntxt.get_full_name(), ".", inst_name};

    r = m_get_resource_match(cntxt, field_name, inst_name);
   
    if(r == null) begin 
      uvm_pool#(string, uvm_resource#(T)) pool = new;
      string key = {inst_name,field_name};
      m_rsc[cntxt] = pool;
      r = new(field_name, inst_name);
      pool.add(key, r);
    end
    else begin
      exists = 1;
    end

    if(curr_phase != null && curr_phase.get_name() == "build")
      r.precedence -= cntxt.get_depth();

    r.write(value, cntxt);

    if(exists) begin
      uvm_resource_pool rp = uvm_resource_pool::get();
      rp.set_priority_name(r, uvm_resource_types::PRI_HIGH);
    end
    else begin
      //Doesn't exist yet, so put it in resource db at the head.
      r.set_override();
    end

    //trigger any waiters
    if(m_waiters.exists(field_name)) begin
      m_uvm_waiter w;
      for(int i=0; i<m_waiters[field_name].size(); ++i) begin
        w = m_waiters[field_name].get(i);
        if(uvm_re_match(inst_name,w.inst_name) == 0)
           ->w.trigger;  
      end
    end

    p.set_randstate(rstate);
  endfunction


  // function: exists
  //
  // Check if a value for ~field_name~ is available in ~inst_name~, using
  // component ~cntxt~ as the starting search point. ~inst_name~ is an explicit
  // instance name relative to ~cntxt~ and may be an empty string if the
  // ~cntxt~ is the instance that the configuration object applies to.
  // ~field_name~ is the specific field in the scope that is being searched for.
  // The ~spell_chk~ arg can be set to 1 to turn spell checking on if it
  // is expected that the field should exist in the database. The function
  // returns 1 if a config parameter exists and 0 if it doesn't exist.
  //

  static function bit exists(uvm_component cntxt, string inst_name,
      string field_name, bit spell_chk=0);

    if(cntxt == null)
      cntxt = uvm_root::get();
    if(inst_name == "")
      inst_name = cntxt.get_full_name();
    else if(cntxt.get_full_name() != "")
      inst_name = {cntxt.get_full_name(), ".", inst_name};

    return (uvm_resource_db#(T)::get_by_name(inst_name,field_name,spell_chk) != null);
  endfunction


  // Function: wait_modified
  //
  // Wait for a configuration setting to be set for ~field_name~
  // in ~cntxt~ and ~inst_name~. The task blocks until a new configuration
  // setting is applied that effects the specified field.

  static task wait_modified(uvm_component cntxt, string inst_name,
      string field_name);
    process p = process::self();
    string rstate = p.get_randstate();
    m_uvm_waiter waiter;

    if(cntxt == null)
      cntxt = uvm_root::get();
    if(cntxt != uvm_root::get()) begin
      if(inst_name != "")
        inst_name = {cntxt.get_full_name(),".",inst_name};
      else
        inst_name = cntxt.get_full_name();
    end

    waiter = new(inst_name, field_name);

    if(!m_waiters.exists(field_name))
      m_waiters[field_name] = new;
    m_waiters[field_name].push_back(waiter);

    p.set_randstate(rstate);

    // wait on the waiter to trigger
    @waiter.trigger;
  
    // Remove the waiter from the waiter list 
    for(int i=0; i<m_waiters[field_name].size(); ++i) begin
      if(m_waiters[field_name].get(i) == waiter) begin
        m_waiters[field_name].delete(i);
        break;
      end
    end 
  endtask


  static function uvm_resource#(T) m_get_resource_match(uvm_component cntxt, 
        string field_name, string inst_name);
    uvm_pool#(string,uvm_resource#(T)) pool;
    string lookup;

    if(!m_rsc.exists(cntxt)) begin
      return null;
    end

    lookup = {inst_name,field_name};
    pool = m_rsc[cntxt];

    if(!pool.exists(lookup)) return null;
      
    return pool.get(lookup);
  endfunction
endclass

typedef uvm_config_db#(uvm_object_wrapper) uvm_config_wrapper;

