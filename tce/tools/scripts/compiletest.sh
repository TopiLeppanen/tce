#!/bin/bash
# Compiles and tests TCE source code base.
#
# Setup environment.

# Defaults:
testWithValgrind=no
skipCompileTest=no
gcovTest=no
quickTest=no
cleanupBeforeCompile=yes
skipConfigure=no
kdialogNotifications=no
skipSystemTests=no
useMutt=no
findBreakingRev=no
skipUnitTests=no

# These are used by the script to figure out how many successive compile test
# runs have been executed successfully. After the given count of executions,
# an e-mail is sent. This is for getting some input occasionally from compile 
# test machines to know they are functioning.
goodRunCountFile=~/compile_test_ok_run_count
goodRunsBeforeEmail=10

lastOkRevisionFile=~/tce_last_ok_revision

# Process command line arguments (from Advanced Bash-Scripting Guide).
while getopts "vhngqckmbsui" Option
do
    case $Option in
        v     ) 

        testWithValgrind=yes;;

        s     ) 

        skipSystemTests=yes;;

        g     )

        gcovTest=yes;;      

        c     )

        cleanupBeforeCompile=no;;      

        m     )

        useMutt=yes;;      

        b     )

        findBreakingRev=yes;;      

        q     ) 

        quickTest=yes;;      

        u     ) 

        skipUnitTests=yes;;      

        n     ) 

        skipCompileTest=yes;;

        k     )

        kdialogNotifications=yes;;

        i     ) 

        installaftercompile=yes;;

        h     ) 

        echo "TCE Compile Test (c) 2003-2006 Pekka Jääskeläinen";
        echo
        echo "switches: ";
        echo
        echo "-v  After compile testing, run unit tests with Valgrind.";
        echo "    The last compile test environment is used, no ";
        echo "    recompilation is done before running the tests.";
        echo
        echo "-s  Skip system tests.";
        echo
        echo "-u  Skip unit tests.";
        echo
        echo "-m  Use mutt as mailer.";
        echo
        echo "-g  After compile testing, run the Gcov test (gcov.php).";
        echo "    Gcov test is run in compiler environment defined in";
        echo "    file gcov_env.";
        echo
        echo "-n  Skip over normal compile testing and run only Valgrind";
        echo "    and/or Gcov test if -v and/or -g is given. Note that";
        echo "    the Valgrind test expects to find a fully configured ";
        echo "    and compiled code base for the Valgrind unit tests.";
        echo
        echo "-q  Use only the current environment for compile testing.";
        echo "    Do not use any env_* files. Can be used for quick compile ";
        echo "    testing before committing changes. Does not configure ";
        echo "    the code base before compiling! Does not run the long ";
        echo "    running test suite.";
        echo
        echo "-c  Does not clean the code base after running configure. ";
        echo "    This allows speeding up the compilation when using '-q' ";
        echo "    and having compiled the code base already. Tests are ";
        echo "    executed normally. This allows even quicker testing of ";
        echo "    code base before committing. It only makes sure that ";
        echo "    the code base builds (no errors) and tests pass.";
        echo
        echo "-k  Use KDialog to show GUI notifications of the compile test ";
        echo "    progress.";
        echo
        echo "-i  Install tce after compile.";

        exit 0;;

        *     ) exit 2;; # Unknown switch given.
    esac
done

if [ "x$quickTest" = "xyes" ]; then

    COMPILER_ENVIRONMENTS=/dev/null
    ENV_DESC="Current environment (no env files used)"

else

    COMPILER_ENVIRONMENTS=`ls -t1 /usr/scripts/env* ~/scripts/env* env* 2>/dev/null| grep -Exv ".*csh|.*~"`

fi

GCOV_ENV=`ls -t1 /usr/scripts/gcov_env ~/scripts/gcov_env gcov_env 2>/dev/null|head -1`

