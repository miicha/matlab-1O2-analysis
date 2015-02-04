gen_installer = input('Installer generieren? (0|1)');
if gen_installer
    deploytool -package SiSaScanAuswertung
else
    deploytool -build SiSaScanAuswertung
end

version = 0.21;

path_to_binary_versions = 'C:\Users\pfitzseb\Dokumente\Git\binary_versions';
prjct = 'sisa-scan-auswertung';

str = ['cd ' path_to_binary_versions ' & git pull & @echo ' num2str(version)...
       '> ' prjct '.ver & git add ' prjct '.ver & git commit -m "tagged new version of '...
       prjct '" & git push origin master'];
   
done = system(str);
if done == 0
    disp('Successfully pushed the new version to GitLab!');
end