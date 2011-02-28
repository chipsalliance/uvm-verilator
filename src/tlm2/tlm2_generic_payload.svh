//----------------------------------------------------------------------
//   Copyright 2010 Mentor Graphics Corporation
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

//----------------------------------------------------------------------
// Title: TLM Generic Payload & Extensions
//----------------------------------------------------------------------
// The Generic Payload transaction represents a generic 
// bus read/write access. It is used as the default transaction in
// TLM2 blocking and nonblocking transport interfaces.
//----------------------------------------------------------------------


//---------------
// Group: Globals
//---------------
//
// Defines, Constants, enums.


// Enum: uvm_tlm_command_e
//
// Command atribute type definition
//
// UVM_TLM_READ_COMMAND      - Bus read operation
//
// UVM_TLM_WRITE_COMMAND     - Bus write operation
//
// UVM_TLM_IGNORE_COMMAND    - No bus operation.

typedef enum
{
    UVM_TLM_READ_COMMAND,
    UVM_TLM_WRITE_COMMAND,
    UVM_TLM_IGNORE_COMMAND
} uvm_tlm_command_e;


// Enum: uvm_tlm_response_status_e
//
// Respone status attribute type definition
//
// UVM_TLM_OK_RESPONSE                - Bus operation completed succesfully
//
// UVM_TLM_INCOMPLETE_RESPONSE        - Transaction was not delivered to target
//
// UVM_TLM_GENERIC_ERROR_RESPONSE     - Bus operation had an error
//
// UVM_TLM_ADDRESS_ERROR_RESPONSE     - Invalid address specified
//
// UVM_TLM_COMMAND_ERROR_RESPONSE     - Invalid command specified
//
// UVM_TLM_BURST_ERROR_RESPONSE       - Invalid burst specified
//
// UVM_TLM_BYTE_ENABLE_ERROR_RESPONSE - Invalid byte enabling specified
//

typedef enum
{
    UVM_TLM_OK_RESPONSE = 1,
    UVM_TLM_INCOMPLETE_RESPONSE = 0,
    UVM_TLM_GENERIC_ERROR_RESPONSE = -1,
    UVM_TLM_ADDRESS_ERROR_RESPONSE = -2,
    UVM_TLM_COMMAND_ERROR_RESPONSE = -3,
    UVM_TLM_BURST_ERROR_RESPONSE = -4,
    UVM_TLM_BYTE_ENABLE_ERROR_RESPONSE = -5
} uvm_tlm_response_status_e;


typedef class uvm_tlm_extension_base;


//-----------------------
// Group: Generic Payload
//-----------------------

//----------------------------------------------------------------------
// Class: uvm_tlm_generic_payload
//
// This class provides a transaction definition commonly used in
// memory-mapped bus-based systems.  It's intended to be a general
// purpose transaction class that lends itself to many applications. The
// class is derived from uvm_sequence_item which enables it to be
// generated in sequences and transported to drivers through sequencers.
//----------------------------------------------------------------------

