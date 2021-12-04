/*=================================================================
 * byteflow2data.c - example used to illustrate how to fill an mxArray

 *
 * Input:   mxArray of uint8
 * Output:  mxArray of different datatypes
 *
 * Copyright 2008-2018 The MathWorks, Inc.
 *	
 *=================================================================*/
#include "mex.h"

// This function takes two arguments, 
// prhs[0]:byte array of data to be converted
// prhs[1]: target datatype, if not given, default uint8

typedef enum {
    CoROS_DTIDX_INT8 = 0,
    CoROS_DTIDX_UINT8 = 1,
    CoROS_DTIDX_UINT16 = 2,
    CoROS_DTIDX_UINT32 = 3,
    CoROS_DTIDX_INT16 = 4,
    CoROS_DTIDX_INT32 = 5,
    CoROS_DTIDX_INT64 = 6,
    CoROS_DTIDX_FLOAT = 7, //single
    CoROS_DTIDX_DOUBLE = 8,
    CoROS_DTIDX_UNKNOWN = 255
} CoROS_DTIDX;



void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[]) {
    
    mwSize index;
    CoROS_DTIDX datatype;
	/* Check for proper number of arguments. */
    if ( nrhs < 1 || nrhs > 2) {
        mexErrMsgIdAndTxt("MATLAB:bytearray2data:rhs",
                "This function takes 1 or 2 input arguments.");
    }else{
        if(nrhs == 1) {
            datatype = CoROS_DTIDX_UINT8;
            mexPrintf("Argument 2 not specified, use default UINT8.\n");
        }else{
            datatype = (CoROS_DTIDX)mxGetScalar(prhs[1]);
        }
    }
    
    mwSize dimnum = mxGetNumberOfDimensions(prhs[0]);
    if ( dimnum > 2 ) {
        mexErrMsgIdAndTxt("MATLAB:getuint8:rhs",
                "Dimension out of bound. This function accepts 1st argument as uint8 byte array only.");
    }
    // check input data type, must be uint8
    bool inputdtok = mxIsUint8(prhs[0]);
    if(!inputdtok){
        mexErrMsgIdAndTxt("MATLAB:getuint8:rhs",
                "The 1st argument accepts uint8 byte array only.");
    }
    
    // prepare rhs data
    mwSize *pdims = mxGetDimensions(prhs[0]);
    mwSize elm_num = mxGetNumberOfElements(prhs[0]);
    mxUint8 *p_bytearray = mxGetData(prhs[0]);
    
    /* Create a local array and load data */
    mxUint8 *dynamicData;
    dynamicData = mxMalloc(elm_num);
    for ( index = 0; index < elm_num; index++ ) {
        dynamicData[index] = *(p_bytearray+index);
    }
    
    unsigned char out_el_size;
    switch(datatype){
        case CoROS_DTIDX_INT8:
            plhs[0] = mxCreateNumericMatrix(0, 0, mxINT8_CLASS, mxREAL); out_el_size = 1;
            break;
        case CoROS_DTIDX_UINT8:
            plhs[0] = mxCreateNumericMatrix(0, 0, mxUINT8_CLASS, mxREAL); out_el_size = 1;
            break;
        case CoROS_DTIDX_UINT16:
            plhs[0] = mxCreateNumericMatrix(0, 0, mxUINT16_CLASS, mxREAL); out_el_size = 2;
            break;
        case CoROS_DTIDX_UINT32:
            plhs[0] = mxCreateNumericMatrix(0, 0, mxUINT32_CLASS, mxREAL); out_el_size = 4;
            break;
        case CoROS_DTIDX_INT16:
            plhs[0] = mxCreateNumericMatrix(0, 0, mxINT16_CLASS, mxREAL); out_el_size = 2;
            break;
        case CoROS_DTIDX_INT32:
            plhs[0] = mxCreateNumericMatrix(0, 0, mxINT32_CLASS, mxREAL); out_el_size = 4;
            break;
        case CoROS_DTIDX_INT64:
            plhs[0] = mxCreateNumericMatrix(0, 0, mxINT64_CLASS, mxREAL); out_el_size = 8;
            break;
        case CoROS_DTIDX_FLOAT:
            plhs[0] = mxCreateNumericMatrix(0, 0, mxSINGLE_CLASS, mxREAL); out_el_size = 4;
            break;
        case CoROS_DTIDX_DOUBLE:
            plhs[0] = mxCreateNumericMatrix(0, 0, mxDOUBLE_CLASS, mxREAL); out_el_size = 8;
            break;
        case CoROS_DTIDX_UNKNOWN:
        default:
            plhs[0] = mxCreateNumericMatrix(0, 0, mxUINT8_CLASS, mxREAL); out_el_size = 1;
            break;
    }
    

    mxSetData(plhs[0], dynamicData);
    
    /*MATLAB matrix stored columnwise in memory: column head-end, then next column*/
    mxSetN(plhs[0], elm_num/out_el_size);
    mxSetM(plhs[0], 1);


    
    return;
}
