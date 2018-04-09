function [ version ] = get_local_version(path_to_prjct)
    str = fileread(fullfile(path_to_prjct, '@UI', 'UI.m'));
    match = regexp(str, 'version\s?\=\s?''(?<ver>\d+\.\d+.\d+)'';', 'names');
    version = match.ver;
end

