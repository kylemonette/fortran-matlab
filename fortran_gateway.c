#include "mex.h"

// Declare external Fortran routine (note trailing underscore)
extern void compute_product_(double *val1, double *val2, double *result);

void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[]) {
    // 1. Validate inputs
    if (nrhs != 2) {
        mexErrMsgIdAndTxt("MyToolbox:fortran_gateway:nrhs", "Two inputs required.");
    }

    // 2. Extract input array data pointers
    double *in1 = mxGetPr(prhs[0]);
    double *in2 = mxGetPr(prhs[1]);

    // 3. Allocate matrix memory space for the output parameter
    plhs[0] = mxCreateDoubleMatrix(1, 1, mxREAL);
    double *out = mxGetPr(plhs[0]);

    // 4. Pass C memory address references to the Fortran routine
    compute_product_(in1, in2, out);
}