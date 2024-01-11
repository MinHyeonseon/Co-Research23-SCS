from djitellopy import tello
from time import sleep
import yolo
import cv2
import move


me = tello.Tello()
me.connect()
print(me.get_battery())

me.streamon()
me.takeoff()
me.send_rc_control(0, 0, 0, 0)

while True:
    img = me.get_frame_read().frame
    img = cv2.resize(img, (360, 240))

    img_return, outs = yolo.Detecting_objects(img)
    x, w, y, h = yolo.get_objects(img_return, outs)
    up_down, front_back, yaw = move.checking_box(x, w, y)
    me.send_rc_control(0, front_back, up_down, yaw)
    if(up_down != 0 or front_back != 0 or yaw != 0):
        sleep(0.4)
    cv2.imshow("image",img)
    cv2.waitKey(1)