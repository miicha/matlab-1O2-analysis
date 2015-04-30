function plot_overlay(data)
    %plot_overlay
    % Plots `data` as an overlay over the current axis.

    [m, n] = size(data);
    image = ones(m, n, 3);
    image(:, :, 1) = (image(:, :, 1) - data);
    for i = 2:3
        image(:, :, i) = (image(:, :, i) - data)*0.2;
    end
    im = imagesc(image);
    set(im, 'HitTest', 'off',...
            'AlphaData', image(:,:,1)*.4);
end