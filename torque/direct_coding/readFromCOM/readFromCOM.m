function data=readFromCOM(comString,printReads)
data = [];
device = serialport(comString,115200);
FS = stoploop({'Click OK to stop acquisition'}) ;
disp('> Compile and run the code. If already running, compile and run the code from scratch');
%string = '';

rowNum = 1;
error = false;

%wait for INIT
while(~FS.Stop())
    newLineString = readline(device);
    if(isequal(strtrim(newLineString),"INIT"))
        break;
    end
end

while(~FS.Stop())
    newLineString = readline(device);
    if(not(isequal(strtrim(newLineString),"INIT")))
        if(printReads)
            disp(newLineString);
        end

        newStr = split(newLineString,', ');
        for j=1:length(newStr)
            numValue = str2double(strtrim(newStr(j)));
            if isnan(numValue)
               error = true; 
            end
            data(rowNum,j) = numValue;
        end
        if error
            disp(strcat('Expected numeric value, but read the following value: ',strtrim(newStr(j))));
            break;
        end
        %string=[string, newline, newLineString];
        rowNum = rowNum+1;
    end
end

FS.Clear() ;
clear FS ;
clear device;
end