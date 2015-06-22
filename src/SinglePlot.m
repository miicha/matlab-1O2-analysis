classdef SinglePlot < handle
    %SINGLEPLOT Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        xdata;
        ydata;
        plot_args;
        defpath;
        h;
    end
    
    methods
        function this = SinglePlot(xdata, ydata, defpath, varargin)
            this.xdata = xdata;
            this.ydata = ydata;
            this.defpath = defpath;
            
            this.plot_args = varargin;
            
            this.h.f = figure();
            this.h.axes = axes();
            
            this.h.save_plot = uicontrol();
            this.h.save_data = uicontrol();
            
            set(this.h.f, 'resizefcn', @this.resize);
            set(this.h.save_plot, 'units', 'pixels',...
                                  'position', [10 10 120 30],...
                                  'string', 'Plot speichern.',...
                                  'FontSize', 9,...
                                  'callback', @this.save_fig_cb);
            set(this.h.save_data, 'units', 'pixels',...
                                  'position', [130 10 120 30],...
                                  'string', 'Daten speichern.',...
                                  'FontSize', 9,...
                                  'callback', @this.save_data_cb);
            set(this.h.axes, 'units', 'pixels',...
                             'OuterPosition', [10 50 1000 500])
            this.plot();
            this.resize();
        end
        
        function plot(this)
            axes(this.h.axes);
            this.h.p = plot(this.xdata, this.ydata);
            
            for i = 1:2:length(this.plot_args)
                plt_props_handler(this.h.axes, this.plot_args{i}, this.plot_args{i+1});
            end
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
            set(this.h.plot_pre, 'PaperSize', [x_pix+80 y_pix+80]/1.5);
            set(this.h.plot_pre, 'PaperPosition', [10 0 x_pix+80 y_pix+80]/1.5);
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
                    else
                        y = this.ydata;
                    end
                    fprintf(fid, 'x,y\n');
                    fclose(fid);
                    dlmwrite(path, [x y], '-append');

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
            
            apos(3:4) = fpos(3:4) - [20 50];
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