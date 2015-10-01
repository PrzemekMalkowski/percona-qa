#!/bin/bash
# Created by Roel Van de Paar, Percona LLC

# Improvement ideas
# If 5.6 is used (./bin/mysql --version), then use --binary-mode option on client (generated cl + test scripts) to avoid replay issues

# Note that ./start<trialnr> is quite unusable when compared with ./start_mtr<trialnr>. The reason is clear if you consider that most
# --mysqld options which were set in the RQG run are not taken accross into ./start<trialnr>. They are however kept/taken accross in
# the ./start_mtr<trialnr> script). So, it is advisable to always use ./start_mtr<trialnr> as generated by this script to ensure the
# testcase will likely be reproducible. Yet, ./start<trialnr> etc. can prove valuable when reducing testcases (because now the server
# is started without all the options - thus, if the issue reproduces even without all the mysqld options, the complexity of the testcase
# is thereby greatly reduced (it may be challenging to discover which option, if any, is reponsible for a given failure - as it 
# requires removing options one by one (or a few at the time) to see if the issue still reproduces. This is btw also the MYEXTRA string
# used in reducer.sh from RQG - i.e. the "extra options" needed (or not) to reproduce a given issue. Reducer.sh does not test removing
# these options automatically, so it is manual work unless you can simply do a quick test with ./start<trialnr> and see if the issue 
# already reproduces without all the options - thus having greatly reduced the complexity). Note there was also an update made on 
# 22/8/14 that now carries the InnoDB locations accross into ./start<trialnr> which will help with getting the server started. 

PORT=$[$RANDOM % 10000 + 10000]
MTRT=$[$RANDOM % 100 + 700]
BUILD=$(pwd | sed 's|^.*/||')
SKIP_RQG_AND_BUILD_EXTRACT=0

JE1="if [ -r /usr/lib64/libjemalloc.so.1 ]; then export LD_PRELOAD=/usr/lib64/libjemalloc.so.1"
JE2=" elif [ -r /usr/lib/x86_64-linux-gnu/libjemalloc.so.1 ]; then export LD_PRELOAD=/usr/lib/x86_64-linux-gnu/libjemalloc.so.1"
JE3=" elif [ -r ${PWD}/lib/mysql/libjemalloc.so.1 ]; then export LD_PRELOAD=${PWD}/lib/mysql/libjemalloc.so.1"
JE4=" else echo 'Error: jemalloc not found, please install it first'; exit 1; fi" 

# Ubuntu mysqld runtime provisioning
if [ "$(uname -v | grep 'Ubuntu')" != "" ]; then
  if [ "$(sudo apt-get -s install libaio1 | grep 'is already')" == "" ]; then
    sudo apt-get install libaio1 
  fi
  if [ "$(sudo apt-get -s install libjemalloc1 | grep 'is already')" == "" ]; then
    sudo apt-get install libjemalloc1
  fi
  if [ ! -r /lib/x86_64-linux-gnu/libssl.so.6 ]; then
    sudo ln -s /lib/x86_64-linux-gnu/libssl.so.1.0.0 /lib/x86_64-linux-gnu/libssl.so.6
  fi
  if [ ! -r /lib/x86_64-linux-gnu/libcrypto.so.6 ]; then
    sudo ln -s /lib/x86_64-linux-gnu/libcrypto.so.1.0.0 /lib/x86_64-linux-gnu/libcrypto.so.6
  fi
fi

if [ "" == "$1" ]; then
  echo "This script expects the trial number to be passed - e.g. 'startup 10' for actioning trial 10 (trial10.log)"
  echo "Other uses: 'startup 10 man': actions trial 10 as found in the RQG run without attempting to extract any tars"
  echo "Other uses: 'startup 0': local build mode (create scripts for a standard server setup without reference to RQG)"
  echo "In other words, use:"
  echo '$ startup.sh <trialno>         When analyzing automated Percona Jenkins RQG runs'
  echo '$ startup.sh <trialno> man     When analyzing manually executed RQG runs'
  echo '$ startup.sh <trialno> ''man2''    Like man option above, but do not attempt to untar tarball again'
  echo '$ startup.sh 0                 When using a binary tar build generated by ./build/build-binary.sh (no RQG), or a yassl-based QA build from Jenkins'
  exit 1
