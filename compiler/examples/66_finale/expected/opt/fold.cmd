export PATH=/g/scoop/apps/msys2/current/ucrt64/bin:$PATH
./build/66_finale/tipa.exe --emit-ir examples/66_finale/programs/fold.tip | opt -passes=mem2reg,sccp,simplifycfg -print-after-all -o /dev/null 2>&1 | grep 'IR Dump After' | grep -v BitcodeWriter
