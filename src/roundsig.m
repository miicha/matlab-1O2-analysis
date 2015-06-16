function [ rounded ] = roundsig( number, dop )
    %ROUNDSIG rounds `number` to `dop` digits of precision
    %   [ rounded ] = roundsig( number, dop )
    
    if numel(number) ~= 1
        rounded = zeros(size(number));
        if numel(dop) ~= numel(number)
            for i = 1:numel(number)
                rounded(i) = roundsig(number(i), dop);
            end
        else
            for i = 1:numel(number)
                rounded(i) = roundsig(number(i), dop(i));
            end
        end
        return
    end
    
    if number == 0 || ~isfinite(number) || sum(dop) == 0
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

