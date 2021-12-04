/*
 * $Revision $
 * $RCSfile: sfun_coros_txqueue.c,v $
 *
 * Copyright
 */

#define S_FUNCTION_NAME sfun_coros_txqueue
#define S_FUNCTION_LEVEL 2

#include "simstruc.h"


/*====================*
 * S-function methods *
 *====================*/

static void mdlInitializeSizes(SimStruct *S)
{
    /* int_T priority; */

    ssSetNumSFcnParams(S, 0);
    ssSetNumInputPorts(       S, 0);
    ssSetNumSampleTimes(      S, 1);
    ssSetNumContStates(       S, 0);
    ssSetNumDiscStates(       S, 0);
    ssSetNumModes(            S, 0);
    ssSetNumNonsampledZCs(    S, 0);

    /*=====================================================================*\
    * OutputPorts
    \*=====================================================================*/
    ssSetNumOutputPorts(S, 7); //6 data ports and 1 function-call port

    // Port 0: Function-Call port
    ssSetOutputPortWidth(S, 0, 1);
    ssSetOutputPortDataType(S, 1, SS_FCN_CALL);
	// Port 1: Response Code
	ssSetOutputPortWidth(S, 1, 1);
	ssSetOutputPortDataType(S, 1, SS_UINT32);
	// Port 2: Response string (converted to uint8 array by MATLAB)
	ssSetOutputPortWidth(S, 2, DYNAMICALLY_SIZED);
	ssSetOutputPortDataType(S, 2, SS_UINT8);
    // Port 3: Response string length
	ssSetOutputPortWidth(S, 3, 1);
	ssSetOutputPortDataType(S, 3, SS_UINT32);
    // Port 4: Response Option
    // ssSetOutputPortWidth(S, 4, 8);
	ssSetOutputPortWidth(S, 4, DYNAMICALLY_SIZED); //Current protocol port width should be 8, may change in future, so use DYNAMICALLY_SIZED to be robust
	ssSetOutputPortDataType(S, 4, SS_UINT32);
	// Port 5: Data payload
	ssSetOutputPortWidth(S, 5, DYNAMICALLY_SIZED);
	ssSetOutputPortDataType(S, 5, SS_UINT8);
	// Port 6: Valid data payload length
	ssSetOutputPortWidth(S, 6, 1);
	ssSetOutputPortDataType(S, 6, SS_UINT32);
    


    /* specify the sim state compliance to be same as a built-in block */
    ssSetSimStateCompliance(S, USE_DEFAULT_SIM_STATE);

    /* Take care when specifying exception free code - see sfuntmpl_doc.c */
    ssSetOptions(S,
                 SS_OPTION_WORKS_WITH_CODE_REUSE |
                 SS_OPTION_EXCEPTION_FREE_CODE |
                 SS_OPTION_USE_TLC_WITH_ACCELERATOR|
                 SS_OPTION_DISALLOW_CONSTANT_SAMPLE_TIME);
}

static void mdlInitializeSampleTimes(SimStruct *S)
{
    ssSetSampleTime(S, 0, INHERITED_SAMPLE_TIME);
    ssSetOffsetTime(S, 0, 0);
    ssSetCallSystemOutput(S,0);
    ssSetModelReferenceSampleTimeDefaultInheritance(S);
}


static void mdlOutputs(SimStruct *S, int_T tid)
{
    ssCallSystemWithTid(S, 0, tid);
}


#define MDL_SET_OUTPUT_PORT_DIMENSION_INFO
/* Function: mdlSetOutputPortDimensionInfo ====================================
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
static void mdlSetOutputPortDimensionInfo(SimStruct        *S,
int_T            port,
const DimsInfo_T *dimsInfo)
{
    /* Set input port dimension */
    if(!ssSetOutputPortDimensionInfo(S, port, dimsInfo)) return;

} /* end mdlSetOutputPortDimensionInfo */




# define MDL_SET_DEFAULT_PORT_DIMENSION_INFO
/* Function: mdlSetDefaultPortDimensionInfo ====================================
 *    This routine is called when Simulink is not able to find dimension
 *    candidates for ports with unknown dimensions. This function must set the
 *    dimensions of all ports with unknown dimensions.
 */
static void mdlSetDefaultPortDimensionInfo(SimStruct *S)
{

} /* end mdlSetDefaultPortDimensionInfo */



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


/*=============================*
 * Required S-function trailer *
 *=============================*/

#ifdef  MATLAB_MEX_FILE    /* Is this file being compiled as a MEX-file? */
#include "simulink.c"      /* MEX-file interface mechanism */
#else
#include "cg_sfun.h"       /* Code generation registration function */
#endif


/* EOF: ez_sfun_cooperation_task.c*/
