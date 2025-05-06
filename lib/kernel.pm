# SUSE's openQA tests
#
# Copyright 2018-2023 SUSE LLC
# SPDX-License-Identifier: FSFAP

# Summary: Kernel helper functions
# Maintainer: Kernel QE <kernel-qa@suse.de>

package kernel;

use base Exporter;
use testapi;
use strict;
use utils;
use version_utils qw(is_sle is_transactional);
use transactional;
use warnings;

our @EXPORT = qw(
  remove_kernel_packages
  get_kernel_flavor
);

sub get_kernel_flavor {
    return get_var('KERNEL_FLAVOR', 'kernel-default');
}

sub remove_kernel_packages {
    my @packages;
    my @devpacks;

    if (check_var('SLE_PRODUCT', 'slert')) {
        # workaround for bsc1227773
        @packages = qw(kernel-rt);
        @devpacks = qw(kernel-rt-devel kernel-source-rt);
    }
    elsif (get_kernel_flavor eq 'kernel-64kb') {
        @packages = qw(kernel-64kb*);
    }
    else {
        @packages = qw(kernel-default);
        @devpacks = qw(kernel-default-devel kernel-macros kernel-source);
    }

    # SLE12 and SLE12SP1 has xen kernel
    if (is_sle('<=12-SP1')) {
        push @packages, qw(kernel-xen kernel-xen-devel);
    }

    my @rmpacks = @packages;
    push @rmpacks, @devpacks unless is_transactional;
    push @rmpacks, "multipath-tools"
      if is_sle('>=15-SP3') and !get_var('KGRAFT');

    if (is_transactional) {
        trup_call 'pkg remove ' . join(' ', @rmpacks);
    } else {
        zypper_call('-n rm ' . join(' ', @rmpacks), exitcode => [0, 104]);
    }

    return (@packages, @devpacks);
}

1;
