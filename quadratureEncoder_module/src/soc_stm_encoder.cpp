/* Connections
 * PB_4 = Encoder A
 * PB_5 = Encoder B
 * PA_4 = Encoder Index
 */
/*********************** Header Include Start *************************/
#include "soc_stm_encoder.h"
#include "mw_mbed_interface.h"

#ifdef TARGET_NUCLEO_F767ZI
#include "stm32f767xx.h"
#elif defined(TARGET_NUCLEO_F401RE)
#include "stm32f401xe.h"
#elif defined(TARGET_NUCLEO_F411RE)
#include "stm32f411xe.h"
#else
#error "Encode supported with STM32 Nucleo-F767ZI, STM32 Nucleo-F401RE or STM32 Nucleo-F411RE boards."
#endif

/*********************** Header Include End ***************************/
/*********************** Encoder defines Start ************************/
#ifdef TARGET_NUCLEO_F767ZI
    #define ENCODER_TIMER                       (TIM3)                                              // Encoder timer
    #define ENCODER_TIMER_CLK_EN                0x00000002                                          // Enable Encoder Clock 
    #define ENCODER_TIMER_CLK_REG               APB1ENR                                             // Encoder timer peripheral clock register
    #define ENCODER_GPIO_PORT                   (GPIOB)                                             // GPIO Port for Encoder Channels
    #define ENCODER_GPIO_PORT_CLK_EN            0x00000002                                          // Enable clock to GPIO B port
    #define ENCODER_GPIO_PORT_CLK_REG           AHB1ENR                                             // GPIO B peripheral clock register
    #define ENCODER_GPIO_PIN_CH1                4                                                   // Encoder timer channel 1 (PB4)
    #define ENCODER_GPIO_PIN_CH2                5                                                   // Encoder timer channel 2 (PB5)
    #define ENCODER_GPIO_PIN_CH_MODER           (GPIO_MODER_MODER4_1 | GPIO_MODER_MODER5_1)         // GPIO configurations to map PB4 and PB5 to use for Encoder timer channels
    #define ENCODER_GPIO_PIN_CH_OTYPER          (GPIO_OTYPER_OT_4 | GPIO_OTYPER_OT_5)
    #define ENCODER_GPIO_PIN_CH_OSPEEDR         (GPIO_OSPEEDER_OSPEEDR4 | GPIO_OSPEEDER_OSPEEDR5)   // Low speed
    #define ENCODER_GPIO_PIN_CH_PUPDR           (GPIO_PUPDR_PUPDR4_0 | GPIO_PUPDR_PUPDR5_0)
    #define ENCODER_GPIO_PIN_CH_AFR0            (0x00220000)
    #define ENCODER_GPIO_PIN_CH_AFR1            (0x00000000)
#else
    #define ENCODER_TIMER                       (TIM1)                                              // Encoder timer
    #define ENCODER_TIMER_CLK_EN                0x00000001                                          // Enable Encoder Clock 
    #define ENCODER_TIMER_CLK_REG               APB2ENR                                             // Encoder timer peripheral clock register
    #define ENCODER_GPIO_PORT                   (GPIOA)                                             // GPIO Port for Encoder Channels
    #define ENCODER_GPIO_PORT_CLK_EN            0x00000001                                          // Enable clock to GPIO A port
    #define ENCODER_GPIO_PORT_CLK_REG           AHB1ENR                                             // GPIO A peripheral clock register
    #define ENCODER_GPIO_PIN_CH1                8                                                   // Encoder timer channel 1 (PA8)
    #define ENCODER_GPIO_PIN_CH2                9                                                   // Encoder timer channel 1 (PA9)
    #define ENCODER_GPIO_PIN_CH_MODER           (GPIO_MODER_MODER8_1 | GPIO_MODER_MODER9_1)         // GPIO configurations to map PA8 and PA9 to use for Encoder timer channels
    #define ENCODER_GPIO_PIN_CH_OTYPER          (GPIO_OTYPER_OT_8 | GPIO_OTYPER_OT_9)
    #define ENCODER_GPIO_PIN_CH_OSPEEDR         (GPIO_OSPEEDER_OSPEEDR8 | GPIO_OSPEEDER_OSPEEDR9)   // Low speed
    #define ENCODER_GPIO_PIN_CH_PUPDR           (GPIO_PUPDR_PUPDR8_0 | GPIO_PUPDR_PUPDR9_0)
    #define ENCODER_GPIO_PIN_CH_AFR0            (0x00000000)
    #define ENCODER_GPIO_PIN_CH_AFR1            (0x00000011)
