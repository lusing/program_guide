export PATH=/g/scoop/apps/msys2/current/ucrt64/bin:$PATH
./build/36_ssa/tipa.exe --emit-ir examples/36_ssa/programs/phi.tip | opt -passes=mem2reg -S | grep -E '^\s*%' | grep 'phi' | sed 's/^[[:space:]]*//'