# Get lines from compilation output that matches one of these regexps.
WARNINGS="\
.*[wW]arning[[:space:]]*:.*|\
.*warning[[:space:]]#.*|\
.*[eE]rror[[:space:]].*|\
.*error:.*|\
.*no[[:space:]]matching[[:space:]]function.*|\
.*cannot[[:space:]]convert.*|\
.*no[[:space:]]matching[[:space:]]function.*|\
.*[[:space:]]error[[:space:]].*|\
.*is[[:space:]]invalid.*|\
.*[[:space:]]undeclared[[:space:]].*|\
.*implicit[[:space:]]declaration.*|\
.*catastrophic[[:space:]]error.*|\
.*[[:space:]]undefined[[:space:]].*"

# Filter away lines that match one of these regexps from lines acquired 
# with WARNINGS regexps.
WARNING_FILTERS="|\
/usr/local/.*include/xercesc/.*|\
.*/usr/local/stow/wx.*|\
.*type.qualifier.is.meaningless.on.cast.type.*|\
.*boost/type_traits/is.*warning.*|\
.*boost/regex/v4/instances.hpp:.*warning:.*|\
.*GT.*longlong.h.*|\
.*does.not.support..long.long.*|\
runner.cpp.*|\
.*warning.#1125.*|\
.*warning.#654.*|\
.*_dummy;.*|\
.*included.from.*xerces.*|\
.*included.from.*boost.*|\
[[:space:]]*^[[:space:]]*|\
.*unrecognized[[:space:]]*#pragma.*|\
.*boost_1_31_0-gcc_2.95.4.*|\
.*Unknown.compiler.version.-.please.run.the.configure.tests.and.report.the.results.*|\
.*/usr/include/wx-2.6/wx/.*warning.*dereferencing.type.punned.*|\
.*TargetMemory.cc.*warning.*dereferencing.type.punned.*|\
.*MemoryGridTable.cc.*warning.*dereferencing.type.punned.*|\
.*TestSuite.h:.*warning.*comparison.between.signed.and.unsigned.*|\
/usr/include/wx-2.8/.*warning.*|\
.*install:.warning:.relinking.*|\
Inconsistency.detected.by.ld\.so:.*Assertion.*"

SYSTEM_TEST_WARNING_FILTERS="\
PHP Warning:  mime_magic: type regex.*"

UNIT_TEST_WARNINGS="\
$WARNINGS|\
.*failed.*|\
In[[:space:]].*|\
.*Error[[:space:]].*|\
.*[[:space:]]Expected[[:space:]].*|\
Failed.*|\
.*\(s\)\.*Running.*|\
.*catastrophic[[:space:]]error.*|\
.*no[[:space:]]method.*"

# Filter these lines away from Valgrind output.
VALGRIND_FILTERS="\
.*[[:space:]]0[[:space:]]bytes.*|\
Running[[:space:]][0-9].*" 

# Get these lines from valgrind output after filtering previous lines.
VALGRIND_WANTED="\
.*using valgrind.*|\
.*=[[:space:]]Invalid[[:space:]]read.*|\
.*[[:space:]]lost:.*|\
.*depends[[:space:]]on[[:space:]]uninitialised.*|\
.*contains[[:space:]]uninitialised[[:space:]].*"

# remove -j parameter from makeflags to avoid an error with make jobserver
MAKEFLAGS="${MAKEFLAGS#-j[0-9]}"
MAKEFLAGS="${MAKEFLAGS#[0-9[:space:]]}"
MAKE_OPT="-j2 -k"

export PATH="$PATH:/bin:/usr/local/bin:/usr/bin"

USER=`whoami`

if [ "$USER" == "root" ]; then
    ERROR_MAIL=yes
    LOG_DIR="/var/log/compiletest" 
    ERROR_MAIL_SENDER="tce@DONOTREPLY.cs.tut.fi"
    ERROR_MAIL_ADDRESS="tce-logs@cs.tut.fi"
else
    if [ "$ERROR_MAIL" != "yes" ]; then
        ERROR_MAIL=no
    fi
    if [ ! "$ERROR_MAIL_SENDER" ]; then
        ERROR_MAIL_SENDER="$USER"
    fi
    if [ ! "$ERROR_MAIL_ADDRESS" ]; then
        ERROR_MAIL_ADDRESS="$USER"
    fi                          
    LOG_DIR="$PWD"
