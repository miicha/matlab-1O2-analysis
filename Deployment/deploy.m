gen_installer = input('Installer generieren? (0|1)');
if gen_installer
    deploytool -package SiSaScanAuswertung
else
    deploytool -build SiSaScanAuswertung
end

prjct = 'sisa-scan-auswertung';
path_to_prjct = 'C:\Users\pfitzseb\Dokumente\Matlab\sisa-scan-auswertung\src';
path_to_binary_versions = 'C:\Users\pfitzseb\Dokumente\Git\binary_versions';

% get version
addpath(path_to_prjct);
strct = readini(fullfile(path_to_prjct, 'config.ini'));
version = strct.version;
rmpath(path_to_prjct);

str = ['cd ' path_to_binary_versions ' & git pull & @echo ' num2str(version)...
       '> ' prjct '.ver & git add ' prjct '.ver & git commit -m "tagged version ' version ' of '...
       prjct '" & git push origin master'];
   
done = system(str);
if done == 0
    disp('Successfully pushed the new version to GitLab!');
end