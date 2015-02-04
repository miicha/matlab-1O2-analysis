function writeini(file, content, append)
    if nargin < 3
        append = false;
    end
    
    old_content = readini(file);
    
    if ~append
        g = fopen(file, 'w+');
        fprintf(g, '');
        fclose(g);
    end
    f = fopen(file, 'a');
    fields = fieldnames(content);
    try
        for i = 1:length(fields)
            val = content.(fields{i});
            name = char(fields{i});
            if ~isfield(old_content, fields{i}) || ~append
                append_line(f, name, val)
            else
                error('warn:fieldexists', ['Key ' fields{i} ' already exists in ini-file! Aborting']);
            end
        end
    catch err
        if strcmp(err.identifier, 'warn:fieldexists')
            warning(err.message);
        end
        fclose(f);
        writeini(file, old_content, false);
        return
    end
    fclose(f);
end

function append_line(f, name, val)
    if ischar(val)
        fprintf(f, '%s = %s\n', name, val);
    elseif isnumeric(val) && numel(val) == 1
        fprintf(f, '%s = %f\n', name, val);
    end
end