%% read new version from source file and check against latest online version
prjct = 'sisa-scan-auswertung';
path_to_prjct = 'C:\Users\pfitzseb\Dokumente\Matlab\sisa-scan-auswertung\src';
path_to_binary_versions = 'C:\Users\pfitzseb\Dokumente\Git\binary_versions';

% get version
addpath(path_to_prjct);
strct = readini(fullfile(path_to_prjct, 'config.ini'));
version = strct.version;
version = regexprep(version, '0+$', ''); % strip zeroes at the end
rmpath(path_to_prjct);

online_version = str2double(urlread('http://git.daten.tk/sebastian.pfitzner/binary_versions/raw/master/sisa-scan-auswertung.ver'));

build = true;
newver = true;
if online_version >= str2double(version)
    newver = false;
    warning(['Online version number (' num2str(online_version)...
           ') is equal to the local number version (' version ').']);
    build = input('Build anyway? (0|1) ');
end

%% compile the binary
if build
    mcc -e  -o SiSaScanAuswertung -d SiSaScanAuswertung/standalone ../src/startUI.m
end

%% push the new version number to binary_versions repo
if newver
    str = ['cd ' path_to_binary_versions ' & git pull & @echo ' num2str(version)...
           '> ' prjct '.ver & git add ' prjct '.ver & git commit -m "tagged version ' version ' of '...
           prjct '" & git push origin master'];

    done = system(str);
    if done == 0
        disp('Successfully pushed the new version number to GitLab!');
    end
end

%% push the binaries to your online repo
if newver
    str = ['cd ' path_to_prjct ' & git pull origin master & git add -u :/ & git commit -m "tagged version ' version ' of '...
           prjct '" & git push origin master'];

    done = system(str);
    if done == 0
        disp('Successfully pushed the new version to GitLab!');
    end
end