/* Copyright 2019 The MathWorks, Inc. */
#ifndef __SOC_STM_ENCODER_H__
#define __SOC_STM_ENCODER_H__

#ifdef __cplusplus
extern "C" {
#endif
	/************************DriverFunction********************************/
	void initEncoder(void);
	unsigned short int getEncoderCount(void);
	unsigned short int getIndexCount(unsigned short int *indexCount);
	void releaseEncoder(void);
	/*******************************************************************/
#ifdef __cplusplus
}
#endif

#endif /* __SOC_STM_ENCODER_H__ */