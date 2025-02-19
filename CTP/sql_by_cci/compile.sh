#!/bin/bash
# 
# Copyright (c) 2016, Search Solution Corporation. All rights reserved.
# 
# Redistribution and use in source and binary forms, with or without 
# modification, are permitted provided that the following conditions are met:
# 
#   * Redistributions of source code must retain the above copyright notice, 
#     this list of conditions and the following disclaimer.
# 
#   * Redistributions in binary form must reproduce the above copyright 
#     notice, this list of conditions and the following disclaimer in 
#     the documentation and/or other materials provided with the distribution.
# 
#   * Neither the name of the copyright holder nor the names of its contributors may be used to endorse or promote products 
#     derived from this software without specific prior written permission.
# 
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, 
# INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE 
# DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, 
# SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR 
# SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
# WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE 
# USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE. 

script_dir=$(dirname $(readlink -f $0))
cd $script_dir

if [ -d "$CUBRID/cci" ]; then
    # since CUBRID 11.2.0
    CUBRID_INCLUDE="-I$CUBRID/include -I$CUBRID/cci/include"
    CUBRID_LDFLAGS="-L$CUBRID/cci/lib -lcascci"
    isSupportHoldCas=`cat ${CUBRID}/cci/include/cas_cci.h | grep "cci_set_cas_change_mode" | wc -l`
    MACRO_OPTION="-D ADD_CAS_ERROR_HEADER=1"
else
    # before CUBRID 11.2.0
    CUBRID_INCLUDE="-I$CUBRID/include"
    CUBRID_LDFLAGS="-L$CUBRID/lib -lcascci"
    isSupportHoldCas=`cat ${CUBRID}/include/cas_cci.h | grep "cci_set_cas_change_mode" | wc -l`
    MACRO_OPTION="-D ADD_CAS_ERROR_HEADER=0"
fi
CFLAGS="-O0 -g -W -Wall"

bits=`cubrid_rel|grep 64bit|grep -v grep|wc -l`
if [ $bits -eq 1 ];then
     CFLAGS="$CFLAGS -m64"
else
     CFLAGS="$CFLAGS -m32"
fi

#Do clean
rm -f *.o ccqt execute interface_verify.h

if [ $isSupportHoldCas -ne 0 ];then
     echo "#define CCI_SET_CAS_CHANGE_MODE_INTERFACE  1" > interface_verify.h
else
     echo ""> interface_verify.h
fi

#Do compile
echo ""
echo "======Start Compile======"
gcc $MACRO_OPTION -o execute execute.c line_scanner.c $CUBRID_INCLUDE $CUBRID_LDFLAGS $CFLAGS
statOfExecute=$?
gcc -o ccqt ccqt.c $CFLAGS
statOfCcqt=$?

echo ""
if [ $statOfExecute -eq 0 -a $statOfCcqt -eq 0 ];then
	echo "======Compile Succuss!!======"
else
	echo "======Compile Fail!!======"
fi
echo "======End Compile======"
echo ""
cd -