fi

# number of lines to tail from error log when mailing the error report
LINES_FROM_ERROR_LOG=1500

# test dir names under tce root
SYSTEMTEST_DIR="systemtest"
SYSTEMTEST_LONG_DIR="systemtest_long"
UNITTEST_DIR="test"

LOG_FILE="$LOG_DIR/compiletest.log"
ERROR_LOG_FILE="$LOG_DIR/compiletest.error.log"
LOG_TIMESTAMP="`date +"%d.%m.%y %H:%M"`"

# whitespace that is as long as the timestamp
# used to pretty-print log file
SPACER="              "

# command to get time in unix time (seconds since 1970)
# used by the timer
SECONDS_CMD="date +%s"

ERROR_MAIL_SUBJECT="OMG! Compiletest was a disaster @ ${HOSTNAME}"
if [ "x${useMutt}" == "xyes" ]; then
    MAIL_BIN=`which mutt`
else
    MAIL_BIN=`which mail`
fi
MAILER="$MAIL_BIN -s \"$ERROR_MAIL_SUBJECT\" $ERROR_MAIL_ADDRESS"

TEMP_FILE=`mktemp /tmp/compiletest.$USER.XXXXXXX` || exit 1

# Global variable for storing the compiler version we are currently testing.
running_compiler=""

# Global "boolean" variable for setting the test failure status.
errors="no"

DEBUG_OUTPUT="yes"

# If compilation fails, do not proceed to unit tests?
RETURN_IF_ERRORS="no"

currentLine=""

firstDialog=yes

function debug_print {
    if [ "$DEBUG_OUTPUT" == "yes" ]; then
        echo -e "$*"
    fi
    currentLine="${currentLine} $*"
    if [ "$kdialogNotifications" == "yes" ]; then
        if [ "$firstDialog" == "no" ]; then
            # Wait for the old dialog to die first...
            fg > /dev/null 2>&1
        fi
        kdialog --title "TCE compile+test progress:" --passivepopup "${currentLine}" 3 > /dev/null 2>&1 &
        firstDialog="no"
    fi
    currentLine=""
}

function debug_print_noendl {
    if [ "$DEBUG_OUTPUT" == "yes" ]; then
        echo -n "$*"
    fi

    if [ "$kdialogNotifications" == "yes" ]; then
        currentLine="${currentLine} $*"
    fi
}

function push_dir {
    pushd . > /dev/null
}

function pop_dir {
    popd > /dev/null
}

# Logs possible failure to error log. 
#
# Failure is detected from the file size of TEMP_FILE which is expected to 
# contain the error output of the program thus size being nonzero in case
# of error.
#
# parameter 1: title of stage e.g. "compilation"
function log_failure {
    if [ -s $TEMP_FILE ]; then
        if [ "x${SKIP_ERROR_LOGGING}" != "xyes" ]; then
            # print revision number when loggin errors
            if [ "x${rev_to_up}" == "x" ]; then
                local _rev_info="With revision ${START_REV}."
            else
                local _rev_info="With revision ${rev_to_up}."
            fi
            echo "$1 errors! ${_rev_info}" >> $LOG_FILE
            echo -e "<$1 errors with $running_compiler. ${_rev_info}>" >> $ERROR_LOG_FILE
            cat $TEMP_FILE >> $ERROR_LOG_FILE
            echo -e "</$1 errors with $running_compiler. ${_rev_info}>" >> $ERROR_LOG_FILE
            echo >> $ERROR_LOG_FILE
        fi
        errors="yes"
        debug_print_noendl PROBLEMS.
    else
        debug_print_noendl OK.
    fi
}

# parameters:
# 1: compiler version number to change to
function change_compiler_env {
    source $1
    running_compiler="$ENV_DESC"
}

# Reconfigures the source base by running "./configure" at the current dir.
function reconfigure {
    push_dir

    autoreconf > /dev/null 2>&1 && ./configure $CONFIGURE_SWITCHES \
        $TCE_CONFIGURE_SWITCHES 1> /dev/null 2> $TEMP_FILE

    if [ "x$cleanupBeforeCompile" = "xyes" ]; then
        make clean 1> /dev/null 2>> $TEMP_FILE
    fi

    log_failure configuration

    pop_dir
}

