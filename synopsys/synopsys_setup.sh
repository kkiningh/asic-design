# Set up the Synopsys toolchain

### Setup module scripts
export MODULESHOME=/afs/ir.stanford.edu/class/ee/modules/tcl
source $MODULESHOME/init/bash.in

### Load the base toolchain
module load base
module load vcs
module load syn
module load icc
module load lc

### Override arch detection to stop a warning from VCS/DC
export ARCH_OVERRIDE=linux
export VCS_ARCH_OVERRIDE=linux

### Queue If Licenses Are Unavailable
export SNPSLMD_QUEUE=true
export SNPS_MAX_WAITTIME=7200
export SNPS_MAX_QUEUETIME=7200

### Fix VCS builds
# In modern Debian/Ubuntu builds, --as-needed is silently added during linking
# This breaks VCS, since --as-needed requires that you order dynamic libraries
# in a particular way (namely, in the reverse order of the dependency graph)
# To fix this, we need to add --no-as-needed to the list of linker options
# when building with VCS
# See http://stackoverflow.com/questions/42113237/undefined-reference-when-linking-dynamic-library-in-ubuntu-system
VCS_FLAGS="-LDFLAGS -Wl,--no-as-needed"

### Add local overrides for libraries that vcs/dc/icc need
LD_PATH="$HOME/.local/lib/"
export LD_LIBRARY_PATH="$LD_LIBRARY_PATH:${LD_PATH}"

### Helper alias
alias vcs="vcs -full64 ${VCS_FLAGS}"
alias dc_shell="TERM=xterm+256color dc_shell-xg-t -64bit ${DC_FLAGS}"
