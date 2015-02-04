gen_installer = input('Installer generieren? (0|1)');
if gen_installer
    deploytool -package SiSaScanAuswertung
else
    deploytool -build SiSaScanAuswertung
end

