classdef CoROSSignal < handle


    % Basic properties
    properties
        Index = -1 %new index after rebuild
        
        RawID % -1 to indicate the object is a time signal
        Name
        DataType % note that boolean should be converted to uint8
        DataTypeId % index of datatype used for bytearray2data
        VarByteOffset % byte offset in signal RawID, zero based
        ByteLength
        
    end


    
    properties
        % Properties for DAQ message assignment
        DAQMsgIndex = -1 % -1 means not assigned yet, one based
        MsgByteOffset = -1 % -1 means not assigned yet, zero based

        % Properties related to APP UITable
        DAQOn % whether DAQ status set on
        Active % whether signal is currently displayed in table
        Value % current signal value

        % Properties for DAQ data recording
        IsRecording = false % boolean, if the signal is being recorded
        RecordingStartTime
        RecordingStopTime
        Buffer % Data buffer before write to disk
        BufferCount = 0;% Pointer indicating current buffer position
        FID = -1; % Temp storage File ID
        TempDirectory % Directory of temp storage
        TempFileName % Temp file name for buffer
        TimeStampSignal % a special CoROSSignal object thant stores time stamp
    end
    properties (Constant=true)
        BUFFERSIZE = 1000;
    end
    
    % Single object methods
    % The following methods typically applies to object array
    methods
        function obj = CoROSSignal(varargin)
            for i=1:2:numel(varargin)
                obj.(varargin{i}) = varargin{i+1};
            end
        end
        

        function set.Value(obj, value)
            obj.Value = value;
            if obj.IsRecording
                obj.AppendValue(value);
            end
        end

        function startRecording(obj)
            obj.IsRecording = true;
            if isempty(obj.Buffer)
                obj.Buffer = zeros(1, obj.BUFFERSIZE, obj.DataType);
                obj.BufferCount = 0;
            end
            obj.TempFileName = [getvalidname(obj.Name), '_', int2str(obj.Index)];
            obj.FID = fopen(fullfile(obj.TempDirectory, obj.TempFileName), 'w+');
        end

        function stopRecording(obj)
            obj.IsRecording = false;
%             if ~isempty(obj.FID)
            % finalize temp buffer data file and rewind for merging
            fwrite(obj.FID, obj.Buffer(1:obj.BufferCount), obj.DataType);
