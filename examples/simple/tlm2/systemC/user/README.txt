This example shows how a blocking TLM2 connection between SystemVerilog and
SystemC could be implemented.

This example lacks tool-specific SV/SC interface mechanisms and as
such CANNOT be executed without additional tool-specific files. Please
contact your vendor to obtain a similar example or the additional
files required.

The verification environment created by this example has the following
structure:


          SystemVerilog           |              SystemC
                                  |
                                  |
           initiator0 -------> "port0" ------->  target0
            target0   <------- "port1" <------- initiator1
                                  |
                                  |
