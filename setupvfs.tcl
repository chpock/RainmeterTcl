# RainmeterTcl
# Copyright (C) 2018 Konstantin Kushnir <chpock@gmail.com>
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.

set auto_path [list]

rename load load_orig
proc load args {
    puts "fake 'load': $args"
}

if { [catch {

    set tcl_ver $tcl_version
    set dst [lindex $argv 2]

    puts "Target kit: $dst"
    puts "Tcl version: $tcl_ver"

    foreach arg [lrange $argv 3 end] {
        switch -glob -- $arg {
            "--tcl=*" { set tcl_path [file normalize [string range $arg 6 end]] }
            "--tk=*"  { set tk_path  [file normalize [string range $arg 5 end]] }
            default {
                error "Unknown arg: $arg"
            }
        }
    }

    if { ![info exists tcl_path] } {
        error "Tcl path is not defined"
    }
    puts "Tcl path: $tcl_path"

    if { ![info exists tk_path] } {
        error "Tk path is not defined"
    }
    puts "Tk path: $tk_path"

    set libs_path [file dirname $tcl_path]

    puts "Libs path: $libs_path"

    set vfslib_path [file join {*}[file split $libs_path] tcl-vfs]

    puts "Tcl-VFS path: $vfslib_path"

    set build_path [file dirname [lindex $argv 1]]

    puts "Build path: $build_path"

    source [file join $vfslib_path library vfs.tcl]
    source [file join $vfslib_path library mk4vfs.tcl]

    if { [file exists $dst] } {
        file delete $dst
    }

    vfs::mk4::Mount $dst $dst

    set filtercopy [list apply {{ src dst args } {
        if { ![file exists $src] } {
            error "Source file not exists: $src"
        }

        set fds [open $src r]
        set data [read $fds]
        close $fds

        foreach { regexp replace } $args {
            regsub -all $regexp $data $replace data
        }

        file mkdir [file dirname $dst]
        set fdd [open $dst w]
        puts -nonewline $fdd $data
        close $fdd

    }}]

    set rcopy [list apply {{ rcopy src dst } {
        if { ![file exists $src] } {
            error "Source file not exists: $src"
        }

        if { ![file isdirectory [set dn [file dirname $dst]]] } {
            file mkdir $dn
        }

        if { [file isdirectory $src] } {
            foreach fn [glob -tails -nocomplain -directory $src *] {

                if { $fn in {demos doc} } continue

                {*}$rcopy $rcopy [file join $src $fn] [file join $dst $fn]
            }
        } {
            switch -- [file extension src] {
                .tcl - .txt - .msg {
                    set fds [open $src r]
                    set fdd [open $dst w]
                    fconfigure $fdd -translation lf
                    fcopy $fds $fdd
                    close $fdd
                    close $fds
                }
                default {
                    file copy $src $dst
                }
            }
            file mtime $dst [file mtime $src]
        }
    }}]
    lappend rcopy $rcopy

    set mcopy [list apply {{ rcopy srcdir flist dstdir } {
        foreach fn $flist {
            {*}$rcopy [file join $srcdir $fn] [file join $dstdir $fn]
        }
    }} $rcopy]

    {*}$rcopy [file join $tcl_path library] [file join $dst lib tcl$tcl_ver]

    {*}$rcopy [file join $tk_path library] [file join $dst lib tk$tcl_ver]

    {*}$rcopy [file join $vfslib_path library] [file join $dst lib vfs]
    {*}$rcopy [file join $vfslib_path pkgIndex.tcl] [file join $dst lib vfs pkgIndex.tcl]
    # don't load any libs for the vfs, it is linked statically
    # and initialized during our bootstrap
    {*}$filtercopy \
        [file join $vfslib_path library vfs.tcl] \
        [file join $dst lib vfs vfs.tcl] \
            {load \[file join \$::vfs::self vfs\d+.a\]} \
            {load {} vfs}

    {*}$rcopy [file join $libs_path procarg] [file join $dst lib procarg]

    #{*}$mcopy [file join $libs_path tcllib modules log] \
    #    {log.tcl logger.tcl loggerAppender.tcl loggerUtils.tcl pkgIndex.tcl} \
    #    [file join $dst lib tcllib modules log]

    #{*}$mcopy [file join $libs_path tcllib modules uev] \
    #    {pkgIndex.tcl uevent.tcl uevent_onidle.tcl} \
    #    [file join $dst lib tcllib modules uev]

    {*}$rcopy [file join $libs_path tkmanager] [file join $dst lib tkmanager]

    {*}$rcopy [file join $libs_path twapi twapi tcl] [file join $dst lib twapi]
    {*}$mcopy [file join $libs_path twapi] \
        {twapi_entry.tcl} \
        [file join $dst lib twapi]
    {*}$filtercopy \
        [file join $libs_path twapi pkgIndex.tcl] \
        [file join $dst lib twapi pkgIndex.tcl] \
            {\[file join \$dir libtwapi\d+\.a\]} \
            {{}}

    {*}$mcopy [file join $libs_path tkcon] \
        {tkcon.tcl pkgIndex.tcl} \
        [file join $dst lib tkcon]

    {*}$rcopy [file join $build_path addons boot.tcl] [file join $dst boot.tcl]

    {*}$rcopy [file join $build_path addons rm] [file join $dst lib rm]

    {*}$rcopy [file join $build_path addons icons] [file join $dst extra icons]

    {*}$filtercopy \
        [file join $libs_path rl_json pkgIndex.tcl] \
        [file join $dst lib rl_json pkgIndex.tcl] \
            {\[file join \$dir librl_json\d+\.a\]} \
            {{}}

    {*}$mcopy [file join $libs_path tdom lib] \
        {tdom.tcl} \
        [file join $dst lib tdom]
    {*}$filtercopy \
        [file join $libs_path tdom pkgIndex.tcl] \
        [file join $dst lib tdom pkgIndex.tcl] \
            {\[file join \$dir libtdom[\d.]+\.a\]} \
            {{} tdom}

    {*}$rcopy [file join $libs_path tklib modules tablelist] \
        [file join $dst lib tablelist]

    vfs::unmount $dst

} errmsg] } {
    puts "ERROR: $errorInfo"
}