function writeini(file, content, append, change)
    %WRITEINI Writes dict to ini-file.
    %   Not a standard-conforming implementation.
    %   
    %       writeini(file, content, append)
    %
    %   Writes the dict `content` to `file` if `append` is false.
    %   If `append` is true, the conents of `content` will be appended to
    %   the end of `file`, if the keys do not already exist.
    
    if nargin < 3
        append = false;
    end
    if nargin < 4
        change = false;
    end
    exists = exist(file, 'file');
    if exists
        old_content = readini(file);
    elseif change
        change = false;
    elseif append
        error('File does not exist! Aborting.')
    end
    
    if change
        new_content = old_content;
        f = fieldnames(content);
        for i = 1:length(f)
            new_content.(f{i}) = content.(f{i});
        end
        content = new_content;
    end
    
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
            if ~append || ~isfield(old_content, fields{i})
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
        if exists
            writeini(file, old_content, false);
            return
        end
    end
    fclose(f);
end

function append_line(f, name, val)
    if ischar(val)
        fprintf(f, '%s = %s\n', name, val);
    elseif isnumeric(val) && numel(val) >= 1
        x = repmat(' %f',1,length(val));
        fprintf(f, ['%s =' x '\n'], name, val);
    end
end