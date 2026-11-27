import RPi.GPIO as GPIO  
from time import sleep  
import spidev  

MyARM_ResetPin = 19  # Pin 4 of the connector = BCM19 = GPIO[1]

# Initialize the SPI device for communication with the FPGA
MySPI_FPGA = spidev.SpiDev()  
MySPI_FPGA.open(0, 0)  # Open SPI bus 
MySPI_FPGA.max_speed_hz = 500000  # Set SPI communication speed 

# Configure GPIO settings
GPIO.setmode(GPIO.BCM) 
GPIO.setwarnings(False)  
GPIO.setup(MyARM_ResetPin, GPIO.OUT)  

# Reset the FPGA
GPIO.output(MyARM_ResetPin, GPIO.HIGH) 
sleep(0.1)  
GPIO.output(MyARM_ResetPin, GPIO.LOW)  
sleep(0.1) 

# Send the first SPI packet: Writing coord_syst and mode at address 0x400
ToSPI = [0x80, 0x01, 0x00, 0x00, 0x00]  # YOU NEED TO MODIFY THIS LINE
FromSPI = MySPI_FPGA.xfer2(ToSPI) 
sleep(0.1)  

# Send the second SPI packet: Writing x_in (K) at address 0x404
ToSPI = [0x81, 0x26, 0xDD, 0x3B, 0x6A]  # YOU NEED TO MODIFY THIS LINE 
FromSPI = MySPI_FPGA.xfer2(ToSPI)  
sleep(0.1)  

# Send the third SPI packet: Writing y_in (0) at address 0x408
ToSPI = [0x82, 0x00, 0x00, 0x00, 0x00]
FromSPI = MySPI_FPGA.xfer2(ToSPI)
sleep(0.1)

# Send the third SPI packet: Writing z_in (30° in radian in q1.30) at address 0x408
ToSPI = [0x83, 0x21, 0x82, 0xA4, 0x70]
FromSPI = MySPI_FPGA.xfer2(ToSPI)
sleep(0.1)


GPIO.output(MyARM_ResetPin, GPIO.HIGH)  
sleep(0.1)  
GPIO.output(MyARM_ResetPin, GPIO.LOW)  


# Send SPI packet to request the cos(30°) (x_out) at address 0x410
ToSPI = [0x04, 0x00, 0x00, 0x00, 0x00]  # YOU NEED TO MODIFY THIS LINE
FromSPI = MySPI_FPGA.xfer2(ToSPI)  
print("Received cos(30°) : ", FromSPI)  # Print the cos(30°)

# Send SPI packet to request the sin(30°) (y_out) at address 0x414
ToSPI = [0x05, 0x00, 0x00, 0x00, 0x00]  # YOU NEED TO MODIFY THIS LINE
FromSPI = MySPI_FPGA.xfer2(ToSPI)  
print("Received sin(30°) : ", FromSPI)  # Print the sin(30°)

# Final reset sequence for the FPGA
GPIO.output(MyARM_ResetPin, GPIO.HIGH) 
sleep(0.1)  
GPIO.output(MyARM_ResetPin, GPIO.LOW)
