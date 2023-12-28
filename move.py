def checking_box(x, w, y):
    if(w != 0) :
        if(x+w/2 < 90):
            yaw = -20
        elif(x+w/2 > 270):
            yaw = 20
        else:
            yaw = 0
        if(y < 60):
            up_down = 15
        elif(y > 180):
            up_down = -15
        else:
            up_down = 0
        if(w > 180):
            front_back = -15
        elif(w < 140):
            front_back = 15
        else:
            front_back = 0

    else:
        return 0, 0, 0

    return up_down, front_back, yaw