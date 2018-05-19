# RainmeterTcl
# Copyright (C) 2018 Konstantin Kushnir <chpock@gmail.com>
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.

proc tclInit {} {
    rename tclInit {}

    global auto_path tcl_library tcl_libPath tcl_version tclkit_system_encoding

    set dll [file normalize $::tcl::kitpath]
    set tcl_library [file join $dll lib tcl$tcl_version]
    set tcl_libPath [list $tcl_library [file join $dll lib]]

    unset -nocomplain ::tclDefaultLibrary

    if { ![file isdirectory $dll] } {
        set d [mk::select exe.dirs parent 0 name lib]
        set d [mk::select exe.dirs parent $d -glob name vfs*]

        foreach x {vfsUtils vfslib mk4vfs} {
            set n [mk::select exe.dirs!$d.files name $x.tcl]
            if {[llength $n] != 1} { error "$x: cannot find startup script"}

            set s [mk::get exe.dirs!$d.files!$n contents]
            catch {set s [zlib decompress $s]}
            uplevel #0 $s
        }

        vfs::filesystem mount $dll [list ::vfs::mk4::handler exe]
        encoding dirs [list [file join [info library] encoding]]
        encoding system utf-8

    }

    namespace eval ::vfs { variable tclkit_version 1 }
    catch { uplevel #0 [list source [file join $dll config.tcl]] }

    # reset auto_path, so that init.tcl's search outside of tclkit is cancelled
    set auto_path [list $tcl_libPath]

    uplevel #0 [list source [file join $tcl_library init.tcl]]
}