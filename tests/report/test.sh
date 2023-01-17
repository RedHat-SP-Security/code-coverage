#!/bin/bash
# vim: dict+=/usr/share/beakerlib/dictionary.vim cpt=.,w,b,u,t,i,k
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
#   runtest.sh of /CoreOS/dummy/Sanity/setup
#   Description: Recompile src rpm with required flags
#   Author: Martin Zeleny <mzeleny@redhat.com>
#
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
#   Copyright (c) 2022 Red Hat, Inc.
#
#   This program is free software: you can redistribute it and/or
#   modify it under the terms of the GNU General Public License as
#   published by the Free Software Foundation, either version 2 of
#   the License, or (at your option) any later version.
#
#   This program is distributed in the hope that it will be
#   useful, but WITHOUT ANY WARRANTY; without even the implied
#   warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
#   PURPOSE.  See the GNU General Public License for more details.
#
#   You should have received a copy of the GNU General Public License
#   along with this program. If not, see http://www.gnu.org/licenses/.
#
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

# Include Beaker environment
. /usr/bin/rhts-environment.sh || exit 1
. /usr/share/beakerlib/beakerlib.sh || exit 1


rlJournalStart
    rlPhaseStartSetup
        rlRun "rlImport --all" || rlDie 'cannot continue'
    rlPhaseEnd


    rlPhaseStartTest "Gather results"
        BINARY="/root/rpmbuild/BUILD/scrub-2.6.1/src/scrub"
        APPDIR=$(dirname $BINARY)

        rlRun "lcov --directory ${APPDIR} --capture --output-file tested.info"

        rlRun "mkdir web-report"
        rlRun "genhtml --output-directory web-report tested.info"
        rlRun "tar cvzf report.tgz web-report/*"

        echo "scp root@$(hostname):$(readlink -f report.tgz) ."
        PS1="\[\e[1;31m\]$(grep -o '[0-9.]\+' /etc/redhat-release)\[\e[0m\] " bash
    rlPhaseEnd


#    rlPhaseStartCleanup
#    rlPhaseEnd
#rlJournalPrintText
rlJournalEnd