fi

# Get version specific options. MID=mysql_install_db
versionOptCheck() {
  if [ "$(${BIN} --version | grep -oe '5\.[1567]' | head -n1)" == "5.7" ]; then
    if [[ ! `${BIN}  --version | grep -oe '5\.[1567]\.[0-5]'` ]]; then
      MID_OPT="--initialize-insecure"
    else
      MID_OPT="--insecure"
    fi
    START_OPT="--core-file"
  elif [ "$(${BIN} --version | grep -oe '5\.[1567]' | head -n1)" == "5.6" ]; then
    MID_OPT="--force --no-defaults"
    START_OPT="--core-file"
  elif [ "$(${BIN} --version | grep -oe '5\.[1567]' | head -n1)" == "5.5" ]; then
    MID_OPT="--force --no-defaults"
    START_OPT="--core"
  else
    echoit "WARNING: mysqld version detection failed. This is likely caused by using this script with a non-supported (only MS and PS are supported currently for versions 5.5, 5.6 and 5.7) distribution or version of mysqld. Please expand this script to handle. This scipt will try and continue, but this may fail."
    MID_OPT=""
    START_OPT="--core-file"
  fi
}

if [ "$1" == "0" ]; then
  if [ -r ./bin/mysqld -o -r ./bin/mysqld-debug ]; then 
    echo "Local build mode: creating scripts for a standard server setup (no connection with RQG)"
  else
    echo "Local build mode active, but no ./bin/mysqld or ./bin/mysqld-debug found"
    exit 1
  fi
elif [ ! -d current1_1 -a ! -r trial$1.log ]; then 
  echo "This script is to be started within a given run directory, for example '/data/ssd/qa/67'"
  echo "For local build mode (create scripts for a standard server setup without reference to RQG), use 'startup 0'"
  exit 1
elif [ "$2" == "man" -o "$2" == "man2" ]; then
  echo "Manual RQG mode active, using RQG and sever directories as found in the RQG run."
  SKIP_RQG_AND_BUILD_EXTRACT=1
else
  if [ ! -r ../build_$BUILD.tar.gz ]; then 
    echo "There is supposed to be a mysql build in .. (../build_$BUILD.tar.gz), exiting"
    echo "(Where you trying to use manual mode? See 'startup' and if so, use 'startup $1 man' instead"
    exit 1
  elif [ ! -r ../randgen_$BUILD.tar.gz ]; then 
    echo "There is supposed to be a randgen build in .. (../randgen_$BUILD.tar.gz), exiting"
    exit 1
  fi
fi

if [ "$1" != "0" ]; then
  if [ "$2" != "man2" ]; then
    if [ ! -r ./vardir1_$1.tar.gz ]; then 
      if [ -d ./vardir1_$1 ]; then 
        echo "There is supposed to be a vardir tarball in . (./vardir1_$1.tar.gz), exiting (you may want to try man2 option instead)"
      else
        echo "There is supposed to be a vardir tarball in . (./vardir1_$1.tar.gz), exiting"
      fi
        exit 1
    fi
  else
    if [ ! -d ./vardir1_$1 ]; then 
      echo "There is supposed to be a vardir directory in . (./vardir1_$1), exiting (did you forget to extract the tarball first before using 'man2' option?)"
      exit 1
    fi
  fi
  if [ ! -r ./trial$1.log ]; then
    echo "There is supposed to be a trial log in . (./trial$1.log), exiting"
    exit 1
  fi
fi

