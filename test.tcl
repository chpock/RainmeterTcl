# RainmeterTcl
# Copyright (C) 2018 Konstantin Kushnir <chpock@gmail.com>
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.

set ::debug true

package require Thread

set __failed_count 0

proc run_tests { name dir script args } {

    puts ""
    puts ""
    puts "****************************************************************"
    puts ""
    puts "    Run test bundle: $name"
    puts ""
    puts "****************************************************************"
    puts ""

    set pwd [pwd]
    unset -nocomplain ::test_results

    set tid [::thread::create [format {

        set __failed_count 0
        set __failed_count_prev 0

        if { ![set code [catch {

            set parent_tid %s
            set workdir %s
            set script %s
            set opts %s

            cd $workdir

            set ::argv  [list -singleproc 1 {*}$opts]
            set ::argc  [llength $::argv]
            set ::argv0 "teststub.exe"

        } result]] } {

            # cleanup variables when test file complited
            namespace eval ::tcltest { proc cleanupTestsHook {} {

                variable numTests

                foreach var [info vars ::*] {
                    if { $var ni $::__initial_variables } {
                        unset -nocomplain $var
                    }
                }

                incr ::__failed_count [expr { $numTests(Failed) - $::__failed_count_prev }]
                set ::__failed_count_prev $numTests(Failed)

            }}

            # force load tcltest package
            # some packages (metakit, rl_json) don't load tcltest
            # package because namespace "::tcltest" exists.
            # It is exists because of our ::tcltest::cleanupTestsHook
            # procedure.
            package require tcltest
            namespace import tcltest::*

            set ::__initial_variables [concat [info vars ::*] {
                    ::__initial_variables
                    ::__failed_count
                    ::__failed_count_prev
                    ::auto_index
                    ::ErrorOnFailures
                    ::errorCode
                    ::errorInfo
                    ::chan
                    ::timeCmd
                    ::_main_parser
                    ::parse_in_chunks
            }]
            # global var $::chan used in rl_json tests
            # global var $::ErrorOnFailures used in tcl tests
            # global var $::timeCmd used in vfs tests
            # global vars $::_main_parser/$::parse_in_chunks used in tdom tests

            set code [catch $script result]

        }

        thread::send -async $parent_tid [list set ::test_result [list $__failed_count $code $result $::errorInfo]]
        thread::release

    } [thread::id] [list $dir] [list $script] [list $args]]]

    vwait ::test_result

    if { [lindex $::test_result 1] } {
        puts stderr [join [list \
            "TEST RESULT:" \
            "  code: [lindex $::test_result 1]" \
            "  result: [lindex $::test_result 2]" \
            "  errorInfo: [lindex $::test_result 3]" \
        ] "\n"]
        exit [lindex $::test_result 1]
    }

    incr ::__failed_count [lindex $::test_result 0]

    cd $pwd

}

run_tests "::tdom" [file join [pwd] .. src tdom tests] {

    source ./all.tcl

}

run_tests "::vfs" [file join [pwd] .. src tcl-vfs tests] {

    source ./all.tcl

} -notfile {
    vfsUrl.test
}
# vfsUrl.test is disabled because:
#   1. We don't have the ftp package
#   2. We don't want to depend on ftp.tcl.tk

run_tests "::metakit" [file join [pwd] .. src metakit] {

    source [file join tcl tests all.tcl]

} -notfile {
    commit.test
    object.test
}
# commit.test/object.test are broken

run_tests "::tcl" [file join [pwd] .. src tcl tests] {

    # needed for "tcltests" package
    lappend auto_path [pwd]

    source ./all.tcl

} -notfile {
    aaa_exit.test
    chanio.test
    compile.test
    encoding.test
    env.test
    event.test
    exec.test
    http11.test
    io.test
    ioCmd.test
    main.test
    pkgMkIndex.test
    socket.test
    stack.test
    thread.test
    tcltest.test
    winPipe.test
} -skip {
    basic-46.*
    cmdAH-8.46
    http-4.14
    info-23.*
    regexp-14.3
    regexpComp-14.3
    subst-5.8
    subst-5.9
    subst-5.10
    winFCmd-1.38
}
# disable all files and tests that attempt to run the interpreter
# tests info-23.* disabled because [info frame] is broken because
#     of our the mechanism that runs the tests
# file thread.test doens't like to be started in thread
# test http-4.14 disabled because on Win10 timeout trown before
#     "connect failed connection refused" error and test fails
# test winFCmd-1.38 disabled becuse it not able to find
#     a collistion on Win10 x64

run_tests "::twapi" [file join [pwd] .. src twapi twapi tests] {

    source ./all.tcl

} -file {
    metoo.test
    osinfo.test
} -skip {
    get_memory_info-6.0
    get_memory_info-17.0
}
# get_memory_info-6.0/get_memory_info-17.0 are broken on my machine

run_tests "::rl_json" [file join [pwd] .. src rl_json tests] {

    source ./all.tcl

} -notfile {
    memory.test
}
# memory.test works on linux only

if { $__failed_count } {
    puts ""
    puts "FAILED TESTS COUNT: $__failed_count"
    exit 1
}
