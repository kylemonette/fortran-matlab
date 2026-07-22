function t = modTime(filename)
%MODTIME
%
%   AUTHOR: Kyle Monette
%   REPOSITORY: https://github.com/kylemonette/fortran-matlab


% Last-modified time of a file, as a datenum.
d = dir(filename);
t = d.datenum;
end