# Local build mode: only setup scritps for local directory, then exit (used for creating startup scripts in the local directory,
# for example after using ./build/binary-build.sh & extracing the resulting tarball or when using a yassl-based QA build from Jenkins.)
if [ "0" == "$1" ]; then
  echo "Adding scripts: ./start | ./start_gypsy | ./stop | ./cl | ./cl_binmode | ./test | ./init | ./wipe (last two without executable attribute)"
  mkdir -p ./data ./data/mysql ./data/test ./log
  if [ -r $PWD/bin/mysqld ]; then
    BIN="$PWD/bin/mysqld"
  else
    BIN="$PWD/bin/mysqld-debug"
  fi
  versionOptCheck
  if [ -r $PWD/lib/mysql/plugin/ha_tokudb.so ]; then
    TOKUDB="--plugin-load=tokudb=ha_tokudb.so "
  else
    TOKUDB=""
  fi
  echo 'MYEXTRA=" --no-defaults"' > ./start
  echo '#MYEXTRA=" --no-defaults --event-scheduler=ON --maximum-bulk_insert_buffer_size=1M --maximum-join_buffer_size=1M --maximum-max_heap_table_size=1M --maximum-max_join_size=1M --maximum-myisam_max_sort_file_size=1M --maximum-myisam_mmap_size=1M --maximum-myisam_sort_buffer_size=1M --maximum-optimizer_trace_max_mem_size=1M --maximum-preload_buffer_size=1M --maximum-query_alloc_block_size=1M --maximum-query_prealloc_size=1M --maximum-range_alloc_block_size=1M --maximum-read_buffer_size=1M --maximum-read_rnd_buffer_size=1M --maximum-sort_buffer_size=1M --maximum-tmp_table_size=1M --maximum-transaction_alloc_block_size=1M --maximum-transaction_prealloc_size=1M --log-output=none --sql_mode=ONLY_FULL_GROUP_BY"' >> ./start
  echo $JE1 >> ./start; echo $JE2 >> ./start; echo $JE3 >> ./start; echo $JE4 >> ./start
  cp ./start ./start_gypsy  # Just copying jemalloc commands from last line above over to gypsy start also
  echo "$BIN \${MYEXTRA} ${START_OPT} --innodb_buffer_pool_size=2147483648 --basedir=$PWD --tmpdir=$PWD/data --datadir=$PWD/data ${TOKUDB} --socket=$PWD/socket.sock --port=$PORT --log-error=$PWD/log/master.err 2>&1 &" >> ./start
  echo "$BIN \${MYEXTRA} ${START_OPT} --innodb_buffer_pool_size=2147483648 --general_log=1 --general_log_file=$PWD/general.log --basedir=$PWD --tmpdir=$PWD/data --datadir=$PWD/data ${TOKUDB} --socket=$PWD/socket.sock --port=$PORT --log-error=$PWD/log/master.err 2>&1 &" >> ./start_gypsy
  echo "echo 'Server socket: $PWD/socket.sock with datadir: $PWD/data'" >> ./start
  tail -n1 start >> ./start_gypsy
  echo "$PWD/bin/mysqladmin -uroot -S$PWD/socket.sock shutdown" > ./stop
  echo "echo 'Server on socket $PWD/socket.sock with datadir $PWD/data halted'" >> ./stop
  echo "$PWD/bin/mysql -A -uroot -S$PWD/socket.sock test" > ./cl
  echo "./start; sleep 5; $PWD/bin/mysql -A -uroot -S$PWD/socket.sock -e \"INSTALL PLUGIN tokudb_file_map SONAME 'ha_tokudb.so'; INSTALL PLUGIN tokudb_fractal_tree_info SONAME 'ha_tokudb.so'; INSTALL PLUGIN tokudb_fractal_tree_block_map SONAME 'ha_tokudb.so'; INSTALL PLUGIN tokudb_trx SONAME 'ha_tokudb.so'; INSTALL PLUGIN tokudb_locks SONAME 'ha_tokudb.so'; INSTALL PLUGIN tokudb_lock_waits SONAME 'ha_tokudb.so';\"; ./stop" > ./tokutek_init
  echo "$PWD/bin/mysql -A -uroot -S$PWD/socket.sock --force --binary-mode test" > ./cl_binmode
  echo "$PWD/bin/mysql -A -uroot -S$PWD/socket.sock --force --binary-mode test < $PWD/in.sql >> $PWD/mysql.out 2>&1" > ./test
  echo "if [ -r ./stop ]; then ./stop 2>/dev/null 1>&2; fi" > ./wipe
  echo "if [ -d $PWD/data.PREV ]; then rm -Rf $PWD/data.PREV.older; mv $PWD/data.PREV $PWD/data.PREV.older; fi;mv $PWD/data $PWD/data.PREV" >> ./wipe
  if [ "$(${BIN} --version | grep -oe '5\.[1567]' | head -n1)" != "5.7" ]; then
     echo "mkdir $PWD/data $PWD/data/test $PWD/data/mysql" >> ./wipe
  fi
  if [ "${MID_OPT}" == "--initialize-insecure" ]; then
    MID_57="$PWD/bin/mysqld"
  else
    MID_57="$PWD/bin/mysql_install_db"
  fi  
  echo "if [ -r $PWD/scripts/mysql_install_db ]; then $PWD/scripts/mysql_install_db ${MID_OPT} --basedir=$PWD --datadir=$PWD/data; elif [ -r $PWD/bin/mysql_install_db ]; then $MID_57 ${MID_OPT} --basedir=$PWD --datadir=$PWD/data; else echo 'mysql_install_db not found in scripts nor bin directories'; fi" >> ./wipe
  if [ "$(${BIN} --version | grep -oe '5\.[1567]' | head -n1)" == "5.7" ]; then
     echo "mkdir -p $PWD/data/test " >> ./wipe
  fi
  echo "if [ -r ./log/master.err.PREV ]; then rm -f ./log/master.err.PREV; fi" >> ./wipe
  echo "if [ -r ./log/master.err ]; then mv ./log/master.err ./log/master.err.PREV; fi" >> ./wipe
  echo "if [ -r ./stop ]; then ./stop 2>/dev/null 1>&2; fi" > ./init
  echo "rm -Rf $PWD/data" >> ./init
  if [ "$(${BIN} --version | grep -oe '5\.[1567]' | head -n1)" != "5.7" ]; then
    echo "mkdir $PWD/data $PWD/data/test $PWD/data/mysql" >> ./init
  fi
  echo "if [ -r $PWD/bin/mysql_install_db ]; then $MID_57 ${MID_OPT} --basedir=$PWD --datadir=$PWD/data; elif [ -r $PWD/scripts/mysql_install_db ]; then $PWD/scripts/mysql_install_db ${MID_OPT} --basedir=$PWD --datadir=$PWD/data; else echo 'mysql_install_db not found in scripts nor bin directories'; fi" >> ./init
  if [ "$(${BIN} --version | grep -oe '5\.[1567]' | head -n1)" == "5.7" ]; then
    echo "mkdir $PWD/data/test" >> ./init
  fi
  echo "rm -f ./log/master.*" >> ./init
  chmod +x start start_gypsy stop cl cl_binmode test init ./tokutek_init
  echo "Setting up server with default directories"
  ./init
  if [ -r $PWD/lib/mysql/plugin/ha_tokudb.so ]; then
    echo "Enabling additional TokuDB engine plugin items"
    ./tokutek_init
  fi
  exit 0  # All done
