% DEMO_MATRIX_LIBRARY
%   2x2 Matrix Multiplication via Fortran
%
%   AUTHOR: Kyle Monette
%   REPOSITORY: https://github.com/kylemonette/fortran-matlab
%

clc; clear;
fprintf('Starting Fortran-MATLAB Matrix Integration Demo\n\n');

% Compile matrix_mult.f90 + matrix_gateway.c into the matrix_gateway
% MEX function, if needed. This is the ONLY setup step -- it locates
% gfortran itself (see findGfortran.m) and handles the shared-library
% linking/runtime-path fix for you. Safe to call every time.

% Pass 'true' to display diagnostics - leave blank, or 'false', for none
build_matrixmult(true);

% Execute Module Evaluation Test
% Try changing A, B below to see that the result still works with
% different inputs -- no need to rebuild anything.

A = [1.0, 2.0; 3.0, 4.0];
B = [5.0, 6.0; 7.0, 8.0];

fprintf('Matrix A:\n'); disp(A);
fprintf('Matrix B:\n'); disp(B);

fprintf('Calling Fortran matrix multiplication routine...\n');
fortran_matrix_output = matrix_gateway(A, B);

fprintf('\nMATLAB received output matrix:\n');
disp(fortran_matrix_output);

% Verification check against MATLAB native multiplication
expected_matrix = A * B;
if isequal(fortran_matrix_output, expected_matrix)
    fprintf('Test Status: PASSED (Fortran matrix math matches MATLAB calculation)\n');
else
    fprintf('Test Status: FAILED (Matrix math mismatch)\n');
end
