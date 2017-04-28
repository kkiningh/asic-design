----
title: Lession 0: Tools and Setup
author: Kevin Kiningham
layout: default
---

Running the Synopsys toolchain on corn
---

In this course, we use the Synopsys EDA toolsuite for simulation, synthesis,
and place and route. These tools are widely used in industry, but are also
propriatary and very expensive. Fortunately, Stanford has several licenses
students can use for educational purposes.

For Stanford students not associated with a research group, the easiest way to
access the Synopsys toolchain at Stanford is through
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

Now we can load the specific tool we're interested in running. For example, to
load VCS (the Synopsys Verilog simulator) run the following command:

```bash
module load vcs
```

You can see a list of currently loaded modules by running:

```bash
module list
```

To see a list of all avalible modules, run:

```bash
module avail
```

Note that multiple tools can loaded at the same time without issue.

As a final note, it can occasionally be useful to access the tools directly
without using the module system. The tools themselves are located in the folder
`/afs/ir.stanford.edu/class/ee/synopsys/<TOOL_NAME>/<TOOL_VERSION>/`.

(Optional) Setting Up the Synopsys toolchain locally
---

If you're on the Stanford network, you can also run the tools locally. This has
the advantange of potentially being faster but can be more difficult to setup.
Note that this will only work if you are using a compatible operating system
such as Red Hat Enterprise Linux or CentOS (although other versions of Linux
may also work, see below).

### Setup Kerberos and OpenAFS ###

First, install an AFS client for your platform. On Ubuntu 16.10, you can
install openafs by running

```bash
sudo apt-get install openafs-krb5 openafs-client krb5-user module-assistant openafs-modules-dkms
```

When prompted, enter the cell as `ir.stanford.edu` and the cache size as needed
(a size of 512000 is reasonable).

Next, we'll need to setup Kerberos. Run the following commands

```bash
cd /etc
mv krb5.conf krb5.conf.old
curl -O http://web.stanford.edu/dept/its/support/kerberos/dist/krb5.conf
```

Finally, checkout a Kerberos ticket and obtain an AFS token by running the following.
Enter your Stanford password when prompted.

```bash
kinit
aklog
```

You should now be able to access the tool folder at `/afs/ir.stanford.edu/class/ee/synopsys/`.

### Compatibilty Setup for Ubuntu ###
---

Unfortunately, Ubuntu is not offically supported by the Synopsys tools.
However, it is possible to run the tools anyway. Note that these instructions
have only been tested with Ubuntu 16.04. They may not work for other versions
or operating systems.

First create a symlink from `/usr/class` to `/afs/ir.stanford.edu/class/`.

```bash
ln -s /usr/class /afs/ir.stanford.edu/class
```

Next, some of the tools rely on outdated library versions. We can workaround
this by creating a symlink to the correct library and adding it to the dynamic
library search path.

```bash
mkdir -p $HOME/.local/lib
ln -s $HOME/.local/lib/libjpeg.so.62 /usr/lib/x86_64-linux-gnu/libjpeg.so.8.0.2
ln -s $HOME/.local/lib/libmng.so.1 /usr/lib/x86_64-linux-gnu/libmng.so.2.0.2
ln -s $HOME/.local/lib/libncurses.so.5 /lib/x86_64-linux-gnu/libncurses.so.5
ln -s $HOME/.local/lib/libtiff.so.3 /usr/lib/x86_64-linux-gnu/libtiff.so.5.2.4
export $LD_LIBRARY_PATH:$HOME/.local/lib/
```

Some tools also attempt to autodetect the current platform and term type.
Override this by setting:

```bash
export ARCH_OVERRIDE=linux
export TERM=xterm+256color
```

Some tools expect that `/bin/sh` is symlinked to `bash` instead of `dash` (Ubuntu default).
Change this by running:

```bash
sudo dpkg-reconfigure dash
```

You should now be able to run the tools normally.
