function moveXundY(dist1,dist2)

mX.resetTachoCount();
mY.resetTachoCount();

 mX.speed = sign(dist)*15;
 mY.speed = sign(dist)*15;

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
