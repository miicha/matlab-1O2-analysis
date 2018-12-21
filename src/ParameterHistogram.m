classdef ParameterHistogram < handle
    %GENERICPLOT Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        h = struct();       % handles
        numbins;
        params;
        paramNames;
        name = 'unknown';
        path = '';
    end
    
    properties (Access = private)
        current_draggable;
    end
    
    methods
        function this = ParameterHistogram(params, paramNames, filename, savepath)
            if nargin > 2
                this.name = filename;
            end
            if nargin > 3
                this.path = [savepath filesep];
            end
            
            num_par = size(params,2);
            
            this.h.f = figure;
            this.h.f.Position = [500 300 900 700];
            this.h.f.Resize = 'off';
            
            this.params = params;
            this.paramNames = strrep(regexprep(paramNames,'^(t)([DT\d])?','\\tau_$2'),'_D','_\Delta');
            this.plotHist();
            
            this.numbins = nan(num_par,1);
            for i = 1:num_par
                this.h.incr{i} = uicontrol(this.h.f, 'units', 'pixels',...
                                                      'style', 'pushbutton',...
                                                      'string','+',...
                                                      'fontsize',12,...
                                                      'tag', num2str(i),...
                                                      'position', [5 5 20 20],...
                                                      'callback', @this.morebins);
                
                this.h.decr{i} = uicontrol(this.h.f, 'units', 'pixels',...
                                                      'style', 'pushbutton',...
                                                      'string','-',...
                                                      'fontsize',12,...
                                                      'tag', num2str(i),...
                                                      'position', [5 5 20 20],...
                                                      'callback', @this.lessbins);
                p = this.h.ax(i).Position;
                tmp = [p(1)+p(3)-20, p(2)+p(4)+5];
                this.h.incr{i}.Position(1:2) = tmp;
                tmp(1) = tmp(1)-22;
                this.h.decr{i}.Position(1:2) = tmp;
            end
            
            this.h.exp_btn = uicontrol(this.h.f, 'units', 'pixels',...
                                                      'style', 'pushbutton',...
                                                      'string','Export',...
                                                      'fontsize',10,...
                                                      'position', [20 20 60 20],...
                                                      'callback', @this.export);
        end
    end
    
    methods(Access=private)
        
        function f = plotHist(this,numbins,saveAx)
            if nargin<3
                saveAx = true;
            end
            num_par = size(this.params,2);
            m = ceil(num_par/2);
            if ~saveAx
                ha = tight_subplot(2,m,[.08 .04],[.08 .02],[.04 .01]);
            end
            for i = 1:num_par
                if saveAx
                    ax_tmp = subplot(2,m,i);
                else
                    ax_tmp = ha(i);
                end
                if nargin >= 2 && length(this.paramNames) == length(numbins) && ~isnan(numbins(i))
                    hi_tmp = histogram(ax_tmp, this.params(:,i),numbins(i));
                else
                    hi_tmp = histogram(ax_tmp,this.params(:,i));
                end
                if saveAx
                    this.h.hist(i) = hi_tmp;
                    this.h.ax(i) = ax_tmp;
                    ax_tmp.Units = 'pixels';
                end
                
                labelname = this.paramNames{i};
                if labelname(1) == '\'
                    labelname = [labelname ' [\mus]'];
                end
                
                xlabel(ax_tmp,labelname)
                drawnow
                
                axes(ax_tmp)
                this.histfit(i,'kernel',saveAx)
                
            end
        end
        
        function morebins(this,varargin)
            i = str2double(varargin{1}.Tag);
            this.numbins(i) = morebins(this.h.hist(i));
            this.histfit(i,'kernel');
        end
        
        function lessbins(this,varargin)
            i = str2double(varargin{1}.Tag);
            this.numbins(i) = fewerbins(this.h.hist(i));
            this.histfit(i,'kernel');
        end
        
        function h = histfit(this,number,dist,saveAx)
            binedges = this.h.hist(number).BinEdges;
            if length(binedges)<5
                try
                    delete(this.h.histFit(number))
                end
                return
            end
            if nargin < 4
                saveAx = true;
            end
            data = this.params(:,number);
            data = data(:);
            data(isnan(data)) = [];
            n = numel(data);

            % Fit distribution to data
            if nargin<3 || isempty(dist)
                dist = 'normal';
            end
            try
                pd = fitdist(data,dist);
            catch myException
                if isequal(myException.identifier,'stats:ProbDistUnivParam:fit:NRequired') || ...
                        isequal(myException.identifier,'stats:binofit:InvalidN')
                    % Binomial is not allowed because we have no N parameter
                    error(message('stats:histfit:BadDistribution'))
                else
                    % Pass along another other errors
                    throw(myException)
                end
            end
            
            % Find range for plotting
            q = icdf(pd,[0.0013499 0.99865]); % three-sigma range for normal distribution
            x = linspace(q(1),q(2));
            if ~pd.Support.iscontinuous
                % For discrete distribution use only integers
                x = round(x);
                x(diff(x)==0) = [];
            end
            
            
            % Normalize the density to match the total area of the histogram
            binwidth = binedges(2)-binedges(1); % Finds the width of each bin
            area = n * binwidth;
            y = area * pdf(pd,x);
            
            if saveAx
                ax = this.h.ax(number);
            else
                ax = gca;
            end
            
            XLim = ax.XLim;
            % Overlay the density
            np = get(ax,'NextPlot');
            set(ax,'NextPlot','add')
            
            if saveAx
                try
                    delete(this.h.histFit(number))
                end
            end
            
            tmp = plot(ax,x,y,'r-','LineWidth',2);
            
            if saveAx
                this.h.histFit(number) = tmp;
            end
            
            if nargout == 1
                h = [hh; hh1];
            end
            
            set(ax,'NextPlot',np)
            ax.XLim = XLim;
        end
        
        function export(this,varargin)
            figure
            this.plotHist(this.numbins, false);
            save2pdf([this.path this.name '-histogramm.pdf'], 'fontsize', 10)
        end
    end
end