# RainmeterTcl
# Copyright (C) 2018 Konstantin Kushnir <chpock@gmail.com>
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.

package require procarg

namespace eval ::rm {
    namespace export *
    namespace ensemble create
}

namespace eval ::rm::raw {
}

# ======== helpers

proc ::rm::quote { str } {
    return "\"\"\"$str\"\"\""
}

proc ::rm::bang { bang args } {

    set ret [list "!$bang"]

    foreach arg $args {
        lappend ret [quote $arg]
    }

    return "\[[join $ret { }]\]"

}

proc ::rm::replaceVariables { str } {
    tailcall ::rm::raw::replaceVariables $str
}

proc ::rm::pathToAbsolute { str } {
    return [file normalize [::rm::raw::pathToAbsolute $str]]
}

proc ::rm::lexecute { list } {
    tailcall execute [join $list {}]
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

proc ::rm::getPath { option default } {
    tailcall pathToAbsolute [getOption $option -default $default]
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

# ======== events

proc ::rm::setUpdateString { string } {
    set ::rm::raw::UpdateString $string
}

proc ::rm::setReloadMaxValue { value } {

    if { ![string is double -strict $value] } {
        log -warning "[info level 0]: value is not double: $value"
        set value 0
    }

    set ::rm::raw::MaxValue $value
}

# ======== me

proc ::rm::getSettingsFile {} {
    return [file normalize [::rm::raw::get 2]]
}

proc ::rm::getSkinName {} {
    tailcall ::rm::raw::get 3
}

proc ::rm::getMeasureName {} {
    tailcall ::rm::raw::get 0
}

proc ::rm::getOption { option {args {
    {0                string -allowempty false}
    {-default         string -default {}}
    {-replaceMeasures boolean -default true}
    {-type            string -restrict {string integer double} -default string}
}} } {

    if { $opts(-type) eq "string" } {
        tailcall ::rm::raw::readString $option $opts(-default) $opts(-replaceMeasures)
    }

    if { $opts(-default) eq "" } {
        set opts(-default) 0
    } elseif { ![string is $opts(-type) -strict $opts(-default)] } {
        rm log -warning "[info level 0]: the default value for the option '$option' has not allowed type \($opts(-type)\): $opts(-default)"
        set opts(-default) 0
    }

    set val [::rm::raw::readFormula $option $opts(-default)]

    if { $opts(-type) eq "integer" } {
        return [expr { round($val) }]
    }

    return [expr { 1.0 * $val }]

}

# ======== variables

proc ::rm::setVariable { var value } {
    tailcall execute [bang SetVariable $var $value]
}

proc ::rm::getVariable { var {args {
    {0        string -allowempty false}
    {-default string}
}} } {

    set req "#${var}#"

    set result [replaceVariables $req]

    if { $var eq $result } {
        if { [info exists opts(-default)] } {
            set result $opts(-default)
        } {
            log -warning "Variable not found: $var"
        }
    }

    return $result

}

# ======== foreign measures

proc ::rm::updateMeasure { ms } {
    tailcall execute [bang UpdateMeasure $ms]
}

proc ::rm::getMeasureValue { ms {args {
    {0      string -allowempty false}
    {-type  string -restrict {number string percentage min max urlencode timestamp} -default number -allowempty false}
}} } {

    switch -exact -- $opts(-type) {
        number     { set req ":" }
        string     { set req ""  }
        percentage { set req ":%" }
        min        { set req ":MinValue" }
        max        { set req ":MaxValue" }
        urlencode  { set req ":EncodeURL" }
        timestamp  { set req ":Timestamp" }
    }

    set req "\[$ms$req\]"
    set result [replaceVariables $req]

    if { $result eq $req } {
        log -warning "Measure was not found for request: $req"
        return ""
    }

    return $result

}

# ======== foreign sections

proc ::rm::setSectionOption { section variable value } {
    tailcall execute [bang SetOption $section $variable $value]
}




#-------------------------------------------------------------------------
#----- RAW, must not be used
#-------------------------------------------------------------------------

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

    log -debug "exec: $bang"

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

}} [rm getOption "ScriptFile"]
