% [pub, msg] = rospublisher('/coros_cal', 'coros_msgs/cmdpacket');

%%
for i=1:1
    %---------
    msg.Cmdstr = 'map2d';
    msg.Cmdcode = hex2dec('20');
    msg.Cmdoption(1:4) = [2,3,2,3]'-1;
    rawdata = single(rand(2,2)*100);
    msg.Data = getuint8(rawdata);
    disp(rawdata);
    disp(msg.Data');
       
    pub.send(msg);
    pause(0.5);
    
    %---------
    msg.Cmdstr = 'c1';
    msg.Cmdcode = hex2dec('20');
    msg.Cmdoption(1:4) = [0,0,0,0]';
    msg.Data = getuint8(single(3.1415));
    disp(msg.Data');
       
    pub.send(msg);
    pause(0.5);
end

%%
CALIDX = 0;
msg.Cmdstr = '';
msg.Cmdcode = hex2dec('1000');
msg.Cmdoption(1) = CALIDX;
disp(msg);
pub.send(msg);