fi

# Prevent (modified | only) vardir from accidental delete
if [ "$2" != "man2" -a -d ./vardir1_$1 ]; then
  echo "=== Accidental erroneous vardir1_$1 deletion prevention ==="
  echo "Note that re-starting this script overwrites mysql and RQG and wipes & re-extracts the vardir"
  echo "This is handy when running various tests on the data where a restore is needed every time."
  echo "However, be careful as this also means that any data you have saved (for instance by using"
  echo "mysql and making changes to tables etc.) will be lost. You are being presented with this message"
  if [ -r ./vardir1_$1.tar.gz ]; then
    echo "since a vardir is already present. You may have made changes to it already. If not, you can go ahead."
  else
    echo "since a vardir is already present, and it looks like you did not use the --clean option in your RQG"
    echo "run, as there is no tar of the vardir present @ ./vardir1_$1.tar.gz. You may want to make a copy of"
    echo "vardir to ensure you have a copy of the state it is in (post-run states should be preserved)"
    echo "It is recommended you exit here (CTRL-C) and take a copy of the vardir: cp -R vardir1_$1 vardir1_$1_copy"
  fi
  echo "Hit enter twice (to continue) or CTRL-C (to abort) now."
  read -p "Hit enter or CTRL-C now:"
  read -p "Hit enter or CTRL-C now:"
fi

