function build_mysub(debug)
%BUILD_MYSUB
%   Compile mysub.f90 and its MEX gateway fortran_gateway.c.
%
%   Call this once before using fortran_gateway.
%   The input 'debug' set to true prints progress.
%
%   Recompiles only when mysub.f90 or fortran_gateway.c is newer than
%   the last build (see needsRebuild.m).
%
%   Everything happens from inside MATLAB via system() calls.
%   findGfortran.m locates a usable gfortran on its own, and
%   libPlatformInfo.m picks the right shared-library extension for the OS.
%
%   AUTHOR: Kyle Monette
%   REPOSITORY: https://github.com/kylemonette/fortran-matlab
%

    if nargin < 1, debug = false; end

    fortranFile = 'mysub.f90';
    gatewayFile = 'fortran_gateway.c';
    [libExt, rpathFlag] = libPlatformInfo();
    libFile = ['libmysub.' libExt];

    if debug
        say = @(varargin) fprintf(varargin{:});
    else
        say = @(varargin) [];
    end

    if ~needsRebuild(libFile, {fortranFile}, gatewayFile)
        say('%s up to date, skipping rebuild.\n', gatewayFile);
        return;
    end

    say('Building mysub MEX Gateway\n\n');

    % Locate gfortran (system() calls don't always inherit a full PATH)
    gf = findGfortran();
    say('Using gfortran at: %s\n\n', gf);

    % Compile the Fortran source into a position-independent object
    say('Compiling %s...\n', fortranFile);
    [status, cmdout] = system([gf, ' -c -fPIC ', fortranFile]);
    if status ~= 0, error('gfortran compilation failed:\n%s', cmdout); end
    say('Object file created.\n\n');

    % Link into a shared library
    say('Linking %s...\n', libFile);
    linkCmd = [gf, ' -shared -o ', libFile, ' mysub.o ', rpathFlag];
    [status, cmdout] = system(linkCmd);
    if status ~= 0, error('Linking %s failed:\n%s', libFile, cmdout); end
    say('%s created.\n\n', libFile);

    % macOS only: fix the dylib's runtime install path so the MEX file
    % can find it next to itself (@loader_path). Linux gets the
    % equivalent behavior via the -Wl,-rpath,'$ORIGIN' flag already
    % baked into linkCmd above.
    if ismac
        say('Applying macOS library path fix...\n');
        [status, cmdout] = system(sprintf('install_name_tool -id "@loader_path/%s" %s', libFile, libFile));
        if status ~= 0, error('Failed to update dylib path identity: %s', cmdout); end
        say('Done.\n\n');
    end

    % Compile the gateway and link against the shared library
    say('Compiling gateway %s...\n', gatewayFile);
    mex(gatewayFile, '-L.', '-lmysub');
    say('%s created.\n\n', gatewayFile);
end
