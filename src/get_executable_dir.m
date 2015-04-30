function p = get_executable_dir()
    %get_executable_dir
    % Get the dir from which this file is run. If deployed, get the location of
    % the compiled *.exe.
    if isdeployed()
        [~, result] = system('path');
        p = char(regexpi(result, 'Path=(.*?);', 'tokens', 'once'));
    else
        p = fileparts(mfilename('fullpath'));
    end
end