if [ -d ./randgen ] ; then
  echo "=== Accidental erroneous RQG and/or MySQL directory deletion prevention ==="
  echo "It looks like you have used this script before in this run directory. That is fine, but please"
  echo "note that the randgen + mysql directories will be overwritten (this is seperate from the vardir)."
  echo "If you have made changes to RQG or to MySQL (for instance having added options in the mysql startup"
  echo "script or made changes to RQG etc.) **FOR ANY TRIAL** that these will be ovewritten by this action."
  echo "Hit enter twice (to continue) or CTRL-C (to abort) now."
  read -p "Hit enter or CTRL-C now:"
  read -p "Hit enter or CTRL-C now:"
fi

if [ $SKIP_RQG_AND_BUILD_EXTRACT -ne 1 ]; then
  # Setting up privs
  sudo chmod -R 777 ../$BUILD

  # Extract RQG here in main run directory (to use for cmd runs - see below)
  echo "Extrating randgen build (../randgen_$BUILD.tar.gz) to ./randgen"
  tar --overwrite -xf ../randgen_$BUILD.tar.gz

  # Extract mysql build here in main run directory
  echo "Extracting mysql build (../build_$BUILD.tar.gz)"
  tar --overwrite -xf ../build_$BUILD.tar.gz

  # Get BASE name by checking for [Pp]ercona-[Ss]erver in current dir (there from build extract above)
  BASE=`echo $PWD`/`ls -1d ?ercona-?erver* | head -n1`
else
  # Get BASE name from RQG trial
  BASE=`grep -m1 'basedir=' trial$1.log | sed 's|^.*basedir=/|/|;s| .*$||'` 
fi

echo "BASE directory: $BASE"

# Extract vardir from actual trial 
# (no need to keep seperate copy - vardir is saved in tarball, or delete was agreed to with 2x enter)
if [ "$2" != "man2" -a -r ./vardir1_$1.tar.gz ]; then    # the -a -r clause is just a safety measure to prevent vardir1_$1 from being accidentally deleted if no tar file is present in any case
  rm -Rf ./vardir1_$1
  echo "Extracting vardir (./vardir1_$1.tar.gz) to ./vardir1_$1"
  tar -xf ./vardir1_$1.tar.gz
fi

# MTR details copy (for accuracy runs, now with socket [old port cmds left ftm, remarked])
echo "Adding scripts: ./start_mtr$1 | start_wipe_mtr$1 | ./stop_mtr$1 | ./cl_mtr$1 | ./cl_binmode_mtr$1 | ./test_mtr$1 | ./dump_mtr$1"
echo " -> These bring up the server (using MTR) with the vardir from the original run, and all mysqld options are preseved"
echo " -> These MTR scripts also preseve the --valgrind option (normal scripts need a ./valgrind$1 addition still)"
echo "cd $BASE/mysql-test/" > ./start_mtr$1
echo $JE1 >> ./start_mtr$1; echo $JE2 >> ./start_mtr$1; echo $JE3 >> ./start_mtr$1; echo $JE4 >> ./start_mtr$1
RND_DIR=$(echo $PWD | sed 's|.*/\([0-9][0-9][0-9][0-9][0-9][0-9]\).*|\1|')
cat trial$1.log | grep -m1 "Running perl" | \
  sed "s|^.* Running perl mysql-test-run|perl lib/v1/mysql-test-run|" | \
  sed "s|^.* Running ||;s|\. *$||" | \
  sed "s|vardir=[^ ]* |vardir=$PWD/vardir1_$1 |" | \
  sed "s|--start-and-exit|--start-and-exit --start-dirty|" | \
  sed "s|=/[^ ]*/${RND_DIR}/_epoch/|=$PWD/vardir1_$1/|g" | \
  sed "s|master_port=[0-9]* |master_port=$PORT |" >> ./start_mtr$1
