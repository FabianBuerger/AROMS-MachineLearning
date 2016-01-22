% linesCellArray = readMultilineString(filename)
% Read content of text file into cell array of string lines
%
function linesCellArray = readMultilineString(filename)

linesCellArray={};
fid = fopen(filename);
tline = fgetl(fid);
while ischar(tline)
   linesCellArray=[linesCellArray;tline];
   tline = fgetl(fid);
end