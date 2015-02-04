function [ res ] = readini( file )
    res = [];    
    f = fopen(file, 'r');
    while ~feof(f)
        current_line = strtrim(fgetl(f));
        if isempty(current_line)
            continue
        end
        [i, o] = regexp(current_line, '^\w+\s?=');
        name = strtrim(current_line(i:o-1));
        val = strtrim(current_line(o+1:end));
        res.(name) = val;
    end
    fclose(f);
end