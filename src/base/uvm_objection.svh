//
//----------------------------------------------------------------------
//   Copyright 2007-2011 Mentor Graphics Corporation
//   Copyright 2007-2011 Cadence Design Systems, Inc. 
//   Copyright 2010-2011 Synopsys, Inc.
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

`ifndef UVM_OBJECTION_SVH
`define UVM_OBJECTION_SVH

typedef class uvm_objection_context_object;
typedef class uvm_objection;
typedef class uvm_sequence_base;
typedef class uvm_objection_callback;
typedef uvm_callbacks #(uvm_objection,uvm_objection_callback) uvm_objection_cbs_t;
typedef class uvm_cmdline_processor;
typedef class uvm_callbacks_objection;

class uvm_objection_events;
  int waiters;
  event raised;
  event dropped;
  event all_dropped;
endclass

//------------------------------------------------------------------------------
// Title: Objection Mechanism
//------------------------------------------------------------------------------
// The following classes define the objection mechanism and end-of-test
// functionality, which is based on <uvm_objection>.
//------------------------------------------------------------------------------

//------------------------------------------------------------------------------
//
// Class: uvm_objection
//
//------------------------------------------------------------------------------
// Objections provide a facility for coordinating status information between
// two or more participating components, objects, and even module-based IP.
// In particular, the ~uvm_test_done~ built-in objection provides a means for
// coordinating when to end a test, i.e. when to call <global_stop_request> to
// end the <uvm_component::run> phase.  When all participating components have
// dropped their raised objections with ~uvm_test_done~, an implicit call to
// ~global_stop_request~ is issued.
//
// Tracing of objection activity can be turned on to follow the activity of
// the objection mechanism. It may be turned on for a specific objection
// instance with <uvm_objection::trace_mode>, or it can be set for all 
// objections from the command line using the option +UVM_OBJECTION_TRACE.
//------------------------------------------------------------------------------

