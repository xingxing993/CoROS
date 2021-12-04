function test_subCallback(src,msg)
disp(msg);
fprintf('Respcode: %u | Respstr %s\n', msg.Respcode, msg.Respstr);
fprintf('Data: [')
fprintf('%.1f ', bytearray2data(msg.Data, 7)); %7: single
fprintf(']\n');