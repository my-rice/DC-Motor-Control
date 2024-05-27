/* USER CODE BEGIN Header */
/**
 ******************************************************************************
 * @file           : main.c
 * @brief          : Main program body
 ******************************************************************************
 * @attention
 *
 * <h2><center>&copy; Copyright (c) 2021 STMicroelectronics.
 * All rights reserved.</center></h2>
 *
 * This software component is licensed by ST under BSD 3-Clause license,
 * the "License"; You may not use this file except in compliance with the
 * License. You may obtain a copy of the License at:
 *                        opensource.org/licenses/BSD-3-Clause
 *
 ******************************************************************************
 */
/* USER CODE END Header */
/* Includes ------------------------------------------------------------------*/
#include "main.h"

/* Private includes ----------------------------------------------------------*/
/* USER CODE BEGIN Includes */
#include "stdio.h"
#include "stdlib.h"
#include "stdbool.h"
#include "math.h"
#include "string.h"
#include  <errno.h>
#include  <sys/unistd.h> // STDOUT_FILENO, STDERR_FILENO
/* USER CODE END Includes */

/* Private typedef -----------------------------------------------------------*/
/* USER CODE BEGIN PTD */

/* USER CODE END PTD */

/* Private define ------------------------------------------------------------*/
/* USER CODE BEGIN PD */
#define WAITING 5 // the number of seconds to wait from one reference change to the next. It also coincides with the number of seconds between one USART send and the next
/* USER CODE END PD */

/* Private macro -------------------------------------------------------------*/
/* USER CODE BEGIN PM */

/* USER CODE END PM */

/* Private variables ---------------------------------------------------------*/
TIM_HandleTypeDef htim1;
TIM_HandleTypeDef htim3;
TIM_HandleTypeDef htim4;

UART_HandleTypeDef huart2;

/* USER CODE BEGIN PV */

/* USER CODE END PV */

/* Private function prototypes -----------------------------------------------*/
void SystemClock_Config(void);
static void MX_GPIO_Init(void);
static void MX_USART2_UART_Init(void);
static void MX_TIM3_Init(void);
static void MX_TIM1_Init(void);
static void MX_TIM4_Init(void);
/* USER CODE BEGIN PFP */

/* USER CODE END PFP */

/* Private user code ---------------------------------------------------------*/
/* USER CODE BEGIN 0 */
/* BEGIN CIRCULAR DATA BUFFER */
typedef struct circular_buffer {
	void *buffer;     // data buffer
	void *buffer_end; // end of data buffer
	size_t capacity;  // maximum number of items in the buffer
	size_t count;     // number of items in the buffer
	size_t sz;        // size of each item in the buffer
	void *head;       // pointer to head
	void *tail;       // pointer to tail
	bool writing;  // signals if the buffer is being written
} circular_buffer;

void cb_init(circular_buffer *cb, size_t capacity, size_t sz) {
	cb->buffer = calloc(capacity, sz);
	if (cb->buffer == NULL)
		printf("ALLOCATED NULL\n\r");
	// handle error
	cb->buffer_end = (char*) cb->buffer + capacity * sz;
	cb->capacity = capacity;
	cb->count = 0;
	cb->sz = sz;
	cb->head = cb->buffer;
	cb->tail = cb->buffer;
	cb->writing = false;

}

void cb_free(circular_buffer *cb) {
	free(cb->buffer);
	// clear out other fields too, just to be safe
}

void cb_push_back(circular_buffer *cb, const void *item) {
	if (cb->count == cb->capacity) {
		printf("ERROR PUSH BACK \n\r");
		// handle error
	}
	cb->writing = true;
	memmove(cb->head, item, cb->sz);
	cb->head = (char*) cb->head + cb->sz;
	if (cb->head == cb->buffer_end)
		cb->head = cb->buffer;
	cb->count++;
	cb->writing = false;
}

void cb_pop_front(circular_buffer *cb, void *item) {
	if (cb->count == 0) {
		printf("ERROR PUSH BACK \n\r");
		// handle error
	}
	memmove(item, cb->tail, cb->sz);
	cb->tail = (char*) cb->tail + cb->sz;
	if (cb->tail == cb->buffer_end)
		cb->tail = cb->buffer;
	while ((cb->writing))
		;
	cb->count--;
}

