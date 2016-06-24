#! /Library/Frameworks/Python.framework/Versions/2.7/bin/python
import serial, io, time, sys
import Tkinter

print("Start")

ser = None
while ser == None:
    try:
        ser = serial.Serial('/dev/cu.usbmodem1411', timeout=1)
    except:
        time.sleep(1)

print("Connection established")
# root = Tkinter.Tk()
#
# class MyApp(Tkinter.Frame):
#     def __init__(self, master):
#         Tkinter.Frame.__init__(self, master, padx=10, pady=10)
#         master.title("Sample Application")
#         master.minsize(width=250, height=100)
#
#         self.pack()
#         self.value_str = Tkinter.StringVar()
#         self.value_str.set("0")
#         self.valueLabel = Tkinter.Label(self, textvariable=self.value_str)
#         self.valueLabel.pack()

def read():
    # sio = io.TextIOWrapper(io.BufferedRWPair(ser, ser))
    #
    # sio.write(unicode("End of data\n"))
    # sio.flush()
    # data = [datum.split(':') for datum in sio.readline(1000).split('\n')]
    # data = (('temperature', 40.0),)
    # data = sio.readline()
    # d = sio.readline()
    # print(data, d)
    # global app

    while True:
        datum = None
        datum = ser.readline(100).strip('\n')
        if datum != None:
            # app.value_str.set(datum)
            # root.update()
            print('\r' + datum),
            sys.stdout.flush()

# app = MyApp(root)
print("0"),
sys.stdout.flush()
read()
