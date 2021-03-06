# RainmeterTcl
# Copyright (C) 2018 Konstantin Kushnir <chpock@gmail.com>
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.

#set debug trace

##nagelfar syntax ::rm::raw::replaceVariables 1
##nagelfar syntax ::rm::raw::pathToAbsolute 1
##nagelfar syntax ::rm::raw::execute 1
##nagelfar syntax ::rm::raw::get 1
##nagelfar syntax ::rm::raw::log 2
##nagelfar syntax ::rm::raw::readString 3
##nagelfar syntax ::rm::raw::readFormula 2

##nagelfar syntax ::thread::release 1
##nagelfar syntax ::thread::names 0
##nagelfar syntax ::thread::id 0
##nagelfar syntax ::thread::exists 1
##nagelfar syntax ::thread::send o* x x
##nagelfar syntax ::thread::create o* x

package require procarg 1.0.1

namespace eval ::rm {

    namespace export *
    namespace ensemble create

    variable threads

}

namespace eval ::rm::raw {
}

# ======== helpers

proc ::rm::quote { str } {

    if { [string first \" $str] == -1 } {
        return \"$str\"
    } elseif { [string first \"\"\" $str] == -1 } {
        return "\"\"\"$str\"\"\""
    }

    log -error "[info level 0]: could not quote the value, too many quotes: $str"
    return $str

}

proc ::rm::bang { bang args } {

    set ret [list "!$bang"]

    foreach arg $args {
        lappend ret [quote $arg]
    }

    return "\[[join $ret { }]\]"

}

proc ::rm::lbang { args } {

    set ret [list]

    foreach bang $args {
        lappend ret [bang {*}$bang]
    }

    return [join $ret {}]

}

proc ::rm::replaceVariables { str } {
    _traceCall

    tailcall ::rm::raw::replaceVariables $str
#    set result [::rm::raw::replaceVariables $str]
#    log -trace "Got result from RM API: $result"
#    return $result
}

proc ::rm::pathToAbsolute { str } {
    _traceCall

    return [::rm::raw::pathToAbsolute $str]
}

proc ::rm::lexecute { list } {
    tailcall execute [join $list {}]
}
proc ::rm::lexec { list } {
    tailcall lexecute $list
}
proc ::rm::execBang { args } {
    tailcall execute [bang {*}$args]
}
proc ::rm::lexecBang { args } {
    tailcall execute [lbang {*}$args]
}

proc ::rm::execute { str } {
    _traceCall

    tailcall ::rm::raw::execute $str
}
proc ::rm::exec { str } {
    tailcall execute $str
}

proc ::rm::getPath { option default } {
    _traceCall

    tailcall pathToAbsolute [getOption $option -default $default -replace variables]
}

proc ::rm::getPathResources { } {
    _traceCall

    return [string trimright [getVariable "@"] "\\"]
}

proc ::rm::getPathSkin { } {
    _traceCall

    return [string trimright [getVariable "CURRENTPATH"] "\\"]
}

proc ::rm::writeKeyValue { {args {
    {-section string -allowempty false -default Variables}
    {-key     string -allowempty false -required}
    {-value   string -required}
    {-file    string -allowempty false}
}} } {;##nagelfar variable opts array
    _traceCall

    set cmd [list WriteKeyValue $opts(-section) $opts(-key) $opts(-value)]

    if { [info exists opts(-file)] } {
        lappend cmd [file nativename $opts(-file)]
    }

    tailcall execBang {*}$cmd
}

proc ::rm::log { args } {

   set usage "usage: ?-error|-warning|-notice|-debug|-trace? message"

   if { [llength $args] < 1 || [llength $args] > 2 } {
       return -code error "[info level 0]: wrong # args, $usage"
   }

   if { [llength $args] == 1 } {
       set level 3
       set msg [lindex $args 0]
   } else {
       switch -glob -- [lindex $args 0] {
           -e* { set level 1 }
           -w* { set level 2 }
           -n* { set level 3 }
           -d* {
               if { ![info exists ::debug] || ([string is boolean -strict $::debug] && !$::debug) || (![string is boolean -strict $::debug] && $::debug ne "trace") } {
                   return
               }
               set level 4
           }
           -t* {
               if { ![info exists ::debug] || $::debug ne "trace" } {
                   return
               }
               set level 4
               set prefix "TRACE: "
           }
           default {
               return -code error "[info level 0]: wrong log level '[lindex $args 1]', $usage"
           }
       }
       set msg [lindex $args 1]

       if { [info exists prefix] } {
           set msg "$prefix$msg"
       }
   }

   ::rm::raw::log $level $msg

}

# ======== events

proc ::rm::setUpdateString { string } {
    _traceCall

    set ::rm::raw::UpdateString $string
}

proc ::rm::setReloadMaxValue { value } {
    _traceCall

    if { ![string is double -strict $value] } {
        log -warning "[info level 0]: value is not double: $value"
        set value 0
    }

    set ::rm::raw::MaxValue $value
}

# ======== me

proc ::rm::getSettingsFile {} {
    _traceCall

    return [::rm::raw::get 2]
}

proc ::rm::getSkinName {} {
    _traceCall

    tailcall ::rm::raw::get 3
}

proc ::rm::getMeasureName {} {
    _traceCall

    tailcall ::rm::raw::get 0
}

proc ::rm::getOption { option {args {
    {0                string  -allowempty false}
    {-default         string  -default {}}
    {-replace         string  -restrict {measures variables}}
    {-format          string  -default string -restrict {string integer double}}
}} } {;##nagelfar variable opts array
    _traceCall

    if { $opts(-format) eq "string" } {

        if { ![info exists opts(-replace)] || $opts(-replace) eq "" } {
            tailcall ::rm::raw::readString $option $opts(-default) 0
        } elseif { $opts(-replace) eq "measures" } {
            tailcall ::rm::raw::readString $option $opts(-default) 1
        } else {
            tailcall replaceVariables [::rm::raw::readString $option $opts(-default) 0]
        }

    }

    if { $opts(-default) eq "" } {
        set opts(-default) 0
    ##nagelfar ignore Non static subcommand to {"string is"}
    } elseif { ![string is $opts(-format) -strict $opts(-default)] } {
        log -warning "[info level 0]: the default value for the option '$option' has not allowed type \($opts(-format)\): $opts(-default)"
        set opts(-default) 0
    }

    if { ![info exists opts(-replace)] } {
        set val [::rm::raw::readFormula $option $opts(-default)]
    } else {

        # RM API doesn't allow to parse formula with variables.
        # Also, RM API doesn't allow to parse formula for particular
        # string. So, we retrive the value, then parse it by tcl.

        if { $opts(-replace) eq "measures" } {
            set val [::rm::raw::readString $option $opts(-default) 1]
        } else {
            set val [replaceVariables [::rm::raw::readString $option $opts(-default) 0]]
        }

        set val [string map [list \[ \\\[ \] \\\] \$ \\\$] $val]

        log -trace "Parsing the formula: $val"

        if { [catch [list expr $val] parsed] } {
            log -error "[info level 0]: could not parse the formula '$val': $parsed"
            set val $opts(-default)
        } elseif { ![string is double -strict $parsed] } {
            log -error "[info level 0]: the parse result for the formula '$val' is not double: $parsed"
            set val $opts(-default)
        } else {
            set val $parsed
        }

    }

    if { $opts(-format) eq "integer" } {
        return [expr { round($val) }]
    }

    return [expr { 1.0 * $val }]
}

proc ::rm::setOption { option value {args {
    {0        string -allowempty false}
    {1        string}
    {-section string -allowempty false}
}} } {
    _traceCall

    if { ![info exists opts(-section)] } {
        set opts(-section) [getMeasureName]
    }

    tailcall execBang SetOption $opts(-section) $option $value
}

# ======== variables

proc ::rm::setVariable { var value } {
    tailcall execute [bang SetVariable $var $value]
}

proc ::rm::getVariable { var {args {
    {0        string -allowempty false}
    {-default string -default {}}
    {-format  string -default string -restrict {string integer double}}
}} } {
    _traceCall

    set req "\[#${var}\]"

    set result [replaceVariables $req]

    if { $req eq $result } {
        if { [info exists opts(-default)] } {
            set result $opts(-default)
        } else {
            log -warning "Variable not found: $var"
        }
    } else {

       if { $opts(-format) ne "string" } {

            set result [string map [list \[ \\\[ \] \\\] \$ \\\$] $result]

            log -trace "Parsing the formula: $result"

            if { [catch [list expr $result] parsed] } {
                log -error "[info level 0]: could not parse the formula '$result': $parsed"
                set result $opts(-default)
            } elseif { ![string is double -strict $parsed] } {
                log -error "[info level 0]: the parse result for the formula '$result' is not double: $parsed"
                set result $opts(-default)
            } else {
                set result $parsed
            }

       }

    }

    return $result
}

# ======== foreign measures

proc ::rm::commandMeasure { ms arg {args {
    {0       string -allowempty false}
    {1       string -allowempty false}
    {-config string -allowempty false}
}} } {
    _traceCall

    set cmd [list CommandMeasure $ms $arg]

    if { [info exists opts(-config)] } {
        lappend cmd $opts(-config)
    }

    tailcall execBang {*}$cmd
}

proc ::rm::getMeasureValue { ms {args {
    {0        string -allowempty false}
    {-type    string -restrict {number string percentage min max urlencode timestamp} -default number -allowempty false}
    {-custom  list   -restrict { 1 + }}
}} } {;##nagelfar variable opts array
    _traceCall

    switch -exact -- $opts(-type) {
        number     { set req ":" }
        string     { set req ""  }
        percentage { set req ":%" }
        min        { set req ":MinValue" }
        max        { set req ":MaxValue" }
        urlencode  { set req ":EncodeURL" }
        timestamp  { set req ":Timestamp" }
    }

    if { [info exists opts(-custom)] } {
        set req ":[lindex $opts(-custom) 0]\([join [lrange $opts(-custom) 1 end] ,]\)"
    }

    set req "\[&$ms$req\]"
    set result [replaceVariables $req]

    if { $result eq $req } {
        log -warning "Measure was not found for request: $req"
        return ""
    }

    return $result
}

# ======== groups

proc ::rm::setMeasureState { name state {args {
    {0       string -allowempty false}
    {1       string -allowempty false -restrict {enable enabled show shown disable disabled hide hidden pause unpause toggle update}}
    {-group  switch}
    {-config string -allowempty false}
}} } {;##nagelfar variable opts array
    _traceCall

    if { $state in {show shown enabled} } {
        set state "enable"
    } elseif { $state in {hide hidden disabled} } {
        set state "disable"
    }

    set cmd [list "[string totitle $state]Measure[expr { $opts(-group)?{Group}:{} }]" $name]

    if { [info exists opts(-config)] } {
        lappend cmd $opts(-config)
    }

    tailcall execBang {*}$cmd
}

proc ::rm::setMeterState { name state {args {
    {0       string -allowempty false}
    {1       string -allowempty false -restrict {enable enabled show shown disable disabled hide hidden toggle update}}
    {-group  switch}
    {-config string -allowempty false}
}} } {;##nagelfar variable opts array
    _traceCall

    if { $state in {enable enabled shown} } {
        set state "show"
    } elseif { $state in {disable disabled hidden} } {
        set state "hide"
    }

    set cmd [list "[string totitle $state]Meter[expr { $opts(-group)?{Group}:{} }]" $name]

    if { [info exists opts(-config)] } {
        lappend cmd $opts(-config)
    }

    tailcall execBang {*}$cmd
}

proc ::rm::setSkinState { state {args {
    {0       string -allowempty false -restrict {enable enabled show shown disable disabled hide hidden toggle update redraw refresh}}
    {-group  string -allowempty false}
    {-config string -allowempty false}
}} } {
    _traceCall

    if { $state in {enable enabled shown} } {
        set state "show"
    } elseif { $state in {disable disabled hidden} } {
        set state "hide"
    }

    set cmd [list "[string totitle $state][expr { [info exists opts(-group)]?{Group}:{} }]"]

    if { [info exists opts(-group)] } {

        lappend cmd $opts(-group)

        if { [info exists opts(-config)] } {
            log -warning "[info level 0]: -config option is not supported for groups"
        }

    } elseif { [info exists opts(-config)] && $opts(-config) ne "" } {

        lappend cmd $opts(-config)

    }

    tailcall execBang {*}$cmd
}

# ======== sugar

proc ::rm::meter { command name args } {
    _traceCall

    if { $command in {enable enabled show shown disable disabled hide hidden toggle update} } {
        foreach name $name {
            if { $command in {enable enabled show shown toggle} } {
                setMeterState $name update
            }
            setMeterState $name $command
        }
        return
    }

    if { $command eq "set" } {
        if { [llength $args] != 2 } {
            return -code error "rm::meter - wrong # args: set <name> <option> <value>"
        }
        tailcall setOption [lindex $args 0] [lindex $args 1] -section $name
    }

    if { $command in {exists exist} } {

        set testValue "\[${name}:X\]"

        if { [replaceVariables $testValue] eq $testValue } {
            return 0
        } else {
            return 1
        }

    }

    return -code error "rm::meter - unknown command '$command'"
}

proc ::rm::meterGroup { command name {args {
    {0       string -allowempty false -restrict {enable enabled show shown disable disabled hide hidden toggle update}}
    {1       list   -allowempty false}
    {-config string -allowempty false}
}} } {
    _traceCall

    foreach meter $name {
        if { $command in {enable enabled show shown toggle} } {
            set cmd [list setMeterState $meter update -group]
            if { [info exists opts(-config)] } {
                lappend cmd -config $opts(-config)
            }
            {*}$cmd
        }
        set cmd [list setMeterState $meter $command -group]
        if { [info exists opts(-config)] } {
            lappend cmd -config $opts(-config)
        }
        {*}$cmd
    }
}

proc ::rm::measure { command name args } {
    _traceCall

    if { $command in {enable enabled show shown disable disabled hide hidden pause unpause toggle update} } {
        foreach name $name {
            setMeasureState $name $command
        }
        return
    }

    if { $command eq "set" } {
        if { [llength $args] != 2 } {
            return -code error "rm::measure - wrong # args: set <name> <option> <value>"
        }
        tailcall setOption [lindex $args 0] [lindex $args 1] -section $name
    }

    if { $command eq "get" } {
        tailcall getMeasureValue $name {*}$args
    }

    return -code error "rm::measure - unknown command '$command'"
}

proc ::rm::measureGroup { command name {args {
    {0       string -allowempty false -restrict {enable enabled show shown disable disabled hide hidden pause unpause toggle update}}
    {1       list   -allowempty false}
    {-config string -allowempty false}
}} } {
    _traceCall

    foreach measure $name {
        set cmd [list setMeasureState $measure $command -group]
        if { [info exists opts(-config)] } {
            lappend cmd -config $opts(-config)
        }
        {*}$cmd
    }
}

proc ::rm::skin { command {args {
    {0 string -allowempty false -restrict {enable enabled show shown disable disabled hide hidden toggle update redraw refresh}}
    {-config string -allowempty false}
}} } {
    _traceCall

    set cmd [list setSkinState $command]

    if { [info exists opts(-config)] } {
        lappend cmd -config $opts(-config)
    }

    return [{*}$cmd]
}

proc ::rm::tkcon { } {

    ::thread::send [getThreadGUI] {
        package require tkcon

        if {
            [info exists ::tkcon::PRIV(root)] &&
            [winfo exists $::tkcon::PRIV(root)] &&
            [wm state $::tkcon::PRIV(root)] ne "withdrawn"
        } {
            tkcon hide
        } else {
            tkcon show
            wm iconbitmap .tkcon [file join $::tcl::kitpath extra icons tkcon.ico]
        }

        proc exit { args } {
            tkcon hide
        }

    }

}

# ======== context menu

proc ::rm::setContextMenu { title {args {
    {0       string -allowempty false}
    {-action string -default ""}
    {-index  int    -default 0 -restrict { { 0 + } }}
}} } {;##nagelfar variable opts array
    _traceCall

    if { $opts(-index) == 0 } {

        set idx [getVariable "_lastContextItem" -default ""]

        if { $idx eq "" } {
            set idxShown "1"
        } else {
            set idxShown $idx
        }

        append idxShown " (auto)"

    } else {

        set idx $opts(-index)
        set idxShown $idx

    }

    if { $idx eq "1" } {
        set idx ""
    }

    log -debug "addContextAction N${idxShown}: \"$title\" = $opts(-action)"

    setOption "ContextTitle$idx" $title -section "Rainmeter"
    setOption "ContextAction$idx" $opts(-action) -section "Rainmeter"

    if { $opts(-index) == 0 } {

        if { $idx eq "" } {
            set idx 2
        } else {
            incr idx
        }

        setVariable "_lastContextItem" $idx

    }

}

proc ::rm::resetContextMenu {} {
    _traceCall

    setVariable "_lastContextItem" ""
}

proc ::rm::sendThread { thread code } {
    _traceCall

    if { $thread eq "GUI" } {
        set thread [getThreadGUI]
    }

    ::thread::send $thread [list after idle $code]

}

proc ::rm::getThreadGUI {} {
    _traceCall

    variable __gui_thread

    if { ![info exists __gui_thread] || ![::thread::exists $__gui_thread] } {

        set __gui_thread [newThread]

        ::thread::send $__gui_thread {
            load {} Tk
            wm geometry . 1x1+-10000+-10000
            wm overrideredirect . 1
            wm transient .
            set ::rm::__gui_thread [::thread::id]
        }

    }

    return $__gui_thread
}

proc ::rm::getThreadMain {} {
    _traceCall

    variable __main_thread

    if { [info exists __main_thread] } {
        return $__main_thread
    } else {
        return [::thread::id]
    }

}

proc ::rm::getThreadParent {} {
    _traceCall

    variable __parent_thread

    if { [info exists __parent_thread] } {
        return $__parent_thread
    } else {
        return [::thread::id]
    }

}

proc ::rm::newThread {} {
    _traceCall

    variable threads

    variable __parent_thread
    variable __main_thread

    set tid [::thread::create {thread::wait}]
    ::thread::send $tid {namespace eval ::rm::raw {}}
    ::thread::send $tid [list set ::rm::raw::ptr_rm   $::rm::raw::ptr_rm]
    ::thread::send $tid [list set ::rm::raw::ptr_skin $::rm::raw::ptr_skin]
    ::thread::send $tid [list set ::rm::__parent_thread [::thread::id]]

    if { [info exists ::debug] } {
        ##nagelfar ignore Found constant {"::debug"} which is also a variable.
        ::thread::send $tid [list set ::debug $::debug]
    }

    if { [info exists __main_thread] } {
        ::thread::send $tid [list set ::rm::__main_thread $__main_thread]
    } else {
        ::thread::send $tid [list set ::rm::__main_thread [::thread::id]]
    }

    ::thread::send $tid [list load {} rm]

    lappend threads $tid

    return $tid
}

#-------------------------------------------------------------------------
#----- RAW, must not be used
#-------------------------------------------------------------------------

# This procedure must not be used in procedures from the namespace ::rm::raw
# I had an unhandled exception when I used this procedure in ::rm::raw::Update,
# and when the real update script (::Update) finished with en error.
proc ::rm::_traceCall {} {

    if { ![info exists ::debug] || $::debug ne "trace" } {
        return
    }

    if { [string range [set func [lindex [info level -1] 0]] 0 1] ne "::" } {
        if { [set ns [uplevel 1 [list namespace current]]] eq "::" } {
          set func ::$func
        } else {
          set func ${ns}::[namespace tail $func]
        }
    }

    set cmd [list $func]

    foreach arg [info args $func] {
        if { [catch [list uplevel 1 [list set $arg]] val] } {
            lappend cmd "${arg}=NONE"
        } else {
            lappend cmd "${arg}='$val'"
        }
    }

    if { ![catch [list uplevel 1 [list array get opts]] opts] } {
        lappend cmd "|" "opts='$opts'"
    }

    log -trace [join $cmd { }]

}

proc ::rm::raw::Update {} {

    variable UpdateString
    variable UpdateStringOld

    ::rm::log -trace "Update the measure"

    if { [info exists UpdateString] } {
        set UpdateStringOld $UpdateString
        unset UpdateString
    }

    if { [catch [list ::Update] result] } {
        ::rm::log -error "Error in the Update procedure: $::errorInfo"
        return 0
    }

    set UpdateString $result

    if { ![string is double -strict $result] } {
        set result 0
    }

    return $result

}

proc ::rm::raw::Reload { maxValue } {

    variable MaxValue

    ::rm::log -trace "Reload the measure"

    unset -nocomplain MaxValue

    if { [catch [list ::Reload $maxValue] result] } {
        ::rm::log -error "Error in the Reload procedure: $::errorInfo"
    }

    if { [info exists MaxValue] && ![string is double -strict $MaxValue] } {
        ::rm::log -error "The maxValue is not double type: $MaxValue"
        unset MaxValue
    }

}

proc ::rm::raw::ExecuteBang { script } {

    ::rm::log -trace "Exec script: $script"

    if { [catch [list uplevel #0 $script] result] } {
        ::rm::log -error "Error in the script \[$script\]: $::errorInfo"
    }

}

proc ::rm::raw::Finalize {} {

    ::rm::log -trace "Finalize the measure"

    if { [llength [info commands ::Finalize]] } {
        if { [catch [list ::Finalize] result] } {
            ::rm::log -error "Error in the Finalize procedure: $::errorInfo"
        }
    }

    if { ![info exists ::rm::threads] || ![llength $::rm::threads] } {
        ::rm::log -trace "Finalize: No threads in this measure"
        return
    }

    foreach tid $::rm::threads {

        if { ![::thread::exists $tid] } {
            ::rm::log -debug "Finalize: Thread '$tid' doesn't exist"
            continue
        }

        ::rm::log -debug "Finalize: Killing thread $tid"

        if { [catch {
            ::thread::send $tid {
                if { ![catch {package present Tk}] } {
                    destroy .
                }
                ::rm::raw::Finalize
            }
        } errmsg] } {
            ::rm::log -debug "Finalize: error while destroying the thread: $::errorInfo"
        }

        if { [catch {
            ::thread::release $tid
        } errmsg] } {
            ::rm::log -debug "Finalize: error while releasing the thread: $::errorInfo"
        }

    }

}

proc ::rm::raw::Eval { args } {

    ::rm::log -trace "Eval procedure: $args"

    if { [catch [list uplevel #0 $args] result] } {
        ::rm::log -error "Error during the eval \"[join $args {, }]\": $::errorInfo"
        return ""
    }

    ::rm::log -trace "Eval procedure result: $result"

    return $result

}

proc ::rm::raw::Initialize { scriptFile } {

    rename ::rm::raw::Initialize ""

    ::rm::log -trace "Initialize the measure"

    if { $scriptFile eq "" } {
        return
    }

    if { [catch [list uplevel #0 [list source $scriptFile]] errmsg] } {
        ::rm::log -error "Error while loading the script file: $scriptFile\n$::errorInfo"
        return
    }

    if { [info commands ::Initialize] eq "" } {
        return
    }

    if { [catch [list uplevel #0 ::Initialize] errmsg] } {
        ::rm::log -error "Error while initializing the script file: $scriptFile\n$::errorInfo"
    }

    rename ::Initialize ""

}

package provide rm 0.0.1

# init
# the main thread has no __main_thread variable
if { ![info exists ::rm::__main_thread] } {
    ::rm::raw::Initialize [::rm::getOption "ScriptFile" -replace variables]
}

proc exit { {returnCode {}} } {
    ::rm::log -error "Exit catched: $returnCode"
}
