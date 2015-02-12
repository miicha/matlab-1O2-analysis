%% I SHOULD REALLY ADD A NEW TAG AND ONLY PUSH THE BINARY!

%% config
% change these four rows to suit your application
prjct = 'sisa-scan-auswertung';
path_to_prjct = 'C:\Users\pfitzseb\Dokumente\Matlab\sisa-scan-auswertung\src';
local_version = get_local_version(path_to_prjct);
version_url = ['http://www.daten.tk/webhook/tags.php?project=SISA%20Scan%20Auswertung];

%% read new version from source file and check against latest online version
build = true;
newver = true;

online_version = str2double(urlread(version_url));

if online_version >= str2double(local_version)
    newver = false;
    warning(['Local version (' local_version ') is NOT greater than '...
             'online version (' num2str(online_version) ').']);
    build = input('Build anyway? (0|1) ');
end

%% compile the binary
if build
    fprintf('\nBuilding the binary...\n')
    mcc -e  -o SiSaScanAuswertung -d . ../src/startUI.m
    fprintf('...Done.\n\n')
    if ~newver
        warning('Will not push the new version and will not update the version number.');
    end
end

%% push the binaries to your online repo
if newver
    str = ['cd ' path_to_prjct ' && git pull origin master && git add -u :/'... 
           ' && git commit -m "tagged version ' local_version ' of '...
           prjct '" && git push origin master'];

    done = system(str);
    if done == 0
        fprintf('\n\n ----- \n\n');
        disp('Successfully pushed the new version''s binaries to GitLab!');
        fprintf('\n ----- \n\n');
    end
end