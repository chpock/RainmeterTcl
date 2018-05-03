# RainmeterTcl
# Copyright (C) 2018 Konstantin Kushnir <chpock@gmail.com>
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.

namespace eval ::rm {
    namespace export *
    namespace ensemble create
}

namespace eval ::rm::raw {
}

proc ::rm::getMeasureName {} {
    tailcall ::rm::raw::get 0
}

proc ::rm::getSettingsFile {} {
    return [file normalize [::rm::raw::get 2]]
}

proc ::rm::getSkinName {} {
    tailcall ::rm::raw::get 3
}

proc ::rm::lexecute { list } {
    tailcall execute "\[[join $list "\]\["]\]"
}
proc ::rm::lexec { list } {
    tailcall lexecute $list
}

proc ::rm::execute { str } {
    tailcall ::rm::raw::execute $str
}
proc ::rm::exec { str } {
    tailcall execute $str
}

proc ::rm::replaceVariables { str } {
    tailcall ::rm::raw::replaceVariables $str
}

proc ::rm::pathToAbsolute { str } {
    return [file normalize [::rm::raw::pathToAbsolute $str]]
}

proc ::rm::readPath { option default } {
    tailcall pathToAbsolute [readString $option $default]
}

proc ::rm::log { args } {

   set usage "usage: ?-error|-warning|-notice|-debug? message"

   if { [llength $args] < 1 || [llength $args] > 2 } {
       return -code error "[info level 0]: wrong # args, $usage"
   }

   if { [llength $args] == 1 } {
       set level 3
       set msg [lindex $args 0]
   } {
       switch -glob -- [lindex $args 0] {
           -e* { set level 1 }
           -w* { set level 2 }
           -n* { set level 3 }
           -d* { set level 4 }
           default {
               return -code error "[info level 0]: wrong log level '[lindex $args 1]', $usage"
           }
       }
       set msg [lindex $args 1]
   }

   ::rm::raw::log $level $msg

}

proc ::rm::readString { option { default {} } { replaceMeasures 1 } } {

    if { ![string is boolean -strict $replaceMeasures] } {
        return -code error "[info level 0]: boolean expected instead of '$replaceMeasures'"
    }

    tailcall ::rm::raw::readString $option $default $replaceMeasures

}

proc ::rm::readFormula { option { default 0 } } {

    if { ![string is double -strict $default] } {
        return -code error "[info level 0]: double expected instead of '$default'"
    }

    tailcall ::rm::raw::readFormula $option $default

}

proc ::rm::readInt { option { default 0 } } {
    tailcall expr { round([readFormula $option $default]) }
}

proc ::rm::readDouble { option { default 0 } } {
    tailcall expr { 1.0 * [readFormula $option $default] }
}

#-----

proc ::rm::setUpdateString { string } {
    set ::rm::raw::UpdateString $string
}

proc ::rm::setMaxValue { value } {
    set ::rm::raw::MaxValue $value
}

proc ::rm::raw::Update {} {

    variable UpdateString
    variable UpdateStringOld

    if { [info exists UpdateString] } {
        set UpdateStringOld $UpdateString
        unset UpdateString
    }

    if { [catch [list ::Update] result] } {
        log -error "Error in the Update procedure: $::errorInfo"
        set result 0
    }

    if { ![string is double -strict $result] } {
        set result 0
    }

    return $result

}

proc ::rm::raw::Reload { maxValue } {

    variable MaxValue

    unset -nocomplain MaxValue

    if { [catch [list ::Reload $maxValue] result] } {
        log -error "Error in the Reload procedure: $::errorInfo"
    }

    if { [info exists MaxValue] && ![string is double -strict $MaxValue] } {
        log -error "The maxValue is not double type: $MaxValue"
        unset MaxValue
    }

}

proc ::rm::raw::ExecuteBang { bang } {

    if { [catch [list uplevel #0 $bang] result] } {
        log -error "Error in the script \[$bang\]: $::errorInfo"
    }

}

package provide rm 0.0.1

# init
apply {{ scriptFile } {

    if { $scriptFile eq "" } {
        return
    }

    if { [catch [list uplevel #0 [list source $scriptFile]] errmsg] } {
        rm log -error "Error while loading the script file: $scriptFile\n$::errorInfo"
        return
    }

    if { [info commands ::Initialize] eq "" } {
        return
    }

    if { [catch [list uplevel #0 ::Initialize] errmsg] } {
        rm log -error "Error while initializing the script file: $scriptFile\n$::errorInfo"
    }

}} [rm readString "ScriptFile"]