# Compiles the source base by running 'make' at the current directory.
function compile {
    push_dir

    {
        make $MAKE_OPT 2>&1 | grep -Ex $WARNINGS | grep -vEx $WARNING_FILTERS
    } 1> $TEMP_FILE 2>&1
    
    log_failure compilation

    pop_dir
}

# make install
function install {
    push_dir

    {
        make dev-install 2>&1 | grep -Ex $WARNINGS | grep -vEx $WARNING_FILTERS
    } 1> $TEMP_FILE 2>&1
    
    log_failure installation

    pop_dir
}

# "Pretty prints" elapsed time (e.g. 12d4h1m23s).
# 
# 1: time in seconds
function prettyPrintTime {
    seconds=$1

    hours=`expr $seconds / 3600`

    seconds=`echo $seconds - $hours \* 3600 | bc`

    if [ $hours != "0" ]; then
        echo -n ${hours}h
    fi

    minutes=`expr $seconds / 60`
    seconds=`echo $seconds - $minutes \* 60 | bc`

    if [ $hours != "0" -o $minutes != "0" ]; then
        echo -n ${minutes}m
    fi

    echo ${seconds}s
}

# Run unit tests for the code base.
function run_unit_tests {
    push_dir

    cd $UNITTEST_DIR
    {
        make clean &> /dev/null 
        make 2>&1 | grep -Ex "$UNIT_TEST_WARNINGS" | grep -vEx $WARNING_FILTERS || true 
        make clean &> /dev/null 
    } 1> $TEMP_FILE 2>&1

    # sets errors=yes if $TEMP_FILE size non zero
    log_failure testing

    # if unit test errors change stop testing them (only with -b)
    if [[ "${last_unit_test_error}x" != "x" && "${errors}x" != "nox" && \
          "${last_unit_test_error}x" != "$(cat ${TEMP_FILE})x" ]]; then
        errors="no"
        echo "Unit testing stopped, because errors changed!" >> ${LOG_FILE}
    fi
    last_unit_test_error="$(cat ${TEMP_FILE})"

    if [[ "x${findBreakingRev}" == "xyes" && \
          "${last_unit_test_error}x" == "x" ]]; then
        cd ..
        echo_broken_unittest_info >> $ERROR_LOG_FILE
    fi

    pop_dir
}

# Run system tests for the code base.
function run_system_tests {
    push_dir

    if [ "x${findBreakingRev}" == "xyes" ]; then
        STPARAM="-bo"
    else
        STPARAM="-o"
    fi

    cd $SYSTEMTEST_DIR
    {
        ../tools/scripts/systemtest.php $STPARAM 2>&1 | grep -vE "$SYSTEM_TEST_WARNING_FILTERS"
    } 1> $TEMP_FILE 2>&1

    log_failure system_testing

    if [ -e "broken_system_tests.temp" ]; then
        echo_broken_systemtest_info >> $ERROR_LOG_FILE
    fi

    pop_dir
}

# Run long system tests for the code base.
function run_long_system_tests {
    push_dir

    if [ "x${findBreakingRev}" == "xyes" ]; then
        STPARAM="-bo"
    else
        STPARAM="-o"
    fi

    cd $SYSTEMTEST_LONG_DIR
    {
        ../tools/scripts/systemtest.php $STPARAM 2>&1 | grep -vE "$SYSTEM_TEST_WARNING_FILTERS"
    } 1> $TEMP_FILE 2>&1

    log_failure long_testing

    if [ -e "broken_system_tests.temp" ]; then
        echo_broken_systemtest_info >> $ERROR_LOG_FILE
    fi

    pop_dir
}

function echo_broken_unittest_info {
    if [[ "x${errors}" == "xno" && "x${last_tested_rev}" != "x${rev_to_up}" ]]; then
        bad_coder="$(bzr revno)"
        echo "Unit tests OK! in revision: ${rev_to_up}."
        echo -e "\t Breaking revision was ${last_tested_rev} commited by ${bad_coder}.\n"
    fi 
}

