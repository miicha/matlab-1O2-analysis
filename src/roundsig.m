function [ rounded ] = roundsig( number, dop )
    %ROUNDSIG rounds `number` to `dop` digits of precision
    %   [ rounded ] = roundsig( number, dop )
    
    if number == 0 || ~isfinite(number)
        rounded = number;
        return
    end
    
    if dop < 1
        dop = 1;
    end
    
    e = floor(log10(abs(number)) - round(dop) + 1);
    og = 10^abs(e);
    
    if e >= 0
        rounded = round(number/og)*og;
    else
        rounded = round(number*og)/og;
    end
end