class uvm_objection extends uvm_report_object;

  protected bit     m_trace_mode=0;
  protected int     m_source_count[uvm_object];
  protected int     m_total_count [uvm_object];
  protected time    m_drain_time  [uvm_object];
  protected bit     m_draining    [uvm_object];
  protected uvm_objection_events m_events [uvm_object];
  /*protected*/ bit     m_top_all_dropped;
  protected process m_background_proc;

  protected uvm_root m_top = uvm_root::get();

  static uvm_objection m_objections[$];

  local uvm_objection_context_object m_context_pool[$];
  local uvm_objection_context_object m_scheduled_list[$];

  /*protected*/ bit m_hier_mode = 1;

  uvm_root top = uvm_root::get();


  protected bit m_cleared = 0; /* for checking obj count<0 */


  // Fuction: clear
  //
  // Immediately clears the objection state. All counts are cleared and the
  // <all_dropped> callback for <uvm_top> is called. 
  // Any drain_times set by the user are not effected.
  //
  virtual function void clear(uvm_object obj=null);
    string name;
    if (obj==null)
      obj=m_top;
    name = obj.get_full_name();
    if (name == "")
      name = "uvm_top";
    else
      name = obj.get_full_name();
    if (!m_top_all_dropped && get_objection_total(m_top))
      uvm_report_warning("OBJTN_CLEAR",{"Object '",name,
            "' cleared objection counts for ",get_name()});
    //Should there be a warning if there are outstanding objections?
    m_source_count.delete();
    m_total_count.delete();
    m_draining.delete();
    m_top_all_dropped = 0;
    m_cleared = 1;
    if (m_events.exists(obj))
      ->m_events[obj].all_dropped;
    m_background_proc.kill();

    fork
      begin
        m_background_proc = process::self();
        m_execute_scheduled_forks();
      end
    join_none
  endfunction


  // Function: new
  //
  // Creates a new objection instance. Accesses the command line
  // argument +UVM_OBJECTION_TRACE to turn tracing on for
  // all objection objects.

  function new(string name="");
    uvm_cmdline_processor clp;
    string trace_args[$];
    super.new(name);
    set_report_verbosity_level(m_top.get_report_verbosity_level());

    // Get the command line trace mode setting
    clp = uvm_cmdline_processor::get_inst();
    if(clp.get_arg_matches("+UVM_OBJECTION_TRACE", trace_args)) begin
      m_trace_mode=1;
    end
    m_objections.push_back(this);
  endfunction


  // Function: trace_mode
  //
  // Set or get the trace mode for the objection object. If no
  // argument is specified (or an argument other than 0 or 1)
  // the current trace mode is unaffected. A trace_mode of
  // 0 turns tracing off. A trace mode of 1 turns tracing on.
  // The return value is the mode prior to being reset.

   function bit trace_mode (int mode=-1);
    trace_mode = m_trace_mode;
    if(mode == 0) m_trace_mode = 0;
    else if(mode == 1) m_trace_mode = 1;
   endfunction

  // Function- m_report
  //
  // Internal method for reporting count updates

  function void m_report(uvm_object obj, uvm_object source_obj, string description, int count, string action);
    string desc;
    int _count = m_source_count.exists(obj) ? m_source_count[obj] : 0;
    int _total = m_total_count.exists(obj) ? m_total_count[obj] : 0;
    if (!uvm_report_enabled(UVM_NONE,UVM_INFO,"OBJTN_TRC") || !m_trace_mode) return;

    //desc = description == "" ? "" : {" ", description, "" };
    if (source_obj == obj)

      uvm_report_info("OBJTN_TRC", 
        $sformatf("Object %0s %0s %0d objection(s)%s: count=%0d  total=%0d",
           obj.get_full_name()==""?"uvm_top":obj.get_full_name(), action,
           count, description != ""? {" (",description,")"}:"", _count, _total), UVM_NONE);
    else begin
      int cpath = 0, last_dot=0;
      string sname = source_obj.get_full_name(), nm = obj.get_full_name();
      int max = sname.len() > nm.len() ? nm.len() : sname.len();

      // For readability, only print the part of the source obj hierarchy underneath
      // the current object.
      while((sname[cpath] == nm[cpath]) && (cpath < max)) begin
        if(sname[cpath] == ".") last_dot = cpath;
        cpath++;
      end 

      if(last_dot) sname = sname.substr(last_dot+1, sname.len());
      uvm_report_info("OBJTN_TRC",
        $sformatf("Object %0s %0s %0d objection(s) %0s its total (%s from source object %s%s): count=%0d  total=%0d",
           obj.get_full_name()==""?"uvm_top":obj.get_full_name(), action=="raised"?"added":"subtracted",
            count, action=="raised"?"to":"from", action, sname, 
            description != ""?{", ",description}:"", _count, _total), UVM_NONE);
    end
  endfunction


  // Function- m_get_parent
  //
  // Internal method for getting the parent of the given ~object~.
  // The ultimate parent is uvm_top, UVM's implicit top-level component. 

  function uvm_object m_get_parent(uvm_object obj);
    uvm_component comp;
    uvm_sequence_base seq;
    if ($cast(comp, obj)) begin
      obj = comp.get_parent();
    end
    else if ($cast(seq, obj)) begin
       obj = seq.get_sequencer();
    end
    else
      obj = m_top;
    if (obj == null)
      obj = m_top;
    return obj;
  endfunction


  // Function- m_propagate
  //
  // Propagate the objection to the objects parent. If the object is a
  // component, the parent is just the hierarchical parent. If the object is
  // a sequence, the parent is the parent sequence if one exists, or
  // it is the attached sequencer if there is no parent sequence. 
  //
  // obj : the uvm_object on which the objection is being raised or lowered
  // source_obj : the root object on which the end user raised/lowered the 
  //   objection (as opposed to an anscestor of the end user object)a
  // count : the number of objections associated with the action.
  // raise : indicator of whether the objection is being raised or lowered. A
  //   1 indicates the objection is being raised.

  function void m_propagate (uvm_object obj,
                             uvm_object source_obj,
                             string description,
                             int count,
                             bit raise,
                             int in_top_thread);
    if (obj != null && obj != m_top) begin
      obj = m_get_parent(obj);
      if(raise)
        m_raise(obj, source_obj, description, count);
      else
        m_drop(obj, source_obj, description, count, in_top_thread);
    end
  endfunction


  // Group: Objection Control
  
  // Function: m_set_hier_mode
  //
  // Hierarchical mode only needs to be set for intermediate components, not
  // for uvm_root or a leaf component.

  function void m_set_hier_mode (uvm_object obj);
    uvm_component c;
    if((m_hier_mode == 1) || (obj == m_top)) begin
      // Don't set if already set or the object is uvm_top.
      return;
    end
    if($cast(c,obj)) begin
      // Don't set if object is a leaf.
      if(c.get_num_children() == 0) begin
        return;
      end
    end
    else begin
      // Don't set if object is a non-component.
      return;
    end

    // restore counts on non-source nodes
    m_total_count.delete();
    foreach (m_source_count[obj]) begin
      uvm_object theobj = obj;
      int count = m_source_count[obj];
      do begin
        if (m_total_count.exists(theobj))
          m_total_count[theobj] += count;
        else
          m_total_count[theobj] = count;
        theobj = m_get_parent(theobj);
      end
      while (theobj != null);
    end
    
    m_hier_mode = 1;
  endfunction


  // Function: raise_objection
  //
  // Raises the number of objections for the source ~object~ by ~count~, which
  // defaults to 1.  The ~object~ is usually the ~this~ handle of the caller.
  // If ~object~ is not specified or null, the implicit top-level component,
  // ~uvm_top~, is chosen.
  //
  // Rasing an objection causes the following.
  //
  // - The source and total objection counts for ~object~ are increased by
  //   ~count~. ~description~ is a string that marks a specific objection
  //   and is used in tracing/debug.
  //
  // - The objection's <raised> virtual method is called, which calls the
  //   <uvm_component::raised> method for all of the components up the 
  //   hierarchy.
  //

  virtual function void raise_objection (uvm_object obj=null,
                                         string description="",
                                         int count=1);
    if(obj == null)
      obj = m_top;
    m_cleared = 0;
    m_raise (obj, obj, description, count);
  endfunction


  // Function- m_raise

  function void m_raise (uvm_object obj,
                         uvm_object source_obj,
                         string description="",
                         int count=1);

    if (m_total_count.exists(obj))
      m_total_count[obj] += count;
    else 
      m_total_count[obj] = count;

    if (source_obj==obj) begin
      if (m_source_count.exists(obj))
        m_source_count[obj] += count;
      else
        m_source_count[obj] = count;
    end
  
    if (m_trace_mode)
      m_report(obj,source_obj,description,count,"raised");

    raised(obj, source_obj, description, count);

    // If this object is still draining from a previous drop, then
    // raise the count and return. Any propagation will be handled
    // by the drain process.
    if (m_draining.exists(obj))
      return;

    if (!m_hier_mode && obj != m_top)
      m_raise(m_top,source_obj,description,count);
    else if (obj != m_top)
      m_propagate(obj, source_obj, description, count, 1, 0);
  
  endfunction
  

  // Function: drop_objection
  //
  // Drops the number of objections for the source ~object~ by ~count~, which
  // defaults to 1.  The ~object~ is usually the ~this~ handle of the caller.
  // If ~object~ is not specified or null, the implicit top-level component,
  // ~uvm_top~, is chosen.
  //
  // Dropping an objection causes the following.
  //
  // - The source and total objection counts for ~object~ are decreased by
  //   ~count~. It is an error to drop the objection count for ~object~ below
  //   zero.
  //
  // - The objection's <dropped> virtual method is called, which calls the
  //   <uvm_component::dropped> method for all of the components up the 
  //   hierarchy.
  //
  // - If the total objection count has not reached zero for ~object~, then
  //   the drop is propagated up the object hierarchy as with
  //   <raise_objection>. Then, each object in the hierarchy will have updated
  //   their ~source~ counts--objections that they originated--and ~total~
  //   counts--the total number of objections by them and all their
  //   descendants.
  //
  // If the total objection count reaches zero, propagation up the hierarchy
  // is deferred until a configurable drain-time has passed and the 
  // <uvm_component::all_dropped> callback for the current hierarchy level
  // has returned. The following process occurs for each instance up
  // the hierarchy from the source caller:
  //
  // A process is forked in a non-blocking fashion, allowing the ~drop~
  // call to return. The forked process then does the following:
  //
  // - If a drain time was set for the given ~object~, the process waits for
  //   that amount of time.
  //
  // - The objection's <all_dropped> virtual method is called, which calls the
  //   <uvm_component::all_dropped> method (if ~object~ is a component).
  //
  // - The process then waits for the ~all_dropped~ callback to complete.
  //
  // - After the drain time has elapsed and all_dropped callback has
  //   completed, propagation of the dropped objection to the parent proceeds
  //   as described in <raise_objection>, except as described below.
  //
  // If a new objection for this ~object~ or any of its descendents is raised
  // during the drain time or during execution of the all_dropped callback at
  // any point, the hierarchical chain described above is terminated and the
  // dropped callback does not go up the hierarchy. The raised objection will
  // propagate up the hierarchy, but the number of raised propagated up is
  // reduced by the number of drops that were pending waiting for the 
  // all_dropped/drain time completion. Thus, if exactly one objection
  // caused the count to go to zero, and during the drain exactly one new
  // objection comes in, no raises or drops are propagted up the hierarchy,
  //
  // As an optimization, if the ~object~ has no set drain-time and no
  // registered callbacks, the forked process can be skipped and propagation
  // proceeds immediately to the parent as described. 

  virtual function void drop_objection (uvm_object obj=null,
                                        string description="",
                                        int count=1);
    if(obj == null)
      obj = m_top;
    m_drop (obj, obj, description, count, 0);
  endfunction


  // Function- m_drop

  function void m_drop (uvm_object obj,
                        uvm_object source_obj,
                        string description="",
                        int count=1,
                        int in_top_thread=0);

    if (!m_total_count.exists(obj) || (count > m_total_count[obj])) begin
      if(m_cleared)
        return;
      uvm_report_fatal("OBJTN_ZERO", {"Object \"", obj.get_full_name(), 
        "\" attempted to drop objection '",this.get_name(),"' count below zero"});
      return;
    end

    if (obj == source_obj) begin
      if (!m_source_count.exists(obj) || (count > m_source_count[obj])) begin
        if(m_cleared)
          return;
        uvm_report_fatal("OBJTN_ZERO", {"Object \"", obj.get_full_name(), 
          "\" attempted to drop objection '",this.get_name(),"' count below zero"});
        return;
      end
      m_source_count[obj] -= count;
    end

    m_total_count[obj] -= count;

    if (m_trace_mode)
      m_report(obj,source_obj,description,count,"dropped");
    
    dropped(obj, source_obj, description, count);
  
    // if count != 0, no reason to fork
    if (m_total_count[obj] != 0) begin
      if (!m_hier_mode && obj != m_top)
        m_drop(m_top,source_obj,description, count, in_top_thread);
      else if (obj != m_top) begin
        this.m_propagate(obj, source_obj, description, count, 0, in_top_thread);
      end

    end
    else begin
      // need to make sure we are safe from the dropping thread terminating
      // while the drain time is being honored. Can call immediatiately if
      // we are in the top thread, otherwise we have to schedule it.
      m_draining[obj] = 1;
      if(in_top_thread) begin
        m_forked_drop(obj, source_obj, description, count, in_top_thread);
      end
      else
      begin
        uvm_objection_context_object ctxt;
        if(m_context_pool.size())
          ctxt = m_context_pool.pop_front();
        else
          ctxt = new;
        ctxt.obj = obj;
        ctxt.source_obj = source_obj;
        ctxt.description = description;
        ctxt.count = count;
        m_scheduled_list.push_back(ctxt); 
      end
    end

  endfunction


  // m_init_objections
  // -----------------

  static function void m_init_objections();
    fork begin
      while(1) begin
        wait(m_objections.size() != 0);
        foreach(m_objections[i]) begin
          automatic uvm_objection obj = m_objections[i];
          fork
            begin
              obj.m_background_proc = process::self();
              obj.m_execute_scheduled_forks();
            end
          join_none
        end
        m_objections.delete();
      end
    end join_none
  endfunction


  // m_execute_scheduled_forks
  // -------------------------

  // background process; when non
  task m_execute_scheduled_forks;
    uvm_objection_context_object ctxt;
    while(1) begin
      wait(m_scheduled_list.size() != 0);
      if(m_scheduled_list.size() != 0) begin
	 ctxt = m_scheduled_list.pop_front();
	 m_forked_drop(ctxt.obj, ctxt.source_obj, ctxt.description, ctxt.count, 1);
	 m_context_pool.push_back(ctxt);
      end
    end
  endtask


  // m_forked_drop
  // -------------

  function void m_forked_drop (uvm_object obj,
                               uvm_object source_obj,
                               string description="",
                               int count=1,
                               int in_top_thread=0);

    int diff_count;

    fork   // join_none, so this can be a function
    begin  //  also serves as guard proc to embedded disable fork

      fork
        begin
          if (m_drain_time.exists(obj))
            `uvm_delay(m_drain_time[obj])
 
           if (m_trace_mode)
             m_report(obj,source_obj,description,count,"all_dropped");
    
          all_dropped(obj,source_obj,description, count);
 
          // wait for all_dropped cbs to complete
          wait fork;
        end
        wait (m_total_count.exists(obj) && m_total_count[obj] != 0);
      join_any
      disable fork;

      m_draining.delete(obj);

      if(!m_total_count.exists(obj))
        diff_count = -count;
      else
        diff_count = m_total_count[obj] - count;

      // no propagation if a re-raise cancels the drop
      if (diff_count != 0) begin
        bit reraise;

        if (diff_count > 0)
          reraise = 1;
        reraise = diff_count > 0 ? 1 : 0;
 
        if (diff_count < 0)
          diff_count = -diff_count;

        // we are ready to delete the 0-count entries for the current
        // object before propagating up the hierarchy. 
        if (m_source_count.exists(obj) && m_source_count[obj] == 0)
            m_source_count.delete(obj);

        if (m_total_count.exists(obj) && m_total_count[obj] == 0)
           m_total_count.delete(obj);

        if (!m_hier_mode && obj != m_top) begin
          if (reraise)
            m_raise(m_top,source_obj,description,diff_count);
          else
            m_drop(m_top,source_obj,description, diff_count, 1);
        end
        else begin
          if (obj != m_top)
            this.m_propagate(obj, source_obj, description, diff_count, reraise, 1);
        end
      end

    end
    join_none
 
  endfunction

  // Function: set_drain_time
  //
  // Sets the drain time on the given ~object~ to ~drain~.
  //
  // The drain time is the amount of time to wait once all objections have
  // been dropped before calling the all_dropped callback and propagating
  // the objection to the parent. 
  //
  // If a new objection for this ~object~ or any of its descendents is raised
  // during the drain time or during execution of the all_dropped callbacks,
  // the drain_time/all_dropped execution is terminated. 

  // AE: set_drain_time(drain,obj=null)?
  function void set_drain_time (uvm_object obj=null, time drain);
    if (obj==null)
      obj = m_top;
    m_drain_time[obj] = drain;
    m_set_hier_mode(obj);
  endfunction
  

  //----------------------
  // Group: Callback Hooks
  //----------------------

  // Function: raised
  //
  // Objection callback that is called when a <raise_objection> has reached ~obj~.
  // The default implementation calls <uvm_component::raised>.

  virtual function void raised (uvm_object obj,
                                uvm_object source_obj,
                                string description,
                                int count);
    uvm_component comp;
    if ($cast(comp,obj))    
      comp.raised(this, source_obj, description, count);
    if (m_events.exists(obj))
       ->m_events[obj].raised;
  endfunction


  // Function: dropped
  //
  // Objection callback that is called when a <drop_objection> has reached ~obj~.
  // The default implementation calls <uvm_component::dropped>.

  virtual function void dropped (uvm_object obj,
                                 uvm_object source_obj,
                                 string description,
                                 int count);
    uvm_component comp;
    if($cast(comp,obj))    
      comp.dropped(this, source_obj, description, count);
    if (m_events.exists(obj))
       ->m_events[obj].dropped;
  endfunction


  // Function: all_dropped
  //
  // Objection callback that is called when a <drop_objection> has reached ~obj~,
  // and the total count for ~obj~ goes to zero. This callback is executed
  // after the drain time associated with ~obj~. The default implementation 
  // calls <uvm_component::all_dropped>.

  virtual task all_dropped (uvm_object obj,
                            uvm_object source_obj,
                            string description,
                            int count);
    uvm_component comp;
    if($cast(comp,obj))    
      comp.all_dropped(this, source_obj, description, count);
    if (m_events.exists(obj))
       ->m_events[obj].all_dropped;
    if (obj == m_top)
      m_top_all_dropped = 1;
  endtask


  //------------------------
  // Group: Objection Status
  //------------------------

  // Function: get_objectors
  //
  // Returns the current list of objecting objects (objects that
  // raised an objection but have not dropped it).

  function void get_objectors(ref uvm_object list[$]);
    list.delete();
    foreach (m_source_count[obj]) list.push_back(obj); 
  endfunction


  // Task: wait_for
  //
  // Waits for the raised, dropped, or all_dropped ~event~ to occur in
  // the given ~obj~. The task returns after all corresponding callbacks
  // have been executed.
  //
  task wait_for(uvm_objection_event objt_event, uvm_object obj=null);

     if (obj==null)
       obj = m_top;

     if (obj == m_top && m_top_all_dropped)
       return;

     if (!m_events.exists(obj)) begin
       m_events[obj] = new;
     end

     m_events[obj].waiters++;
     case (objt_event)
       UVM_RAISED:      @(m_events[obj].raised);
       UVM_DROPPED:     @(m_events[obj].dropped);
       UVM_ALL_DROPPED: @(m_events[obj].all_dropped);
     endcase
     
     m_events[obj].waiters--;

     if (m_events[obj].waiters == 0)
       m_events.delete(obj);

   endtask


   task wait_for_total_count(uvm_object obj=null, int count=0);
     if (obj==null)
       obj = m_top;

     if(!m_total_count.exists(obj) && count == 0)
       return;
     if (count == 0)
        wait (!m_total_count.exists(obj) && count == 0);
     else
        wait (m_total_count.exists(obj) && m_total_count[obj] == count);
   endtask
   

  // Function: get_objection_count
  //
  // Returns the current number of objections raised by the given ~object~.

  function int get_objection_count (uvm_object obj=null);
    if (obj==null)
      obj = m_top;

    if (!m_source_count.exists(obj))
      return 0;
    return m_source_count[obj];
  endfunction
  

  // Function: get_objection_total
  //
  // Returns the current number of objections raised by the given ~object~ 
  // and all descendants.

  function int get_objection_total (uvm_object obj=null);
    uvm_component c;
    string ch;
 
    if (obj==null)
      obj = m_top;

    if (!m_total_count.exists(obj))
      return 0;
    if (m_hier_mode) 
      return m_total_count[obj];
    else begin
      if ($cast(c,obj)) begin
        if (!m_source_count.exists(obj))
          get_objection_total = 0;
        else
          get_objection_total = m_source_count[obj];
        if (c.get_first_child(ch))
        do
          get_objection_total += get_objection_total(c.get_child(ch));
        while (c.get_next_child(ch));
      end
      else begin
        return m_total_count[obj];
      end
    end
  endfunction
  

  // Function: get_drain_time
  //
  // Returns the current drain time set for the given ~object~ (default: 0 ns).

  function time get_drain_time (uvm_object obj=null);
    if (obj==null)
      obj = m_top;

    if (!m_drain_time.exists(obj))
      return 0;
    return m_drain_time[obj];
  endfunction


  // m_display_objections

  protected function string m_display_objections(uvm_object obj=null, bit show_header=1);

    static string blank="                                                                                   ";
    
    string s;
    int total;
    uvm_object list[string];
    uvm_object curr_obj;
    int depth;
    string name;
    string this_obj_name;
    string curr_obj_name;
  
    foreach (m_total_count[o]) begin
      uvm_object theobj = o; 
      if ( m_total_count[o] > 0)
        list[theobj.get_full_name()] = theobj;
    end

    if (obj==null)
      obj = m_top;

    total = get_objection_total(obj);
    
    s = $sformatf("The total objection count is %0d\n",total);

    if (total == 0)
      return s;

    s = {s,"---------------------------------------------------------\n"};
    s = {s,"Source  Total   \n"};
    s = {s,"Count   Count   Object\n"};
    s = {s,"---------------------------------------------------------\n"};

  
    this_obj_name = obj.get_full_name();
    curr_obj_name = this_obj_name;

    do begin

      curr_obj = list[curr_obj_name];
  
      // determine depth
      depth=0;
      foreach (curr_obj_name[i])
        if (curr_obj_name[i] == ".")
          depth++;

      // determine leaf name
      name = curr_obj_name;
      for (int i=curr_obj_name.len()-1;i >= 0; i--)
        if (curr_obj_name[i] == ".") begin
           name = curr_obj_name.substr(i+1,curr_obj_name.len()-1); 
           break;
        end
      if (curr_obj_name == "")
        name = "uvm_top";
      else
        depth++;

      // print it
      s = {s, $sformatf("%-6d  %-6d %s%s\n",
         m_source_count.exists(curr_obj) ? m_source_count[curr_obj] : 0,
         m_total_count.exists(curr_obj) ? m_total_count[curr_obj] : 0,
         blank.substr(0,2*depth), name)};

    end while (list.next(curr_obj_name) &&
        curr_obj_name.substr(0,this_obj_name.len()-1) == this_obj_name);
  
    s = {s,"---------------------------------------------------------\n"};

    return s;

  endfunction
  

  function string convert2string();
    return m_display_objections(m_top,1);
  endfunction
  
  
  // Function: display_objections
  // 
  // Displays objection information about the given ~object~. If ~object~ is
  // not specified or ~null~, the implicit top-level component, <uvm_root>, is
  // chosen. The ~show_header~ argument allows control of whether a header is
  // output.

  function void display_objections(uvm_object obj=null, bit show_header=1);
    $display(m_display_objections(obj,show_header));
  endfunction


  // Below is all of the basic data stuff that is needed for an uvm_object
  // for factory registration, printing, comparing, etc.

  typedef uvm_object_registry#(uvm_objection,"uvm_objection") type_id;
  static function type_id get_type();
    return type_id::get();
  endfunction

  function uvm_object create (string name="");
    uvm_objection tmp = new(name);
    return tmp;
  endfunction

  virtual function string get_type_name ();
    return "uvm_objection";
  endfunction

  function void do_copy (uvm_object rhs);
    uvm_objection _rhs;
    $cast(_rhs, rhs);
    m_source_count = _rhs.m_source_count;
    m_total_count  = _rhs.m_total_count;
    m_drain_time   = _rhs.m_drain_time;
    m_draining     = _rhs.m_draining;
    m_hier_mode    = _rhs.m_hier_mode;
  endfunction

endclass


`ifdef UVM_USE_CALLBACKS_OBJECTION_FOR_TEST_DONE
  typedef uvm_callbacks_objection m_uvm_test_done_objection_base;