circular_buffer myBuff;

/* BEGIN RECORD TYPEDEF*/
typedef struct record {
	double current_u; // value of the current controller output
	double current_y; // value of the current motor output (speed)
	uint32_t cycleCoreDuration; // time needed to read, compute and actuate
	uint32_t cycleBeginDelay; // difference between the actual and the expected absolute start time of the cycle
	uint32_t currentTimestamp; // current timestamp in millis
} record;

/* BEGIN USART WRITE FUNCTION (used by printf)*/
int _write(int file, char *data, int len) {
	if ((file != STDOUT_FILENO) && (file != STDERR_FILENO)) {
		errno = EBADF;
		return -1;
	}

	// arbitrary timeout 1000
	HAL_StatusTypeDef status = HAL_UART_Transmit(&huart2, (uint8_t*) data, len,
			1000);

	// return # of bytes written - as best we can tell
	return (status == HAL_OK ? len : 0);
}

void setPulseFromDutyValue(double dutyVal) {
	HAL_GPIO_WritePin(GPIOA, GPIO_PIN_10, GPIO_PIN_SET); // enable the motor driver

	uint16_t channelToModulate;
	uint16_t channelToStop;

	if (dutyVal > 0) {
		channelToModulate = TIM_CHANNEL_1;
		channelToStop = TIM_CHANNEL_2;
	} else {
		channelToModulate = TIM_CHANNEL_2;
		channelToStop = TIM_CHANNEL_1;
	}

	__HAL_TIM_SET_COMPARE(&htim3, channelToStop, 0);
	__HAL_TIM_SET_COMPARE(&htim3, channelToModulate,
			(abs(dutyVal) * ((double )htim3.Init.Period)) / 100); //cast integer value to double to correctly perform division between decimal numbers
}

double getSpeedByDelta(double ticksDelta, double Ts) {
	return ticksDelta * 60 / (8400 * Ts);
}

double getTicksDelta(double currentTicks, double lastTicks, double Ts) {
	double delta;

	if (abs(currentTicks - lastTicks) <= ceil(12600 * Ts))
		delta = currentTicks - lastTicks;
	else {
		if (lastTicks > currentTicks)
			delta = currentTicks + pow(2, 16) - 1 - lastTicks;
		else
			delta = currentTicks - pow(2, 16) + 1 - lastTicks;
	}
	return delta;
}

double sign(double x) {
	if (x > 0)
		return 1;
	else if (x < 0)
		return -1;
	else
		return 0;
}


double getPositionByDelta(double ticksDelta, double* ticksStar) {
	// 
	*ticksStar = *ticksStar + (double)ticksDelta;
	double completeTheta = 2*3.14159265359*(*ticksStar/8400);
	double position=sign(completeTheta)*fmod(completeTheta,2*3.14159265359);
	return position;
}

int cycleduration;
double lastTicks = 0;
double currentTicks = 0;
uint32_t ticControlStep;
uint32_t tocControlStep;
uint32_t controlComputationDuration;
double u_last_integrated = 0;
double u_last = 0;
double e_last = 0;
double Ts = 0.005;
double referenceVals[8] = { 3.14, 3.14, 3.14, 3.14, 3.14, 3.14, 3.14, 3.14 };
double referenceVal;
uint32_t k_controller = -1;
int samplingPrescaler = 2;
int samplingPrescalerCounter = 0;

double ticksStar = 0; 

typedef struct controller_gains{
	double K1;
	double K2;
	double K3;
	double KI;
	double Kr;
} controller_gains;

controller_gains controller_gain = {
	.K1 = 2.8533651377751847,
	.K2 = 25.840304667836726,
	.K3 = 0.70305257229905194,
	.KI = 0.00883883476483182,
	.Kr = 4.6009096074749376
};

typedef struct observer_A_s{
	double A11;
	double A12;
	double A13;
	double A21;
	double A22;
	double A23;
	double A31;
	double A32;
	double A33;
} observer_A_t;

