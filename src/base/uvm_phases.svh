//
//------------------------------------------------------------------------------
//   Copyright 2007-2011 Mentor Graphics Corporation
//   Copyright 2007-2011 Cadence Design Systems, Inc. 
//   Copyright 2011 Synopsys, Inc.
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
//------------------------------------------------------------------------------


//------------------------------------------------------------------------------
// TITLE: Phasing
//------------------------------------------------------------------------------
//
// UVM implements an automated mechanism for phasing the execution of
// the various components in a testbench.
//


//------------------------------------------------------------------------------
//
// Class: Pre-Defined Phases
//
//------------------------------------------------------------------------------
//
// This section describes the set of pre-defined phases
// provided as a standard part of the UVM library.
//
// Group: Common Phases
//
// The common phases are the set of function and task phases that all
// <uvm_component>s execute together.
// All <uvm_component>s are always synchronized
// with respect to the common phases.
//
// The common phases are executed in the sequence they are specified below.
//
// Class: uvm_build_phase
//
// Create and configure of testbench structure
//
// <uvm_topdown_phase> that calls the
// <uvm_component::build_phase> method.
//
// Upon entry:
//  - The top-level components have been instantiated under <uvm_root>.
//  - Current simulation time is still equal to 0 but some "delta cycles" may have occurred
//
// Typical Uses:
//  - Instantiate sub-components.
//  - Instantiate register model.
//  - Get configuration values for the component being built.
//  - Set configuration values for sub-components.
//
// Exit Criteria:
//  - All <uvm_component>s have been instantiated.
//
//
// Class: uvm_connect_phase
//
// Establish cross-component connections.
//
// <uvm_bottomup_phase> that calls the
// <uvm_component::connect_phase> method.
//
// Upon Entry:
// - All components have been instantiated.
// - Current simulation time is still equal to 0
//   but some "delta cycles" may have occurred.
//
// Typical Uses:
// - Connect TLM ports and exports.
// - Connect TLM initiator sockets and target sockets.
// - Connect register model to adapter components.
// - Setup explicit phase domains.
//
// Exit Criteria:
// - All cross-component connections have been established.
// - All independent phase domains are set.
//
//
// Class: uvm_end_of_elaboration_phase
//
// Fine-tune the testbench.
//
// <uvm_bottomup_phase> that calls the
// <uvm_component::end_of_elaboration_phase> method.
//
// Upon Entry:
// - The verification environment has been completely assembled.
// - Current simulation time is still equal to 0
//   but some "delta cycles" may have occurred.
//
// Typical Uses:
// - Display environment topology.
// - Open files.
// - Define additional configuration settings for components.
//
// Exit Criteria:
// - None.
//                              
//
// Class: uvm_start_of_simulation_phase
//
// Get ready for DUT to be simulated.
//
// <uvm_bottomup_phase> that calls the
// <uvm_component::start_of_simulation_phase> method.
//
// Upon Entry:
// - Other simulation engines, debuggers, hardware assisted platforms and
//   all other run-time tools have been started and synchronized.
// - The verification environment has been completely configured
//   and is ready to start.
// - Current simulation time is still equal to 0
//   but some "delta cycles" may have occurred.
//
// Typical Uses:
// - Display environment topology
// - Set debugger breakpoint
// - Set initial run-time configuration values.
//
// Exit Criteria:
// - None.
//
//
// Class: uvm_run_phase
//
// Stimulate the DUT.
//
// This <uvm_task_phase> calls the
// <uvm_component::run_phase> virtual method. This phase runs in
// parallel to the runtime phases, <uvm_pre_reset_ph> through
// <uvm_post_shutdown_ph>. All components in the testbench
// are synchronized with respect to the run phase regardles of
// the phase domain they belong to.
//
// Upon Entry:
// - Indicates that power has been applied.
// - There should not have been any active clock edges before entry
//   into this phase (e.g. x->1 transitions via initial blocks).
// - Current simulation time is still equal to 0
//   but some "delta cycles" may have occurred.
//
// Typical Uses:
// - Components implement behavior that is exhibited for the entire
//   run-time, across the various run-time phases.
// - Backward compatibility with OVM.
//
// Exit Criteria:
// - The DUT no longer needs to be simulated, and 
// - The <uvm_post_shutdown_ph> is ready to end
//
// The run phase terminates in one of four ways.
//
// 1. Explicit call to <global_stop_request>:
//
//   When <global_stop_request> is called, an ordered shut-down for the
//   run phase begins.
//   First, all enabled components' <uvm_component::stop> tasks 
//   are called bottom-up, i.e., childrens' <uvm_component::stop> tasks
//   are called before the parent's.
//
//   Stopping a component is enabled by its
//   <uvm_component::enable_stop_interrupt> bit.
//   Each component can implement <uvm_component::stop>
//   to allow completion of in-progress transactions, flush queues,
//   and other shut-down activities.
//   Upon return from <uvm_component::stop> by all enabled components,
//   the run phase becomes ready to end pending completion of the
//   runtime phases (i.e. the <uvm_post_shutdown_ph> being ready to
//   end.
//
//   If any component raised a phase objection in <uvm_component::run_phase()>,
//   this stopping procedure is deferred until all outstanding objections
//   have been dropped.
//
// 2. All run phase objections have been dropped after having been raised:
//
//   When all objections on the run phase objection have been dropped
//   by the <uvm_component::run_phase()> methods,
//   <global_stop_request> is called automatically, thus kicking off the
//   stopping procedure described above.
//
//   If no component ever raises a phase objection, this termination
//   mechanism never happens.
//   
//
// 3. Explicit call to <uvm_component::kill> or <uvm_component::do_kill_all>:
//
//   When <uvm_component::kill> is called,
//   that component's <uvm_component::run_phase> processes are killed
//   immediately.
//   The <uvm_component::do_kill_all> methods applies to the component
//   and all its descendants.
//
//   Use of this method is not recommended.
//   It is better to use the stopping mechanism, which affords a more ordered,
//   safer shut-down. If an immediate termination is desired, a 
//   <uvm_component::jump> to the <uvm_extract_ph> phase is recommended as
//   this will cause both the run phase and the parallel runtime phases to
//   immediately end and go to extract.
//
// 4. Timeout:
//
//   The phase ends if the timeout expires before an explicit call to
//   <global_stop_request> or <uvm_component::kill>.
//   By default, the timeout is set to 0, which is no timeout.
//   You may override this via <set_global_timeout>.
//
//   If a timeout occurs in your simulation, or if simulation never
//   ends despite completion of your test stimulus, then it usually indicates
//   a missing call to <global_stop_request>.
//
//
//
// Class: uvm_extract_phase
//
// Extract data from different points of the verficiation environment.
//
// <uvm_bottomup_phase> that calls the
// <uvm_component::extract_phase> method.
//
// Upon Entry:
// - The DUT no longer needs to be simulated.
// - Simulation time will no longer advance.
//
// Typical Uses:
// - Extract any remaining data and final state information
//   from scoreboard and testbench components
// - Probe the DUT (via zero-time hierarchical references
//   and/or backdoor accesses) for final state information.
// - Compute statistics and summaries.
// - Display final state information
// - Close files.
//
// Exit Criteria:
// - All data has been collected and summarized.
//
//
// Class: uvm_check_phase
//
// Check for any unexpected conditions in the verification environment.
//
// <uvm_bottomup_phase> that calls the
// <uvm_component::check_phase> method.
//
// Upon Entry:
// - All data has been collected.
//
// Typical Uses:
// - Check that no unaccounted-for data remain.
//
// Exit Criteria:
// - Test is known to have passed or failed.
//
//
// Class: uvm_report_phase
//
// Report results of the test.
//
// <uvm_bottomup_phase> that calls the
// <uvm_component::report_phase> method.
//
// Upon Entry:
// - Test is known to have passed or failed.
//
// Typical Uses:
// - Report test results.
// - Write results to file.
//
// Exit Criteria:
// - End of test.
//
//
// Class: uvm_final_phase
//
// Tie up loose ends.
//
// <uvm_topdown_phase> that calls the
// <uvm_component::final_phase> method.
//
// Upon Entry:
// - All test-related activity has completed.
//
// Typical Uses:
// - Close files.
// - Terminate co-simulation engines.
//
// Exit Criteria:
// - Ready to exit simulator.
//
//
// Group: Run-Time Phases
//
// The run-time schedule is the pre-defined phase schedule
// which runs concurrently to the <uvm_run_ph> global run phase.
// By default, all <uvm_component>s using the run-time schedule
// are synchronized with respect to the pre-defined phases in the schedule.
// It is possible for components to belong to different domains
// in which case their schedules can be unsynchronized.
//
// Class: uvm_pre_reset_phase
//
// Before reset is asserted.
//
// <uvm_task_phase> that calls the
// <uvm_component::pre_reset_phase> method. This phase starts at the
// same time as the <uvm_run_ph> unless a user defined phase is inserted
// in front of this phase.
//
// Upon Entry:
// - Indicates that power has been applied but not necessarily valid or stable.
// - There should not have been any active clock edges
//   before entry into this phase.
//
// Typical Uses:
// - Wait for power good.
// - Components connected to virtual interfaces should initialize
//   their output to X's or Z's.
// - Initialize the clock signals to a valid value
// - Assign reset signals to X (power-on reset).
// - Wait for reset signal to be asserted
//   if not driven by the verification environment.
//
// Exit Criteria:
// - Reset signal, if driven by the verification environment,
//   is ready to be asserted.
// - Reset signal, if not driven by the verification environment, is asserted.
//
//
// Class: uvm_reset_phase
//
// Reset is asserted.
//
// <uvm_task_phase> that calls the
// <uvm_component::reset_phase> method.
//
// Upon Entry:
// - Indicates that the hardware reset signal is ready to be asserted.
//
// Typical Uses:
// - Assert reset signals.
// - Components connected to virtual interfaces should drive their output
//   to their specified reset or idle value.
// - Components and environments should initialize their state variables.
// - Clock generators start generating active edges.
// - De-assert the reset signal(s)  just before exit.
// - Wait for the reset signal(s) to be de-asserted.
//
// Exit Criteria:
// - Reset signal has just been de-asserted.
// - Main or base clock is working and stable.
// - At least one active clock edge has occurred.
// - Output signals and state variables have been initialized.
//
//
// Class: uvm_post_reset_phase
//
// After reset is de-asserted.
//
// <uvm_task_phase> that calls the
// <uvm_component::post_reset_phase> method.
//
// Upon Entry:
// - Indicates that the DUT reset signal has been de-asserted.
//
// Typical Uses:
// - Components should start behavior appropriate for reset being inactive.
//   For example, components may start to transmit idle transactions
//   or interface training and rate negotiation.
//   This behavior typically continues beyond the end of this phase.
//
// Exit Criteria:
// - The testbench and the DUT are in a known, active state.
//
//
// Class: uvm_pre_configure_phase
//
// Before the DUT is configured by the SW.
//
// <uvm_task_phase> that calls the
// <uvm_component::pre_configure_phase> method.
//
// Upon Entry:
// - Indicates that the DUT has been completed reset
//  and is ready to be configured.
//
// Typical Uses:
// - Procedurally modify the DUT configuration information as described
//   in the environment (and that will be eventually uploaded into the DUT).
// - Wait for components required for DUT configuration to complete
//   training and rate negotiation.
//
// Exit Criteria:
// - DUT configuration information is defined.
//
//
// Class: uvm_configure_phase
//
// The SW configures the DUT.
//
// <uvm_task_phase> that calls the
// <uvm_component::configure_phase> method.
//
// Upon Entry:
// - Indicates that the DUT is ready to be configured.
//
// Typical Uses:
// - Components required for DUT configuration execute transactions normally.
// - Set signals and program the DUT and memories
//   (e.g. read/write operations and sequences)
//   to match the desired configuration for the test and environment.
//
// Exit Criteria:
// - The DUT has been configured and is ready to operate normally.
//
//
// Class: uvm_post_configure_phase
//
// After the SW has configured the DUT.
//
// <uvm_task_phase> that calls the
// <uvm_component::post_configure_phase> method. 
//
// Upon Entry:
// - Indicates that the configuration information has been fully uploaded.
//
// Typical Uses:
// - Wait for configuration information to fully propagate and take effect.
// - Wait for components to complete training and rate negotiation.
// - Enable the DUT.
// - Sample DUT configuration coverage.
//
// Exit Criteria:
// - The DUT has been fully configured and enabled
//   and is ready to start operating normally.
//
//
// Class: uvm_pre_main_phase
//
// Before the primary test stimulus starts.
//
// <uvm_task_phase> that calls the
// <uvm_component::pre_main_phase> method.
//
// Upon Entry:
// - Indicates that the DUT has been fully configured.
//
// Typical Uses:
// - Wait for components to complete training and rate negotiation.
//
// Exit Criteria:
// - All components have completed training and rate negotiation.
// - All components are ready to generate and/or observe normal stimulus.
//
//
// Class: uvm_main_phase
//
// Primary test stimulus.
//
// <uvm_task_phase> that calls the
// <uvm_component::main_phase> method.
//
// Upon Entry:
// - The stimulus associated with the test objectives is ready to be applied.
//
// Typical Uses:
// - Components execute transactions normally.
// - Data stimulus sequences are started.
// - Wait for a time-out or certain amount of time,
//   or completion of stimulus sequences.
//
// Exit Criteria:
// - Enough stimulus has been applied to meet the primary
//   stimulus objective of the test.
//
//
// Class: uvm_post_main_phase
//
// After enough of the primary test stimulus.
//
// <uvm_task_phase> that calls the
// <uvm_component::post_main_phase> method.
//
// Upon Entry:
// - The primary stimulus objective of the test has been met.
//
// Typical Uses:
// - Included for symmetry.
//
// Exit Criteria:
// - None.
//
//
// Class: uvm_pre_shutdown_phase
//
// Before things settle down.
//
// <uvm_task_phase> that calls the
// <uvm_component::pre_shutdown_phase> method.
//
// Upon Entry:
// - None.
//
// Typical Uses:
// - Included for symmetry.
//
// Exit Criteria:
// - None.
//
//
// Class: uvm_shutdown_phase
//
// Letting things settle down.
//
// <uvm_task_phase> that calls the
// <uvm_component::shutdown_phase> method.
//
// Upon Entry:
// - None.
//
// Typical Uses:
// - Wait for all data to be drained out of the DUT.
// - Extract data still buffered in the DUT,
//   usually through read/write operations or sequences.
//
// Exit Criteria:
// - All data has been drained or extracted from the DUT.
// - All interfaces are idle.
//
//
// Class: uvm_post_shutdown_phase
//
// After things have settled down.
//
// <uvm_task_phase> that calls the
// <uvm_component::post_shutdown_phase> method.  The end of this phase is
// synchronized to the end of the <uvm_run_ph> phase unless a user defined
// phase is added after this phase.
//
// Upon Entry:
// - No more "data" stimulus is applied to the DUT.
//
// Typical Uses:
// - Perform final checks that require run-time access to the DUT
//   (e.g. read accounting registers or dump the content of memories).
//
// Exit Criteria:
// - All run-time checks have been satisfied.
// - The <uvm_run_ph> phase is ready to end.
//
//


