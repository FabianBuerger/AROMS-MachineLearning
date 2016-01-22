%function saveMultilineString2File(linesCellArray,filename)
% save a multi line string to file
%
function saveMultilineString2File(linesCellArray,filename)

    FID = fopen(filename, 'w');
    fprintf(FID, '%s\n', linesCellArray{:});
    fclose(FID);  