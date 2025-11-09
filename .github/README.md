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

# Tags and branches

GIT branches contain UVM versions supported or otherwise relevant, and may
point to different revisions over time:

- master: default branch. Currently matches "uvm-2020-3.1-vlt"
- standard: branch with most recent Accellera standard release. Currently matches "uvm-2020-3.1".
- uvm-2017-1.0-vlt: UVM 2017 1.0 plus Verilator changes

GIT tags point to specific upstream standard releases:

- uvm-2020-3.1: Tag of Accellera release 3.1 from 2024-08.
- uvm-2020-3.0: Tag of Accellera release 3.0 from 2024-02.
- uvm-2020-2.0: Tag of Accellera release 2.0 from 2023-02.
- uvm-2020-1.1: Tag of Accellera release 1.1 from 2021-02.
- uvm-2020-1.0: Tag of Accellera release 1.0 from 2020-12.
- uvm-2017-1.1: Tag of Accellera release 1.1 from 2020-06.
- uvm-2017-1.0: Tag of Accellera release 1.0 from 2018-11.
- uvm-2017-0.9: Tag of Accellera release 0.9 from 2018-06.
- uvm-1.2: Tag of Accellera release 1.2 from 2014-06.
- uvm-1.1d: Tag of Accellera release 1.1d from 2013-03.
- uvm-1.1c: Tag of Accellera release 1.1c from 2012-11.
- uvm-1.1b: Tag of Accellera release 1.1b from 2012-05.
- uvm-1.1a: Tag of Accellera release 1.1a from 2011-12.
- uvm-1.0p1: Tag of Accellera release 1.0p1 from 2011-02.

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