function echo_broken_systemtest_info {
    echo "UPDATE THIS FOR bzr!."; exit 1;
    testdesc="$(grep -E ' [0-9]+$' broken_system_tests.temp)"
    cd .. # to tce root dir from systemtest dir
    if [[ "x${testdesc}" != "x" && "x${last_tested_rev}" != "x" && "x${rev_to_up}" != "x" ]]; then
        bad_coder="$(svn info -r ${last_tested_rev} | grep -E 'Author:' | grep -Eio '[[:alnum:]]+$')"
        echo -e "[test]\t\t[last working revision]\n${testdesc}"
        echo -e "\t Breaking revision was ${last_tested_rev} commited by ${bad_coder}.\n"
    fi
}

# Run unit tests with valgrind for the code base.
function run_tests_with_valgrind {
    push_dir
    prevline=""
    cd test
    {
        make clean 1> /dev/null 
        make valgrind=yes 2>&1 | \
        grep -vEx "$VALGRIND_FILTERS" | \
        grep -Ex "$VALGRIND_WANTED" | \
        while read line; do \
            if [ "`echo x$line | cut -b -8`" != "xRunning" ]; then
                echo $prevline;
            else
                if [ "`echo x$prevline | cut -b -8`" != "xRunning" ]; then
                    echo $prevline;
                fi;
            fi;
            prevline=$line
        done

        # The last while loop filters out filenames that have no errors.
        # Terrible hack, huh? :)

    } 1> $TEMP_FILE 2>&1

    log_failure valgrind

    pop_dir
}

startTime=0
# Starts the timer.
function startTimer {
    startTime=`$SECONDS_CMD`
}

# Stops the timer and pretty prints the elapsed time.
function stopTimer {
    stopTime=`$SECONDS_CMD`
    elapsedTimeSec=`expr $stopTime - $startTime`
    prettyPrintTime $elapsedTimeSec
}

# parameters:
# 1: project root (where to run configure and make)
# 2: env file name
function compile_test {

    push_dir
    cd $1 1> /dev/null 2>&1

    # compile test started with revision
    START_REV="$(bzr revno)"
    echo "Current revision of $(basename $(pwd)) is ${START_REV}." 

    errors="no"

    echo -n "$2: " >> $LOG_FILE

    # run configure if not quick tests
    if [ "x$quickTest" == "xno" ]; then
        debug_print_noendl " configure: "
        reconfigure  
        debug_print ""
    fi

    # compilation
    run_tests "compile: " "compile"

    if [ "x$installaftercompile" == "xyes" ]; then
        # install after compile
        run_tests "install: " "install"
    fi

    if [ "x${errors}" == "xyes" -a "x${RETURN_IF_ERRORS}" == "xyes" ]; then
        pop_dir
        return
    fi  
    errors="no"

    # remove broken test temp lists written by systemtest.php
    rm -rf "./${SYSTEMTEST_DIR}/broken_system_tests.temp"
    rm -rf "./${SYSTEMTEST_LONG_DIR}/broken_system_tests.temp"

    # remove broken unit test temp list, not implemented yet (TODO)
    # rm -rf "./${UNITTEST_DIR}/broken_unit_tests.temp"

    # TODO: add compile test failed
    unit_tests_failed="yes"
    system_tests_failed="yes"
    long_system_tests_failed="yes"
    # TODO: limit unit tests with count or error diff

    while true; do
        # unit test function
        if [ "x$skipUnitTests" == "xno" -a "x$unit_tests_failed" == "xyes" ]; then 
            run_tests "unit tests: " "run_unit_tests"
        fi

        test_errors_for unit_tests_failed

        if [ "x$skipSystemTests" == "xno" ]; then

            # short system test function
            if [ "x$system_tests_failed" == "xyes" ]; then 
                run_tests "sys tests: " "run_system_tests"
            fi

            test_errors_for system_tests_failed

            # long system test function
            if [ "x$quickTest" == "xno" -a "x$long_system_tests_failed" == "xyes" ]; then 
                run_tests "long tests: " "run_long_system_tests"
            fi

            test_errors_for long_system_tests_failed
        fi

        # loop test
        if [[ "x${findBreakingRev}" == "xyes" && \
            ( "x${unit_tests_failed}" == "xyes" || \
              "x${system_tests_failed}" == "xyes" || \
              "x${long_system_tests_failed}" == "xyes" ) ]]; then

            echo "DEBUG LOOP TEST: ${findBreakingRev}, ${unit_tests_failed}, ${system_tests_failed}, ${long_system_tests_failed}" >> ${LOG_FILE}
            SKIP_ERROR_LOGGING="no"
            update_tce_to_last_changed_rev
            continue;
        else
            break;
        fi
    done

    pop_dir
}

