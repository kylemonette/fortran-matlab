function [libExt, rpathFlag] = libPlatformInfo()
%LIBPLATFORMINFO
%   Platform-specific shared-library settings used by the build_*.m scripts
%   in this project.
%
%   [libExt, rpathFlag] = libPlatformInfo()
%
%   libExt    - shared library file extension: 'dylib' on macOS, 'so' on
%               Linux -- so build scripts don't hardcode one platform.
%   rpathFlag - on Linux, a linker flag that embeds a relative runtime
%               search path so the compiled MEX gateway can find
%               libFOO.so sitting next to it without LD_LIBRARY_PATH
%               being set. On macOS this is empty, because the build
%               scripts fix the library's install-name with
%               install_name_tool instead (the macOS equivalent).
%
%   Neither of the two worked examples in this repo (mysub.f90,
%   matrix_mult.f90) needs any external numerical library (no
%   BLAS/LAPACK) -- they're self-contained, so there's nothing platform
%   -specific to link beyond the shared library mechanics themselves.
%
%   Windows is not supported directly -- gfortran + MEX is a much
%   rougher setup there. Use WSL2 (Linux) instead.
%
%   AUTHOR: Kyle Monette
%   REPOSITORY: https://github.com/kylemonette/fortran-matlab
%

    if ismac
        libExt    = 'dylib';
        rpathFlag = '';
    elseif isunix
        libExt    = 'so';
        rpathFlag = '-Wl,-rpath,''$ORIGIN''';
    else
        error('libPlatformInfo:unsupportedPlatform', ...
            ['Windows is not supported directly by these build scripts.\n' ...
             'Use WSL2 (Windows Subsystem for Linux) and follow the Linux ' ...
             'instructions in README.md instead.']);
    end
end
