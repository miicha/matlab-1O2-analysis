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

query = ['SELECT ergebnisse.`ID`,`A1`,`t1`,`t2`,`t3`,datapointinfos.fluo_val,datapointinfos.sisa_intens, Modell '...
         'FROM `ergebnisse` '...
         'JOIN datapointinfos ON datapointinfos.ID = ergebnisse.DS_ID '...
         'JOIN dateiinfos ON dateiinfos.ID = datapointinfos.datei '...
         'JOIN ps ON dateiinfos.photosensitizer = ps.ID '...
         'WHERE '...
         'ps.name = "Foslip" AND dateiinfos.Probe = 1 AND datapointinfos.sisa_intens > 100  AND Modell = 6']


% query = ['SELECT * FROM `ergebnisse` JOIN datapointinfos on datapointinfos.ID = DS_ID '...
%     'JOIN dateiinfos ON dateiinfos.ID = datapointinfos.datei WHERE `A1`>20 '...
%     'AND `A1_err`<`A1`/4 AND `chisq`< 1.08 '...
%     'AND dateiinfos.ID = 15']
% %     'AND dateiinfos.name like "%art%"']

db = db_interaction('messdaten2', config.dbuser, config.dbpw, config.dbserver);
daten = db.get(query);
db.close();


%% Darstellung
figure(424)
ax1 = subplot(2,2,1);
h = histogram(daten.t1);
title('t1')
ax2 = subplot(2,2,2);
h2 = histogram(daten.t2);
title('t2')
ax3 = subplot(2,2,3);
h3 = histogram(daten.t3);
title('t3')


x2 = h2.BinEdges(1:end-1)+h2.BinWidth/2;
y2 = h2.Values;
x3 = h3.BinEdges(1:end-1)+h3.BinWidth/2;
y3 = h3.Values;

fo2 = fitoptions('Method','NonlinearLeastSquares',...
               'Lower',[0,0,0,0,0,0],...
               'StartPoint',[200 100 6 10 1 1]);
ft2 = fittype('a1*exp(-((x-b1)/c1)^2)+a2*exp(-((x-b2)/c2)^2)','options',fo2);

fo3 = fitoptions('Method','NonlinearLeastSquares',...
               'Lower',[0,0,0,0,0,0],...
               'StartPoint',[200 100 20 100 10 10]);
ft3 = fittype('a1*exp(-((x-b1)/c1)^2)+a2*exp(-((x-b2)/c2)^2)','options',fo3);


f2 = fit(x2',y2',ft2)
f3 = fit(x3',y3',ft3)


axes(ax2)
% figure(4512)
% plot(x,y)
hold on
plot(f2)
hold off

axes(ax3)
hold on
plot(f3)
hold off


% for j = 15:50
%     h2.NumBins = j;
%     ax2.Title.String = num2str(j);
%     pause(0.1)
% end


