function [ version ] = get_local_version(path_to_prjct)
    addpath(path_to_prjct);
    strct = readini(fullfile(path_to_prjct, 'config.ini'));
    version = strct.version;
    version = regexprep(version, '0{2,}$', ''); % strip zeroes at the end
    version = str2double(strsplit(version));
    rmpath(path_to_prjct);
end

