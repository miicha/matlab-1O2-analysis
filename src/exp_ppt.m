abb = gcf;

% abb.Resize = 'on';

x_limits = [-0.5 30];


fontsize = 22;
tick_fontsize = fontsize-2;

versch_1 = 40;
versch_2 = 20;


texify = false;


aspectratio = 5/3; % width/height
figwidth = 0.8; % *textwidth
textwidth = 17; % cm


set(abb, 'PaperUnits', 'centimeters');
set(abb, 'PaperSize', [textwidth, textwidth/aspectratio].*figwidth);
set(abb, 'PaperPosition', [0, 0, [textwidth, textwidth/aspectratio].*figwidth]);

if texify
    legendo = {'interpreter', 'latex', 'FontSize', tick_fontsize};
else
    legendo = {'FontSize', tick_fontsize};
end

children = abb.Children;
for i = 1:length(children)
    i
    if isa(children(i), 'matlab.graphics.axis.Axes')
        
        xlim(children(i),x_limits);
        
        pos = children(i).Position;
        
        pos = pos + [versch_2 versch_1 -versch_2 -versch_1];
        
        children(i).Position = pos;
        children(i).FontSize = tick_fontsize;
        children(i).ActivePositionProperty = 'OuterPosition'; % Beschriftung nicht abschneiden
        children(i).XLabel.FontSize = fontsize;
        children(i).YLabel.FontSize = fontsize;
        children(i).ZLabel.FontSize = fontsize;
        
        if texify
            children(i).TickLabelInterpreter = 'latex';
        end
        
        for j = 1:length(children(i).XAxis)
            children(i).XAxis(j).Label.FontSize = fontsize;
            if texify
                children(i).XAxis(j).Label.Interpreter = 'latex';
            end
        end
        for j = 1:length(children(i).YAxis)
            children(i).YAxis(j).Label.FontSize = fontsize;
            if texify
                children(i).YAxis(j).Label.Interpreter = 'latex';
            end
        end
        for j = 1:length(children(i).XAxis)
            children(i).ZAxis(j).Label.FontSize = fontsize;
            if texify
                children(i).ZAxis(j).Label.Interpreter = 'latex';
            end
        end
        
    end
    if isa(children(i), 'matlab.graphics.illustration.Legend')
        set(children(i), legendo{:})
    end
    if isa(children(i), 'matlab.graphics.illustration.ColorBar')
        set(children(i), 'TickLabelInterpreter', 'latex')
        set(children(i), 'FontSize', tick_fontsize)
    end
end


print -clipboard -dmeta    % Funktioniert beschissen...