echo "echo 'If you would like to create a new vardir @ $PWD/vardir1_$1, then please remove --start-dirty from ./start_mtr$1'" >> ./start_mtr$1
#echo "echo 'Server port: $PORT with vardir: $PWD/vardir1_$1'" >> ./start_mtr$1
echo "echo 'Server socket: $PWD/vardir1_$1/tmp/master.sock with vardir: $PWD/vardir1_$1'" >> ./start_mtr$1
echo "echo 'Base Directory: $BASE'" >> ./start_mtr$1
cat ./start_mtr$1 | sed "s|--start-dirty||" > ./start_wipe_mtr$1
#echo "$BASE/bin/mysqladmin -uroot -h127.0.0.1 -P$PORT shutdown" > ./stop_mtr$1
echo "$BASE/bin/mysqladmin -uroot -S$PWD/vardir1_$1/tmp/master.sock shutdown" > ./stop_mtr$1
#echo "echo 'Server on port $PORT with vardir $PWD/vardir1_$1 halted'" >> ./stop_mtr$1
echo "echo 'Server on socket $PWD/vardir1_$1/tmp/master.sock with vardir $PWD/vardir1_$1 halted'" >> ./stop_mtr$1
#echo "$BASE/bin/mysql -uroot -h127.0.0.1 -P$PORT test" > ./cl_mtr$1
echo "$BASE/bin/mysql -A -uroot -S$PWD/vardir1_$1/tmp/master.sock test" > ./cl_mtr$1
echo "$BASE/bin/mysql -A -uroot -S$PWD/vardir1_$1/tmp/master.sock --force --binary-mode test" > ./cl_binmode_mtr$1
echo "if [ ! -a $PWD/$1.sql ]; then" > ./test_mtr$1
echo "  cp trial$1.log $PWD/$1.sql" >> ./test_mtr$1
echo "else" >> ./test_mtr$1
echo "  echo 'Found existing SQL file @ $PWD/$1.sql, so did not generate new one. Ensure this is correct.'" >> ./test_mtr$1
echo "fi" >> ./test_mtr$1
echo 'echo "=========== NEW RUN @ `date` ===========" >> $PWD/$1.out' >> ./test_mtr$1
#echo "$BASE/bin/mysql -A -uroot -h127.0.0.1 -P$PORT --force test < $PWD/$1.sql >> $PWD/$1.out 2>&1" >> ./test_mtr$1
echo "$BASE/bin/mysql -A -uroot -S$PWD/vardir1_$1/tmp/master.sock --force --binary-mode test < $PWD/$1.sql >> $PWD/$1.out 2>&1" >> ./test_mtr$1
echo "$BASE/bin/mysqldump -uroot -S$PWD/vardir1_$1/tmp/master.sock --force --add-drop-database --flush-logs --routines --events --triggers --all-databases > $1.sql" > ./dump_mtr$1
chmod +x start_mtr$1 start_wipe_mtr$1 stop_mtr$1 cl_mtr$1 cl_binmode_mtr$1 test_mtr$1 dump_mtr$1

# SOCKET + NO MTR IS FASTER TWICE (BUT MAY NOT REPRODUCE ISSUES AS ALL MYSQLD OPTIONS ARE NOT PASSED!)
echo "Adding scripts: ./start$1 | ./stop$1 | ./cl$1 | ./cl_binmode$1 | ./test$1 | ./wipe$1 (w/o exe attrib) | ./init$1 (w/o exe attrib) | ./dump$1"
echo " -> These quickly bring up the server with the same vardir (but no original run mysqld options are passed)"
echo " -> Use for testing if an issues reproduces without specific mysqld options passed at startup. For more info on this, see the extra (# remarked) at the top of startup.sh"
echo " -> Not using MTR also results in a faster startup, and finally, this uses socket connections which gives faster SQL replay, thereby reducing the probability of non-reproducibility"
if [ -r $BASE/bin/mysqld ]; then
  BIN="$BASE/bin/mysqld"
else
  BIN="$BASE/bin/mysqld-debug"
fi
versionOptCheck
if [ -r $PWD/lib/mysql/plugin/ha_tokudb.so ]; then
  TOKUDB="--plugin-load=tokudb=ha_tokudb.so "
else
  TOKUDB=""
fi
echo $JE1 > ./start$1; echo $JE2 >> ./start$1; echo $JE3 >> ./start$1; echo $JE4 >> ./start$1
log_arch_dir=`cat trial$1.log | grep -m1 'innodb_log_arch_dir' | grep -o 'innodb_log_arch_dir[^ ,]\+' | sed 's/.*_epoch\///'`
log_group_home_dir=`cat trial$1.log | grep -m1 'innodb_log_group_home_dir' | grep -o 'innodb_log_group_home_dir[^ ,]\+' | sed 's/.*_epoch\///'`
if [ $log_arch_dir ];then
 epoch="--innodb_log_arch_dir=$PWD/vardir1_$1/$log_arch_dir "
