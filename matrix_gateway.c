#include "mex.h"

// Declare the external Fortran matrix subroutine (note trailing underscore)
extern void multiply_matrices_(double *A, double *B, double *C_out);

void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[]) {
    // 1. Validate inputs (Ensure exactly two inputs)
    if (nrhs != 2) {
        mexErrMsgIdAndTxt("MyToolbox:matrix_gateway:nrhs", "Two inputs required.");
    }
    // 2. Extract 1D continuous data pointers from MATLAB matrices
    double *matA = mxGetPr(prhs[0]);
    double *matB = mxGetPr(prhs[1]);
    // 3. Allocate a 2x2 matrix for the output
    plhs[0] = mxCreateDoubleMatrix(2, 2, mxREAL);
    double *matC = mxGetPr(plhs[0]);
    // 4. Execute Fortran routine, passing pointers to the data blocks
    multiply_matrices_(matA, matB, matC);
}