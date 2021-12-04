classdef CAR
    properties(Constant)
        %unit: mm
        Length = single(4547)
        Width = single(1906)
        HalfWidth = CAR.Width/2;
        WidthMirror = single(2185)
        AxisLen = single(2730)
        FrontOH = single(929)
        RearOH = single(888)
        MaxPulse = uint8(255)
        MaxFrontWheelAngle = single(30)
        MaxSteerWheelAngle = single(512)
        MinRearAxisTurnRadius = single(5900)
    end
end