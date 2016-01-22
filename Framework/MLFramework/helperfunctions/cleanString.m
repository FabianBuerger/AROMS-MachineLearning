%function str = cleanString(str)
% removes blanks and other signs from string to make nice folder or filenames
%
%
function str = cleanString(str)
   str = strrep(str,' ','');
   str = strrep(str,':',''); 
   str = strrep(str,'/',''); 
   str = strrep(str,'\',''); 
   str = strrep(str,'#','');
   str = strrep(str,'~','');
   str = strrep(str,'*','');