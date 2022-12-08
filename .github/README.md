# Summary

This repository contains all versions of the the Accellera Standard
Universal Verification Methodology, for use as a submodule by projects
requiring UVM for any simulator including Verilator.

For installation etc, please see the [Accelera README](../README.md).

# Purpose

This is intended for use by:

1. Any project desiring UVM as a submodule.

2. All projects using UVM with [Verilator](https://verilator.org).  Note
Verilator UVM support is still in development.

3. The [SymbiFlow sv-tests](https://github.com/SymbiFlow/sv-tests) project.

# Source Material

This repository is hosted at https://github.com/chipsalliance/uvm-verilator.

The repository code was downloaded from [Accellera Standard Universal
Verification Methodology
Downloads](https://www.accellera.org/downloads/standards/uvm).

It also contains modifications for [Verilator](https://verilator.org).  All
such modifications have appropriate `ifdef annotations, and once proven are
expected to be fed upstream into future new Accellera releases.

# Tags

GIT tags may be used to select the UVM version of interest:

- master: default branch. Includes "stable" plus any released but potentially unstable features.
- stable: most recent stable release. Currently points to "v2017-1.0".
- standard: most recent Accellera standard release. Currently points to "v2017-1.0".
- v2017-1.0: Accellera release 2018-11.
- v2017-0.9: Accellera release 2018-06.
- v1.2: Accellera release 2014-06.
- v1.1d: Accellera release 2013-03.
- v1.1c: Accellera release 2012-11.
- v1.1b: Accellera release 2012-05.
- v1.1a: Accellera release 2011-12.
- v1.0p1: Accellera release 2011-02.

# License

SPDX-License-Identifier: Apache-2.0

Copyright 2011-2017 Accellera

Licensed under the Apache License, Version 2.0 (the "License"); you may not
use this file except in compliance with the License.  You may obtain a copy
of the License at http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.  See the
License for the specific language governing permissions and limitations
under the License.
