Setup
===

Setting up the Synopsys toolchain on Corn
---

In this course, we use the Synopsys EDA toolsuite for simulation, synthesis, and place and route.
These tools are widely used in industry, but they are also propriatary and very expensive.
Fortunately, Stanford has bought educational licenses you can use for this course.

The easiest way to access the Synopsys toolchain at Stanford is through
[corn](https://web.stanford.edu/group/farmshare/cgi-bin/wiki/index.php/Main_Page#corn_info).
Login to corn by opening a terminal and typing the following:

```bash
ssh -X corn.stanford.edu
```

Once you've logged into corn, you'll need to load the base toolchain.

```bash
export MODULESHOME=/afs/ir.stanford.edu/class/ee/modules/tcl
source $MODULESHOME/init/bash.in

module load base
```

Now we can load the specific tool we're interested in. For example, to load VCS
(the Synopsys Verilog simulator), Design Compiler (the Synopsys synthesis tool),
and ICC (the Synopsys palce and route tool) run the following commands:

```bash
module load vcs
module load syn
module load icc
```

Note that multiple tools can loaded at once without issue. To see a list of all avalible
modules type:

```bash
module avail
```

#### Automatically loading Synopsys tools on login ####

You can also load the tools automatically on login. First clone the
[stanford-synopsys-setup](https://github.com/kkiningh/stanford-synopsys-setup)
repo by running the following command:

```bash
git clone git@github.com/stanford-synopsys-setup
```

This repo contains several scripts used to setup the Synopsys toolchain and
libraries. Next, you'll need to add the setup script to your `.bashrc` by
running:

```bash
echo "source `pwd`/stanford-synopsys-setup/setup.sh" >> ~/.bashrc
```

Now, logout and log back in to corn. Check that the Synopsys toolchain has
loaded by running:

```bash
module list
```

(Optional) Setting Up the Synopsys toolchain locally
---

If you're on the Stanford network, you can also run the tools locally. This has
the advantange of being significanly faster (if you have a fast computer!) but
can be much harder to setup.

### Setup OpenAFS ###

To access AFS on a personal computer, install OpenAFS.

Set it up like the following:

TODO

The toolchain is located at `/afs/ir.stanford.edu/class/ee/synopsys/`

### Installing Dependencies ###

TODO

(Optional) Using open source tools
---

As another alternative, for simulation and synthesis it is also possible to use open source tools.

See iverilog, verilator, yosys

