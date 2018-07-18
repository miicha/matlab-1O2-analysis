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
% query = 'SELECT * FROM `ergebnisse` JOIN datapointinfos on datapointinfos.ID = DS_ID JOIN dateiinfos ON dateiinfos.ID = datapointinfos.datei WHERE `A1`>20 AND `A1_err`<`A1`/4 AND `chisq`< 1.08 ORDER BY `ergebnisse`.`A1_err` DESC ';

query = ['SELECT * FROM `ergebnisse` JOIN datapointinfos on datapointinfos.ID = DS_ID '...
    'JOIN dateiinfos ON dateiinfos.ID = datapointinfos.datei WHERE `A1`>20 '...
    'AND `A1_err`<`A1`/4 AND `chisq`< 1.08 '...
    'AND dateiinfos.ID = 15']
%     'AND dateiinfos.name like "%art%"']

db = db_interaction('messdaten2', config.dbuser, config.dbpw, config.dbserver);
daten = db.get(query);
db.close();


%% Darstellung
figure(42)
ax1 = subplot(2,2,1);
h = histogram(daten.t1);
ax2 = subplot(2,2,2);
h2 = histogram(daten.t2);
ax3 = subplot(2,2,3);
h3 = histogram(daten.t3);

for j = 15:50
    h2.NumBins = j;
    ax2.Title.String = num2str(j);
    pause(0.1)
end


