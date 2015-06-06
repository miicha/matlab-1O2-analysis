function s = format_time(number)
    %format_time
    % takes a time in seconds and returns a nice string representation

    if number > 1.5*60*60 % more than one and a half hours
        s = sprintf('%.0f hours %.0f min', floor(number/(60*60)), number-(60*60*floor(number/(60*60))));
    elseif number > 1.5*60 % more than one and a half minutes
        s = sprintf('%.0f min %.0f s', floor(number/60), number-(60*floor(number/60)));
    else % seconds
        s = sprintf('%.1f s', number);
    end
end