// Define classes and declare singletons called uvm_PHASE_ph for predefined phases

typedef class uvm_phase;
typedef class uvm_domain;

typedef class uvm_topdown_phase;
typedef class uvm_bottomup_phase;
typedef class uvm_task_phase;

`uvm_builtin_topdown_phase(build)
`uvm_builtin_bottomup_phase(connect)
`uvm_builtin_bottomup_phase(end_of_elaboration)
`uvm_builtin_bottomup_phase(start_of_simulation)

`uvm_builtin_task_phase(run)

`uvm_builtin_task_phase(pre_reset)
`uvm_builtin_task_phase(reset)
`uvm_builtin_task_phase(post_reset)
`uvm_builtin_task_phase(pre_configure)
`uvm_builtin_task_phase(configure)
`uvm_builtin_task_phase(post_configure)
`uvm_builtin_task_phase(pre_main)
`uvm_builtin_task_phase(main)
`uvm_builtin_task_phase(post_main)
`uvm_builtin_task_phase(pre_shutdown)
`uvm_builtin_task_phase(shutdown)
`uvm_builtin_task_phase(post_shutdown)

`uvm_builtin_bottomup_phase(extract)
`uvm_builtin_bottomup_phase(check)
`uvm_builtin_bottomup_phase(report)
`uvm_builtin_topdown_phase(final)


// For backward compatibility with OVM only! Use the uvm_ prefixed
// handles for each phase, e.g. uvm_build_ph. Or better yet, always
// use uvm_<phase>_phase::get() to access the singleton handle
// for a given <phase>.
uvm_phase build_ph ;
uvm_phase connect_ph ;
uvm_phase end_of_elaboration_ph ;
uvm_phase start_of_simulation_ph ;
uvm_phase run_ph ;
uvm_phase extract_ph ;
uvm_phase check_ph ;
uvm_phase report_ph ;




//------------------------------------------------------------------------------
//
// Class: User-Defined Phases
//
//------------------------------------------------------------------------------
//
// To defined your own custom phase, use the following pattern
//
// 1. extend the appropriate base class for your phase type
//|       class my_PHASE_phase extends uvm_task_phase("PHASE");
//|       class my_PHASE_phase extends uvm_topdown_phase("PHASE");
//|       class my_PHASE_phase extends uvm_bottomup_phase("PHASE");
//
// 2. implement your exec_task or exec_func method
//|       task exec_task(uvm_component comp, uvm_phase schedule);
//|       function void exec_func(uvm_component comp, uvm_phase schedule);
//
// 3. the implementation usually calls the related method on the component
//|          comp.PHASE_phase(uvm_phase phase);
//
// 4. after declaring your phase singleton class, instantiate one for global use
//|       static my_``PHASE``_phase my_``PHASE``_ph = new();
//
// 5. insert the phase in a phase schedule or domain using the
//    <uvm_phase::add> method inside your VIP base class's definition
//    of the <uvm_phase::define_domain> method.
//
//------------------------------------------------------------------------------


//-----------------------------------------------------------------------------
// Class: Phasing Implementation
//-----------------------------------------------------------------------------
//                                                                             
// The API described here provides a general purpose testbench phasing         
// solution, consisting of a phaser machine, traversing a master schedule      
// graph, which is built by the integrator from one or more instances of       
// template schedules provided by UVM or by 3rd-party VIP, and which supports  
// implicit or explicit synchronization, runtime control of threads and jumps. 
//                                                                             
// Each schedule leaf node refers to a single phase that is compatible with    
// that VIP's components and which executes the required behavior via a        
// functor or delegate extending the phase into component context as required. 
// Execution threads are tracked on a per-component basis and various thread   
// semantics available to allow defined phase control and responsibility.      
//                                                                             
//-----------------------------------------------------------------------------
//
//
//------------------------------------------------------------------------------
// Class hierarchy:
//------------------------------------------------------------------------------
//
// A single class represents both the definition, the state, and the context
// of a phase. It is instantiated once as a singleton IMP and one or more times
// as nodes in a graph which represents serial and parallel phase relationships
// and stores current state as the phaser progresses,
// and the phase implementation which specifies required component behavior
// (by extension into component context if non-default behavior required.)
//
// (see uvm_ref_phases_uml.gif)
//
// The following classes related to phasing are defined herein:
//
// <uvm_phase> : The base class for defining a phase's behavior, state, context
//
// <uvm_bottomup_phase> : A phase implemenation for bottom up function phases.
//
// <uvm_topdown_phase> : A phase implemenation for topdown function phases.
//
// <uvm_task_phase> : A phase implemenation for task phases.
//


typedef class uvm_test_done_objection;
typedef class uvm_sequencer_base;
typedef class uvm_process;

//------------------------------------------------------------------------------
//
// Class: uvm_phase
//
//------------------------------------------------------------------------------
//
// This base class defines everything about a phase: behavior, state, and context
//
// To define behavior, it is extended by UVM or the user to create singleton
// objects which capture the definition of what the phase does and how it does it.
// These are then cloned to produce multiple nodes which are hooked up in a graph
// structure to provide context: which phases follow which, and to hold the state
// of the phase throughout its lifetime.
// UVM provides default extensions of this class for the standard runtime phases.
// VIP Providers can likewise extend this class to define the phase functor for a
// particular component context as required.
//
// Phase Definition
//
// Singleton instances of those extensions are provided as package variables.
// These instances define the attributes of the phase (not what state it is in)
// They are then cloned into schedule nodes which point back to one of these
// implementations, and calls it's virtual task or function methods on each
// participating component.
// It is the base class for phase functors, for both predefined and
// user-defined phases. Per-component overrides can use a customized imp.
//
// To create custom phases, do not extend uvm_phase directly: see the
// three predefined extended classes below which encapsulate behavior for
// different phase types: task, bottom-up function and top-down function.
//
// Extend the appropriate one of these to create a uvm_YOURNAME_phase class
// (or YOURPREFIX_NAME_phase class) for each phase, containing the default
// implementation of the new phase, which must be a uvm_component-compatible
// delegate, and which may be a null implementation. Instantiate a singleton
// instance of that class for your code to use when a phase handle is required.
// If your custom phase depends on methods that are not in uvm_component, but
// are within an extended class, then extend the base YOURPREFIX_NAME_phase
// class with parameterized component class context as required, to create a
// specialized functor which calls your extended component class methods.
// This scheme ensures compile-safety for your extended component classes while
// providing homogeneous base types for APIs and underlying data structures.
//
// Phase Context
//
// A schedule is a coherent group of one or mode phase/state nodes linked
// together by a graph structure, allowing arbitrary linear/parallel
// relationships to be specified, and executed by stepping through them in
// the graph order.
// Each schedule node points to a phase and holds the execution state of that
// phase, and has optional links to other nodes for synchronization.
//
// The main build operations are: construct, add phases, and instantiate
// hierarchically within another schedule.
//
// Structure is a DAG (Directed Acyclic Graph). Each instance is a node
// connected to others to form the graph. Hierarchy is overlaid with m_parent.
// Each node in the graph has zero or more successors, and zero or more
// predecessors. No nodes are completely isolated from others. Exactly
// one node has zero predecessors. This is the root node. Also the graph
// is acyclic, meaning for all nodes in the graph, by following the forward
// arrows you will never end up back where you started but you will eventually
// reach a node that has no successors.
//
// Phase State
//
// A given phase may appear multiple times in the complete phase graph, due
// to the multiple independent domain feature, and the ability for different
// VIP to customize their own phase schedules perhaps reusing existing phases.
// Each node instance in the graph maintains its own state of execution.
//
// Phase Handle
//
// Handles of this type uvm_phase are used frequently in the API, both by
// the user, to access phasing-specific API, and also as a parameter to some
// APIs. In many cases, the singleton package-global phase handles can be
// used (eg. connect_ph, run_ph) in APIs. For those APIs that need to look
// up that phase in the graph, this is done automatically.



class uvm_phase extends uvm_object;

  //`uvm_object_utils(uvm_phase)


  //--------------------
  // Group: Construction
  //--------------------
  
  // Function: new
  //
  // Create a new phase node, with a name and a note of its type
  //   name   - name of this phase
  //   type   - task, topdown func or bottomup func
  //
  extern function new(string name="uvm_phase",
                      uvm_phase_type phase_type=UVM_PHASE_SCHEDULE,
                      uvm_phase parent=null);

  // Function: get_phase_type
  //
  // Returns the phase type as defined by <uvm_phase_type>
  //
  extern function uvm_phase_type get_phase_type();


  //-------------
  // Group: State
  //-------------

  // Function: get_state
  //
  // Accessor to return current state of this phase
  //
  extern function uvm_phase_state get_state();


  // Function: get_run_count
  //
  // Accessor to return the integer number of times this phase has executed
  //
  extern function int get_run_count();


  // Function: find_by_name
  //
  // Locate a phase node with the specified ~name~ and return its handle.
  // With ~stay_in_scope~ set, searches only within this phase's schedule or
  // domain.
  //
  extern function uvm_phase find_by_name(string name, bit stay_in_scope=1);


  // Function: find
  //
  // Locate the phase node with the specified ~phase~ IMP and return its handle.
  // With ~stay_in_scope~ set, searches only within this phase's schedule or
  // domain.
  //
  extern function uvm_phase find(uvm_phase phase, bit stay_in_scope=1);


  // Function: is
  //
  // returns 1 if the containing uvm_phase refers to the same phase
  // as the phase argument, 0 otherwise
  //
  extern function bit is(uvm_phase phase);


  // Function: is_before
  //
  // Returns 1 if the containing uvm_phase refers to a phase that is earlier
  // than the phase argument, 0 otherwise
  //
  extern function bit is_before(uvm_phase phase);


  // Function: is_after
  //
  // returns 1 if the containing uvm_phase refers to a phase that is later
  // than the phase argument, 0 otherwise
  //
  extern function bit is_after(uvm_phase phase);


  //-----------------
  // Group: Callbacks
  //-----------------

  // Function: exec_func
  //
  // Implements the functor/delegate functionality for a function phase type
  //   comp  - the component to execute the functionality upon
  //   phase - the phase schedule that originated this phase call
  //
  virtual function void exec_func(uvm_component comp, uvm_phase phase); endfunction


  // Function: exec_task
  //
  // Implements the functor/delegate functionality for a task phase type
  //   comp  - the component to execute the functionality upon
  //   phase - the phase schedule that originated this phase call
  //
  virtual task exec_task(uvm_component comp, uvm_phase phase); endtask



  //----------------
  // Group: Schedule
  //----------------

  // Function: add
  //
  // Build up a schedule structure inserting phase by phase, specifying linkage
  //
  // Phases can be added anywhere, in series or parallel with existing nodes
  //
  //   phase        - handle of singleton derived imp containing actual functor.
  //                  by default the new phase is appended to the schedule
  //   with_phase   - specify to add the new phase in parallel with this one
  //   after_phase  - specify to add the new phase as successor to this one
  //   before_phase - specify to add the new phase as predecessor to this one
  //
  extern function void add(uvm_phase phase,
                           uvm_phase with_phase=null,
                           uvm_phase after_phase=null,
                           uvm_phase before_phase=null);


  // Function: get_parent
  //
  // Returns the parent schedule node, if any, for hierarchical graph traversal
  //
  extern function uvm_phase get_parent();


  // Function: get_full_name
  //
  // Returns the full path from the enclosing domain down to this node.
  // The singleton IMP phases have no hierarchy.
  //
  extern virtual function string get_full_name();


  // Function: get_schedule
  //
  // Returns the topmost parent schedule node, if any, for hierarchical graph traversal
  //
  extern function uvm_phase get_schedule(bit hier=0);


  // Function: get_schedule_name
  //
  // Returns the schedule name associated with this phase node
  //
  extern function string get_schedule_name(bit hier=0);


  // Function: get_domain
  //
  // Returns the enclosing domain
  //
  extern function uvm_domain get_domain();


  // Function: get_imp
  //
  // Returns the phase implementation for this this node.
  // Returns null if this phase type is not a UVM_PHASE_LEAF_NODE. 
  //
  extern function uvm_phase get_imp();


  // Function: get_domain_name
  //
  // Returns the domain name associated with this phase node
  //
  extern function string get_domain_name();


  //-----------------------
  // Group: Synchronization
  //-----------------------

  // Function: get_objection
  //
  // Return the <uvm_objection> that gates the termination of the phase.
  //
  function uvm_objection get_objection(); return this.phase_done; endfunction


  // Function: raise_objection
  //
  // Raise an objection to ending this phase
  // Provides components with greater control over the phase flow for
  // processes which are not implicit objectors to the phase.
  //
  //|   while(1) begin
  //|     some_phase.raise_objection(this);
  //|     ...
  //|     some_phase.drop_objection(this);
  //|   end 
  //|   ...
  //
  extern virtual function void raise_objection (uvm_object obj, 
                                                string description="",
                                                int count=1);

  // Function: drop_objection
  //
  // Drop an objection to ending this phase
  //
  // The drop is expected to be matched with an earlier raise.
  //
  extern virtual function void drop_objection (uvm_object obj, 
                                               string description="",
                                               int count=1);


  // Functions: sync and unsync
  //
  // Add soft sync relationships between nodes
  //
  // Summary of usage:
  //| target::sync(.source(domain)
  //|              [,.phase(phase)[,.with_phase(phase)]]);
  //| target::unsync(.source(domain)
  //|                [,.phase(phase)[,.with_phase(phase)]]);
  //
  // Components in different schedule domains can be phased independently or in sync
  // with each other. An API is provided to specify synchronization rules between any
  // two domains. Synchronization can be done at any of three levels:
  //
  // - the domain's whole phase schedule can be synchronized
  // - a phase can be specified, to sync that phase with a matching counterpart
  // - or a more detailed arbitrary synchronization between any two phases
  //
  // Each kind of synchronization causes the same underlying data structures to
  // be managed. Like other APIs, we use the parameter dot-notation to set
  // optional parameters.
  //
  // When a domain is synced with another domain, all of the matching phases in
  // the two domains get a 'with' relationship between them. Likewise, if a domain
  // is unsynched, all of the matching phases that have a 'with' relationship have
  // the dependency removed. It is possible to sync two domains and then just
  // remove a single phase from the dependency relationship by unsyncing just
  // the one phase.


  // Function: sync
  //
  // Synchronize two domains, fully or partially
  //
  //   target       - handle of target domain to synchronize this one to
  //   phase        - optional single phase in this domain to synchronize, 
  //                  otherwise sync all
  //   with_phase   - optional different target-domain phase to synchronize with,
  //                  otherwise use ~phase~ in the target domain
  //
  extern function void sync(uvm_domain target,
                            uvm_phase phase=null,
                            uvm_phase with_phase=null);

  // Function: unsync
  //
  // Remove synchronization between two domains, fully or partially
  //
  //   target       - handle of target domain to remove synchronization from
  //   phase        - optional single phase in this domain to un-synchronize, 
  //                  otherwise unsync all
  //   with_phase   - optional different target-domain phase to un-synchronize with,
  //                  otherwise use ~phase~ in the target domain
  //
  extern function void unsync(uvm_domain target,
                              uvm_phase phase=null,
                              uvm_phase with_phase=null);


  // Function: wait_for_state
  //
  // Wait until this phase compares with the given ~state~ and ~op~ operand.
  // For <UVM_EQ> and <UVM_NE> operands, several <uvm_phase_states> can be
  // supplied by ORing their enum constants, in which case the caller will
  // wait until the phase state is any of (UVM_EQ) or none of (UVM_NE) the
  // provided states.
  //
  // To wait for the phase to be at the started state or after
  //
  //| wait_for_state(UVM_PHASE_STARTED, UVM_GT);
  //
  // To wait for the phase to be either started or executing
  //
  //| wait_for_state(UVM_PHASE_STARTED | UVM_PHASE_EXECUTING, UVM_EQ);
  //
  extern task wait_for_state(uvm_phase_state state, uvm_wait_op op=UVM_EQ);

   
  //---------------
  // Group: Jumping
  //---------------

  // Force phases to jump forward or backward in a schedule
  //
  // A phasing domain can execute a jump from its current phase to any other.
  // A jump passes phasing control in the current domain from the current phase
  // to a target phase. There are two kinds of jump scope:
  //
  // - local jump to another phase within the current schedule, back- or forwards
  // - global jump of all domains together, either to a point in the master
  //   schedule outwith the current schedule, or by calling jump_all()
  //
  // A jump preserves the existing soft synchronization, so the domain that is
  // ahead of schedule relative to another synchronized domain, as a result of
  // a jump in either domain, will await the domain that is behind schedule.
  //
  // *Note*: A jump out of the local schedule causes other schedules that have
  // the jump node in their schedule to jump as well. In some cases, it is
  // desirable to jump to a local phase in the schedule but to have all
  // schedules that share that phase to jump as well. In that situation, the
  // jump_all static function should be used. This function causes all schedules
  // that share a phase to jump to that phase.
 
  // Function: jump
  //
  // Jump to a specified ~phase~. If the destination ~phase~ is within the current 
  // phase schedule, a simple local jump takes place. If the jump-to ~phase~ is
  // outside of the current schedule then the jump affects other schedules which
  // share the phase.
  //
  extern function void jump(uvm_phase phase);


  // Function: jump_all
  //
  // Make all schedules jump to a specified ~phase~, even if the jump target is local.
  // The jump happens to all phase schedules that contain the jump-to ~phase~,
  // i.e. a global jump. 
  //
  extern static function void jump_all(uvm_phase phase);


  // Function: get_jump_target
  //
  // Return handle to the target phase of the current jump, or null if no jump
  // is in progress. Valid for use during the phase_ended() callback
  //
  extern function uvm_phase get_jump_target();


  int unsigned max_ready_to_end_iter = 20;

  //--------------------------
  // Internal - Implementation
  //--------------------------

  // Implementation - Construction
  //------------------------------
  protected uvm_phase_type m_phase_type;
  protected uvm_phase      m_parent;     // our 'schedule' node [or points 'up' one level]
  uvm_phase                m_imp;        // phase imp to call when we execute this node

  // Implementation - State
  //-----------------------
  local uvm_phase_state    m_state;
  local int                m_run_count; // num times this phase has executed
  local process            m_phase_proc;
  int                      m_num_procs_not_yet_returned;
  extern function uvm_phase m_find_predecessor(uvm_phase phase, bit stay_in_scope=1, uvm_phase orig_phase=null);
  extern function uvm_phase m_find_successor(uvm_phase phase, bit stay_in_scope=1, uvm_phase orig_phase=null);
  extern function uvm_phase m_find_predecessor_by_name(string name, bit stay_in_scope=1, uvm_phase orig_phase=null);
  extern function uvm_phase m_find_successor_by_name(string name, bit stay_in_scope=1, uvm_phase orig_phase=null);
  extern function void m_print_successors();

  // Implementation - Callbacks
  //---------------------------
  // Provide the required component traversal behavior. Called by execute()
  virtual function void traverse(uvm_component comp,
                                 uvm_phase phase,
                                 uvm_phase_state state);
  endfunction
  // Provide the required per-component execution flow. Called by traverse()
  virtual function void execute(uvm_component comp,
                                 uvm_phase phase);
  endfunction

  // Implementation - Schedule
  //--------------------------
  protected bit  m_predecessors[uvm_phase];
  protected bit  m_successors[uvm_phase];
  //protected uvm_phase m_begin_node;
  protected uvm_phase m_end_node;
  function uvm_phase get_begin_node(); if (m_imp != null) return this; return null; endfunction
  function uvm_phase get_end_node();   return m_end_node; endfunction

  // Implementation - Synchronization
  //---------------------------------
  local uvm_phase m_sync[$];  // schedule instance to which we are synced
  uvm_objection phase_done; // phase done objection
  local int unsigned m_ready_to_end_count;

  function int unsigned get_ready_to_end_count();
     return m_ready_to_end_count;
  endfunction

  // Implementation - Jumping
  //-------------------------
  local bit                m_jump_bkwd;
  local bit                m_jump_fwd;
  local uvm_phase          m_jump_phase;
  extern function void clear(uvm_phase_state state = UVM_PHASE_DORMANT);
  extern function void clear_successors(
                             uvm_phase_state state = UVM_PHASE_DORMANT);

  // Implementation - Overall Control
  //---------------------------------
  local static mailbox #(uvm_phase) m_phase_hopper = new();
  local static uvm_process m_phase_top_procs[uvm_phase];
  //static bit m_has_rt_phases; //TBD access?

  extern static task m_run_phases();
  extern local task  execute_phase();
  extern local function void m_terminate_phase();
  extern local function void m_print_termination_state();
  extern function void kill();
  extern function void kill_successors();

  // TBD add more useful debug
  //---------------------------------
  protected static bit m_phase_trace;
  local static bit m_use_ovm_run_semantic;


  function string convert2string();
  //return $sformatf("PHASE %s = %p",get_name(),this);
  string s;
    s = $sformatf("phase: %s parent=%s  pred=%s  succ=%s",get_name(),
                     (m_parent==null) ? "null" : get_schedule_name(),
                     m_aa2string(m_predecessors),
                     m_aa2string(m_successors));
      //if (m_begin_node != null) 
      //  s = {s, "\n  m_begin_node=",m_begin_node.convert2string()};
    return s;
  endfunction

  local function string m_aa2string(bit aa[uvm_phase]); // TBD tidy
    string s;
    int i;
    s = "'{ ";
    foreach (aa[ph]) begin
      uvm_phase n = ph;
      s = {s, (n == null) ? "null" : n.get_name(),
        (i == aa.num()-1) ? "" : ", "};
      i++;
    end
    s = {s, " }"};
    return s;
  endfunction

  function bit is_domain();
    return (m_phase_type == UVM_PHASE_DOMAIN);
  endfunction