observer_A_t observer_A = {
	.A11 = 0.9323301716064688,
	.A12 = -11.678660637721487,
	.A13 = 0.039014496138124237,
	.A21 = 0.0027413091396064947,
	.A22 = 0.1183557159613379,
	.A23 = 5.5348095481874759E-5,
	.A31 = -0.0068954979109303533,
	.A32 = -2.8131155992845822,
	.A33 = 0.8383381318909956
};


typedef struct observer_B_s{
	double B11;
	double B12;
	double B21;
	double B22;
	double B31;
	double B32;
} observer_B_t;

observer_B_t observer_B = {
	.B11 = -0.0040505355062536866,
	.B12 = 2.0794225090756346,
	.B21 = -5.7463109393787418E-6,
	.B22 = 0.15697955665449895,
	.B31 = 0.036784001382597235,
	.B32 = 0.50088414067706177
};

typedef struct observer_C_s{
	double C11;
	double C12;
	double C13;
	double C21;
	double C22;
	double C23;
	double C31;
	double C32;
	double C33;
} observer_C_t;

observer_C_t observer_C = {
	.C11 = 0.96616508580323435,
	.C12 = -5.8393303188607444,
	.C13 = 0.019507248069062118,
	.C21 = 0.0013706545698032474,
	.C22 = 0.559177857980669,
	.C23 = 2.767404774093738E-5,
	.C31 = -0.0034477489554651771,
	.C32 = -1.4065577996422911,
	.C33 = 0.91916906594549774
};

typedef struct observer_D_s{
	double D11;
	double D12;
	double D21;
	double D22;
	double D31;
	double D32;
} observer_D_t;

observer_D_t observer_D = {
	.D11 = -0.0020252677531268433,
	.D12 = 1.0397112545378173,
	.D21 = -2.8731554696893709E-6,
	.D22 = 0.078489778327249474,
	.D31 = 0.018392000691298618,
	.D32 = 0.25044207033853089
};
typedef struct x_hat_s {
	double x1;
	double x2;
	double x3;
} x_hat_t;

x_hat_t observer_state = {0, 0, 0};



/* USER CODE END 0 */

/**
 * @brief  The application entry point.
 * @retval int
 */
int main(void) {
	/* USER CODE BEGIN 1 */
	/* USER CODE END 1 */
	/* MCU Configuration--------------------------------------------------------*/

	/* Reset of all peripherals, Initializes the Flash interface and the Systick. */
	HAL_Init();

	/* USER CODE BEGIN Init */
	size_t bufferSize = (size_t)ceil(2 * WAITING / (Ts * samplingPrescaler));
	cb_init(&myBuff, bufferSize, sizeof(record));

	/* USER CODE END Init */

	/* Configure the system clock */
	SystemClock_Config();

	/* USER CODE BEGIN SysInit */
	/* USER CODE END SysInit */

	/* Initialize all configured peripherals */
	MX_GPIO_Init();
	MX_USART2_UART_Init();
	MX_TIM3_Init();
	MX_TIM1_Init();
	MX_TIM4_Init();
	/* USER CODE BEGIN 2 */
	HAL_TIM_PWM_Start(&htim3, TIM_CHANNEL_1);
	HAL_TIM_PWM_Start(&htim3, TIM_CHANNEL_2);

	int referenceIndex = 0;

	referenceVal = referenceVals[referenceIndex];
	HAL_TIM_Base_Start(&htim1);
	HAL_TIM_Base_Start_IT(&htim4);
	/* USER CODE END 2 */

	/* Infinite loop */
	/* USER CODE BEGIN WHILE */
	printf("INIT\n\r"); // initialize the Matlab tool for COM data acquiring

	while (1) {
		size_t nEntriesToSend = myBuff.count; //number of samples not read yet
		record retrieved; //buffer entry

		for (size_t count = 0; count < nEntriesToSend; count++) {
			cb_pop_front(&myBuff, &retrieved); //take entry from the buffer
			printf("%lu, %f, %f, %lu\n\r", retrieved.currentTimestamp,
					retrieved.current_u, retrieved.current_y,
					retrieved.cycleCoreDuration); // send values via USART using format: value1, value2, value3, ... valuen \n \r
		}
		referenceVal = referenceVals[referenceIndex];
		referenceIndex = referenceIndex + 1;
		HAL_Delay(WAITING*1000); // takes a time value in ms
		if (referenceIndex > 7)
			referenceIndex = 0;

		/* USER CODE END WHILE */

		/* USER CODE BEGIN 3 */
	}
	/* USER CODE END 3 */
}

