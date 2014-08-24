#/bin/sh +xe

# Hacky script to re-gen the pdf diagram and run a simple test.

ragel -Vp *.rl | dot -Tpdf -o out.pdf
ragel vimlogs.rl
CFLAGS="-O0 -g -pedantic-errors -Wall -Wextra" python setup.py build
cd build/lib.*
python -c 'import vimkeylogparser;vimkeylogparser.parse("jjk:x\r:e\x80kb\x80kb")'