endclass



//------------------------------------------------------------------------------
//                               IMPLEMENTATION
//------------------------------------------------------------------------------

typedef class uvm_cmdline_processor;

`define PH_TRACE(ID,MSG,PH,VERB) \
   `uvm_info(ID, {MSG, $sformatf(" %0s (in schedule %0s, domain %s) id=%0d", \
       PH.get_name(), PH.get_schedule_name(), PH.get_domain_name(), PH.get_inst_id())}, VERB);

//-----------------------------
// Implementation - Construction
//-----------------------------

// new

function uvm_phase::new(string name="uvm_phase",
                        uvm_phase_type phase_type=UVM_PHASE_SCHEDULE,
                        uvm_phase parent=null);
  string trace_args[$];
  uvm_cmdline_processor clp;

  super.new(name);
  m_phase_type = phase_type;

  if (name == "run")
    phase_done = uvm_test_done_objection::get();
  else begin
    phase_done = new(name);
  end

  m_state = UVM_PHASE_DORMANT;
  m_run_count = 0;
  m_parent = parent;

  if (parent == null && (phase_type == UVM_PHASE_SCHEDULE ||
                         phase_type == UVM_PHASE_DOMAIN )) begin
    //m_parent = this;
    m_end_node = new({name,"_end"}, UVM_PHASE_TERMINAL, this);
    this.m_successors[m_end_node] = 1;
    m_end_node.m_predecessors[this] = 1;
  end

