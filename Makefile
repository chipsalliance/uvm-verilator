##----------------------------------------------------------------------
##   Copyright 2010 Synopsys, Inc.
##   Copyright 2010 Cadence Design Systems, Inc.
##   Copyright 2011 Mentor Graphics Corporation
##   All Rights Reserved Worldwide
##
##   Licensed under the Apache License, Version 2.0 (the
##   "License"); you may not use this file except in
##   compliance with the License.  You may obtain a copy of
##   the License at
##
##       http://www.apache.org/licenses/LICENSE-2.0
##
##   Unless required by applicable law or agreed to in
##   writing, software distributed under the License is
##   distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
##   CONDITIONS OF ANY KIND, either express or implied.  See
##   the License for the specific language governing
##   permissions and limitations under the License.
##----------------------------------------------------------------------

TOOL	= $(shell $(UVM_HOME)/bin/uvm_dpi_name -tool)

UVM_HOME = .

OS	= $(shell $(UVM_HOME)/bin/uvm_os_name)

SRCDIR	= $(UVM_HOME)/src/dpi
SONAME	= $(shell $(UVM_HOME)/bin/uvm_dpi_name)
LIBDIR	= $(shell dirname $(SONAME))

CC	= gcc
CFLAGS	+= -shared -fPIC


SRCS	= $(SRCDIR)/uvm_hdl.c


ifeq ($(TOOL),error)
all install:
	@echo "\$$(TOOL) variable not set."
	@echo "Use one of:"
	@echo "   make TOOL=questa"
	@echo "   make TOOL=ius"
	@echo "   make TOOL=vcs"
else
all install: $(SONAME)
endif


ifeq ($(TOOL),questa)
CFLAGS += -DQUESTA -I$(MTI_HOME)/include -m32
CC = $(MTI_HOME)/gcc-4.3.3-linux_x86_64/bin/gcc
endif

ifeq ($(TOOL),ius)
CFLAGS += -DNCSIM  -I`ncroot`/tools/include -m32
endif

ifeq ($(TOOL),vcs)
CFLAGS += -DVCS -I $(VCS_HOME)/include -m32
endif



$(SONAME): $(LIBDIR) $(SRCS) Makefile
	$(CC) $(CFLAGS) -o $(SONAME) $(SRCS)

$(LIBDIR):
	mkdir -p $(LIBDIR)

clean:
	rm -rf $(SONAME)

distclean realclean allclean squeakyclean: clean
	rm -rf $(LIBDIR)
