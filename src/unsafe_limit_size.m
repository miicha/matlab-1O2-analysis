function unsafe_limit_size(fig, minSize)
    %unsafe_limit_size
    % Uses calls to the underlying java-window-object to limit the size of
    % figure `fig` to `minSize` (vector with two entries, min_x and min_y).
    drawnow();
    jFrame = get(handle(fig), 'JavaFrame');
    jWindow = jFrame.fHG2Client.getWindow;
    tmp = java.awt.Dimension(minSize(1), minSize(2));
    jWindow.setMinimumSize(tmp);
end