endfunction


// add
// ---
// TBD error checks if param nodes are actually in this schedule or not

function void uvm_phase::add(uvm_phase phase,
                             uvm_phase with_phase=null,
                             uvm_phase after_phase=null,
                             uvm_phase before_phase=null);
  uvm_phase new_node, begin_node, end_node;
  assert(phase != null);

  if (with_phase != null && with_phase.get_phase_type() == UVM_PHASE_IMP) begin
    string nm = with_phase.get_name();
    with_phase = find(with_phase);
    if (with_phase == null)
      `uvm_fatal("PH_BAD_ADD",
         {"cannot find with_phase '",nm,"' within node '",get_name(),"'"})
  end

  if (before_phase != null && before_phase.get_phase_type() == UVM_PHASE_IMP) begin
    string nm = before_phase.get_name();
    before_phase = find(before_phase);
    if (before_phase == null)
      `uvm_fatal("PH_BAD_ADD",
         {"cannot find before_phase '",nm,"' within node '",get_name(),"'"})
  end

  if (after_phase != null && after_phase.get_phase_type() == UVM_PHASE_IMP) begin
    string nm = after_phase.get_name();
    after_phase = find(after_phase);
    if (after_phase == null)
      `uvm_fatal("PH_BAD_ADD",
         {"cannot find after_phase '",nm,"' within node '",get_name(),"'"})
  end

  if (with_phase != null && (after_phase != null || before_phase != null))
    `uvm_fatal("PH_BAD_ADD",
       "cannot specify both 'with' and 'before/after' phase relationships")

  if (before_phase == this || after_phase == m_end_node || with_phase == m_end_node)
    `uvm_fatal("PH_BAD_ADD",
       "cannot add before begin node, after end node, or with end nodes")

  // If we are inserting a new "leaf node"
  if (phase.get_phase_type() == UVM_PHASE_IMP) begin
    new_node = new(phase.get_name(),UVM_PHASE_NODE,this);
    new_node.m_imp = phase;
    begin_node = new_node;
    end_node = new_node;
  end
  // We are inserting an existing schedule
  else begin
    begin_node = phase;
    end_node   = phase.m_end_node;
    phase.m_parent = this;
  end

  // If 'with_phase' is us, then insert node in parallel
  /*
  if (with_phase == this) begin
    after_phase = this;
    before_phase = m_end_node;
  end
  */

  // If no before/after/with specified, insert at end of this schedule
  if (with_phase == null && after_phase == null && before_phase == null) begin
    before_phase = m_end_node;
  end


  if (m_phase_trace) begin
    uvm_phase_type typ = phase.get_phase_type();
    `uvm_info("PH/TRC/ADD_PH",
      {get_name()," (",m_phase_type.name(),") ADD_PHASE: phase=",phase.get_full_name()," (",
      typ.name(),", inst_id=",$sformatf("%0d",phase.get_inst_id()),")",
      " with_phase=",   (with_phase == null)   ? "null" : with_phase.get_name(), 
      " after_phase=",  (after_phase == null)  ? "null" : after_phase.get_name(),
      " before_phase=", (before_phase == null) ? "null" : before_phase.get_name(), 
      " new_node=",     (new_node == null)     ? "null" : {new_node.get_name(),
                                                           " inst_id=",
                                                           $sformatf("%0d",new_node.get_inst_id())},
      " begin_node=",   (begin_node == null)   ? "null" : begin_node.get_name(),
      " end_node=",     (end_node == null)     ? "null" : end_node.get_name()},UVM_DEBUG)
  end


  // INSERT IN PARALLEL WITH 'WITH' PHASE
  if (with_phase != null) begin
    begin_node.m_predecessors = with_phase.m_predecessors;
    end_node.m_successors = with_phase.m_successors;
    foreach (with_phase.m_predecessors[pred])
      pred.m_successors[begin_node] = 1;
    foreach (with_phase.m_successors[succ])
      succ.m_predecessors[end_node] = 1;
  end
  
  
  // INSERT BEFORE PHASE
  else if (before_phase != null && after_phase == null) begin
    begin_node.m_predecessors = before_phase.m_predecessors;
    end_node.m_successors[before_phase] = 1;
    foreach (before_phase.m_predecessors[pred]) begin
      pred.m_successors.delete(before_phase);
      pred.m_successors[begin_node] = 1;
    end
    before_phase.m_predecessors.delete();
    before_phase.m_predecessors[end_node] = 1;
  end
  

  // INSERT AFTER PHASE
  else if (before_phase == null && after_phase != null) begin
    end_node.m_successors = after_phase.m_successors;
    begin_node.m_predecessors[after_phase] = 1;
    foreach (after_phase.m_successors[succ]) begin
      succ.m_predecessors.delete(after_phase);
      succ.m_predecessors[end_node] = 1;
    end
    after_phase.m_successors.delete();
    after_phase.m_successors[begin_node] = 1;
  end
  

  // IN BETWEEN 'BEFORE' and 'AFTER' PHASES
  else if (before_phase != null && after_phase != null) begin
    if (!after_phase.is_before(before_phase)) begin
      `uvm_fatal("PH_ADD_PHASE",{"Phase '",before_phase.get_name(),
                 "' is not before phase '",after_phase.get_name(),"'"})
    end
    // before and after? add 1 pred and 1 succ
    begin_node.m_predecessors[after_phase] = 1;
    end_node.m_successors[before_phase] = 1;
    after_phase.m_successors[begin_node] = 1;
    before_phase.m_predecessors[end_node] = 1;
    if (after_phase.m_successors.exists(before_phase)) begin
      after_phase.m_successors.delete(before_phase);
      before_phase.m_successors.delete(after_phase);
    end
  end

endfunction


// get_parent
// ----------

function uvm_phase uvm_phase::get_parent();
  return m_parent;
endfunction


// get_imp
// -------

function uvm_phase uvm_phase::get_imp();
  return m_imp;
endfunction


// get_schedule
// ------------

function uvm_phase uvm_phase::get_schedule(bit hier=0);
  uvm_phase sched;
  sched = this;
  if (hier)
    while (sched.m_parent != null && (sched.m_parent.get_phase_type() == UVM_PHASE_SCHEDULE))
      sched = sched.m_parent;
  if (sched.m_phase_type == UVM_PHASE_SCHEDULE)
    return sched;
  if (sched.m_phase_type == UVM_PHASE_NODE)
    if (m_parent != null && m_parent.m_phase_type != UVM_PHASE_DOMAIN)
      return m_parent;
  return null;
endfunction


// get_domain
// ----------

function uvm_domain uvm_phase::get_domain();
  uvm_phase phase;
  phase = this;
  while (phase != null && phase.m_phase_type != UVM_PHASE_DOMAIN)
    phase = phase.m_parent;
  if (phase == null) // no parent domain 
    return null;
  assert($cast(get_domain,phase));
endfunction


// get_domain_name
// ---------------
  
function string uvm_phase::get_domain_name();
  uvm_domain domain;
  domain = get_domain();
  if (domain == null)
    return "unknown";
  return domain.get_name();
endfunction


// get_schedule_name
// -----------------
  
function string uvm_phase::get_schedule_name(bit hier=0);
  uvm_phase sched;
  string s;
  sched = get_schedule(hier);
  if (sched == null)
    return "";
  s = sched.get_name();
  while (sched.m_parent != null && sched.m_parent != sched &&
          (sched.m_parent.get_phase_type() == UVM_PHASE_SCHEDULE)) begin
    sched = sched.m_parent;
    s = {sched.get_name(),(s.len()>0?".":""),s};
  end
  return s;
endfunction


// get_full_name
// -------------

function string uvm_phase::get_full_name();
  string dom, sch;
  if (m_phase_type == UVM_PHASE_IMP)
    return get_name();
  get_full_name = get_domain_name();
  sch = get_schedule_name();
  if (sch != "")
    get_full_name = {get_full_name, ".", sch};
  if (m_phase_type == UVM_PHASE_NODE)
    get_full_name = {get_full_name, ".", get_name()};
endfunction


// get_phase_type
// --------------

function uvm_phase_type uvm_phase::get_phase_type();
  return m_phase_type;
endfunction


//-----------------------
// Implementation - State
//-----------------------

// get_state
// ---------

function uvm_phase_state uvm_phase::get_state();
  return m_state;
endfunction

// get_run_count
// -------------

function int uvm_phase::get_run_count();
  return m_run_count;
endfunction


// m_print_successors
// ------------------

function void uvm_phase::m_print_successors();
  uvm_phase found;
  static string spaces = "                                                 ";
  static int level = 0;
  if (m_phase_type == UVM_PHASE_DOMAIN)
    level = 0;
  $display(spaces.substr(0,level*2),get_name(), " (",m_phase_type.name(),") id=%0d",get_inst_id());
  level++;
  foreach (m_successors[succ]) begin
    succ.m_print_successors();
  end
  level--;
endfunction


// m_find_predecessor
// ------------------

function uvm_phase uvm_phase::m_find_predecessor(uvm_phase phase, bit stay_in_scope=1, uvm_phase orig_phase=null);
  uvm_phase found;
  //$display("  FIND PRED node '",phase.get_name(),"' (id=",$sformatf("%0d",phase.get_inst_id()),") - checking against ",get_name()," (",m_phase_type.name()," id=",$sformatf("%0d",get_inst_id()),(m_imp==null)?"":{"/",$sformatf("%0d",m_imp.get_inst_id())},")");
  if (phase == m_imp || phase == this)
    return this;
  foreach (m_predecessors[pred]) begin
    uvm_phase orig;
    orig = (orig_phase==null) ? this : orig_phase;
    if (!stay_in_scope || 
        (pred.get_schedule() == orig.get_schedule()) ||
        (pred.get_domain() == orig.get_domain())) begin
      found = pred.m_find_predecessor(phase,stay_in_scope,orig);
      if (found != null)
        return found;
    end
  end
  return null;
endfunction


// m_find_predecessor_by_name
// --------------------------

function uvm_phase uvm_phase::m_find_predecessor_by_name(string name, bit stay_in_scope=1, uvm_phase orig_phase=null);
  uvm_phase found;
  //$display("  FIND PRED node '",name,"' - checking against ",get_name()," (",m_phase_type.name()," id=",$sformatf("%0d",get_inst_id()),(m_imp==null)?"":{"/",$sformatf("%0d",m_imp.get_inst_id())},")");
  if (get_name() == name)
    return this;
  foreach (m_predecessors[pred]) begin
    uvm_phase orig;
    orig = (orig_phase==null) ? this : orig_phase;
    if (!stay_in_scope || 
        (pred.get_schedule() == orig.get_schedule()) ||
        (pred.get_domain() == orig.get_domain())) begin
      found = pred.m_find_predecessor_by_name(name,stay_in_scope,orig);
      if (found != null)
        return found;
    end
  end
  return null;
endfunction


// m_find_successor
// ----------------

function uvm_phase uvm_phase::m_find_successor(uvm_phase phase, bit stay_in_scope=1, uvm_phase orig_phase=null);
  uvm_phase found;
  //$display("  FIND SUCC node '",phase.get_name(),"' (id=",$sformatf("%0d",phase.get_inst_id()),") - checking against ",get_name()," (",m_phase_type.name()," id=",$sformatf("%0d",get_inst_id()),(m_imp==null)?"":{"/",$sformatf("%0d",m_imp.get_inst_id())},")");
  if (phase == m_imp || phase == this) begin
    return this;
    end
  foreach (m_successors[succ]) begin
    uvm_phase orig;
    orig = (orig_phase==null) ? this : orig_phase;
    if (!stay_in_scope || 
        (succ.get_schedule() == orig.get_schedule()) ||
        (succ.get_domain() == orig.get_domain())) begin
      found = succ.m_find_successor(phase,stay_in_scope,orig);
      if (found != null) begin
        return found;
        end
    end
  end
  return null;
endfunction


// m_find_successor_by_name
// ------------------------

function uvm_phase uvm_phase::m_find_successor_by_name(string name, bit stay_in_scope=1, uvm_phase orig_phase=null);
  uvm_phase found;
  //$display("  FIND SUCC node '",name,"' - checking against ",get_name()," (",m_phase_type.name()," id=",$sformatf("%0d",get_inst_id()),(m_imp==null)?"":{"/",$sformatf("%0d",m_imp.get_inst_id())},")");
  if (get_name() == name)
    return this;
  foreach (m_successors[succ]) begin
    uvm_phase orig;
    orig = (orig_phase==null) ? this : orig_phase;
    if (!stay_in_scope || 
        (succ.get_schedule() == orig.get_schedule()) ||
        (succ.get_domain() == orig.get_domain())) begin
      found = succ.m_find_successor_by_name(name,stay_in_scope,orig);
      if (found != null)
        return found;
    end
  end
  return null;
endfunction


// find
// ----

function uvm_phase uvm_phase::find(uvm_phase phase, bit stay_in_scope=1);
  // TBD full search
  //$display({"\nFIND node '",phase.get_name(),"' within ",get_name()," (scope ",m_phase_type.name(),")", (stay_in_scope) ? " staying within scope" : ""});
  if (phase == m_imp || phase == this)
    return phase;
  find = m_find_predecessor(phase,stay_in_scope,this);
  if (find == null)
    find = m_find_successor(phase,stay_in_scope,this);
endfunction


// find_by_name
// ------------

function uvm_phase uvm_phase::find_by_name(string name, bit stay_in_scope=1);
  // TBD full search
  //$display({"\nFIND node named '",name,"' within ",get_name()," (scope ",m_phase_type.name(),")", (stay_in_scope) ? " staying within scope" : ""});
  if (get_name() == name)
    return this;
  find_by_name = m_find_predecessor_by_name(name,stay_in_scope,this);
  if (find_by_name == null)
    find_by_name = m_find_successor_by_name(name,stay_in_scope,this);
endfunction


// is
// --
  
function bit uvm_phase::is(uvm_phase phase);
  return (m_imp == phase || this == phase); 
endfunction

  
// is_before
// ---------

function bit uvm_phase::is_before(uvm_phase phase);
  //$display("this=%s is before phase=%s?",get_name(),phase.get_name());
  // TODO: add support for 'stay_in_scope=1' functionality
  return (!is(phase) && m_find_successor(phase,0,this) != null);
endfunction


// is_after
// --------
  
function bit uvm_phase::is_after(uvm_phase phase);
  //$display("this=%s is after phase=%s?",get_name(),phase.get_name());
  // TODO: add support for 'stay_in_scope=1' functionality
  return (!is(phase) && m_find_predecessor(phase,0,this) != null);
endfunction


// execute_phase
// -------------

task uvm_phase::execute_phase();

  uvm_root top;
  top = uvm_root::get();

  // If we got here by jumping forward, we must wait for
  // all its predecessor nodes to be marked DONE.
  // (the next conditional speeds this up)
  foreach (m_predecessors[pred]) begin
    wait (pred.m_state == UVM_PHASE_DONE);
  end


  // If DONE (by, say, a forward jump), return immed
  if (m_state == UVM_PHASE_DONE)
    return;
  

  //---------
  // SYNCING:
  //---------
  // Wait for phases with which we have a sync()
  // relationship to be ready. Sync can be 2-way -
  // this additional state avoids deadlock.
  if (m_sync.size()) begin
    m_state = UVM_PHASE_SYNCING;
    foreach (m_sync[i]) begin
      wait (m_sync[i].m_state >= UVM_PHASE_SYNCING);
    end
  end

  m_run_count++;


  if (m_phase_trace) begin
    `PH_TRACE("PH/TRC/STRT","Starting phase",this,UVM_LOW)
  end


  // If we're a schedule or domain, then "fake" execution
  if (m_phase_type != UVM_PHASE_NODE) begin
    m_state = UVM_PHASE_STARTED;
    #0;
    m_state = UVM_PHASE_EXECUTING;
    #0;
  end


  else begin // PHASE NODE
    uvm_task_phase task_phase;

    // TODO: Find out why needed on VCS; this may overwrite any apriori
    //       raised objections for the run phase
    if (get_name() == "run")
      phase_done = uvm_test_done_objection::get();

    //---------
    // STARTED:
    //---------
    m_state = UVM_PHASE_STARTED;
    #0; // LET ANY WAITERS WAKE UP
    m_imp.traverse(top,this,UVM_PHASE_STARTED);


    //if (m_imp.get_phase_type() != UVM_PHASE_TASK) begin
    if (!$cast(task_phase,m_imp)) begin

      //-----------
      // EXECUTING: (function phases)
      //-----------
      m_state = UVM_PHASE_EXECUTING;
      #0; // LET ANY WAITERS WAKE UP
      m_imp.traverse(top,this,UVM_PHASE_EXECUTING);

    end
    else begin

        fork : master_phase_process
          begin
  
            m_phase_proc = process::self();
  
            //-----------
            // EXECUTING: (task phases)
            //-----------
            m_state = UVM_PHASE_EXECUTING;
            task_phase.traverse(top,this,UVM_PHASE_EXECUTING);
  
            wait(0); // stay alive for later kill
  
          end
        join_none
  
        uvm_wait_for_nba_region(); //Give sequences, etc. a chance to object
  
        // Now wait for one of three criterion for end-of-phase.
        fork
        begin // guard
          
          do begin

           fork
  
             // WAIT_FOR_ALL_DROPPED
             begin
               // OVM semantic: don't end until objection raised or stop request
               if (phase_done.get_objection_total(top) ||
                   m_use_ovm_run_semantic && m_imp.get_name() == "run") begin
                 phase_done.wait_for(UVM_ALL_DROPPED, top);
                 `PH_TRACE("PH/TRC/EXE/ALLDROP","PHASE EXIT ALL_DROPPED",this,UVM_DEBUG)
               end
               else begin
                  if (m_phase_trace)
                    `PH_TRACE("PH/TRC/SKIP","No objections raised, skipping phase",this,UVM_LOW)
               end
             end
  
             // TIMEOUT
             begin
               if (top.phase_timeout == 0)
                 wait(top.phase_timeout != 0);
               `uvm_delay(top.phase_timeout)
               if ($time == `UVM_DEFAULT_TIMEOUT) begin
                 `uvm_error("PH_TIMEOUT",
                     $sformatf("Default phase timeout of %0t hit. All processes are waiting, indicating a probable testbench issue. Phase '%0s' ready to end",
                             top.phase_timeout, get_name()))
               end
               else begin
                 `uvm_error("PH_TIMEOUT",
                     $sformatf("Phase timeout of %0t hit, phase '%0s' ready to end",
                             top.phase_timeout, get_name()))
               end
               phase_done.clear(this);
               `PH_TRACE("PH/TRC/EXE/3","PHASE EXIT TIMEOUT",this,UVM_DEBUG)
             end
  
           join_any
           disable fork;
        
           phase_done.clear();
           m_ready_to_end_count++;
           if (m_ready_to_end_count < max_ready_to_end_iter) begin
             if (m_phase_trace)
               `PH_TRACE("PH_READY_TO_END_CB","CALLING READY_TO_END CB",this,UVM_HIGH)
             if (m_imp != null)
               m_imp.traverse(top,this,UVM_PHASE_READY_TO_END);
             #0; // LET ANY WAITERS WAKE UP
           end
    
          end
          while (phase_done.get_objection_total(top));
  
        end
        join // guard

    end

  end

  //--------------
  // READY_TO_END:
  //--------------

  `PH_TRACE("PH_READY_TO_END","PHASE READY TO END",this,UVM_DEBUG)
  m_state = UVM_PHASE_READY_TO_END;


  //---------
  // JUMPING:
  //---------

  // If jump_to() was called then we need to kill all the successor
  // phases which may still be running and then initiate the new
  // phase.  The return is necessary so we don't start new successor
  // phases.  If we are doing a forward jump then we want to set the
  // state of this phase's successors to UVM_PHASE_DONE.  This
  // will let us pretend that all the phases between here and there
  // were executed and completed.  Thus any dependencies will be
  // satisfied preventing deadlocks.
  // GSA TBD insert new jump support

  if(m_jump_fwd || m_jump_bkwd) begin

    #0; // LET ANY WAITERS ON READY_TO_END TO WAKE UP

    // execute 'phase_ended' callbacks
    if (m_phase_trace)
      `PH_TRACE("PH_END","JUMPING OUT OF PHASE",this,UVM_HIGH)
    m_state = UVM_PHASE_ENDED;
    if (m_imp != null)
       m_imp.traverse(top,this,UVM_PHASE_ENDED);
    #0; // LET ANY WAITERS WAKE UP

    m_state = UVM_PHASE_JUMPING;
    if (m_phase_proc != null) begin
      m_phase_proc.kill();
      m_phase_proc = null;
    end
    #0; // LET ANY WAITERS WAKE UP

    if(m_jump_fwd) begin
      clear_successors(UVM_PHASE_DONE);
    end
    m_jump_phase.clear_successors();
    m_jump_fwd = 0;
    m_jump_bkwd = 0;
    void'(m_phase_hopper.try_put(m_jump_phase));
    m_jump_phase = null;
    m_phase_top_procs.delete(this);
    return;
  end

  //-----------------------
  // WAIT FOR PREDECESSORS:
  //-----------------------
  begin
    bit pred_of_succ[uvm_phase];

    foreach (m_successors[succ]) begin
      foreach(succ.m_predecessors[pred]) begin
        uvm_phase p;
        p = uvm_phase'(pred);
        pred_of_succ[ p ] = 1;
      end
    end
    pred_of_succ.delete(this);

    foreach (pred_of_succ[sibling]) begin
      //$display("  ** ", get_name(), " (",get_inst_id(),")",
      //         "Waiting for phase '",sibling.get_name(),"' (",sibling.get_inst_id(),
      //         ") to be ready to end that phase's current state is ",sibling.m_state.name());
      sibling.wait_for_state(UVM_PHASE_READY_TO_END, UVM_GTE);
      //$display("  ** ", get_name(), " (",get_inst_id(),")",
      //         "Released: Phase '", sibling.get_name(),"' is now ready to end");
    end
    //$display("  ** ", get_name(), " (",get_inst_id(),")",
    //         "All pred to succ ready to end, so ending this phase");
  end
  #0; // LET ANY WAITERS WAKE UP


  //-------
  // ENDED:
  //-------
  // execute 'phase_ended' callbacks
  if (m_phase_trace)
    `PH_TRACE("PH_END","ENDING PHASE",this,UVM_HIGH)
  m_state = UVM_PHASE_ENDED;
  if (m_imp != null)
    m_imp.traverse(top,this,UVM_PHASE_ENDED);
  #0; // LET ANY WAITERS WAKE UP


  //---------
  // CLEANUP:
  //---------
  // kill this phase's threads
  m_state = UVM_PHASE_CLEANUP;
  if (m_phase_proc != null) begin
    m_phase_proc.kill();
    m_phase_proc = null;
  end
  #0; // LET ANY WAITERS WAKE UP



  //------
  // DONE:
  //------
  if (m_phase_trace)
    `PH_TRACE("PH/TRC/DONE","Completed phase",this,UVM_LOW)
  m_state = UVM_PHASE_DONE;
  m_phase_proc = null;
  #0; // LET ANY WAITERS WAKE UP



  //-----------
  // SCHEDULED:
  //-----------
  // If more successors, schedule them to run now
  m_phase_top_procs.delete(this);
  if (m_successors.size() == 0) begin
    top.m_phase_all_done=1;
  end 
  else begin
    // execute all the successors
    foreach (m_successors[succ]) begin
      if(succ.m_state != UVM_PHASE_SCHEDULED) begin
        succ.m_state = UVM_PHASE_SCHEDULED;
          #0; // LET ANY WAITERS WAKE UP
        if (m_phase_trace)
          `PH_TRACE("PH/TRC/SCHEDULED","Scheduling phase",succ,UVM_LOW)
        void'(m_phase_hopper.try_put(succ));
      end
    end
  end

endtask


//---------------------------------
// Implementation - Synchronization
//---------------------------------

// raise_objection
// ---------------

function void uvm_phase::raise_objection (uvm_object obj, 
                                                   string description="",
                                                   int count=1);
  phase_done.raise_objection(obj,description,count);
endfunction


// drop_objection
// --------------

function void uvm_phase::drop_objection (uvm_object obj, 
                                                  string description="",
                                                  int count=1);
  phase_done.drop_objection(obj,description,count);
endfunction


// sync
// ----

function void uvm_phase::sync(uvm_domain target,
                              uvm_phase phase=null,
                              uvm_phase with_phase=null);
  if (!this.is_domain()) begin
    `uvm_fatal("PH_BADSYNC","sync() called from a non-domain phase schedule node");
  end
  else if (target == null) begin
    `uvm_fatal("PH_BADSYNC","sync() called with a null target domain");
  end
  else if (!target.is_domain()) begin
    `uvm_fatal("PH_BADSYNC","sync() called with a non-domain phase schedule node as target");
  end
  else if (phase == null && with_phase != null) begin
    `uvm_fatal("PH_BADSYNC","sync() called with null phase and non-null with phase");
  end
  else if (phase == null) begin
    // whole domain sync - traverse this domain schedule from begin to end node and sync each node
    int visited[uvm_phase];
    uvm_phase queue[$];
    queue.push_back(this);
    visited[this] = 1;
    while (queue.size()) begin
      uvm_phase node;
      node = queue.pop_front();
      if (node.m_imp != null) begin
        sync(target, node.m_imp);
      end
      foreach (node.m_successors[succ]) begin
        if (!visited.exists(succ)) begin
          queue.push_back(succ);
          visited[succ] = 1;
        end
      end
    end
  end else begin
    // single phase sync
    // this is a 2-way ('with') sync and we check first in case it is already there
    uvm_phase from_node, to_node;
    int found_to[$], found_from[$];
    if(with_phase == null) with_phase = phase;
    from_node = find(phase);
    to_node = target.find(with_phase);
    if(from_node == null || to_node == null) return;
    found_to = from_node.m_sync.find_index(node) with (node == to_node);
    found_from = to_node.m_sync.find_index(node) with (node == from_node);
    if (found_to.size() == 0) from_node.m_sync.push_back(to_node);
    if (found_from.size() == 0) to_node.m_sync.push_back(from_node);
  end
endfunction


// unsync
// ------

function void uvm_phase::unsync(uvm_domain target,
                                uvm_phase phase=null,
                                uvm_phase with_phase=null);
  if (!this.is_domain()) begin
    `uvm_fatal("PH_BADSYNC","unsync() called from a non-domain phase schedule node");
  end else if (target == null) begin
    `uvm_fatal("PH_BADSYNC","unsync() called with a null target domain");
  end else if (!target.is_domain()) begin
    `uvm_fatal("PH_BADSYNC","unsync() called with a non-domain phase schedule node as target");
  end else if (phase == null && with_phase) begin
    `uvm_fatal("PH_BADSYNC","unsync() called with null phase and non-null with phase");
  end else if (phase == null) begin
    // whole domain unsync - traverse this domain schedule from begin to end node and unsync each node
    int visited[uvm_phase];
    uvm_phase queue[$];
    queue.push_back(this);
    visited[this] = 1;
    while (queue.size()) begin
      uvm_phase node;
      node = queue.pop_front();
      if (node.m_imp) unsync(target,node.m_imp);
      foreach (node.m_successors[succ]) begin
        if (!visited.exists(succ)) begin
          queue.push_back(succ);
          visited[succ] = 1;
        end
      end
    end
  end else begin
    // single phase unsync
    // this is a 2-way ('with') sync and we check first in case it is already there
    uvm_phase from_node, to_node;
    int found_to[$], found_from[$];
    from_node = target.find(phase);
    to_node = target.find(phase);
    found_to = from_node.m_sync.find_index(node) with (node == to_node);
    found_from = to_node.m_sync.find_index(node) with (node == from_node);
    if (found_to.size()) from_node.m_sync.delete(found_to[0]);
    if (found_from.size()) to_node.m_sync.delete(found_from[0]);
  end
endfunction


// wait_for_state
//---------------
  
task uvm_phase::wait_for_state(uvm_phase_state state, uvm_wait_op op=UVM_EQ);
  case (op)
    UVM_EQ:  wait((state&m_state) != 0);
    UVM_NE:  wait((state&m_state) == 0);
    UVM_LT:  wait(m_state <  state);
    UVM_LTE: wait(m_state <= state);
    UVM_GT:  wait(m_state >  state);
    UVM_GTE: wait(m_state >= state);
  endcase
endtask


//-------------------------
// Implementation - Jumping
//-------------------------

// jump
// ----
//
// Note that this function does not directly alter flow of control.
// That is, the new phase is not initiated in this function.
// Rather, flags are set which execute_phase() uses to determine
// that a jump has been requested and performs the jump.

function void uvm_phase::jump(uvm_phase phase);
  uvm_phase d;
  // TBD refactor

  `uvm_info("PH_JUMP",
            $psprintf("phase %s (schedule %s, domain %s) is jumping to phase %s",
             get_name(), get_schedule_name(), get_domain_name(), phase.get_name()),
            UVM_MEDIUM);

  // A jump can be either forward or backwards in the phase graph.
  // If the specified phase (name) is found in the set of predecessors
  // then we are jumping backwards.  If, on the other hand, the phase is in the set
  // of successors then we are jumping forwards.  If neither, then we
  // have an error.
  //
  // If the phase is non-existant and thus we don't know where to jump
  // we have a situation where the only thing to do is to uvm_report_fatal
  // and terminate_phase.  By calling this function the intent was to
  // jump to some other phase. So, continuing in the current phase doesn't
  // make any sense.  And we don't have a valid phase to jump to.  So we're done.

  d = m_find_predecessor(phase,0);
  if (d == null) begin
    d = m_find_successor(phase,0);
    if (d == null) begin
      string msg;
      $sformat(msg,{"phase %s is neither a predecessor or successor of ",
                    "phase %s or is non-existant, so we cannot jump to it.  ",
                    "Phase control flow is now undefined so the simulation ",
                    "must terminate"}, phase.get_name(), get_name());
      `uvm_fatal("PH_BADJUMP", msg);
    end
    else begin
      m_jump_fwd = 1;
      `uvm_info("PH_JUMPF",$psprintf("jumping forward to phase %s", phase.get_name()),
                UVM_DEBUG);
    end
  end
  else begin
    m_jump_bkwd = 1;
    `uvm_info("PH_JUMPB",$psprintf("jumping backward to phase %s", phase.get_name()),
              UVM_DEBUG);
  end
  
  m_jump_phase = d;
  m_terminate_phase();
endfunction


// jump_all
// --------

function void uvm_phase::jump_all(uvm_phase phase);
  // TBD integration task ongoing
endfunction


// get_jump_target
// ---------------
  
function uvm_phase uvm_phase::get_jump_target();
  return m_jump_phase;
endfunction


// clear
// -----
// for internal graph maintenance after a forward jump
function void uvm_phase::clear(uvm_phase_state state = UVM_PHASE_DORMANT);
  m_state = state;
  m_phase_proc = null;
  phase_done.clear();
endfunction


// clear_successors
// ----------------
// for internal graph maintenance after a forward jump
// - called only by execute_phase()
// - depth-first traversal of the DAG, calliing clear() on each node
function void uvm_phase::clear_successors(uvm_phase_state state = UVM_PHASE_DORMANT);
  clear(state);
  foreach(m_successors[succ])
    succ.clear_successors(state);
endfunction


//---------------------------------
// Implementation - Overall Control
//---------------------------------

// kill
// ----

function void uvm_phase::kill();

  `uvm_info("PH_KILL", {"killing phase '", get_name(),"'"}, UVM_DEBUG);

  if (m_phase_proc != null) begin
    m_phase_proc.kill();
    m_phase_proc = null;
  end

