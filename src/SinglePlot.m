classdef SinglePlot < handle
    %SINGLEPLOT 1-D plot that can be saved to .pdf and .txt.
    %
    %   handle = SinglePlot(xdata, ydata, defpath, varargin)
    %   
    %   xdata and ydata can either be vectors or matrices. If xdata is a
    %   vector, all columns in ydata will be plotted against xdata; if
    %   xdata is a matrix, each column in ydata will be plotted against the
    %   correspondung column in xdata.
    %   
    %   defpath is the default path (and filename) where the plot or the 
    %   data should be saved. If undefined the current working dir is the 
    %   default path. Set to '' if you do not want to specify it but need
    %   the varargin.
    %
    %   varargin are certain property-value-pairs that can customize the
    %   axes labels and title among others. To be expanded.
    %
    %   Example:
    %       SinglePlot([1 2 3 5], [2 3 4 5]);
    %
    %   Author:
    %       Sebastian Pfitzner
    
    properties
        xdata;
        ydata;
        ydata_err;
        plot_args;
        defpath;
        h;
        plot_3d;
        l_max;
        l_min;
        use_user_legend;
    end
    
    methods
        function this = SinglePlot(xdata, ydata, ydata_err, defpath, varargin)
            if nargin < 4
                defpath = '';
                if nargin < 3
                    ydata_err = [];
                end
            end
            
            this.xdata = xdata;
            if length(ydata)>length(xdata)
                warning('Länge der zu plottenden Vektoren stimmt nicht überein...')
                ydata = ydata(1:length(xdata));
            end
            temp = size(ydata);
            if min(temp)>1
                this.plot_3d = true;
            else
                this.plot_3d = false;
            end
                
            this.ydata = ydata;

            this.ydata_err = ydata_err;
            this.defpath = defpath;
            
            this.plot_args = varargin;
            
            this.h.f = figure();
            this.h.axes = axes();
            
            this.h.save_plot = uicontrol(this.h.f);
            this.h.save_data = uicontrol(this.h.f);
            this.h.tick_min = uicontrol(this.h.f);
            this.h.tick_max = uicontrol(this.h.f);
            
            tick_min = xdata(1);
            tick_max = xdata(end);
            if tick_min > 208 && tick_min < 209
                tick_min = 500;
                tick_max = 900;
            end
            
            set(this.h.f, 'resizefcn', @this.resize);
            set(this.h.save_plot, 'units', 'pixels',...
                                  'position', [10 10 100 22],...
                                  'string', 'Plot speichern',...
                                  'callback', @this.save_fig_cb);
            set(this.h.save_data, 'units', 'pixels',...
                                  'position', [120 10 100 22],...
                                  'string', 'Daten speichern',...
                                  'callback', @this.save_data_cb);
            %% x-axis               
            set(this.h.tick_min,  'units', 'pixels',...
                               'style', 'edit',...
                               'FontSize', 9,...
                               'string', num2str(tick_min),...
                               'horizontalAlignment', 'left',...
                               'callback', @this.set_tick_cb,...
                               'position', [250 10 65 17]);
            set(this.h.tick_max,  'units', 'pixels',...
                               'style', 'edit',...
                               'FontSize', 9,...
                               'string', num2str(tick_max),...
                               'horizontalAlignment', 'left',...
                               'callback', @this.set_tick_cb,...
                               'position', [320 10 65 17]);
            %% general                  
            set(this.h.axes, 'units', 'pixels',...
                             'OuterPosition', [10 30 1000 500])
            this.plot();
            this.resize();
        end
        
        function plot(this)
            axes(this.h.axes);
            
            xmin = min(min(this.xdata));
            xmax = max(max(this.xdata));
            xmax = xmax + eps(xmax);
            ymin = min(min(this.ydata));
            ymax = max(max(this.ydata));
            ymax = ymax + eps(ymax);
            
            this.l_max = xmax;
            this.l_min = xmin;
            
            if isempty(this.ydata_err)
                if this.plot_3d
                    y = 1:size(this.ydata,1);
                    this.h.p = surf(this.h.axes,this.xdata, y, this.ydata);
                    this.h.p.EdgeColor = 'none';
                    this.set_limits('lower');
                    this.set_limits('upper');
