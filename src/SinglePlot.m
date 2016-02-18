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
    end
    
    methods
        function this = SinglePlot(xdata, ydata, ydata_err, defpath, varargin)
            if nargin < 3
                defpath = '';
            end

            this.xdata = xdata;
            this.ydata = ydata;
            if isempty(ydata_err)
                ydata_err = zeros(size(ydata));
            end
            this.ydata_err = ydata_err;
            this.defpath = defpath;
            
            this.plot_args = varargin;
            
            this.h.f = figure();
            this.h.axes = axes();
            
            this.h.save_plot = uicontrol();
            this.h.save_data = uicontrol();
            
            set(this.h.f, 'resizefcn', @this.resize);
            set(this.h.save_plot, 'units', 'pixels',...
                                  'position', [10 10 100 22],...
                                  'string', 'Plot speichern',...
                                  'callback', @this.save_fig_cb);
            set(this.h.save_data, 'units', 'pixels',...
                                  'position', [120 10 100 22],...
                                  'string', 'Daten speichern',...
                                  'callback', @this.save_data_cb);
            set(this.h.axes, 'units', 'pixels',...
                             'OuterPosition', [10 30 1000 500])
            this.plot();
            this.resize();
        end
        
        function plot(this)
            axes(this.h.axes);
            this.h.p = errorbar(this.xdata, this.ydata, this.ydata_err);
            
            for i = 1:2:length(this.plot_args)
                plt_props_handler(this.h.axes, this.plot_args{i}, this.plot_args{i+1});
            end
            xmin = min(min(this.xdata));
            xmax = max(max(this.xdata));
            xmax = xmax + eps(xmax);
            ymin = min(min(this.ydata));
            ymax = max(max(this.ydata));
            ymax = ymax + eps(ymax);
            
            xlim([xmin-(xmax-xmin)/30 xmax+(xmax-xmin)/30])
            ylim([ymin-(ymax-ymin)/30 ymax+(ymax-ymin)/30])
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
        end
        
        function save_data_cb(this, varargin)
            [name, path] = uiputfile('*.txt', 'Plot als PDF speichern', this.defpath);
            if name == 0
                return
            end
            this.save_data([path name]);
        end
        
        function resize(this, varargin)
            apos = this.h.axes.OuterPosition;
            fpos = this.h.f.Position;
            
            apos(3:4) = fpos(3:4) - [20 30];
            this.h.axes.OuterPosition = apos;
        end
    end
end

function plt_props_handler(ax, prop, val)
    if strcmpi(prop, 'title')
        ax.Title.String = val;
    elseif strcmpi(prop, 'xlabel')
        ax.XLabel.String = val;
    elseif strcmpi(prop, 'ylabel')
        ax.YLabel.String = val;
    else
        warning(['Unknown property-value-pair: "' prop '" - "' val '".' ]);
    end
    
end