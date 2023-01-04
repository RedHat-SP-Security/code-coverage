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

PACKAGE="fapolicyd"
DIR="/usr/sbin"

rlJournalStart
    rlPhaseStartSetup
        rlRun "rlImport --all" || rlDie 'cannot continue'

#        CleanupRegister 'rlRun "RpmSnapshotRevert"; rlRun "RpmSnapshotDiscard"'
#        rlRun "RpmSnapshotCreate"
        rlRun "rpm -q lcov || epel yum install -y lcov &> /dev/null"

#        rlRun "mkdir ~/code_cov_setup"
#        rlRun "pushd ~/code_cov_setup"

        rlFetchSrcForInstalled "${PACKAGE}"
        rlRun "dnf builddep -y --enablerepo='*' ${PACKAGE}* &> /dev/null"
    rlPhaseEnd


    rlPhaseStartTest "Rebuild"
#        CleanupRegister 'rlRun "rlFileRestore"'
#        rlFileBackup --clean '~/rpmbuild'

        rlRun "rpm -i ${PACKAGE}*.src.rpm"
        rlRun "pushd ~/rpmbuild"

        export CFLAGS="$(rpm --eval %{optflags}) -fprofile-arcs -ftest-coverage"
        export LDFLAGS="$(rpm --eval %{build_ldflags}) -lgcov -coverage"

        rlRun "sed -i '/^Release: /s/%/_codecoverage%/' SPECS/${PACKAGE}.spec"
        rlRun "rpmbuild -ba SPECS/${PACKAGE}.spec &> /dev/null"

#        rlRun "RpmSnapshotRevert"
#        rlRun "RpmSnapshotDiscard"
#        rlRun "RpmSnapshotCreate"

        rlRun "dnf install -y RPMS/x86_64/${PACKAGE}-*_codecoverage* RPMS/noarch/${PACKAGE}-*_codecoverage* &> /dev/null"
        rlRun "popd"
    rlPhaseEnd


    rlPhaseStartTest "lcov setup and run app"
        rlRun "lcov --directory ${DIR} --zerocounters"
    rlPhaseEnd


#    rlPhaseStartCleanup
##        CleanupDo
##        rlRun "rlFileRestore"
##        rlRun "popd"
#    rlPhaseEnd
#rlJournalPrintText
rlJournalEnd
