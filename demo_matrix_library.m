% MATLAB Demonstration: 2x2 Matrix Multiplication via Fortran
clc; clear;
fprintf('=== Starting Fortran-MATLAB Matrix Integration Demo ===\n\n');

% Fix macOS Dynamic Library Runtime Path
fprintf('Applying macOS library path fix for matrix binary...\n');
[status,cmdout]=system('install_name_tool -id "@loader_path/libmatrixmult.dylib" libmatrixmult.dylib');
if status ~= 0
    error('Failed to update dylib path identity: %s', cmdout);
end

% Compile the C Gateway and Link the Matrix Library
fprintf('Compiling C Gateway (matrix_gateway.c) with MATLAB MEX...\n');
try
    mex matrix_gateway.c -L. -lmatrixmult
    fprintf('Success: MEX binary "matrix_gateway" created.\n\n');
catch ME
    rethrow(ME);
end

% Execute Module Evaluation Test

% NOTE: Everything ABOVE this line only needs to be done ONCE. Try changing A, B
% variables below to see that the result stil works with different inputs!

A = [1.0, 2.0; 3.0, 4.0];
B = [5.0, 6.0; 7.0, 8.0];

fprintf('Matrix A:\n'); disp(A);
fprintf('Matrix B:\n'); disp(B);

fprintf('Calling Fortran matrix multiplication routine...\n');
fortran_matrix_output = matrix_gateway(A, B);

fprintf('\n=== Results ===\n');
fprintf('MATLAB received output matrix:\n');
disp(fortran_matrix_output);

% Verification check against MATLAB native multiplication
expected_matrix = A * B;
if isequal(fortran_matrix_output, expected_matrix)
    fprintf('Test Status: PASSED (Fortran matrix math matches MATLAB calculation)\n');
else
    fprintf('Test Status: FAILED (Matrix math mismatch)\n');
end