fi
if [ $log_group_home_dir ];then
 epoch=" ${epoch}  --innodb_log_group_home_dir=$PWD/vardir1_$1/$log_group_home_dir "
fi
echo "$BIN ${START_OPT} --basedir=$BASE --tmpdir=$PWD/data --datadir=$PWD/vardir1_$1/master-data ${TOKUDB} --socket=$PWD/vardir1_$1/socket.sock ${epoch} --log-error=$PWD/vardir1_$1/log/master.err 2>&1 &" >> ./start$1
echo "echo 'Server socket: $PWD/vardir1_$1/socket.sock with vardir: $PWD/vardir1_$1'" >> ./start$1
echo "echo 'Base Directory: $BASE'" >> ./start$1
echo "$BASE/bin/mysqladmin -uroot -S$PWD/vardir1_$1/socket.sock shutdown" > ./stop$1
echo "echo 'Server on socket $PWD/vardir1_$1/socket.sock with vardir $PWD/vardir1_$1 halted'" >> ./stop$1
echo "$BASE/bin/mysql -A -uroot -S$PWD/vardir1_$1/socket.sock test" > ./cl$1
echo "$BASE/bin/mysql -A -uroot -S$PWD/vardir1_$1/socket.sock --force --binary-mode test" > ./cl_binmode$1
echo "cat trial$1.log | sed 's/^\(.*\)\(\bPROCEDURE\|FUNCTION\b\)\(.*\)$/DELIMITER |\n\1\2\3 |\nDELIMITER ;/i' > $PWD/$1.sql" > ./test$1   # Temp hack for RQG BUG#1074485
echo 'echo "=========== NEW RUN @ `date` ===========" >> '"$PWD/$1.out" >> ./test$1
echo "$BASE/bin/mysql -A -uroot -S$PWD/vardir1_$1/socket.sock --force --binary-mode test < $PWD/$1.sql >> $PWD/$1.out 2>&1" >> ./test$1
echo "if [ -d $PWD/vardir1_$1/master-data.PREV ]; then rm -Rf $PWD/vardir1_$1/master-data.PREV.older; mv $PWD/vardir1_$1/master-data.PREV $PWD/vardir1_$1/master-data.PREV.older; fi; mv $PWD/vardir1_$1/master-data $PWD/vardir1_$1/master-data.PREV; mkdir $PWD/vardir1_$1/master-data $PWD/vardir1_$1/master-data/test $PWD/vardir1_$1/master-data/mysql; if [ -r $BASE/scipts/mysql_install_db ]; then $BASE/scripts/mysql_install_db ${MID_OPT} --basedir=$BASE --datadir=$PWD/vardir1_$1/master-data; elif [ -r $BASE/bin/mysql_install_db ]; then $BASE/bin/mysql_install_db ${MID_OPT} --basedir=$BASE --datadir=$PWD/vardir1_$1/master-data; else echo 'mysql_install_db not found in scripts nor bin directories'; fi" > ./wipe$1
echo "rm -Rf $PWD/vardir1_$1/master-data; mkdir $PWD/vardir1_$1/master-data $PWD/vardir1_$1/master-data/test $PWD/vardir1_$1/master-data/mysql; if [ -r $BASE/scripts/mysql_install_db ]; then $BASE/scripts/mysql_install_db ${MID_OPT} --basedir=$BASE --datadir=$PWD/vardir1_$1/master-data; elif [ -r $BASE/bin/mysql_install_db ]; then $BASE/bin/mysql_install_db ${MID_OPT} --basedir=$BASE --datadir=$PWD/vardir1_$1/master-data; else echo 'mysql_install_db not found in scripts nor bin directories'; fi" > ./init$1
echo "$BASE/bin/mysqldump -uroot -S$PWD/vardir1_$1/tmp/master.sock --force --add-drop-database --flush-logs --routines --events --triggers --all-databases > $1.sql" > ./dump$1
chmod +x start$1 stop$1 cl$1 cl_binmode$1 test$1 dump$1