/**
 * @brief System Clock Configuration
 * @retval None
 */
void SystemClock_Config(void) {
	RCC_OscInitTypeDef RCC_OscInitStruct = { 0 };
	RCC_ClkInitTypeDef RCC_ClkInitStruct = { 0 };

	/** Configure the main internal regulator output voltage
	 */
	__HAL_RCC_PWR_CLK_ENABLE();
	__HAL_PWR_VOLTAGESCALING_CONFIG(PWR_REGULATOR_VOLTAGE_SCALE2);
	/** Initializes the RCC Oscillators according to the specified parameters
	 * in the RCC_OscInitTypeDef structure.
	 */
	RCC_OscInitStruct.OscillatorType = RCC_OSCILLATORTYPE_HSI;
	RCC_OscInitStruct.HSIState = RCC_HSI_ON;
	RCC_OscInitStruct.HSICalibrationValue = RCC_HSICALIBRATION_DEFAULT;
	RCC_OscInitStruct.PLL.PLLState = RCC_PLL_ON;
	RCC_OscInitStruct.PLL.PLLSource = RCC_PLLSOURCE_HSI;
	RCC_OscInitStruct.PLL.PLLM = 16;
	RCC_OscInitStruct.PLL.PLLN = 336;
	RCC_OscInitStruct.PLL.PLLP = RCC_PLLP_DIV4;
	RCC_OscInitStruct.PLL.PLLQ = 4;
	if (HAL_RCC_OscConfig(&RCC_OscInitStruct) != HAL_OK) {
		Error_Handler();
	}
	/** Initializes the CPU, AHB and APB buses clocks
	 */
	RCC_ClkInitStruct.ClockType = RCC_CLOCKTYPE_HCLK | RCC_CLOCKTYPE_SYSCLK
			| RCC_CLOCKTYPE_PCLK1 | RCC_CLOCKTYPE_PCLK2;
	RCC_ClkInitStruct.SYSCLKSource = RCC_SYSCLKSOURCE_PLLCLK;
	RCC_ClkInitStruct.AHBCLKDivider = RCC_SYSCLK_DIV1;
	RCC_ClkInitStruct.APB1CLKDivider = RCC_HCLK_DIV2;
	RCC_ClkInitStruct.APB2CLKDivider = RCC_HCLK_DIV1;

	if (HAL_RCC_ClockConfig(&RCC_ClkInitStruct, FLASH_LATENCY_2) != HAL_OK) {
		Error_Handler();
	}
}

/**
 * @brief TIM1 Initialization Function
 * @param None
 * @retval None
 */
