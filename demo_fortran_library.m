%DEMO_FORTRAN_LIBRARY
%   Running Arbitrary Fortran via C Gateway
%
%   AUTHOR: Kyle Monette
%   REPOSITORY: https://github.com/kylemonette/fortran-matlab
%

clc; clear;
fprintf('Starting Fortran-MATLAB Integration Demo\n\n');

% Compile mysub.f90 + fortran_gateway.c into the fortran_gateway MEX
% function, if needed. This is the ONLY setup step -- it locates
% gfortran itself (see findGfortran.m) and handles the shared-library
% linking/runtime-path fix for you. Safe to call every time.

% Pass 'true' to display diagnostics - leave blank, or 'false', for none
build_mysub(true);

% Execute Module Evaluation Test
% Try changing the input_val variables below to see that the result
% still works with different inputs -- no need to rebuild anything.

input_val1 = 4.5; input_val2 = 2.0;
fprintf('Calling Fortran routine with inputs: %g and %g...\n', input_val1, input_val2);

fortran_output = fortran_gateway(input_val1, input_val2);

fprintf('\nMATLAB received output value: %g\n', fortran_output);
