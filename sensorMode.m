function brickObj = lightConnectEV3(brickConnectionType, sensorMode)
% brickObj = lightConnectEV3('usb','ambient')
% brickObj = lightConnectEV3('bluetooth','reflect')

    % 1) connect
    brickObj = legoev3(brickConnectionType);

    % 2) set sensor mode (sensor is on port 1 in this Versuch)
    if strcmp(sensorMode, 'ambient')
        brickObj.sensor1.mode = DeviceMode.Color.Ambient;
    elseif strcmp(sensorMode, 'reflect')
        brickObj.sensor1.mode = DeviceMode.Color.Reflect;
    else
        error("sensorMode must be 'ambient' or 'reflect'.");
    end
end