%                     this.h.axes.View = [80,20];
                    this.h.axes.View = [9,4];
                else
                    this.h.p = plot(this.h.axes, this.xdata, this.ydata');
                end
            else
                if this.plot_3d
                    this.ydata = this.ydata(1,:);
                end
                this.h.p = errorbar(this.h.axes, this.xdata, this.ydata, this.ydata_err);
            end
            
            for i = 1:2:length(this.plot_args)
                this.plt_props_handler(this.h.axes, this.plot_args{i}, this.plot_args{i+1});
            end
            
            if this.plot_3d
                xlim([xmin-(xmax-xmin)/30 xmax+(xmax-xmin)/30])
%                 ylim([ymin-(ymax-ymin)/30 ymax+(ymax-ymin)/30])
            else
                xlim([xmin-(xmax-xmin)/30 xmax+(xmax-xmin)/30])
                ylim([ymin-(ymax-ymin)/30 ymax+(ymax-ymin)/30])
            end
            this.set_limits('lower');
            this.set_limits('upper');
        end
        
         % upper and lower bound of legend
        function set_tick_cb(this, varargin)
            switch varargin{1}
                case this.h.tick_min
                    this.set_limits('lower');
                case this.h.tick_max
                    this.set_limits('upper');
            end
        end
        
        function set_limits(this,type)
            switch type
                case 'lower'
                    new_l_min = str2double(get(this.h.tick_min, 'string'));
                    if new_l_min < this.l_max
                        this.l_min = new_l_min;
                        this.use_user_legend = true;
                    elseif isempty(get(this.h.tick_min, 'string'))
                        this.use_user_legend = false;
                    else
                        set(this.h.tick_min, 'string', this.l_min);
                    end
                case 'upper'
                    new_l_max = str2double(get(this.h.tick_max, 'string'));
                    if new_l_max > this.l_min
                        this.l_max = new_l_max;
                        this.use_user_legend = true;
                    elseif isempty(get(this.h.tick_max, 'string'))
                        this.use_user_legend = false;
                    else
                        set(this.h.tick_max, 'string', this.l_max);
                    end
            end
            this.h.axes.XLim = [this.l_min this.l_max];
        end
        
        function generate_export_fig(this, vis)
            if isfield(this.h, 'plot_pre') && ishandle(this.h.plot_pre)
                figure(this.h.plot_pre);
                clf();
            else
                this.h.plot_pre = figure('visible', vis);
            end
            set(this.h.plot_pre, 'units', 'pixels',...
                                 'numbertitle', 'off',...
                                 'menubar', 'none',...
                                 'position', [100 100 1100 750],...
                                 'name', 'Plot-Vorschau',...
                                 'resize', 'off',...
                                 'Color', [.95, .95, .95]);

            ax = copyobj(this.h.axes, this.h.plot_pre);
            ax.OuterPosition = [50 50 1050 690];
            
            this.h.plot_pre.Position = [100 100 460 310];
            ax.OuterPosition = [10 10 450 300];
            ax.Title.Visible = 'off';
        end
        
        function save_fig(this, path)
            tmp = get(this.h.plot_pre, 'position');
            x_pix = tmp(3);
            y_pix = tmp(4);
            
            % save the plot and close the figure
            set(this.h.plot_pre, 'PaperUnits', 'points');
            set(this.h.plot_pre, 'PaperSize', [x_pix y_pix]/2);
            set(this.h.plot_pre, 'PaperPosition', [0 0 x_pix y_pix]/2);
            print(this.h.plot_pre, '-dpdf', '-r600', path);
            close(this.h.plot_pre)
        end
        
        function save_data(this, path)
            fid = fopen(path, 'w');
            
            sx = size(this.xdata);
            sy = size(this.ydata);
            
            % only one set of x values
            if sx(1) == 1 || sx(2) == 1
                if sx(1) < sx(2)
                    x = this.xdata';
                else
                    x = this.xdata;
                end
                
                % only one set of y values
                if sy(1) == 1 || sy(2) == 1
                    if sy(1) < sy(2)
                        y = this.ydata';
                        yerr = this.ydata_err';
                    else
                        y = this.ydata;
                        yerr = this.ydata_err;
                    end
                    fprintf(fid, 'x,y,err\n');
                    fclose(fid);
                    dlmwrite(path, [x y yerr], '-append');
                    
                elseif this.plot_3d
                    data = this.ydata';
                    sy = size(data);
                    fprintf(fid, 'x,');
                    for i = 1:sy(2)
                        if i == sy(2)
                            fprintf(fid, 'y%d\n', i);
                        else
                            fprintf(fid, 'y%d,', i);
                        end
                        
                    end
                    fclose(fid);
                    data = [x data];
                    data(:,1:4)
                    dlmwrite(path, data, '-append');
                    
                else % multiple sets of y values
                    fprintf(fid, 'x,');
                    for i = 1:sy(2)
                        if i == sy(2)
                            fprintf(fid, 'y%d\n', i);
                        else
                            fprintf(fid, 'y%d,', i);
                        end
                        
                    end
                    fclose(fid);
                    dlmwrite(path, [x this.ydata], '-append');
                end
            else % multiple sets of x values
                warndlg('Cannot currently export plot-data with more than one x-axis');
            end
            
        end
        
        function save_fig_cb(this, varargin)
            [name, path] = uiputfile('*.pdf', 'Plot als PDF speichern', this.defpath);
            if name == 0
                return
            end
            this.generate_export_fig('off');
            this.save_fig([path name]);
%             this.smode.p.set_savepath(path);
        end
        
        function save_data_cb(this, varargin)
            [name, path] = uiputfile('*.txt', 'Plot als PDF speichern', this.defpath);
            if name == 0
                return
            end
            this.save_data([path name]);
%             this.smode.p.set_savepath(path);
        end
        
        function resize(this, varargin)
            apos = this.h.axes.OuterPosition;
            fpos = this.h.f.Position;
            
            apos(3:4) = fpos(3:4) - [20 30];
            this.h.axes.OuterPosition = apos;
        end
        
        function plt_props_handler(this,ax, prop, val)
            if strcmpi(prop, 'title')
                ax.Title.String = val;
            elseif strcmpi(prop, 'xlabel')
                ax.XLabel.String = val;
            elseif strcmpi(prop, 'ylabel')
                ax.YLabel.String = val;
            elseif strcmpi(prop, 'timescale')
                this.h.p.YData = this.h.p.YData * val;
            else
                warning(['Unknown property-value-pair: "' prop '" - "' val '".' ]);
            end
            
        end
    end
end