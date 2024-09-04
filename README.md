# Pololu Motor Controllers
## Project Objective:

The goal of this project is to design modern control schemes for a DC motor control system using the state-feedback technique. Specifically, this involves utilizing the kit provided during the lecture to design, implement, and test at least one Linear Quadratic Regulator (LQR) controller. 
Additionally, the project aims to develop a second controller (a torque controller) capable of ensuring that the electric motor delivers the desired torque.

The development process will follow the V-model methodology, and a detailed description of the design, implementation, and testing of these controllers is provided in the attached report ("report.pdf").
## SETUP
The kit provided consists of:
 • STM32F401RE Nucleo-board: a high-performance programmable board based on ARM Cortex-M4
 microcontroller whose clock reaches 84 MHz. The board is equipped with a USB interface, via Universal
 Synchronous-Asynchronous Receiver Transmitter (USART), for communication with the PC and an
 ST-Link debug interface, 11 hardware timers that can be configured as PWM generators or time
 counters.
 • Pololu 37D Gearmotor: it consists of a high power, 12 V brushed DC motor. It is equipped with a
 non-separable gearbox that translates a complete inner revolution to a fraction 1
 131.25 of a complete
 outer revolution. Thus, the gear ratio is 131.25 : 1. The motor also provides a Hall effect quadrature
 encoder to sense rotation of the motor shaft. It generates 64 Counts Per Inner Revolution (CPR),
 thus generating 131.24 ∗ 64 = 8400 Counts Per outer Revolution.
 • STM X-Nucleo-IHM04A1 driver: this module is a dual brush DC motor drive expansion board. It
 allows to drive up to two bipolar motors (A and B). The driver implements an H-Bridge to set the
 rotation direction of the motor.
 • Kit wiring: allows us to provide the desired power supply to the motor, the maximum power supply
 is 12V.
 • Pololu Wheel Kit: it consists of a wheel, an aluminum hub and an L-bracket Pair that can be used to
 mount the motor to the chassis.
 • Current sensor ACS714: it is a Hall effect-based linear current sensor that can be used to measure the
 current flowing through the motor.
 ![image](https://github.com/user-attachments/assets/f965d611-9de3-414a-be8f-11bec885afba)

