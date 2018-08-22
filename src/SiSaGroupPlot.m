classdef SiSaGroupPlot < handle
    %SiSaGroupPlot
    
    properties
        p
        x_pos
        y_pos
        x_data
        y_data
        x_size
        y_size
        ind
        data
        params
        model_fun
        h = struct()           % handles
    end
    
    methods
        function this = SiSaGroupPlot(p)
            this.p = p;
            [this.x_pos, this.y_pos] = find(squeeze(p.overlays{p.current_ov})); % size of the selection
            this.x_data = this.x_pos;
            this.y_data = this.y_pos;

            
            this.x_pos = this.x_pos - min(this.x_pos) + 1;
            this.y_pos = this.y_pos - min(this.y_pos) + 1;
            this.x_size = max(this.x_pos) - min(this.x_pos) + 1;
            this.y_size = max(this.y_pos) - min(this.y_pos) + 1;
            
            this.ind = p.get_current_slice();
            this.data = squeeze(p.data(this.ind{:}, :));
            this.params = squeeze(p.fit_params(this.ind{:}, :));
            this.model_fun = this.p.sisa_fit.func;
            
            this.h.f = figure(); 
            this.h.s = {};
            
            scsize = get(0,'screensize');
            
            set(this.h.f, 'units', 'pixels',...
                          'position', [scsize(3)-950 scsize(4)-750 900 680],...
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

            maxy = max(max(max(pltdata(:, :, (this.p.t_zero+this.p.t_offset):end))))*1.2;
            for i = 1:length(indx)
                if ndims(this.params)==3
                    p = num2cell(squeeze(this.params(indx(i), indy(i), :)));
                else
                    p = num2cell(squeeze(this.params(indx(i), :)));
                end
                fitdata = this.model_fun(p{:}, this.p.x_data(this.p.t_zero:end));
                
                this.h.s{i} = subplot(this.y_size, this.x_size,sub2ind([this.x_size, this.y_size],...
                        this.x_pos(i), 1+this.y_size-this.y_pos(i)));
                plot(this.p.x_data(this.p.t_zero:end), squeeze(this.data(indx(i),...
                           indy(i), this.p.t_zero:end)),'.');
                       
                set(this.h.s{i}, 'xtick', [], 'ytick', [], 'ButtonDownFcn', @this.click_cb,...
                                 'Tag', [num2str(indx(i)) '/' num2str(indy(i))]);
                
                hold on
                plot(this.p.x_data(this.p.t_zero:end), fitdata, 'r-');
                hold off
                xlim([0 max(this.p.x_data)])
                ylim([0 maxy])
            end
        end
        
        function save_fig_cb(this, varargin)
            [name, path] = uiputfile('*.pdf', 'Plot als PDF speichern', fullfile(this.p.p.savepath, this.p.p.genericname));
            if name == 0
                return
            end
            this.p.p.set_savepath(path);
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
            indxy = str2double(strsplit(varargin{1}.Tag, '/'));
            slice = this.ind;
            
            a = false(length(slice), 1);
            for i = 1:length(slice)
                if ischar(slice{i})
                    a(i) = true;
                end
            end

            slice(logical(a)) = num2cell(indxy);
            this.p.left_click_on_axes(slice);
        end % mouseclick on plot
    end
end

