classdef UIPlot < handle
    %UIPLOT Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        cp;                     % current point
        data;
        sp;                     % starting point for fit
        n_param;
        fitted = false;
        fitparams;
        cfit;
        model;
        models;
        h = struct();           % handles
    end
    
    methods
        function plt = UIPlot(cp, ui)
            %% get data
            plt.models = ui.models;
            if ui.fitted
                plt.fitted = true;
            end
            if ui.model
                m = keys(plt.models);
                plt.model = plt.models(m{ui.model});
            end
            plt.cp = [cp ui.current_z ui.current_sa];
            plt.getdata(ui);

            %% initialize UI objects
            
            plt.h.f = figure();
            
            plt.h.axes = axes();
            plt.h.res = axes();
            
            plt.h.fitpanel = uipanel();
                plt.h.drpd = uicontrol(plt.h.fitpanel);
                plt.h.pb = uicontrol(plt.h.fitpanel);
                plt.h.param = uipanel(plt.h.fitpanel);

            
            %% figure
            
            set(plt.h.f, 'units', 'pixels',...
                         'position', [500 200 1000 710],...
                         'numbertitle', 'off',...
                         'name',  ['SISA Scan - ' ui.fileinfo.name ' - ' num2str(plt.cp)],...
                         'resize', 'on',...
                         'ResizeFcn', @plt.resize);
                  
            %% plot

            set(plt.h.axes, 'units', 'pixels',...
                            'position', [50 260 900 400]);
                        
            set(plt.h.res, 'units', 'pixels',...
                            'position', [50 110 900 130]);
            
            %% fitoptions
            set(plt.h.fitpanel, 'units', 'pixels',...
                                'position', [50 10 900 75]);
            
            set(plt.h.drpd, 'units', 'pixels',...
                            'style', 'popupmenu',...
                            'string', keys(ui.models),...
                            'value', ui.model,...
                            'position', [10 5 200 27],...
                            'FontSize', 9,...
                            'callback', @plt.set_model);
                        
            set(plt.h.pb, 'units', 'pixels',...
                          'position', [10 35 100 30],...
                          'string', 'Fit',...
                          'FontSize', 9,...
                          'callback', @plt.fit);
                        
            set(plt.h.param, 'units', 'pixels',...
                             'position', [250 10 600 55]);
                         
            plt.h.pe = cell(1, 1);
            plt.h.pd = cell(1, 1);
            plt.h.pc = cell(1, 1);

            %% pushbutton

                      
            %% draw plot
            plt.plotdata();
            plt.generate_param();
        end
        
        function getdata(plt, ui)
            if ~ui.data_read
                dataset = ['/' num2str(plt.cp(1)-1) '/' num2str(plt.cp(2)-1)...
                           '/' num2str(plt.cp(3)-1) '/sisa/' num2str(ui.current_sa)];
                plt.data(1, :) = h5read(ui.fileinfo.path, dataset);
            else
                plt.data(1, :) = squeeze(ui.data(plt.cp(1), plt.cp(2), plt.cp(3), ui.current_sa, :));
            end
%             if ui.fitted
%                 plt.model = ui.model;
%                 plt.fitparams = ui.params(plt.cp(1), plt.cp(2), plt.cp(3), ui.current_sa, :);
%             end
            x = 0:(length(plt.data(1, :))-1);
            plt.data(2, :) = x*ui.channel_width;
        end
        
        function plotdata(plt)
            datal = plt.data(1, :);
            x = plt.data(2, :);
            [~, pulse] = max(datal);
            m = max(datal((pulse + 30):end));
            m = m*1.1;
            axes(plt.h.axes);
            plot(x, datal, '.');
            ylim([0 m]);
            xlim([0 max(x)]);
        end
        
        function plotfit(plt)
            x = plt.data(2, :);

            plt.plotdata();
            axes(plt.h.axes);
            hold on
%             plot(plt.data(2, :), feval(, 'r');
            plot(plt.cfit);
            hold off
            axes(plt.h.res);
            hold on
%             plot(x, fity-plt.data(1,:), 'b.');
            line([0 max(x)], [0 0], 'Color', 'r');
            xlim([0 max(x)]);
        end
        
        function fit(plt, varargin)
            x = plt.data(2, :);
            y = plt.data(1, :);
            x = x(10:end)+10*20/1000;
            y = y(10:end);
            w = sqrt(y);
            for i = 1:plt.n_param
                sp(i) = str2double(get(plt.h.pe{i}, 'string'));
            end
            plt.set_model();
            [f, gof] = fitdata(x, y, plt.model, sp, w);
            p = coeffvalues(f);
            p_e = confint(f);
            chisq = gof.rmse/gof.dfe;
            plt.cfit = f;
            plt.fitparams = p;
            plt.fitted = true;
            plt.plotfit();
            for i = 1:plt.n_param
                str = sprintf('%1.2f', p(i));
                set(plt.h.pe{i}, 'string', str);
            end
        end
        
        function set_model(plt, varargin)
            m = keys(plt.models);
            plt.model = plt.models(m{get(plt.h.drpd, 'value')});
            plt.generate_param();
        end
        
        function resize(plt, varargin)
            fP = get(plt.h.f, 'position');
            
            aP = get(plt.h.axes, 'position');
            aP(3:4) = fP(3:4) - aP(1:2) - 50;
            set(plt.h.axes, 'position', aP);
            
            aP = get(plt.h.res, 'position');
            aP(3) = fP(3) - aP(1) - 50;
            set(plt.h.res, 'position', aP);
            
            fpP = get(plt.h.fitpanel, 'position');
            fpP(3) = fP(3) - fpP(1) - 50;
            set(plt.h.fitpanel, 'position', fpP);
        end
        
        function generate_param(plt)
            for i = 1:length(plt.h.pe)
                delete(plt.h.pe{i});
                set(plt.h.pd{i}, 'visible', 'off');
                delete(plt.h.pd{i});
                delete(plt.h.pc{i});
                clear('plt.h.pe', 'plt.h.pd', 'plt.h.pc');
            end
            n_param = 0;
            for i = 1:10
                p = num2cell(ones(i, 1));
                try 
                    plt.model(p{:});
                catch
                    continue
                end
                n_param = i-1;
                break
            end
            plt.h.pe = cell(n_param, 1);
            plt.h.pd = cell(n_param, 1);
            plt.h.pc = cell(n_param, 1);
            for i = 1:n_param
                 plt.h.pe{i} = uicontrol(plt.h.param, 'units', 'pixels',...
                                                      'style', 'edit',...
                                                      'string', '1',...
                                                      'position', [10+(i-1)*100 25 45 20]);
                 plt.h.pd{i} = uicontrol(plt.h.param, 'units', 'pixels',...
                                                      'style', 'text',...
                                                      'string', '+-',...
                                                      'HorizontalAlignment', 'left',...
                                                      'position', [55+(i-1)*100 25 30 20]); 
                 plt.h.pc{i} = uicontrol(plt.h.param, 'units', 'pixels',...
                                                      'style', 'checkbox',...
                                                      'string', 'fix',...
                                                      'position', [10+(i-1)*100 5 50 15]); 
            end
            if n_param == 0
                set(plt.h.param, 'visible', 'off');
            else
                set(plt.h.param, 'visible', 'on');
                pP = get(plt.h.param, 'position');
                pP(3) = 45+(n_param-1)*100+45+10;
                set(plt.h.param, 'position', pP);
            end
            plt.n_param = n_param;
        end
    end
    
end

