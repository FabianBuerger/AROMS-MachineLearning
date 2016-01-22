% function str = struct2string(structObj)
% makes a string out of a struct structObj
%
function str = struct2string(structObj)
    str = evalc('structObj(1)');
end