class uvm_tlm_generic_payload extends uvm_sequence_item;
   
   // Variable: m_address
   //
   // Address for the bus operation.
   // Should be set or read using the <set_address> and <get_address>
   // methods. The variable should be used only when constraining.
   //
   // For a read command or a write command, the target shall
   // interpret the current value of the address attribute as the start
   // address in the system memory map of the contiguous block of data
   // being read or written.
   // The address associated with any given byte in the data array is
   // dependent upon the address attribute, the array index, the
   // streaming width attribute, the endianness and the width of the physical bus.
   //
   // If the target is unable to execute the transaction with
   // the given address attribute (because the address is out-of-range,
   // for example) it shall generate a standard error response. The
   // recommended response status is ~UVM_TLM_ADDRESS_ERROR_RESPONSE~.

   rand bit [63:0]             m_address;
 
   // Variable: m_command
   //
   // Bus operation type.
   // Should be set using the <set_command>, <set_read> or <set_write> methods
   // and read using the <get_command>, <is_read> or <is_write> methods.
   // The variable should be used only when constraining.
   //
   // If the target is unable to execute a read or write command, it
   // shall generate a standard error response. The
   // recommended response status is UVM_TLM_COMMAND_ERROR_RESPONSE.
   //
   // On receipt of a generic payload transaction with the command
   // attribute equal to UVM_TLM_IGNORE_COMMAND, the target shall not execute
   // a write command or a read command not modify any data.
   // The target may, however, use the value of any attribute in
   // the generic payload, including any extensions.
   //
   // The command attribute shall be set by the initiator, and shall
   // not be overwritten by any interconnect

   rand uvm_tlm_command_e          m_command;
   
   // Variable: m_data
   //
   // Data read or to be written.
   // Should be set and read using the <set_data> or <get_data> methods
   // The variable should be used only when constraining.
   //
   // For a read command or a write command, the target shall copy data
   // to or from the data array, respectively, honoring the semantics of
   // the remaining attributes of the generic payload.
   //
   // For a write command or UVM_TLM_IGNORE_COMMAND, the contents of the
   // data array shall be set by the initiator, and shall not be
   // overwritten by any interconnect component or target. For a read
   // command, the contents of the data array shall be overwritten by the
   // target (honoring the semantics of the byte enable) but by no other
   // component.
   //
   // Unlike the OSCI TLM-2.0 LRM, there is no requirement on the endiannes
   // of multi-byte data in the generic payload to match the host endianness.
   // Unlike C++, it is not possible in SystemVerilog to cast an arbitrary
   // data type as an array of bytes. Therefore, matching the host
   // endianness is not necessary. In constrast, arbitrary data types may be
   // converted to and from a byte array using the streaming operator and
   // <uvm_object> objects may be further converted using the
   // <uvm_object::pack_bytes()> and <uvm_object::unpack_bytes()> methods.
   // All that is required is that a consistent mechanism is used to
   // fill the payload data array and later extract data from it.
   //
   // Should a generic payload be transfered to/from a systemC model,
   // it will be necessary for any multi-byte data in that generic payload
   // to use/be interpreted using the host endianness.
   // However, this process is currently outside the scope of this standard.
   //

   rand byte unsigned             m_data[];

   // Variable: m_length
   //
   // The number of bytes to be copied to or from the <m_data> array,
   // inclusive of any bytes disabled by the <m_byte_enable> attribute.
   //
   // The data length attribute shall be set by the initiator,
   // and shall not be overwritten by any interconnect component or target.
   //
   // The data length attribute shall not be set to 0.
   // In order to transfer zero bytes, the <m_command> attribute
   // should be set to <UVM_TLM_IGNORE_COMMAND>.
   
   rand int unsigned           m_length;
   
   // Variable: m_response_status
   //
   // Status of the bus operation.
   // Should be set using the <set_response_status> method
   // and read using the <get_response_status>, <get_response_string>,
   // <is_response_ok> or <is_response_error> methods.
   // The variable should be used only when constraining.
   //
   // The response status attribute shall be set to
   // UVM_TLM_INCOMPLETE_RESPONSE by the initiator, and may
   // be overwritten by the target. The response status attribute
   // should not be overwritten by any interconnect
   // component, because the default value UVM_TLM_INCOMPLETE_RESPONSE
   // indicates that the transaction was not delivered to the target.
   //
   // The target may set the response status attribute to UVM_TLM_OK_RESPONSE
   // to indicate that it was able to execute the command
   // successfully, or to one of the five error responses
   // to indicate an error. The target should choose the appropriate
   // error response depending on the cause of the error.
   // If a target detects an error but is unable to select a specific
   // error response, it may set the response status to
   // UVM_TLM_GENERIC_ERROR_RESPONSE.
   //
   // The target shall be responsible for setting the response status
   // attribute at the appropriate point in the
   // lifetime of the transaction. In the case of the blocking
   // transport interface, this means before returning
   // control from b_transport. In the case of the non-blocking
   // transport interface and the base protocol, this
   // means before sending the BEGIN_RESP phase or returning a value of UVM_TLM_COMPLETED.
   //
   // It is recommended that the initiator should always check the
   // response status attribute on receiving a
   // transition to the BEGIN_RESP phase or after the completion of
   // the transaction. An initiator may choose
   // to ignore the response status if it is known in advance that the
   // value will be UVM_TLM_OK_RESPONSE,
   // perhaps because it is known in advance that the initiator is
   // only connected to targets that always return
   // UVM_TLM_OK_RESPONSE, but in general this will not be the case. In
   // other words, the initiator ignores the
   // response status at its own risk.

   rand uvm_tlm_response_status_e  m_response_status;

   // Variable: m_dmi
   //
   // DMI mode is not yet supported in the UVM TLM2 subset.
   // This variable is provided for completeness and interoperability
   // with SystemC.
   rand bit                    m_dmi;
   
   // Variable: m_byte_enable
   //
   // Indicates valid <m_data> array elements.
   // Should be set and read using the <set_byte_enable> or <get_byte_enable> methods
   // The variable should be used only when constraining.
   //
   // The elements in the byte enable array shall be interpreted as
   // follows. A value of 8'h00 shall indicate that that
   // corresponding byte is disabled, and a value of 8'hFF shall
   // indicate that the corresponding byte is enabled.
   //
   // Byte enables may be used to create burst transfers where the
   // address increment between each beat is
   // greater than the number of significant bytes transferred on each
   // beat, or to place words in selected byte
   // lanes of a bus. At a more abstract level, byte enables may be
   // used to create "lacy bursts" where the data array of the generic
   // payload has an arbitrary pattern of holes punched in it.
   //
   // The byte enable mask may be defined by a small pattern applied
   // repeatedly or by a large pattern covering the whole data array.
   // The byte enable array may be empty, in which case byte enables
   // shall not be used for the current transaction.
   //
   // The byte enable array shall be set by the initiator and shall
   // not be overwritten by any interconnect component or target.
   //
   // If the byte enable pointer is not empty, the target shall either
   // implement the semantics of the byte enable as defined below or
   // shall generate a standard error response. The recommended response
   // status is UVM_TLM_BYTE_ENABLE_ERROR_RESPONSE.
   //
   // In the case of a write command, any interconnect component or
   // target should ignore the values of any disabled bytes in the
   // <m_data> array. In the case of a read command, any interconnect
   // component or target should not modify the values of disabled
   // bytes in the <m_data> array.
   
   rand byte unsigned          m_byte_enable[];

   // Variable: m_byte_enable_length
   // The number of elements in the <m_byte_enable> array.
   //
   // It shall be set by the initiator, and shall not be overwritten
   // by any interconnect component or target.
   
   rand int unsigned           m_byte_enable_length;

   // Variable: m_streaming_width
   //    
   // Number of bytes transferred on each beat.
   // Should be set and read using the <set_streaming_width> or
   // <get_streaming_width> methods
   // The variable should be used only when constraining.
   //
   // Streaming affects the way a component should interpret the data
   // array. A stream consists of a sequence of data transfers occurring
   // on successive notional beats, each beat having the same start
   // address as given by the generic payload address attribute. The
   // streaming width attribute shall determine the width of the stream,
   // that is, the number of bytes transferred on each beat. In other
   // words, streaming affects the local address associated with each
   // byte in the data array. In all other respects, the organisation of
   // the data array is unaffected by streaming.
   //
   // The bytes within the data array have a corresponding sequence of
   // local addresses within the component accessing the generic payload
   // transaction. The lowest address is given by the value of the
   // address attribute. The highest address is given by the formula
   // address_attribute + streaming_width - 1. The address to or from
   // which each byte is being copied in the target shall be set to the
   // value of the address attribute at the start of each beat.
   //
   // With respect to the interpretation of the data array, a single
   // transaction with a streaming width shall be functionally equivalent
   // to a sequence of transactions each having the same address as the
   // original transaction, each having a data length attribute equal to
   // the streaming width of the original, and each with a data array
   // that is a different subset of the original data array on each
   // beat. This subset effectively steps down the original data array
   // maintaining the sequence of bytes.
   //
   // A streaming width of 0 indicates that a streaming transfer
   // is not required. it is equivalent to a streaming width 
   // value greater than or equal to the size of the <m_data> array.
   //
   // Streaming may be used in conjunction with byte enables, in which
   // case the streaming width would typically be equal to the byte
   // enable length. It would also make sense to have the streaming width
   // a multiple of the byte enable length. Having the byte enable length
   // a multiple of the streaming width would imply that different bytes
   // were enabled on each beat.
   //
   // If the target is unable to execute the transaction with the
   // given streaming width, it shall generate a standard error
   // response. The recommended response status is
   // TLM_BURST_ERROR_RESPONSE.
               
   rand int unsigned           m_streaming_width;


   local uvm_tlm_extension_base m_extensions [uvm_tlm_extension_base];

   `uvm_object_utils_begin(uvm_tlm_generic_payload)
      `uvm_field_int(m_address, UVM_ALL_ON);
      `uvm_field_enum(uvm_tlm_command_e, m_command, UVM_ALL_ON);
      `uvm_field_array_int(m_data, UVM_ALL_ON);
      `uvm_field_int(m_length, UVM_ALL_ON);
      `uvm_field_enum(uvm_tlm_response_status_e, m_response_status, UVM_ALL_ON);
      `uvm_field_array_int(m_byte_enable, UVM_ALL_ON);
      `uvm_field_int(m_streaming_width, UVM_ALL_ON);
   `uvm_object_utils_end
   

  // Function: new
  //
  // Create a new instance of the generic payload.  Initialize all the
  // members to their default values.

  function new(string name="");
    super.new(name);
    m_address = 0;
    m_command = UVM_TLM_IGNORE_COMMAND;
    m_length = 0;
    m_response_status = UVM_TLM_INCOMPLETE_RESPONSE;
    m_dmi = 0;
    m_byte_enable_length = 0;
    m_streaming_width = 0;
  endfunction


   function void do_print(uvm_printer printer);
      foreach (m_extensions[ext_]) begin
      	 uvm_tlm_extension_base ext = ext_;
         printer.print_object(ext.get_type_handle_name(), m_extensions[ext]);
      end
   endfunction


   function void do_copy(uvm_object rhs);
      uvm_tlm_generic_payload gp;
      super.do_copy(rhs);
      $cast(gp, rhs);
      m_extensions.delete();
      foreach (gp.m_extensions[ext]) begin
         $cast(m_extensions[ext], gp.m_extensions[ext].clone());
      end
   endfunction
   

   function bit do_compare(uvm_object rhs, uvm_comparer comparer);
      uvm_tlm_generic_payload gp;
      do_compare = super.do_compare(rhs, comparer);
      $cast(gp, rhs);
      foreach (m_extensions[ext_]) begin
      	 uvm_tlm_extension_base ext = ext_;
         if (!gp.m_extensions.exists(ext)) 
            do_compare &= comparer.compare_object(ext.get_type_handle_name(), m_extensions[ext], null);
         else do_compare &= comparer.compare_object(ext.get_type_handle_name(), m_extensions[ext], gp.m_extensions[ext]);
      end
      foreach (gp.m_extensions[ext_]) begin
      	 uvm_tlm_extension_base ext = ext_;
         if (!m_extensions.exists(ext)) 
            do_compare &= comparer.compare_object(ext.get_type_handle_name(), null, gp.m_extensions[ext]);
      end
   endfunction
   

  // Function: convert2string
  //
  // Convert the contents of the class to a string suitable for
  // printing.

  function string convert2string();

    string msg;
    string addr_fmt;
    string s;
     int unsigned addr_chars = 16;

    $sformat(msg, "%s [0x%16x] =", m_command.name(), m_address);

    for(int unsigned i = 0; i < m_data.size(); i++) begin
      $sformat(s, " %02x", m_data[i]);
      msg = { msg , s };
    end

    if(m_response_status != UVM_TLM_INCOMPLETE_RESPONSE)
      msg = { msg, " <-- ", get_response_string() };

    return msg;

  endfunction

  //--------------------------------------------------------------------
  // Group: accessors
  //
  // The accessor functions let you set and get each of the members of the 
  // generic payload. All of the accessor methods are virtual. This implies 
  // a slightly different use model for the generic payload than 
  // in SsytemC. The way the generic payload is defined in SystemC does 
  // not encourage you to create new transaction types derived from 
  // uvm_tlm_generic_payload. Instead, you would use the extensions mechanism. 
  // Thus in SystemC none of the accessors are virtual.
  //--------------------------------------------------------------------

   // Function: get_command
   //
   // Get the value of the <m_command> variable

  virtual function uvm_tlm_command_e get_command();
    return m_command;
  endfunction

   // Function: set_command
   //
   // Set the value of the <m_command> variable
   
  virtual function void set_command(uvm_tlm_command_e command);
    m_command = command;
  endfunction

   // Function: is_read
   //
   // Returns true if the current value of the <m_command> variable
   // is ~UVM_TLM_READ_COMMAND~.
   
  virtual function bit is_read();
    return (m_command == UVM_TLM_READ_COMMAND);
  endfunction
 
   // Function: set_read
   //
   // Set the current value of the <m_command> variable
   // to ~UVM_TLM_READ_COMMAND~.
   
  virtual function void set_read();
    set_command(UVM_TLM_READ_COMMAND);
  endfunction

   // Function: is_write
   //
   // Returns true if the current value of the <m_command> variable
   // is ~UVM_TLM_WRITE_COMMAND~.
 
  virtual function bit is_write();
    return (m_command == UVM_TLM_WRITE_COMMAND);
  endfunction
 
   // Function: set_write
   //
   // Set the current value of the <m_command> variable
   // to ~UVM_TLM_WRITE_COMMAND~.

  virtual function void set_write();
    set_command(UVM_TLM_WRITE_COMMAND);
  endfunction
  
   // Function: set_address
   //
   // Set the value of the <m_address> variable
  virtual function void set_address(bit [63:0] addr);
    m_address = addr;
  endfunction

   // Function: get_address
   //
   // Get the value of the <m_address> variable
 
  virtual function bit [63:0] get_address();
    return m_address;
  endfunction

   // Function: get_data
   //
   // Return the value of the <m_data> array
 
  virtual function void get_data (output byte unsigned p []);
    p = m_data;
  endfunction

   // Function: set_data
   //
   // Set the value of the <m_data> array  

  virtual function void set_data(ref byte unsigned p []);
    m_data = p;
  endfunction 
  
   // Function: get_data_length
   //
   // Return the current size of the <m_data> array
   
  virtual function int unsigned get_data_length();
    return m_length;
  endfunction

  // Function: set_data_length
  // Set the value of the <m_length>
   
   virtual function void set_data_length(int unsigned length);
    m_length = length;
  endfunction

   // Function: get_streaming_width
   //
   // Get the value of the <m_streaming_width> array
  
  virtual function int unsigned get_streaming_width();
    return m_streaming_width;
  endfunction

 
   // Function: set_streaming_width
   //
   // Set the value of the <m_streaming_width> array
   
  virtual function void set_streaming_width(int unsigned width);
    m_streaming_width = width;
  endfunction

   // Function: get_byte_enable
   //
   // Return the value of the <m_byte_enable> array
  virtual function void get_byte_enable(output byte unsigned p[]);
    p = m_byte_enable;
  endfunction

   // Function: set_byte_enable
   //
   // Set the value of the <m_byte_enable> array
   
  virtual function void set_byte_enable(ref byte unsigned p[]);
    m_byte_enable = p;
  endfunction

   // Function: get_byte_enable_length
   //
   // Return the current size of the <m_byte_enable> array
   
  virtual function int unsigned get_byte_enable_length();
    return m_byte_enable_length;
  endfunction

   // Function: set_byte_enable_length
   //
   // Set the size <m_byte_enable_length> of the <m_byte_enable> array
   // i.e  <m_byte_enable>.size()
   
 virtual function void set_byte_enable_length(int unsigned length);
    m_byte_enable_length = length;
  endfunction

   // Function: set_dmi_allowed
   //
   // DMI hint. Set the internal flag <m_dmi> to allow dmi access
   
  virtual function void set_dmi_allowed(bit dmi);
    m_dmi = dmi;
  endfunction
   
   // Function: is_dmi_allowed
   //
   // DMI hint. Query the internal flag <m_dmi> if allowed dmi access 

 virtual function bit is_dmi_allowed();
    return m_dmi;
  endfunction

   // Function: get_response_status
   //
   // Return the current value of the <m_response_status> variable
   
  virtual function uvm_tlm_response_status_e get_response_status();
    return m_response_status;
  endfunction

   // Function: set_response_status
   //
   // Set the current value of the <m_response_status> variable

  virtual function void set_response_status(uvm_tlm_response_status_e status);
    m_response_status = status;
  endfunction

   // Function: is_response_ok
   //
   // Return TRUE if the current value of the <m_response_status> variable
   // is ~UVM_TLM_OK_RESPONSE~

  virtual function bit is_response_ok();
    return (int'(m_response_status) > 0);
  endfunction

   // Function: is_response_error
   //
   // Return TRUE if the current value of the <m_response_status> variable
   // is not ~UVM_TLM_OK_RESPONSE~

  virtual function bit is_response_error();
    return !is_response_ok();
  endfunction

   // Function: get_response_string
   //
   // Return the current value of the <m_response_status> variable
   // as a string

  virtual function string get_response_string();

    case(m_response_status)
      UVM_TLM_OK_RESPONSE                : return "OK";
      UVM_TLM_INCOMPLETE_RESPONSE        : return "INCOMPLETE";
      UVM_TLM_GENERIC_ERROR_RESPONSE     : return "GENERIC_ERROR";
      UVM_TLM_ADDRESS_ERROR_RESPONSE     : return "ADDRESS_ERROR";
      UVM_TLM_COMMAND_ERROR_RESPONSE     : return "COMMAND_ERROR";
      UVM_TLM_BURST_ERROR_RESPONSE       : return "BURST_ERROR";
      UVM_TLM_BYTE_ENABLE_ERROR_RESPONSE : return "BYTE_ENABLE_ERROR";
    endcase

    // we should never get here
    return "UNKNOWN_RESPONSE";

  endfunction

  //--------------------------------------------------------------------
  // Group: Extensions Mechanism
  //
  //--------------------------------------------------------------------

  // Function: set_extension
  //
  // Add an instance-specific extension.
  // The specified extension is bound to the generic payload by ts type
  // handle.
   
  function uvm_tlm_extension_base set_extension(uvm_tlm_extension_base ext);
    uvm_tlm_extension_base ext_handle = ext.get_type_handle();
    set_extension = m_extensions[ext_handle];
    m_extensions[ext_handle] = ext;
  endfunction

  // Function: get_num_extensions
  //
  // Return the current number of instance specific extensions.
   
  function int get_num_extensions();
    return m_extensions.num();
  endfunction: get_num_extensions
   
  // Function: get_extension
  //
  // Return the instance specific extension bound under the specified key.
  // If no extension is bound under that key, ~null~ is returned.
   
  function uvm_tlm_extension_base get_extension(uvm_tlm_extension_base ext_handle);
    if(!m_extensions.exists(ext_handle))
      return null;
    return m_extensions[ext_handle];
  endfunction
   
  // Function: clear_extension
  //
  // Remove the instance-specific extension bound under the specified key.
   
  function void clear_extension(uvm_tlm_extension_base ext_handle);
    if(m_extensions.exists(ext_handle))
      m_extensions.delete(ext_handle);
    else
      `uvm_info("GP_EXT", $sformatf("Unable to find extension to clear"), UVM_MEDIUM);

  endfunction: clear_extension

  // Function: clear_extensions
  //
  // Remove all instance-specific extensions
   
  function void clear_extensions();
    m_extensions.delete();
  endfunction
    
