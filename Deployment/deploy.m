%% config
% change these four rows to suit your application
prjct = 'sisa-scan-auswertung';
path_to_prjct = [pwd '\..\src'];
local_version = get_local_version(path_to_prjct)
version_url = 'http://www.daten.tk/webhook/tags.php?owner=sebastian.pfitzner&project=sisa-scan-auswertung';

%% read new version from source file and check against latest online version
addpath(path_to_prjct);
build = true;
newver = true;
ov = urlread(version_url);

%%
if UI.compare_versions(local_version, ov)
    newver = false;
    warning(['Local version (' local_version ') is NOT greater than '...
             'online version (' ov ').']);
    build = input('Build anyway? (0|1) ');
end

%% compile the binary
cd('bin')
if build
    fprintf('\nBuilding the binary...\n')
    mcc -e  -o SiSaScanAuswertung -d . ../src/startUI.m
    fprintf('...Done.\n\n')
    if ~newver
        warning('Will not push the new version and will not update the version number.');
    else
        ver_msg = input('Version message: ', 's');
    end
end

%% push the binaries to your online repo
if newver
    str = ['cd ' path_to_prjct ' && git pull origin master && git add -u :/'... 
               ' && git commit -m "tagged version ' local_version ' of ' prjct '"'];
    if ~isempty(ver_msg)
         str = [str '&& git tag -a ' local_version ' -m "' ver_msg '" && git push origin master --tags'];
    else
        str = [str '&& git tag ' local_version ' && git push origin master --tags'];
    end
    done = system(str);
    if done == 0
        fprintf('\n\n ----- \n\n');
        disp('Successfully pushed the new version''s binaries to GitLab!');
        fprintf('\n ----- \n\n');
    end
end
rmpath(path_to_prjct);