# Make an RQG trial run cmd also
echo "Adding RQG trial run scripts: ./cmd$1 ./cmdtrace$1"
echo " -> Use the cmd script to start the trial again in the same way as originally executed, to see if the issue is reproducible."
echo " -> Use the cmdtrace script to generate an sql trace. Do check that the issue reproduces, otherwise the sql trace is useless."
echo " -> Note the cmdtrace script runs longer then the original trial. This is to compensate for disk writes. Note --duration= may need further increass."

echo $JE1 > ./cmd$1; echo $JE2 >> ./cmd$1; echo $JE3 >> ./cmd$1; echo $JE4 >> ./cmd$1
echo "ps -ef | grep 'rundir1_$1' | grep -v grep | awk '{print \$2}' | xargs sudo kill -9 > /dev/null 2>&1" >> ./cmd$1
echo "rm -Rf $PWD/rundir1_$1" >> ./cmd$1
echo "rm -Rf $PWD/rundir1_$1_epoch" >> ./cmd$1
echo "mkdir $PWD/rundir1_$1" >> ./cmd$1

# Check if RQG's _epoch functionality was used, and prepare appropriate new directory for it if so
EPOCHD=$(cat ./vardir1_$1/command | sed 's|^.* --mysqld=.*=\(.*_epoch\)|\1|;s| .*||;s|[/ \t]*$||' | grep "_epoch" )
if [ ! -z $EPOCHD ]; then
  echo "mkdir $PWD/rundir1_$1_epoch" >> ./cmd$1
else 
  EPOCHD="DefinitelyNotExistingWordsDummy"  # Dummy used to ensure no replace happens in sed below
fi

if [ $SKIP_RQG_AND_BUILD_EXTRACT -ne 1 ]; then
  echo "cd $PWD/randgen" >> ./cmd$1
else
  # This was not a Percona Jenkins RQG run. Obtain RQG path from trial log.
  RQG_MPATH=`grep -m1 'Revno' trial$1.log | sed 's|^.* /|/|;s| Rev.*$||'`
  echo "cd $RQG_MPATH" >> ./cmd$1
fi
if [ "$2" == "man" ]; then
  BD1="Dummy"
  BD2="Dummy"
else
  BD1="basedir=.*/Percona-Server-"
  BD2="basedir=$PWD/Percona-Server-"
fi
SEED=$(grep -m1 "seed =>" trial$1.log | sed 's/^.*=> \([0-9]*\)/\1/')
if [ -z $SEED ]; then
  SEED=$(grep -m1 "seed=" trial$1.log | sed 's/.*--seed=//;s/ .*//')
  echo "# Caution: no actual seed value found (did server crash during bootstrap?): using original --seed=$SEED paramater instead!" >> ./cmd$1
  echo "Caution: no actual seed value found (did server crash during bootstrap?): using original --seed=$SEED paramater instead!"
fi
cat ./vardir1_$1/command | \
  sed "s|$BD1|$BD2|gi" | \
  sed "s|seed=[a-zA-Z0-9]* |seed=$SEED |" | \
  sed "s|mtr-build-thread=[0-9]* |mtr-build-thread=$MTRT |" | \
  sed "s|vardir\([0-9]\)=.*current[0-9]*_[0-9]*[ ]|vardir\1=$PWD/rundir1_$1 |g" | \
  sed "s|>.*/trial[0-9]*.log|> $PWD/cmd$1.log|" | \
  sed "s|$EPOCHD|$PWD/rundir1_$1_epoch|g" | \
  sed "s| \+| |g" >> ./cmd$1
echo >> ./cmd$1
echo "tail -n1 $PWD/cmd$1.log" >> ./cmd$1
cat cmd$1 | sed "s|..mysqld=..log.output=none|--mysqld=--log-output=FILE --mysqld=--general_log --mysqld=--general_log_file=$PWD/$1.sql|" | \
  sed "s|duration=240 |duration=400 |;s|duration=300 |duration=450 |;s|duration=600 |duration=900 |;s|duration=900 |duration=1300 |" > cmdtrace$1
chmod +x cmd$1 cmdtrace$1