function test_errors_for {
    if [ "x${errors}" != "xno" ]; then
        eval ${1}="yes"
        errors="no"
    else
        eval ${1}="no"
    fi
}

function run_tests {
    debug_print_noendl "${1}"
    echo -n "${1}" >> $LOG_FILE
    startTimer
    $2
    testing_time=`stopTimer`
    if [ "$errors" == "no" ]; then
        # get the testing time
        echo "OK (${testing_time})" >> ${LOG_FILE}
        debug_print " (${testing_time})"
    else
        echo "FAILED! (${testing_time})"
        echo "FAILED! (${testing_time})" >> ${LOG_FILE}
    fi
}

# excepts that cwd is tce root dir
function update_tce_to_last_changed_rev {
    echo "UPDATE THIS FOR bzr!."; exit 1;
    last_tested_rev="$(bzr revno)"
    rev_to_up="$(svn info -r "$(expr ${last_tested_rev} - 1)" | grep 'Last Changed Rev: ' | grep -Eo '[0-9]+$')"
    # quick fix for unit test svn screwage
    rm -rf "test/base"
    rm -rf "test/applibs/Explorer/ExplorerPluginTest/data/test.dsdb"
    up_check="$(svn up -r "${rev_to_up}" 2>&1 1>/dev/null)"
    echo "DEBUG: revision ${rev_to_up} got from: $(pwd)" >> ${LOG_FILE}
    if [ "x${up_check}" != "x" ]; then 
        echo "svn error: ${up_check}"
        echo "Updating tce to revision ${rev_to_up} in dir $(pwd) -- FAILED."
        exit 1
    fi
    echo -e -n "Compiling revision: ${rev_to_up}..."
    # TODO: exit if compile failed with error
    compile
    echo ""

    errors="no"
}

# this function can be used to easily test this script when using option -b
function break_tests {
    echo "UPDATE THIS FOR bzr!."; exit 1;
    # first revision
    rev_to_up=${rev_to_up:="3398"}

    # break test 1
    if [ "${rev_to_up}" -ge "3398" ]; then
        echo "BREAK" > ./systemtest/bintools/PIG/function_pointer/1_output.txt 
    else
        svn revert ./systemtest/bintools/PIG/function_pointer/1_output.txt
    fi

    # break test 2
    if [ "${rev_to_up}" -ge "3395" ]; then
        echo "BREAK" > ./systemtest/codesign/Estimator/worm/1_output.txt 
    else
        svn revert ./systemtest/codesign/Estimator/worm/1_output.txt 
    fi
}

function getLines {
    count=$1
    lines=""
    while `expr $count \> 0 > /dev/null`;
    do
        lines="$lines-"
        count=`expr $count - 1`
    done;
    echo $lines
}

function handleError {
    if [ "x$errors" == "xno" ]; then
        # Get the testing time.
        testing_time=`stopTimer`
        echo "OK ($testing_time)" >> $LOG_FILE
        debug_print " ($testing_time)"
    else
        echo "FAILED!";
    fi
}