endclass

//----------------------------------------------------------------------
// Class: uvm_tlm_gp
//
// This typedef provides a short, more convenient name for the
// <uvm_tlm_generic_payload> type.
//----------------------------------------------------------------------

typedef uvm_tlm_generic_payload uvm_tlm_gp;


//----------------------------------------------------------------------
// Class: uvm_tlm_extension_base
//
// The class uvm_tlm_extension_base is the non-parameterized base class for
// all generic payload extensions.  It includes the utility do_copy()
// and create().  The pure virtual function get_type_handle() allows you
// to get a unique handles that represents the derived type.  This is
// implemented in derived classes.
//
// This class is never used directly by users.
// The <uvm_tlm_extension> class is used instead.
//
virtual class uvm_tlm_extension_base extends uvm_object;

  // Function: new
  //
  function new(string name = "");
    super.new(name);
  endfunction

  // Function: get_type_handle
  //
  // An interface to polymorphically retrieve a handle that uniquely
  // identifies the type of the sub-class

  pure virtual function uvm_tlm_extension_base get_type_handle();

  // Function: get_type_handle_name
  //
  // An interface to polymorphically retrieve the name that uniquely
  // identifies the type of the sub-class

  pure virtual function string get_type_handle_name();

  virtual function void do_copy(uvm_object rhs);
    super.do_copy(rhs);
  endfunction

  // Function: create
  //
   
  virtual function uvm_object create (string name="");
    return null;
  endfunction

