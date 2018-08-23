%% config
% change these four rows to suit your application
prjct = 'sisa-scan-auswertung';
path_to_prjct = [pwd filesep '..' filesep 'src'];
local_version = get_local_version(path_to_prjct)
version_url = 'http://www.daten.tk/webhook/tags.php?owner=sebastian.pfitzner&project=sisa-scan-auswertung';

%% read new version from source file and check against latest online version
addpath(path_to_prjct);
build = false;
upload_binary = false;
newver = true;
ov = webread(version_url);

%%
if UI.compare_versions(local_version, ov)
    newver = false;
    warning(['Local version (' local_version ') is NOT greater than '...
             'online version (' ov ').']);
    build = input('Build anyway? (0|1) ');
end

%% compile the binary
if build
    fprintf('\nBuilding the binary...\n')
    binpath = [path_to_prjct '/../Deployment/bin'];
    startpath = [path_to_prjct '/startUI.m'];
    mcc('-e', '-o', 'SiSaScanAuswertung', '-d', binpath, startpath)
    fprintf('...Done.\n\n')
end

if ~newver
    warning('Will not push the new version and will not update the version number.');
else
    ver_msg = input('Version message: ', 's');
end

%% push the binaries to your online repo
if newver
    if ispc
        chngfldr = 'pushd ';
    else
        chngfldr = 'cd ';
    end
    % pull first
    str = [chngfldr path_to_prjct ' && git pull origin master'];
           
    done = system(str)
    
    % commit , tag, push
    str = [chngfldr path_to_prjct ' && git add -u :/'... 
               ' && git commit -m "tagged version ' local_version ' of ' prjct '"'];
    if ~isempty(ver_msg)
         str = [str '&& git tag -a ' local_version ' -m "' ver_msg '" && git push origin master --tags'];
    else
        str = [str '&& git tag ' local_version ' && git push origin master --tags'];
    end
    str
    done = system(str);
    if done == 0
        fprintf('\n\n ----- \n\n');
        disp('Successfully pushed the new version''s tag to GitLab!');
        fprintf('\n ----- \n\n');
    end
    
    if upload_binary
        % upload binary
        fid = fopen('./bin/SiSaScanAuswertung.exe', 'r');
        data = char(fread(fid)');
        fclose(fid);
        headerFields = [{'project', 'sisa-scan-auswertung'}; {'name', ['SiSaScanAuswertung-' local_version '.exe']}];
        headerFields = string(headerFields);
        opt = weboptions;
        opt.MediaType = 'application/octet-stream';
        opt.CharacterEncoding = 'ISO-8859-1';
        opt.RequestMethod = 'post';
        opt.HeaderFields = headerFields;
        opt.Timeout = Inf;
        
        response = webwrite('http://www.daten.tk/webhook/upl.php', data, opt);
        if contains(response, '...file written')
            fprintf('\n\n ----- \n\n');
            disp('Successfully pushed the new version''s binaries to the share!');
            fprintf('\n ----- \n\n');
        else
            disp('Failed to push binaries to share:');
            disp(response);
        end
    end
end
rmpath(path_to_prjct);