# parameters:
# 1: project root (i.e. where to run configure and make)
function compile_test_with_all_compilers {

    mkdir -p ${LOG_DIR}
    lineLength=79
    echo -n > $ERROR_LOG_FILE
    echo -n "$LOG_TIMESTAMP: " >> $LOG_FILE

    if [ "x$COMPILER_ENVIRONMENTS" == "x" ]; then
        COMPILER_ENVIRONMENTS=/dev/null
        ENV_DESC="Current shell environment"
    fi

    if [ "x$skipCompileTest" != "xyes" ]; then

        for COMPILER in $COMPILER_ENVIRONMENTS
        do
            change_compiler_env $COMPILER
            line=`getLines $lineLength`
            echo $line 
            debug_print $ENV_DESC. 
            echo $line 
            compile_test $1 `basename $COMPILER`
            echo -n "$SPACER: " >> $LOG_FILE
        done;

    fi

    # The Valgrind test.
    if [ "x$testWithValgrind" = "xyes" ]; then
        push_dir
        cd $1 1> /dev/null 2>&1

        debug_print_noendl "  valgrind: "
        echo -n "valgrind: " >> $LOG_FILE

        errors="no"
        startTimer
        run_tests_with_valgrind

        handleError

        echo -n "$SPACER: " >> $LOG_FILE
        pop_dir
        debug_print $line
    fi
    
    # The Gcov test.
    if [ "x$gcovTest" = "xyes" ]; then

        # Change to the gcov compiler environment.
        source ${GCOV_ENV} || exit 3;
        running_compiler=gcov_env

        push_dir
        cd $1 1> /dev/null 2>&1 
 
        debug_print_noendl "      gcov: "
        echo -n "gcov: " >> $LOG_FILE

        errors=no

        ./configure --with-gcov > /dev/null
        make clean > /dev/null 2>&1 

        startTimer

        tools/scripts/gcov.php 2>&1 | grep -v "##" > $TEMP_FILE

        log_failure gcov

        handleError

        echo -n "$SPACER: " >> $LOG_FILE
        pop_dir
        debug_print $line
    fi

    if [ -s $ERROR_LOG_FILE ]; then
        debug_print Errors were found during testing.
        echo "FAILED!" >> $LOG_FILE
        echo 0 > $goodRunCountFile
    
        push_dir
        cd $1 > /dev/null 2>&1
        if [ "${last_tested_rev}x" == "x" ]; then
            bzr log --short -l 1 >> $ERROR_LOG_FILE 2>&1
        else    
            bzr log --short -r ${last_tested_rev} >> $ERROR_LOG_FILE 2>&1
        fi
        pop_dir 
    
        echo "Last passed revision:" >> $ERROR_LOG_FILE
        cat $lastOkRevisionFile >> $ERROR_LOG_FILE 2>&1

        if [ "x$ERROR_MAIL" == "xyes" ]; then
            tail -n ${LINES_FROM_ERROR_LOG} $ERROR_LOG_FILE | eval $MAILER 
        fi
    else
        echo "OK." >> $LOG_FILE
        debug_print No errors were found during testing.
        if [ -e $goodRunCountFile ]; then
            goodRuns=$(cat $goodRunCountFile)
        else
            goodRuns=0
        fi

        goodRuns=$(expr $goodRuns + 1)
        echo -n $goodRuns > $goodRunCountFile

        push_dir
        cd $1 > /dev/null 2>&1
        bzr log --short -l 1 > $lastOkRevisionFile 2>&1
        pop_dir

        if [ "${goodRuns}" -ge "${goodRunsBeforeEmail}" ]; then

            if [ "x$ERROR_MAIL" == "xyes" ]; then
                # send e-mail that states that everything has been OK for n runs
                eval echo "Good work, guys!" | $MAIL_BIN -s \
"GREAT! Compiletest @ ${HOSTNAME} has been successful $goodRuns times since "\
"the last e-mail." $ERROR_MAIL_ADDRESS 
            fi
            echo -n 0 > $goodRunCountFile
        fi        
    fi

    rm -f $TEMP_FILE
}

#
# END of functions
#

echo " Temp: $TEMP_FILE"
echo "[ === Starting compile test ===]" >> $LOG_FILE
compile_test_with_all_compilers tce .