`else
  typedef uvm_objection m_uvm_test_done_objection_base;
`endif


// TODO: change to plusarg
`define UVM_DEFAULT_TIMEOUT 9200s

typedef class uvm_cmdline_processor;



//------------------------------------------------------------------------------
//
// Class- uvm_test_done_objection DEPRECATED
//
// Provides built-in end-of-test coordination
//------------------------------------------------------------------------------

class uvm_test_done_objection extends m_uvm_test_done_objection_base;

  protected static uvm_test_done_objection m_inst = get();
  protected bit m_forced;

  // For communicating all objections dropped and end of phasing
  local  bit m_executing_stop_processes;
  local  int m_n_stop_threads;


  // Function- new DEPRECATED
  //
  // Creates the singleton test_done objection. Users must not to call
  // this method directly.

  function new(string name="uvm_test_done");
    super.new(name);
  endfunction


  // Function- qualify DEPRECATED
  //
  // Checks that the given ~object~ is derived from either <uvm_component> or
  // <uvm_sequence_base>.

  virtual function void qualify(uvm_object obj=null,
                                bit is_raise,
                                string description);
    uvm_component c;
    uvm_sequence_base s;
    string nm = is_raise ? "raise_objection" : "drop_objection";
    string desc = description == "" ? "" : {" (\"", description, "\")"};
    if(! ($cast(c,obj) || $cast(s,obj))) begin
      uvm_report_error("TEST_DONE_NOHIER", {"A non-hierarchical object, '",
        obj.get_full_name(), "' (", obj.get_type_name(),") was used in a call ",
        "to uvm_test_done.", nm,"(). For this objection, a sequence ",
        "or component is required.", desc });
    end
  endfunction

  
  // m_do_stop_all
  // -------------

  task m_do_stop_all(uvm_component comp);

    string name;

    // we use an external traversal to ensure all forks are 
    // made from a single threaad.
    if (comp.get_first_child(name))
      do begin
        m_do_stop_all(comp.get_child(name));
      end
      while (comp.get_next_child(name));
  
    if (comp.enable_stop_interrupt) begin
      m_n_stop_threads++;
      fork begin
        comp.stop_phase(run_ph);
        m_n_stop_threads--;
      end
      join_none
    end
  endtask
 

  // Function- stop_request DEPRECATED
  //
  // Calling this function triggers the process of shutting down the currently
  // running task-based phase. This process involves calling all components'
  // stop tasks for those components whose enable_stop_interrupt bit is set.
  // Once all stop tasks return, or once the optional global_stop_timeout
  // expires, all components' kill method is called, effectively ending the
  // current phase. The uvm_top will then begin execution of the next phase,
  // if any.

  function void stop_request();
    `uvm_info_context("STOP_REQ",
                      "Stop-request called. Waiting for all-dropped on uvm_test_done",
                      UVM_FULL,m_top);
    fork
      m_stop_request();
    join_none
  endfunction

  task m_stop_request();
    raise_objection(m_top,"stop_request called; raising test_done objection");
    uvm_wait_for_nba_region();
    drop_objection(m_top,"stop_request called; dropping test_done objection");
  endtask


  // Variable- stop_timeout DEPRECATED
  //
  // These set watchdog timers for task-based phases and stop tasks. You can not
  // disable the timeouts. When set to 0, a timeout of the maximum time possible
  // is applied. A timeout at this value usually indicates a problem with your
  // testbench. You should lower the timeout to prevent "never-ending"
  // simulations. 

  time stop_timeout = 0;


  // Task- all_dropped DEPRECATED
  //
  // This callback is called when the given ~object's~ objection count reaches
  // zero; if the ~object~ is the implicit top-level, <uvm_root> then it means
  // there are no more objections raised for the ~uvm_test_done~ objection.
  // Thus, after calling <uvm_objection::all_dropped>, this method will call
  // <global_stop_request> to stop the current task-based phase (e.g. run).
  
  virtual task all_dropped (uvm_object obj,
                            uvm_object source_obj,
                            string description,
                            int count);
    if (obj != m_top) begin
      super.all_dropped(obj,source_obj,description,count);
      return;
    end

    m_top.all_dropped(this, source_obj, description, count);

    // All stop tasks are forked from a single thread within a 'guard' process
    // so 'disable fork' can be used.
  
    if(m_cleared == 0) begin
      `uvm_info_context("TEST_DONE",
          "All end-of-test objections have been dropped. Calling stop tasks",
          UVM_FULL,m_top);
      fork begin // guard
        fork
          begin
            m_executing_stop_processes = 1;
            m_do_stop_all(m_top);
            wait (m_n_stop_threads == 0);
            m_executing_stop_processes = 0;
          end
          begin
            if (stop_timeout == 0)
              wait(stop_timeout != 0);
            `uvm_delay(stop_timeout)
            `uvm_error("STOP_TIMEOUT",
              {$sformatf("Stop-task timeout of %0t expired. ", stop_timeout),
                 "'run' phase ready to proceed to extract phase"})
          end
        join_any
        disable fork;
      end
      join // guard
  
      `uvm_info_context("TEST_DONE", {"'run' phase is ready ",
                        "to proceed to the 'extract' phase"}, UVM_LOW,m_top)

    end

    if (m_events.exists(obj))
      ->m_events[obj].all_dropped;
    m_top_all_dropped = 1;

  endtask


  // Function- raise_objection DEPRECATED
  //
  // Calls <uvm_objection::raise_objection> after calling <qualify>. 
  // If the ~object~ is not provided or is ~null~, then the implicit top-level
  // component, ~uvm_top~, is chosen.

  virtual function void raise_objection (uvm_object obj=null, 
                                         string description="",
                                         int count=1);
    if(obj==null)
      obj=m_top;
    else
      qualify(obj, 1, description);

    if (m_executing_stop_processes) begin
      string desc = description == "" ? "" : {"(\"", description, "\") "};
      `uvm_warning("ILLRAISE", {"The uvm_test_done objection was ",
        "raised ", desc, "during processing of a stop_request, i.e. stop ",
        "task execution. The objection is ignored by the stop process"})
        return;
    end

    super.raise_objection(obj,description,count);

  endfunction


  // Function- drop_objection DEPRECATED
  //
  // Calls <uvm_objection::drop_objection> after calling <qualify>. 
  // If the ~object~ is not provided or is ~null~, then the implicit top-level
  // component, ~uvm_top~, is chosen.

  virtual function void drop_objection (uvm_object obj=null, 
                                        string description="",
                                        int count=1);
    if(obj==null)
      obj=m_top;
    else
      qualify(obj, 0, description);
    super.drop_objection(obj,description,count);
  endfunction


  // Task- force_stop DEPRECATED
  //
  // Forces the propagation of the all_dropped() callback, even if there are still
  // outstanding objections. The net effect of this action is to forcibly end
  // the current phase.

  virtual task force_stop(uvm_object obj=null);
    uvm_report_warning("FORCE_STOP",{"Object '",
       (obj!=null?obj.get_name():"<unknown>"),"' called force_stop"});
    m_cleared = 1;
    all_dropped(m_top,obj,"force_stop() called",1);
    clear(obj);
  endtask


  // Below are basic data operations needed for all uvm_objects
  // for factory registration, printing, comparing, etc.

  typedef uvm_object_registry#(uvm_test_done_objection,"uvm_test_done") type_id;
  static function type_id get_type();
    return type_id::get();
  endfunction

  function uvm_object create (string name="");
    uvm_test_done_objection tmp = new(name);
    return tmp;
  endfunction

  virtual function string get_type_name ();
    return "uvm_test_done";
  endfunction

  static function uvm_test_done_objection get();
    if(m_inst == null)
      m_inst = uvm_test_done_objection::type_id::create("run");
    return m_inst;
  endfunction

endclass



// Have a pool of context objects to use
class uvm_objection_context_object;
  uvm_object obj;
  uvm_object source_obj;
  string description;
  int count;
endclass


//------------------------------------------------------------------------------
//
// Class: uvm_callbacks_objection
//
//------------------------------------------------------------------------------
// The uvm_callbacks_objection is a specialized <uvm_objection> which contains
// callbacks for the raised and dropped events. Callbacks happend for the three
// standard callback activities, <raised>, <dropped>, and <all_dropped>.
//
// The <uvm_heartbeat> mechanism use objections of this type for creating
// heartbeat conditions.  Whenever the objection is raised or dropped, the component 
// which did the raise/drop is considered to be alive.
//


class uvm_callbacks_objection extends uvm_objection;
  `uvm_register_cb(uvm_callbacks_objection, uvm_objection_callback)
  function new(string name="");
    super.new(name);
  endfunction

  // Function: raised
  //
  // Executes the <uvm_objection_callback::raised> method in the user callback
  // class whenever this objection is raised at the object ~obj~.

  virtual function void raised (uvm_object obj, uvm_object source_obj, 
      string description, int count);
    `uvm_do_callbacks(uvm_callbacks_objection,uvm_objection_callback,raised(this,obj,source_obj,description,count))
  endfunction

  // Function: dropped
  //
  // Executes the <uvm_objection_callback::dropped> method in the user callback
  // class whenever this objection is dropped at the object ~obj~.

  virtual function void dropped (uvm_object obj, uvm_object source_obj, 
      string description, int count);
    `uvm_do_callbacks(uvm_callbacks_objection,uvm_objection_callback,dropped(this,obj,source_obj,description,count))
  endfunction

  // Function: all_dropped
  //
  // Executes the <uvm_objection_callback::all_dropped> task in the user callback
  // class whenever the objection count for this objection in reference to ~obj~
  // goes to zero.

  virtual task all_dropped (uvm_object obj, uvm_object source_obj, 
      string description, int count);
    `uvm_do_callbacks(uvm_callbacks_objection,uvm_objection_callback,all_dropped(this,obj,source_obj,description,count))
  endtask
endclass


//------------------------------------------------------------------------------
//
// Class: uvm_objection_callback
//
//------------------------------------------------------------------------------
// The uvm_objection is the callback type that defines the callback 
// implementations for an objection callback. A user uses the callback
// type uvm_objection_cbs_t to add callbacks to specific objections.
//
// For example:
//
//| class my_objection_cb extends uvm_objection_callback;
//|   function new(string name);
//|     super.new(name);
//|   endfunction
//|
//|   virtual function void raised (uvm_objection objection, uvm_object obj, 
//|       uvm_object source_obj, string description, int count);
//|     $display("%0t: Objection %s: Raised for %s", $time, objection.get_name(),
//|         obj.get_full_name());
//|   endfunction
//| endclass
//| ...
//| initial begin
//|   my_objection_cb cb = new("cb");
//|   uvm_objection_cbs_t::add(null, cb); //typewide callback
//| end


class uvm_objection_callback extends uvm_callback;
  function new(string name);
    super.new(name);
  endfunction

  // Function: raised
  //
  // Objection raised callback function. Called by <uvm_callbacks_objection::raised>.

  virtual function void raised (uvm_objection objection, uvm_object obj, 
      uvm_object source_obj, string description, int count);
  endfunction

  // Function: dropped
  //
  // Objection dropped callback function. Called by <uvm_callbacks_objection::dropped>.

  virtual function void dropped (uvm_objection objection, uvm_object obj, 
      uvm_object source_obj, string description, int count);
  endfunction

  // Function: all_dropped
  //
  // Objection all_dropped callback function. Called by <uvm_callbacks_objection::all_dropped>.

  virtual task all_dropped (uvm_objection objection, uvm_object obj, 
      uvm_object source_obj, string description, int count);
  endtask

endclass


`endif

