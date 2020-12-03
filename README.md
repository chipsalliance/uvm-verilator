# Accellera Universal Verification Methodology (UVM, IEEE 1800.2-2020)

# Scope

This kit provides a Systemverilog library matching the requirements of [IEEE 1800.2-2020](https://ieeexplore.ieee.org/document/9195920). 
See details in the Library Release Description below.

**Note:** The implementation provided deviates from the 1800.2-2020 standard, see [DEVIATIONS.md](./DEVIATIONS.md) for additional details.

# Kit version

1800.2-2020 1.0

This kit was generated based upon the following git commit state: 93c9214 db8f1708988ef878f09d7f8c440dd472e8b9ddac.

# License

The UVM kit is licensed under the Apache-2.0 license.  The full text of
the Apache license is provided in this kit in the file [LICENSE.txt](./LICENSE.txt).

# Copyright

All copyright owners for this kit are listed in [NOTICE.txt](./NOTICE.txt).

All Rights Reserved Worldwide

# Contacts and Support

If you have questions about this implementation and/or its application to verification environments, please visit the
[Accellera UVM (IEEE 1800.2) - Methodology and BCL Forum](https://forums.accellera.org/forum/43-uvm-ieee-18002-methodology-and-bcl-forum/) or 
contact the Accellera UVM Working Group (uvm-wg@lists.accellera.org).

# Bug Fixes

The following bugs were fixed in 1.0.

[Mantis 6533](https://accellera.mantishub.io/view.php?id=6533) In uvm_component, added accessors set_print_config_matches() and get_print_config_matches() and deprecated directe access to print_config_matches field.

[Mantis 5716](https://accellera.mantishub.io/view.php?id=5716) In uvm_reg_field, added set_rand_mode() and get_rand_mode() methods.

[Mantis 6757](https://accellera.mantishub.io/view.php?id=6757) Fixed uvm_reg_map::mirror handling of map when backdoor is used, avoiding meaningless warnings.

[Mantis 6306](https://accellera.mantishub.io/view.php?id=6306) uvm_default_report_server::report_summarize() now uses file argument instead of always sending to STDOUT.

[Mantis 7213](https://accellera.mantishub.io/view.php?id=7213) In uvm_mem, fixed order of post_read() and callbacks such that callbacks come first. 

[Mantis 6766](https://accellera.mantishub.io/view.php?id=6976) In uvm_mem, get_addresses now checks if offset argument is smaller than array size - 1.

[Mantis 7092](https://accellera.mantishub.io/view.php?id=7092) Allow command line control of messages before the uvm_root build_phase.

[Mantis 5689](https://accellera.mantishub.io/view.php?id=5689) uvm_reg_access_seq and bitbash_seq now tests sub-hierarchy registers only once.

[Mantis 7167](https://accellera.mantishub.io/view.php?id=7167) Fixed corner case for uvm_component::lookup().

[Mantis 5618](https://accellera.mantishub.io/view.php?id=5618) In uvm_reg, any value changes made in do_read now are maintained.

[Mantis 7051](https://accellera.mantishub.io/view.php?id=7051) In uvm_reg, do_read now correctly compares against get_mirrored_value() instead of get().

[Mantis 6222](https://accellera.mantishub.io/view.php?id=6222) In uvm_comparer, compare_field_int now errors if size > 64.

[Mantis 5029](https://accellera.mantishub.io/view.php?id=5029) Fixed memory leak in uvm_sequencer_base::execute_item.

[Mantis 6814](https://accellera.mantishub.io/view.php?id=6814) uvm_reg::convert2string() now includes register name

[Mantis 6346](https://accellera.mantishub.io/view.php?id=6346) uvm_reg::add_field now checks if whole field is within register size.

[Mantis 5341](https://accellera.mantishub.io/view.php?id=5341) In uvm_reg, fixed prints in do_read and do_write to clearly show values are hexadecimal.

[Mantis 5679](https://accellera.mantishub.io/view.php?id=5679) uvm_sqr_if now has an API to facilitate sequencer layering

[Mantis 6398](https://accellera.mantishub.io/view.php?id=6398) In uvm_reg_block, when sub-block has more than one map defined, all maps are initialized when the model is locked.

[Mantis 7066](https://accellera.mantishub.io/view.php?id=7066) uvm_tlm_fifo::flush() no longer causes get_ap.write()

[Mantis 4780](https://accellera.mantishub.io/view.php?id=4780) Removed unnecessary warning in uvm_callbacks

[Mantis 4934](https://accellera.mantishub.io/view.php?id=4934) Fixed time of assignment of uvm_event::trigger_data

[Mantis 4464](https://accellera.mantishub.io/view.php?id=4464) Made uvm_tlm_fifo::get() robust when terminated

[Mantis 5918](https://accellera.mantishub.io/view.php?id=5918) Corrected uvm_sequence_library::do_print call to print_field_int

[Mantis 5650](https://accellera.mantishub.io/view.php?id=5650) uvm_reg_hw_reset_seq now tests all registers when a reg_block includes sub_blocks and registers

[Mantis 6786](https://accellera.mantishub.io/view.php?id=6786) Fixed operation of uvm_sequence_library::select_sequence.

[Mantis 6324](https://accellera.mantishub.io/view.php?id=6324) uvm_mem_access_seq and uvm_reg_mem_shared_access_seq now use randomize() calls instead of $random

# Deprecated API

In addition to the API deprecated in the 1800.2-2020 LRM, this library deprecates the following:

- Direct access to uvm_component::print_config_matches is deprecated in favor of new accessor methods, see [Mantis 6533](https://accellera.mantishub.io/view.php?id=6533).

# Installing the kit

Installation of UVM requires first unpacking the kit in a convenient
location.

```
    % mkdir path/to/convenient/location
    % cd path/to/convenient/location
    % gunzip -c path/to/UVM/distribution/tar.gz | tar xvf -
```

Follow the installation instructions provided by your tool vendor for
using this UVM installation and tool version dependencies.

# Prerequisites

- IEEE1800 compliant SV simulator. Please check with your tool vendor for exact tool version requirements.
- C compiler to compile the DPI code (if not otherwise provided by tool vendor)


# Library Release description

Each class and method in the standard is annotated in the implementation, allowing tools to identify 
the corresponding section in the standard. 

Example:
```
// @uvm-ieee 1800.2-2020 auto 16.5.3.2
extern virtual function void get_packed_bits (ref bit unsigned stream[]);
```

In addition to the APIs described in the standard, the Library includes the following categories of extra API:

1. APIs that are being considered for contribution to the IEEE by Accellera.  They are identified by the following annotation:
```
// @uvm-contrib Potential Contribution to 1800.2
```
2. APIs that are not being considered for contribution to the IEEE.  Generally these are provided for debug purposes.  They are identified by the following annotation:
```
// @uvm-accellera Accellera Implementation-specific API
```
3. Deprecated API\
**Note:** APIs deprecated in the 1800.2-2020 LRM are under a `` `ifdef UVM_ENABLE_DEPRECATED_API `` guard.  These APIs are
only supported when the deprecated API didn't contradict 1800.2-2020 API.  When `UVM_ENABLE_DEPRECATED_API` is defined
both the deprecated and 1800.2-2020 APIs are available.  When `UVM_ENABLE_DEPRECATED_API` is _not_ defined, the deprecated
APIs are not available, and any code referencing them will miscompile.\
\
These APIs will only be supported until the next release of the 1800.2 standard.  Code leveraging these deprecated APIs
should be migrated to 1800.2-2020 standard APIs to maintain compatibility with future versions of the implementation. \
\
By default, `UVM_ENABLE_DEPRECATED_API` is not  defined. 
4. APIs used within the library that are not intended to be directly used outside of the implementation.

**Note:** While the Accellera UVM Working Group supports the APIs described in (1), (2) and (3) above, these APIs are technically not a part of the 1800.2 standard.  As such, any code which leverages these APIs may not be portable to alternative 1800.2 implementations.  

# Backwards Compatibility Concerns

These are instances wherein the functionality of an API that exists in both UVM 1.2 and the IEEE 1800.2 standard has changed in a non 
backwards-compatible manner.

1. [Mantis 7082](https://accellera.mantishub.io/view.php?id=7082) Arguments and fields in uvm_mem_mam, uvm_mem_mam_cfg, and uvm_mem_region have changed from type "bit [63:0]" to the typedef uvm_reg_addr_t.
                             
2. [Mantis 7090](https://accellera.mantishub.io/view.php?id=7090) The uvm_split_string method has been deprecated in favor of uvm_string_split.  The command line processor now uses uvm_string_split.  The difference is that uvm_split_string did not create any empty strings, so ",,xxx,," would not be treated any differently than "xxx".  Now with uvm_string_split, ",,xxx,," will be interpreted as two empty strings, then "xxx", then two more empty strings.



# Migration instructions

In order to migrate to the Library version of the release, It is recommended that you perform the following steps to get your code to 
run with this release of UVM. 

1. Compile/Run using a UVM 1800.2-2017 library with `UVM_NO_DEPRECATED` defined. This will ensure that your code runs 
with UVM 1800.2-2017 which was a baseline for the UVM 1800.2-2020 library development.  

**Note:** All code deprecated in UVM 1800.2-2017 has been removed from this version of the library.

2. Compile/Run using this library with `UVM_ENABLE_DEPRECATED_API` defined.  This step helps identify the areas where your code may need modifications to comply with the standard.


3. Compile/Run using this library without `UVM_ENABLE_DEPRECATED_API` defined. Removing the define ensures that only the 1800.2 API documented in the standard, along with any non-deprecation accellera supplied API, is used.  Any new compile failures are the result of deprecated 1800.2-2017 APIs.