endfunction


// kill_successors
// ---------------

// Using a depth-first traversal, kill all the successor phases of the
// current phase.
function void uvm_phase::kill_successors();
  foreach (m_successors[succ])
    succ.kill_successors();
  kill();
endfunction


// m_run_phases
// ------------

// This task contains the top-level process that owns all the phase
// processes.  By hosting the phase processes here we avoid problems
// associated with phase processes related as parents/children
task uvm_phase::m_run_phases();
  uvm_root top = uvm_root::get();

  m_phase_trace = 0;
  m_use_ovm_run_semantic = 0;
  begin
    uvm_cmdline_processor clp = uvm_cmdline_processor::get_inst();
    string val;
    if (clp.get_arg_value("+UVM_PHASE_TRACE", val))
      m_phase_trace = 1;
    if (clp.get_arg_value("+UVM_USE_OVM_RUN_SEMANTIC", val))
      m_use_ovm_run_semantic = 1;
  end
  
  // initiate by starting first phase in common domain
  begin
    uvm_phase ph = uvm_domain::get_common_domain();
    void'(m_phase_hopper.try_put(ph));
  end

  forever begin
    uvm_phase phase;
    uvm_process proc;
    m_phase_hopper.get(phase);
    fork
      begin
        proc = new(process::self());
        phase.execute_phase();
      end
    join_none
    m_phase_top_procs[phase] = proc;
    #0;  // let the process start running
  end
