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

query1 = ['SELECT datapointinfos.ID, `name`,'...
    'ergebnisse.sisa_intens,ergebnisse.sisa_intens_err,ergebnisse.fluo_val '...
    'FROM `datapointinfos` JOIN ergebnisse ON ergebnisse.DS_ID = datapointinfos.ID '...
    'WHERE ergebnisse.fluo_val'];

db = db_interaction('messdaten2', config.dbuser, config.dbpw, config.dbserver);
daten = db.get(query1);


for i = 1:height(daten)
    query = sprintf('UPDATE `datapointinfos` SET `sisa_intens`=%f,`sisa_intens_err`=%f,`fluo_val`=%f WHERE `ID`=%i',...
                    daten.sisa_intens(i),daten.sisa_intens_err(i),daten.fluo_val(i),daten.ID(i));
    db.exec(query)
end

db.close();