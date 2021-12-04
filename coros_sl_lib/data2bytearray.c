/*=================================================================
 * data2bytearray.c - example used to illustrate how to fill an mxArray

 *
 * Input:   mxArray of different datatypes
 * Output:  mxArray of uint8
 *
 * Copyright 2008-2018 The MathWorks, Inc.
 *	
 *=================================================================*/
#include "mex.h"



void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[]) {

    mwSize index;

	/* Check for proper number of arguments. */
    if ( nrhs != 1 ) {
        mexErrMsgIdAndTxt("MATLAB:data2bytearray:rhs",
                "This function takes 1 input arguments.");
    }
    
    mwSize dimnum = mxGetNumberOfDimensions(prhs[0]);
    if ( dimnum > 2 ) {
        mexErrMsgIdAndTxt("MATLAB:data2bytearray:rhs",
                "Dimension out of bound. This function accepts scalar, 1D or 2D numeric values only.");
    }
    mwSize *pdims = mxGetDimensions(prhs[0]);
    size_t elm_size = mxGetElementSize(prhs[0]);
    mwSize elm_num = mxGetNumberOfElements(prhs[0]);
    
    // Print info for debug
//     switch(dimnum){
//         case 1:
//             mexPrintf("Dim %u - [%u];\nElements <%u> of <%u> bytes;\n", dimnum, *pdims, elm_num, elm_size);
//             break;
//         case 2:
//             mexPrintf("Dim %u - [%u, %u];\nElements <%u> of <%u> bytes;\n", dimnum, *pdims, *(pdims+1), elm_num, elm_size);
//             break;
//         default:
//             mexPrintf("DIMENSIONS OTHER THAN 1/2\n");
//     }
    
    
    uint8_T *pdata = (uint8_T*)mxGetData(prhs[0]);
    

    /* Create a local array and load data */
    mxUint8 *dynamicData;
    dynamicData = mxCalloc(elm_num, elm_size);
    for ( index = 0; index < elm_num*elm_size; index++ ) {
        dynamicData[index] = *(pdata+index);
    }
// 
    /* Create a 0-by-0 mxArray; you will allocate the memory dynamically */
    plhs[0] = mxCreateNumericMatrix(0, 0, mxUINT8_CLASS, mxREAL);

    mxSetData(plhs[0], dynamicData);
    
    /*MATLAB matrix stored columnwise in memory: column head-end, then next column*/
    mxSetN(plhs[0], (*(pdims+1))*(*pdims)*elm_size);
    mxSetM(plhs[0], 1);


    
    return;
}
