function tf = needsRebuild(libFile, sourceFiles, gatewayFile)
%NEEDSREBUILD
%   True if a source or gateway file is newer than the
%   compiled outputs, or if any expected output doesn't exist yet.
%   Shared by every build_*.m script in this project.
%
%   tf = needsRebuild(libFile, sourceFiles, gatewayFile)
%
%   libFile     - shared library filename, e.g. 'libmysub.dylib'
%   sourceFiles - cell array of Fortran source filenames to watch
%   gatewayFile - the MEX gateway .c filename
%
%   AUTHOR: Kyle Monette
%   REPOSITORY: https://github.com/kylemonette/fortran-matlab
%

    mexFile = [erase_ext(gatewayFile) '.' mexext];

    if ~isfile(libFile) || ~isfile(mexFile)
        tf = true;
        return;
    end
    builtTime = min(modTime(libFile), modTime(mexFile));
    watchFiles = [sourceFiles, {gatewayFile}];
    for i = 1:numel(watchFiles)
        f = watchFiles{i};
        if isfile(f) && modTime(f) > builtTime
            tf = true;
            return;
        end
    end
    tf = false;
end

function s = erase_ext(f)
    [~, s] = fileparts(f);
end
