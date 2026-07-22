function gf = findGfortran()
%FINDGFORTRAN
%   Return a full, usable path to the gfortran executable.
%   MATLAB's system() calls run in a subshell that doesn't always see a
%   user's full Terminal PATH (this is especially common on macOS when
%   MATLAB is launched from Spotlight/Finder rather than a terminal, and
%   on Linux distros that install versioned binaries like gfortran-11
%   without a plain "gfortran" symlink). Try the plain command first,
%   then fall back to common install locations -- including versioned
%   names -- so the same script works across machines without editing.
%
%   Because every build script in this repo calls this function instead
%   of assuming "gfortran" is already on PATH, you never need to touch
%   your shell profile.
%
%   AUTHOR: Kyle Monette
%   REPOSITORY: https://github.com/kylemonette/fortran-matlab
%


    [status, out] = system('which gfortran');
    if status == 0 && ~isempty(strtrim(out))
        gf = strtrim(out);
        return;
    end

    % Fixed, most-common locations first.
    candidates = { ...
        '/opt/homebrew/bin/gfortran', ...  % Homebrew on Apple Silicon
        '/usr/local/bin/gfortran', ...     % Homebrew on Intel Mac / some Linux
        '/usr/bin/gfortran' };             % typical Linux package manager location

    for i = 1:numel(candidates)
        if isfile(candidates{i})
            gf = candidates{i};
            return;
        end
    end

    % Some distros (and some Homebrew versions) only install a versioned
    % binary, e.g. gfortran-11, gfortran-13, gfortran-14, with no
    % unversioned "gfortran" symlink. Search for those too.
    
    globPatterns = { ...
        '/opt/homebrew/bin/gfortran-*', ...
        '/usr/local/bin/gfortran-*', ...
        '/usr/bin/gfortran-*' };

    versioned = {};
    for i = 1:numel(globPatterns)
        d = dir(globPatterns{i});
        for k = 1:numel(d)
            versioned{end+1} = fullfile(d(k).folder, d(k).name); %#ok<AGROW>
        end
    end

    if ~isempty(versioned)
        % Prefer the highest version number found.
        versionNums = zeros(1, numel(versioned));
        for i = 1:numel(versioned)
            tok = regexp(versioned{i}, 'gfortran-(\d+)$', 'tokens', 'once');
            if ~isempty(tok)
                versionNums(i) = str2double(tok{1});
            end
        end
        [~, idx] = max(versionNums);
        gf = versioned{idx};
        return;
    end

    error('findGfortran:notFound', ...
        ['gfortran not found.\n' ...
         'Install it and rerun:\n' ...
         '  macOS         : brew install gcc   (provides gfortran via Homebrew)\n' ...
         '  Ubuntu/Debian : sudo apt install gfortran\n' ...
         '  Fedora/RHEL   : sudo dnf install gcc-gfortran\n' ...
         'If it is installed somewhere findGfortran.m does not check,\n' ...
         'add its full path to the "candidates" list in this file.']);
end
