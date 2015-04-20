classdef UIGroupPlot < handle
    %UIGROUPPLOT
    
    properties
        ui
        x_pos
        y_pos
        x_data
        y_data
        x_size
        y_size
        data
        params
        model_fun
        h = struct()           % handles
    end
    
    methods
        function this = UIGroupPlot(ui)
            this.ui = ui;
            [this.x_pos, this.y_pos] = find(ui.overlay_data); % size of the selection
            if ui.curr_dims(1) < ui.curr_dims(2)
                this.x_data = this.x_pos;
                this.y_data = this.y_pos;
            else
                this.y_data = this.x_pos;
                this.x_data = this.y_pos;
            end
            
            this.x_pos = this.x_pos - min(this.x_pos) + 1;
            this.y_pos = this.y_pos - min(this.y_pos) + 1;
            this.x_size = max(this.x_pos) - min(this.x_pos) + 1;
            this.y_size = max(this.y_pos) - min(this.y_pos) + 1;
            
            this.data = squeeze(ui.data(ui.ind{:}, :));
            this.params = squeeze(ui.fit_params(ui.ind{:}, :));
            tmp = this.ui.models(this.ui.model);
            this.model_fun =  tmp{1};
            
            
            this.h.f = figure(); 
            this.h.s = {};
            set(this.h.f, 'units', 'pixels',...
                          'position', [500 200 1000 710],...
                          'numbertitle', 'off',...
                          'menubar', 'none',...
                          'toolbar', 'figure',...
                          'resize', 'on',...
                          'name', 'Auswahl 1');
                      
            toolbar_pushtools = findall(findall(this.h.f, 'Type', 'uitoolbar'),...
                                                         'Type', 'uipushtool');
            toolbar_toggletools = findall(findall(this.h.f, 'Type', 'uitoolbar'),...
                                                    'Type', 'uitoggletool');

            set(findall(toolbar_pushtools, 'Tag', 'Plottools.PlottoolsOn'), 'visible', 'off');
            set(findall(toolbar_pushtools, 'Tag', 'Plottools.PlottoolsOff'), 'visible', 'off');
            set(findall(toolbar_pushtools, 'Tag', 'Standard.PrintFigure'), 'visible', 'off');
            set(findall(toolbar_pushtools, 'Tag', 'Standard.FileOpen'), 'visible', 'off');
            set(findall(toolbar_pushtools, 'Tag', 'Standard.NewFigure'), 'visible', 'off');
            
            set(findall(toolbar_pushtools, 'Tag', 'Standard.SaveFigure'),...
                                                  'clickedcallback', @this.save_fig_cb);
            
            set(findall(toolbar_toggletools, 'Tag', 'Annotation.InsertLegend'), 'visible', 'off',...
                                                                          'Separator', 'off');
            set(findall(toolbar_toggletools, 'Tag', 'Annotation.InsertColorbar'), 'visible', 'off',...
                                                                          'Separator', 'off');
            set(findall(toolbar_toggletools, 'Tag', 'DataManager.Linking'), 'visible', 'off',...
                                                                          'Separator', 'off');
            set(findall(toolbar_toggletools, 'Tag', 'Exploration.Rotate'), 'visible', 'off');
            set(findall(toolbar_toggletools, 'Tag', 'Standard.EditPlot'), 'visible', 'off',...
                                                                          'Separator', 'off');
                      
            this.plot_selection();
        end
        
        function plot_selection(this)
            indx = this.x_data;
            indy = this.y_data;
%             size(this.data)
            pltdata = this.data(indx, indy, :);
 
            maxy = max(max(max(pltdata(:, :, (this.ui.t_zero+this.ui.t_offset):end))))*1.2;
            for i = 1:length(indx)
                if ndims(this.params)==3
                    p = num2cell(squeeze(this.params(indx(i), indy(i), :)));
                else
                    p = num2cell(squeeze(this.params(indx(i), :)));
                end
                fitdata = this.model_fun(p{:}, this.ui.x_data(this.ui.t_zero:end));
                
                this.h.s{i} = subplot(this.y_size, this.x_size,sub2ind([this.x_size, this.y_size],...
                        this.x_pos(i), 1+this.y_size-this.y_pos(i)));
                plot(this.ui.x_data(this.ui.t_zero:end), squeeze(this.data(indx(i),...
                           indy(i), this.ui.t_zero:end)),'.');
                       
                set(this.h.s{i}, 'xtick', [], 'ytick', [], 'ButtonDownFcn', @this.click_cb, 'Tag', num2str(i));
                
                hold on
                plot(this.ui.x_data(this.ui.t_zero:end), fitdata, 'r-');
                hold off
                xlim([0 max(this.ui.x_data)])
                ylim([0 maxy])
            end
        end
        
        function save_fig_cb(this, varargin)
            [name, path] = uiputfile('*.pdf', 'Plot als PDF speichern', fullfile(this.ui.savepath, this.ui.genericname));
            if name == 0
                return
            end
            this.ui.set_savepath(path);
            path = fullfile(path, name);
            set(this.h.f, 'toolbar', 'none');
            tmp = get(this.h.f, 'position');
            x_pix = tmp(3);
            y_pix = tmp(4);
            
            set(this.h.f, 'PaperUnits', 'points');
            set(this.h.f, 'PaperSize', [x_pix+80 y_pix+80]/1.5);
            set(this.h.f, 'PaperPosition', [0 0 x_pix+80 y_pix+80]/1.5);
            print(this.h.f, '-dpdf', '-r600', path);
            set(this.h.f, 'toolbar', 'figure');
        end
        
        function click_cb(this, varargin)
            t = str2double(varargin{1}.Tag);
            this.x_data(t);
            
            index{this.ui.curr_dims(1)} = this.x_data(t); % x ->
            index{this.ui.curr_dims(2)} = this.y_data(t); % y ^
            index{this.ui.curr_dims(3)} = this.ui.ind{this.ui.curr_dims(3)};
            index{this.ui.curr_dims(4)} = this.ui.ind{this.ui.curr_dims(4)};

            for i = 1:4
                if index{i} > this.ui.fileinfo.size(i)
                    index{i} = this.ui.fileinfo.size(i);
                elseif index{i} <= 0
                     index{i} = 1;
                end
            end
            
            i = length(this.ui.plt);
            this.ui.plt{i+1} = UIPlot([index{:}], this.ui);
        end % mouseclick on plot
    end
    
end