endclass


//----------------------------------------------------------------------
// Class: uvm_tlm_extension
//
// TLM extension class. The class is parameterized with arbitrary type
// which represents the type of the extension. An instance of the
// generic payload can contain one extension object of each type; it
// cannot contain two instances of the same extension type.
//
// The extension type can be identified using the <ID()>
// method.
//
// To implement a generic payload extension, simply derive a new class
// from this class and specify the name of the derived class as the
// extension parameter.
//
//|
//| class my_ID extends uvm_tlm_extension#(my_ID);
//|   int ID;
//|
//|   `uvm_object_utils_begin(my_ID)
//|      `uvm_field_int(ID, UVM_ALL_ON)
//|   `uvm_object_utils_end
//|
//|   function new(string name = "my_ID");
//|      super.new(name);
//|   endfunction
//| endclass
//|

class uvm_tlm_extension #(type T=int) extends uvm_tlm_extension_base;

   typedef uvm_tlm_extension#(T) this_type;

   local static this_type m_my_tlm_ext_type = ID();

   // Function: new
   //
   // creates a new extension object.

   function new(string name="");
     super.new(name);
   endfunction

   // Function: ID()
   //
   // Return the unique ID of this TLM extension type.
   // This method is used to identify the type of the extension to retrieve
   // from a <uvm_tlm_generic_payload> instance,
   // using the <uvm_tlm_generic_payload::get_extension()> method.
   //
  static function this_type ID();
    if (m_my_tlm_ext_type == null)
      m_my_tlm_ext_type = new();
    return m_my_tlm_ext_type;
  endfunction

  virtual function uvm_tlm_extension_base get_type_handle();
     return ID();
  endfunction

  virtual function string get_type_handle_name();
`ifndef UVM_USE_TYPENAME
     return "";
`else
     return $typename(T);
`endif
  endfunction

  virtual function void do_copy(uvm_object rhs);
    super.do_copy(rhs);
  endfunction

  virtual function uvm_object create (string name="");
    return null;
  endfunction

endclass

