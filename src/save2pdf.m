function [ ] = save2pdf( filename, fig, escape )
    %SAVE2PDF: Saves figure to pdf.
    %
    % save2pdf(filename, fig, escape)
    %
    % Saves a figure to a pdf in a nice size and with texed text.
    % 
    % filename - Path (absolute or relative to the current working dir).
    % fig      - Figure to save. Default: Current figure.
    % escape   - escapes ' ' and '~', which cannot be parsed by LaTeX.
    %            Default: true.
    %
    % Example:   plot(1:10);
    %            xlabel('bla');
    %            legend({'curve 1'});
    %            save2pdf('plot')
    %
    % Author:    Sebastian Pfitzner
    %            pfitzseb [at] physik . hu - berlin . de
    
    if nargin < 3
        escape = true;
        if nargin < 2 
            fig = gcf;
        end
    end
    if strcmp(filename, '')
        filename = 'plot.pdf';
    end
    
    [pathstr, name] = fileparts(filename);
    if escape
        name = regexprep(name, ' ', '_');
        name = regexprep(name, '~', '_');
    end
    
    set(fig, 'PaperUnits', 'centimeters');
    set(fig, 'PaperSize', [21 12.5]);
    set(fig, 'PaperPosition', [-1, 0, 22.5, 12.5]);
    
    % Font options:
    o = {'interpreter', 'latex', 'FontSize', 12};
    
    set(get(gca, 'XLabel'), o{:});
    set(get(gca, 'YLabel'), o{:});
    set(get(gca, 'ZLabel'), o{:});
    set(findobj(gcf,'Type','axes','Tag','legend'), o{:});
	if strcmp(pathstr, '')
		print(fig, '-dpdf', '-r600', [name '.pdf'])
	else
		print(fig, '-dpdf', '-r600', [pathstr '/' name '.pdf'])
	end
end
