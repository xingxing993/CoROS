/*
 * File : sfun_coros_cmdproc
 * Abstract:
 */


#define S_FUNCTION_NAME  sfun_coros_cmdproc
#define S_FUNCTION_LEVEL 2

#include "simstruc.h"



/*================*
 * Build checking *
 *================*/


/* Function: mdlInitializeSizes ===============================================
 * Abstract:
 *   Setup sizes of the various vectors.
 */
static void mdlInitializeSizes(SimStruct *S)
{


    ssSetNumSFcnParams(S, 0);
    
	/*if (ssGetNumSFcnParams(S) != ssGetSFcnParamsCount(S)) {
        return; // Parameter mismatch will be reported by Simulink
    }
	// No parameters will be tunable
    for(idx=0; idx<P_NPARMS; idx++){
            ssSetSFcnParamNotTunable(S,idx);
    }
	*/
	
	
/*=====================================================================*\
 * OutputPorts
\*=====================================================================*/
    if (!ssSetNumOutputPorts(S, 0)) return;


    /*for(idx=1; idx<nOutps; idx++){
        ssSetOutputPortWidth(S, idx, DYNAMICALLY_SIZED);
        ssSetOutputPortDataType(S, idx, SS_SINGLE);
    }*/
	
	
/*=====================================================================*\
 * InputPorts
\*=====================================================================*/
    if (!ssSetNumInputPorts(S,7)) return;
	// Port 0: Command Code
	ssSetInputPortWidth(S, 0, 1);
	ssSetInputPortDataType(S, 0, SS_UINT32);
	// Port 1: Parameter name string (converted to uint8 array by MATLAB)
	ssSetInputPortWidth(S, 1, DYNAMICALLY_SIZED);
	ssSetInputPortDataType(S, 1, SS_UINT8);
    // Port 2: Parameter name length, attached by MATLAB from ROS message
	ssSetInputPortWidth(S, 2, 1);
	ssSetInputPortDataType(S, 2, SS_UINT32);
    // Port 3: Command Option
    // ssSetInputPortWidth(S, 3, 8);
	ssSetInputPortWidth(S, 3, DYNAMICALLY_SIZED); //Current protocol port width should be 8, may change in future, so use DYNAMICALLY_SIZED to be robust
	ssSetInputPortDataType(S, 3, SS_UINT32);
	// Port 4: Data payload
	ssSetInputPortWidth(S, 4, DYNAMICALLY_SIZED);
	ssSetInputPortDataType(S, 4, SS_UINT8);
	// Port 5: Valid data payload length (maybe truncated from original), attached by MATLAB from ROS message
	ssSetInputPortWidth(S, 5, 1);
	ssSetInputPortDataType(S, 5, SS_UINT32);
	// Port 6: Original data payload length, attached by MATLAB from ROS message
    // Currently not used, reserved
	ssSetInputPortWidth(S, 6, 1);
	ssSetInputPortDataType(S, 6, SS_UINT32);
	

/*=====================================================================*\
 * SampleTimes
\*=====================================================================*/
    ssSetNumSampleTimes(S, 1);

    /* specify the sim state compliance to be same as a built-in block */
    ssSetSimStateCompliance(S, USE_DEFAULT_SIM_STATE);

    /* Take care when specifying exception free code - see sfuntmpl_doc.c */
    ssSetOptions(S,
                 SS_OPTION_WORKS_WITH_CODE_REUSE |
                 SS_OPTION_EXCEPTION_FREE_CODE |
                 SS_OPTION_USE_TLC_WITH_ACCELERATOR);
}


/* Function: mdlInitializeSampleTimes =========================================
 * Abstract:
 *    This function is used to specify the sample time(s) for your
 *    S-function. You must register the same number of sample times as
 *    specified in ssSetNumSampleTimes.
 */
static void mdlInitializeSampleTimes(SimStruct *S)
{
    ssSetSampleTime(S, 0, INHERITED_SAMPLE_TIME);
    ssSetOffsetTime(S, 0, 0.0);
    ssSetModelReferenceSampleTimeDefaultInheritance(S); 
}

/* Function: mdlOutputs =======================================================
 * Abstract:
 *    
 */
static void mdlOutputs(SimStruct *S, int_T tid)
{

}


#define MDL_SET_INPUT_PORT_DIMENSION_INFO
/* Function: mdlSetInputPortDimensionInfo ====================================
 * Abstract:
 *    This routine is called with the candidate dimensions for an input port
 *    with unknown dimensions. If the proposed dimensions are acceptable, the
 *    routine should go ahead and set the actual port dimensions.
 *    If they are unacceptable an error should be generated via
 *    ssSetErrorStatus.
 *    Note that any other input or output ports whose dimensions are
 *    implicitly defined by virtue of knowing the dimensions of the given port
 *    can also have their dimensions set.
 */
static void mdlSetInputPortDimensionInfo(SimStruct        *S,
int_T            port,
const DimsInfo_T *dimsInfo)
{
    /* Set input port dimension */
    if(!ssSetInputPortDimensionInfo(S, port, dimsInfo)) return;

} /* end mdlSetInputPortDimensionInfo */




# define MDL_SET_DEFAULT_PORT_DIMENSION_INFO
/* Function: mdlSetDefaultPortDimensionInfo ====================================
 *    This routine is called when Simulink is not able to find dimension
 *    candidates for ports with unknown dimensions. This function must set the
 *    dimensions of all ports with unknown dimensions.
 */
static void mdlSetDefaultPortDimensionInfo(SimStruct *S)
{

} /* end mdlSetDefaultPortDimensionInfo */



/* Function: mdlTerminate =====================================================
 * Abstract:
 *    No termination needed, but we are required to have this routine.
 */
static void mdlTerminate(SimStruct *S)
{
}

#if defined(MATLAB_MEX_FILE)
#define MDL_RTW
/* Function: mdlRTW ===========================================================
 * Abstract:
 */
static void mdlRTW(SimStruct *S)
{

}
#endif /* MDL_RTW */

#ifdef  MATLAB_MEX_FILE    /* Is this file being compiled as a MEX-file? */
#include "simulink.c"      /* MEX-file interface mechanism */
#else
#include "cg_sfun.h"       /* Code generation registration function */
#endif
