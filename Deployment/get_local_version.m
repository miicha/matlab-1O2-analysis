function [ version ] = get_local_version(path_to_prjct)
    version = fileread(fullfile(path_to_prjct, '..', 'version.txt'));
end