#endif
// Index pulse pin
#define ENCODER_INDEX_PULSE_PIN                 PB_3
/*********************** Encoder defines End **************************/
/*********************** Static Variable Start ************************/
static volatile unsigned short int IndexCount = 0;
static volatile unsigned short int ValidIndex = 0;
static volatile unsigned short int start = 1;
/*********************** Static Variable End ***************************/
/*********************** Global Variable Start ************************/
InterruptIn IndexPulse(ENCODER_INDEX_PULSE_PIN) ;
/*********************** Global Variable End ***************************/
/*********************** ISR function Start ****************************/
// Index Pulse ISR
void IndexEncoderCount() {
    IndexCount = ENCODER_TIMER->CNT;
    ValidIndex = 1;
}
/*********************** ISR function End ******************************/
/************************ Init Function Start **************************/
void initEncoder(void)
{
	// configure GPIO PB4 & PB5 as inputs for Encoder
	RCC->ENCODER_GPIO_PORT_CLK_REG  |= ENCODER_GPIO_PORT_CLK_EN;                            // Enable clock for GPIO
	ENCODER_GPIO_PORT->MODER        |= ENCODER_GPIO_PIN_CH_MODER;                           // Alternate Function
	ENCODER_GPIO_PORT->OTYPER       |= ENCODER_GPIO_PIN_CH_OTYPER;                          // 
	ENCODER_GPIO_PORT->OSPEEDR      |= ENCODER_GPIO_PIN_CH_OSPEEDR;                         // 
	ENCODER_GPIO_PORT->PUPDR        |= ENCODER_GPIO_PIN_CH_PUPDR;                           // 
	ENCODER_GPIO_PORT->AFR[0]       |= ENCODER_GPIO_PIN_CH_AFR0;                            // 
	ENCODER_GPIO_PORT->AFR[1]       |= ENCODER_GPIO_PIN_CH_AFR1;                            //

	// configure ENCODER_TIMER as Encoder input
	RCC->ENCODER_TIMER_CLK_REG |= ENCODER_TIMER_CLK_EN;                                     // Enable clock for ENCODER_TIMER
	ENCODER_TIMER->SMCR  = 0x0003;                                                          // SMS='011' (Encoder mode 3)  < TIM slave mode control register
	ENCODER_TIMER->CCMR1 = 0x0101;                                                          // CC1S='01' CC2S='01'         < TIM capture/compare mode register 1
	ENCODER_TIMER->CCMR2 = 0x0000;                                                          //                             < TIM capture/compare mode register 2
	ENCODER_TIMER->CCER  = 0x0011;                                                          // CC1P CC2P                   < TIM capture/compare enable register
	ENCODER_TIMER->PSC   = 0x0000;                                                          // Prescaler = (0+1)           < TIM prescaler
	ENCODER_TIMER->ARR   = 0xffffffff;                                                      // reload at 0xfffffff         < TIM auto-reload register
	
	ENCODER_TIMER->CNT = 0x0000;                                                            // reset the counter before we use it
	ENCODER_TIMER->CR1 = 0x0001;                                                            // CEN(Counter Enable)='1'     < TIM control register 1
	IndexPulse.rise(&IndexEncoderCount) ;                                                   // Setup Interrupt for rising edge of Index pulse
	IndexPulse.mode(PullUp) ;                                                               // Set input as pull up
	IndexCount = 0;
	ValidIndex = 0;
}
/************************ Init Function End **************************/
/************************ Step Function Start ************************/
unsigned short int getEncoderCount(void)
{
	//encoder count
	if(start==1){
		ENCODER_TIMER->CNT = 0x0000;
		start=0;
	}
	return ((TIM_TypeDef *)ENCODER_TIMER)->CNT;
}
unsigned short int getIndexCount(unsigned short int *indexCount)
{
	//index count
	*indexCount = IndexCount;
	//index count is valid
	return ValidIndex;
}
/*************************Step Function End************************/
/********************* Release Function Start *********************/
void releaseEncoder(void)
{
	//disable the timer 3
	ENCODER_TIMER->CR1 = 0x0000;
	//unconfigure Interrupt for index pulse
	IndexPulse.rise(NULL);
}
/********************** Release Function End************************/
