function hmap(data, grid, cmap)
    %hmap
    % Creates a heat map in the curren axis. Colormap is given by cmap, grid
    % can be either true or false and determines whether a grid is plotted or
    % not.
    if nargin < 3
        cmap = 'summer';
        if nargin < 2
            grid = false;
        end
    end
    im = imagesc(data);
    set(im, 'HitTest', 'off');
    colormap(cmap);
    if grid
        [max_x, max_y] = size(data');
        hold on
        for i = 1:max_x-1
            for j = 1:max_y-1
                line([0 max_x]+.5,[j j]+.5, 'color', [.6 .6 .6], 'HitTest', 'off');
                line([i i]+.5, [0 max_y]+.5, 'color', [.6 .6 .6], 'HitTest', 'off');
            end
        end
        hold off
    end
end