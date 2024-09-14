#include <avr/interrupt.h>
#include <avr/io.h>
#include <avr/sleep.h>
#include <avr/wdt.h>
#include <stdbool.h>
#include <stdint.h>
#include <util/delay.h>

volatile bool wake_up = false;
volatile uint16_t sleep_cycles = 0;
const uint16_t target_cycles = (15 * 60) / 8; // 15min divided by 8sec from the WDT

// Setup watchdog timer
void setup_wdt()
{
    cli();  // Disable interrupts
    wdt_reset();

    WDTCSR |= (1 << WDCE) | (1 << WDE);   // Enable configuration mode
    WDTCSR = (1 << WDIE) | (1 << WDP3) | (1 << WDP0);  // Enable Interrupt mode, Set prescaler to 8 seconds

    sei();  // Enable interrupts
}

// Interrupt Service Routine
ISR(WDT_vect)
{
    sleep_cycles++;

    if (sleep_cycles >= target_cycles)
    {
        wake_up = true;
        sleep_cycles = 0;
    }
}

void setup_sleep()
{
    set_sleep_mode(SLEEP_MODE_PWR_DOWN);
}

void sleep()
{
    sleep_enable();
    sleep_mode();  // Enter sleep mode, wakes up after interrupt
    sleep_disable();
}

int main(void)
{
    DDRB |= (1 << PB5);

    setup_sleep();
    setup_wdt();

    while (1)
    {
        if (wake_up)
        {
            PORTB ^= (1 << PB5);
            wake_up = false;
            continue;
        }
        
        sleep();
    }
}
