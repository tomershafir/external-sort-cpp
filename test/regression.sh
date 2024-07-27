#/bin/bash
[[ -z $BUILD_DIR ]] && _BUILD_DIR='build' || _BUILD_DIR=$BUILD_DIR
[[ -z $TESTDATA_PATH ]] && _TESTDATA_PATH='test/testdata' || _TESTDATA_PATH=$TESTDATA_PATH

for compressed in $_TESTDATA_PATH/*.txt.gz; do
    decompressed=${compressed%".gz"} &&
    gunzip -c $compressed > $decompressed &&
    $_BUILD_DIR/ssort $decompressed 2>/dev/null
    
    rm -rf $decompressed
done
