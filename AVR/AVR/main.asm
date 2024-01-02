    .include "m328pdef.inc"
    .include "delayMacro.inc"
    .include "UART.inc"

    ;Declaring Names for Easy Using of Components
    .equ RX = PD0              ;Digital 0
    .equ TX = PD1              ;Digital 1
    .equ IR1 = PD2	        ;Digital 2     ;Parking Slot 1 Sensor
    .equ IR2 = PD3	        ;Digital 3     ;Parking Slot 2 Sensor
    .equ GATEIR = PD4         ;Digital 4     ;Gate Sensor
    .equ RedLight = PD6         ;Digital 6     ;Parking Slot 1 Red LED
    .equ YellowLight = PD7         ;Digital 7     ;Parking Slot 1 Green LED
    .equ GreenLight = PB0         ;Digital 8     ;Parking Slot 2 Red LED
    .equ RGate = PB2          ;Digital 10    ;Gate Red LED
    .equ YGate = PB3          ;Digital 11    ;Gate Yellow LED
    .equ GGate = PB4          ;Digital 12    ;Gate Green LED 
    .equ Buzzer = PB5         ;Digital 13    ;Gate Alarm Buzzer
    .def traffictimer_first = r18
    .def traffictimer_second = r19
    .def traffictimer_third = r20
    .def trafficcycle = r21
    .def carEntry_checked = r22
    .def slot1_current_state = r23
    .def slot2_current_state = r24
    .def slot1_previous_state = r25
    .def slot2_previous_state = r26

    .cseg
    .org 0x00
        Serial_begin
        ; Setting Up Sensor Pins for Input
                CBI DDRD, IR1
                CBI DDRD, IR2
                CBI DDRD, GATEIR
                CBI DDRB, RX

        ;SettingUp Buzzer and Light Pins for Output 
                SBI DDRD, RedLight
                SBI DDRD, YellowLight
                SBI DDRB, GreenLight
                SBI DDRB, RGate
                SBI DDRB, YGate
                SBI DDRB, GGate
                SBI DDRB, Buzzer
                SBI DDRB, TX
        ; Setting Up Send Strings
        
        ;Resetting all Sensors and LEDs to default settings
                SBI PORTD, RedLight
                CBI PORTD, YellowLight
                CBI PORTB, GreenLight
                CBI PORTB, RGate
                CBI PORTB, YGate
                SBI PORTB, GGate
                CBI PORTB, Buzzer
                LDI traffictimer_first, 0x00
                LDI traffictimer_second, 0x00
                LDI traffictimer_third, 0x00
                LDI trafficcycle, 0x00
                LDI carEntry_checked, 0x00
                LDI slot1_current_state, 0x00
                LDI slot2_current_state, 0x00
                LDI slot1_previous_state, 0x00
                LDI slot2_previous_state, 0x00
                
        MainLoop:
            INC traffictimer_first                  ;i++

        ; Check if (trafficcycle == 0 or trafficcycle == 2)
        CPI trafficcycle, 0x00
        BREQ Timer_Long
        CPI trafficcycle, 0x02
        BREQ Timer_Long

        ; Check first timer
        CPI traffictimer_first, 0xAA
        BREQ Short_Timer_Two
        RJMP Skip_TrafficLightChange

        Short_Timer_Two:
        INC traffictimer_second
        CPI traffictimer_second, 0x08
        BREQ Short_Timer_Three
        RJMP Skip_TrafficLightChange

        Short_Timer_Three:
        INC traffictimer_third
        CPI traffictimer_third, 0x08
        BREQ ChangeTrafficLight
        RJMP Skip_TrafficLightChange

        Timer_Long:
        ; Check first timer
        CPI traffictimer_first, 0xAA
        BREQ Timer_Two
        RJMP Skip_TrafficLightChange

        ; Check second timer
        Timer_Two:
        INC traffictimer_second
        CPI traffictimer_second, 0xAA
        BREQ Timer_Third
        RJMP Skip_TrafficLightChange

        Timer_Third:
        INC traffictimer_third
        CPI traffictimer_third, 0xAA
        BREQ ChangeTrafficLight
        RJMP Skip_TrafficLightChange

    ChangeTrafficLight:
        LDI traffictimer_first, 0x00
        LDI traffictimer_second, 0x00
        LDI traffictimer_third, 0x00

        ; Check if (trafficcycle == 0)
        CPI trafficcycle, 0x00
        BREQ Change_Red_to_Yellow

        ; Check if (trafficcycle == 1)
        CPI trafficcycle, 0x01
        BREQ Change_Yellow_to_Green

        ; Check if (trafficcycle == 2)
        CPI trafficcycle, 0x02
        BREQ Change_Green_to_Yellow

        ; Check if (trafficcycle == 3)
        CPI trafficcycle, 0x03
        BREQ Change_Yellow_to_Red
        RJMP Skip_TrafficLightChange

    Change_Red_to_Yellow:
        CBI PORTD, RedLight
        SBI PORTD, YellowLight
        CBI PORTB, GreenLight
        LDI trafficcycle, 0x01
        RJMP Skip_TrafficLightChange

    Change_Yellow_to_Green:
        CBI PORTD, RGate
        SBI PORTD, GGate
        CBI PORTD, RedLight
        CBI PORTD, YellowLight
        SBI PORTB, GreenLight
        LDI trafficcycle, 0x02
        RJMP Skip_TrafficLightChange

    Change_Green_to_Yellow:
        SBI PORTD, RGate
        CBI PORTD, GGate
        CBI PORTD, RedLight
        SBI PORTD, YellowLight
        CBI PORTB, GreenLight
        LDI trafficcycle, 0x03
        RJMP Skip_TrafficLightChange

    Change_Yellow_to_Red:
        SBI PORTD, RedLight
        CBI PORTD, YellowLight
        CBI PORTB, GreenLight
        LDI trafficcycle, 0x00


        Skip_TrafficLightChange:

        ;Check if Parking Slot1 is Full or Empty
                    SBIS PIND, IR1
                    RJMP Slot1_Full
                    LDI slot1_current_state, 0x00
                    CP slot1_current_state, slot1_previous_state
                    BREQ Slot1_Free
                    Serial_writeChar 'A'
                    delay 10
                    LDI slot1_previous_state, 0x00
                    RJMP Slot1_Free
            ;If Slot1 was Full
                Slot1_Full:
                    LDI slot1_current_state, 0x01
                    CP slot1_current_state, slot1_previous_state
                    BREQ Slot1_Free
                    Serial_writeChar 'B' 
                    delay 10
                    LDI slot1_previous_state, 0x01
                
                Slot1_Free:

            ;Check if Parking Slot2 is Full or Empty
                    SBIS PIND, IR2
                    RJMP Slot2_Full
                    LDI slot2_current_state, 0x00
                    CP slot2_current_state, slot2_previous_state
                    BREQ Slot2_Free
                    Serial_writeChar 'C'
                    delay 10
                    LDI slot2_previous_state, 0x00
                    RJMP Slot2_Free
            
            ;If (Slot2 was Full)
                Slot2_Full:
                    LDI slot2_current_state, 0x01
                    CP slot2_current_state, slot2_previous_state
                    BREQ Slot2_Free
                    Serial_writeChar 'D'
                    delay 10
                    LDI slot2_previous_state, 0x01
            ;else
                Slot2_Free:
                
                ;Check Parking Slots
                ; Check if (Parking Slot 1 is Occupied)
                SBIS PIND, IR1
                RJMP Check_Parking_Slot_2_1
                RJMP Turn_Off_Red_Light

            Check_Parking_Slot_2_1:
                ; Check if (Parking Slot 2 is Occupied)
                SBIS PIND, IR2
                RJMP Turn_On_Red_Light
                RJMP Turn_Off_Red_Light
        
            Turn_On_Red_Light:
                SBI PORTD, RGate
                CBI PORTD, GGate
                RJMP CheckGate
            
            Turn_Off_Red_Light:
                CBI PORTD, RGate
                SBI PORTD, GGate
                RJMP CheckGate

    CheckGate:
        ; Check if (Car is at Gate)
        SBIS PIND, GATEIR
        RJMP Check_TrafficLight
        LDI carEntry_checked ,0x00
        RJMP Car_Not_at_Gate

        
    Check_TrafficLight:
        ; Check if (Traffic Light is Green)
        SBIC PORTB, GreenLight
        RJMP Check_Parking_Slots
        RJMP Alarm_Buzzer

    Check_Parking_Slots:
        ; Check if (Parking Slot 1 is Occupied)
        SBIS PIND, IR1
        RJMP Check_Parking_Slot_2
        RJMP YellowLight_Blink

    Check_Parking_Slot_2:
        ; Check if (Parking Slot 2 is Occupied)
        SBIS PIND, IR2
        RJMP Alarm_Buzzer
        RJMP YellowLight_Blink

    YellowLight_Blink:
        SBI PORTB, YGate
        delay 70
        CBI PORTB, YGate
        CPI carEntry_checked, 0x00
        BREQ sendEntry
        RJMP MainLoop

    sendEntry:
        Serial_writeChar 'E'
        delay 10
        LDI carEntry_checked, 0x01 
        RJMP MainLoop

    Alarm_Buzzer:

        SBI PORTB, RGate
        SBI PORTB, Buzzer
        delay 100
        CBI PORTB, RGate
        CBI PORTB, Buzzer
        delay 100

    Car_Not_at_Gate:
        RJMP MainLoop