%             end
            obj.BufferCount = 0;
            obj.Buffer=[]; %clear data buffer
            fclose(obj.FID);
            %
        end

        function AppendValue(obj, value)
            if obj.BufferCount >= obj.BUFFERSIZE % if buffer full
                % first write to disk and clear buffercount
                fwrite(obj.FID, obj.Buffer, obj.DataType);
                obj.BufferCount = 0;
            end
            obj.BufferCount = obj.BufferCount + 1;
            obj.Buffer(obj.BufferCount) = value;
        end
        
                
        function sigbuf = readBuffer(obj)
            if ~isempty(obj.TempDirectory) && ~isempty(obj.TempFileName)
                obj.FID = fopen(fullfile(obj.TempDirectory, obj.TempFileName), 'r');
                sigbuf = fread(obj.FID, obj.DataType);
                fclose(obj.FID);
            else
                sigbuf = [];
            end
        end
    end

    % Array methods
    % The following methods typically applies to object array
    methods        
        function msgcfgs = stuffMessages(objs,MSGLEN)
            if nargin<2
                MSGLEN = 128; % default 128 bytes, same as Simulink ROS default
            end
            
            bytelens = [objs.ByteLength];
            i1 = 1; %first signal index in message
            msgidx = 1;
            msgcfgs = [];
            while true
                irel = find(cumsum(bytelens(i1:end))>MSGLEN, 1, 'first'); %last relative index in this message
                thismsg.Index = msgidx;
                thismsg.TimeStampSignal = CoROSSignal(...
                                'Index', msgidx, ... % Index of time signal is defined as its message index
                                'RawID', -1, ... % -1 is specific for time signals
                                'Name', ['Time_', int2str(msgidx)], ...
                                'DataType', 'double', ...
                                'DataTypeId', 8, ...
                                'VarByteOffset', [], ... 
                                'ByteLength', 8, ...
                                'DAQMsgIndex', msgidx, ...
                                'MsgByteOffset', -1); % -1 means invalid
                if ~isempty(irel)
                    i_msgseg = i1:(i1+irel-2); %segment index of signals stuffed in current message
                    [objs(i_msgseg).DAQMsgIndex] = deal(msgidx);
                    offset_in_msg = num2cell(cumsum(bytelens(i_msgseg))-bytelens(i_msgseg));
                    [objs(i_msgseg).MsgByteOffset] = deal(offset_in_msg{:});
                    thismsg.Signals = objs(i_msgseg)';
                    [thismsg.Signals.TimeStampSignal] = deal(thismsg.TimeStampSignal);
                    msgcfgs = [msgcfgs; thismsg];
                    %move on to next message
                    msgidx = msgidx+1;
                    i1 = i1+irel-1;
                else
                    [objs(i1:end).DAQMsgIndex] = deal(msgidx);
                    offset_in_msg = num2cell(cumsum(bytelens(i1:end))-bytelens(i1:end));
                    [objs(i1:end).MsgByteOffset] = deal(offset_in_msg{:});
                    thismsg.Signals = objs(i1:end)';
                    [thismsg.Signals.TimeStampSignal] = deal(thismsg.TimeStampSignal);
                    msgcfgs = [msgcfgs; thismsg];
                    break;
                end
            end
            info.num_total_daq_sigs = numel(objs);
            info.num_daq_msgs = numel(msgcfgs);
            info.num_sig_in_daqmsg = arrayfun(@(msg) numel(msg.Signals), msgcfgs);
        end
        
        
        function subsigobjs = getDAQOn(objs)
            subsigobjs = objs([objs.DAQOn]');
        end

        function startGroupRecording(objs)
            bufdir = fullfile(pwd,'_coros_tmpdatabuf');
            if ~exist(bufdir, 'dir')
                mkdir(bufdir);
            end
            [objs.TempDirectory] = deal(bufdir);
            [objs.RecordingStartTime] = deal(now); %start time
            for i=1:numel(objs)
                objs(i).startRecording;
            end
        end

        function stopGroupRecording(objs, usreventlog)
            if nargin<2
                usreventlog = [];
            end
            [objs.RecordingStopTime] = deal(now); %stop time
            for i=1:numel(objs)
                objs(i).stopRecording; % the signal buffer should be finalized and rewind to head now
            end
            % ------ align time sampling to one time array ----------
            timesigs = objs([objs.RawID]==-1); % RawID==-1 is time signal
            timearrays(1:numel(timesigs)) = struct('DAQMsgIndex', [], 'TimeData', []); %initialize
            for i=1:numel(timesigs)
                timearrays(i).DAQMsgIndex = timesigs(i).DAQMsgIndex;
                timearrays(i).TimeData = timesigs(i).readBuffer;
            end
            trefsigobj = timesigs(1);
            tref = timearrays(1).TimeData; % Suppose no big communciation lag, any of time signals can be used as reference, just use the 1st message time to align
            % re-index as container to store data indexes after align with reference time array
            timearrays(1).ReIndex = 1:numel(tref);
            for i=2:numel(timearrays)
                timearrays(i).ReIndex = interp1(timearrays(i).TimeData, 1:numel(timearrays(i).TimeData), tref, 'nearest', 'extrap');
            end
            sigobjs = [trefsigobj; objs([objs.RawID]>0)]; % construct signal objects to be written (all signals plus one time channel)
            % merge and save to file accordingly
            [filename, pathname, filterindex] = uiputfile( ...
                {'*.mdf;*.dat', 'MDF Format Files (*.mdf, *.dat)';
                '*.mat','MAT-files (*.mat)';}, ...
                'Save as');
            if ~(isequal(filename,0) || isequal(pathname,0))
                if filterindex==1
                    sigobjs.saveToMDFFile(timearrays, usreventlog, fullfile(pathname, filename));
                elseif filterindex==2
                    sigobjs.saveToMatFile(timearrays, usreventlog, fullfile(pathname, filename));
                else
                end
            end
            % delete temporary directory
            for i=1:numel(objs)
                try
                    fclose(objs(i).FID);
                end
            end
            if exist(objs(1).TempDirectory, 'dir')
                rmdir(objs(1).TempDirectory, 's');
            end
        end


        function saveToMatFile(objs, timearrays, filename)
            if nargin<3
                filename = sprintf('logfile_%s.mat', datestr(now, 30));
            end
            m = matfile(filename,'Writable',true);
            for i=1:numel(objs)
                if objs(i).RawID > 0 % if not a time signal
                    sigbuf = objs(i).readBuffer;
                    bidx_msg = [timearrays.DAQMsgIndex]==objs(i).DAQMsgIndex;
                    vals = sigbuf(timearrays(bidx_msg).ReIndex); % reindex to align with reference time array
                    matvar.Name = objs(i).Name;
                    matvar.Value = vals;
                    m.(getvalidname(matvar.Name)) = matvar;
                else
                    matvar.Name = 'time';
                    matvar.Value = timearrays(1).TimeData;
                    m.time = matvar;
                end
            end
        end


        function saveToMDFFile(objs, timearrays, usreventdata, filename)
            if nargin<4
                filename = sprintf('logfile_%s.dat', datestr(now, 30));
            end
            if nargin<3
                usreventdata = [];
            end
            % input "objs" should be object array that contains exactly one time signal object (RawID==-1) at element 1
            fid = fopen(filename,'W');
            numChannels = numel(objs); % RawID>0 to filter variable signal (time signal RawID==-1)
            isTimeChannel = ([objs.RawID] == -1);
            numSamples = numel(timearrays(1).TimeData);
            varLens = [objs.ByteLength];
            varTypes = {objs.DataType};
            varNames = getValidVariableNames({objs.Name});
            rateSample = 0;
            datamat_towrite = zeros(numel(timearrays(1).TimeData), numel(objs));
            datamat_towrite(:,1) = timearrays(1).TimeData';
            % fill in signal data other than time
            for i=2:numel(objs)
                sigbuf = objs(i).readBuffer;
                bidx_msg = [timearrays.DAQMsgIndex]==objs(i).DAQMsgIndex;
                vals = sigbuf(timearrays(bidx_msg).ReIndex); % reindex to align with reference time array
                datamat_towrite(:,i) = vals;
            end

            % Basic pointer definition
            p_ID = 0;
            p_HD = 64; % sizeof(IDBLOCK) = 64
            p_CC = 300; % 
            blocksize_cc = 63;
            pad_cc = 2;
            p_CN = p_CC + numChannels*(blocksize_cc+pad_cc);
            blocksize_cn = 228;
            pad_cn = 2;
            p_CG = p_CN + numChannels*(blocksize_cn+pad_cn);
            p_DG = p_CG + 50;
            if ~isempty(usreventdata)
                numChannels_Event = 2; % {'time', 'event'}
                numSamples_Event = size(usreventdata, 1);
                varLens_Event = 8+2; % double + uint16
                %use seperate channel group to store "User event logging signal"
                p_CC_Event = p_DG+50;
                p_CN_Event = p_CC_Event+(blocksize_cc+pad_cc)*numChannels_Event;
                p_CG_Event = p_CN_Event+(blocksize_cn+pad_cn)*numChannels_Event;
                p_DG_Event = p_CG_Event + 50;
                p_DR_Event = p_DG_Event + 50;
                lenEventDR = size(usreventdata, 1)*varLens_Event;
                pad_dr_event = 80; % pad to create space in case of unexpected out of bounds
                p_DR = p_DR_Event + lenEventDR + pad_dr_event;
            else
                p_DR = p_DG + 50;
            end

            % initialize to char(0) for ID, HD, DG, CG, CNs, CCs, and also Event DR as necessary
            fwrite(fid, repmat(char(0), 1, p_DR), 'char');

            % begin to write file
            writeIDBlock(fid, p_ID);
            if ~isempty(usreventdata)
                writeHDBlock(fid, p_HD, p_DG_Event, 2); % add another DG for User Event
                writeDGBlock(fid, p_DG_Event, p_DG, p_CG_Event, p_DR_Event); % in this condition, the first DG should be the User Event channels
                writeDGBlock(fid, p_DG, 0, p_CG, p_DR); % then link to the actual data group
                writeCGBlock(fid, p_CG_Event, p_CN_Event, numChannels_Event, numSamples_Event, varLens_Event);
                writeCGBlock(fid, p_CG, p_CN, numChannels, numSamples, sum(varLens));
                %Event: CG-->(CN-->CC)*2
                writeCCBlock(fid, p_CC_Event, '');
                p_nextCN = p_CN_Event+blocksize_cn+pad_cn;
                % write time channel
                writeCNBlock(fid, p_CN_Event, p_CC_Event, p_nextCN, ...
                    true, 'EventTime', 'double', 8, 0, ... % varlength:8, startbyte:0
                    0, false);
                % write event signal channel
                p_CN_Event = p_nextCN;
                p_CC_Event = p_CC_Event + (blocksize_cc+pad_cc);
                writeCCBlock(fid, p_CC_Event, '');
                writeCNBlock(fid, p_CN_Event, p_CC_Event, 0, ...
                    false, 'EventId', 'uint16', 2, 8, ... % varlength:2, startbyte:4
                    0, true);
                writeDRBlock(fid, p_DR_Event, usreventdata, {'double', 'uint16'});
            else
                writeHDBlock(fid, p_HD, p_DG_Event, 1);
                writeDGBlock(fid, p_DG, 0, p_CG, p_DR);
                writeCGBlock(fid, p_CG, p_CN, numChannels, numSamples, sum(varLens)); % this should be the last CG
            end

            startByte = 0;
            for index = 1 : numChannels
                writeCCBlock(fid, p_CC, ''); % set Units of all signals to empty #for now#
                p_nextCN = p_CN+blocksize_cn+pad_cn;
                writeCNBlock(fid, p_CN, p_CC, p_nextCN, ...
                    isTimeChannel(index), varNames{index}, varTypes{index}, varLens(index), startByte, ...
                    rateSample, index==numChannels);
                startByte = startByte + varLens(index);
                p_CC = p_CC+blocksize_cc+pad_cc;
                p_CN = p_CN+blocksize_cn+pad_cn;
            end
            
            writeDRBlock(fid, p_DR, datamat_towrite, varTypes);
            fclose(fid);
        end
    end
end


function validname = getvalidname(varname)
validname = regexprep(varname, '\[(\d+)\]', '_D$1'); % Convert array [N] to _DN style
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% MDF Write Utilities
function writeIDBlock(fid, offset)
    fseek(fid,offset,'bof');
    fwrite(fid, 'MDF     ', 'char'); % Fixed File identifier, 8 bytes
    fwrite(fid, '3.00    ', 'char'); % Format identifier, 8 bytes
    fwrite(fid, 'CoROS1.0', 'char'); % Program identifier, 8 bytes
    fwrite(fid, 0, 'uint16'); % Byte order: little endian
    fwrite(fid, 0, 'uint16'); % Floating-point format: IEEE 754
    fwrite(fid, 300, 'uint16'); % Version number 3.0.0
    fwrite(fid, 0, 'uint16'); % Reserved
    fwrite(fid, [0 0], 'char'); % Reserved
    fwrite(fid, repmat(char(0),1,30), 'char'); % Reserved
end


function writeHDBlock(fid, offset, p_DG, numDG)
    blocksize = 164;
    fseek(fid,offset,'bof');        % file pointer always to 64 for HD
    fwrite(fid,char('HD'),'char');
    fwrite(fid,blocksize,'uint16'); % Block size of this block in bytes
    fwrite(fid,p_DG,'uint32'); % Pointer to the first file group block (DGBLOCK) 
    fwrite(fid,0,'uint32');  % Pointer to the measurement file comment text (TXBLOCK), NIL #for now#
    fwrite(fid,0,'uint32');  % Pointer to program block (PRBLOCK), NIL #for now#
    fwrite(fid,numDG,'uint16');  % number of DG
    fwrite(fid,datestr(now,'dd:mm:yyyy'),'char');
    fwrite(fid,datestr(now,'HH:MM:SS'),'char');
    username = getenv('USERNAME');
    usrnamebuf = zeros(1,32, 'uint8'); 
    usrnamebuf(1:min(31,numel(username))) = username(1:min(31,end)); % Author’s name, char[32] string
    fwrite(fid, usrnamebuf, 'char');
    fwrite(fid, zeros(1,32,'uint8'),'char'); % Name of organization or department 
    strbuf32 = zeros(1,32,'uint8');
    prjname = 'CoROS@jiangxinauto@163.com';
    strbuf32(1:numel(prjname)) = prjname;
    fwrite(fid, strbuf32,'char'); % Project name 
    fwrite(fid, zeros(1,32,'uint8'),'char'); % Measurement object e. g. the vehicle identification
end


function writeDGBlock(fid, offset, p_nextDG, p_CG, p_DR)
    blocksize = 28;
    fseek(fid,offset,'bof');
    fwrite(fid,char('DG'),'2*char');
    fwrite(fid,blocksize,'uint16');
    fwrite(fid,p_nextDG,'uint32');     % Pointer to next data group block (DGBLOCK)
    fwrite(fid,p_CG,'uint32');  % Pointer to next channel group block (CGBLOCK) 
    fwrite(fid,0,'uint32');     % Reserved
    fwrite(fid,p_DR,'uint32');  % Pointer to the data records
    fwrite(fid,1,'uint16');     % Number of channel groups (CGs)
    fwrite(fid,0,'uint16');     % data records without record ID
    fwrite(fid,0,'uint32');     % reserved
end


function writeCGBlock(fid, offset, p_CN, numChannels, numSamples, recordSize)
    blocksize = 26;
    fseek(fid,offset,'bof');
    fwrite(fid,char('CG'),'2*char');
    fwrite(fid,blocksize,'uint16');
    fwrite(fid,0,'uint32');        % pointer to next CG, only one DAQ time, and sorted storage
    fwrite(fid,p_CN,'uint32');     % pointer to next CN block
    fwrite(fid,0,'uint32');        % pointer to next TX block, NIL #for now#
    fwrite(fid,2,'uint16');        % recordID
    fwrite(fid,uint16(numChannels),'uint16');      % number of channels
    fwrite(fid,uint16(recordSize),'uint16');       % record size in bytes
    fwrite(fid,uint32(numSamples),'uint32');       % number of samples
end

function writeCNBlock(fid, offset, p_CC, p_nextCN, isTimeChannel, signalName, signaltype, signalLen, start_byte, rateSample, lastVar)
    if lastVar
        p_nextCN = 0;
    end
    blocksize = 228;
    
    start_offset = start_byte * 8;
    if start_offset >  2^16-1
        error('Too many signals!');
    end
    
    fseek(fid,offset,'bof');
    fwrite(fid,'CN','char');
    fwrite(fid,blocksize,'uint16');    % block size
    fwrite(fid,p_nextCN,'uint32');     % pointer to nextCN
    fwrite(fid,p_CC,'uint32');         % pointer to  CC block
    fwrite(fid,0,'uint32');            % pointer to CE block, do not exist
    fwrite(fid,0,'uint32');            % pointer to CD block, do not exist
    fwrite(fid,0,'uint32');            % pointer to TX block, do not exist
    fwrite(fid,isTimeChannel,'uint16');        %channel type
    fwrite(fid,signalName(1:min(length(signalName),31)), 'char');
    fseek(fid,32-length(signalName),0);                % fill the rest 32bytes with null 
    description = 'no_description_at_all^~^';
    fwrite(fid,description,'char');
    fseek(fid,128-length(description),0);              % fill the rest 128bytes with null 
    fwrite(fid,start_offset,'uint16');                 % start offset
    fwrite(fid,signalLen*8,'uint16');                  % num of bits
    switch signaltype
        case {'uint32', 'uint16', 'uint8'}
            signaldt_im = 0;
        case {'int32', 'int16', 'int8'}
            signaldt_im = 1;
        case {'single'}
            signaldt_im = 2;
        case {'double'}
            signaldt_im = 3;
        otherwise
            error('only data type double/single/uint32/uint16/uint8/int32/int16/int8 are supported.');
    end
    fwrite(fid,signaldt_im,'uint16');
    fwrite(fid,0,'uint16');    % value range valid
    fwrite(fid,0,'double');    % min signal value
    fwrite(fid,0,'double');    % max signal value
    fwrite(fid,rateSample,'double');    % sampling rate
    fwrite(fid,0,'uint32');     % poitnter to TX block
    fwrite(fid,0,'uint32');     % poitnter to TX block
    fwrite(fid,0,'uint16');     % additional byte offset is not supported   
end


function writeCCBlock(fid, offset, units)
    % units modification - limit to 20 with trailing zeros
    units = units(1:min(19,length(units)));
    units = [units repmat(char(0),1,20-length(units))];
    
    blocksize = 62;
    
    fseek(fid,offset,'bof');
    fwrite(fid,'CC','char');
    fwrite(fid,blocksize,'uint16');    
    fwrite(fid,0,'uint16');            % value range valid
    fwrite(fid,0,'double');            % min signal value
    fwrite(fid,0,'double');            % max signal value
    fwrite(fid,units,'char');          % units of the signal
    fwrite(fid,0,'uint16');            % conversion type - linear
    fwrite(fid,2,'uint16');            % number of parameters
    fwrite(fid,0,'double');            % P1
    fwrite(fid,1,'double');            % P2
end


function writeDRBlock(fid, offset, DT, varTypes)
    fseek(fid,offset,'bof');
    [nr,nc] = size(DT);
    for row = 1:nr
        for col = 1:nc
            fwrite(fid,DT(row,col),varTypes{col});
        end
    end
end



function varnames = getValidVariableNames(varnames)
    % variable names should conform to 
    % 1 - no space allowed : replace with __
    % 2 - length should be less than 31 chars
    % 3 - unique name for each variables 
    
    % check if space exists in names
    varnames = strrep(varnames, ' ','_');
    
    % check more than 31 chars names
    flg_longnames = cellfun(@(x) length(x)>31, varnames);
    % then truncate in between; use rolling 31 chars that produce unique names
    if any(flg_longnames)
        newvarnames = varnames;
        longnames = varnames(flg_longnames);
        shift_idx=[0:1:14 -1:-1:-14];
        i=1;
        while ((length(unique(newvarnames)) ~= length(newvarnames) || i==1) && i<= length(shift_idx))
            idx = shift_idx(i);
            newlongnames = cellfun(@(x) [x(1:15-idx) '_' x(end-14-idx:end)], longnames, 'UniformOutput', false);
            newvarnames(flg_longnames) = newlongnames;
            i=i+1;
        end
        if (length(unique(newvarnames)) ~= length(newvarnames) && i > length(shift_idx))
            error('Try to minimize the signal names to less than 31 chars');
        else
            varnames = newvarnames;
        end    
    end
end
