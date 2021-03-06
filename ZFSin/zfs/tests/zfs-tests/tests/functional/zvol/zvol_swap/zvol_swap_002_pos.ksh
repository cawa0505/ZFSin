#!/bin/bash
#
# CDDL HEADER START
#
# The contents of this file are subject to the terms of the
# Common Development and Distribution License (the "License").
# You may not use this file except in compliance with the License.
#
# You can obtain a copy of the license at usr/src/OPENSOLARIS.LICENSE
# or http://www.opensolaris.org/os/licensing.
# See the License for the specific language governing permissions
# and limitations under the License.
#
# When distributing Covered Code, include this CDDL HEADER in each
# file and include the License file at usr/src/OPENSOLARIS.LICENSE.
# If applicable, add the following below this CDDL HEADER, with the
# fields enclosed by brackets "[]" replaced with your own identifying
# information: Portions Copyright [yyyy] [name of copyright owner]
#
# CDDL HEADER END
#

#
# Copyright 2009 Sun Microsystems, Inc.  All rights reserved.
# Use is subject to license terms.
#

#
# Copyright (c) 2013 by Delphix. All rights reserved.
#

. $STF_SUITE/include/libtest.shlib
. $STF_SUITE/tests/functional/zvol/zvol_common.shlib

#
# DESCRIPTION:
#	Add a swap zvol, and consume most (not all) of the space. This test
#	used to fill up swap, which can hang the system.
#
# STRATEGY:
#	1. Create a new zvol and add it as swap
#	2. Fill /tmp with 80% the size of the zvol
#	5. Remove the new zvol, and restore original swap devices
#

verify_runnable "global"
log_assert "Using a zvol as swap space, fill /tmp to 80%."

vol=$TESTPOOL/$TESTVOL
swapdev=$ZVOL_DEVDIR/$vol
if [[ -n "$LINUX" ]]; then
	log_must mkswap $swapdev
	log_must $SWAP $swapdev
else
	log_must $SWAP -a $swapdev
fi

# Get 80% of the number of 512 blocks in the zvol
typeset -i count blks volsize=$(get_prop volsize $vol)
((blks = (volsize / 512) * 80 / 100))
# Use 'blks' to determine a count for dd based on a 1M block size.
((count = blks / 2048))

log_note "Fill 80% of swap"
log_must $DD if=/dev/urandom of=/tmp/$TESTFILE bs=1048576 count=$count
log_must $RM -f /tmp/$TESTFILE
if [[ -n "$LINUX" ]]; then
	log_must swapoff $swapdev
else
	log_must $SWAP -d $swapdev
fi

log_pass "Using a zvol as swap space, fill /tmp to 80%."