endtask


// terminate_phase
// ---------------

function void uvm_phase::m_terminate_phase();
  phase_done.clear();
endfunction


// print_termination_state
// -----------------------

function void uvm_phase::m_print_termination_state();
  `uvm_info("PH_TERMSTATE",
            $psprintf("phase %s outstanding objections = %0d",
            get_name(), phase_done.get_objection_total(uvm_root::get())),
            UVM_DEBUG);
endfunction



//------------------------------------------------------------------------------
//
// Class: uvm_domain
//
//------------------------------------------------------------------------------
//
// Phasing schedule node representing an independent branch of the schedule.
// Handle used to assign domains to components or hierarchies in the testbench
//

class uvm_domain extends uvm_phase;

  static local uvm_domain m_common_domain;
  static local uvm_domain m_uvm_domain; // run-time phases
  static local uvm_domain m_domains[string];
  static local uvm_phase m_uvm_schedule;


  // Function: get_domains
  //
  // Provies a list of all domains in the provided ~domains~ argument. 
  //
  static function void get_domains(output uvm_domain domains[string]);
    domains = m_domains;
  endfunction 


  // Function: get_uvm_schedule
  //
  //
  static function uvm_phase get_uvm_schedule();
    void'(get_uvm_domain());
    return m_uvm_schedule;
  endfunction 


  // Function: get_common_domain
  //
  // Get the "common" domain, which consists of the common phases that
  // all components execute in sync with each other. Phases in the "common"
  // domain are build, connect, end_of_elaboration, start_of_simulation, run,
  // extract, check, report, and final.
  //
  static function uvm_domain get_common_domain();

    uvm_domain domain;
    uvm_phase schedule;

    if (m_common_domain != null)
      return m_common_domain;

    domain = new("common");
    domain.add(uvm_build_phase::get());
    domain.add(uvm_connect_phase::get());
    domain.add(uvm_end_of_elaboration_phase::get());
    domain.add(uvm_start_of_simulation_phase::get());
    domain.add(uvm_run_phase::get());
    domain.add(uvm_extract_phase::get());
    domain.add(uvm_check_phase::get());
    domain.add(uvm_report_phase::get());
    domain.add(uvm_final_phase::get());
    m_domains["common"] = domain;

    // for backward compatibility, make common phases visible;
    // same as uvm_<name>_phase::get().
    build_ph               = domain.find(uvm_build_phase::get());
    connect_ph             = domain.find(uvm_connect_phase::get());
    end_of_elaboration_ph  = domain.find(uvm_end_of_elaboration_phase::get());
    start_of_simulation_ph = domain.find(uvm_start_of_simulation_phase::get());
    run_ph                 = domain.find(uvm_run_phase::get());   
    extract_ph             = domain.find(uvm_extract_phase::get());
    check_ph               = domain.find(uvm_check_phase::get());
    report_ph              = domain.find(uvm_report_phase::get());
    m_common_domain = domain;

    domain = get_uvm_domain();
    m_common_domain.add(domain,
                     .with_phase(m_common_domain.find(uvm_run_phase::get())));


    return m_common_domain;

  endfunction


  // Function: add_uvm_phases
  //
  // Appends to the given ~schedule~ the built-in UVM phases.
  //
  static function void add_uvm_phases(uvm_phase schedule);

    schedule.add(uvm_pre_reset_phase::get());
    schedule.add(uvm_reset_phase::get());
    schedule.add(uvm_post_reset_phase::get());
    schedule.add(uvm_pre_configure_phase::get());
    schedule.add(uvm_configure_phase::get());
    schedule.add(uvm_post_configure_phase::get());
    schedule.add(uvm_pre_main_phase::get());
    schedule.add(uvm_main_phase::get());
    schedule.add(uvm_post_main_phase::get());
    schedule.add(uvm_pre_shutdown_phase::get());
    schedule.add(uvm_shutdown_phase::get());
    schedule.add(uvm_post_shutdown_phase::get());

  endfunction


  // Function: get_uvm_domain
  //
  // Get a handle to the singleton ~uvm~ domain
  //
  static function uvm_domain get_uvm_domain();
  
    if (m_uvm_domain == null) begin
      m_uvm_domain = new("uvm");
      m_uvm_schedule = new("uvm_sched", UVM_PHASE_SCHEDULE);
      add_uvm_phases(m_uvm_schedule);
      m_uvm_domain.add(m_uvm_schedule);
    end
    return m_uvm_domain;
  endfunction


  // Function: new
  //
  // Create a new instance of a phase domain.
  function new(string name);
    super.new(name,UVM_PHASE_DOMAIN);
    m_domains[name] = this;
  endfunction

endclass




//------------------------------------------------------------------------------
//
// Class: uvm_bottomup_phase
//
//------------------------------------------------------------------------------
// Virtual base class for function phases that operate bottom-up.
// The pure virtual function execute() is called for each component.
// This is the default traversal so is included only for naming.
//
// A bottom-up function phase completes when the <execute()> method
// has been called and returned on all applicable components
// in the hierarchy.

virtual class uvm_bottomup_phase extends uvm_phase;

  // Function: new
  //
  // Create a new instance of a bottom-up phase.
  //
  function new(string name);
    super.new(name,UVM_PHASE_IMP);
  endfunction


  // Function: traverse
  //
  // Traverses the component tree in bottom-up order, calling <execute> for
  // each component.
  //
  virtual function void traverse(uvm_component comp,
                                 uvm_phase phase,
                                 uvm_phase_state state);
    string name;
    uvm_domain phase_domain =phase.get_domain();
    uvm_domain comp_domain = comp.get_domain();

    if (comp.get_first_child(name))
      do
        traverse(comp.get_child(name), phase, state);
      while(comp.get_next_child(name));

    if (m_phase_trace)
    `uvm_info("PH_TRACE",$sformatf("bottomup-phase phase=%s state=%s comp=%s comp.domain=%s phase.domain=%s",
          phase.get_name(), state.name(), comp.get_full_name(),comp_domain.get_name(),phase_domain.get_name()),
          UVM_DEBUG)

    if (phase_domain == uvm_domain::get_common_domain() ||
        phase_domain == comp_domain) begin
      case (state)
        UVM_PHASE_STARTED: begin
          comp.m_current_phase = phase;
          comp.m_apply_verbosity_settings(phase);
          comp.phase_started(phase);
          end
        UVM_PHASE_EXECUTING: begin
          uvm_phase ph = this; 
          if (comp.m_phase_imps.exists(this))
            ph = comp.m_phase_imps[this];
          ph.execute(comp, phase);
          end
        UVM_PHASE_READY_TO_END: begin
          comp.phase_ready_to_end(phase);
          end
        UVM_PHASE_ENDED: begin
          comp.phase_ended(phase);
          comp.m_current_phase = null;
          end
        default:
          `uvm_fatal("PH_BADEXEC","bottomup phase traverse internal error")
      endcase
    end
  endfunction


  // Function: execute
  //
  // Executes the bottom-up phase ~phase~ for the component ~comp~. 
  //
  protected virtual function void execute(uvm_component comp,
                                          uvm_phase phase);
    comp.m_current_phase = phase;
    exec_func(comp,phase);
  endfunction

endclass


//------------------------------------------------------------------------------
//
// Class: uvm_topdown_phase
//
//------------------------------------------------------------------------------
// Virtual base class for function phases that operate top-down.
// The pure virtual function execute() is called for each component.
//
// A top-down function phase completes when the <execute()> method
// has been called and returned on all applicable components
// in the hierarchy.

virtual class uvm_topdown_phase extends uvm_phase;


  // Function: new
  //
  // Create a new instance of a top-down phase
  //
  function new(string name);
    super.new(name,UVM_PHASE_IMP);
  endfunction


  // Function: traverse
  //
  // Traverses the component tree in top-down order, calling <execute> for
  // each component.
  //
  virtual function void traverse(uvm_component comp,
                                 uvm_phase phase,
                                 uvm_phase_state state);
    string name;
    uvm_domain phase_domain = phase.get_domain();
    uvm_domain comp_domain = comp.get_domain();

    if (m_phase_trace)
    `uvm_info("PH_TRACE",$sformatf("topdown-phase phase=%s state=%s comp=%s comp.domain=%s phase.domain=%s",
          phase.get_name(), state.name(), comp.get_full_name(),comp_domain.get_name(),phase_domain.get_name()),
          UVM_DEBUG)

    if (phase_domain == uvm_domain::get_common_domain() ||
        phase_domain == comp_domain) begin
        case (state)
          UVM_PHASE_STARTED: begin
            comp.m_current_phase = phase;
            comp.m_apply_verbosity_settings(phase);
            comp.phase_started(phase);
            end
          UVM_PHASE_EXECUTING: begin
            if (!(phase.get_name() == "build" && comp.m_build_done)) begin
              uvm_phase ph = this; 
              if (comp.m_phase_imps.exists(this))
                ph = comp.m_phase_imps[this];
              ph.execute(comp, phase);
            end
            end
          UVM_PHASE_READY_TO_END: begin
            comp.phase_ready_to_end(phase);
            end
          UVM_PHASE_ENDED: begin
            comp.phase_ended(phase);
            comp.m_current_phase = null;
            end
          default:
            `uvm_fatal("PH_BADEXEC","topdown phase traverse internal error")
        endcase
    end
    if(comp.get_first_child(name))
      do
        traverse(comp.get_child(name), phase, state);
      while(comp.get_next_child(name));
  endfunction


  // Function: execute
  //
  // Executes the top-down phase ~phase~ for the component ~comp~. 
  //
  protected virtual function void execute(uvm_component comp,
                                          uvm_phase phase);
    comp.m_current_phase = phase;
    exec_func(comp,phase);
  endfunction

endclass


//------------------------------------------------------------------------------
//
// Class: uvm_task_phase
//
//------------------------------------------------------------------------------
// Base class for all task phases.
// It forks a call to <uvm_phase::exec_task()>
// for each component in the hierarchy.
//
// A task phase completes when there are no raised objections
// to the end of phase. The completion of the task
// does not imply, nor is it required for, the end of phase.
// Once the phase completes, any remaining forked <uvm_phase::exec_task()>
// threads are forcibly and immediately killed.
//
// The only way for a task phase to extend over time is if there is
// at least one component that raises an objection.
//
//| class my_comp extends uvm_component;
//|    task main_phase(uvm_phase phase);
//|       phase.raise_objection(this, "Applying stimulus")
//|       ...
//|       phase.drop_objection(this, "Applied enough stimulus")
//|    endtask
//| endclass
// 

virtual class uvm_task_phase extends uvm_phase;


  // Function: new
  //
  // Create a new instance of a task-based phase
  //
  function new(string name);
    super.new(name,UVM_PHASE_IMP);
  endfunction


  // Function: traverse
  //
  // Traverses the component tree in bottom-up order, calling <execute> for
  // each component. The actual order for task-based phases doesn't really
  // matter, as each component task is executed in a separate process whose
  // starting order is not deterministic.
  //
  virtual function void traverse(uvm_component comp,
                                 uvm_phase phase,
                                 uvm_phase_state state);
    phase.m_num_procs_not_yet_returned = 0;
    m_traverse(comp, phase, state);
  endfunction

  function void m_traverse(uvm_component comp,
                           uvm_phase phase,
                           uvm_phase_state state);
    string name;
    uvm_domain phase_domain =phase.get_domain();
    uvm_domain comp_domain = comp.get_domain();
    
    if (comp.get_first_child(name))
      do
        m_traverse(comp.get_child(name), phase, state);
      while(comp.get_next_child(name));

    if (m_phase_trace)
    `uvm_info("PH_TRACE",$sformatf("topdown-phase phase=%s state=%s comp=%s comp.domain=%s phase.domain=%s",
          phase.get_name(), state.name(), comp.get_full_name(),comp_domain.get_name(),phase_domain.get_name()),
          UVM_DEBUG)

    if (phase_domain == uvm_domain::get_common_domain() ||
        phase_domain == comp_domain) begin
      case (state)
        UVM_PHASE_STARTED: begin
          comp.m_current_phase = phase;
          comp.m_apply_verbosity_settings(phase);
          comp.phase_started(phase);
          end
        UVM_PHASE_EXECUTING: begin
          uvm_phase ph = this; 
          if (comp.m_phase_imps.exists(this))
            ph = comp.m_phase_imps[this];
          ph.execute(comp, phase);
          end
        UVM_PHASE_READY_TO_END: begin
          comp.phase_ready_to_end(phase);
          end
        UVM_PHASE_ENDED: begin
          comp.phase_ended(phase);
          comp.m_current_phase = null;
          end
        default:
          `uvm_fatal("PH_BADEXEC","task phase traverse internal error")
      endcase
    end

  endfunction


  // Function: execute
  //
  // Fork the task-based phase ~phase~ for the component ~comp~. 
  //
  protected virtual function void execute(uvm_component comp,
                                          uvm_phase phase);

    fork
      begin
        uvm_sequencer_base seqr;
        
        phase.m_num_procs_not_yet_returned++;

        if ($cast(seqr,comp))
          seqr.start_phase_sequence(phase);

        exec_task(comp,phase);

        phase.m_num_procs_not_yet_returned--;

      end
    join_none

  endfunction
endclass



//------------------------------------------------------------------------------
//
// Class - uvm_process
//
//------------------------------------------------------------------------------
// Workaround container for process construct.

class uvm_process;

  protected process m_process_id;  

  function new(process pid);
    m_process_id = pid;
  endfunction

  function process self();
    return m_process_id;
  endfunction

  virtual function void kill();
    m_process_id.kill();
  endfunction

`ifdef UVM_USE_FPC
  virtual function process::state status();
    return m_process_id.status();
  endfunction

  task await();
    m_process_id.await();
  endtask

  task suspend();
   m_process_id.suspend();
  endtask

  function void resume();
   m_process_id.resume();
  endfunction
`else
  virtual function int status();
    return m_process_id.status();
  endfunction
`endif

endclass


//----------------------------------------------------------------------
// End
//----------------------------------------------------------------------

