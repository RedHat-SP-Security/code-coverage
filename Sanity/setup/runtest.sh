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

rlJournalStart
    rlPhaseStartSetup
        rlAssertRpm $PACKAGE
        rlRun "TmpDir=\$(mktemp -d)" 0 "Creating tmp directory"
        rlRun "pushd $TmpDir"
    rlPhaseEnd

    rlPhaseStartTest "Instalation"
        rlRun "dnf install -y --enablerepo='epel' lcov rpm-build"
        rlRun "dnf download --source fapolicyd"
        rlRun "dnf builddep -y --enablerepo='*' fapolicyd*"
    rlPhaseEnd

    rlPhaseStartTest "Rebuild"
        # rm -rf rpmbuild/
        # rpm -i fapolicyd*.src.rpm
        # rpmbuild -ba rpmbuild/SPECS/fapolicyd.spec 2>&1 | tee build_log_orig.txt

        rm -rf ~/rpmbuild/
        rlRun "rpm -i fapolicyd*.src.rpm"
        export CFLAGS="$(rpm --eval %{optflags}) -fprofile-arcs -ftest-coverage"
        export LDFLAGS="$(rpm --eval %{build_ldflags}) -lgcov -coverage"

        rlRun "sed -i '/^Release: /s/%/_codecoverage%/' ~/rpmbuild/SPECS/fapolicyd.spec"
        rlRun -s "rpmbuild -ba ~/rpmbuild/SPECS/fapolicyd.spec"

        rlRun "dnf install -y ~/rpmbuild/RPMS/x86_64/fapolicyd-*_codecoverage* ~/rpmbuild/RPMS/noarch/fapolicyd-*_codecoverage*"
    rlPhaseEnd

    rlPhaseStartTest "lcov setup and run app"
        dir=$(dirname $(find ~/rpmbuild -name fapolicyd))
        rlRun "lcov --directory $dir --zerocounters"
        rlRun "$dir/fapolicyd --debug-deny"
    rlPhaseEnd

    rlPhaseStartTest "Gather results"
        rlRun "lcov --directory $dir --capture --initial --output-file fapolicyd_base.info"
        #lcov --directory $dir --capture --output-file fapolicyd_test.info
        rlRun "mkdir html_report"
        rlRun "pushd html_report"
        rlRun "genhtml ../fapolicyd_base.info"
        rlRun "tar cvzf output.tgz *"
        rlLog "$(whoami)@$(hostname):$(readlink -f output.tgz)"
        rlRun "popd"
    rlPhaseEnd

    rlPhaseStartCleanup
        rlRun "popd"
        rlRun "rm -r $TmpDir" 0 "Removing tmp directory"
    rlPhaseEnd
#rlJournalPrintText
rlJournalEnd
