export PATH=/ucrt64/bin:$PATH && build/17_sign_const/tipa --emit-ir examples/17_sign_const/programs/fold.tip | opt -passes=sccp -S
