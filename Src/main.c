/**
  ******************************************************************************
  * File Name          : main.c
  * Description        : A simple blinky program using cmsis header files
  ******************************************************************************
*/

#include <stdint.h>
#include "main.h"


static void wait(long unsigned int cycles){
    for(long unsigned int i = 0; i < cycles; i++){
        __asm__("nop");
    }
}

int main(void)
{ 
    // Setup clock to enable GPIOA
    RCC->AHB1ENR |= RCC_AHB1ENR_GPIOAEN;

    //Configure GPIOA pin 5 as output
    GPIOA->MODER &= ~GPIO_MODER_MODER5_Msk;
    GPIOA->MODER |= GPIO_MODER_MODER5_0;
    
    /* Loop forever */
	while(1){
        // Turn LED ON
        GPIOA->ODR |= GPIO_ODR_OD5;
        wait(16000000 / 16);

        GPIOA->ODR &= ~GPIO_ODR_OD5; 
        wait(16000000 / 16);
    }
}
