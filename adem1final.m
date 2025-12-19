function moveXundY(dist1,dist2)

mX.resetTachoCount();
mY.resetTachoCount();

 mX.speed = sign(dist1)*15;
 mY.speed = sign(dist2)*15;

    mX.start(); 
    mY.start();

while (abs(mX.tachoCount) < abs(dist1)) || (abs(mY.tachoCount) < abs(dist2))
        
     
        if abs(mX.tachoCount) >= abs(dist1)
            mX.stop();
        end
        
      
        if abs(mY.tachoCount) >= abs(dist2)
            mY.stop();
        end
        
        pause(0.01);
    end

    mX.stop();
    mY.stop();
    
    pause(0.15);

end

moveY(h);
moveY(-h);
moveX(2*w/2);
moveY(h/2);
moveX(-2*w/3);
moveXundY(2*w/3,h/2);
penUp();
%mZ.power = 75;
%mZ.start();
%pause(0.2);
%mZ.stop();
moveXundY(-2*w/3,-h/2);
moveX(2*w/3);
moveY(-h/2);

moveX(w/2);

penDown();
%mZ.power = -50;
%mZ.start();
%pause(0.2);
%mZ.stop();

moveXundY(w/4,h);
moveXundY(w/4,-h/3);
moveXundY(w/4,h/3);
moveXundY(w/4,-h);

penUp();
%mZ.power = 75;
%mZ.start();
%pause(0.2);
%mZ.stop();

moveX(w/2);


penDown();
%mZ.power = -50;
%mZ.start();
%pause(0.2);
%mZ.stop();

moveX(w);
moveX(-w/2);
moveY(h);

penUp();
%mZ.power = 75;
%mZ.start();
%pause(0.2);
%mZ.stop();

moveY(-h);
moveX(w/2);

moveX(w);

penDown();
%mZ.power = -50;
%mZ.start();
%pause(0.2);
%mZ.stop();

moveY(h);
moveY(-h/2);
moveX(w/2);
moveY(-h/2);
moveY(h);

function penUp()
mZ.resetTachoCount();
mZ.power = 75;
mZ.start();
pause(0.2);
mZ.stop();
end

function penDown()

mZ.resetTachoCount();
mZ.power = -50;
mZ.start();
pause(0.2);
mZ.stop();
end
