#!/usr/bin/env bash

# Copyright (c) 2018, University of Kaiserslautern
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are
# met:
#
# 1. Redistributions of source code must retain the above copyright notice,
#    this list of conditions and the following disclaimer.
#
# 2. Redistributions in binary form must reproduce the above copyright
#    notice, this list of conditions and the following disclaimer in the
#    documentation and/or other materials provided with the distribution.
#
# 3. Neither the name of the copyright holder nor the names of its
#    contributors may be used to endorse or promote products derived from
#    this software without specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
# "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED
# TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
# PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER
# OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
# EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
# PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
# PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
# LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
# NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
# SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
#
# Author: Éder F. Zulian

source ../../common/defaults.in
source ../../common/util.in

sysver=20180409
imgdir="$FSDIRARM/aarch-system-${sysver}/disks"
bmsuite="parsec-3.0"
img="$imgdir/linaro-minimal-aarch64-${bmsuite}-inside.img"
bmsuiteroot="home"

arch="ARM"
mode="opt"
gem5_elf="build/$arch/gem5.$mode"
cd $ROOTDIR/gem5
if [[ ! -e $gem5_elf ]]; then
	build_gem5 $arch $mode
fi

currtime=$(date "+%Y.%m.%d-%H.%M.%S")
config_script="configs/example/arm/starter_fs.py"
ncores="2"
cpu_options="--cpu=hpi --num-cores=$ncores"
mem_options="--mem-size=1GB"
#tlm_options="--tlm-memory"
disk_options="--disk-image=$img"
kernel="--kernel=$FSDIRARM/aarch-system-${sysver}/binaries/vmlinux.vexpress_gem5_v1_64"
dtb="--dtb=$FSDIRARM/aarch-system-${sysver}/binaries/armv8_gem5_v1_${ncores}cpu.dtb"

bmsuitedir="/$bmsuiteroot/$bmsuite"
parsec_nthreads="$ncores"

# Application : Input size
# Input sizes are test, simdev, simsmall, simmedium, simlarge or native.
apps=(
"blackscholes:test"
"bodytrack:test"
"facesim:test"
"ferret:test"
"fluidanimate:test"
"freqmine:test"
"swaptions:test"
"streamcluster:test"
"blackscholes:simdev"
"bodytrack:simdev"
"facesim:simdev"
"ferret:simdev"
"fluidanimate:simdev"
"freqmine:simdev"
"swaptions:simdev"
"streamcluster:simdev"
"blackscholes:simsmall"
"bodytrack:simsmall"
"facesim:simsmall"
"ferret:simsmall"
"fluidanimate:simsmall"
"freqmine:simsmall"
"swaptions:simsmall"
"streamcluster:simsmall"
"blackscholes:simmedium"
"bodytrack:simmedium"
"facesim:simmedium"
"ferret:simmedium"
"fluidanimate:simmedium"
"freqmine:simmedium"
"swaptions:simmedium"
"streamcluster:simmedium"
"blackscholes:simlarge"
"bodytrack:simlarge"
"facesim:simlarge"
"ferret:simlarge"
"fluidanimate:simlarge"
"freqmine:simlarge"
"swaptions:simlarge"
"streamcluster:simlarge"
"blackscholes:native"
"bodytrack:native"
"facesim:native"
"ferret:native"
"fluidanimate:native"
"freqmine:native"
"swaptions:native"
"streamcluster:native"
)

for e in "${apps[@]}"; do
	a=${e%%:*}
	in=${e#*:}
	bootscript=${a}_${in}_${parsec_nthreads}.rcS
	cat > $bootscript <<- EOM
	#!/bin/bash
	cd $bmsuitedir
	source ./env.sh
	echo "Running parsec $a input $in threads $parsec_nthreads"
	parsecmgmt -a run -p $a -c gcc-hooks -i $in -n $parsec_nthreads
	echo "Benchmark finished."
	sleep 1
	m5 exit
	EOM
	bootscript_options="--script=$ROOTDIR/gem5/$bootscript"
	output_rootdir="fs_output_${bmsuite}_${in}_${currtime}"
	output_dir="$output_rootdir/$a"
	export M5_PATH="$FSDIRARM/aarch-system-${sysver}":${M5_PATH}
	$gem5_elf -d $output_dir $config_script $cpu_options $mem_options $tlm_options $kernel $dtb $disk_options $bootscript_options &
done
wait
