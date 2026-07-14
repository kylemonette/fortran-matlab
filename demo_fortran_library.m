% MATLAB Demonstration: Running Arbitrary Fortran via C Gateway
clc; clear;
fprintf('=== Starting Fortran-MATLAB Integration Demo ===\n\n');

% Fix macOS Dynamic Library Runtime Path
% Tells macOS to look inside the active MEX binary folder to locate the .dylib
fprintf('Applying macOS library path fix...\n');
[status, cmdout] = system('install_name_tool -id "@loader_path/libmysub.dylib" libmysub.dylib');
if status ~= 0
    error('Failed to update dylib path identity: %s', cmdout);
end

% Compile the C Gateway and Link the Fortran Library
% -L.     -> Searches current directory for shared objects
% -lmysub -> Looks for a library file named 'libmysub.dylib'
fprintf('Compiling C Gateway (fortran_gateway.c) with MATLAB MEX...\n');
try
    mex fortran_gateway.c -L. -lmysub
    fprintf('Success: MEX binary "fortran_gateway" created.\n\n');
catch ME
    rethrow(ME);
end

% Execute Module Evaluation Test
% NOTE: Everything ABOVE this line only needs to be done ONCE. Try changing the input_val
% variables below to see that the result stil works with different inputs!

input_val1 = 4.5; input_val2 = 2.0;
fprintf('Calling Fortran routine with inputs: %g and %g...\n', input_val1, input_val2);

fortran_output = fortran_gateway(input_val1, input_val2);

fprintf('\n=== Results ===\n');
fprintf('MATLAB received output value: %g\n', fortran_output);