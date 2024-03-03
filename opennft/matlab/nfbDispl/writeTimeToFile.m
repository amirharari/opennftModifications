function writeTimeToFile()
    % This function writes the current date and time to a file every time it is called.
    % The file will be named 'time_log.txt', and each entry will be on a new line.

    % Get the current date and time
    c = clock; % [year month day hour minute seconds]
    fixed_c = fix(c); % Remove decimal parts
    
    % Format the date and time as a string
    datetime_str = sprintf('%04d-%02d-%02d %02d:%02d:%02d', fixed_c(1), fixed_c(2), fixed_c(3), fixed_c(4), fixed_c(5), round(fixed_c(6)));
    
    % Open or create the file for appending
    fileID = fopen('time_log.txt', 'a');
    
    % Write the formatted date and time to the file
    fprintf(fileID, '%s\n', datetime_str);
    
    % Close the file
    fclose(fileID);
end
