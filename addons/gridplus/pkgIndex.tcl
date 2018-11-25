# RainmeterTcl
# Copyright (C) 2018 Konstantin Kushnir <chpock@gmail.com>
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.

package ifneeded gridplus 2.11 [list apply {{ dir } {

    uplevel #0 [list source [file join $dir gridplus.tcl]]
    namespace import gridplus::*

    # patch gridplus icons
    proc ::gridplus::=: { icon } {

        set result "::icon::$icon"

        if { [llength [info commands $result]] } {
            return $result
        }

        set paths [list \
            [file join $::tcl::kitpath extra icons famfamfam] \
        ]

        foreach path $paths {
            if { [file exists [set fn [file join $path "${icon}.png"]]] } break
            unset fn
        }

        if { ![info exists fn] } {
            return -code error "Could not find the image file for the icon: '$icon'"
        }

        namespace eval ::icon {}
        return [image create photo $result -file $fn -format "png"]

    }

}} $dir]