static void MX_TIM1_Init(void) {

	/* USER CODE BEGIN TIM1_Init 0 */

	/* USER CODE END TIM1_Init 0 */

	TIM_Encoder_InitTypeDef sConfig = { 0 };
	TIM_MasterConfigTypeDef sMasterConfig = { 0 };

	/* USER CODE BEGIN TIM1_Init 1 */

	/* USER CODE END TIM1_Init 1 */
	htim1.Instance = TIM1;
	htim1.Init.Prescaler = 0;
	htim1.Init.CounterMode = TIM_COUNTERMODE_UP;
	htim1.Init.Period = 65535;
	htim1.Init.ClockDivision = TIM_CLOCKDIVISION_DIV1;
	htim1.Init.RepetitionCounter = 0;
	htim1.Init.AutoReloadPreload = TIM_AUTORELOAD_PRELOAD_DISABLE;
	sConfig.EncoderMode = TIM_ENCODERMODE_TI12;
	sConfig.IC1Polarity = TIM_ICPOLARITY_RISING;
	sConfig.IC1Selection = TIM_ICSELECTION_DIRECTTI;
	sConfig.IC1Prescaler = TIM_ICPSC_DIV1;
	sConfig.IC1Filter = 0;
	sConfig.IC2Polarity = TIM_ICPOLARITY_RISING;
	sConfig.IC2Selection = TIM_ICSELECTION_DIRECTTI;
	sConfig.IC2Prescaler = TIM_ICPSC_DIV1;
	sConfig.IC2Filter = 0;
	if (HAL_TIM_Encoder_Init(&htim1, &sConfig) != HAL_OK) {
		Error_Handler();
	}
	sMasterConfig.MasterOutputTrigger = TIM_TRGO_RESET;
	sMasterConfig.MasterSlaveMode = TIM_MASTERSLAVEMODE_DISABLE;
	if (HAL_TIMEx_MasterConfigSynchronization(&htim1, &sMasterConfig)
			!= HAL_OK) {
		Error_Handler();
	}
	/* USER CODE BEGIN TIM1_Init 2 */

	/* USER CODE END TIM1_Init 2 */

}

/**
 * @brief TIM3 Initialization Function
 * @param None
 * @retval None
 */
static void MX_TIM3_Init(void) {

	/* USER CODE BEGIN TIM3_Init 0 */

	/* USER CODE END TIM3_Init 0 */

	TIM_ClockConfigTypeDef sClockSourceConfig = { 0 };
	TIM_MasterConfigTypeDef sMasterConfig = { 0 };
	TIM_OC_InitTypeDef sConfigOC = { 0 };

	/* USER CODE BEGIN TIM3_Init 1 */

	/* USER CODE END TIM3_Init 1 */
	htim3.Instance = TIM3;
	htim3.Init.Prescaler = 84 - 1;
	htim3.Init.CounterMode = TIM_COUNTERMODE_UP;
	htim3.Init.Period = 500 - 1;
	htim3.Init.ClockDivision = TIM_CLOCKDIVISION_DIV1;
	htim3.Init.AutoReloadPreload = TIM_AUTORELOAD_PRELOAD_ENABLE;
	if (HAL_TIM_Base_Init(&htim3) != HAL_OK) {
		Error_Handler();
	}
	sClockSourceConfig.ClockSource = TIM_CLOCKSOURCE_INTERNAL;
	if (HAL_TIM_ConfigClockSource(&htim3, &sClockSourceConfig) != HAL_OK) {
		Error_Handler();
	}
	if (HAL_TIM_PWM_Init(&htim3) != HAL_OK) {
		Error_Handler();
	}
	sMasterConfig.MasterOutputTrigger = TIM_TRGO_RESET;
	sMasterConfig.MasterSlaveMode = TIM_MASTERSLAVEMODE_DISABLE;
	if (HAL_TIMEx_MasterConfigSynchronization(&htim3, &sMasterConfig)
			!= HAL_OK) {
		Error_Handler();
	}
	sConfigOC.OCMode = TIM_OCMODE_PWM1;
	sConfigOC.Pulse = 0;
	sConfigOC.OCPolarity = TIM_OCPOLARITY_HIGH;
	sConfigOC.OCFastMode = TIM_OCFAST_DISABLE;
	if (HAL_TIM_PWM_ConfigChannel(&htim3, &sConfigOC, TIM_CHANNEL_1)
			!= HAL_OK) {
		Error_Handler();
	}
	if (HAL_TIM_PWM_ConfigChannel(&htim3, &sConfigOC, TIM_CHANNEL_2)
			!= HAL_OK) {
		Error_Handler();
	}
	/* USER CODE BEGIN TIM3_Init 2 */

	/* USER CODE END TIM3_Init 2 */
	HAL_TIM_MspPostInit(&htim3);

}

/**
 * @brief TIM4 Initialization Function
 * @param None
 * @retval None
 */
