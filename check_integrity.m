%% Config
config = struct();
p = get_executable_dir();
if exist(fullfile(p, 'config.ini'), 'file')
    conf = readini('config.ini');
    if isfield(conf, 'dbuser')
        config.dbuser = conf.dbuser;
    end
    if isfield(conf, 'dbserver')
        config.dbserver = conf.dbserver;
    end
    if isfield(conf, 'dbpw')
        config.dbpw = conf.dbpw;
    end
end

%% Datenbankabfrage

db = db_interaction('messdaten2', config.dbuser, config.dbpw, config.dbserver);
query = ['SELECT DISTINCT(`DS_ID`) FROM `ergebnisse`']

daten = db.get(query);

query = ['SELECT `ID` FROM `datapointinfos`']
daten2 = db.get(query);
db.close();

%% Analyse

ergebnisse = daten.DS_ID;
datapointinfos = daten2.ID;

clear tmp
j = 0;
for i = 1:length(ergebnisse)
    t = find(datapointinfos == ergebnisse(i));
    if isempty(t)
        j = j+1;
        tmp(j,1) = ergebnisse(i);
    end
end