static void MX_TIM4_Init(void) {

	/* USER CODE BEGIN TIM4_Init 0 */

	/* USER CODE END TIM4_Init 0 */

	TIM_ClockConfigTypeDef sClockSourceConfig = { 0 };
	TIM_MasterConfigTypeDef sMasterConfig = { 0 };

	/* USER CODE BEGIN TIM4_Init 1 */

	/* USER CODE END TIM4_Init 1 */
	htim4.Instance = TIM4;
	htim4.Init.Prescaler = 84 - 1;
	htim4.Init.CounterMode = TIM_COUNTERMODE_UP;
	htim4.Init.Period = 5000 - 1;
	htim4.Init.ClockDivision = TIM_CLOCKDIVISION_DIV1;
	htim4.Init.AutoReloadPreload = TIM_AUTORELOAD_PRELOAD_DISABLE;
	if (HAL_TIM_Base_Init(&htim4) != HAL_OK) {
		Error_Handler();
	}
	sClockSourceConfig.ClockSource = TIM_CLOCKSOURCE_INTERNAL;
	if (HAL_TIM_ConfigClockSource(&htim4, &sClockSourceConfig) != HAL_OK) {
		Error_Handler();
	}
	sMasterConfig.MasterOutputTrigger = TIM_TRGO_RESET;
	sMasterConfig.MasterSlaveMode = TIM_MASTERSLAVEMODE_DISABLE;
	if (HAL_TIMEx_MasterConfigSynchronization(&htim4, &sMasterConfig)
			!= HAL_OK) {
		Error_Handler();
	}
	/* USER CODE BEGIN TIM4_Init 2 */

	/* USER CODE END TIM4_Init 2 */

}

/**
 * @brief USART2 Initialization Function
 * @param None
 * @retval None
 */
static void MX_USART2_UART_Init(void) {

	/* USER CODE BEGIN USART2_Init 0 */

	/* USER CODE END USART2_Init 0 */

	/* USER CODE BEGIN USART2_Init 1 */

	/* USER CODE END USART2_Init 1 */
	huart2.Instance = USART2;
	huart2.Init.BaudRate = 115200;
	huart2.Init.WordLength = UART_WORDLENGTH_8B;
	huart2.Init.StopBits = UART_STOPBITS_1;
	huart2.Init.Parity = UART_PARITY_NONE;
	huart2.Init.Mode = UART_MODE_TX_RX;
	huart2.Init.HwFlowCtl = UART_HWCONTROL_NONE;
	huart2.Init.OverSampling = UART_OVERSAMPLING_16;
	if (HAL_UART_Init(&huart2) != HAL_OK) {
		Error_Handler();
	}
	/* USER CODE BEGIN USART2_Init 2 */

	/* USER CODE END USART2_Init 2 */

}

/**
 * @brief GPIO Initialization Function
 * @param None
 * @retval None
 */
static void MX_GPIO_Init(void) {
	GPIO_InitTypeDef GPIO_InitStruct = { 0 };

	/* GPIO Ports Clock Enable */
	__HAL_RCC_GPIOA_CLK_ENABLE();
	__HAL_RCC_GPIOB_CLK_ENABLE();

	/*Configure GPIO pin Output Level */
	HAL_GPIO_WritePin(GPIOA, GPIO_PIN_10, GPIO_PIN_RESET);

	/*Configure GPIO pin : PA10 */
	GPIO_InitStruct.Pin = GPIO_PIN_10;
	GPIO_InitStruct.Mode = GPIO_MODE_OUTPUT_PP;
	GPIO_InitStruct.Pull = GPIO_NOPULL;
	GPIO_InitStruct.Speed = GPIO_SPEED_FREQ_LOW;
	HAL_GPIO_Init(GPIOA, &GPIO_InitStruct);

}

/* USER CODE BEGIN 4 */
x_hat_t get_x_hat(double u_last, double y_now) {
	double x1 = observer_state.x1;
	double x2 = observer_state.x2;
	double x3 = observer_state.x3;

	double u = u_last;
	double y = y_now;

	x_hat_t state_estimated = {0,0,0}; 

	
	state_estimated.x1 = observer_C.C11 * x1 + observer_C.C12 * x2 + observer_C.C13 * x3 + observer_D.D11 * u + observer_D.D12 * y;
	state_estimated.x2 = observer_C.C21 * x1 + observer_C.C22 * x2 + observer_C.C23 * x3 + observer_D.D21 * u + observer_D.D22 * y;
	state_estimated.x3 = observer_C.C31 * x1 + observer_C.C32 * x2 + observer_C.C33 * x3 + observer_D.D31 * u + observer_D.D32 * y;
	
	double x1_new = observer_A.A11 * x1 + observer_A.A12 * x2 + observer_A.A13 * x3 + observer_B.B11 * u + observer_B.B12 * y;
	double x2_new = observer_A.A21 * x1 + observer_A.A22 * x2 + observer_A.A23 * x3 + observer_B.B21 * u + observer_B.B22 * y;
	double x3_new = observer_A.A31 * x1 + observer_A.A32 * x2 + observer_A.A33 * x3 + observer_B.B31 * u + observer_B.B32 * y;

	observer_state.x1 = x1_new;
	observer_state.x2 = x2_new;
	observer_state.x3 = x3_new;

	return state_estimated;
}

void HAL_TIM_PeriodElapsedCallback(TIM_HandleTypeDef *htim) {
	if (htim == &htim4) {
		k_controller = k_controller + 1;
		if (k_controller == 0) {
			ticControlStep = HAL_GetTick();
		}
		tocControlStep = HAL_GetTick();

		currentTicks = (double) __HAL_TIM_GET_COUNTER(&htim1); //take current value of ticks counting the encoder edges
		// double speed = getSpeedByDelta(
		// 		getTicksDelta(currentTicks, lastTicks, Ts), Ts);

		double position = getPositionByDelta(
				getTicksDelta(currentTicks, lastTicks, Ts), &ticksStar);

		// double e = referenceVal - speed;
		double e = referenceVal - position;

		x_hat_t state_estimated = get_x_hat(u_last, position);

		double u = -controller_gain.K1 * state_estimated.x1 - controller_gain.K2 * state_estimated.x2 - controller_gain.K3 * state_estimated.x3 + controller_gain.Kr * referenceVal;
		double u_integrator = u_last_integrated + controller_gain.KI *(e + e_last);
		u += u_integrator;
		setPulseFromDutyValue(u * 100 / 12);

		u_last_integrated = u_integrator;
		u_last = u;
		e_last = e;

		controlComputationDuration = HAL_GetTick() - tocControlStep;
		lastTicks = currentTicks;
		// recording data in the buffer
		record r;
		r.current_u = u;
		r.current_y = position;
		r.cycleCoreDuration = controlComputationDuration;
		r.cycleBeginDelay = tocControlStep - ticControlStep
				- (k_controller * Ts * 1000);
		r.currentTimestamp = HAL_GetTick();
		if (samplingPrescalerCounter == (samplingPrescaler - 1)) {
			cb_push_back(&myBuff, &r);
			samplingPrescalerCounter = -1;
		}
		samplingPrescalerCounter++;
	}
}
/* USER CODE END 4 */

/**
 * @brief  This function is executed in case of error occurrence.
 * @retval None
 */
void Error_Handler(void) {
	/* USER CODE BEGIN Error_Handler_Debug */
	/* User can add his own implementation to report the HAL error return state */
	__disable_irq();
	while (1) {
	}
	/* USER CODE END Error_Handler_Debug */
}

#ifdef  USE_FULL_ASSERT
/**
  * @brief  Reports the name of the source file and the source line number
  *         where the assert_param error has occurred.
  * @param  file: pointer to the source file name
  * @param  line: assert_param error line source number
  * @retval None
  */
void assert_failed(uint8_t *file, uint32_t line)
{
  /* USER CODE BEGIN 6 */
  /* User can add his own implementation to report the file name and line number,
     ex: printf("Wrong parameters value: file %s on line %d\r\n", file, line) */
  /* USER CODE END 6 */
}
#endif /* USE_FULL_ASSERT */

/************************ (C) COPYRIGHT STMicroelectronics *****END OF FILE****/
